import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../services/device_service.dart';
import '../services/trial_service.dart';
import '../controllers/chat_controller.dart';

class LoginController extends GetxController {
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

    // Sign out and navigate to login
    FirebaseAuth.instance.signOut();
    Get.offAllNamed('/login');
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
      throw e; // Re-throw to be caught by the UI layer
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
      final userCredential = await _authRepository.signInWithOTP(
        verificationId.value,
        otpController.text,
      );

      await _authRepository.createOrUpdateUser(userCredential.user!);

      // Register device for multi-device login prevention
      try {
        await _deviceService.registerDevice(userCredential.user!.uid);
        debugPrint('✅ Device registered');
      } catch (e) {
        debugPrint('⚠️ Device registration failed (non-critical): $e');
        // Don't throw here - device registration failure shouldn't block sign-in
      }

      Get.snackbar('Success', 'Login successful');
      // Check profile completion and navigate accordingly
      await _navigateBasedOnProfileCompletion(userCredential.user!);
    } catch (e) {
      Get.snackbar('Error', 'Invalid OTP: ${e.toString()}');
    } finally {
      // Add a small delay to ensure loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    // Show prominent loading dialog immediately
    _showGoogleSignInLoadingDialog();

    try {
      debugPrint('🔄 Starting Google Sign-In process...');

      // Step 1: Google authentication (account picker will show here)
      debugPrint('📱 Initiating Google authentication...');
      final userCredential = await _authRepository.signInWithGoogle();
      debugPrint('✅ Google authentication successful');

      // Handle cancelled sign-in or timeout with successful auth
      if (userCredential == null) {
        // Check if authentication actually succeeded despite returning null
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint(
            '✅ Authentication succeeded despite null credential, proceeding with current user',
          );
          await _handleSuccessfulAuthenticationWithCurrentUser(currentUser);
          return;
        } else {
          _hideGoogleSignInLoadingDialog();
          Get.snackbar("Cancelled", "Google sign-in was cancelled");
          return;
        }
      }
      if (userCredential.user == null) {
        _hideGoogleSignInLoadingDialog();
        Get.snackbar("Error", "Google sign-in failed: No user returned");
        return;
      }

      await _handleSuccessfulAuthentication(userCredential);

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
        // The user can still use the app, just without device management features
      }

      // Update loading dialog message
      _updateGoogleSignInLoadingDialog('Almost ready...');

      // Step 4: Show success and navigate
      Get.snackbar('Success', 'Google sign-in successful');

      debugPrint('🏠 Checking profile completion and navigating...');
      await _navigateBasedOnProfileCompletion(userCredential.user!);
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      _hideGoogleSignInLoadingDialog();
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog();
      debugPrint('✅ Google sign-in process completed');
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

  Future<void> _navigateBasedOnProfileCompletion(User user) async {
    try {
      debugPrint('🔍 Checking user profile completion...');

      // Check if user profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;
        final roleSelected = userData?['roleSelected'] ?? false;

        debugPrint(
          '📋 Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted',
        );

        // Clean up expired trials on login
        try {
          await _trialService.cleanupExpiredTrials(user.uid);
          debugPrint('🧹 Trial cleanup completed');
        } catch (e) {
          debugPrint('⚠️ Trial cleanup failed: $e');
        }

        if (!roleSelected) {
          debugPrint('🎭 Navigating to role selection...');
          Get.offAllNamed('/role-selection');
          return;
        }

        if (!profileCompleted) {
          debugPrint('📝 Navigating to profile completion...');
          Get.offAllNamed('/profile-completion');
          return;
        }
      } else {
        // User document doesn't exist, need role selection first
        debugPrint(
          '📄 User document not found, navigating to role selection...',
        );
        Get.offAllNamed('/role-selection');
        return;
      }

      // Profile is complete and role is selected, go to home
      debugPrint('🏠 Profile complete, navigating to home...');

      // Ensure ChatController is initialized for the new user session
      if (!Get.isRegistered<ChatController>()) {
        Get.put<ChatController>(ChatController());
        debugPrint('✅ ChatController recreated for new user session');
      }

      Get.offAllNamed('/home');
    } catch (e) {
      debugPrint('❌ Error during profile check: $e');
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    } finally {
      // Ensure loading state is cleared after navigation
      debugPrint('✅ Navigation completed, clearing loading state');
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog(); // Ensure dialog is closed
    }
  }
}
