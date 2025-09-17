import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import '../../controllers/login_controller.dart';

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
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.welcomeMessage,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Obx(
                      () => controller.isOTPScreen.value
                          ? _buildOTPScreen(context, controller)
                          : _buildPhoneInputScreen(context, controller),
                    ),
                    const SizedBox(height: 20),
                    _buildGoogleSignInButton(context, controller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneInputScreen(
    BuildContext context,
    LoginController controller,
  ) {
    return Column(
      children: [
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.phoneNumber,
            prefixText: '+91 ',
            border: OutlineInputBorder(),
          ),
          maxLength: 10,
        ),
        const SizedBox(height: 20),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.sendOTP,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: controller.isLoading.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(AppLocalizations.of(context)!.sending),
                    ],
                  )
                : Text(AppLocalizations.of(context)!.sendOTP),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPScreen(BuildContext context, LoginController controller) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(
            context,
          )!.enterOTP(controller.phoneController.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.otp,
            border: OutlineInputBorder(),
          ),
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.verifyOTP,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: controller.isLoading.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(AppLocalizations.of(context)!.verifying),
                          ],
                        )
                      : Text(AppLocalizations.of(context)!.verifyOTP),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.goBackToPhoneInput,
          child: Text(AppLocalizations.of(context)!.changePhoneNumber),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    LoginController controller,
  ) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: controller.isLoading.value
            ? null
            : controller.signInWithGoogle,
        icon: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(
          controller.isLoading.value
              ? 'Signing in...'
              : AppLocalizations.of(context)!.signInWithGoogle,
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
