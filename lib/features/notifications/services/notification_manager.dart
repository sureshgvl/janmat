import '../controllers/notification_controller.dart';
import '../controllers/notification_controller_impl.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import 'notification_badge_service.dart';
import 'notification_scheduler_service.dart';
import 'notification_analytics_service.dart';

/// Centralized notification manager - main entry point for all notification operations
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;

  NotificationManager._internal();

  NotificationController? _controller;
  NotificationBadgeService? _badgeService;
  NotificationSchedulerService? _schedulerService;
  NotificationAnalyticsService? _analyticsService;

  /// Initialize the notification manager
  Future<void> initialize() async {
    _controller = NotificationControllerImpl();
    await _controller!.initialize();

    _badgeService = NotificationBadgeService();
    _schedulerService = NotificationSchedulerService();
    await _schedulerService!.initialize();

    _analyticsService = NotificationAnalyticsService();
  }

  /// Get the notification controller
  NotificationController get controller {
    if (_controller == null) {
      throw Exception('NotificationManager not initialized. Call initialize() first.');
    }
    return _controller!;
  }

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    NotificationModel? startAfter,
  }) {
    return controller.getNotifications(limit: limit, startAfter: startAfter);
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() {
    return controller.getUnreadCount();
  }

  /// Create a new notification
  Future<String> createNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) {
    return controller.createNotification(
      type: type,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) {
    return controller.markAsRead(notificationId);
  }

  /// Mark notification as unread
  Future<void> markAsUnread(String notificationId) {
    return controller.markAsUnread(notificationId);
  }

  /// Archive notification
  Future<void> archiveNotification(String notificationId) {
    return controller.archiveNotification(notificationId);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) {
    return controller.deleteNotification(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() {
    return controller.markAllAsRead();
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() {
    return controller.deleteAllNotifications();
  }

  /// Get user notification preferences
  Future<NotificationPreferences> getUserPreferences() {
    return controller.getUserPreferences();
  }

  /// Update user notification preferences
  Future<void> updateUserPreferences(NotificationPreferences preferences) {
    return controller.updateUserPreferences(preferences);
  }

  /// Check if a notification type is enabled
  Future<bool> isNotificationTypeEnabled(NotificationType type) {
    return controller.isNotificationTypeEnabled(type);
  }

  /// Check if push notifications are enabled for a type
  Future<bool> isPushEnabled(NotificationType type) {
    return controller.isPushEnabled(type);
  }

  /// Check if in-app notifications are enabled for a type
  Future<bool> isInAppEnabled(NotificationType type) {
    return controller.isInAppEnabled(type);
  }

  /// Stream of notifications for real-time updates
  Stream<List<NotificationModel>> getNotificationsStream({int limit = 20}) {
    return controller.getNotificationsStream(limit: limit);
  }

  /// Stream of unread count for real-time updates
  Stream<int> getUnreadCountStream() {
    return controller.getUnreadCountStream();
  }

  /// Send push notification (if enabled)
  Future<void> sendPushNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) {
    return controller.sendPushNotification(
      type: type,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Send in-app notification (if enabled)
  Future<void> sendInAppNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) {
    return controller.sendInAppNotification(
      type: type,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  /// Send both push and in-app notification
  Future<void> sendNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) {
    return controller.sendNotification(
      type: type,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  // ===== ENHANCED FEATURES =====

  /// Get badge service
  NotificationBadgeService get badgeService {
    if (_badgeService == null) {
      throw Exception('NotificationManager not initialized. Call initialize() first.');
    }
    return _badgeService!;
  }

  /// Get scheduler service
  NotificationSchedulerService get schedulerService {
    if (_schedulerService == null) {
      throw Exception('NotificationManager not initialized. Call initialize() first.');
    }
    return _schedulerService!;
  }

  /// Get analytics service
  NotificationAnalyticsService get analyticsService {
    if (_analyticsService == null) {
      throw Exception('NotificationManager not initialized. Call initialize() first.');
    }
    return _analyticsService!;
  }

  /// Update app icon badge count
  Future<void> updateBadgeCount() async {
    // This would need userId - in a real implementation, this would be passed or retrieved
    // For now, this is a placeholder
    await badgeService.updateBadgeCount('current_user_id');
  }

  /// Clear app icon badge
  Future<void> clearBadge() async {
    await badgeService.clearBadge();
  }

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationType type,
    Map<String, dynamic> data = const {},
    String? payload,
  }) async {
    await schedulerService.scheduleReminder(
      userId: 'current_user_id', // Would be retrieved from auth
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      type: type,
      data: data,
      payload: payload,
    );
  }

  /// Schedule event reminder
  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
    required Duration reminderBefore,
  }) async {
    await schedulerService.scheduleEventReminder(
      userId: 'current_user_id', // Would be retrieved from auth
      eventId: eventId,
      eventTitle: eventTitle,
      eventTime: eventTime,
      reminderBefore: reminderBefore,
    );
  }

  /// Track notification delivery
  Future<void> trackNotificationDelivered({
    required String notificationId,
    required NotificationType type,
    required String deliveryMethod,
  }) async {
    await analyticsService.trackNotificationDelivered(
      userId: 'current_user_id', // Would be retrieved from auth
      notificationId: notificationId,
      type: type,
      deliveryMethod: deliveryMethod,
    );
  }

  /// Track notification opened
  Future<void> trackNotificationOpened({
    required String notificationId,
    required NotificationType type,
    required String deliveryMethod,
  }) async {
    await analyticsService.trackNotificationOpened(
      userId: 'current_user_id', // Would be retrieved from auth
      notificationId: notificationId,
      type: type,
      deliveryMethod: deliveryMethod,
    );
  }

  /// Get notification analytics
  Future<Map<String, dynamic>> getNotificationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await analyticsService.getUserNotificationAnalytics(
      'current_user_id', // Would be retrieved from auth
      startDate: startDate,
      endDate: endDate,
    );
  }
}