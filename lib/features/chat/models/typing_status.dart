/// Model representing a user's typing status in a chat room
class TypingStatus {
  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime timestamp;

  TypingStatus({
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.timestamp,
  });

  /// Create a copy with updated fields
  TypingStatus copyWith({
    String? userId,
    String? userName,
    bool? isTyping,
    DateTime? timestamp,
  }) {
    return TypingStatus(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isTyping: isTyping ?? this.isTyping,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TypingStatus.fromJson(Map<String, dynamic> json) {
    return TypingStatus(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      isTyping: json['isTyping'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'TypingStatus(userId: $userId, userName: $userName, isTyping: $isTyping, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypingStatus &&
        other.userId == userId &&
        other.userName == userName &&
        other.isTyping == isTyping;
  }

  @override
  int get hashCode => userId.hashCode ^ userName.hashCode ^ isTyping.hashCode;
}
