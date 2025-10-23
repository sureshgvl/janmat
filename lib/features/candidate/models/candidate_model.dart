import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import 'location_model.dart';
import 'contact_model.dart';
import 'achievements_model.dart';
import 'basic_info_model.dart';
import 'analytics_model.dart';
import 'events_model.dart';
import 'highlights_model.dart';
import 'manifesto_model.dart';
import 'media_model.dart';

class Candidate {
  final String candidateId;
  final String? userId; // User who registered this candidate
  final String name;
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
  final List<Media>? media;

  final int followersCount;
  final int followingCount;
  final bool? approved; // Admin approval status
  final String? status; // "pending_election" or "finalized"

  Candidate({
    required this.candidateId,
    this.userId,
    required this.name,
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
    this.approved,
    this.status,
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

    return Candidate(
      candidateId: json['candidateId'] ?? '',
      userId: json['userId'],
      name: json['name'] ?? '',
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
      photo: json['photo'],
      coverPhoto: json['coverPhoto'],
      contact: ContactModel.fromJson(json['contact'] ?? {}),
      sponsored: json['sponsored'] ?? false,
      createdAt: createdAt,
      achievements: json['achievements'] != null
          ? (json['achievements'] as List<dynamic>)
              .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
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
              .map((item) => HighlightData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      manifestoData: json['manifesto_data'] != null
          ? ManifestoModel.fromJson(json['manifesto_data'])
          : null,
      media: json['media'] != null
          ? (json['media'] as List<dynamic>)
              .map((item) => Media.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      followersCount: json['followersCount']?.toInt() ?? 0,
      followingCount: json['followingCount']?.toInt() ?? 0,
      approved: json['approved'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'userId': userId,
      'name': name,
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
      'media': media?.map((m) => m.toJson()).toList(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'approved': approved,
      'status': status,
    };
  }

  Candidate copyWith({
    String? candidateId,
    String? userId,
    String? name,
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
    List<Media>? media,
    int? followersCount,
    int? followingCount,
    bool? approved,
    String? status,
  }) {
    return Candidate(
      candidateId: candidateId ?? this.candidateId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
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
      approved: approved ?? this.approved,
      status: status ?? this.status,
    );
  }
}
