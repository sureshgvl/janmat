import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      postId: json['postId'] ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }

    return null;
  }
}