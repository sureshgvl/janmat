import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/app_logger.dart';

/// Manages FCM token synchronization across user and candidate profiles
class UserTokenManager {
  static final UserTokenManager _instance = UserTokenManager._internal();
  factory UserTokenManager() => _instance;
  UserTokenManager._internal();

  bool _isInitialized = false;
  Stream<String>? _tokenRefreshStream;

  /// Initialize FCM token management - call once in app startup
  Future<void> initialize() async {
    if (kIsWeb) {
      AppLogger.common('📱 WEB: Skipping FCM token management (not supported on web)');
      _isInitialized = true; // Mark as initialized to prevent retries
      return;
    }

    if (_isInitialized) return;

    try {
      AppLogger.common('🔄 Initializing FCM token management...');

      // Setup token refresh listener
      _tokenRefreshStream = FirebaseMessaging.instance.onTokenRefresh;
      _tokenRefreshStream?.listen(_onTokenRefreshed);

      // Validate and update current token
      await _validateAndUpdateCurrentToken();

      _isInitialized = true;
      AppLogger.common('✅ FCM token management initialized successfully');

    } catch (e) {
      AppLogger.commonError('❌ Failed to initialize FCM token management', error: e);
      rethrow;
    }
  }

  /// Call after user authentication/login
  Future<void> onUserAuthenticated() async {
    if (kIsWeb) {
      AppLogger.common('📱 WEB: Skipping FCM token update after authentication');
      return;
    }

    try {
      AppLogger.common('🔐 User authenticated - updating FCM tokens...');
      await _validateAndUpdateCurrentToken();
      AppLogger.common('✅ FCM tokens updated after authentication');
    } catch (e) {
      AppLogger.commonError('❌ Failed to update FCM tokens after authentication', error: e);
      // Don't throw - auth should continue even if token update fails
    }
  }

  /// Force token update (useful for testing or manual refresh)
  Future<void> forceTokenUpdate() async {
    if (kIsWeb) return;
    await _validateAndUpdateCurrentToken();
  }

  /// Check if candidate profiles have FCM tokens and update if missing
  Future<void> ensureCandidateTokens() async {
    if (kIsWeb) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get user's FCM token
      final currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken == null) return;

      // Find candidates without FCM tokens or with different tokens
      final candidateQuery = await FirebaseFirestore.instance
          .collectionGroup('candidates')
          .where('userId', isEqualTo: user.uid)
          .get();

      int updatedCount = 0;
      for (var candidateDoc in candidateQuery.docs) {
        final candidateData = candidateDoc.data();
        final existingToken = candidateData['fcmToken'] as String?;

        if (existingToken != currentToken) {
          await candidateDoc.reference.set({
            'fcmToken': currentToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        AppLogger.common('🔄 Updated FCM tokens in $updatedCount candidate profiles');
      }

    } catch (e) {
      AppLogger.commonError('❌ Failed to ensure candidate tokens', error: e);
    }
  }

  /// Handle FCM token refresh events
  Future<void> _onTokenRefreshed(String newToken) async {
    try {
      AppLogger.common('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
      await _updateTokenInAllProfiles(newToken);
      AppLogger.common('✅ Token refresh handled successfully');
    } catch (e) {
      AppLogger.commonError('❌ Failed to handle token refresh', error: e);
    }
  }

  /// Validate current token and update if necessary
  Future<void> _validateAndUpdateCurrentToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.common('⚠️ No authenticated user - skipping token validation');
        return;
      }

      // Get current FCM token
      final currentToken = await FirebaseMessaging.instance.getToken();
      if (currentToken == null) {
        AppLogger.commonError('❌ Failed to get FCM token');
        return;
      }

      // Get stored token from user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final storedToken = userDoc.data()?['fcmToken'] as String?;

      // Update if tokens don't match
      if (currentToken != storedToken) {
        AppLogger.common('🔄 Token mismatch detected - updating all profiles');
        await _updateTokenInAllProfiles(currentToken);
      } else {
        AppLogger.common('✅ FCM token is up-to-date');
      }

    } catch (e) {
      AppLogger.commonError('❌ Failed to validate FCM token', error: e);
    }
  }

  /// Update FCM token in user profile and all candidate profiles
  Future<void> _updateTokenInAllProfiles(String newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      AppLogger.common('🔄 Updating FCM token for user: ${user.uid}');

      // 1. Update user profile (always exists after auth so we can use update)
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      AppLogger.common('✅ User profile FCM token updated');

      // 2. Find and update all candidate profiles for this user
      final candidateQuery = await FirebaseFirestore.instance
          .collectionGroup('candidates')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (candidateQuery.docs.isNotEmpty) {
        AppLogger.common('📝 Found ${candidateQuery.docs.length} candidate profiles to update');

        // Use individual updates instead of batch since batch.update fails if doc doesn't exist
        // Use merge: true to create if missing or update if exists
        for (var candidateDoc in candidateQuery.docs) {
          await candidateDoc.reference.set({
            'fcmToken': newToken,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));  // This will create or update
        }

        AppLogger.common('✅ Updated FCM tokens in ${candidateQuery.docs.length} candidate profiles');
      } else {
        AppLogger.common('ℹ️ No candidate profiles found for user - tokens will be set during candidate creation');
      }

      AppLogger.common('✅ FCM token update completed successfully');

    } catch (e) {
      AppLogger.commonError('❌ Failed to update FCM token in profiles', error: e);
      // Don't throw - FCM token issues shouldn't crash the app
      // Tokens will be set next time they change or during candidate creation
    }
  }

  /// Clean up resources
  void dispose() {
    _tokenRefreshStream = null;
    _isInitialized = false;
  }
}
