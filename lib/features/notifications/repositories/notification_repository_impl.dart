import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_repository.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences.dart';

/// Implementation of NotificationRepository using Firestore
class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<NotificationModel>> getUserNotifications(String userId, {
    int limit = 50,
    NotificationModel? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter.createdAt)]);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'unread')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(notification.userId)
          .collection('notifications')
          .add(notification.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<void> updateNotification(String notificationId, NotificationModel notification) async {
    try {
      await _firestore
          .collection('users')
          .doc(notification.userId)
          .collection('notifications')
          .doc(notificationId)
          .update(notification.toFirestore());
    } catch (e) {
      throw Exception('Failed to update notification: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Note: This implementation requires the userId to be passed or stored
      // In a real implementation, you might want to modify this to accept userId
      throw UnimplementedError('deleteNotification requires userId parameter');
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Delete notification with userId
  Future<void> deleteNotificationForUser(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      // Note: This implementation requires the userId to be passed or stored
      throw UnimplementedError('markAsRead requires userId parameter');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark notification as read with userId
  Future<void> markAsReadForUser(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': 'read',
            'readAt': Timestamp.now(),
          });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAsUnread(String notificationId) async {
    try {
      throw UnimplementedError('markAsUnread requires userId parameter');
    } catch (e) {
      throw Exception('Failed to mark notification as unread: $e');
    }
  }

  /// Mark notification as unread with userId
  Future<void> markAsUnreadForUser(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'status': 'unread',
            'readAt': null,
          });
    } catch (e) {
      throw Exception('Failed to mark notification as unread: $e');
    }
  }

  @override
  Future<void> archiveNotification(String notificationId) async {
    try {
      throw UnimplementedError('archiveNotification requires userId parameter');
    } catch (e) {
      throw Exception('Failed to archive notification: $e');
    }
  }

  /// Archive notification with userId
  Future<void> archiveNotificationForUser(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'archived'});
    } catch (e) {
      throw Exception('Failed to archive notification: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final unreadNotifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('status', isEqualTo: 'unread')
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'status': 'read',
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();

      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  @override
  Future<NotificationPreferences?> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        return null;
      }

      return NotificationPreferences.fromFirestore(doc.data()!, userId);
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  @override
  Future<void> updateUserPreferences(NotificationPreferences preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(preferences.userId)
          .collection('preferences')
          .doc('notifications')
          .set(preferences.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> getNotificationsStream(String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
