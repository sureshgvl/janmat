import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/auth/auth_localizations.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late SmsAutoFill _autoFill;

  @override
  void initState() {
    super.initState();
    _autoFill = SmsAutoFill();
    _listenForSms();
  }

  @override
  void dispose() {
    _autoFill.unregisterListener();
    super.dispose();
  }

  void _listenForSms() async {
    await _autoFill.listenForCode();
    _autoFill.code.listen((code) {
      if (code != null && code.isNotEmpty) {
        AppLogger.auth('📱 Auto-read OTP from SMS: $code');

        // Auto-fill the OTP controller
        final controller = Get.find<AuthController>();
        controller.otpController.text = code;
        AppLogger.auth('✅ OTP auto-filled in text field');

        // Show success message
        Get.snackbar(
          'OTP Auto-filled',
          'OTP has been automatically filled from SMS',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    });
  }

  // MAINTAIN SECONDARY LOADING POPUP DURING NAVIGATION TRANSITION
  Future<void> _handleGoogleSignIn(
    AuthController controller,
    bool forceAccountPicker,
    AuthLocalizations authLocalizations,
  ) async {
    // Show the secondary loading dialog
    Get.dialog(
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Determining your account status...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we set up your account',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      barrierDismissible: false, // Prevent dismissal while navigating
    );

    try {
      AppLogger.auth('🔄 [LOGIN SCREEN] Starting Google sign-in process...');
      await controller.signInWithGoogle(forceAccountPicker: forceAccountPicker, showOwnDialog: false);
      AppLogger.auth('✅ [LOGIN SCREEN] Google sign-in completed');

      // Keep the loading dialog until navigation completes
      // The AuthController.signInWithGoogle already handles navigation
    } catch (e) {
      AppLogger.auth('❌ [LOGIN SCREEN] Error in Google sign-in: $e');
      // Close the secondary loading dialog on error
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      // Primary sign-in error handling is done in AuthController
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();

    // Get translations with fallback to ensure they always work
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                      const SizedBox(height: 10),

                      Text(
                        appLocalizations.welcomeMessage,
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.purple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: kIsWeb
                              ? _buildEmailPasswordScreen(context, controller)
                              : Obx(
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

  Widget _buildEmailPasswordScreen(BuildContext context, AuthController controller) {
    return Column(
      children: [
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
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
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
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
        ),
        const SizedBox(height: 20),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isLoading.value ? null : () async {
              await controller.signInWithEmailAndPassword();
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
                      Text('Signing in...'),
                    ],
                  )
                : Text('Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputScreen(
    BuildContext context,
    AuthController controller,
  ) {
    // Get translations with fallback to ensure they always work
    final authLocalizations = AuthLocalizations.of(context) ?? AuthLocalizations.current;

    return Column(
      children: [
        TextField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: authLocalizations.translate('phoneNumber'),
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
              AppLogger.auth('🔘 Send OTP button pressed');
              AppLogger.auth('📱 Phone number: ${controller.phoneController.text}');

              // Show loading dialog using GetX
              Get.dialog(
                AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        authLocalizations.sendingOTP,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authLocalizations.verificationMayTakeTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                barrierDismissible: false,
              );

              try {
                AppLogger.auth('📤 LoadingDialog shown, calling controller.sendOTP()');
                await controller.sendOTP();
                AppLogger.auth('✅ controller.sendOTP() completed');
              } catch (e) {
                AppLogger.auth('❌ Error in sendOTP: $e');
                // Close loading dialog on error
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                  AppLogger.auth('📤 LoadingDialog dismissed due to error');
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
                      Text(authLocalizations.sending),
                    ],
                  )
                : Text(authLocalizations.translate('sendOTP')),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPScreen(BuildContext context, AuthController controller) {
    // Get translations with fallback to ensure they always work
    final authLocalizations = AuthLocalizations.of(context) ?? AuthLocalizations.current;

    return Column(
      children: [
        Text(
          authLocalizations.enterOTP(controller.phoneController.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Auto-read indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smartphone,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Auto-read OTP from SMS',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: authLocalizations.otp,
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
                                  Text(
                                    authLocalizations.verifyingOTP,
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
                            AppLogger.auth('❌ Error in verifyOTP: $e');
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
                  child: Text(authLocalizations.verifyOTP),
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
                    authLocalizations.resendOTP,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  authLocalizations.resendOTPIn(controller.otpTimer.value),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: controller.goBackToPhoneInput,
          child: Text(authLocalizations.changePhoneNumber),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    AuthController controller,
  ) {
    // Get translations with fallback to ensure they always work
    final authLocalizations = AuthLocalizations.of(context) ?? AuthLocalizations.current;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: controller.getLastGoogleAccount(),
        builder: (context, snapshot) {
          final hasStoredAccount = snapshot.hasData && snapshot.data != null;
          final storedAccount = snapshot.data;

          return Obx(
            () => Column(
              children: [
                // Show both options when account is stored
                if (hasStoredAccount && !controller.isLoading.value) ...[
                  // Continue as existing account button
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value ? null : () async {
                        await _handleGoogleSignIn(controller, false, authLocalizations);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              children: [
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authLocalizations.continueAs(storedAccount?['displayName'] ?? 'User'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        storedAccount?['email'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Sign in with different account button
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value ? null : () async {
                      await _handleGoogleSignIn(controller, true, authLocalizations);
                    },
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
                      authLocalizations.signInWithDifferentAccount,
                      style: TextStyle(
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

                  // Info text
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      authLocalizations.chooseHowToSignIn,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  // Default Google Sign-In button when no stored account
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.signInWithGoogle(forceAccountPicker: false),
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
                          ? authLocalizations.signingIn
                          : authLocalizations.translate('signInWithGoogle'),
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
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
