import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
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

      // Get FCM token
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        debugPrint('🎫 FCM Token: $fcmToken');
      } else {
        debugPrint('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM token refreshed: $newToken');
        // Update token in all user documents where this old token exists
        _updateTokenInDatabase(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
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

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('❌ Error getting current FCM token: $e');
      return null;
    }
  }

  // Update token in database when it refreshes
  Future<void> _updateTokenInDatabase(String newToken) async {
    try {
      // Find all users with the old token and update them
      // This is a simplified approach - in production you'd want to track token-user mapping
      final usersSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isEqualTo: newToken) // This won't work for refresh
          .get();

      // For token refresh, we need a different approach
      // Usually you'd store the current token and update it when it changes
      debugPrint('🔄 Token refresh detected, tokens should be updated via user login');
    } catch (e) {
      debugPrint('❌ Error updating token in database: $e');
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('🛌 Handling background message: ${message.messageId}');
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show in-app notification or handle the message
    debugPrint('📱 Foreground message: ${message.notification?.body}');

    // You could show a local notification here or update the UI
    // For now, we'll just log it
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