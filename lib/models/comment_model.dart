import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String text;
  final DateTime createdAt;
  final String? parentId;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    required this.createdAt,
    this.parentId,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      postId: json['postId'] ?? '',
      text: json['text'] ?? '',
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      parentId: json['parentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
    };
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? postId,
    String? text,
    DateTime? createdAt,
    String? parentId,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
    );
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

