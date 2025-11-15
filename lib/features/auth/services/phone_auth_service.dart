import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../utils/app_logger.dart';

// COMMENTED OUT: Original Firebase OTP implementation
// Keeping for reference - can be restored if needed
/*
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
*/

class PhoneAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // MSG91 API Configuration - Guaranteed SMS delivery
  final String _sendOtpUrl = 'https://api.msg91.com/api/v5/otp';
  final String _verifyOtpUrl = 'https://api.msg91.com/api/v5/otp/verify';
  String? _currentPhoneNumber; // Store phone number for verification

  // Get MSG91 credentials from environment at runtime
  String get _authKey => dotenv.env['MSG91_AUTH_KEY'] ?? 'YOUR_MSG91_AUTH_KEY';
  String get _senderId => dotenv.env['MSG91_SENDER_ID'] ?? 'JANMAT';
  String get _templateId => dotenv.env['MSG91_TEMPLATE_ID'] ?? 'YOUR_TEMPLATE_ID';

  // Send OTP using MSG91 (₹0.12 per SMS) - Guaranteed SMS delivery
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
  ) async {
    AppLogger.auth('Initiating MSG91 SMS OTP for: +91$phoneNumber', tag: 'PHONE_VERIFY');

    try {
      _currentPhoneNumber = phoneNumber; // Store for verification

      // Try template-based OTP first (your approved template)
      final response = await http.post(
        Uri.parse(_sendOtpUrl),
        headers: {
          'authkey': _authKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'template_id': _templateId, // MSG91 pre-approved template ID
          'mobile': '91$phoneNumber', // MSG91 expects format without +
          'sender': _senderId,
          'otp_expiry': 5, // 5 minutes expiry (integer)
        })
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.auth('MSG91 API timeout after 30 seconds', tag: 'PHONE_VERIFY');
          throw Exception('OTP request timed out. Please check your internet connection.');
        },
      );

      AppLogger.auth('MSG91 API Response: ${response.body}', tag: 'PHONE_VERIFY');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['type'] == 'success') {
          final requestId = data['request_id'];
          AppLogger.auth('SMS OTP sent successfully via MSG91, Request ID: $requestId', tag: 'PHONE_VERIFY');

          // Check delivery status after a short delay
          _checkDeliveryStatus(requestId, phoneNumber);

          onCodeSent('msg91_session'); // Return a dummy verification ID
        } else {
          AppLogger.authError('MSG91 Template API Error: ${data['message']}', tag: 'PHONE_VERIFY');

          // Fallback: Try sending OTP with direct message instead of template
          AppLogger.auth('Attempting fallback: Sending OTP with direct message', tag: 'PHONE_VERIFY');
          await _sendOtpWithDirectMessage(phoneNumber, onCodeSent);
        }
      } else {
        AppLogger.authError('MSG91 HTTP Error: ${response.statusCode}', tag: 'PHONE_VERIFY');
        throw Exception('Failed to send SMS OTP. Please try again.');
      }
    } catch (e) {
      AppLogger.authError('MSG91 SMS OTP setup failed', tag: 'PHONE_VERIFY', error: e);
      rethrow;
    }
  }

  // Check SMS delivery status (for debugging)
  Future<void> _checkDeliveryStatus(String requestId, String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 10)); // Wait 10 seconds for delivery

    try {
      final response = await http.get(
        Uri.parse('https://api.msg91.com/api/v5/otp/delivery-status?request_id=$requestId'),
        headers: {
          'authkey': _authKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.auth('MSG91 Delivery Status for +91$phoneNumber: ${response.body}', tag: 'PHONE_VERIFY');

        if (data['type'] == 'success' && data['reports'] != null) {
          final reports = data['reports'] as List;
          if (reports.isNotEmpty) {
            final status = reports[0]['status'];
            AppLogger.auth('SMS Delivery Status: $status', tag: 'PHONE_VERIFY');
          }
        }
      }
    } catch (e) {
      AppLogger.auth('Failed to check delivery status: $e', tag: 'PHONE_VERIFY');
    }
  }

  // Fallback: Send OTP with direct message (no template)
  Future<void> _sendOtpWithDirectMessage(String phoneNumber, Function(String) onCodeSent) async {
    try {
      final response = await http.post(
        Uri.parse(_sendOtpUrl),
        headers: {
          'authkey': _authKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mobile': '91$phoneNumber',
          'sender': _senderId,
          'otp': '6', // Length of OTP
          'otp_expiry': '5', // 5 minutes
          'message': 'Your JanMat verification code is {{otp}}. Please do not share it. Valid for 5 minutes.',
        })
      ).timeout(const Duration(seconds: 30));

      AppLogger.auth('MSG91 Direct Message Fallback Response: ${response.body}', tag: 'PHONE_VERIFY');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['type'] == 'success') {
          final requestId = data['request_id'];
          AppLogger.auth('SMS OTP sent successfully via MSG91 Direct Message, Request ID: $requestId', tag: 'PHONE_VERIFY');

          // Check delivery status for fallback too
          _checkDeliveryStatus(requestId, phoneNumber);

          onCodeSent('msg91_session');
        } else {
          AppLogger.authError('MSG91 Direct Message Fallback Error: ${data['message']}', tag: 'PHONE_VERIFY');
          throw Exception('Failed to send SMS OTP via fallback method: ${data['message']}');
        }
      } else {
        AppLogger.authError('MSG91 Direct Message HTTP Error: ${response.statusCode}', tag: 'PHONE_VERIFY');
        throw Exception('Failed to send SMS OTP via fallback method. Please try again.');
      }
    } catch (e) {
      AppLogger.authError('MSG91 Direct Message fallback failed', tag: 'PHONE_VERIFY', error: e);
      rethrow;
    }
  }

  // Verify OTP using MSG91 - Returns success/failure
  Future<bool> verifyOTP(
    String verificationId, // Not used with MSG91
    String smsCode,
  ) async {
    AppLogger.auth('Verifying OTP with MSG91, Phone: $_currentPhoneNumber, OTP: $smsCode', tag: 'OTP_VERIFY');

    if (_currentPhoneNumber == null) {
      throw Exception('Session expired. Please request OTP again.');
    }

    try {
      final response = await http.post(
        Uri.parse(_verifyOtpUrl),
        headers: {
          'authkey': _authKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'mobile': '91$_currentPhoneNumber', // MSG91 expects format without +
          'otp': smsCode,
        })
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          AppLogger.auth('MSG91 verification timeout', tag: 'OTP_VERIFY');
          throw Exception('OTP verification timed out. Please try again.');
        },
      );

      AppLogger.auth('MSG91 Verify Response: ${response.body}', tag: 'OTP_VERIFY');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['type'] == 'success') {
          AppLogger.auth('OTP verification successful with MSG91', tag: 'OTP_VERIFY');
          return true;
        } else {
          AppLogger.authError('Invalid OTP: ${data['message']}', tag: 'OTP_VERIFY');
          throw Exception('Invalid OTP. Please check and try again.');
        }
      } else {
        AppLogger.authError('MSG91 verification HTTP error: ${response.statusCode}', tag: 'OTP_VERIFY');
        throw Exception('OTP verification failed. Please try again.');
      }
    } catch (e) {
      AppLogger.authError('MSG91 OTP verification failed', tag: 'OTP_VERIFY', error: e);
      rethrow;
    }
  }

  // Legacy method for backward compatibility - creates anonymous Firebase user after MSG91 verification
  Future<UserCredential> signInWithOTP(
    String verificationId,
    String smsCode,
  ) async {
    // First verify OTP with MSG91
    final isValid = await verifyOTP(verificationId, smsCode);

    if (isValid) {
      try {
        // Try to create anonymous Firebase user for compatibility
        final userCredential = await _firebaseAuth.signInAnonymously();
        AppLogger.auth('Anonymous Firebase sign-in successful after MSG91 verification', tag: 'OTP_VERIFY');
        return userCredential;
      } catch (e) {
        AppLogger.auth('Anonymous auth failed, but MSG91 verification succeeded: $e', tag: 'OTP_VERIFY');
        // Return a basic success indicator - the auth controller will handle this
        throw Exception('OTP verified but authentication setup failed. Please contact support.');
      }
    } else {
      throw Exception('OTP verification failed');
    }
  }

  // Resend OTP (MSG91 supports this)
  Future<void> resendOTP(String phoneNumber, Function(String) onCodeSent) async {
    AppLogger.auth('Resending OTP via MSG91 for: +91$phoneNumber', tag: 'PHONE_VERIFY');
    await verifyPhoneNumber(phoneNumber, onCodeSent);
  }
}
