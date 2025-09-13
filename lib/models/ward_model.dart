import 'package:cloud_firestore/cloud_firestore.dart';

class Ward {
  final String wardId;
  final String districtId;
  final String bodyId;
  final String name;
  final int? number;
  final int? populationTotal;
  final int? scPopulation;
  final int? stPopulation;
  final List<String>? areas;
  final DateTime? createdAt;

  Ward({
    required this.wardId,
    required this.districtId,
    required this.bodyId,
    required this.name,
    this.number,
    this.populationTotal,
    this.scPopulation,
    this.stPopulation,
    this.areas,
    this.createdAt,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    }

    return Ward(
      wardId: json['wardId'] ?? json['id'] ?? '',
      districtId: json['districtId'] ?? json['cityId'] ?? '', // Backward compatibility
      bodyId: json['bodyId'] ?? '',
      name: json['name'] ?? '',
      number: json['number'],
      populationTotal: json['population_total'] ?? json['populationTotal'],
      scPopulation: json['sc_population'] ?? json['scPopulation'],
      stPopulation: json['st_population'] ?? json['stPopulation'],
      areas: json['areas'] != null ? List<String>.from(json['areas']) : null,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wardId': wardId,
      'districtId': districtId,
      'bodyId': bodyId,
      'name': name,
      'number': number,
      'population_total': populationTotal,
      'sc_population': scPopulation,
      'st_population': stPopulation,
      'areas': areas,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Ward copyWith({
    String? wardId,
    String? districtId,
    String? bodyId,
    String? name,
    int? number,
    int? populationTotal,
    int? scPopulation,
    int? stPopulation,
    List<String>? areas,
    DateTime? createdAt,
  }) {
    return Ward(
      wardId: wardId ?? this.wardId,
      districtId: districtId ?? this.districtId,
      bodyId: bodyId ?? this.bodyId,
      name: name ?? this.name,
      number: number ?? this.number,
      populationTotal: populationTotal ?? this.populationTotal,
      scPopulation: scPopulation ?? this.scPopulation,
      stPopulation: stPopulation ?? this.stPopulation,
      areas: areas ?? this.areas,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
