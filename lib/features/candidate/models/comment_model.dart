import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final String text;
  final DateTime createdAt;
  final String? parentId; // For nested replies
  final String? userName;
  final String? userPhoto;

  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.userName,
    this.userPhoto,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      postId: json['postId'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      parentId: json['parentId'],
      userName: json['userName'],
      userPhoto: json['userPhoto'],
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
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }

  @override
  List<Object?> get props => [id, userId, postId, text, createdAt, parentId, userName, userPhoto];
}
