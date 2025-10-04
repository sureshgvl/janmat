import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for community feed posts
class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final String districtId;
  final String bodyId;
  final String wardId;
  final int likes;
  final int comments;
  final List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      content: json['content'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      wardId: json['wardId'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'districtId': districtId,
      'bodyId': bodyId,
      'wardId': wardId,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
    };
  }
}

/// Model for sponsored/push feed updates
class SponsoredUpdate {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final String districtId;
  final String bodyId;
  final String wardId;
  final bool isActive;

  SponsoredUpdate({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    this.isActive = true,
  });

  factory SponsoredUpdate.fromJson(Map<String, dynamic> json) {
    return SponsoredUpdate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'],
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      wardId: json['wardId'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'timestamp': Timestamp.fromDate(timestamp),
      'districtId': districtId,
      'bodyId': bodyId,
      'wardId': wardId,
      'isActive': isActive,
    };
  }
}

