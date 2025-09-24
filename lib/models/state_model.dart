import 'package:cloud_firestore/cloud_firestore.dart';

class State {
  final String stateId;
  final String name;
  final String? marathiName;
  final String? code;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  State({
    required this.stateId,
    required this.name,
    this.marathiName,
    this.code,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    DateTime? updatedAt;

    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        createdAt = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    }

    if (json['updatedAt'] != null) {
      if (json['updatedAt'] is Timestamp) {
        updatedAt = (json['updatedAt'] as Timestamp).toDate();
      } else if (json['updatedAt'] is String) {
        updatedAt = DateTime.parse(json['updatedAt']);
      }
    }

    return State(
      stateId: json['stateId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      marathiName: json['marathiName'],
      code: json['code'],
      isActive: json['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stateId': stateId,
      'name': name,
      'marathiName': marathiName,
      'code': code,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  State copyWith({
    String? stateId,
    String? name,
    String? marathiName,
    String? code,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return State(
      stateId: stateId ?? this.stateId,
      name: name ?? this.name,
      marathiName: marathiName ?? this.marathiName,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'State(stateId: $stateId, name: $name, marathiName: $marathiName, code: $code, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is State &&
        other.stateId == stateId &&
        other.name == name &&
        other.marathiName == marathiName &&
        other.code == code &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      stateId.hashCode ^ name.hashCode ^ marathiName.hashCode ^ code.hashCode ^ isActive.hashCode;
}