import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../utils/multi_level_cache.dart';
import '../../user/services/user_token_manager.dart';
import '../../user/models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/repositories/candidate_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool isOTPScreen = false.obs;
  RxString verificationId = ''.obs;
  Rx<User?> currentUser = Rx<User?>(null); // Reactive user state

  // OTP Timer
  RxInt otpTimer = 60.obs;
  RxBool canResendOTP = false.obs;
  Timer? _otpTimer;

  // Background sync
  Timer? _backgroundSyncTimer;
  static const Duration _backgroundSyncInterval = Duration(minutes: 30);

  // Debounced auth change handling
  Timer? _authChangeDebouncer;
  static const Duration _authDebounceDelay = Duration(milliseconds: 500);

  // Cached auth state for fault tolerance
  Map<String, dynamic>? _cachedAuthData;

  @override
  void onInit() {
    super.onInit();
    _initializeAuthListeners();
    _initializeBackgroundSync();
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    _otpTimer?.cancel();
    _authChangeDebouncer?.cancel();
    _backgroundSyncTimer?.cancel();
    super.onClose();
  }

  // Initialize Firebase auth listeners with debouncing
  void _initializeAuthListeners() {
    // Listen to auth state changes with debouncing
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    // Listen to idToken changes for more sensitive auth handling
    FirebaseAuth.instance.idTokenChanges().listen(_onIdTokenChanged);

    AppLogger.auth('AuthController listeners initialized');
  }

  // Initialize background sync timer
  void _initializeBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      _performBackgroundSync();
    });
  }

  // Debounced auth state change handler
  void _onAuthStateChanged(User? user) {
    _authChangeDebouncer?.cancel();
    _authChangeDebouncer = Timer(_authDebounceDelay, () {
      _handleAuthStateChange(user);
    });
  }

  // Handle ID token changes (more sensitive than auth state)
  void _onIdTokenChanged(User? user) {
    if (user != null) {
      // Cache basic user info for fault tolerance
      _cacheCurrentUserInfo(user);
    }
  }

  // Handle authenticated state change
  void _handleAuthStateChange(User? user) {
    currentUser.value = user;

    if (user != null) {
      AppLogger.auth('User authenticated: ${user.uid}');
      _cacheCurrentUserInfo(user);

      // Update FCM tokens for authenticated user
      UserTokenManager().onUserAuthenticated();

      // Background sync will handle data fetching
    } else {
      AppLogger.auth('User signed out');
      _clearCachedAuthData();
    }
  }

  // Cache user info for offline fault tolerance
  void _cacheCurrentUserInfo(User user) {
    _cachedAuthData = {
      'uid': user.uid,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'displayName': user.displayName,
      'lastLogin': DateTime.now().toIso8601String(),
    };

    // Persist to SharedPreferences for early app initialization
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cached_user_data', _cachedAuthData.toString());
    });

    AppLogger.auth('User info cached for fault tolerance');
  }

  // Clear cached auth data on logout
  void _clearCachedAuthData() {
    _cachedAuthData = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('cached_user_data');
      prefs.remove('last_google_account'); // Clear silent login data too
    });
  }

  // Background sync every 30 minutes
  Future<void> _performBackgroundSync() async {
    if (currentUser.value != null && Get.currentRoute == '/home') {
      try {
        AppLogger.auth('Performing background auth sync');
        // Refresh user data without blocking UI
        await _authRepository.createOrUpdateUser(currentUser.value!);
        AppLogger.auth('Background sync completed successfully');
      } catch (e) {
        AppLogger.auth('Background sync failed: $e');
        // Don't disrupt UI flow if background sync fails
      }
    }
  }

  // Get last used Google account for smart login UX
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    return await _authRepository.getLastGoogleAccount();
  }

  // OTP LOGIN - SIMPLE
  Future<void> sendOTP() async {
    if (phoneController.text.isEmpty || phoneController.text.length != 10) {
      SnackbarUtils.showError('Please enter a valid 10-digit phone number');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.verifyPhoneNumber(phoneController.text, (String vid) {
        verificationId.value = vid;
        isOTPScreen.value = true;
        _startOTPTimer();
        if (Get.isDialogOpen ?? false) Get.back();
        SnackbarUtils.showSuccess('OTP sent to +91${phoneController.text}');
      });

      AppLogger.auth('OTP sent successfully');
    } catch (e) {
      AppLogger.authError('SendOTP failed', error: e);
      if (Get.isDialogOpen ?? false) Get.back();
      SnackbarUtils.showError('Failed to send OTP: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  // VERIFY OTP AND GO HOME
  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      SnackbarUtils.showError('Please enter a valid 6-digit OTP');
      return;
    }

    isLoading.value = true;
    try {
      final userCredential = await _authRepository.signInWithOTP(
        verificationId.value,
        otpController.text,
      );

      if (userCredential.user != null) {
        AppLogger.auth('OTP login successful: ${userCredential.user!.uid}');
        await _authRepository.createOrUpdateUser(userCredential.user!);

        // Cache fresh user data for immediate home screen display
        await _cacheFreshUserDataAfterLogin(userCredential.user!.uid);

        SnackbarUtils.showSuccess('Login successful');
        Get.offAllNamed('/home');
      }
    } catch (e) {
      AppLogger.authError('OTP verification failed', error: e);
      SnackbarUtils.showError('Invalid OTP: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  // GOOGLE LOGIN - WITH DETAILED ERROR LOGGING
  Future<void> signInWithGoogle({bool forceAccountPicker = false}) async {
    isLoading.value = true;

    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Signing in with Google...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      AppLogger.auth('🔄 [DEBUG] Starting Google sign-in process...');
      final userCredential = await _authRepository.signInWithGoogle(forceAccountPicker: forceAccountPicker);

      if (Get.isDialogOpen ?? false) Get.back();

      if (userCredential == null || userCredential.user == null) {
        AppLogger.auth('⚠️ [DEBUG] User cancelled Google sign-in');
        SnackbarUtils.showError('Google sign-in was cancelled');
        return;
      }

      AppLogger.auth('✅ [DEBUG] Google login successful: ${userCredential.user!.uid}');
      await _authRepository.createOrUpdateUser(userCredential.user!);

      // Cache fresh user data for immediate home screen display
      await _cacheFreshUserDataAfterLogin(userCredential.user!.uid);

      SnackbarUtils.showSuccess('Google sign-in successful');
      Get.offAllNamed('/home');

    } catch (e) {
      // FORCE SHOW BUG: Everything gets caught in AuthRepository - let's see what we actually get
      final actualError = e;
      final errorStr = e.toString();

      AppLogger.auth('🔥 [LAST RESORT] ACTUAL ERROR RECEIVED: $actualError');
      AppLogger.auth('🔥 [LAST RESORT] ERROR STRING: $errorStr');
      AppLogger.auth('🔥 [LAST RESORT] ERROR TYPE: ${e.runtimeType}');

      if (Get.isDialogOpen ?? false) Get.back();

      // FORCE DISPLAY RAW ERROR - bypass all categorization
      SnackbarUtils.showError('Firebase Error: $errorStr (${e.runtimeType})');

      AppLogger.authError('RAW ERROR DISPLAY: $errorStr (${e.runtimeType})', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  // UNIFIED LOGOUT - Clears Firebase + SharedPrefs + Get routes (prevents ghost logins)
  Future<void> signOut() async {
    AppLogger.auth('🚪 Starting unified sign-out process...');

    try {
      // Step 1: Clear local account data (silent login)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_google_account');
      await prefs.remove('cached_user_data');

      // Step 2: Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Step 3: Cancel background sync and debouncers
      _backgroundSyncTimer?.cancel();
      _authChangeDebouncer?.cancel();

      // Step 4: Force close any dialogs
      if (Get.isDialogOpen ?? false) Get.back();

      // Step 5: Clear reactive states
      currentUser.value = null;
      _cachedAuthData = null;

      AppLogger.auth('✅ Unified sign-out completed successfully');
      SnackbarUtils.showSuccess('Logged out successfully');

      // Step 6: Navigate to login (clears navigation stack)
      Get.offAllNamed('/login');

    } catch (e) {
      AppLogger.authError('Unified sign-out failed', error: e);
      SnackbarUtils.showError('Some logout steps failed, but you are logged out');

      // Fallback navigation even if other cleanup fails
      try {
        Get.offAllNamed('/login');
      } catch (navError) {
        // If navigation fails, force restart would be needed
        AppLogger.authError('Navigation failed during logout', error: navError);
      }
    }
  }

  // UPDATED: Maintain backward compatibility
  Future<void> logout() async => await signOut();

  // OFFLINE FAULT TOLERANCE: Get cached user data if Firestore fails
  Map<String, dynamic>? getCachedUserData() {
    if (_cachedAuthData != null) {
      return _cachedAuthData;
    }

    // Try to load from SharedPreferences as fallback
    SharedPreferences.getInstance().then((prefs) {
      final cachedData = prefs.getString('cached_user_data');
      if (cachedData != null) {
        // Parse and store in memory for faster future access
        _cachedAuthData = {'parsed_from_prefs': true, 'data': cachedData};
        AppLogger.auth('Loaded cached user data from SharedPreferences');
      }
    });

    return _cachedAuthData;
  }

  // FORCE REFRESH - For manual user data sync in settings
  Future<void> forceRefreshUserData() async {
    if (currentUser.value != null) {
      try {
        AppLogger.auth('Force refreshing user data');
        await _authRepository.createOrUpdateUser(currentUser.value!);
        _cacheCurrentUserInfo(currentUser.value!); // Refresh cache
        AppLogger.auth('Force refresh completed successfully');
      } catch (e) {
        AppLogger.authError('Force refresh failed', error: e);
        // Try cached fallback
        final cachedData = getCachedUserData();
        if (cachedData != null) {
          AppLogger.auth('Using cached data as fallback after force refresh failure');
        }
      }
    }
  }

  // Cache fresh user data after login for immediate home screen display
  Future<void> _cacheFreshUserDataAfterLogin(String userId) async {
    try {
      AppLogger.auth('🔄 Caching fresh user data after login for: $userId');

      // Fetch fresh user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);

        Candidate? candidateModel;

        // For candidates with completed profiles, also fetch and cache candidate data
        if (userModel.role == 'candidate' && userModel.profileCompleted) {
          AppLogger.auth('🎯 User is candidate, fetching candidate data for: $userId');
          try {
            // Use the candidate repository to properly fetch candidate data from the nested structure
            final candidateRepository = CandidateRepository();
            candidateModel = await candidateRepository.getCandidateData(userId);
            if (candidateModel != null) {
              AppLogger.auth('✅ Candidate data fetched and cached for: $userId');
            } else {
              AppLogger.auth('⚠️ Candidate document not found for: $userId');
            }
          } catch (candidateError) {
            AppLogger.authError('Failed to fetch candidate data for caching', error: candidateError);
            // Continue without candidate data - user can still access home screen
          }
        }

        // Prepare cache data in the same format as HomeServices
        final cacheData = {'user': userModel, 'candidate': candidateModel};
        final cacheKey = 'home_user_data_$userId';

        // Cache with high priority for immediate home screen access
        await MultiLevelCache().set<Map<String, dynamic>>(
          cacheKey,
          cacheData,
          priority: CachePriority.high,
          ttl: const Duration(minutes: 30),
        );

        // Also update routing cache
        final routingData = {
          'hasCompletedProfile': userModel.profileCompleted,
          'hasSelectedRole': userModel.roleSelected,
          'role': userModel.role,
          'lastLogin': DateTime.now().toIso8601String(),
        };
        await MultiLevelCache().setUserRoutingData(userId, routingData);

        AppLogger.auth('✅ Fresh user data cached after login for: $userId');
      } else {
        AppLogger.auth('⚠️ User document not found after login for: $userId');
      }
    } catch (e) {
      AppLogger.authError('Failed to cache fresh user data after login', error: e);
      // Don't fail login if caching fails - home screen will fetch fresh data
    }
  }

  // UTILITY METHODS
  void goBackToPhoneInput() {
    isOTPScreen.value = false;
    otpController.clear();
    _stopOTPTimer();
  }

  Future<void> resendOTP() async {
    if (!canResendOTP.value) return;

    isLoading.value = true;
    try {
      await _authRepository.resendOTP(phoneController.text, (String vid) {
        verificationId.value = vid;
        _startOTPTimer();
        SnackbarUtils.showSuccess('OTP resent to +91${phoneController.text}');
      });

      AppLogger.auth('OTP resent successfully');
    } catch (e) {
      AppLogger.authError('ResendOTP failed', error: e);
      SnackbarUtils.showError('Failed to resend OTP: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _startOTPTimer() {
    _stopOTPTimer();
    otpTimer.value = 60;
    canResendOTP.value = false;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpTimer.value > 0) {
        otpTimer.value--;
      } else {
        canResendOTP.value = true;
        _stopOTPTimer();
      }
    });
  }

  void _stopOTPTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }
}
