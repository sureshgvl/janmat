import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../../../services/device_service.dart';
import '../../../services/trial_service.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../candidate/controllers/candidate_controller.dart';
import '../../notifications/services/chat_notification_service.dart';
import '../../../utils/app_logger.dart';

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

  // Helper method to extract location data from UserModel
  Map<String, dynamic> _extractUserLocation(UserModel userModel) {
    return {
      'stateId': userModel.stateId,
      'districtId': userModel.districtId,
      'bodyId': userModel.bodyId,
      'wardId': userModel.wardId,
      'area': userModel.area,
    };
  }

  // Logout method
  Future<void> logout() async {
    try {
      AppLogger.auth('Starting logout process', tag: 'AuthController');

      // Clear stored Google account info
      await _clearStoredGoogleAccount();

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Clear any cached data or controllers if needed
      // Note: GetX controllers will be disposed when navigating to login

      AppLogger.auth('Logout completed successfully', tag: 'AuthController');

      // Navigate to login screen
      Get.offAllNamed('/login');
      Get.snackbar('Success', 'Logged out successfully');
    } catch (e) {
      AppLogger.authError('Logout failed', tag: 'AuthController', error: e);
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }

  // Find existing user by phone number in Firestore
  Future<Map<String, dynamic>?> _findExistingUserByPhone(String phoneNumber) async {
    try {
      AppLogger.auth('Searching for user with phone: $phoneNumber', tag: 'USER_LOOKUP');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        userData['uid'] = userDoc.id; // Add the document ID as uid

        AppLogger.auth('Found existing user: ${userDoc.id}', tag: 'USER_LOOKUP');
        return userData;
      }

      AppLogger.auth('No existing user found with phone: $phoneNumber', tag: 'USER_LOOKUP');
      return null;
    } catch (e) {
      AppLogger.authError('Error finding user by phone', tag: 'USER_LOOKUP', error: e);
      return null;
    }
  }

  // Find existing user by email in Firestore
  Future<Map<String, dynamic>?> _findExistingUserByEmail(String email) async {
    try {
      AppLogger.auth('Searching for user with email: $email', tag: 'USER_LOOKUP');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        userData['uid'] = userDoc.id; // Add the document ID as uid

        AppLogger.auth('Found existing user: ${userDoc.id}', tag: 'USER_LOOKUP');
        return userData;
      }

      AppLogger.auth('No existing user found with email: $email', tag: 'USER_LOOKUP');
      return null;
    } catch (e) {
      AppLogger.authError('Error finding user by email', tag: 'USER_LOOKUP', error: e);
      return null;
    }
  }

  // Link Firebase Auth user to existing Firestore user profile
  Future<void> _linkFirebaseUserToExistingProfile(User firebaseUser, Map<String, dynamic> existingUserData) async {
    try {
      AppLogger.auth('Linking Firebase user ${firebaseUser.uid} to existing profile ${existingUserData['uid']}', tag: 'USER_LINKING');

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

      AppLogger.auth('Successfully linked Firebase user to existing profile', tag: 'USER_LINKING');

    } catch (e) {
      AppLogger.authError('Error linking user profiles', tag: 'USER_LINKING', error: e);
      rethrow;
    }
  }

  Future<void> sendOTP() async {
    AppLogger.auth('sendOTP() method called', tag: 'AuthController');
    if (phoneController.text.isEmpty || phoneController.text.length != 10) {
      AppLogger.auth('Invalid phone number: ${phoneController.text}', tag: 'AuthController');
      Get.snackbar('Error', 'Please enter a valid 10-digit phone number');
      return;
    }

    AppLogger.auth('SendOTP called with phone: ${phoneController.text}', tag: 'AuthController');
    isLoading.value = true;
    AppLogger.auth('isLoading set to: ${isLoading.value}', tag: 'AuthController');

    try {
      AppLogger.auth('Starting phone verification', tag: 'AuthController');
      await _authRepository.verifyPhoneNumber(phoneController.text, (
        String vid,
      ) {
        AppLogger.auth('Phone verification callback received with verificationId: $vid', tag: 'AuthController');
        verificationId.value = vid;
        isOTPScreen.value = true;
        _startOTPTimer(); // Start the OTP timer

        // Close loading dialog when OTP screen is ready
        if (Get.isDialogOpen ?? false) {
          Get.back();
          AppLogger.auth('LoadingDialog dismissed - OTP screen ready', tag: 'AuthController');
        }

        Get.snackbar('Success', 'OTP sent to +91${phoneController.text}');
        AppLogger.auth('OTP screen activated, timer started', tag: 'AuthController');
      }).timeout(
        const Duration(seconds: 120), // Increased timeout for reCAPTCHA completion
        onTimeout: () {
          AppLogger.auth('SendOTP timed out after 120 seconds', tag: 'AuthController');
          // Close loading dialog on timeout
          if (Get.isDialogOpen ?? false) {
            Get.back();
            AppLogger.auth('LoadingDialog dismissed due to timeout', tag: 'AuthController');
          }
          throw Exception('Phone verification timed out. If a browser opened for verification, please complete it and try again.');
        },
      );
      AppLogger.auth('Phone verification request completed', tag: 'AuthController');
    } catch (e) {
      AppLogger.authError('SendOTP failed', tag: 'AuthController', error: e);
      // Close loading dialog on error
      if (Get.isDialogOpen ?? false) {
        Get.back();
        AppLogger.auth('LoadingDialog dismissed due to error', tag: 'AuthController');
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
      AppLogger.auth('isLoading reset to: ${isLoading.value}', tag: 'AUTH_CONTROLLER');
    }
  }

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
      return;
    }

    isLoading.value = true;
    try {
      AppLogger.auth('Starting OTP verification', tag: 'OTP_VERIFY');

      // Step 1: Authenticate with Firebase using phone number
      AppLogger.auth('Authenticating with Firebase Auth', tag: 'OTP_VERIFY');
      final userCredential = await _authRepository.signInWithOTP(
        verificationId.value,
        otpController.text,
      );
      AppLogger.auth('Firebase Auth successful for user: ${userCredential.user!.uid}', tag: 'OTP_VERIFY');

      // Step 2: Check if user already exists in Firestore by phone number
      AppLogger.auth('Checking for existing user profile by phone number', tag: 'OTP_VERIFY');
      final phoneNumber = '+91${phoneController.text}';
      final existingUser = await _findExistingUserByPhone(phoneNumber);

      if (existingUser != null) {
        AppLogger.auth('Found existing user profile: ${existingUser['uid']}', tag: 'OTP_VERIFY');

        // Link the Firebase Auth user to the existing Firestore profile
        AppLogger.auth('Linking Firebase Auth user to existing profile', tag: 'OTP_VERIFY');
        await _linkFirebaseUserToExistingProfile(userCredential.user!, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        AppLogger.auth('Successfully linked to existing user: $existingUserId', tag: 'OTP_VERIFY');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          AppLogger.auth('Device registered for existing user', tag: 'OTP_VERIFY');
        } catch (e) {
          AppLogger.auth('Device registration failed (non-critical): $e', tag: 'OTP_VERIFY');
        }

        Get.snackbar('Success', 'Login successful');
        await _navigateBasedOnProfileCompletionForExistingUser(existingUser);
      } else {
        AppLogger.auth('No existing user found, creating new profile', tag: 'OTP_VERIFY');

        // Create new user profile
        await _authRepository.createOrUpdateUser(userCredential.user!);

        // Register device for new user
        try {
          await _deviceService.registerDevice(userCredential.user!.uid);
          AppLogger.auth('Device registered for new user', tag: 'OTP_VERIFY');
        } catch (e) {
          AppLogger.auth('Device registration failed (non-critical): $e', tag: 'OTP_VERIFY');
        }

        Get.snackbar('Success', 'Login successful');
        await _navigateBasedOnProfileCompletion(userCredential.user!);
      }

    } catch (e) {
      AppLogger.authError('OTP verification failed', tag: 'OTP_VERIFY', error: e);
      Get.snackbar('Error', 'Invalid OTP: ${e.toString()}');
    } finally {
      // Add a small delay to ensure loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }


  Future<void> signInWithGoogle({bool forceAccountPicker = false}) async {
    final controllerStartTime = DateTime.now();
    AppLogger.auth('Starting Google Sign-In process (${forceAccountPicker ? 'forced account picker' : 'smart mode'})', tag: 'AUTH_CONTROLLER');

    // Show prominent loading dialog immediately
    _showGoogleSignInLoadingDialog();
    AppLogger.auth('Loading dialog displayed', tag: 'AUTH_CONTROLLER');

    try {
      // Step 1: Google authentication with smart account switching
      AppLogger.auth('Calling repository signInWithGoogle', tag: 'AUTH_CONTROLLER');
      final repoStartTime = DateTime.now();
      final userCredential = await _authRepository.signInWithGoogle(forceAccountPicker: forceAccountPicker);
      final repoDuration = DateTime.now().difference(repoStartTime);
      AppLogger.auth('Repository signInWithGoogle completed in ${repoDuration.inSeconds}s', tag: 'AUTH_CONTROLLER');

      // Handle cancelled sign-in or timeout with successful auth
      if (userCredential == null) {
        AppLogger.auth('Repository returned null UserCredential', tag: 'AUTH_CONTROLLER');
        // Check if authentication actually succeeded despite returning null
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          AppLogger.auth('Authentication succeeded despite null credential, proceeding with current user: ${currentUser.uid}', tag: 'AUTH_CONTROLLER');
          await _handleSuccessfulAuthenticationWithCurrentUser(currentUser);
          final totalDuration = DateTime.now().difference(controllerStartTime);
          AppLogger.auth('Google Sign-In completed successfully (recovery path) in ${totalDuration.inSeconds}s', tag: 'AUTH_CONTROLLER');
          return;
        } else {
          AppLogger.auth('No authenticated user found, sign-in was cancelled', tag: 'AUTH_CONTROLLER');
          _hideGoogleSignInLoadingDialog();
          Get.snackbar("Cancelled", "Google sign-in was cancelled");
          final totalDuration = DateTime.now().difference(controllerStartTime);
          AppLogger.auth('Google Sign-In cancelled after ${totalDuration.inSeconds}s', tag: 'AUTH_CONTROLLER');
          return;
        }
      }
      if (userCredential.user == null) {
        AppLogger.auth('UserCredential exists but user is null', tag: 'AUTH_CONTROLLER');
        _hideGoogleSignInLoadingDialog();
        Get.snackbar("Error", "Google sign-in failed: No user returned");
        final totalDuration = DateTime.now().difference(controllerStartTime);
        AppLogger.auth('Google Sign-In failed (no user) after ${totalDuration.inSeconds}s', tag: 'AUTH_CONTROLLER');
        return;
      }

      AppLogger.auth('Valid user obtained: ${userCredential.user!.uid} (${userCredential.user!.email})', tag: 'AUTH_CONTROLLER');

      // Step 2: Check if user already exists in Firestore by email
      AppLogger.auth('Checking for existing user profile by email', tag: 'GOOGLE_VERIFY');
      final existingUser = await _findExistingUserByEmail(userCredential.user!.email!);

      if (existingUser != null) {
        AppLogger.auth('Found existing user profile: ${existingUser['uid']}', tag: 'GOOGLE_VERIFY');

        // Link the Firebase Auth user to the existing Firestore profile
        AppLogger.auth('Linking Firebase Auth user to existing profile', tag: 'GOOGLE_VERIFY');
        await _linkFirebaseUserToExistingProfile(userCredential.user!, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        AppLogger.auth('Successfully linked to existing user: $existingUserId', tag: 'GOOGLE_VERIFY');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          AppLogger.auth('Device registered for existing user', tag: 'GOOGLE_VERIFY');
        } catch (e) {
          AppLogger.auth('Device registration failed (non-critical): $e', tag: 'GOOGLE_VERIFY');
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
      AppLogger.auth('Creating/updating user profile', tag: 'AUTH_CONTROLLER');
      final profileStart = DateTime.now();
      await _authRepository.createOrUpdateUser(userCredential.user!);
      final profileDuration = DateTime.now().difference(profileStart);
      AppLogger.auth('User profile updated in ${profileDuration.inMilliseconds}ms', tag: 'AUTH_CONTROLLER');

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Setting up your account...');

      // Step 4: Keep loading while registering device
      AppLogger.auth('Registering device', tag: 'AUTH_CONTROLLER');
      final deviceStart = DateTime.now();
      try {
        await _deviceService.registerDevice(userCredential.user!.uid);
        final deviceDuration = DateTime.now().difference(deviceStart);
        AppLogger.auth('Device registered in ${deviceDuration.inMilliseconds}ms', tag: 'AUTH_CONTROLLER');
      } catch (e) {
        final deviceDuration = DateTime.now().difference(deviceStart);
        AppLogger.auth('Device registration failed after ${deviceDuration.inMilliseconds}ms (non-critical): $e', tag: 'AUTH_CONTROLLER');
        // Don't throw here - device registration failure shouldn't block sign-in
        // The user can still use the app, just without device management features
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Almost ready...');

      // Step 5: Show success and navigate
      Get.snackbar('Success', 'Google sign-in successful');
      AppLogger.auth('Success snackbar displayed', tag: 'AUTH_CONTROLLER');

      AppLogger.auth('Checking profile completion and navigating', tag: 'AUTH_CONTROLLER');
      final navStart = DateTime.now();
      await _navigateBasedOnProfileCompletion(userCredential.user!);
      final navDuration = DateTime.now().difference(navStart);
      AppLogger.auth('Navigation completed in ${navDuration.inMilliseconds}ms', tag: 'AUTH_CONTROLLER');
    } catch (e) {
      final totalDuration = DateTime.now().difference(controllerStartTime);
      AppLogger.authError('Google sign-in failed after ${totalDuration.inSeconds}s', tag: 'AUTH_CONTROLLER', error: e);
      AppLogger.auth('Error type: ${e.runtimeType}', tag: 'AUTH_CONTROLLER');
      _hideGoogleSignInLoadingDialog();
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog();
      final totalDuration = DateTime.now().difference(controllerStartTime);
      AppLogger.auth('Google sign-in process completed in ${totalDuration.inSeconds}s', tag: 'AUTH_CONTROLLER');
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
    AppLogger.auth('Creating/updating user profile', tag: 'AUTH_CONTROLLER');
    await _authRepository.createOrUpdateUser(userCredential.user!);
    AppLogger.auth('User profile updated', tag: 'AUTH_CONTROLLER');

    // Update loading dialog message
    _updateGoogleSignInLoadingDialog('Setting up your account...');

    // Step 3: Keep loading while registering device
    AppLogger.auth('Registering device', tag: 'AUTH_CONTROLLER');
    try {
      await _deviceService.registerDevice(userCredential.user!.uid);
      AppLogger.auth('Device registered', tag: 'AUTH_CONTROLLER');
    } catch (e) {
      AppLogger.auth('Device registration failed (non-critical): $e', tag: 'AUTH_CONTROLLER');
      // Don't throw here - device registration failure shouldn't block sign-in
    }

    // Update loading dialog message
    _updateGoogleSignInLoadingDialog('Almost ready...');

    // Step 4: Show success and navigate
    Get.snackbar('Success', 'Google sign-in successful');

    AppLogger.auth('Checking profile completion and navigating', tag: 'AUTH_CONTROLLER');
    await _navigateBasedOnProfileCompletion(userCredential.user!);
  }

  // Handle successful authentication when userCredential is null but user is authenticated
  Future<void> _handleSuccessfulAuthenticationWithCurrentUser(User user) async {
    try {
      // Check if user already exists in Firestore by email
      AppLogger.auth('Checking for existing user profile by email...', tag: 'GOOGLE_VERIFY_RECOVERY');
      final existingUser = await _findExistingUserByEmail(user.email!);

      if (existingUser != null) {
        AppLogger.auth('Found existing user profile: ${existingUser['uid']}', tag: 'GOOGLE_VERIFY_RECOVERY');

        // Link the Firebase Auth user to the existing Firestore profile
        AppLogger.auth('Linking Firebase Auth user to existing profile...', tag: 'GOOGLE_VERIFY_RECOVERY');
        await _linkFirebaseUserToExistingProfile(user, existingUser);

        // Use the existing user's UID for navigation and device registration
        final existingUserId = existingUser['uid'];
        AppLogger.auth('Successfully linked to existing user: $existingUserId', tag: 'GOOGLE_VERIFY_RECOVERY');

        // Register device for the existing user
        try {
          await _deviceService.registerDevice(existingUserId);
          AppLogger.auth('Device registered for existing user', tag: 'GOOGLE_VERIFY_RECOVERY');
        } catch (e) {
          AppLogger.auth('Device registration failed (non-critical): $e', tag: 'GOOGLE_VERIFY_RECOVERY');
        }

        Get.snackbar('Success', 'Google sign-in successful');
        await _navigateBasedOnProfileCompletionForExistingUser(existingUser);
        return;
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Creating your profile...');

      // Step 2: Keep loading while creating/updating user profile
      AppLogger.auth('Creating/updating user profile...', tag: 'AUTH_CONTROLLER');
      await _authRepository.createOrUpdateUser(user);
      AppLogger.auth('User profile updated', tag: 'AUTH_CONTROLLER');

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Setting up your account...');

      // Step 3: Keep loading while registering device
      AppLogger.auth('Registering device...', tag: 'AUTH_CONTROLLER');
      try {
        await _deviceService.registerDevice(user.uid);
        AppLogger.auth('Device registered', tag: 'AUTH_CONTROLLER');
      } catch (e) {
        AppLogger.auth('Device registration failed (non-critical): $e', tag: 'AUTH_CONTROLLER');
        // Don't throw here - device registration failure shouldn't block sign-in
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Almost ready...');

      // Step 4: Show success and navigate
      Get.snackbar('Success', 'Google sign-in successful');

      AppLogger.auth('Checking profile completion and navigating...', tag: 'AUTH_CONTROLLER');
      await _navigateBasedOnProfileCompletion(user);
    } catch (e) {
      AppLogger.authError('Error in successful authentication flow', tag: 'AUTH_CONTROLLER', error: e);
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
      // Create UserModel from the raw data
      final userModel = UserModel.fromJson(userData);
      final userId = userModel.uid;
      AppLogger.auth('Checking profile completion for existing user: $userId', tag: 'EXISTING_USER_NAV');

      final profileCompleted = userModel.profileCompleted;
      final roleSelected = userModel.roleSelected;

      AppLogger.auth('Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted', tag: 'EXISTING_USER_NAV');

      // Clean up expired trials on login
      AppLogger.auth('Starting trial cleanup...', tag: 'EXISTING_USER_NAV');
      try {
        await _trialService.cleanupExpiredTrials(userId);
        AppLogger.auth('Trial cleanup completed', tag: 'EXISTING_USER_NAV');
      } catch (e) {
        AppLogger.auth('Trial cleanup failed: $e', tag: 'EXISTING_USER_NAV');
      }

      if (!roleSelected) {
        AppLogger.auth('Role not selected, navigating to role selection...', tag: 'EXISTING_USER_NAV');
        Get.offAllNamed('/role-selection');
        return;
      }

      if (!profileCompleted) {
        AppLogger.auth('Profile not completed, navigating to profile completion...', tag: 'EXISTING_USER_NAV');
        Get.offAllNamed('/profile-completion');
        return;
      }

      // Profile is complete and role is selected, go to home
      AppLogger.auth('Profile complete, preparing to navigate to home...', tag: 'EXISTING_USER_NAV');

      // Ensure controllers are initialized for the existing user session
      if (!Get.isRegistered<ChatController>()) {
        AppLogger.auth('Initializing ChatController...', tag: 'EXISTING_USER_NAV');
        Get.put<ChatController>(ChatController());
        AppLogger.auth('ChatController recreated for existing user session', tag: 'EXISTING_USER_NAV');
      } else {
        AppLogger.auth('ChatController already registered', tag: 'EXISTING_USER_NAV');
      }

      // Ensure CandidateController is initialized
      if (!Get.isRegistered<CandidateController>()) {
        AppLogger.auth('Initializing CandidateController...', tag: 'EXISTING_USER_NAV');
        Get.put<CandidateController>(CandidateController());
        AppLogger.auth('CandidateController recreated for existing user session', tag: 'EXISTING_USER_NAV');
      } else {
        AppLogger.auth('CandidateController already registered', tag: 'EXISTING_USER_NAV');
      }

      // Initialize Chat Notification Service
      AppLogger.auth('Initializing Chat Notification Service...', tag: 'EXISTING_USER_NAV');
      try {
        final chatNotificationService = ChatNotificationService();
        final userLocation = _extractUserLocation(userModel);
        await chatNotificationService.initialize(
          userId: userId,
          userRole: userModel.role,
          userLocation: userLocation,
        );
        AppLogger.auth('Chat Notification Service initialized', tag: 'EXISTING_USER_NAV');
      } catch (e) {
        AppLogger.auth('Chat Notification Service initialization failed: $e', tag: 'EXISTING_USER_NAV');
      }

      AppLogger.auth('Navigating to home screen...', tag: 'EXISTING_USER_NAV');
      Get.offAllNamed('/home');
      AppLogger.auth('Navigation to home completed', tag: 'EXISTING_USER_NAV');

    } catch (e) {
      AppLogger.authError('Error during profile check', tag: 'EXISTING_USER_NAV', error: e);
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    } finally {
      // Ensure loading state is cleared after navigation
      AppLogger.auth('Navigation completed, clearing loading state', tag: 'EXISTING_USER_NAV');
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog(); // Ensure dialog is closed
    }
  }

  Future<void> _navigateBasedOnProfileCompletion(User user) async {
    try {
      AppLogger.auth('Checking user profile completion for ${user.uid}...', tag: 'AUTH_CONTROLLER');

      // Check if user profile is complete
      AppLogger.auth('Fetching user document from Firestore...', tag: 'AUTH_CONTROLLER');
      final docStart = DateTime.now();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final docDuration = DateTime.now().difference(docStart);
      AppLogger.auth('User document fetched in ${docDuration.inMilliseconds}ms - Exists: ${userDoc.exists}', tag: 'AUTH_CONTROLLER');

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;
        final roleSelected = userData?['roleSelected'] ?? false;

        AppLogger.auth('Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted', tag: 'AUTH_CONTROLLER');

        // Clean up expired trials on login
        AppLogger.auth('Starting trial cleanup...', tag: 'AUTH_CONTROLLER');
        final trialStart = DateTime.now();
        try {
          await _trialService.cleanupExpiredTrials(user.uid);
          final trialDuration = DateTime.now().difference(trialStart);
          AppLogger.auth('Trial cleanup completed in ${trialDuration.inMilliseconds}ms', tag: 'AUTH_CONTROLLER');
        } catch (e) {
          final trialDuration = DateTime.now().difference(trialStart);
          AppLogger.auth('Trial cleanup failed after ${trialDuration.inMilliseconds}ms: $e', tag: 'AUTH_CONTROLLER');
        }

        if (!roleSelected) {
          AppLogger.auth('Role not selected, navigating to role selection...', tag: 'AUTH_CONTROLLER');
          Get.offAllNamed('/role-selection');
          return;
        }

        if (!profileCompleted) {
          AppLogger.auth('Profile not completed, navigating to profile completion...', tag: 'AUTH_CONTROLLER');
          Get.offAllNamed('/profile-completion');
          return;
        }

        AppLogger.auth('Profile complete and role selected', tag: 'AUTH_CONTROLLER');

        // Initialize Chat Notification Service
        AppLogger.auth('Initializing Chat Notification Service...', tag: 'AUTH_CONTROLLER');
        try {
          final chatNotificationService = ChatNotificationService();
          final userModel = UserModel.fromJson(userData!);
          final userLocation = _extractUserLocation(userModel);
          await chatNotificationService.initialize(
            userId: user.uid,
            userRole: userModel.role,
            userLocation: userLocation,
          );
          AppLogger.auth('Chat Notification Service initialized', tag: 'AUTH_CONTROLLER');
        } catch (e) {
          AppLogger.auth('Chat Notification Service initialization failed: $e', tag: 'AUTH_CONTROLLER');
        }
      } else {
        // User document doesn't exist, need role selection first
        AppLogger.auth('User document not found, navigating to role selection...', tag: 'AUTH_CONTROLLER');
        Get.offAllNamed('/role-selection');
        return;
      }

      // Profile is complete and role is selected, go to home
      AppLogger.auth('Profile complete, preparing to navigate to home...', tag: 'AUTH_CONTROLLER');

      // Ensure controllers are initialized for the new user session
      if (!Get.isRegistered<ChatController>()) {
        AppLogger.auth('Initializing ChatController...', tag: 'AUTH_CONTROLLER');
        Get.put<ChatController>(ChatController());
        AppLogger.auth('ChatController recreated for new user session', tag: 'AUTH_CONTROLLER');
      } else {
        AppLogger.auth('ChatController already registered', tag: 'AUTH_CONTROLLER');
      }

      // Ensure CandidateController is initialized
      if (!Get.isRegistered<CandidateController>()) {
        AppLogger.auth('Initializing CandidateController...', tag: 'AUTH_CONTROLLER');
        Get.put<CandidateController>(CandidateController());
        AppLogger.auth('CandidateController recreated for new user session', tag: 'AUTH_CONTROLLER');
      } else {
        AppLogger.auth('CandidateController already registered', tag: 'AUTH_CONTROLLER');
      }

      AppLogger.auth('Navigating to home screen...', tag: 'AUTH_CONTROLLER');
      Get.offAllNamed('/home');
      AppLogger.auth('Navigation to home completed', tag: 'AUTH_CONTROLLER');
    } catch (e) {
      AppLogger.authError('Error during profile check', tag: 'AUTH_CONTROLLER', error: e);
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    } finally {
      // Ensure loading state is cleared after navigation
      AppLogger.auth('Navigation completed, clearing loading state', tag: 'AUTH_CONTROLLER');
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog(); // Ensure dialog is closed
    }
  }
}

