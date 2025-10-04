import 'package:cloud_firestore/cloud_firestore.dart';

class State {
  final String id;
  final String name;
  final String? marathiName;
  final String? code;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  State({
    required this.id,
    required this.name,
    this.marathiName,
    this.code,
    this.isActive,
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
      id: json['id'] ?? json['stateId'] ?? '',
      name: json['name'] ?? '',
      marathiName: json['marathiName'],
      code: json['code'],
      isActive: json['isActive'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'marathiName': marathiName,
      'code': code,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  State copyWith({
    String? id,
    String? name,
    String? marathiName,
    String? code,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return State(
      id: id ?? this.id,
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
    return 'State(id: $id, name: $name, marathiName: $marathiName, code: $code, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is State &&
        other.id == id &&
        other.name == name &&
        other.marathiName == marathiName &&
        other.code == code &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ marathiName.hashCode ^ code.hashCode ^ isActive.hashCode;
}

