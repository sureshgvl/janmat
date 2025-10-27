import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';

/// Data Layer: Handles all Firebase and SharedPreferences operations for authentication
/// Clean separation - no business logic or UI code here
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  /// Get current user from Firebase
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Fetch user role and profile data from Firestore
  Future<Map<String, dynamic>?> fetchUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (error) {
      AppLogger.error('AuthRepository: Failed to fetch user role - $error');
      return null; // Graceful failure
    }
  }

  /// Cache user role in SharedPreferences for instant access
  Future<void> cacheRole(String role) async {
    await _prefs.setString('user_role', role);
    AppLogger.common('✅ CACHED ROLE: $role');
  }

  /// Get cached role for instant UX (no network calls)
  Future<String?> getCachedRole() async {
    return _prefs.getString('user_role');
  }

  /// Clear all cached auth data (logout cleanup)
  Future<void> clearAllCache() async {
    await _prefs.remove('user_role');
    await _prefs.remove('last_google_account');
    await _prefs.clear();
    AppLogger.auth('🧹 Cleared all auth cache');
  }

  /// Enhanced logout - Firebase + Google + local cleanup
  Future<void> signOut() async {
    AppLogger.auth('🚪 Starting enhanced sign-out...');

    // Clear local cache first
    await clearAllCache();
    AppLogger.auth('✅ Cleared local cache');

    // Firebase auth logout
    await _auth.signOut();
    AppLogger.auth('✅ Firebase logout complete');

    // Google sign-in sign out
    await GoogleSignIn().signOut();
    AppLogger.auth('✅ Google logout complete');

    AppLogger.auth('🚪 Sign-out completed successfully');
  }

  /// Store last successful Google account for silent login
  Future<void> _storeLastGoogleAccount(GoogleSignInAccount account) async {
    final accountData = {
      'email': account.email,
      'displayName': account.displayName ?? 'User',
      'photoUrl': account.photoUrl,
      'id': account.id,
      'lastLogin': DateTime.now().toIso8601String(),
    };

    final accountJson = jsonEncode(accountData);
    await _prefs.setString('last_google_account', accountJson);
    AppLogger.auth('✅ Stored Google account: ${account.email}');
  }

  /// Retrieve last Google account for "Continue as [Name]" UI
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    final accountData = _prefs.getString('last_google_account');
    if (accountData == null) return null;

    try {
      return jsonDecode(accountData) as Map<String, dynamic>;
    } catch (error) {
      AppLogger.error('AuthRepository: Failed to decode account data - $error');
      // Clean corrupted data
      await _prefs.remove('last_google_account');
      return null;
    }
  }

  /// Silent sign-in with Google (no UI interaction)
  Future<GoogleSignInAccount?> signInSilently() async {
    AppLogger.auth('🔍 Attempting silent Google sign-in...');

    try {
      final googleUser = await GoogleSignIn().signInSilently().timeout(
        const Duration(seconds: 5), // Fast timeout for UX
        onTimeout: () => null,
      );

      if (googleUser != null) {
        // Store for future silent logins
        await _storeLastGoogleAccount(googleUser);
        AppLogger.auth('✅ Silent Google sign-in successful');
        return googleUser;
      } else {
        AppLogger.auth('❌ Silent sign-in returned null');
      }
    } catch (error) {
      AppLogger.error('AuthRepository: Silent sign-in failed - $error');
    }

    return null;
  }

  /// Google sign-in with account picker
  Future<GoogleSignInAccount?> signInWithGoogle([bool forceAccountPicker = false]) async {
    try {
      final googleUser = forceAccountPicker
          ? await GoogleSignIn().signIn() // Force account picker
          : await signInSilently();       // Try silent first

      if (googleUser != null) {
        // Store successful account
        await _storeLastGoogleAccount(googleUser);
        return googleUser;
      }
    } catch (error) {
      AppLogger.error('AuthRepository: Google sign-in failed - $error');
    }

    return null;
  }

  /// Authenticate with Firebase using Google credential
  Future<User?> authenticateWithFirebase(AuthCredential credential) async {
    try {
      final authResult = await _auth.signInWithCredential(credential);
      final user = authResult.user;

      if (user != null) {
        AppLogger.auth('✅ Firebase authentication successful: ${user.email}');
        return user;
      } else {
        AppLogger.error('AuthRepository: Firebase returned null user');
      }
    } catch (error) {
      AppLogger.error('AuthRepository: Firebase authentication failed - $error');
    }

    return null;
  }

  /// Listen to Firebase auth state changes
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Check if user is currently authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }
}
