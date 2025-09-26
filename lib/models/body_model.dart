import 'package:cloud_firestore/cloud_firestore.dart';

enum BodyType {
  municipal_corporation,
  municipal_council,
  nagar_panchayat,
  zilla_parishad,
  panchayat_samiti,
  cantonment_board,
  town_area_committee,
  notified_area_committee,
  industrial_township,
}

class Body {
  final String id;
  final String name;
  final BodyType type;
  final String districtId;
  final String stateId;
  final int? ward_count;
  final Map<String, String>? area_to_ward;
  final Map<String, dynamic>? source;
  final Map<String, dynamic>? special;
  final DateTime? createdAt;

  Body({
    required this.id,
    required this.name,
    required this.type,
    required this.districtId,
    required this.stateId,
    this.ward_count,
    this.area_to_ward,
    this.source,
    this.special,
    this.createdAt,
  });

  factory Body.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    }

    BodyType parseBodyType(String? typeStr) {
      switch (typeStr) {
        case 'municipal_corporation':
          return BodyType.municipal_corporation;
        case 'municipal_council':
          return BodyType.municipal_council;
        case 'nagar_panchayat':
          return BodyType.nagar_panchayat;
        case 'zilla_parishad':
          return BodyType.zilla_parishad;
        case 'panchayat_samiti':
          return BodyType.panchayat_samiti;
        case 'cantonment_board':
          return BodyType.cantonment_board;
        case 'town_area_committee':
          return BodyType.town_area_committee;
        case 'notified_area_committee':
          return BodyType.notified_area_committee;
        case 'industrial_township':
          return BodyType.industrial_township;
        default:
          return BodyType.municipal_corporation; // Default fallback
      }
    }

    return Body(
      id: json['id'] ?? json['bodyId'] ?? '',
      name: json['name'] ?? '',
      type: parseBodyType(json['type']),
      districtId: json['districtId'] ?? '',
      stateId: json['stateId'] ?? '',
      ward_count: json['ward_count'] ?? json['wardCount'],
      area_to_ward: json['area_to_ward'] != null
          ? Map<String, String>.from(json['area_to_ward'])
          : null,
      source: json['source'] != null
          ? Map<String, dynamic>.from(json['source'])
          : null,
      special: json['special'] != null
          ? Map<String, dynamic>.from(json['special'])
          : null,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last, // Convert enum to string
      'districtId': districtId,
      'stateId': stateId,
      'ward_count': ward_count,
      'area_to_ward': area_to_ward,
      'source': source,
      'special': special,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Body copyWith({
    String? id,
    String? name,
    BodyType? type,
    String? districtId,
    String? stateId,
    int? ward_count,
    Map<String, String>? area_to_ward,
    Map<String, dynamic>? source,
    Map<String, dynamic>? special,
    DateTime? createdAt,
  }) {
    return Body(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      districtId: districtId ?? this.districtId,
      stateId: stateId ?? this.stateId,
      ward_count: ward_count ?? this.ward_count,
      area_to_ward: area_to_ward ?? this.area_to_ward,
      source: source ?? this.source,
      special: special ?? this.special,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Body(id: $id, name: $name, type: $type, districtId: $districtId, stateId: $stateId, ward_count: $ward_count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Body &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.districtId == districtId &&
        other.stateId == stateId &&
        other.ward_count == ward_count;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      districtId.hashCode ^
      stateId.hashCode ^
      ward_count.hashCode;
}
