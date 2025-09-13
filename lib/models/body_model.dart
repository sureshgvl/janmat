class Body {
  final String bodyId;
  final String districtId;
  final String name;
  final String type;
  final int wardCount;
  final Map<String, String>? areaToWard;
  final Map<String, dynamic>? source;
  final Map<String, dynamic>? special;

  Body({
    required this.bodyId,
    required this.districtId,
    required this.name,
    required this.type,
    required this.wardCount,
    this.areaToWard,
    this.source,
    this.special,
  });

  factory Body.fromJson(Map<String, dynamic> json) {
    return Body(
      bodyId: json['bodyId'] ?? json['id'] ?? '',
      districtId: json['districtId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Municipal Corporation',
      wardCount: json['ward_count'] ?? json['wardCount'] ?? 0,
      areaToWard: json['area_to_ward'] != null
          ? Map<String, String>.from(json['area_to_ward'])
          : null,
      source: json['source'] != null
          ? Map<String, dynamic>.from(json['source'])
          : null,
      special: json['special'] != null
          ? Map<String, dynamic>.from(json['special'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyId': bodyId,
      'districtId': districtId,
      'name': name,
      'type': type,
      'ward_count': wardCount,
      'area_to_ward': areaToWard,
      'source': source,
      'special': special,
    };
  }

  Body copyWith({
    String? bodyId,
    String? districtId,
    String? name,
    String? type,
    int? wardCount,
    Map<String, String>? areaToWard,
    Map<String, dynamic>? source,
    Map<String, dynamic>? special,
  }) {
    return Body(
      bodyId: bodyId ?? this.bodyId,
      districtId: districtId ?? this.districtId,
      name: name ?? this.name,
      type: type ?? this.type,
      wardCount: wardCount ?? this.wardCount,
      areaToWard: areaToWard ?? this.areaToWard,
      source: source ?? this.source,
      special: special ?? this.special,
    );
  }

  @override
  String toString() {
    return 'Body(bodyId: $bodyId, districtId: $districtId, name: $name, type: $type, wardCount: $wardCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Body &&
        other.bodyId == bodyId &&
        other.districtId == districtId &&
        other.name == name &&
        other.type == type &&
        other.wardCount == wardCount;
  }

  @override
  int get hashCode =>
      bodyId.hashCode ^
      districtId.hashCode ^
      name.hashCode ^
      type.hashCode ^
      wardCount.hashCode;
}
