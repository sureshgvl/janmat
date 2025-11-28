import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/performance_monitor.dart';
import '../../../services/background_sync_manager.dart';
import '../../../services/fcm_service.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackgroundSyncManager _syncManager = BackgroundSyncManager();
  final FCMService _fcmService = FCMService();

  // 🔒 SIGN-IN MUTEX to prevent "Future already completed"
  bool _isSigningIn = false;

  // SINGLETON GoogleSignIn instance - prevents multiple conflicting instances
  static GoogleSignIn? _sharedGoogleSignIn;

  GoogleAuthService() {
    // Initialize services but don't create GoogleSignIn here to avoid conflicts
  }

  // Get the singleton GoogleSignIn instance
  static GoogleSignIn get _googleSignInInstance {
    _sharedGoogleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      // Don't set clientId here for web - it gets it from the meta tag
    );
    return _sharedGoogleSignIn!;
  }

  // Public getter for shared GoogleSignIn instance (singleton)
  static GoogleSignIn get sharedGoogleSignIn => _googleSignInInstance;

  // Check network connectivity before attempting Google Sign-In
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);
      AppLogger.network('Network connectivity check: ${hasConnection ? 'Connected' : 'No connection'}', tag: 'CONNECTIVITY');
      return hasConnection;
    } catch (e) {
      AppLogger.network('Could not check connectivity: $e', tag: 'CONNECTIVITY');
      return true; // Assume connected if check fails
    }
  }

  // Google Sign-In - Platform-specific implementation with MUTEX
  Future<UserCredential?> signInWithGoogle({bool forceAccountPicker = false}) async {
    // 🔒 MUTEX: Prevent duplicate sign-in attempts
    if (_isSigningIn) {
      AppLogger.auth('⚠️ Sign-in already in progress, ignoring duplicate request');
      return null;
    }

    _isSigningIn = true;
    AppLogger.auth('🚀 Starting Google Sign-In...');

    try {
      if (kIsWeb) {
        // Web implementation: Use Firebase Auth popup
        AppLogger.auth('🌐 Attempting Google Sign-In popup...');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential = await _firebaseAuth.signInWithPopup(googleProvider);

        AppLogger.auth('✅ Google Sign-In successful: ${userCredential.user?.displayName}');
        AppLogger.auth('📧 Email: ${userCredential.user?.email}');
        AppLogger.auth('🆔 UID: ${userCredential.user?.uid}');

        // Create/update user record
        await _createOrUpdateUserMinimal(userCredential.user!);

        return userCredential;
      } else {
        // Mobile/Android implementation: Use GoogleSignIn package
        AppLogger.auth('📱 Attempting Google Sign-In on mobile...');

        final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();

        if (googleUser == null) {
          throw 'Google sign-in was cancelled by user';
        }

        AppLogger.auth('✅ Google account selected: ${googleUser.email}');

        // Get authentication credentials
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create Firebase credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

        AppLogger.auth('✅ Firebase authentication successful: ${userCredential.user?.displayName}');
        AppLogger.auth('📧 Email: ${userCredential.user?.email}');
        AppLogger.auth('🆔 UID: ${userCredential.user?.uid}');

        // Store Google account info for UX
        await _storeLastGoogleAccount(googleUser);

        // Create/update user record
        await _createOrUpdateUserMinimal(userCredential.user!);

        return userCredential;
      }

    } catch (e) {
      AppLogger.auth('❌ Google Sign-In failed: ${e.toString()}');

      // Categorize errors for better error messages
      if (e.toString().contains('popup-blocked')) {
        throw 'Please allow popups for this site to sign in with Google';
      } else if (e.toString().contains('cancelled') || e.toString().contains('was cancelled by user')) {
        throw 'Sign-in was cancelled';
      } else if (e.toString().contains('network')) {
        throw 'Network error - please check your connection';
      } else if (e.toString().contains('sign_in_failed')) {
        throw 'Google sign-in failed - please try again';
      } else if (e.toString().contains('invalid_client')) {
        throw 'Google authentication configuration error';
      } else {
        throw 'Sign-in failed: ${e.toString()}';
      }
    } finally {
      // 🔒Always reset mutex
      _isSigningIn = false;
    }
  }

  // Prepare user data locally (fast operation)
  Future<Map<String, dynamic>> _prepareUserDataLocally(GoogleSignInAccount googleUser) async {
    AppLogger.auth('📋 Preparing user data locally...');

    final userData = {
      'name': googleUser.displayName ?? 'User',
      'email': googleUser.email,
      'photoURL': googleUser.photoUrl,
      'preparedAt': DateTime.now().toIso8601String(),
    };

    // Cache locally for immediate access
    // await _cacheService.cacheTempUserData(userData);

    AppLogger.auth('✅ User data prepared locally');
    return userData;
  }

  // Create minimal user record (fast operation)
  Future<void> _createOrUpdateUserMinimal(User firebaseUser) async {
    startPerformanceTimer('minimal_user_creation');

    try {
      AppLogger.auth('👤 Creating minimal user record...');

      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);

      // Only store essential login data immediately
      final minimalData = {
        'uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': FieldValue.increment(1),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use set with merge for atomic operation
      await userDoc.set(minimalData, SetOptions(merge: true));

      AppLogger.auth('✅ Minimal user record created');
    } catch (e) {
      AppLogger.auth('Error creating minimal user record: $e');
      rethrow;
    } finally {
      stopPerformanceTimer('minimal_user_creation');
    }
  }

  // Perform background setup operations (non-blocking)
  void _performBackgroundSetup(User user) {
    AppLogger.auth('🔄 Starting background setup...');

    // Use the background sync manager for comprehensive sync
    _syncManager.performFullBackgroundSync(user);
  }

  // Update user's FCM token for push notifications
  Future<void> _updateUserFCMToken(User user) async {
    try {
      AppLogger.auth('📱 Updating FCM token for user: ${user.uid}');

      // Get current FCM token
      final fcmToken = await _fcmService.getCurrentToken();

      if (fcmToken != null) {
        // Update token in user's document
        await _fcmService.updateUserFCMToken(user.uid, fcmToken);
        AppLogger.auth('✅ FCM token updated for user: ${user.uid}');
      } else {
        AppLogger.auth('⚠️ No FCM token available for user: ${user.uid}');
      }
    } catch (e) {
      AppLogger.auth('Error updating FCM token: $e');
      // Don't throw - FCM token update failure shouldn't break authentication
    }
  }

  // Store last used Google account info for smart login UX - Enhanced Version
  Future<void> _storeLastGoogleAccount(GoogleSignInAccount account) async {
    try {
      // Validate account data before storing
      if (account.email == null || account.email.isEmpty) {
        AppLogger.auth('⚠️ Cannot store Google account: email is null or empty');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final accountData = {
        'email': account.email,
        'displayName': account.displayName ?? 'User',
        'photoUrl': account.photoUrl,
        'id': account.id,
        'lastLogin': DateTime.now().toIso8601String(),
        'serverAuthCode': account.serverAuthCode, // For enhanced security
        'version': '2.0', // Version for future migrations
      };

      // Properly encode as JSON string with error handling
      final accountJson = jsonEncode(accountData);
      await prefs.setString('last_google_account', accountJson);

      // Also store backup copy for recovery
      await prefs.setString('last_google_account_backup', accountJson);

      AppLogger.auth('✅ Enhanced account storage: ${account.email} (v2.0 with backup)');
    } catch (e) {
      AppLogger.auth('⚠️ Error storing last Google account: $e');
      // Try to store minimal data as fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final minimalData = {
          'email': account.email ?? 'unknown',
          'displayName': account.displayName ?? 'User',
          'lastLogin': DateTime.now().toIso8601String(),
          'version': '1.0', // Fallback version
        };
        await prefs.setString('last_google_account', jsonEncode(minimalData));
        AppLogger.auth('✅ Fallback account storage successful');
      } catch (fallbackError) {
        AppLogger.auth('⚠️ Fallback account storage also failed: $fallbackError');
      }
    }
  }

  // Get last used Google account info - Enhanced with recovery and validation
  Future<Map<String, dynamic>?> getLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? accountData = prefs.getString('last_google_account');

      // If primary data is missing, try backup
      if (accountData == null) {
        AppLogger.auth('ℹ️ Primary account data not found, checking backup...');
        accountData = prefs.getString('last_google_account_backup');

        if (accountData == null) {
          AppLogger.auth('ℹ️ No stored Google account found (primary or backup)');
          return null;
        } else {
          AppLogger.auth('📋 Found backup Google account data, restoring...');
          // Restore from backup to primary
          await prefs.setString('last_google_account', accountData);
        }
      }

      AppLogger.auth('📋 Found stored Google account data');

      // Parse the stored JSON string
      final accountMap = jsonDecode(accountData) as Map<String, dynamic>;

      // Validate the account data structure
      if (!_isValidAccountData(accountMap)) {
        AppLogger.auth('⚠️ Invalid account data structure, clearing...');
        await prefs.remove('last_google_account');
        return null;
      }

      // Check if account data is too old (older than 30 days)
      final lastLoginStr = accountMap['lastLogin'] as String?;
      if (lastLoginStr != null) {
        try {
          final lastLogin = DateTime.parse(lastLoginStr);
          final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;

          if (daysSinceLogin > 30) {
            AppLogger.auth('⚠️ Account data is ${daysSinceLogin} days old, clearing for security');
            await prefs.remove('last_google_account');
            await prefs.remove('last_google_account_backup');
            return null;
          }
        } catch (e) {
          AppLogger.auth('⚠️ Could not parse last login date: $e');
          // Continue with the data but log the issue
        }
      }

      AppLogger.auth('✅ Successfully parsed and validated stored account: ${accountMap['displayName']} (${accountMap['email']})');

      return accountMap;
    } catch (e) {
      AppLogger.auth('⚠️ Error retrieving last Google account: $e');
      // Clear corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_google_account');
        await prefs.remove('last_google_account_backup');
        AppLogger.auth('🧹 Cleared corrupted account data (primary and backup)');
      } catch (clearError) {
        AppLogger.auth('⚠️ Error clearing corrupted data: $clearError');
      }
      return null;
    }
  }

  // Validate account data structure
  bool _isValidAccountData(Map<String, dynamic> accountData) {
    // Check for required fields
    final requiredFields = ['email', 'displayName'];
    for (final field in requiredFields) {
      if (!accountData.containsKey(field) || accountData[field] == null) {
        AppLogger.auth('⚠️ Missing required field: $field');
        return false;
      }
    }

    // Validate email format
    final email = accountData['email'] as String;
    if (!email.contains('@') || !email.contains('.')) {
      AppLogger.auth('⚠️ Invalid email format: $email');
      return false;
    }

    return true;
  }

  // Clear stored Google account info (on logout) - Enhanced to clear both primary and backup
  Future<void> clearLastGoogleAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_google_account');
      await prefs.remove('last_google_account_backup');
      AppLogger.auth('✅ Cleared last Google account info (primary and backup)');
    } catch (e) {
      AppLogger.auth('⚠️ Error clearing last Google account: $e');
    }
  }

  // Sign out from Google and clear all auth data
  Future<void> signOutFromGoogle() async {
    try {
      // Sign out from Firebase first
      await FirebaseAuth.instance.signOut();
      AppLogger.auth('✅ Firebase user signed out');

      // Sign out from Google Sign-In
      await _googleSignInInstance.signOut();
      AppLogger.auth('✅ Google account signed out');

      // Clear all cached auth data
      await clearLastGoogleAccount();
      AppLogger.auth('✅ Auth cache cleared');

    } catch (e) {
      AppLogger.auth('⚠️ Sign out error: $e');
    }
  }

  // 🔥 COMPLETE FIREBASE AUTH RESET - for when auth gets corrupted
  Future<void> resetFirebaseAuth() async {
    AppLogger.auth('🔥 Starting COMPLETE Firebase Auth Reset...');

    try {
      // Step 1: Sign out from everything
      await signOutFromGoogle();

      // Step 2: Disconnect Firebase Auth listeners temporarily
      FirebaseAuth.instance.authStateChanges().listen((user) {
        AppLogger.auth('🔄 Auth state during reset: ${user?.uid ?? 'null'}');
      });

      // Step 3: Clear local storage and preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.auth('🧹 SharedPreferences cleared');

      // Step 4: Force Firebase to clean state
      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 100));

      AppLogger.auth('✅ Firebase Auth completely reset');
      AppLogger.auth('🎯 Now try Google Sign-In again - should be clean');

    } catch (e) {
      AppLogger.auth('❌ Reset failed: $e');
    }
  }
}
