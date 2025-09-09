import 'package:cloud_firestore/cloud_firestore.dart';

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

class ExtraInfo {
  final String? bio;
  final List<String>? achievements;
  final String? manifesto;
  final String? manifestoPdf;
  final Contact? contact;
  final Map<String, dynamic>? media;
  final bool? highlight;
  final List<Map<String, dynamic>>? events;

  ExtraInfo({
    this.bio,
    this.achievements,
    this.manifesto,
    this.manifestoPdf,
    this.contact,
    this.media,
    this.highlight,
    this.events,
  });

  factory ExtraInfo.fromJson(Map<String, dynamic> json) {
    return ExtraInfo(
      bio: json['bio'],
      achievements: json['achievements'] != null
          ? List<String>.from(json['achievements'])
          : null,
      manifesto: json['manifesto'],
      manifestoPdf: json['manifesto_pdf'],
      contact: json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      media: json['media'],
      highlight: json['highlight'],
      events: json['events'] != null
          ? List<Map<String, dynamic>>.from(json['events'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'achievements': achievements,
      'manifesto': manifesto,
      'manifesto_pdf': manifestoPdf,
      'contact': contact?.toJson(),
      'media': media,
      'highlight': highlight,
      'events': events,
    };
  }

  ExtraInfo copyWith({
    String? bio,
    List<String>? achievements,
    String? manifesto,
    String? manifestoPdf,
    Contact? contact,
    Map<String, dynamic>? media,
    bool? highlight,
    List<Map<String, dynamic>>? events,
  }) {
    return ExtraInfo(
      bio: bio ?? this.bio,
      achievements: achievements ?? this.achievements,
      manifesto: manifesto ?? this.manifesto,
      manifestoPdf: manifestoPdf ?? this.manifestoPdf,
      contact: contact ?? this.contact,
      media: media ?? this.media,
      highlight: highlight ?? this.highlight,
      events: events ?? this.events,
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