import 'package:cloud_firestore/cloud_firestore.dart';

class Ward {
  final String id;
  final String districtId;
  final String bodyId;
  final String name;
  final int? number;
  final String stateId;
  final int? population_total;
  final int? sc_population;
  final int? st_population;
  final List<String>? areas;
  final String? assembly_constituency;
  final String? parliamentary_constituency;
  final DateTime? createdAt;

  Ward({
    required this.id,
    required this.districtId,
    required this.bodyId,
    required this.name,
    this.number,
    required this.stateId,
    this.population_total,
    this.sc_population,
    this.st_population,
    this.areas,
    this.assembly_constituency,
    this.parliamentary_constituency,
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
      id: json['id'] ?? json['wardId'] ?? '',
      districtId:
          json['districtId'] ?? json['cityId'] ?? '', // Backward compatibility
      bodyId: json['bodyId'] ?? '',
      name: json['name'] ?? '',
      number: json['number'],
      stateId: json['stateId'] ?? '',
      population_total: json['population_total'] ?? json['populationTotal'],
      sc_population: json['sc_population'] ?? json['scPopulation'],
      st_population: json['st_population'] ?? json['stPopulation'],
      areas: json['areas'] != null ? List<String>.from(json['areas']) : null,
      assembly_constituency: json['assembly_constituency'],
      parliamentary_constituency: json['parliamentary_constituency'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'districtId': districtId,
      'bodyId': bodyId,
      'name': name,
      'number': number,
      'stateId': stateId,
      'population_total': population_total,
      'sc_population': sc_population,
      'st_population': st_population,
      'areas': areas,
      'assembly_constituency': assembly_constituency,
      'parliamentary_constituency': parliamentary_constituency,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Ward copyWith({
    String? id,
    String? districtId,
    String? bodyId,
    String? name,
    int? number,
    String? stateId,
    int? population_total,
    int? sc_population,
    int? st_population,
    List<String>? areas,
    String? assembly_constituency,
    String? parliamentary_constituency,
    DateTime? createdAt,
  }) {
    return Ward(
      id: id ?? this.id,
      districtId: districtId ?? this.districtId,
      bodyId: bodyId ?? this.bodyId,
      name: name ?? this.name,
      number: number ?? this.number,
      stateId: stateId ?? this.stateId,
      population_total: population_total ?? this.population_total,
      sc_population: sc_population ?? this.sc_population,
      st_population: st_population ?? this.st_population,
      areas: areas ?? this.areas,
      assembly_constituency: assembly_constituency ?? this.assembly_constituency,
      parliamentary_constituency: parliamentary_constituency ?? this.parliamentary_constituency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

