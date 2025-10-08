import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../services/local_notification_service.dart';
import '../../../utils/app_logger.dart';

/// Service responsible for handling FCM messages
class FCMMessageHandler {
  final FirebaseMessaging _firebaseMessaging;
  final LocalNotificationService _localNotificationService;

  FCMMessageHandler({
    FirebaseMessaging? firebaseMessaging,
    LocalNotificationService? localNotificationService,
  }) :
    _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
    _localNotificationService = localNotificationService ?? LocalNotificationService();

  /// Initialize message handlers
  Future<void> initialize() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    AppLogger.common('Handling background message: ${message.messageId}');
  }

  /// Handle foreground messages with local notifications
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.common('Received foreground message: ${message.notification?.title}');
    AppLogger.common('Message data: ${message.data}');

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

      AppLogger.common('Local notification shown for foreground message');
    }

    // You can also update app state or trigger other actions here
    // For example, refresh data, update badges, etc.
  }

  /// Handle when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.common('App opened from notification: ${message.data}');

    // Extract notification type and navigate accordingly
    final type = message.data['type'];
    if (type != null) {
      _navigateBasedOnNotificationType(type, message.data);
    }
  }

  /// Navigate based on notification type
  void _navigateBasedOnNotificationType(String type, Map<String, dynamic> data) {
    AppLogger.common('Navigating based on notification type: $type');

    switch (type) {
      case 'new_follower':
        // Navigate to candidate profile
        AppLogger.common('Navigate to candidate profile: ${data['candidateId']}');
        break;
      case 'event_rsvp':
        // Navigate to event details
        AppLogger.common('Navigate to event: ${data['eventId']}');
        break;
      case 'new_message':
        // Navigate to chat
        AppLogger.common('Navigate to chat');
        break;
      case 'poll_result':
        // Navigate to poll results
        AppLogger.common('Navigate to poll: ${data['pollId']}');
        break;
      case 'achievement':
        // Navigate to achievements
        AppLogger.common('Navigate to achievements');
        break;
      default:
        AppLogger.common('Unknown notification type: $type');
    }
  }

  /// Set up custom message handlers (optional)
  void setCustomForegroundHandler(Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }

  void setCustomOpenedAppHandler(Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// Get initial message (when app is opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await _firebaseMessaging.getInitialMessage();
    } catch (e) {
      throw Exception('Failed to get initial message: $e');
    }
  }
}
