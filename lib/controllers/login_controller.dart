import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../services/device_service.dart';
import '../services/trial_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final DeviceService _deviceService = DeviceService();
  final TrialService _trialService = TrialService();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  RxBool isLoading = false.obs;
  var verificationId = ''.obs;
  var isOTPScreen = false.obs;

  @override
  void onInit() {
    super.onInit();
    _startDeviceMonitoring();
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
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
    if (phoneController.text.isEmpty || phoneController.text.length != 10) {
      Get.snackbar('Error', 'Please enter a valid 10-digit phone number');
      return;
    }

  debugPrint('SendOTP called with phone: ${phoneController.text}');
    isLoading.value = true;
  debugPrint('isLoading set to: ${isLoading.value}');
    try {
      await _authRepository.verifyPhoneNumber(
        phoneController.text,
        (String vid) {
          verificationId.value = vid;
          isOTPScreen.value = true;
          Get.snackbar('Success', 'OTP sent to +91${phoneController.text}');
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
    } finally {
      // Add a small delay to ensure loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
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
      await _deviceService.registerDevice(userCredential.user!.uid);

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

      // Handle cancelled sign-in
      if (userCredential == null) {
        _hideGoogleSignInLoadingDialog();
        Get.snackbar("Cancelled", "Google sign-in was cancelled");
        return;
      }
      if (userCredential.user == null) {
        _hideGoogleSignInLoadingDialog();
        Get.snackbar("Error", "Google sign-in failed: No user returned");
        return;
      }

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
      await _deviceService.registerDevice(userCredential.user!.uid);
      debugPrint('✅ Device registered');

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
    }finally {
      isLoading.value = false;
      _hideGoogleSignInLoadingDialog();
      debugPrint('✅ Google sign-in process completed');
    }
  }

  void goBackToPhoneInput() {
    isOTPScreen.value = false;
    otpController.clear();
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

        debugPrint('📋 Profile status - Role selected: $roleSelected, Profile completed: $profileCompleted');

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
        debugPrint('📄 User document not found, navigating to role selection...');
        Get.offAllNamed('/role-selection');
        return;
      }

      // Profile is complete and role is selected, go to home
      debugPrint('🏠 Profile complete, navigating to home...');
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