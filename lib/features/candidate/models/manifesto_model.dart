import 'package:equatable/equatable.dart';

class ManifestoModel extends Equatable {
  final String? title;
  final List<Map<String, dynamic>>? promises;
  final String? pdfUrl;
  final String? image;
  final String? videoUrl;

  const ManifestoModel({
    this.title,
    this.promises,
    this.pdfUrl,
    this.image,
    this.videoUrl,
  });

  factory ManifestoModel.fromJson(Map<String, dynamic> json) {
    return ManifestoModel(
      title: json['title'] as String?,
      promises: json['promises'] != null
          ? _parsePromises(json['promises'])
          : null,
      pdfUrl: json['pdfUrl'] as String?,
      image: json['image'] ?? json['images']?.first, // Backward compatibility
      videoUrl: json['videoUrl'] as String?,
    );
  }

  static List<Map<String, dynamic>> _parsePromises(dynamic data) {
    if (data == null) return [];

    // Handle new structured format
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is String) {
          // Convert old string format to new structured format
          return {
            'title': item,
            '1': item, // Use the string as the first point
          };
        } else {
          return {'title': item.toString(), '1': item.toString()};
        }
      }).toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (promises != null) 'promises': promises,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (image != null) 'image': image,
      if (videoUrl != null) 'videoUrl': videoUrl,
    };
  }

  ManifestoModel copyWith({
    String? title,
    List<Map<String, dynamic>>? promises,
    String? pdfUrl,
    String? image,
    String? videoUrl,
  }) {
    return ManifestoModel(
      title: title ?? this.title,
      promises: promises ?? this.promises,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      image: image ?? this.image,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [title, promises, pdfUrl, image, videoUrl];
}