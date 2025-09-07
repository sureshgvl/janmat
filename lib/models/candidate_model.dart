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
}

class Candidate {
  final String candidateId;
  final String name;
  final String party;
  final String? symbol;
  final String cityId;
  final String wardId;
  final String? manifesto;
  final String? photo;
  final Contact contact;
  final bool sponsored;
  final DateTime createdAt;
  final ExtraInfo? extraInfo;

  Candidate({
    required this.candidateId,
    required this.name,
    required this.party,
    this.symbol,
    required this.cityId,
    required this.wardId,
    this.manifesto,
    this.photo,
    required this.contact,
    required this.sponsored,
    required this.createdAt,
    this.extraInfo,
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
      name: json['name'] ?? '',
      party: json['party'] ?? '',
      symbol: json['symbol'],
      cityId: json['cityId'] ?? '',
      wardId: json['wardId'] ?? '',
      manifesto: json['manifesto'],
      photo: json['photo'],
      contact: Contact.fromJson(json['contact'] ?? {}),
      sponsored: json['sponsored'] ?? false,
      createdAt: createdAt,
      extraInfo: json['extra_info'] != null ? ExtraInfo.fromJson(json['extra_info']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'name': name,
      'party': party,
      'symbol': symbol,
      'cityId': cityId,
      'wardId': wardId,
      'manifesto': manifesto,
      'photo': photo,
      'contact': contact.toJson(),
      'sponsored': sponsored,
      'createdAt': createdAt.toIso8601String(),
      'extra_info': extraInfo?.toJson(),
    };
  }

  Candidate copyWith({
    String? candidateId,
    String? name,
    String? party,
    String? symbol,
    String? cityId,
    String? wardId,
    String? manifesto,
    String? photo,
    Contact? contact,
    bool? sponsored,
    DateTime? createdAt,
    ExtraInfo? extraInfo,
  }) {
    return Candidate(
      candidateId: candidateId ?? this.candidateId,
      name: name ?? this.name,
      party: party ?? this.party,
      symbol: symbol ?? this.symbol,
      cityId: cityId ?? this.cityId,
      wardId: wardId ?? this.wardId,
      manifesto: manifesto ?? this.manifesto,
      photo: photo ?? this.photo,
      contact: contact ?? this.contact,
      sponsored: sponsored ?? this.sponsored,
      createdAt: createdAt ?? this.createdAt,
      extraInfo: extraInfo ?? this.extraInfo,
    );
  }
}