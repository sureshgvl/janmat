import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../../../utils/app_logger.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool isOTPScreen = false.obs;
  RxString verificationId = ''.obs;

  // OTP Timer
  RxInt otpTimer = 60.obs;
  RxBool canResendOTP = false.obs;
  Timer? _otpTimer;

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    _otpTimer?.cancel();
    super.onClose();
  }

  // Get last used Google account for smart login UX
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    return await _authRepository.getLastGoogleAccount();
  }

  // OTP LOGIN - SIMPLE
  Future<void> sendOTP() async {
    if (phoneController.text.isEmpty || phoneController.text.length != 10) {
      Get.snackbar('Error', 'Please enter a valid 10-digit phone number');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepository.verifyPhoneNumber(phoneController.text, (String vid) {
        verificationId.value = vid;
        isOTPScreen.value = true;
        _startOTPTimer();
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar('Success', 'OTP sent to +91${phoneController.text}');
      });

      AppLogger.auth('OTP sent successfully');
    } catch (e) {
      AppLogger.authError('SendOTP failed', error: e);
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  // VERIFY OTP AND GO HOME
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

      if (userCredential.user != null) {
        AppLogger.auth('OTP login successful: ${userCredential.user!.uid}');
        await _authRepository.createOrUpdateUser(userCredential.user!);
        Get.snackbar('Success', 'Login successful');
        Get.offAllNamed('/home');
      }
    } catch (e) {
      AppLogger.authError('OTP verification failed', error: e);
      Get.snackbar('Error', 'Invalid OTP: ${e.toString()}');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isLoading.value = false;
    }
  }

  // GOOGLE LOGIN - SIMPLE
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
      final userCredential = await _authRepository.signInWithGoogle(forceAccountPicker: forceAccountPicker);

      if (Get.isDialogOpen ?? false) Get.back();

      if (userCredential == null || userCredential.user == null) {
        Get.snackbar('Cancelled', 'Google sign-in was cancelled');
        return;
      }

      AppLogger.auth('Google login successful: ${userCredential.user!.uid}');
      await _authRepository.createOrUpdateUser(userCredential.user!);
      Get.snackbar('Success', 'Google sign-in successful');
      Get.offAllNamed('/home');

    } catch (e) {
      AppLogger.authError('Google sign-in failed', error: e);
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // LOGOUT - SIMPLE
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      AppLogger.auth('Logout successful');
      Get.offAllNamed('/login');
      Get.snackbar('Success', 'Logged out successfully');
    } catch (e) {
      AppLogger.authError('Logout failed', error: e);
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
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
    await sendOTP();
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
