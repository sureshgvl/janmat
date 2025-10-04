import 'package:cloud_firestore/cloud_firestore.dart';

class UserQuota {
  final String userId;
  final int dailyLimit;
  final int messagesSent;
  final int extraQuota;
  final DateTime lastReset;
  final DateTime createdAt;

  UserQuota({
    required this.userId,
    this.dailyLimit = 20,
    this.messagesSent = 0,
    this.extraQuota = 0,
    required this.lastReset,
    required this.createdAt,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    DateTime lastReset;
    if (json['lastReset'] is Timestamp) {
      lastReset = (json['lastReset'] as Timestamp).toDate();
    } else if (json['lastReset'] is String) {
      lastReset = DateTime.parse(json['lastReset']);
    } else {
      lastReset = DateTime.now();
    }

    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return UserQuota(
      userId: json['userId'] ?? '',
      dailyLimit: json['dailyLimit'] ?? 20,
      messagesSent: json['messagesSent'] ?? 0,
      extraQuota: json['extraQuota'] ?? 0,
      lastReset: lastReset,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dailyLimit': dailyLimit,
      'messagesSent': messagesSent,
      'extraQuota': extraQuota,
      'lastReset': Timestamp.fromDate(lastReset),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  int get remainingMessages => (dailyLimit + extraQuota) - messagesSent;

  bool get canSendMessage => remainingMessages > 0;

  UserQuota copyWith({
    String? userId,
    int? dailyLimit,
    int? messagesSent,
    int? extraQuota,
    DateTime? lastReset,
    DateTime? createdAt,
  }) {
    return UserQuota(
      userId: userId ?? this.userId,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      messagesSent: messagesSent ?? this.messagesSent,
      extraQuota: extraQuota ?? this.extraQuota,
      lastReset: lastReset ?? this.lastReset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

