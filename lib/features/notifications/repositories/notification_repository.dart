import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

/// Abstract repository interface for notification data operations
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId, {
    int limit = 50,
    NotificationModel? startAfter,
  });

  /// Get unread notifications count for a user
  Future<int> getUnreadCount(String userId);

  /// Create a new notification
  Future<String> createNotification(NotificationModel notification);

  /// Update an existing notification
  Future<void> updateNotification(String notificationId, NotificationModel notification);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId);

  /// Archive notification
  Future<void> archiveNotification(String notificationId);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId);

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId);

  /// Get notification preferences for a user
  Future<NotificationPreferences?> getUserPreferences(String userId);

  /// Update notification preferences for a user
  Future<void> updateUserPreferences(NotificationPreferences preferences);

  /// Stream of notifications for real-time updates
  Stream<List<NotificationModel>> getNotificationsStream(String userId, {
    int limit = 20,
  });

  /// Stream of unread count for real-time updates
  Stream<int> getUnreadCountStream(String userId);
}