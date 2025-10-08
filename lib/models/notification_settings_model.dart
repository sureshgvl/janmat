/// Model representing user notification settings and preferences
/// Follows the same pattern as UserModel for consistency
class NotificationSettingsModel {
  final String userId;

  // Chat notifications
  final bool chatEnabled;
  final bool chatSoundEnabled;
  final bool chatVibrationEnabled;
  final bool chatPreviewEnabled;

  // Candidate notifications
  final bool candidateEnabled;
  final bool candidateSoundEnabled;
  final bool candidateVibrationEnabled;
  final bool newFollowerEnabled;
  final bool candidateActivityEnabled;

  // Poll notifications
  final bool pollEnabled;
  final bool pollSoundEnabled;
  final bool pollVibrationEnabled;
  final bool pollResultsEnabled;

  // System notifications
  final bool systemEnabled;
  final bool systemSoundEnabled;
  final bool systemVibrationEnabled;
  final bool appUpdatesEnabled;
  final bool securityEnabled;

  // Push notification settings
  final bool pushEnabled;
  final bool backgroundSyncEnabled;

  // Quiet hours
  final bool quietHoursEnabled;
  final String? quietHoursStart; // HH:mm format
  final String? quietHoursEnd; // HH:mm format

  // Advanced settings
  final bool doNotDisturbEnabled;
  final List<String> mutedUsers; // List of muted user IDs
  final List<String> mutedChats; // List of muted chat room IDs

  final DateTime lastUpdated;

  NotificationSettingsModel({
    required this.userId,
    this.chatEnabled = true,
    this.chatSoundEnabled = true,
    this.chatVibrationEnabled = true,
    this.chatPreviewEnabled = true,
    this.candidateEnabled = true,
    this.candidateSoundEnabled = true,
    this.candidateVibrationEnabled = true,
    this.newFollowerEnabled = true,
    this.candidateActivityEnabled = true,
    this.pollEnabled = true,
    this.pollSoundEnabled = true,
    this.pollVibrationEnabled = true,
    this.pollResultsEnabled = true,
    this.systemEnabled = true,
    this.systemSoundEnabled = true,
    this.systemVibrationEnabled = true,
    this.appUpdatesEnabled = true,
    this.securityEnabled = true,
    this.pushEnabled = true,
    this.backgroundSyncEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.doNotDisturbEnabled = false,
    this.mutedUsers = const [],
    this.mutedChats = const [],
    required this.lastUpdated,
  });

  /// Create default settings for a new user
  factory NotificationSettingsModel.createDefault(String userId) {
    return NotificationSettingsModel(
      userId: userId,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create from JSON (for Firestore/caching)
  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      userId: json['userId'] ?? '',
      chatEnabled: json['chatEnabled'] ?? true,
      chatSoundEnabled: json['chatSoundEnabled'] ?? true,
      chatVibrationEnabled: json['chatVibrationEnabled'] ?? true,
      chatPreviewEnabled: json['chatPreviewEnabled'] ?? true,
      candidateEnabled: json['candidateEnabled'] ?? true,
      candidateSoundEnabled: json['candidateSoundEnabled'] ?? true,
      candidateVibrationEnabled: json['candidateVibrationEnabled'] ?? true,
      newFollowerEnabled: json['newFollowerEnabled'] ?? true,
      candidateActivityEnabled: json['candidateActivityEnabled'] ?? true,
      pollEnabled: json['pollEnabled'] ?? true,
      pollSoundEnabled: json['pollSoundEnabled'] ?? true,
      pollVibrationEnabled: json['pollVibrationEnabled'] ?? true,
      pollResultsEnabled: json['pollResultsEnabled'] ?? true,
      systemEnabled: json['systemEnabled'] ?? true,
      systemSoundEnabled: json['systemSoundEnabled'] ?? true,
      systemVibrationEnabled: json['systemVibrationEnabled'] ?? true,
      appUpdatesEnabled: json['appUpdatesEnabled'] ?? true,
      securityEnabled: json['securityEnabled'] ?? true,
      pushEnabled: json['pushEnabled'] ?? true,
      backgroundSyncEnabled: json['backgroundSyncEnabled'] ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'],
      quietHoursEnd: json['quietHoursEnd'],
      doNotDisturbEnabled: json['doNotDisturbEnabled'] ?? false,
      mutedUsers: List<String>.from(json['mutedUsers'] ?? []),
      mutedChats: List<String>.from(json['mutedChats'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for Firestore/caching
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'chatEnabled': chatEnabled,
      'chatSoundEnabled': chatSoundEnabled,
      'chatVibrationEnabled': chatVibrationEnabled,
      'chatPreviewEnabled': chatPreviewEnabled,
      'candidateEnabled': candidateEnabled,
      'candidateSoundEnabled': candidateSoundEnabled,
      'candidateVibrationEnabled': candidateVibrationEnabled,
      'newFollowerEnabled': newFollowerEnabled,
      'candidateActivityEnabled': candidateActivityEnabled,
      'pollEnabled': pollEnabled,
      'pollSoundEnabled': pollSoundEnabled,
      'pollVibrationEnabled': pollVibrationEnabled,
      'pollResultsEnabled': pollResultsEnabled,
      'systemEnabled': systemEnabled,
      'systemSoundEnabled': systemSoundEnabled,
      'systemVibrationEnabled': systemVibrationEnabled,
      'appUpdatesEnabled': appUpdatesEnabled,
      'securityEnabled': securityEnabled,
      'pushEnabled': pushEnabled,
      'backgroundSyncEnabled': backgroundSyncEnabled,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'doNotDisturbEnabled': doNotDisturbEnabled,
      'mutedUsers': mutedUsers,
      'mutedChats': mutedChats,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  NotificationSettingsModel copyWith({
    String? userId,
    bool? chatEnabled,
    bool? chatSoundEnabled,
    bool? chatVibrationEnabled,
    bool? chatPreviewEnabled,
    bool? candidateEnabled,
    bool? candidateSoundEnabled,
    bool? candidateVibrationEnabled,
    bool? newFollowerEnabled,
    bool? candidateActivityEnabled,
    bool? pollEnabled,
    bool? pollSoundEnabled,
    bool? pollVibrationEnabled,
    bool? pollResultsEnabled,
    bool? systemEnabled,
    bool? systemSoundEnabled,
    bool? systemVibrationEnabled,
    bool? appUpdatesEnabled,
    bool? securityEnabled,
    bool? pushEnabled,
    bool? backgroundSyncEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? doNotDisturbEnabled,
    List<String>? mutedUsers,
    List<String>? mutedChats,
    DateTime? lastUpdated,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      chatSoundEnabled: chatSoundEnabled ?? this.chatSoundEnabled,
      chatVibrationEnabled: chatVibrationEnabled ?? this.chatVibrationEnabled,
      chatPreviewEnabled: chatPreviewEnabled ?? this.chatPreviewEnabled,
      candidateEnabled: candidateEnabled ?? this.candidateEnabled,
      candidateSoundEnabled: candidateSoundEnabled ?? this.candidateSoundEnabled,
      candidateVibrationEnabled: candidateVibrationEnabled ?? this.candidateVibrationEnabled,
      newFollowerEnabled: newFollowerEnabled ?? this.newFollowerEnabled,
      candidateActivityEnabled: candidateActivityEnabled ?? this.candidateActivityEnabled,
      pollEnabled: pollEnabled ?? this.pollEnabled,
      pollSoundEnabled: pollSoundEnabled ?? this.pollSoundEnabled,
      pollVibrationEnabled: pollVibrationEnabled ?? this.pollVibrationEnabled,
      pollResultsEnabled: pollResultsEnabled ?? this.pollResultsEnabled,
      systemEnabled: systemEnabled ?? this.systemEnabled,
      systemSoundEnabled: systemSoundEnabled ?? this.systemSoundEnabled,
      systemVibrationEnabled: systemVibrationEnabled ?? this.systemVibrationEnabled,
      appUpdatesEnabled: appUpdatesEnabled ?? this.appUpdatesEnabled,
      securityEnabled: securityEnabled ?? this.securityEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      backgroundSyncEnabled: backgroundSyncEnabled ?? this.backgroundSyncEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      doNotDisturbEnabled: doNotDisturbEnabled ?? this.doNotDisturbEnabled,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      mutedChats: mutedChats ?? this.mutedChats,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if notifications are allowed based on current time and settings
  bool areNotificationsAllowed() {
    if (!pushEnabled) return false;
    if (doNotDisturbEnabled) return false;

    // Check quiet hours
    if (quietHoursEnabled && quietHoursStart != null && quietHoursEnd != null) {
      final now = DateTime.now();
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      if (_isTimeInRange(currentTime, quietHoursStart!, quietHoursEnd!)) {
        return false;
      }
    }

    return true;
  }

  /// Check if a specific user is muted
  bool isUserMuted(String userId) {
    return mutedUsers.contains(userId);
  }

  /// Check if a specific chat is muted
  bool isChatMuted(String chatId) {
    return mutedChats.contains(chatId);
  }

  /// Helper method to check if current time is within quiet hours range
  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    final current = _timeToMinutes(currentTime);
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);

    if (start <= end) {
      // Same day range
      return current >= start && current <= end;
    } else {
      // Overnight range (e.g., 22:00 to 06:00)
      return current >= start || current <= end;
    }
  }

  /// Convert HH:mm to minutes since midnight
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  @override
  String toString() {
    return 'NotificationSettingsModel(userId: $userId, pushEnabled: $pushEnabled, quietHoursEnabled: $quietHoursEnabled, mutedUsers: ${mutedUsers.length}, mutedChats: ${mutedChats.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettingsModel &&
        other.userId == userId &&
        other.pushEnabled == pushEnabled &&
        other.quietHoursEnabled == quietHoursEnabled &&
        other.doNotDisturbEnabled == doNotDisturbEnabled;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        pushEnabled.hashCode ^
        quietHoursEnabled.hashCode ^
        doNotDisturbEnabled.hashCode ^
        mutedUsers.hashCode ^
        mutedChats.hashCode;
  }
}