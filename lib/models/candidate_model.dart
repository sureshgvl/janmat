import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'achievement_model.dart';


class Contact {
  final String phone;
  final String? email;
  final Map<String, String>? socialLinks;

  Contact({
    required this.phone,
    this.email,
    this.socialLinks,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      phone: json['phone'] ?? '',
      email: json['email'],
      socialLinks: json['socialLinks'] != null
          ? Map<String, String>.from(json['socialLinks'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'socialLinks': socialLinks,
    };
  }

  Contact copyWith({
    String? phone,
    String? email,
    Map<String, String>? socialLinks,
  }) {
    return Contact(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}

class ManifestoData {
  final String? title;
  final List<Map<String, dynamic>>? promises;
  final String? pdfUrl;
  final List<String>? images;
  final String? videoUrl;

  ManifestoData({
    this.title,
    this.promises,
    this.pdfUrl,
    this.images,
    this.videoUrl,
  });

  factory ManifestoData.fromJson(Map<String, dynamic> json) {
    return ManifestoData(
      title: json['title'],
      promises: json['promises'] != null ? _parsePromises(json['promises']) : null,
      pdfUrl: json['pdfUrl'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      videoUrl: json['videoUrl'],
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
          return {
            'title': item.toString(),
            '1': item.toString(),
          };
        }
      }).toList();
    }

    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'promises': promises,
      'pdfUrl': pdfUrl,
      'images': images,
      'videoUrl': videoUrl,
    };
  }

  ManifestoData copyWith({
    String? title,
    List<Map<String, dynamic>>? promises,
    String? pdfUrl,
    List<String>? images,
    String? videoUrl,
  }) {
    return ManifestoData(
      title: title ?? this.title,
      promises: promises ?? this.promises,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      images: images ?? this.images,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}


class ExtendedContact {
  final String? phone;
  final String? email;
  final String? address;
  final Map<String, String>? socialLinks;
  final String? officeAddress;
  final String? officeHours;

  ExtendedContact({
    this.phone,
    this.email,
    this.address,
    this.socialLinks,
    this.officeAddress,
    this.officeHours,
  });

  factory ExtendedContact.fromJson(Map<String, dynamic> json) {
    return ExtendedContact(
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      socialLinks: json['social_links'] != null
          ? Map<String, String>.from(json['social_links'])
          : null,
      officeAddress: json['office_address'],
      officeHours: json['office_hours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'address': address,
      'social_links': socialLinks,
      'office_address': officeAddress,
      'office_hours': officeHours,
    };
  }
}

class MediaItem {
  final String url;
  final String? caption;
  final String? title;
  final String? description;
  final String? duration;
  final String? type;
  final String? uploadedAt;

  MediaItem({
    required this.url,
    this.caption,
    this.title,
    this.description,
    this.duration,
    this.type,
    this.uploadedAt,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
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
}

class EventData {
  final String? id;
  final String title;
  final String? description;
  final String date;
  final String? time;
  final String? venue;
  final String? mapLink;
  final String? type;
  final String? status;
  final int? attendeesExpected;
  final List<String>? agenda;
  final Map<String, List<String>>? rsvp; // interested, going, not_going

  EventData({
    this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.venue,
    this.mapLink,
    this.type,
    this.status,
    this.attendeesExpected,
    this.agenda,
    this.rsvp,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: json['date'],
      time: json['time'],
      venue: json['venue'],
      mapLink: json['map_link'],
      type: json['type'],
      status: json['status'],
      attendeesExpected: json['attendees_expected'],
      agenda: json['agenda'] != null ? List<String>.from(json['agenda']) : null,
      rsvp: json['rsvp'] != null
          ? Map<String, List<String>>.from(json['rsvp'].map((key, value) =>
              MapEntry(key, value is List ? List<String>.from(value) : [])))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'venue': venue,
      'map_link': mapLink,
      'type': type,
      'status': status,
      'attendees_expected': attendeesExpected,
      'agenda': agenda,
      'rsvp': rsvp,
    };
  }

  // Helper methods for RSVP
  int getInterestedCount() => rsvp?['interested']?.length ?? 0;
  int getGoingCount() => rsvp?['going']?.length ?? 0;
  int getNotGoingCount() => rsvp?['not_going']?.length ?? 0;

  bool isUserInterested(String userId) => rsvp?['interested']?.contains(userId) ?? false;
  bool isUserGoing(String userId) => rsvp?['going']?.contains(userId) ?? false;
  bool isUserNotGoing(String userId) => rsvp?['not_going']?.contains(userId) ?? false;

  EventData copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? venue,
    String? mapLink,
    String? type,
    String? status,
    int? attendeesExpected,
    List<String>? agenda,
    Map<String, List<String>>? rsvp,
  }) {
    return EventData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      venue: venue ?? this.venue,
      mapLink: mapLink ?? this.mapLink,
      type: type ?? this.type,
      status: status ?? this.status,
      attendeesExpected: attendeesExpected ?? this.attendeesExpected,
      agenda: agenda ?? this.agenda,
      rsvp: rsvp ?? this.rsvp,
    );
  }
}

class HighlightData {
  final bool enabled;
  final String? title;
  final String? message;
  final String? imageUrl;
  final String? priority;
  final String? expiresAt;

  HighlightData({
    required this.enabled,
    this.title,
    this.message,
    this.imageUrl,
    this.priority,
    this.expiresAt,
  });

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    return HighlightData(
      enabled: json['enabled'] ?? false,
      title: json['title'],
      message: json['message'],
      imageUrl: json['image_url'],
      priority: json['priority'],
      expiresAt: json['expires_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'priority': priority,
      'expires_at': expiresAt,
    };
  }
}

class AnalyticsData {
  final int? profileViews;
  final int? manifestoViews;
  final List<Map<String, dynamic>>? followerGrowth;
  final double? engagementRate;
  final Map<String, dynamic>? topPerformingContent;
  final Map<String, dynamic>? demographics;

  AnalyticsData({
    this.profileViews,
    this.manifestoViews,
    this.followerGrowth,
    this.engagementRate,
    this.topPerformingContent,
    this.demographics,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      profileViews: json['profile_views'],
      manifestoViews: json['manifesto_views'],
      followerGrowth: json['follower_growth'] != null
          ? List<Map<String, dynamic>>.from(json['follower_growth'])
          : null,
      engagementRate: json['engagement_rate']?.toDouble(),
      topPerformingContent: json['top_performing_content'],
      demographics: json['demographics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile_views': profileViews,
      'manifesto_views': manifestoViews,
      'follower_growth': followerGrowth,
      'engagement_rate': engagementRate,
      'top_performing_content': topPerformingContent,
      'demographics': demographics,
    };
  }
}

class BasicInfoData {
  final String? fullName;
  final String? dateOfBirth;
  final int? age;
  final String? gender;
  final String? education;
  final String? profession;
  final List<String>? languages;
  final int? experienceYears;
  final List<String>? previousPositions;

  BasicInfoData({
    this.fullName,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.education,
    this.profession,
    this.languages,
    this.experienceYears,
    this.previousPositions,
  });

  factory BasicInfoData.fromJson(Map<String, dynamic> json) {
    return BasicInfoData(
      fullName: json['full_name'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      gender: json['gender'],
      education: json['education'],
      profession: json['profession'],
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      experienceYears: json['experience_years'],
      previousPositions: json['previous_positions'] != null ? List<String>.from(json['previous_positions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'age': age,
      'gender': gender,
      'education': education,
      'profession': profession,
      'languages': languages,
      'experience_years': experienceYears,
      'previous_positions': previousPositions,
    };
  }
}

class ExtraInfo {
  final String? bio;
  final List<Achievement>? achievements;
  final ManifestoData? manifesto;
  final ExtendedContact? contact;
  final Map<String, List<MediaItem>>? media;
  final List<EventData>? events;
  final HighlightData? highlight;
  final AnalyticsData? analytics;
  final BasicInfoData? basicInfo;

  ExtraInfo({
    this.bio,
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
    debugPrint('🔍 ExtraInfo.fromJson - Raw JSON keys: ${json.keys.toList()}');
    debugPrint('   education field: ${json['education']}');
    debugPrint('   basic_info exists: ${json['basic_info'] != null}');

    // Handle backward compatibility for raw fields
    BasicInfoData? basicInfo = json['basic_info'] != null ? BasicInfoData.fromJson(json['basic_info']) : null;
    ExtendedContact? contact = json['contact'] != null ? ExtendedContact.fromJson(json['contact']) : null;

    // If basicInfo exists, merge raw fields into it
    if (basicInfo != null) {
      debugPrint('   Merging raw fields into existing basicInfo');
      basicInfo = BasicInfoData(
        fullName: basicInfo.fullName,
        dateOfBirth: basicInfo.dateOfBirth,
        age: basicInfo.age ?? (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
        gender: basicInfo.gender ?? json['gender'],
        education: basicInfo.education ?? json['education'], // This is the key fix!
        profession: basicInfo.profession ?? json['profession'],
        languages: basicInfo.languages ?? (json['languages'] != null ? List<String>.from(json['languages']) : null),
        experienceYears: basicInfo.experienceYears ?? json['experience_years'],
        previousPositions: basicInfo.previousPositions ?? (json['previous_positions'] != null ? List<String>.from(json['previous_positions']) : null),
      );
    }
    // If basicInfo doesn't exist but we have raw education field, create basicInfo
    else if (json['education'] != null) {
      debugPrint('   Creating basicInfo from raw education field');
      basicInfo = BasicInfoData(
        education: json['education'],
        age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
        gender: json['gender'],
        fullName: json['full_name'],
        dateOfBirth: json['date_of_birth'],
        profession: json['profession'],
        languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
        experienceYears: json['experience_years'],
        previousPositions: json['previous_positions'] != null ? List<String>.from(json['previous_positions']) : null,
      );
    }

    // If contact doesn't exist but we have raw address field, create contact
    if (contact == null && json['address'] != null) {
      debugPrint('   Creating contact from raw address field');
      contact = ExtendedContact(
        address: json['address'],
        phone: json['phone'],
        email: json['email'],
        socialLinks: json['social_links'] != null ? Map<String, String>.from(json['social_links']) : null,
        officeAddress: json['office_address'],
        officeHours: json['office_hours'],
      );
    }

    debugPrint('   Final basicInfo.education: ${basicInfo?.education}');

    return ExtraInfo(
      bio: json['bio'],
      achievements: json['achievements'] != null
          ? (json['achievements'] as List<dynamic>)
              .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      manifesto: json['manifesto'] != null ? ManifestoData.fromJson(json['manifesto']) : null,
      contact: contact,
      media: json['media'] != null
          ? _parseMediaData(json['media'])
          : null,
      events: json['events'] != null
          ? (json['events'] as List<dynamic>)
              .map((item) => EventData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
      highlight: json['highlight'] != null ? HighlightData.fromJson(json['highlight']) : null,
      analytics: json['analytics'] != null ? AnalyticsData.fromJson(json['analytics']) : null,
      basicInfo: basicInfo,
    );
  }

  static Map<String, List<MediaItem>>? _parseMediaData(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return null;

    final Map<String, List<MediaItem>> result = {};

    data.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((item) => MediaItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    });

    return result;
  }

  // Helper method to parse manifesto promises from different formats
  static List<Map<String, dynamic>>? _parseManifestoPromises(dynamic data) {
    if (data == null) return null;

    try {
      // Handle new format: List<Map<String, dynamic>>
      if (data is List) {
        return data.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is String) {
            // Convert old string format to new map format
            return {
              'title': item,
              'points': [item], // Use the string as both title and first point
            };
          } else {
            return {'title': item.toString(), 'points': [item.toString()]};
          }
        }).toList();
      }

      // Handle old format: single string (shouldn't happen but safety check)
      if (data is String) {
        return [{
          'title': data,
          'points': [data],
        }];
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing manifesto promises: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'achievements': achievements?.map((a) => a.toJson()).toList(),
      'manifesto': manifesto?.toJson(),
      'contact': contact?.toJson(),
      'media': media?.map((key, value) => MapEntry(key, value.map((item) => item.toJson()).toList())),
      'events': events?.map((e) => e.toJson()).toList(),
      'highlight': highlight?.toJson(),
      'analytics': analytics?.toJson(),
      'basic_info': basicInfo?.toJson(),
    };
  }

  ExtraInfo copyWith({
    String? bio,
    List<Achievement>? achievements,
    ManifestoData? manifesto,
    ExtendedContact? contact,
    Map<String, List<MediaItem>>? media,
    List<EventData>? events,
    HighlightData? highlight,
    AnalyticsData? analytics,
    BasicInfoData? basicInfo,
  }) {
    return ExtraInfo(
      bio: bio ?? this.bio,
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
}

class Candidate {
  final String candidateId;
  final String? userId; // User who registered this candidate
  final String name;
  final String party;
  final String? symbol;
  final String cityId;
  final String wardId;
  final String? manifesto;
  final String? photo;
  final String? coverPhoto; // Premium feature: Facebook-style cover photo
  final Contact contact;
  final bool sponsored;
  final bool premium; // Premium candidate features
  final DateTime createdAt;
  final ExtraInfo? extraInfo;
  final int followersCount;
  final int followingCount;
  final bool? approved; // Admin approval status
  final String? status; // "pending_election" or "finalized"

  Candidate({
    required this.candidateId,
    this.userId,
    required this.name,
    required this.party,
    this.symbol,
    required this.cityId,
    required this.wardId,
    this.manifesto,
    this.photo,
    this.coverPhoto,
    required this.contact,
    required this.sponsored,
    required this.premium,
    required this.createdAt,
    this.extraInfo,
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
      symbol: json['symbol'],
      cityId: json['cityId'] ?? '',
      wardId: json['wardId'] ?? '',
      manifesto: json['manifesto'],
      photo: json['photo'],
      coverPhoto: json['coverPhoto'],
      contact: Contact.fromJson(json['contact'] ?? {}),
      sponsored: json['sponsored'] ?? false,
      premium: json['premium'] ?? false,
      createdAt: createdAt,
      extraInfo: json['extra_info'] != null ? ExtraInfo.fromJson(json['extra_info']) : null,
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
      'symbol': symbol,
      'cityId': cityId,
      'wardId': wardId,
      'manifesto': manifesto,
      'photo': photo,
      'coverPhoto': coverPhoto,
      'contact': contact.toJson(),
      'sponsored': sponsored,
      'premium': premium,
      'createdAt': createdAt.toIso8601String(),
      'extra_info': extraInfo?.toJson(),
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
    String? symbol,
    String? cityId,
    String? wardId,
    String? manifesto,
    String? photo,
    String? coverPhoto,
    Contact? contact,
    bool? sponsored,
    bool? premium,
    DateTime? createdAt,
    ExtraInfo? extraInfo,
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
      symbol: symbol ?? this.symbol,
      cityId: cityId ?? this.cityId,
      wardId: wardId ?? this.wardId,
      manifesto: manifesto ?? this.manifesto,
      photo: photo ?? this.photo,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      contact: contact ?? this.contact,
      sponsored: sponsored ?? this.sponsored,
      premium: premium ?? this.premium,
      createdAt: createdAt ?? this.createdAt,
      extraInfo: extraInfo ?? this.extraInfo,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      approved: approved ?? this.approved,
      status: status ?? this.status,
    );
  }
}
