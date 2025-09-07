import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  RxBool isLoading = false.obs;
  var verificationId = ''.obs;
  var isOTPScreen = false.obs;

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
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

      Get.snackbar('Success', 'Login successful');
      // Navigate to home or next screen
      Get.offAllNamed('/home'); // Assuming home route is set up
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

      Get.snackbar('Success', 'Google sign-in successful');
      // Navigate to home or next screen
      Get.offAllNamed('/home');
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
}