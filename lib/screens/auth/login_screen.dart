import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/login_controller.dart';
import '../../common/loading_overlay.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to JanMat',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Obx(() => controller.isOTPScreen.value
                        ? _buildOTPScreen(controller)
                        : _buildPhoneInputScreen(controller)),
                    const SizedBox(height: 20),
                    _buildGoogleSignInButton(controller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneInputScreen(LoginController controller) {
    return Column(
      children: [
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixText: '+91 ',
            border: OutlineInputBorder(),
          ),
          maxLength: 10,
        ),
        const SizedBox(height: 20),
        Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.sendOTP,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: controller.isLoading.value
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Sending...'),
                  ],
                )
              : const Text('Send OTP'),
        )),
      ],
    );
  }

  Widget _buildOTPScreen(LoginController controller) {
    return Column(
      children: [
        Text(
          'Enter OTP sent to +91${controller.phoneController.text}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'OTP',
            border: OutlineInputBorder(),
          ),
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.verifyOTP,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: controller.isLoading.value
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Verifying...'),
                        ],
                      )
                    : const Text('Verify OTP'),
              )),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.goBackToPhoneInput,
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(LoginController controller) {
    return LoadingOverlay(
      isLoading: controller.isLoading.value,
      child: OutlinedButton.icon(
        onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
        icon: const Icon(Icons.login),
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}