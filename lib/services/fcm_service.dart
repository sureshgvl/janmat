import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../utils/app_logger.dart';
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
      AppLogger.fcm('✅ Local notification service initialized');

      // Configure FCM to NOT show notifications automatically
      // We'll handle all notifications manually through local notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false, // Don't show alert
        badge: true,  // Update badge
        sound: false, // Don't play sound
      );
      AppLogger.fcm('✅ FCM configured to not show automatic notifications');

      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.fcm('🔐 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.fcm('✅ FCM permissions granted');
      } else {
        AppLogger.fcm('❌ FCM permissions denied');
      }

      // Get FCM token and store it
      _currentToken = await _firebaseMessaging.getToken();
      if (_currentToken != null) {
        AppLogger.fcm('🎫 FCM Token obtained successfully');
      } else {
        AppLogger.fcm('❌ Failed to get FCM token');
      }

      // Listen for token refresh with improved handling
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        AppLogger.fcm('🔄 FCM token refreshed');
        _handleTokenRefresh(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages with local notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.fcm('📱 Received foreground message: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.fcm('🚀 App opened from notification: ${message.notification?.title}');
        _handleMessageOpenedApp(message);
      });

    } catch (e) {
      AppLogger.fcmError('❌ Error initializing FCM', error: e);
    }
  }

  // Update FCM token in user's document
  Future<void> updateUserFCMToken(String userId, String? token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      AppLogger.fcm('💾 Updated FCM token for user: $userId');
    } catch (e) {
      AppLogger.fcmError('❌ Error updating FCM token', error: e);
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
      AppLogger.fcmError('❌ Error getting current FCM token', error: e);
      return null;
    }
  }

  // Handle token refresh with improved logic
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      // Store the new token
      final oldToken = _currentToken;
      _currentToken = newToken;

      AppLogger.fcm('🔄 Token refresh completed');

      // If we have an old token, find and update all users with that token
      if (oldToken != null && oldToken != newToken) {
        final usersSnapshot = await _firestore
            .collection('users')
            .where('fcmToken', isEqualTo: oldToken)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          AppLogger.fcm('📝 Updating ${usersSnapshot.docs.length} user documents with new token');

          // Update each user document with the new token
          for (final doc in usersSnapshot.docs) {
            await doc.reference.update({
              'fcmToken': newToken,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
          }

          AppLogger.fcm('✅ Token updated for ${usersSnapshot.docs.length} users');
        } else {
          AppLogger.fcm('ℹ️ No users found with old token - token may not be stored yet');
        }
      } else {
        AppLogger.fcm('ℹ️ First token or same token - no database update needed');
      }
    } catch (e) {
      AppLogger.fcmError('❌ Error handling token refresh', error: e);
      // Don't throw - token refresh should not break the app
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    AppLogger.fcm('🛌 Handling background message: ${message.messageId}');
    AppLogger.fcm('📊 Background message data: ${message.data}');

    // Extract notification details from data payload
    final title = message.data['title'] ?? 'JanMat';
    final body = message.data['body'] ?? 'You have a new notification';

    // For background messages, we need to show local notification
    // since FCM won't auto-show system notifications with data-only payloads
    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialize();

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    localNotificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: message.data.toString(),
    );

    AppLogger.fcm('🔔 Background local notification shown: $title');
  }

  // Handle foreground messages with local notifications
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.fcm('📱 Foreground message received');
    AppLogger.fcm('📊 Message data: ${message.data}');
    AppLogger.fcm('📱 Message notification: ${message.notification}');

    // Extract notification details from data payload
    final title = message.data['title'] ?? 'JanMat';
    final body = message.data['body'] ?? 'You have a new notification';

    // Generate unique ID based on timestamp to avoid conflicts
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    _localNotificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: message.data.toString(),
    );

    AppLogger.fcm('🔔 Local notification shown for foreground message: $title');

    // If FCM still shows a system notification despite data-only payload,
    // immediately cancel it to prevent duplicate notifications
    if (message.notification != null) {
      AppLogger.fcm('⚠️ FCM showed system notification despite data-only payload, canceling...');
      Future.delayed(const Duration(milliseconds: 100), () {
        _localNotificationService.cancelNotification(notificationId);
        AppLogger.fcm('✅ Canceled duplicate system notification');
      });
    }

    // You can also update app state or trigger other actions here
    // For example, refresh data, update badges, etc.
  }

  // Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navigate to appropriate screen based on notification data
    AppLogger.fcm('🚀 Message opened app: ${message.data}');

    // Extract notification type and navigate accordingly
    final type = message.data['type'];
    if (type != null) {
      _navigateBasedOnNotificationType(type, message.data);
    }
  }

  // Navigate based on notification type
  void _navigateBasedOnNotificationType(String type, Map<String, dynamic> data) {
    // This would integrate with your app's navigation system
    AppLogger.fcm('🎯 Navigating based on notification type: $type');

    switch (type) {
      case 'new_follower':
        // Navigate to candidate profile
        AppLogger.fcm('👤 Navigate to candidate profile: ${data['candidateId']}');
        break;
      case 'event_rsvp':
        // Navigate to event details
        AppLogger.fcm('📅 Navigate to event: ${data['eventId']}');
        break;
      case 'new_message':
        // Navigate to chat
        AppLogger.fcm('💬 Navigate to chat');
        break;
      default:
        AppLogger.fcm('❓ Unknown notification type: $type');
    }
  }

  // Subscribe to topic (for broadcasting to multiple users)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.fcm('📢 Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.fcmError('❌ Error subscribing to topic', error: e);
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.fcm('🔕 Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.fcmError('❌ Error unsubscribing from topic', error: e);
    }
  }

  // Check notification permissions
  Future<bool> hasNotificationPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      AppLogger.fcmError('❌ Error checking notification permission', error: e);
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
      AppLogger.fcmError('❌ Error requesting notification permission', error: e);
      return false;
    }
  }
}
