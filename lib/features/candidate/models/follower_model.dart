import 'package:cloud_firestore/cloud_firestore.dart';

class Follower {
  final String userId;
  final DateTime followedAt;
  final bool notificationsEnabled;

  Follower({
    required this.userId,
    required this.followedAt,
    required this.notificationsEnabled,
  });

  /// Factory constructor to create Follower from Firestore document
  factory Follower.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Follower(
      userId: doc.id, // Document ID is the follower userId
      followedAt: data['followedAt'] != null
          ? (data['followedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'followedAt': Timestamp.fromDate(followedAt),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  /// Copy with method for immutability
  Follower copyWith({
    String? userId,
    DateTime? followedAt,
    bool? notificationsEnabled,
  }) {
    return Follower(
      userId: userId ?? this.userId,
      followedAt: followedAt ?? this.followedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  String toString() {
    return 'Follower(userId: $userId, followedAt: $followedAt, notificationsEnabled: $notificationsEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Follower &&
        other.userId == userId &&
        other.followedAt == followedAt &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        followedAt.hashCode ^
        notificationsEnabled.hashCode;
  }
}
