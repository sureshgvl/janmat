import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_type.dart';
import 'notification_status.dart';

/// Core notification model representing a single notification
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;
  final String? actionUrl;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
    this.actionUrl,
  });

  /// Create a NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: _parseNotificationType(data['type']),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: data['data'] ?? {},
      status: _parseNotificationStatus(data['status'] ?? 'unread'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  /// Convert NotificationModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  /// Create a copy of this notification with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  /// Mark notification as read
  NotificationModel markAsRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  /// Mark notification as unread
  NotificationModel markAsUnread() {
    return copyWith(
      status: NotificationStatus.unread,
      readAt: null,
    );
  }

  /// Archive notification
  NotificationModel archive() {
    return copyWith(status: NotificationStatus.archived);
  }

  /// Check if notification is unread
  bool get isUnread => status.isUnread;

  /// Check if notification is read
  bool get isRead => status.isRead;

  /// Check if notification is archived
  bool get isArchived => status.isArchived;

  /// Check if notification is high priority
  bool get isHighPriority => type.isHighPriority;

  /// Get notification category
  String get category => type.category;

  /// Get time ago string (simplified)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        body.hashCode ^
        status.hashCode;
  }
}

/// Helper function to parse notification type from string
NotificationType _parseNotificationType(String? typeString) {
  if (typeString == null) return NotificationType.newMessage;

  try {
    return NotificationType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => NotificationType.newMessage,
    );
  } catch (e) {
    return NotificationType.newMessage;
  }
}

/// Helper function to parse notification status from string
NotificationStatus _parseNotificationStatus(String? statusString) {
  if (statusString == null) return NotificationStatus.unread;

  try {
    return NotificationStatus.values.firstWhere(
      (status) => status.name == statusString,
      orElse: () => NotificationStatus.unread,
    );
  } catch (e) {
    return NotificationStatus.unread;
  }
}
