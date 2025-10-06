import 'package:firebase_auth/firebase_auth.dart';
import 'notification_controller.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';
import '../models/notification_type.dart';
import '../models/notification_status.dart';
import '../../../services/local_notification_service.dart';

/// Implementation of NotificationController
class NotificationControllerImpl implements NotificationController {
  final NotificationRepository _repository;
  final LocalNotificationService _localNotificationService;

  String? _currentUserId;

  NotificationControllerImpl({
    NotificationRepository? repository,
    LocalNotificationService? localNotificationService,
  }) :
    _repository = repository ?? NotificationRepositoryImpl(),
    _localNotificationService = localNotificationService ?? LocalNotificationService();

  @override
  Future<void> initialize() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;

        // Ensure user has default preferences
        final existingPrefs = await _repository.getUserPreferences(_currentUserId!);
        if (existingPrefs == null) {
          final defaultPrefs = NotificationPreferences.getDefault(_currentUserId!);
          await _repository.updateUserPreferences(defaultPrefs);
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize notification controller: $e');
    }
  }

  String? get currentUserId => _currentUserId;

  void _ensureUserId() {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    NotificationModel? startAfter,
  }) async {
    _ensureUserId();
    return _repository.getUserNotifications(_currentUserId!, limit: limit, startAfter: startAfter);
  }

  @override
  Future<int> getUnreadCount() async {
    _ensureUserId();
    return _repository.getUnreadCount(_currentUserId!);
  }

  @override
  Future<String> createNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) async {
    _ensureUserId();

    final notification = NotificationModel(
      id: '', // Will be set by Firestore
      userId: _currentUserId!,
      type: type,
      title: title,
      body: body,
      data: data,
      status: NotificationStatus.unread,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    return _repository.createNotification(notification);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    _ensureUserId();
    await (_repository as NotificationRepositoryImpl).markAsReadForUser(_currentUserId!, notificationId);
  }

  @override
  Future<void> markAsUnread(String notificationId) async {
    _ensureUserId();
    await (_repository as NotificationRepositoryImpl).markAsUnreadForUser(_currentUserId!, notificationId);
  }

  @override
  Future<void> archiveNotification(String notificationId) async {
    _ensureUserId();
    await (_repository as NotificationRepositoryImpl).archiveNotificationForUser(_currentUserId!, notificationId);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    _ensureUserId();
    await (_repository as NotificationRepositoryImpl).deleteNotificationForUser(_currentUserId!, notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    _ensureUserId();
    await _repository.markAllAsRead(_currentUserId!);
  }

  @override
  Future<void> deleteAllNotifications() async {
    _ensureUserId();
    await _repository.deleteAllNotifications(_currentUserId!);
  }

  @override
  Future<NotificationPreferences> getUserPreferences() async {
    _ensureUserId();

    final prefs = await _repository.getUserPreferences(_currentUserId!);
    if (prefs != null) {
      return prefs;
    }

    // Return default preferences if none exist
    return NotificationPreferences.getDefault(_currentUserId!);
  }

  @override
  Future<void> updateUserPreferences(NotificationPreferences preferences) async {
    await _repository.updateUserPreferences(preferences);
  }

  @override
  Future<bool> isNotificationTypeEnabled(NotificationType type) async {
    final prefs = await getUserPreferences();
    return prefs.isTypeEnabled(type);
  }

  @override
  Future<bool> isPushEnabled(NotificationType type) async {
    final prefs = await getUserPreferences();
    return prefs.isPushEnabled(type);
  }

  @override
  Future<bool> isInAppEnabled(NotificationType type) async {
    final prefs = await getUserPreferences();
    return prefs.isInAppEnabled(type);
  }

  @override
  Stream<List<NotificationModel>> getNotificationsStream({int limit = 20}) {
    _ensureUserId();
    return _repository.getNotificationsStream(_currentUserId!, limit: limit);
  }

  @override
  Stream<int> getUnreadCountStream() {
    _ensureUserId();
    return _repository.getUnreadCountStream(_currentUserId!);
  }

  @override
  Future<void> sendPushNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final isEnabled = await isPushEnabled(type);
    if (!isEnabled) return;

    final prefs = await getUserPreferences();
    if (prefs.isInQuietHours) return;

    // Note: Actual push notification sending would be implemented here
    // For now, this is a placeholder
    // You would integrate with FCMService or a backend service
  }

  @override
  Future<void> sendInAppNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) async {
    final isEnabled = await isInAppEnabled(type);
    if (!isEnabled) return;

    // Create notification in database
    await createNotification(
      type: type,
      title: title,
      body: body,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );

    // Show local notification
    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    await _localNotificationService.showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: data.toString(),
    );
  }

  @override
  Future<void> sendNotification({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) async {
    await Future.wait([
      sendPushNotification(
        type: type,
        title: title,
        body: body,
        data: data,
      ),
      sendInAppNotification(
        type: type,
        title: title,
        body: body,
        data: data,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      ),
    ]);
  }
}