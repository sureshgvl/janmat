import '../models/notification_model.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';

/// Abstract controller interface for notification business logic
abstract class NotificationController {
  /// Initialize the controller
  Future<void> initialize();

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    NotificationModel? startAfter,
  });

  /// Get unread notifications count
  Future<int> getUnreadCount();

  /// Create a new notification
  Future<String> createNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  });

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId);

  /// Archive notification
  Future<void> archiveNotification(String notificationId);

  /// Delete notification
  Future<void> deleteNotification(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete all notifications
  Future<void> deleteAllNotifications();

  /// Get user notification preferences
  Future<NotificationPreferences> getUserPreferences();

  /// Update user notification preferences
  Future<void> updateUserPreferences(NotificationPreferences preferences);

  /// Check if a notification type is enabled
  Future<bool> isNotificationTypeEnabled(NotificationType type);

  /// Check if push notifications are enabled for a type
  Future<bool> isPushEnabled(NotificationType type);

  /// Check if in-app notifications are enabled for a type
  Future<bool> isInAppEnabled(NotificationType type);

  /// Stream of notifications for real-time updates
  Stream<List<NotificationModel>> getNotificationsStream({int limit = 20});

  /// Stream of unread count for real-time updates
  Stream<int> getUnreadCountStream();

  /// Send push notification (if enabled)
  Future<void> sendPushNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  });

  /// Send in-app notification (if enabled)
  Future<void> sendInAppNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  });

  /// Send both push and in-app notification
  Future<void> sendNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  });
}
