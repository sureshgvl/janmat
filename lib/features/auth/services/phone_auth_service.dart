import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';

class PhoneAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Phone Authentication with improved reCAPTCHA handling and timeout
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    AppLogger.auth('Initiating phone verification for: +91$phoneNumber', tag: 'PHONE_VERIFY');

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          AppLogger.auth('Phone verification completed automatically', tag: 'PHONE_VERIFY');
          // Auto-verification successful, sign in immediately
          try {
            await _firebaseAuth.signInWithCredential(credential);
            AppLogger.auth('Auto-signed in with phone credential', tag: 'PHONE_VERIFY');
          } catch (e) {
            AppLogger.authError('Auto-sign in failed', tag: 'PHONE_VERIFY', error: e);
            rethrow;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.authError('Phone verification failed: ${e.message}', tag: 'PHONE_VERIFY', error: e);
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.auth('OTP sent successfully, verification ID: $verificationId', tag: 'PHONE_VERIFY');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.auth('Auto-retrieval timeout, manual OTP entry required', tag: 'PHONE_VERIFY');
          // This is called when auto-retrieval times out
          // The verificationId is still valid for manual OTP entry
          onCodeSent(verificationId);
        },
        // Force reCAPTCHA to be more responsive
        timeout: const Duration(seconds: 30), // Reduced timeout for better UX
        // Enable forceResendingToken for better UX
        forceResendingToken: null,
      ).timeout(
        const Duration(seconds: 60), // Overall timeout for the entire operation
        onTimeout: () {
          AppLogger.auth('Phone verification timed out after 60 seconds', tag: 'PHONE_VERIFY');
          throw Exception('Phone verification timed out. Please check your internet connection and try again.');
        },
      );

      AppLogger.auth('Phone verification setup completed', tag: 'PHONE_VERIFY');
    } catch (e) {
      AppLogger.authError('Phone verification setup failed', tag: 'PHONE_VERIFY', error: e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithOTP(
    String verificationId,
    String smsCode,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }
}
