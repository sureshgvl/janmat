import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../services/device_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final DeviceService _deviceService = DeviceService();

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

    print('SendOTP called with phone: ${phoneController.text}');
    isLoading.value = true;
    print('isLoading set to: ${isLoading.value}');
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
    isLoading.value = true;
    try {
      final userCredential = await _authRepository.signInWithGoogle();
      print('Google Sign-In UserCredential: ${userCredential.user}');
      await _authRepository.createOrUpdateUser(userCredential.user!);

      // Register device for multi-device login prevention
      await _deviceService.registerDevice(userCredential.user!.uid);

      Get.snackbar('Success', 'Google sign-in successful');
      // Check profile completion and navigate accordingly
      await _navigateBasedOnProfileCompletion(userCredential.user!);
    } catch (e) {
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void goBackToPhoneInput() {
    isOTPScreen.value = false;
    otpController.clear();
  }

  Future<void> _navigateBasedOnProfileCompletion(User user) async {
    try {
      // Check if user profile is complete
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final profileCompleted = userData?['profileCompleted'] ?? false;

        if (!profileCompleted) {
          Get.offAllNamed('/profile-completion');
          return;
        }
      } else {
        // User document doesn't exist, need profile completion
        Get.offAllNamed('/profile-completion');
        return;
      }

      // Profile is complete, go to home
      Get.offAllNamed('/home');
    } catch (e) {
      // If there's an error checking profile, default to login
      Get.offAllNamed('/login');
    }
  }
}