import 'package:equatable/equatable.dart';

class Like extends Equatable {
  final String id;
  final String userId;
  final String postId;
  final String mediaKey; // 'post', 'video_0', 'youtube_1', etc.
  final DateTime createdAt;
  final String? userName;
  final String? userPhoto;

  const Like({
    required this.id,
    required this.userId,
    required this.postId,
    required this.mediaKey,
    required this.createdAt,
    this.userName,
    this.userPhoto,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      postId: json['postId'] ?? '',
      mediaKey: json['mediaKey'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      userName: json['userName'],
      userPhoto: json['userPhoto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'mediaKey': mediaKey,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }

  @override
  List<Object?> get props => [id, userId, postId, mediaKey, createdAt, userName, userPhoto];
}
