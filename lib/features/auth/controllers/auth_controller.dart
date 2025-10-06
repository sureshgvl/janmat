import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../../../services/device_service.dart';
import '../../../services/trial_service.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../candidate/controllers/candidate_controller.dart';
import '../../notifications/services/chat_notification_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final DeviceService _deviceService = DeviceService();
  final TrialService _trialService = TrialService();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  RxBool isLoading = false.obs;
  var verificationId = ''.obs;
  var isOTPScreen = false.obs;

  // OTP Timer
  RxInt otpTimer = 60.obs;
  RxBool canResendOTP = false.obs;
  Timer? _otpTimer;

  @override
  void onInit() {
    super.onInit();
    _startDeviceMonitoring();
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    _otpTimer?.cancel();
    super.onClose();
  }

  // Start monitoring device status for multi-device login prevention
  void _startDeviceMonitoring() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _deviceService.monitorDeviceStatus(currentUser.uid, _handleForcedSignOut);
    }
  }

  // Handle forced sign-out when device becomes inactive
  void _handleForcedSignOut() {
    Get.snackbar(
      'Session Expired',
      'You have been signed out because you logged in from another device',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 5),
    );

    // Clear stored Google account info
    _clearStoredGoogleAccount();

    // Sign out and navigate to login
    FirebaseAuth.instance.signOut();
    Get.offAllNamed('/login');
  }

  // Get last used Google account for smart login UX
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    return await _authRepository.getLastGoogleAccount();
  }

  // Clear stored Google account info (on logout)
  Future<void> _clearStoredGoogleAccount() async {
    await _authRepository.clearLastGoogleAccount();
  }

  // Logout method
  Future<void> logout() async {
    try {
      debugPrint('🚪 [AUTH_CONTROLLER] Starting logout process...');

      // Clear stored Google account info
      await _clearStoredGoogleAccount();

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Clear any cached data or controllers if needed
      // Note: GetX controllers will be disposed when navigating to login

      debugPrint('✅ [AUTH_CONTROLLER] Logout completed successfully');

      // Navigate to login screen
      Get.offAllNamed('/login');
      Get.snackbar('Success', 'Logged out successfully');
    } catch (e) {
      debugPrint('❌ [AUTH_CONTROLLER] Logout failed: $e');
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  // Find existing user by phone number in Firestore
  Future<Map<String, dynamic>?> _findExistingUserByPhone(String phoneNumber) async {
    try {
      debugPrint('🔍 [USER_LOOKUP] Searching for user with phone: $phoneNumber');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        userData['uid'] = userDoc.id; // Add the document ID as uid

        debugPrint('✅ [USER_LOOKUP] Found existing user: ${userDoc.id}');
        return userData;
      }

      debugPrint('ℹ️ [USER_LOOKUP] No existing user found with phone: $phoneNumber');
      return null;
    } catch (e) {
      debugPrint('❌ [USER_LOOKUP] Error finding user by phone: $e');
      return null;
    }
  }

  // Find existing user by email in Firestore
  Future<Map<String, dynamic>?> _findExistingUserByEmail(String email) async {
    try {
      debugPrint('🔍 [USER_LOOKUP] Searching for user with email: $email');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        userData['uid'] = userDoc.id; // Add the document ID as uid

        debugPrint('✅ [USER_LOOKUP] Found existing user: ${userDoc.id}');
        return userData;
      }

      debugPrint('ℹ️ [USER_LOOKUP] No existing user found with email: $email');
      return null;
    } catch (e) {
      debugPrint('❌ [USER_LOOKUP] Error finding user by email: $e');
      return null;
    }
  }

  // Link Firebase Auth user to existing Firestore user profile
  Future<void> _linkFirebaseUserToExistingProfile(User firebaseUser, Map<String, dynamic> existingUserData) async {
    try {
      debugPrint('🔗 [USER_LINKING] Linking Firebase user ${firebaseUser.uid} to existing profile ${existingUserData['uid']}');

      final existingUserId = existingUserData['uid'];

      // Update the existing user document to include the Firebase Auth UID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(existingUserId)
          .update({
            'firebaseAuthUid': firebaseUser.uid,
            'lastLogin': FieldValue.serverTimestamp(),
            'loginCount': FieldValue.increment(1),
          });

      // Optionally, you could also store a mapping from Firebase Auth UID to the main user ID
      // This can help with future lookups
      await FirebaseFirestore.instance
          .collection('user_mappings')
          .doc(firebaseUser.uid)
          .set({
            'primaryUserId': existingUserId,
            'linkedAt': FieldValue.serverTimestamp(),
            'linkType': 'phone_number',
          });

      debugPrint('✅ [USER_LINKING] Successfully linked Firebase user to existing profile');

    } catch (e) {
      debugPrint('❌ [USER_LINKING] Error linking user profiles: $e');
      rethrow;
    }
  }

  Future<void> sendOTP() async {
    debugPrint('🎯 sendOTP() method called in LoginController');
    if (phoneController.text.isEmpty || phoneController.text.length != 10) {
      debugPrint('❌ Invalid phone number: ${phoneController.text}');
      Get.snackbar('Error', 'Please enter a valid 10-digit phone number');
      return;
    }

    debugPrint('SendOTP called with phone: ${phoneController.text}');
    isLoading.value = true;
    debugPrint('isLoading set to: ${isLoading.value}');

    try {
      debugPrint('📞 Starting phone verification...');
      await _authRepository.verifyPhoneNumber(phoneController.text, (
        String vid,
      ) {
        debugPrint('📱 Phone verification callback received with verificationId: $vid');
        verificationId.value = vid;
        isOTPScreen.value = true;
        _startOTPTimer(); // Start the OTP timer

        // Close loading dialog when OTP screen is ready
        if (Get.isDialogOpen ?? false) {
          Get.back();
          debugPrint('📤 LoadingDialog dismissed - OTP screen ready');
        }

        Get.snackbar('Success', 'OTP sent to +91${phoneController.text}');
        debugPrint('✅ OTP screen activated, timer started');
      }).timeout(
        const Duration(seconds: 120), // Increased timeout for reCAPTCHA completion
        onTimeout: () {
          debugPrint('⏰ SendOTP timed out after 120 seconds');
          // Close loading dialog on timeout
          if (Get.isDialogOpen ?? false) {
            Get.back();
            debugPrint('📤 LoadingDialog dismissed due to timeout');
          }
          throw Exception('Phone verification timed out. If a browser opened for verification, please complete it and try again.');
        },
      );
      debugPrint('📞 Phone verification request completed');
    } catch (e) {
      debugPrint('❌ SendOTP failed: $e');
      // Close loading dialog on error
      if (Get.isDialogOpen ?? false) {
        Get.back();
        debugPrint('📤 LoadingDialog dismissed due to error');
      }
      // Provide more helpful error messages for common Firebase issues
      String errorMessage = 'Failed to send OTP';
      String userGuidance = '';

      if (e.toString().contains('blocked all requests') ||
          e.toString().contains('unusual activity')) {
        errorMessage = 'Too Many Attempts';
        userGuidance = 'Please wait a few minutes before trying again. This is a security measure to prevent spam.';
      } else if (e.toString().contains('invalid-phone-number')) {
        errorMessage = 'Invalid Phone Number';
        userGuidance = 'Please check your phone number and try again.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too Many Requests';
        userGuidance = 'Please wait before trying again.';
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorMessage = 'Network Error';
        userGuidance = 'Please check your internet connection and try again.';
      }

      if (userGuidance.isNotEmpty) {
        Get.snackbar(
          errorMessage,
          userGuidance,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
      } else {
        Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
      }
      rethrow; // Re-throw to be caught by the UI layer
    } finally {
      // Add a small delay to ensure loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
      debugPrint('isLoading reset to: ${isLoading.value}');
    }
  }

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
      return;
    }

    isLoading.value = true;
    try {
      debugPrint('🔐 [OTP_VERIFY] Starting OTP verification...');

      // Step 1: Authenticate with Firebase using phone number
      debugPrint('📱 [OTP_VERIFY] Authenticating with Firebase Auth...');
      final userCredential = await _authRepository.signInWithOTP(
        verificationId.value,
        otpController.text,
      );
      debugPrint('✅ [OTP_VERIFY] Firebase Auth successful for user: ${userCredential.user!.uid}');

      // Step 2: Check if user already exists in Firestore by phone number
      debugPrint('🔍 [OTP_VERIFY] Checking for existing user profile by phone number...');
      final phoneNumber = '+91${phoneController.text}';
      final existingUser = await _findExistingUserByPhone(phoneNumber);

      if (existingUser != null) {
        debugPrint('✅ [OTP_VERIFY] Found existing user profile: ${existingUser['uid']}');

        // Link the Firebase Auth user to the existing Firestore profile
        debugPrint('🔗 [OTP_VERIFY] Linking Firebase Auth user to existing profile...');
        await _linkFirebaseUserToExistingProfile(userCredential.user!, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        debugPrint('✅ [OTP_VERIFY] Successfully linked to existing user: $existingUserId');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          debugPrint('✅ [OTP_VERIFY] Device registered for existing user');
        } catch (e) {
          debugPrint('⚠️ [OTP_VERIFY] Device registration failed (non-critical): $e');
        }

        Get.snackbar('Success', 'Login successful');
        await _navigateBasedOnProfileCompletionForExistingUser(existingUser);
      } else {
        debugPrint('ℹ️ [OTP_VERIFY] No existing user found, creating new profile...');

        // Create new user profile
        await _authRepository.createOrUpdateUser(userCredential.user!);

        // Register device for new user
        try {
          await _deviceService.registerDevice(userCredential.user!.uid);
          debugPrint('✅ [OTP_VERIFY] Device registered for new user');
        } catch (e) {
          debugPrint('⚠️ [OTP_VERIFY] Device registration failed (non-critical): $e');
        }

        Get.snackbar('Success', 'Login successful');
        await _navigateBasedOnProfileCompletion(userCredential.user!);
      }

    } catch (e) {
      debugPrint('❌ [OTP_VERIFY] OTP verification failed: $e');
      Get.snackbar('Error', 'Invalid OTP: ${e.toString()}');
    } finally {
      // Add a small delay to ensure loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }


  Future<void> signInWithGoogle({bool forceAccountPicker = false}) async {
    final controllerStartTime = DateTime.now();
    debugPrint('🚀 [AUTH_CONTROLLER] Starting Google Sign-In process (${forceAccountPicker ? 'forced account picker' : 'smart mode'}) at ${controllerStartTime.toIso8601String()}');

    // Show prominent loading dialog immediately
    _showGoogleSignInLoadingDialog();
    debugPrint('📱 [AUTH_CONTROLLER] Loading dialog displayed');

    try {
      // Step 1: Google authentication with smart account switching
      debugPrint('🔐 [AUTH_CONTROLLER] Calling repository signInWithGoogle...');
      final repoStartTime = DateTime.now();
      final userCredential = await _authRepository.signInWithGoogle(forceAccountPicker: forceAccountPicker);
      final repoDuration = DateTime.now().difference(repoStartTime);
      debugPrint('✅ [AUTH_CONTROLLER] Repository signInWithGoogle completed in ${repoDuration.inSeconds}s');

      // Handle cancelled sign-in or timeout with successful auth
      if (userCredential == null) {
        debugPrint('⚠️ [AUTH_CONTROLLER] Repository returned null UserCredential');
        // Check if authentication actually succeeded despite returning null
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint('✅ [AUTH_CONTROLLER] Authentication succeeded despite null credential, proceeding with current user: ${currentUser.uid}');
          await _handleSuccessfulAuthenticationWithCurrentUser(currentUser);
          final totalDuration = DateTime.now().difference(controllerStartTime);
          debugPrint('🎉 [AUTH_CONTROLLER] Google Sign-In completed successfully (recovery path) in ${totalDuration.inSeconds}s');
          return;
        } else {
          debugPrint('❌ [AUTH_CONTROLLER] No authenticated user found, sign-in was cancelled');
          _hideGoogleSignInLoadingDialog();
          Get.snackbar("Cancelled", "Google sign-in was cancelled");
          final totalDuration = DateTime.now().difference(controllerStartTime);
          debugPrint('❌ [AUTH_CONTROLLER] Google Sign-In cancelled after ${totalDuration.inSeconds}s');
          return;
        }
      }
      if (userCredential.user == null) {
        debugPrint('❌ [AUTH_CONTROLLER] UserCredential exists but user is null');
        _hideGoogleSignInLoadingDialog();
        Get.snackbar("Error", "Google sign-in failed: No user returned");
        final totalDuration = DateTime.now().difference(controllerStartTime);
        debugPrint('❌ [AUTH_CONTROLLER] Google Sign-In failed (no user) after ${totalDuration.inSeconds}s');
        return;
      }

      debugPrint('✅ [AUTH_CONTROLLER] Valid user obtained: ${userCredential.user!.uid} (${userCredential.user!.email})');

      // Step 2: Check if user already exists in Firestore by email
      debugPrint('🔍 [GOOGLE_VERIFY] Checking for existing user profile by email...');
      final existingUser = await _findExistingUserByEmail(userCredential.user!.email!);

      if (existingUser != null) {
        debugPrint('✅ [GOOGLE_VERIFY] Found existing user profile: ${existingUser['uid']}');

        // Link the Firebase Auth user to the existing Firestore profile
        debugPrint('🔗 [GOOGLE_VERIFY] Linking Firebase Auth user to existing profile...');
        await _linkFirebaseUserToExistingProfile(userCredential.user!, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        debugPrint('✅ [GOOGLE_VERIFY] Successfully linked to existing user: $existingUserId');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          debugPrint('✅ [GOOGLE_VERIFY] Device registered for existing user');
        } catch (e) {
          debugPrint('⚠️ [GOOGLE_VERIFY] Device registration failed (non-critical): $e');
        }

        Get.snackbar('Success', 'Google sign-in successful');
        await _navigateBasedOnProfileCompletionForExistingUser(existingUser);
        return;
      }

      // No existing user found, proceed with normal flow
      await _handleSuccessfulAuthentication(userCredential);

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Creating your profile...');

      // Step 3: Keep loading while creating/updating user profile
      debugPrint('👤 [AUTH_CONTROLLER] Creating/updating user profile...');
      final profileStart = DateTime.now();
      await _authRepository.createOrUpdateUser(userCredential.user!);
      final profileDuration = DateTime.now().difference(profileStart);
      debugPrint('✅ [AUTH_CONTROLLER] User profile updated in ${profileDuration.inMilliseconds}ms');

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Setting up your account...');

      // Step 4: Keep loading while registering device
      debugPrint('📱 [AUTH_CONTROLLER] Registering device...');
      final deviceStart = DateTime.now();
      try {
        await _deviceService.registerDevice(userCredential.user!.uid);
        final deviceDuration = DateTime.now().difference(deviceStart);
        debugPrint('✅ [AUTH_CONTROLLER] Device registered in ${deviceDuration.inMilliseconds}ms');
      } catch (e) {
        final deviceDuration = DateTime.now().difference(deviceStart);
        debugPrint('⚠️ [AUTH_CONTROLLER] Device registration failed after ${deviceDuration.inMilliseconds}ms (non-critical): $e');
        // Don't throw here - device registration failure shouldn't block sign-in
        // The user can still use the app, just without device management features
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Almost ready...');

      // Step 5: Show success and navigate
      Get.snackbar('Success', 'Google sign-in successful');
      debugPrint('🍪 [AUTH_CONTROLLER] Success snackbar displayed');

      debugPrint('🏠 [AUTH_CONTROLLER] Checking profile completion and navigating...');
      final navStart = DateTime.now();
      await _navigateBasedOnProfileCompletion(userCredential.user!);
      final navDuration = DateTime.now().difference(navStart);
      debugPrint('✅ [AUTH_CONTROLLER] Navigation completed in ${navDuration.inMilliseconds}ms');
    } catch (e) {
      final totalDuration = DateTime.now().difference(controllerStartTime);
      debugPrint('❌ [AUTH_CONTROLLER] Google sign-in failed after ${totalDuration.inSeconds}s: $e');
      debugPrint('❌ [AUTH_CONTROLLER] Error type: ${e.runtimeType}');
      _hideGoogleSignInLoadingDialog();
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog();
      final totalDuration = DateTime.now().difference(controllerStartTime);
      debugPrint('🏁 [AUTH_CONTROLLER] Google sign-in process completed in ${totalDuration.inSeconds}s');
    }
  }

  void goBackToPhoneInput() {
    isOTPScreen.value = false;
    otpController.clear();
    _stopOTPTimer();
  }

  // OTP Timer Methods
  void _startOTPTimer() {
    _stopOTPTimer(); // Cancel any existing timer
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

  Future<void> resendOTP() async {
    if (!canResendOTP.value) return;

    await sendOTP();
  }

  // Google Sign-In Loading Dialog Methods
  void _showGoogleSignInLoadingDialog() {
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Signing in with Google...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your Google account',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       Get.back();
        //       Get.snackbar('Cancelled', 'Google sign-in was cancelled');
        //     },
        //     child: const Text('Cancel'),
        //   ),
        // ],
      ),
      barrierDismissible: false,
    );
  }

  void _updateGoogleSignInLoadingDialog(String message) {
    if (Get.isDialogOpen ?? false) {
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  void _hideGoogleSignInLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  // Handle successful authentication flow
  Future<void> _handleSuccessfulAuthentication(
    UserCredential userCredential,
  ) async {
    // Update loading dialog message
    _updateGoogleSignInLoadingDialog('Creating your profile...');

    // Step 2: Keep loading while creating/updating user profile
    debugPrint('👤 Creating/updating user profile...');
    await _authRepository.createOrUpdateUser(userCredential.user!);
    debugPrint('✅ User profile updated');

    // Update loading dialog message
    _updateGoogleSignInLoadingDialog('Setting up your account...');

    // Step 3: Keep loading while registering device
    debugPrint('📱 Registering device...');
    try {
      await _deviceService.registerDevice(userCredential.user!.uid);
      debugPrint('✅ Device registered');
    } catch (e) {
      debugPrint('⚠️ Device registration failed (non-critical): $e');
      // Don't throw here - device registration failure shouldn't block sign-in
    }

    // Update loading dialog message
    _updateGoogleSignInLoadingDialog('Almost ready...');

    // Step 4: Show success and navigate
    Get.snackbar('Success', 'Google sign-in successful');

    debugPrint('🏠 Checking profile completion and navigating...');
    await _navigateBasedOnProfileCompletion(userCredential.user!);
  }

  // Handle successful authentication when userCredential is null but user is authenticated
  Future<void> _handleSuccessfulAuthenticationWithCurrentUser(User user) async {
    try {
      // Check if user already exists in Firestore by email
      debugPrint('🔍 [GOOGLE_VERIFY_RECOVERY] Checking for existing user profile by email...');
      final existingUser = await _findExistingUserByEmail(user.email!);

      if (existingUser != null) {
        debugPrint('✅ [GOOGLE_VERIFY_RECOVERY] Found existing user profile: ${existingUser['uid']}');

        // Link the Firebase Auth user to the existing Firestore profile
        debugPrint('🔗 [GOOGLE_VERIFY_RECOVERY] Linking Firebase Auth user to existing profile...');
        await _linkFirebaseUserToExistingProfile(user, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        debugPrint('✅ [GOOGLE_VERIFY_RECOVERY] Successfully linked to existing user: $existingUserId');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          debugPrint('✅ [GOOGLE_VERIFY_RECOVERY] Device registered for existing user');
        } catch (e) {
          debugPrint('⚠️ [GOOGLE_VERIFY_RECOVERY] Device registration failed (non-critical): $e');
        }

        Get.snackbar('Success', 'Google sign-in successful');
        await _navigateBasedOnProfileCompletionForExistingUser(existingUser);
        return;
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Creating your profile...');

      // Step 2: Keep loading while creating/updating user profile
      debugPrint('👤 Creating/updating user profile...');
      await _authRepository.createOrUpdateUser(user);
      debugPrint('✅ User profile updated');

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Setting up your account...');

      // Step 3: Keep loading while registering device
      debugPrint('📱 Registering device...');
      try {
        await _deviceService.registerDevice(user.uid);
        debugPrint('✅ Device registered');
      } catch (e) {
        debugPrint('⚠️ Device registration failed (non-critical): $e');
        // Don't throw here - device registration failure shouldn't block sign-in
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Almost ready...');

      // Step 4: Show success and navigate
      Get.snackbar('Success', 'Google sign-in successful');

      debugPrint('🏠 Checking profile completion and navigating...');
      await _navigateBasedOnProfileCompletion(user);
    } catch (e) {
      debugPrint('❌ Error in successful authentication flow: $e');
      _hideGoogleSignInLoadingDialog();
      Get.snackbar(
        'Error',
        'Failed to complete sign-in setup: ${e.toString()}',
      );
    }
  }

  // Navigation method for existing users (when logging in with phone that matches existing profile)
  Future<void> _navigateBasedOnProfileCompletionForExistingUser(Map<String, dynamic> userData) async {
    try {
      final userId = userData['uid'];
      debugPrint('🔍 [EXISTING_USER_NAV] Checking profile completion for existing user: $userId');

      final profileCompleted = userData['profileCompleted'] ?? false;
      final roleSelected = userData['roleSelected'] ?? false;

      debugPrint('📋 [EXISTING_USER_NAV] Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted');

      // Clean up expired trials on login
      debugPrint('🧹 [EXISTING_USER_NAV] Starting trial cleanup...');
      try {
        await _trialService.cleanupExpiredTrials(userId);
        debugPrint('✅ [EXISTING_USER_NAV] Trial cleanup completed');
      } catch (e) {
        debugPrint('⚠️ [EXISTING_USER_NAV] Trial cleanup failed: $e');
      }

      if (!roleSelected) {
        debugPrint('🎭 [EXISTING_USER_NAV] Role not selected, navigating to role selection...');
        Get.offAllNamed('/role-selection');
        return;
      }

      if (!profileCompleted) {
        debugPrint('📝 [EXISTING_USER_NAV] Profile not completed, navigating to profile completion...');
        Get.offAllNamed('/profile-completion');
        return;
      }

      // Profile is complete and role is selected, go to home
      debugPrint('🏠 [EXISTING_USER_NAV] Profile complete, preparing to navigate to home...');

      // Ensure controllers are initialized for the existing user session
      if (!Get.isRegistered<ChatController>()) {
        debugPrint('🔧 [EXISTING_USER_NAV] Initializing ChatController...');
        Get.put<ChatController>(ChatController());
        debugPrint('✅ [EXISTING_USER_NAV] ChatController recreated for existing user session');
      } else {
        debugPrint('ℹ️ [EXISTING_USER_NAV] ChatController already registered');
      }

      // Ensure CandidateController is initialized
      if (!Get.isRegistered<CandidateController>()) {
        debugPrint('🔧 [EXISTING_USER_NAV] Initializing CandidateController...');
        Get.put<CandidateController>(CandidateController());
        debugPrint('✅ [EXISTING_USER_NAV] CandidateController recreated for existing user session');
      } else {
        debugPrint('ℹ️ [EXISTING_USER_NAV] CandidateController already registered');
      }

      // Initialize Chat Notification Service
      debugPrint('🔔 [EXISTING_USER_NAV] Initializing Chat Notification Service...');
      try {
        final chatNotificationService = ChatNotificationService();
        final userLocation = {
          'stateId': userData['stateId'],
          'districtId': userData['districtId'],
          'bodyId': userData['bodyId'],
          'wardId': userData['wardId'],
          'area': userData['area'],
        };
        await chatNotificationService.initialize(
          userId: userId,
          userRole: userData['role'] ?? 'voter',
          userLocation: userLocation,
        );
        debugPrint('✅ [EXISTING_USER_NAV] Chat Notification Service initialized');
      } catch (e) {
        debugPrint('⚠️ [EXISTING_USER_NAV] Chat Notification Service initialization failed: $e');
      }

      debugPrint('🏠 [EXISTING_USER_NAV] Navigating to home screen...');
      Get.offAllNamed('/home');
      debugPrint('✅ [EXISTING_USER_NAV] Navigation to home completed');

    } catch (e) {
      debugPrint('❌ [EXISTING_USER_NAV] Error during profile check: $e');
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    } finally {
      // Ensure loading state is cleared after navigation
      debugPrint('✅ [EXISTING_USER_NAV] Navigation completed, clearing loading state');
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog(); // Ensure dialog is closed
    }
  }

  Future<void> _navigateBasedOnProfileCompletion(User user) async {
    try {
      debugPrint('🔍 [AUTH_CONTROLLER] Checking user profile completion for ${user.uid}...');

      // Check if user profile is complete
      debugPrint('📄 [AUTH_CONTROLLER] Fetching user document from Firestore...');
      final docStart = DateTime.now();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final docDuration = DateTime.now().difference(docStart);
      debugPrint('📄 [AUTH_CONTROLLER] User document fetched in ${docDuration.inMilliseconds}ms - Exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;
        final roleSelected = userData?['roleSelected'] ?? false;

        debugPrint('📋 [AUTH_CONTROLLER] Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted');

        // Clean up expired trials on login
        debugPrint('🧹 [AUTH_CONTROLLER] Starting trial cleanup...');
        final trialStart = DateTime.now();
        try {
          await _trialService.cleanupExpiredTrials(user.uid);
          final trialDuration = DateTime.now().difference(trialStart);
          debugPrint('✅ [AUTH_CONTROLLER] Trial cleanup completed in ${trialDuration.inMilliseconds}ms');
        } catch (e) {
          final trialDuration = DateTime.now().difference(trialStart);
          debugPrint('⚠️ [AUTH_CONTROLLER] Trial cleanup failed after ${trialDuration.inMilliseconds}ms: $e');
        }

        if (!roleSelected) {
          debugPrint('🎭 [AUTH_CONTROLLER] Role not selected, navigating to role selection...');
          Get.offAllNamed('/role-selection');
          return;
        }

        if (!profileCompleted) {
          debugPrint('📝 [AUTH_CONTROLLER] Profile not completed, navigating to profile completion...');
          Get.offAllNamed('/profile-completion');
          return;
        }

        debugPrint('✅ [AUTH_CONTROLLER] Profile complete and role selected');

        // Initialize Chat Notification Service
        debugPrint('🔔 [AUTH_CONTROLLER] Initializing Chat Notification Service...');
        try {
          final chatNotificationService = ChatNotificationService();
          final userLocation = {
            'stateId': userData?['stateId'],
            'districtId': userData?['districtId'],
            'bodyId': userData?['bodyId'],
            'wardId': userData?['wardId'],
            'area': userData?['area'],
          };
          await chatNotificationService.initialize(
            userId: user.uid,
            userRole: userData?['role'] ?? 'voter',
            userLocation: userLocation,
          );
          debugPrint('✅ [AUTH_CONTROLLER] Chat Notification Service initialized');
        } catch (e) {
          debugPrint('⚠️ [AUTH_CONTROLLER] Chat Notification Service initialization failed: $e');
        }
      } else {
        // User document doesn't exist, need role selection first
        debugPrint('📄 [AUTH_CONTROLLER] User document not found, navigating to role selection...');
        Get.offAllNamed('/role-selection');
        return;
      }

      // Profile is complete and role is selected, go to home
      debugPrint('🏠 [AUTH_CONTROLLER] Profile complete, preparing to navigate to home...');

      // Ensure controllers are initialized for the new user session
      if (!Get.isRegistered<ChatController>()) {
        debugPrint('🔧 [AUTH_CONTROLLER] Initializing ChatController...');
        Get.put<ChatController>(ChatController());
        debugPrint('✅ [AUTH_CONTROLLER] ChatController recreated for new user session');
      } else {
        debugPrint('ℹ️ [AUTH_CONTROLLER] ChatController already registered');
      }

      // Ensure CandidateController is initialized
      if (!Get.isRegistered<CandidateController>()) {
        debugPrint('🔧 [AUTH_CONTROLLER] Initializing CandidateController...');
        Get.put<CandidateController>(CandidateController());
        debugPrint('✅ [AUTH_CONTROLLER] CandidateController recreated for new user session');
      } else {
        debugPrint('ℹ️ [AUTH_CONTROLLER] CandidateController already registered');
      }

      debugPrint('🏠 [AUTH_CONTROLLER] Navigating to home screen...');
      Get.offAllNamed('/home');
      debugPrint('✅ [AUTH_CONTROLLER] Navigation to home completed');
    } catch (e) {
      debugPrint('❌ [AUTH_CONTROLLER] Error during profile check: $e');
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    } finally {
      // Ensure loading state is cleared after navigation
      debugPrint('✅ [AUTH_CONTROLLER] Navigation completed, clearing loading state');
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog(); // Ensure dialog is closed
    }
  }
}

