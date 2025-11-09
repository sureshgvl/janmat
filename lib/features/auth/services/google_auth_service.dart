import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/performance_monitor.dart';
import '../../../services/background_sync_manager.dart';
import '../../../services/fcm_service.dart';
import '../../../features/user/services/user_cache_service.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final UserCacheService _cacheService = UserCacheService();
  final BackgroundSyncManager _syncManager = BackgroundSyncManager();
  final FCMService _fcmService = FCMService();

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

  // Google Sign-In - Optimized for Release Build Performance
  Future<UserCredential?> signInWithGoogle({bool forceAccountPicker = false}) async {
    final startTime = DateTime.now();
    startPerformanceTimer('google_signin_release_optimized');

    AppLogger.auth('🚀 Starting RELEASE-OPTIMIZED Google Sign-In at ${startTime.toIso8601String()}');

    try {
      // RELEASE OPTIMIZATION: Skip connectivity check for faster startup
      // App Check and Firebase will handle network issues
      AppLogger.auth('⚡ [RELEASE_OPTIMIZED] Skipping connectivity check for speed');

      GoogleSignInAccount? googleUser;

      // RELEASE OPTIMIZATION: Skip silent sign-in for first-time users
      // Go directly to account picker for faster UX
      if (!forceAccountPicker) {
        // Try silent sign-in with shorter timeout (2s instead of 5s)
        AppLogger.auth('🔍 [RELEASE_OPTIMIZED] Quick silent sign-in attempt...');
        try {
          googleUser = await _googleSignIn.signInSilently().timeout(
            const Duration(seconds: 2), // Reduced from 5s for faster UX
            onTimeout: () {
              AppLogger.auth('⏰ [RELEASE_OPTIMIZED] Silent sign-in timeout after 2s');
              return null;
            },
          );
          if (googleUser != null) {
            AppLogger.auth('✅ [RELEASE_OPTIMIZED] Silent sign-in successful: ${googleUser.displayName}');
          }
        } catch (e) {
          AppLogger.auth('ℹ️ [RELEASE_OPTIMIZED] Silent sign-in failed, proceeding to picker');
        }
      }

      // If silent failed or forced picker requested, show account picker
      if (googleUser == null) {
        AppLogger.auth('📱 [RELEASE_OPTIMIZED] Showing Google account picker...');

        final signInStart = DateTime.now();
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30), // Reduced from 45s for faster UX
          onTimeout: () {
            final timeoutDuration = DateTime.now().difference(signInStart);
            AppLogger.auth('⏰ [RELEASE_OPTIMIZED] Account picker timeout after ${timeoutDuration.inSeconds}s');
            throw Exception('Google Sign-In timed out. Please try again.');
          },
        );

        final signInDuration = DateTime.now().difference(signInStart);
        AppLogger.auth('✅ [RELEASE_OPTIMIZED] Account picker completed in ${signInDuration.inSeconds}s');
      }

      if (googleUser == null) {
        final totalDuration = DateTime.now().difference(startTime);
        stopPerformanceTimer('google_signin_release_optimized');
        AppLogger.auth('[RELEASE_OPTIMIZED] User cancelled Google Sign-In after ${totalDuration.inSeconds}s');
        return null;
      }

      AppLogger.auth('✅ [RELEASE_OPTIMIZED] Google account selected: ${googleUser.displayName}');

      // RELEASE OPTIMIZATION: Store account info asynchronously (don't await)
      _storeLastGoogleAccount(googleUser); // Fire-and-forget

      // RELEASE OPTIMIZATION: Get tokens and prepare data in parallel with reduced logging
      final parallelStart = DateTime.now();

      final tokenFuture = googleUser.authentication;
      final userDataPrepFuture = _prepareUserDataLocally(googleUser);

      final parallelResults = await Future.wait([tokenFuture, userDataPrepFuture]);
      final parallelDuration = DateTime.now().difference(parallelStart);

      AppLogger.auth('✅ [RELEASE_OPTIMIZED] Parallel operations completed in ${parallelDuration.inMilliseconds}ms');

      final GoogleSignInAuthentication googleAuth = parallelResults[0] as GoogleSignInAuthentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to retrieve authentication tokens from Google';
      }

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // RELEASE OPTIMIZATION: Firebase auth with shorter timeout (30s instead of 45s)
      final firebaseStart = DateTime.now();

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30), // Reduced from 45s for faster UX
            onTimeout: () {
              AppLogger.auth('⏰ [RELEASE_OPTIMIZED] Firebase auth timeout after 30s');
              throw Exception('Authentication is taking longer than expected. Please try again.');
            },
          );

      final firebaseDuration = DateTime.now().difference(firebaseStart);
      AppLogger.auth('✅ [RELEASE_OPTIMIZED] Firebase auth successful in ${firebaseDuration.inMilliseconds}ms');

      // RELEASE OPTIMIZATION: Create minimal user record asynchronously for faster navigation
      _createOrUpdateUserMinimal(userCredential.user!); // Fire-and-forget

      // RELEASE OPTIMIZATION: Move all background operations to true background
      // Don't block navigation for any setup operations
      Future.delayed(const Duration(milliseconds: 500), () {
        _performBackgroundSetup(userCredential.user!);
        _updateUserFCMToken(userCredential.user!);
      });

      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_release_optimized');

      AppLogger.auth('🎉 [RELEASE_OPTIMIZED] Google Sign-In completed in ${totalDuration.inSeconds}s');
      AppLogger.auth('📊 [RELEASE_OPTIMIZED] Breakdown: Parallel=${parallelDuration.inMilliseconds}ms, Firebase=${firebaseDuration.inMilliseconds}ms');

      return userCredential;
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      stopPerformanceTimer('google_signin_optimized');

      AppLogger.auth('[GOOGLE_SIGNIN] Google Sign-In failed after ${totalDuration.inSeconds}s');

      AppLogger.auth('[GOOGLE_SIGNIN] Error details: ${e.toString()}');
      AppLogger.auth('[GOOGLE_SIGNIN] Error type: ${e.runtimeType}');
      // Handle the special case where auth succeeded but timed out
      if (e.toString() == 'AUTH_SUCCESS_BUT_TIMEOUT') {
        AppLogger.auth('✅ [GOOGLE_SIGNIN] Handling successful authentication that timed out');

        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          AppLogger.auth('✅ [GOOGLE_SIGNIN] Proceeding with authenticated user: ${currentUser.displayName} (UID: ${currentUser.uid})');

          // Minimal user data for successful auth
          AppLogger.auth('👤 [GOOGLE_SIGNIN] Creating minimal user record for timeout recovery...');
          final recoveryStart = DateTime.now();
          await _createOrUpdateUserMinimal(currentUser);
          final recoveryDuration = DateTime.now().difference(recoveryStart);
          AppLogger.auth('✅ [GOOGLE_SIGNIN] Recovery user record created in ${recoveryDuration.inMilliseconds}ms');

          // Background setup
          _performBackgroundSetup(currentUser);
          AppLogger.auth('✅ [GOOGLE_SIGNIN] Background setup initiated for timeout recovery');

          AppLogger.auth('🎉 [GOOGLE_SIGNIN] Google Sign-In completed successfully despite timeout');
          return null; // Return null to indicate success but no UserCredential
        } else {
          AppLogger.auth('[GOOGLE_SIGNIN] Timeout recovery failed - no current user found');
        }
      }

      // Categorize and provide more specific error messages
      String errorCategory = 'unknown';
      String userMessage = 'Sign-in failed';

      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        errorCategory = 'network';
        userMessage = 'Network error during sign-in. Please check your internet connection and try again.';
        AppLogger.auth('🌐 [GOOGLE_SIGNIN] Network-related error detected');
      } else if (e.toString().contains('cancelled') || e.toString().contains('CANCELLED')) {
        errorCategory = 'user_cancelled';
        userMessage = 'Sign-in was cancelled.';
        AppLogger.auth('🚫 [GOOGLE_SIGNIN] User cancelled the sign-in process');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('SIGN_IN_FAILED')) {
        errorCategory = 'auth_failed';
        userMessage = 'Authentication failed. Please try again.';
        AppLogger.auth('🔐 [GOOGLE_SIGNIN] Authentication failure detected');
      } else if (e.toString().contains('account') || e.toString().contains('ACCOUNT')) {
        errorCategory = 'account_issue';
        userMessage = 'Account selection failed. Please try selecting a different account.';
        AppLogger.auth('👤 [GOOGLE_SIGNIN] Account-related error detected');
      } else if (e.toString().contains('Firebase authentication timed out')) {
        errorCategory = 'firebase_timeout';
        userMessage = 'Sign-in is taking longer than expected. Please wait a moment and try again.';
        AppLogger.auth('⏰ [GOOGLE_SIGNIN] Firebase authentication timeout detected');
      } else {
        errorCategory = 'unknown';
        userMessage = 'Sign-in failed: ${e.toString()}';
        AppLogger.auth('❓ [GOOGLE_SIGNIN] Unknown error category');
      }

      AppLogger.auth('📊 [GOOGLE_SIGNIN] Error summary:');
      AppLogger.auth('   - Category: $errorCategory');
      AppLogger.auth('   - Duration: ${totalDuration.inSeconds}s');
      AppLogger.auth('   - User message: $userMessage');

      throw userMessage;
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
    await _cacheService.cacheTempUserData(userData);

    AppLogger.auth('✅ User data prepared and cached locally');
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

  // Sign out from Google
  Future<void> signOutFromGoogle() async {
    await _googleSignIn.signOut();
    AppLogger.auth('✅ Google account signed out');
  }
}
