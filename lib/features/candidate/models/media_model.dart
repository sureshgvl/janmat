import 'package:equatable/equatable.dart';
import 'like_model.dart';
import 'comment_model.dart';

// Media Item Model for Facebook-style post sharing
class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  String? addedDate; // New field for added date display
  List<Like> likes; // Likes stored directly in media item
  List<Comment> comments; // Comments stored directly in media item

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    this.addedDate,
    List<Like>? likes,
    List<Comment>? comments,
  }) : date = date ?? DateTime.now().toIso8601String().split('T')[0],
       images = images ?? [],
       videos = videos ?? [],
       youtubeLinks = youtubeLinks ?? [],
       likes = likes ?? [],
       comments = comments ?? [];

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] ?? '',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      addedDate: json['added_date'],
      likes: (json['likes'] as List<dynamic>?)?.map((like) => Like.fromJson(like as Map<String, dynamic>)).toList() ?? [],
      comments: (json['comments'] as List<dynamic>?)?.map((comment) => Comment.fromJson(comment as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'images': images,
      'videos': videos,
      'youtubeLinks': youtubeLinks,
      'added_date': addedDate,
      'likes': likes.map((like) => like.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }

  // Helper methods for engagement
  int get likeCount => likes.length;
  int get commentCount => comments.length;

  bool hasUserLiked(String userId) {
    return likes.any((like) => like.userId == userId);
  }

  // Convenience method for checking if current user liked (requires userId parameter)
  bool isLikedBy(String userId) {
    return hasUserLiked(userId);
  }

  void addLike(Like like) {
    // Remove existing like from same user if exists
    likes.removeWhere((existingLike) => existingLike.userId == like.userId);
    likes.add(like);
  }

  void removeLike(String userId) {
    likes.removeWhere((like) => like.userId == userId);
  }

  void addComment(Comment comment) {
    comments.add(comment);
    // Sort comments by creation time (most recent first)
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  MediaItem copyWith({
    String? title,
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    String? addedDate,
    List<Like>? likes,
    List<Comment>? comments,
  }) {
    return MediaItem(
      title: title ?? this.title,
      date: date ?? this.date,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      youtubeLinks: youtubeLinks ?? this.youtubeLinks,
      addedDate: addedDate ?? this.addedDate,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
    );
  }
}

class Media extends Equatable {
  final String url;
  final String? caption;
  final String? title;
  final String? description;
  final String? duration;
  final String? type;
  final String? uploadedAt;
  final String? addedDate; // New field for added date display

  const Media({
    required this.url,
    this.caption,
    this.title,
    this.description,
    this.duration,
    this.type,
    this.uploadedAt,
    this.addedDate,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      url: json['url'],
      caption: json['caption'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      type: json['type'],
      uploadedAt: json['uploaded_at'],
      addedDate: json['added_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'caption': caption,
      'title': title,
      'description': description,
      'duration': duration,
      'type': type,
      'uploaded_at': uploadedAt,
      'added_date': addedDate,
    };
  }

  Media copyWith({
    String? url,
    String? caption,
    String? title,
    String? description,
    String? duration,
    String? type,
    String? uploadedAt,
    String? addedDate,
  }) {
    return Media(
      url: url ?? this.url,
      caption: caption ?? this.caption,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  @override
  List<Object?> get props => [url, caption, title, description, duration, type, uploadedAt, addedDate];
}
