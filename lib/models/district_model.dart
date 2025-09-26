import 'package:cloud_firestore/cloud_firestore.dart';

class District {
  final String id;
  final String name;
  final String stateId;
  final String? municipalCorporation;
  final String? municipalCouncil;
  final String? nagarPanchayat;
  final String? zillaParishad;
  final String? panchayatSamiti;
  final String? municipalCorporationPdfUrl;
  final String? municipalCouncilPdfUrl;
  final String? nagarPanchayatPdfUrl;
  final String? zillaParishadPdfUrl;
  final String? panchayatSamitiPdfUrl;
  final DateTime? createdAt;

  District({
    required this.id,
    required this.name,
    required this.stateId,
    this.municipalCorporation,
    this.municipalCouncil,
    this.nagarPanchayat,
    this.zillaParishad,
    this.panchayatSamiti,
    this.municipalCorporationPdfUrl,
    this.municipalCouncilPdfUrl,
    this.nagarPanchayatPdfUrl,
    this.zillaParishadPdfUrl,
    this.panchayatSamitiPdfUrl,
    this.createdAt,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    }

    return District(
      id: json['id'] ?? json['districtId'] ?? '',
      name: json['name'] ?? '',
      stateId: json['stateId'] ?? '',
      municipalCorporation: json['municipalCorporation'],
      municipalCouncil: json['municipalCouncil'],
      nagarPanchayat: json['nagarPanchayat'],
      zillaParishad: json['zillaParishad'],
      panchayatSamiti: json['panchayatSamiti'],
      municipalCorporationPdfUrl: json['municipalCorporationPdfUrl'],
      municipalCouncilPdfUrl: json['municipalCouncilPdfUrl'],
      nagarPanchayatPdfUrl: json['nagarPanchayatPdfUrl'],
      zillaParishadPdfUrl: json['zillaParishadPdfUrl'],
      panchayatSamitiPdfUrl: json['panchayatSamitiPdfUrl'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stateId': stateId,
      'municipalCorporation': municipalCorporation,
      'municipalCouncil': municipalCouncil,
      'nagarPanchayat': nagarPanchayat,
      'zillaParishad': zillaParishad,
      'panchayatSamiti': panchayatSamiti,
      'municipalCorporationPdfUrl': municipalCorporationPdfUrl,
      'municipalCouncilPdfUrl': municipalCouncilPdfUrl,
      'nagarPanchayatPdfUrl': nagarPanchayatPdfUrl,
      'zillaParishadPdfUrl': zillaParishadPdfUrl,
      'panchayatSamitiPdfUrl': panchayatSamitiPdfUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  District copyWith({
    String? id,
    String? name,
    String? stateId,
    String? municipalCorporation,
    String? municipalCouncil,
    String? nagarPanchayat,
    String? zillaParishad,
    String? panchayatSamiti,
    String? municipalCorporationPdfUrl,
    String? municipalCouncilPdfUrl,
    String? nagarPanchayatPdfUrl,
    String? zillaParishadPdfUrl,
    String? panchayatSamitiPdfUrl,
    DateTime? createdAt,
  }) {
    return District(
      id: id ?? this.id,
      name: name ?? this.name,
      stateId: stateId ?? this.stateId,
      municipalCorporation: municipalCorporation ?? this.municipalCorporation,
      municipalCouncil: municipalCouncil ?? this.municipalCouncil,
      nagarPanchayat: nagarPanchayat ?? this.nagarPanchayat,
      zillaParishad: zillaParishad ?? this.zillaParishad,
      panchayatSamiti: panchayatSamiti ?? this.panchayatSamiti,
      municipalCorporationPdfUrl: municipalCorporationPdfUrl ?? this.municipalCorporationPdfUrl,
      municipalCouncilPdfUrl: municipalCouncilPdfUrl ?? this.municipalCouncilPdfUrl,
      nagarPanchayatPdfUrl: nagarPanchayatPdfUrl ?? this.nagarPanchayatPdfUrl,
      zillaParishadPdfUrl: zillaParishadPdfUrl ?? this.zillaParishadPdfUrl,
      panchayatSamitiPdfUrl: panchayatSamitiPdfUrl ?? this.panchayatSamitiPdfUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'District(id: $id, name: $name, stateId: $stateId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District &&
        other.id == id &&
        other.name == name &&
        other.stateId == stateId;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ stateId.hashCode;
}
