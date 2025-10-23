import 'package:equatable/equatable.dart';
import '../../../utils/app_logger.dart';
import 'achievements_model.dart';
import 'basic_info_model.dart';
import 'manifesto_model.dart';
import 'contact_model.dart';
import 'media_model.dart';
import 'events_model.dart';
import 'highlights_model.dart';
import 'analytics_model.dart';

class ExtraInfo extends Equatable {
  final AchievementsModel? achievements;
  final ManifestoModel? manifesto;
  final ContactModel? contact;
  final List<Media>? media;
  final List<EventData>? events;
  final HighlightData? highlight;
  final AnalyticsModel? analytics;
  final BasicInfoModel? basicInfo;

  ExtraInfo({
    this.achievements,
    this.manifesto,
    this.contact,
    this.media,
    this.events,
    this.highlight,
    this.analytics,
    this.basicInfo,
  });

  factory ExtraInfo.fromJson(Map<String, dynamic> json) {
    AppLogger.candidate('🔍 ExtraInfo.fromJson - Raw JSON keys: ${json.keys.toList()}');
    AppLogger.candidate('   education field: ${json['education']}');
    AppLogger.candidate('   profession field: ${json['profession']}');
    AppLogger.candidate('   languages field: ${json['languages']}');
    AppLogger.candidate('   address field: ${json['address']}');
    AppLogger.candidate('   basic_info exists: ${json['basic_info'] != null}');

    // Handle backward compatibility for raw fields
    BasicInfoModel? basicInfo = json['basic_info'] != null
        ? BasicInfoModel.fromJson(json['basic_info'])
        : null;
    ContactModel? contact = json['contact'] != null
        ? ContactModel.fromJson(json['contact'])
        : null;

    // If basicInfo exists, merge raw fields into it
    if (basicInfo != null) {
      AppLogger.candidate('   Merging raw fields into existing basicInfo');
      basicInfo = BasicInfoModel(
        fullName: basicInfo.fullName ?? json['fullName'] as String?,
        dateOfBirth: basicInfo.dateOfBirth ??
            (json['dateOfBirth'] != null
                ? DateTime.tryParse(json['dateOfBirth'].toString())
                : null),
        age: basicInfo.age ??
            (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
        gender: basicInfo.gender ?? json['gender'] as String?,
        education: basicInfo.education ?? json['education'] as String?,
        profession: basicInfo.profession ?? json['profession'] as String?,
        languages: basicInfo.languages ??
            (json['languages'] != null
                ? List<String>.from(json['languages'])
                : null),
        experienceYears: basicInfo.experienceYears ??
            (json['experienceYears'] != null
                ? int.tryParse(json['experienceYears'].toString())
                : null),
        previousPositions: basicInfo.previousPositions ??
            (json['previousPositions'] != null
                ? List<String>.from(json['previousPositions'])
                : null),
        photo: basicInfo.photo ?? json['photo'] as String?,
      );
    }
    // If basicInfo doesn't exist but we have raw fields, create basicInfo
    else if (json['education'] != null ||
             json['profession'] != null ||
             json['languages'] != null ||
             json['fullName'] != null ||
             json['age'] != null ||
             json['gender'] != null) {
      AppLogger.candidate('   Creating basicInfo from raw fields');
      basicInfo = BasicInfoModel(
        fullName: json['fullName'] as String?,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.tryParse(json['dateOfBirth'].toString())
            : null,
        age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
        gender: json['gender'] as String?,
        education: json['education'] as String?,
        profession: json['profession'] as String?,
        languages: json['languages'] != null
            ? List<String>.from(json['languages'])
            : null,
        experienceYears: json['experienceYears'] != null
            ? int.tryParse(json['experienceYears'].toString())
            : null,
        previousPositions: json['previousPositions'] != null
            ? List<String>.from(json['previousPositions'])
            : null,
        photo: json['photo'] as String?,
      );
    }

    // If contact doesn't exist but we have raw address field, create contact
    if (contact == null && json['address'] != null) {
      AppLogger.candidate('   Creating contact from raw address field');
      contact = ContactModel(
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        socialLinks: json['social_links'] != null
            ? Map<String, String>.from(json['social_links'])
            : null,
        officeAddress: json['office_address'] as String?,
        officeHours: json['office_hours'] as String?,
      );
    }

    AppLogger.candidate('   Final basicInfo.education: ${basicInfo?.education}');

    return ExtraInfo(
      achievements: json['achievements'] != null
          ? AchievementsModel.fromJson(json['achievements'])
          : null,
      manifesto: json['manifesto'] != null
          ? ManifestoModel.fromJson(json['manifesto'])
          : null,
      contact: contact,
      media: json['media'] != null
          ? (json['media'] as List<dynamic>)
              .map((item) => Media.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      events: json['events'] != null
          ? (json['events'] as List<dynamic>)
              .map((item) => EventData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      highlight: json['highlight'] != null
          ? HighlightData.fromJson(json['highlight'])
          : null,
      analytics: json['analytics'] != null
          ? AnalyticsModel.fromJson(json['analytics'])
          : null,
      basicInfo: basicInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievements': achievements?.toJson(),
      'manifesto': manifesto?.toJson(),
      'contact': contact?.toJson(),
      'media': media?.map((m) => m.toJson()).toList(), // media is already List<Media>
      'events': events?.map((e) => e.toJson()).toList(),
      'highlight': highlight?.toJson(),
      'analytics': analytics?.toJson(),
      'basic_info': basicInfo?.toJson(),
    };
  }

  ExtraInfo copyWith({
    AchievementsModel? achievements,
    ManifestoModel? manifesto,
    ContactModel? contact,
    List<Media>? media,
    List<EventData>? events,
    HighlightData? highlight,
    AnalyticsModel? analytics,
    BasicInfoModel? basicInfo,
  }) {
    return ExtraInfo(
      achievements: achievements ?? this.achievements,
      manifesto: manifesto ?? this.manifesto,
      contact: contact ?? this.contact,
      media: media ?? this.media,
      events: events ?? this.events,
      highlight: highlight ?? this.highlight,
      analytics: analytics ?? this.analytics,
      basicInfo: basicInfo ?? this.basicInfo,
    );
  }

  @override
  List<Object?> get props => [
        achievements,
        manifesto,
        contact,
        media,
        events,
        highlight,
        analytics,
        basicInfo,
      ];
}
