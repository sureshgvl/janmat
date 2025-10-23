import 'package:cloud_firestore/cloud_firestore.dart';

class Highlight {
  final String id;
  final String candidateId;
  final String wardId;
  final String districtId;
  final String bodyId; // Added for hierarchical targeting
  final String locationKey; // Composite key: district_body_ward
  final String package;
  final List<String> placement;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final bool exclusive;
  final bool rotation;
  final DateTime? lastShown;
  final int views;
  final int clicks;
  final String? imageUrl;
  final String? candidateName;
  final String? party;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.candidateId,
    required this.wardId,
    required this.districtId,
    required this.bodyId,
    required this.locationKey,
    required this.package,
    required this.placement,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.exclusive,
    required this.rotation,
    this.lastShown,
    required this.views,
    required this.clicks,
    this.imageUrl,
    this.candidateName,
    this.party,
    required this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['highlightId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      wardId: json['wardId'] ?? '',
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      locationKey: json['locationKey'] ?? '',
      package: json['package'] ?? '',
      placement: List<String>.from(json['placement'] ?? []),
      priority: json['priority'] ?? 1,
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: json['active'] ?? false,
      exclusive: json['exclusive'] ?? false,
      rotation: json['rotation'] ?? true,
      lastShown: (json['lastShown'] as Timestamp?)?.toDate(),
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      imageUrl: json['imageUrl'],
      candidateName: json['candidateName'],
      party: json['party'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': id,
      'candidateId': candidateId,
      'wardId': wardId,
      'districtId': districtId,
      'bodyId': bodyId,
      'locationKey': locationKey,
      'package': package,
      'placement': placement,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'exclusive': exclusive,
      'rotation': rotation,
      'lastShown': lastShown != null ? Timestamp.fromDate(lastShown!) : null,
      'views': views,
      'clicks': clicks,
      'imageUrl': imageUrl,
      'candidateName': candidateName,
      'party': party,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Highlight copyWith({
    String? id,
    String? candidateId,
    String? wardId,
    String? districtId,
    String? bodyId,
    String? locationKey,
    String? package,
    List<String>? placement,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    bool? exclusive,
    bool? rotation,
    DateTime? lastShown,
    int? views,
    int? clicks,
    String? imageUrl,
    String? candidateName,
    String? party,
    DateTime? createdAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      candidateId: candidateId ?? this.candidateId,
      wardId: wardId ?? this.wardId,
      districtId: districtId ?? this.districtId,
      bodyId: bodyId ?? this.bodyId,
      locationKey: locationKey ?? this.locationKey,
      package: package ?? this.package,
      placement: placement ?? this.placement,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      exclusive: exclusive ?? this.exclusive,
      rotation: rotation ?? this.rotation,
      lastShown: lastShown ?? this.lastShown,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      imageUrl: imageUrl ?? this.imageUrl,
      candidateName: candidateName ?? this.candidateName,
      party: party ?? this.party,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

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
