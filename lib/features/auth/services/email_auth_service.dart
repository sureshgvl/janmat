import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';

class EmailAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    AppLogger.auth('Signing in with email: $email', tag: 'EMAIL_AUTH');

    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.auth('Email sign-in successful for: ${userCredential.user?.email}', tag: 'EMAIL_AUTH');
      return userCredential;
    } catch (e) {
      AppLogger.authError('Email sign-in failed', tag: 'EMAIL_AUTH', error: e);
      rethrow;
    }
  }

  // Create user with email and password (sign up)
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    AppLogger.auth('Creating user with email: $email', tag: 'EMAIL_AUTH');

    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      AppLogger.auth('User creation successful for: ${userCredential.user?.email}', tag: 'EMAIL_AUTH');
      return userCredential;
    } catch (e) {
      AppLogger.authError('User creation failed', tag: 'EMAIL_AUTH', error: e);
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    AppLogger.auth('Sending password reset email to: $email', tag: 'EMAIL_AUTH');

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      AppLogger.auth('Password reset email sent successfully', tag: 'EMAIL_AUTH');
    } catch (e) {
      AppLogger.authError('Password reset email failed', tag: 'EMAIL_AUTH', error: e);
      rethrow;
    }
  }
}
