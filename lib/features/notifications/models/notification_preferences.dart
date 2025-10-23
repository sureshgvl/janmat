import 'notification_type.dart';

/// Model representing user notification preferences
class NotificationPreferences {
  final String userId;

  // Master toggle for all notifications
  final bool notificationsEnabled;

  // Push notification preferences
  final bool pushNotificationsEnabled;

  // In-app notification preferences
  final bool inAppNotificationsEnabled;

  // Category-specific preferences
  final Map<String, bool> categoryPreferences;

  // Type-specific preferences
  final Map<NotificationType, bool> typePreferences;

  // Time-based preferences
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour in 24-hour format (0-23)
  final int quietHoursEnd; // Hour in 24-hour format (0-23)

  // Frequency preferences
  final bool batchNotificationsEnabled;
  final int batchIntervalMinutes; // How often to batch notifications

  const NotificationPreferences({
    required this.userId,
    this.notificationsEnabled = true,
    this.pushNotificationsEnabled = true,
    this.inAppNotificationsEnabled = true,
    this.categoryPreferences = const {},
    this.typePreferences = const {},
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 8, // 8 AM
    this.batchNotificationsEnabled = false,
    this.batchIntervalMinutes = 60,
  });

  /// Create NotificationPreferences from Firestore document
  factory NotificationPreferences.fromFirestore(Map<String, dynamic> data, String userId) {
    final categoryPrefs = <String, bool>{};
    final typePrefs = <NotificationType, bool>{};

    // Parse category preferences
    final categories = data['categoryPreferences'] as Map<String, dynamic>? ?? {};
    categories.forEach((key, value) {
      if (value is bool) {
        categoryPrefs[key] = value;
      }
    });

    // Parse type preferences
    final types = data['typePreferences'] as Map<String, dynamic>? ?? {};
    types.forEach((key, value) {
      if (value is bool) {
        try {
          final type = NotificationType.values.firstWhere(
            (t) => t.name == key,
          );
          typePrefs[type] = value;
        } catch (e) {
          // Skip invalid type names
        }
      }
    });

    return NotificationPreferences(
      userId: userId,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      pushNotificationsEnabled: data['pushNotificationsEnabled'] ?? true,
      inAppNotificationsEnabled: data['inAppNotificationsEnabled'] ?? true,
      categoryPreferences: categoryPrefs,
      typePreferences: typePrefs,
      quietHoursEnabled: data['quietHoursEnabled'] ?? false,
      quietHoursStart: data['quietHoursStart'] ?? 22,
      quietHoursEnd: data['quietHoursEnd'] ?? 8,
      batchNotificationsEnabled: data['batchNotificationsEnabled'] ?? false,
      batchIntervalMinutes: data['batchIntervalMinutes'] ?? 60,
    );
  }

  /// Convert NotificationPreferences to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'inAppNotificationsEnabled': inAppNotificationsEnabled,
      'categoryPreferences': categoryPreferences,
      'typePreferences': typePreferences.map((key, value) => MapEntry(key.name, value)),
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'batchNotificationsEnabled': batchNotificationsEnabled,
      'batchIntervalMinutes': batchIntervalMinutes,
    };
  }

  /// Create a copy of this preferences with updated fields
  NotificationPreferences copyWith({
    String? userId,
    bool? notificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? inAppNotificationsEnabled,
    Map<String, bool>? categoryPreferences,
    Map<NotificationType, bool>? typePreferences,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? batchNotificationsEnabled,
    int? batchIntervalMinutes,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      inAppNotificationsEnabled: inAppNotificationsEnabled ?? this.inAppNotificationsEnabled,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      typePreferences: typePreferences ?? this.typePreferences,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      batchNotificationsEnabled: batchNotificationsEnabled ?? this.batchNotificationsEnabled,
      batchIntervalMinutes: batchIntervalMinutes ?? this.batchIntervalMinutes,
    );
  }

  /// Check if a specific notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    if (!notificationsEnabled) return false;

    // Check type-specific preference first
    final typeEnabled = typePreferences[type];
    if (typeEnabled != null) return typeEnabled;

    // Check category preference
    final categoryEnabled = categoryPreferences[type.category];
    if (categoryEnabled != null) return categoryEnabled;

    // Default to enabled
    return true;
  }

  /// Check if push notifications are enabled for a type
  bool isPushEnabled(NotificationType type) {
    return pushNotificationsEnabled && isTypeEnabled(type);
  }

  /// Check if in-app notifications are enabled for a type
  bool isInAppEnabled(NotificationType type) {
    return inAppNotificationsEnabled && isTypeEnabled(type);
  }

  /// Check if current time is within quiet hours
  bool get isInQuietHours {
    if (!quietHoursEnabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    if (quietHoursStart <= quietHoursEnd) {
      // Same day range (e.g., 8 AM to 10 PM)
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    } else {
      // Overnight range (e.g., 10 PM to 8 AM)
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    }
  }

  /// Get default preferences for new users
  static NotificationPreferences getDefault(String userId) {
    return NotificationPreferences(
      userId: userId,
      notificationsEnabled: true,
      pushNotificationsEnabled: true,
      inAppNotificationsEnabled: true,
      categoryPreferences: {
        'Chat': true,
        'Following': true,
        'Events': true,
        'Polls': true,
        'Achievements': true,
        'System': true,
        'Social': true,
        'Content': true,
      },
      typePreferences: {
        // High priority notifications always enabled by default
        NotificationType.securityAlert: true,
        NotificationType.electionReminder: true,
        NotificationType.eventReminder: true,
        NotificationType.pollDeadline: true,
      },
      quietHoursEnabled: false,
      quietHoursStart: 22,
      quietHoursEnd: 8,
      batchNotificationsEnabled: false,
      batchIntervalMinutes: 60,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(userId: $userId, enabled: $notificationsEnabled, push: $pushNotificationsEnabled, inApp: $inAppNotificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPreferences &&
        other.userId == userId &&
        other.notificationsEnabled == notificationsEnabled &&
        other.pushNotificationsEnabled == pushNotificationsEnabled &&
        other.inAppNotificationsEnabled == inAppNotificationsEnabled;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        notificationsEnabled.hashCode ^
        pushNotificationsEnabled.hashCode ^
        inAppNotificationsEnabled.hashCode;
  }
}
