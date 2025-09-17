import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/app_localizations.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.find<LoginController>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Image.asset(
                        'assets/images/app-icon.png',
                        height: 80,
                        width: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Janmat',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.welcomeMessage,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          '📱 For phone verification, a browser may open to complete the security check. Please complete the verification and return to the app.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Obx(
                            () => controller.isOTPScreen.value
                                ? _buildOTPScreen(context, controller)
                                : _buildPhoneInputScreen(context, controller),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildGoogleSignInButton(context, controller),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLength: 10,
        ),
        const SizedBox(height: 20),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () async {
              debugPrint('🔘 Send OTP button pressed');
              debugPrint('📱 Phone number: ${controller.phoneController.text}');

              // Show loading dialog using GetX
              Get.dialog(
                AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Sending OTP...',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This may take a moment if verification is required.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                barrierDismissible: false,
              );

              try {
                debugPrint('📤 LoadingDialog shown, calling controller.sendOTP()');
                await controller.sendOTP();
                debugPrint('✅ controller.sendOTP() completed');
              } catch (e) {
                debugPrint('❌ Error in sendOTP: $e');
                // Close loading dialog on error
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                  debugPrint('📤 LoadingDialog dismissed due to error');
                }
              }
              // Note: Loading dialog will be closed by the controller when OTP screen is shown
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
                      Text('Sending...'),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
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
                      : () async {
                          // Show loading dialog using GetX
                          Get.dialog(
                            AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Verifying OTP...',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            barrierDismissible: false,
                          );

                          try {
                            await controller.verifyOTP();
                          } catch (e) {
                            debugPrint('❌ Error in verifyOTP: $e');
                          } finally {
                            // Always close the loading dialog
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(AppLocalizations.of(context)!.verifyOTP),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // OTP Timer and Resend Button
        Obx(
          () => controller.canResendOTP.value
              ? TextButton(
                  onPressed: controller.resendOTP,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  'Resend OTP in ${controller.otpTimer.value}s',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
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
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: controller.isLoading.value
              ? null
              : controller.signInWithGoogle,
          icon: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                ),
          label: Text(
            controller.isLoading.value
                ? 'Signing in...'
                : AppLocalizations.of(context)!.signInWithGoogle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 2,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
