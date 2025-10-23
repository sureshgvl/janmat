/// Enum representing the read/unread status of notifications
enum NotificationStatus {
  unread,
  read,
  archived,
}

/// Extension to provide utility methods for notification status
extension NotificationStatusExtension on NotificationStatus {
  String get displayName {
    switch (this) {
      case NotificationStatus.unread:
        return 'Unread';
      case NotificationStatus.read:
        return 'Read';
      case NotificationStatus.archived:
        return 'Archived';
    }
  }

  bool get isUnread => this == NotificationStatus.unread;
  bool get isRead => this == NotificationStatus.read;
  bool get isArchived => this == NotificationStatus.archived;
}
