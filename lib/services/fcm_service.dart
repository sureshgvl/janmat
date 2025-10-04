import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'local_notification_service.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  // Store current token for comparison during refresh
  String? _currentToken;

  // Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Initialize local notification service first
      await _localNotificationService.initialize();
      debugPrint('✅ Local notification service initialized');

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔐 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ FCM permissions granted');
      } else {
        debugPrint('❌ FCM permissions denied');
      }

      // Get FCM token and store it
      _currentToken = await _firebaseMessaging.getToken();
      if (_currentToken != null) {
        debugPrint('🎫 FCM Token: $_currentToken');
      } else {
        debugPrint('❌ Failed to get FCM token');
      }

      // Listen for token refresh with improved handling
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: $newToken');
        _handleTokenRefresh(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages with local notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📱 Received foreground message: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🚀 App opened from notification: ${message.notification?.title}');
        _handleMessageOpenedApp(message);
      });

    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  // Update FCM token in user's document
  Future<void> updateUserFCMToken(String userId, String? token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('💾 Updated FCM token for user: $userId');
    } catch (e) {
      debugPrint('❌ Error updating FCM token: $e');
    }
  }

  // Get current FCM token (from cache if available, otherwise fetch)
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
      debugPrint('❌ Error getting current FCM token: $e');
      return null;
    }
  }

  // Handle token refresh with improved logic
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      // Store the new token
      final oldToken = _currentToken;
      _currentToken = newToken;

      debugPrint('🔄 Token refresh: $oldToken -> $newToken');

      // If we have an old token, find and update all users with that token
      if (oldToken != null && oldToken != newToken) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isEqualTo: oldToken)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          debugPrint('📝 Updating ${usersSnapshot.docs.length} user documents with new token');

          // Update each user document with the new token
          for (final doc in usersSnapshot.docs) {
            await doc.reference.update({
              'fcmToken': newToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
          }

          debugPrint('✅ Token updated for ${usersSnapshot.docs.length} users');
        } else {
          debugPrint('ℹ️ No users found with old token - token may not be stored yet');
        }
      } else {
        debugPrint('ℹ️ First token or same token - no database update needed');
      }
    } catch (e) {
      debugPrint('❌ Error handling token refresh: $e');
      // Don't throw - token refresh should not break the app
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('🛌 Handling background message: ${message.messageId}');
  }

  // Handle foreground messages with local notifications
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message: ${message.notification?.body}');
    debugPrint('📊 Message data: ${message.data}');

    // Show local notification for foreground messages
    if (message.notification != null) {
      final title = message.notification!.title ?? 'JanMat';
      final body = message.notification!.body ?? 'You have a new notification';

      // Generate unique ID based on timestamp to avoid conflicts
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      _localNotificationService.showNotification(
        id: notificationId,
        title: title,
        body: body,
        payload: message.data.toString(),
      );

      debugPrint('🔔 Local notification shown for foreground message');
    }

    // You can also update app state or trigger other actions here
    // For example, refresh data, update badges, etc.
  }

  // Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    debugPrint('🚀 Message opened app: ${message.data}');

    // Extract notification type and navigate accordingly
    final type = message.data['type'];
    if (type != null) {
      _navigateBasedOnNotificationType(type, message.data);
    }
  }

  // Navigate based on notification type
  void _navigateBasedOnNotificationType(String type, Map<String, dynamic> data) {
    // This would integrate with your app's navigation system
    debugPrint('🎯 Navigating based on notification type: $type');

    switch (type) {
      case 'new_follower':
        // Navigate to candidate profile
        debugPrint('👤 Navigate to candidate profile: ${data['candidateId']}');
        break;
      case 'event_rsvp':
        // Navigate to event details
        debugPrint('📅 Navigate to event: ${data['eventId']}');
        break;
      case 'new_message':
        // Navigate to chat
        debugPrint('💬 Navigate to chat');
        break;
      default:
        debugPrint('❓ Unknown notification type: $type');
    }
  }

  // Subscribe to topic (for broadcasting to multiple users)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('🔕 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  // Check notification permissions
  Future<bool> hasNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      return false;
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }
}

