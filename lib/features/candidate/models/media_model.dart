import 'package:equatable/equatable.dart';

class Media extends Equatable {
  final String url;
  final String? caption;
  final String? title;
  final String? description;
  final String? duration;
  final String? type;
  final String? uploadedAt;

  const Media({
    required this.url,
    this.caption,
    this.title,
    this.description,
    this.duration,
    this.type,
    this.uploadedAt,
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
  }) {
    return Media(
      url: url ?? this.url,
      caption: caption ?? this.caption,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  List<Object?> get props => [url, caption, title, description, duration, type, uploadedAt];
}
