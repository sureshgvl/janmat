/// Model representing user following relationships
/// Follows the same pattern as UserModel for consistency
class FollowingModel {
  final String userId;
  final List<String> followingIds; // List of candidate/user IDs being followed
  final Map<String, FollowingDetails> followingDetails; // Detailed info for each follow
  final int followingCount;
  final DateTime lastUpdated;

  FollowingModel({
    required this.userId,
    this.followingIds = const [],
    this.followingDetails = const {},
    this.followingCount = 0,
    required this.lastUpdated,
  });

  /// Create from JSON (for Firestore/caching)
  factory FollowingModel.fromJson(Map<String, dynamic> json) {
    final followingDetails = <String, FollowingDetails>{};
    if (json['followingDetails'] != null) {
      final detailsMap = json['followingDetails'] as Map<String, dynamic>;
      detailsMap.forEach((key, value) {
        followingDetails[key] = FollowingDetails.fromJson(value as Map<String, dynamic>);
      });
    }

    return FollowingModel(
      userId: json['userId'] ?? '',
      followingIds: List<String>.from(json['followingIds'] ?? []),
      followingDetails: followingDetails,
      followingCount: json['followingCount'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for Firestore/caching
  Map<String, dynamic> toJson() {
    final detailsJson = <String, dynamic>{};
    followingDetails.forEach((key, value) {
      detailsJson[key] = value.toJson();
    });

    return {
      'userId': userId,
      'followingIds': followingIds,
      'followingDetails': detailsJson,
      'followingCount': followingCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  FollowingModel copyWith({
    String? userId,
    List<String>? followingIds,
    Map<String, FollowingDetails>? followingDetails,
    int? followingCount,
    DateTime? lastUpdated,
  }) {
    return FollowingModel(
      userId: userId ?? this.userId,
      followingIds: followingIds ?? this.followingIds,
      followingDetails: followingDetails ?? this.followingDetails,
      followingCount: followingCount ?? this.followingCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if user is following a specific candidate/user
  bool isFollowing(String targetId) {
    return followingIds.contains(targetId);
  }

  /// Get following details for a specific candidate/user
  FollowingDetails? getFollowingDetails(String targetId) {
    return followingDetails[targetId];
  }

  /// Add a new following relationship
  FollowingModel addFollowing(String targetId, {FollowingDetails? details}) {
    final newFollowingIds = List<String>.from(followingIds);
    if (!newFollowingIds.contains(targetId)) {
      newFollowingIds.add(targetId);
    }

    final newDetails = Map<String, FollowingDetails>.from(followingDetails);
    if (details != null) {
      newDetails[targetId] = details;
    } else if (!newDetails.containsKey(targetId)) {
      newDetails[targetId] = FollowingDetails.createDefault(targetId);
    }

    return copyWith(
      followingIds: newFollowingIds,
      followingDetails: newDetails,
      followingCount: newFollowingIds.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Remove a following relationship
  FollowingModel removeFollowing(String targetId) {
    final newFollowingIds = List<String>.from(followingIds);
    newFollowingIds.remove(targetId);

    final newDetails = Map<String, FollowingDetails>.from(followingDetails);
    newDetails.remove(targetId);

    return copyWith(
      followingIds: newFollowingIds,
      followingDetails: newDetails,
      followingCount: newFollowingIds.length,
      lastUpdated: DateTime.now(),
    );
  }

  /// Update following details for a specific relationship
  FollowingModel updateFollowingDetails(String targetId, FollowingDetails details) {
    final newDetails = Map<String, FollowingDetails>.from(followingDetails);
    newDetails[targetId] = details;

    return copyWith(
      followingDetails: newDetails,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get all following IDs with notification enabled
  List<String> getFollowingWithNotificationsEnabled() {
    return followingIds.where((id) {
      final details = followingDetails[id];
      return details?.notificationsEnabled ?? true;
    }).toList();
  }

  /// Get following statistics
  Map<String, dynamic> getStats() {
    int notificationsEnabled = 0;
    int notificationsDisabled = 0;
    final now = DateTime.now();

    for (final details in followingDetails.values) {
      if (details.notificationsEnabled) {
        notificationsEnabled++;
      } else {
        notificationsDisabled++;
      }
    }

    return {
      'totalFollowing': followingCount,
      'notificationsEnabled': notificationsEnabled,
      'notificationsDisabled': notificationsDisabled,
      'lastUpdated': lastUpdated,
      'daysSinceLastUpdate': now.difference(lastUpdated).inDays,
    };
  }

  @override
  String toString() {
    return 'FollowingModel(userId: $userId, followingCount: $followingCount, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowingModel &&
        other.userId == userId &&
        other.followingCount == followingCount &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        followingIds.hashCode ^
        followingDetails.hashCode ^
        followingCount.hashCode ^
        lastUpdated.hashCode;
  }
}

/// Details for a specific following relationship
class FollowingDetails {
  final String targetId; // The candidate/user being followed
  final DateTime followedAt;
  final bool notificationsEnabled;
  final String? followReason; // Why they followed (optional)
  final Map<String, dynamic> customSettings; // Extensible settings

  FollowingDetails({
    required this.targetId,
    required this.followedAt,
    this.notificationsEnabled = true,
    this.followReason,
    this.customSettings = const {},
  });

  /// Create default following details
  factory FollowingDetails.createDefault(String targetId) {
    return FollowingDetails(
      targetId: targetId,
      followedAt: DateTime.now(),
    );
  }

  /// Create from JSON
  factory FollowingDetails.fromJson(Map<String, dynamic> json) {
    return FollowingDetails(
      targetId: json['targetId'] ?? '',
      followedAt: DateTime.parse(json['followedAt'] ?? DateTime.now().toIso8601String()),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      followReason: json['followReason'],
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'targetId': targetId,
      'followedAt': followedAt.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'followReason': followReason,
      'customSettings': customSettings,
    };
  }

  /// Create a copy with updated fields
  FollowingDetails copyWith({
    String? targetId,
    DateTime? followedAt,
    bool? notificationsEnabled,
    String? followReason,
    Map<String, dynamic>? customSettings,
  }) {
    return FollowingDetails(
      targetId: targetId ?? this.targetId,
      followedAt: followedAt ?? this.followedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      followReason: followReason ?? this.followReason,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Get days since following
  int get daysSinceFollowing {
    return DateTime.now().difference(followedAt).inDays;
  }

  @override
  String toString() {
    return 'FollowingDetails(targetId: $targetId, followedAt: $followedAt, notificationsEnabled: $notificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowingDetails &&
        other.targetId == targetId &&
        other.followedAt == followedAt &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return targetId.hashCode ^
        followedAt.hashCode ^
        notificationsEnabled.hashCode;
  }
}
