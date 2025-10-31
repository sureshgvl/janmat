import 'package:cloud_firestore/cloud_firestore.dart';

class PushFeedItem {
  final String id;
  final String? highlightId;
  final String candidateId;
  final String wardId;
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isSponsored;

  PushFeedItem({
    required this.id,
    this.highlightId,
    required this.candidateId,
    required this.wardId,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.isSponsored,
  });

  factory PushFeedItem.fromJson(Map<String, dynamic> json) {
    return PushFeedItem(
      id: json['feedId'] ?? '',
      highlightId: json['highlightId'],
      candidateId: json['candidateId'] ?? '',
      wardId: json['wardId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSponsored: json['isSponsored'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedId': id,
      'highlightId': highlightId,
      'candidateId': candidateId,
      'wardId': wardId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSponsored': isSponsored,
    };
  }
}
