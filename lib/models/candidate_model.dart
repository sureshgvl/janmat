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
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
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
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
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
    };
  }
}