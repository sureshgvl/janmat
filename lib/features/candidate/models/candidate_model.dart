import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';
import 'contact_model.dart';
import 'achievements_model.dart';
import 'basic_info_model.dart';
import 'analytics_model.dart';
import 'events_model.dart';
import 'highlights_model.dart';
import 'manifesto_model.dart';
import 'follower_model.dart';

class Candidate {
  final String candidateId;
  final String? userId; // User who registered this candidate
  final String party;
  final String? symbolUrl;
  final String? symbolName;
  final LocationModel location; // New location model
  final String? photo;
  final String? coverPhoto; // Premium feature: Facebook-style cover photo
  final ContactModel contact;
  final bool sponsored;
  final DateTime createdAt;

  // Flattened fields from extra_info - all at top level
  final List<Achievement>? achievements;
  final BasicInfoModel? basicInfo;
  final AnalyticsModel? analytics;
  final List<EventData>? events;
  final List<HighlightData>? highlights;
  final ManifestoModel? manifestoData;
  final List<dynamic>? media;

  final int followersCount;
  final int followingCount;
  final List<Follower>? followers; // Optional: loaded on demand for analytics/admin views
  final String? fcmToken; // For push notifications - cached from user profile
  final bool? approved; // Admin approval status
  final String? status; // "pending_election" or "finalized"

  // Deferred delete pattern: Storage paths waiting for cleanup by Cloud Function
  final List<String>? deleteStorage;

  Candidate({
    required this.candidateId,
    this.userId,
    required this.party,
    this.symbolUrl,
    this.symbolName,
    required this.location,
    this.photo,
    this.coverPhoto,
    required this.contact,
    required this.sponsored,
    required this.createdAt,
    this.achievements,
    this.basicInfo,
    this.analytics,
    this.events,
    this.highlights,
    this.manifestoData,
    this.media,
    this.followersCount = 0,
    this.followingCount = 0,
    this.followers,
    this.fcmToken,
    this.approved,
    this.status,
    this.deleteStorage,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    // Handle Firestore Timestamp conversion
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    // Determine photo source: prefer basic_info.photo, fallback to top-level photo
    String? extractedPhoto = (json['basic_info']?['photo'] as String?) ?? json['photo'];

    return Candidate(
      candidateId: json['candidateId'] ?? '',
      userId: json['userId'],
      party: json['party'] ?? '',
      symbolUrl: json['symbol'],
      symbolName: json['symbolName'],
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : LocationModel(
              stateId: json['stateId'],
              districtId: json['districtId'],
              bodyId: json['bodyId'],
              wardId: json['wardId'],
            ),
      photo: extractedPhoto,
      coverPhoto: json['coverPhoto'],
      contact: ContactModel.fromJson(json['contact'] ?? {}),
      sponsored: json['sponsored'] ?? false,
      createdAt: createdAt,
      achievements: json['achievements'] != null
          ? (json['achievements'] as List<dynamic>)
                .map(
                  (item) => Achievement.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
      basicInfo: json['basic_info'] != null
          ? BasicInfoModel.fromJson(json['basic_info'])
          : null,
      analytics: json['analytics'] != null
          ? AnalyticsModel.fromJson(json['analytics'])
          : null,
      events: json['events'] != null
          ? (json['events'] as List<dynamic>)
                .map((item) => EventData.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
      highlights: json['highlights'] != null
          ? (json['highlights'] as List<dynamic>)
                .map(
                  (item) =>
                      HighlightData.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
      manifestoData: json['manifesto_data'] != null
          ? ManifestoModel.fromJson(json['manifesto_data'])
          : null,
      media: _parseMediaData(json['media']),
      followersCount: json['followersCount']?.toInt() ?? 0,
      followingCount: json['followingCount']?.toInt() ?? 0,
      fcmToken: json['fcmToken'],
      approved: json['approved'],
      status: json['status'],
      deleteStorage: json['deleteStorage'] != null
          ? List<String>.from(json['deleteStorage'] as List<dynamic>)
          : null,
    );
  }

  /// Helper method to parse media data - stores raw Firebase data as Maps for grouped format
  static List<dynamic>? _parseMediaData(dynamic mediaData) {
    if (mediaData == null) return null;

    if (mediaData is! List) return null;

    final List<dynamic> mediaList = List<dynamic>.from(mediaData);
    return mediaList.isEmpty ? [] : mediaList;
  }



  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'userId': userId,
      'party': party,
      'symbol': symbolUrl,
      'symbolName': symbolName,
      'location': location.toJson(),
      'photo': photo,
      'coverPhoto': coverPhoto,
      'contact': contact.toJson(),
      'sponsored': sponsored,
      'createdAt': createdAt.toIso8601String(),
      'achievements': achievements?.map((a) => a.toJson()).toList(),
      'basic_info': basicInfo?.toJson(),
      'analytics': analytics?.toJson(),
      'events': events?.map((e) => e.toJson()).toList(),
      'highlights': highlights?.map((h) => h.toJson()).toList(),
      'manifesto_data': manifestoData?.toJson(),
      'media': media,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'fcmToken': fcmToken,
      'approved': approved,
      'status': status,
      'deleteStorage': deleteStorage,
    };
  }

  Candidate copyWith({
    String? candidateId,
    String? userId,
    String? party,
    String? symbolUrl,
    String? symbolName,
    LocationModel? location,
    String? photo,
    String? coverPhoto,
    ContactModel? contact,
    bool? sponsored,
    DateTime? createdAt,
    List<Achievement>? achievements,
    BasicInfoModel? basicInfo,
    AnalyticsModel? analytics,
    List<EventData>? events,
    List<HighlightData>? highlights,
    ManifestoModel? manifestoData,
    List<dynamic>? media,
    int? followersCount,
    int? followingCount,
    List<Follower>? followers,
    String? fcmToken,
    bool? approved,
    String? status,
    List<String>? deleteStorage,
  }) {
    return Candidate(
      candidateId: candidateId ?? this.candidateId,
      userId: userId ?? this.userId,
      party: party ?? this.party,
      symbolUrl: symbolUrl ?? this.symbolUrl,
      symbolName: symbolName ?? this.symbolName,
      location: location ?? this.location,
      photo: photo ?? this.photo,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      contact: contact ?? this.contact,
      sponsored: sponsored ?? this.sponsored,
      createdAt: createdAt ?? this.createdAt,
      achievements: achievements ?? this.achievements,
      basicInfo: basicInfo ?? this.basicInfo,
      analytics: analytics ?? this.analytics,
      events: events ?? this.events,
      highlights: highlights ?? this.highlights,
      manifestoData: manifestoData ?? this.manifestoData,
      media: media ?? this.media,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      followers: followers ?? this.followers,
      fcmToken: fcmToken ?? this.fcmToken,
      approved: approved ?? this.approved,
      status: status ?? this.status,
      deleteStorage: deleteStorage ?? this.deleteStorage,
    );
  }
}
