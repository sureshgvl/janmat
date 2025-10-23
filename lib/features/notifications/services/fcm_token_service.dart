import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service responsible for FCM token management
class FCMTokenService {
  final FirebaseMessaging _firebaseMessaging;
  final FirebaseFirestore _firestore;

  // Store current token for comparison during refresh
  String? _currentToken;

  FCMTokenService({
    FirebaseMessaging? firebaseMessaging,
    FirebaseFirestore? firestore,
  }) :
    _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
    _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize token service and set up token refresh listener
  Future<void> initialize() async {
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Get initial token
    _currentToken = await _firebaseMessaging.getToken();
  }

  /// Get current FCM token (from cache if available, otherwise fetch)
  Future<String?> getCurrentToken() async {
    try {
      // Return cached token if available
      if (_currentToken != null) {
        return _currentToken;
      }

      // Otherwise fetch from Firebase
      _currentToken = await _firebaseMessaging.getToken();
      return _currentToken;
    } catch (e) {
      throw Exception('Failed to get FCM token: $e');
    }
  }

  /// Update FCM token in user's document
  Future<void> updateUserFCMToken(String userId, String? token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  /// Handle token refresh with improved logic
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      // Store the new token
      final oldToken = _currentToken;
      _currentToken = newToken;

      // If we have an old token, find and update all users with that token
      if (oldToken != null && oldToken != newToken) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isEqualTo: oldToken)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          // Update each user document with the new token
          final batch = _firestore.batch();
          for (final doc in usersSnapshot.docs) {
            batch.update(doc.reference, {
              'fcmToken': newToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }
      }
    } catch (e) {
      // Don't throw - token refresh should not break the app
      // Log error for debugging
      print('Error handling token refresh: $e');
    }
  }

  /// Get FCM token for a specific user
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user FCM token: $e');
    }
  }

  /// Delete FCM token for a user (logout, etc.)
  Future<void> deleteUserFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete FCM token: $e');
    }
  }
}
