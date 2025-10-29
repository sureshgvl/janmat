import 'package:equatable/equatable.dart';

// Media Item Model for Facebook-style post sharing
class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  Map<String, int> likes; // Track likes for each media item
  String? addedDate; // New field for added date display

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    Map<String, int>? likes,
    this.addedDate,
  }) : date = date ?? DateTime.now().toIso8601String().split('T')[0],
       images = images ?? [],
       videos = videos ?? [],
       youtubeLinks = youtubeLinks ?? [],
       likes = likes ?? {};

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    // Handle Firebase format where title might be in likes map
    String title = json['title'] ?? '';
    if (title.isEmpty && json['likes'] is Map && json['likes']['title'] != null) {
      title = json['likes']['title'];
    }

    // Handle likes map - it might contain the title, so we need to extract only integer values
    final rawLikes = json['likes'] ?? {};
    final Map<String, int> likes = {};
    if (rawLikes is Map) {
      rawLikes.forEach((key, value) {
        if (value is int && key != 'title') { // Skip title key
          likes[key] = value;
        }
      });
    }

    return MediaItem(
      title: title,
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      likes: likes,
      addedDate: json['added_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'images': images,
      'videos': videos,
      'youtubeLinks': youtubeLinks,
      'likes': likes,
      'added_date': addedDate,
    };
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
