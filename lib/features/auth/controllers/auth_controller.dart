import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_route_names.dart';
import '../repositories/auth_repository.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../user/services/user_token_manager.dart';
import '../../user/models/user_model.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/repositories/candidate_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
    emailController.dispose();
    passwordController.dispose();
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

  // EMAIL LOGIN - WITH SMART ROUTING BASED ON USER STATUS
  Future<void> signInWithEmailAndPassword() async {
    if (emailController.text.isEmpty) {
      SnackbarUtils.showError('Please enter your email address');
      return;
    }

    if (passwordController.text.isEmpty) {
      SnackbarUtils.showError('Please enter your password');
      return;
    }

    isLoading.value = true;

    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Signing in...'),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      AppLogger.auth('🔄 Starting email sign-in process for: ${emailController.text}');
      final userCredential = await _authRepository.signInWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
      );

      if (Get.isDialogOpen ?? false) Get.back();

      if (userCredential.user != null) {
        AppLogger.auth('✅ Email login successful: ${userCredential.user!.uid}');
        await _authRepository.createOrUpdateUser(userCredential.user!);

        // Cache fresh user data for immediate screen access
        await _cacheFreshUserDataAfterLogin(userCredential.user!.uid);

        // 🔍 DETERMINE CORRECT ROUTE BASED ON USER STATUS
        final targetRoute = await _getPostLoginRoute(userCredential.user!);
        AppLogger.auth('🎯 Post-login route determined: $targetRoute');

        SnackbarUtils.showSuccess('Email sign-in successful');
        Get.offAllNamed(targetRoute);
      } else {
        SnackbarUtils.showError('Sign-in failed. Please try again.');
      }

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
        SnackbarUtils.showError('Invalid email or password. Please check your credentials and try again.');
      } else if (errorStr.contains('user-not-found')) {
        SnackbarUtils.showError('No account found with this email address.');
      } else if (errorStr.contains('user-disabled')) {
        SnackbarUtils.showError('This account has been disabled. Please contact support.');
      } else if (errorStr.contains('too-many-requests')) {
        SnackbarUtils.showError('Too many failed login attempts. Please try again later.');
      } else {
        AppLogger.authError('Email sign-in failed', error: e);
        SnackbarUtils.showError('Sign-in failed: ${e.toString()}');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // GOOGLE LOGIN - WITH SMART ROUTING BASED ON USER STATUS
  Future<void> signInWithGoogle({bool forceAccountPicker = false, bool showOwnDialog = true}) async {
    isLoading.value = true;

    // CONDITIONAL DIALOG: Only show dialog if requested
    if (showOwnDialog) {
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
    }

    try {
      AppLogger.auth('🔄 [DEBUG] Starting Google sign-in process...');
      final userCredential = await _authRepository.signInWithGoogle(forceAccountPicker: forceAccountPicker);

      if (userCredential == null || userCredential.user == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppLogger.auth('⚠️ [DEBUG] User cancelled Google sign-in');
        SnackbarUtils.showError('Google sign-in was cancelled');
        return;
      }

      AppLogger.auth('✅ [DEBUG] Google login successful: ${userCredential.user!.uid}');
      await _authRepository.createOrUpdateUser(userCredential.user!);

      // Cache fresh user data for immediate screen access
      await _cacheFreshUserDataAfterLogin(userCredential.user!.uid);

      // 🔍 DETERMINE CORRECT ROUTE BASED ON USER STATUS
      final targetRoute = await _getPostLoginRoute(userCredential.user!);
      AppLogger.auth('🎯 Post-login route determined: $targetRoute');

      SnackbarUtils.showSuccess('Google sign-in successful');
      if (Get.isDialogOpen ?? false) Get.back();
      Get.offAllNamed(targetRoute);

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

  // 🚨 EMERGENCY: Complete Firebase Auth Reset - Use when auth is corrupted
  Future<void> resetAuthCompletely() async {
    AppLogger.auth('🚨 Starting EMERGENCY Auth Reset...');

    try {
      await _authRepository.resetFirebaseAuth();
      AppLogger.auth('✅ Auth reset completed');

      // Clear reactive states
      currentUser.value = null;
      _cachedAuthData = null;

      SnackbarUtils.showSuccess('Authentication reset complete. Try signing in again.');
      Get.offAllNamed('/login');

    } catch (e) {
      AppLogger.authError('Auth reset failed', error: e);
      SnackbarUtils.showError('Reset failed, but try signing in anyway.');
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

  // Simplified - no caching after login, data will be loaded fresh on home screen
  Future<void> _cacheFreshUserDataAfterLogin(String userId) async {
    try {
      AppLogger.auth('🔄 Fresh user data will be loaded on home screen for: $userId');
      // No caching - data will be loaded fresh from Firebase on home screen access
    } catch (e) {
      AppLogger.authError('Note: Fresh user data loading prepared for: $userId', error: e);
      // Don't fail login if preparation fails - home screen will fetch fresh data
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

  // DETERMINE POST-LOGIN ROUTE BASED ON USER STATUS
  Future<String> _getPostLoginRoute(User user) async {
    try {
      AppLogger.auth('🔍 Determining post-login route for user: ${user.uid}');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5), onTimeout: () {
            AppLogger.auth('⏰ User data fetch timeout during post-login routing');
            throw Exception('User data fetch timeout');
          });

      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] ?? '';
        final roleSelected = userData?['roleSelected'] ?? false;
        final profileCompleted = userData?['profileCompleted'] ?? false;

        AppLogger.auth('✅ User status: role="$role", roleSelected=$roleSelected, profileCompleted=$profileCompleted');

        // LEGACY COMPATIBILITY: Fix old users who have role but missing flags
        if (!roleSelected && role.isNotEmpty && (role == 'candidate' || role == 'voter')) {
          AppLogger.auth('🚨 LEGACY USER: Setting flags automatically');
          try {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'roleSelected': true,
              'profileCompleted': true,
            });
            AppLogger.auth('✅ Legacy user flags set successfully');
          } catch (e) {
            AppLogger.authError('Failed to update legacy user flags', error: e);
          }
          return AppRouteNames.home; // LEGACY: Go directly to home since they have role and data
        }

        // CLEAN FLOW: Navigate based on completion status
        if (!roleSelected) {
          AppLogger.auth('🎯 → Role selection screen');
          return AppRouteNames.roleSelection;
        } else if (!profileCompleted) {
          AppLogger.auth('🎯 → Profile completion screen');
          return AppRouteNames.profileCompletion;
        } else {
          AppLogger.auth('🎯 → Home screen (setup complete)');
          return AppRouteNames.home;
        }
      } else {
        // NEW USER: Always start with role selection
        AppLogger.auth('🆕 New user → Role selection screen');
        return AppRouteNames.roleSelection;
      }
    } catch (e) {
      AppLogger.authError('Failed to determine post-login route', error: e);
      // On error, try to use cached routing data as fallback
      final cachedRoute = await _getCachedPostLoginRoute(user.uid);
      if (cachedRoute != null) {
        AppLogger.auth('✨ Using cached route as fallback: $cachedRoute');
        return cachedRoute;
      }
      // Last resort: default to home for existing users to not disrupt experience
      AppLogger.auth('💔 No cached route available, defaulting to home');
      return AppRouteNames.home;
    }
  }

  // Get cached routing data for fallback during post-login
  Future<String?> _getCachedPostLoginRoute(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final routingKey = 'routing_data_$userId';
      final routingData = prefs.getString(routingKey);
      if (routingData != null) {
        final data = jsonDecode(routingData);
        final hasCompletedProfile = data['hasCompletedProfile'] ?? false;
        final hasSelectedRole = data['hasSelectedRole'] ?? false;

        if (hasSelectedRole && hasCompletedProfile) {
          return AppRouteNames.home;
        } else if (hasSelectedRole && !hasCompletedProfile) {
          return AppRouteNames.profileCompletion;
        } else {
          return AppRouteNames.roleSelection;
        }
      }
    } catch (e) {
      AppLogger.auth('⚠️ Failed to get cached post-login route: $e');
    }
    return null;
  }
}
