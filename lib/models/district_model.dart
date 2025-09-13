class District {
  final String districtId;
  final String name;

  District({
    required this.districtId,
    required this.name,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtId: json['districtId'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'districtId': districtId,
      'name': name,
    };
  }

  District copyWith({
    String? districtId,
    String? name,
  }) {
    return District(
      districtId: districtId ?? this.districtId,
      name: name ?? this.name,
    );
  }

  @override
  String toString() {
    return 'District(districtId: $districtId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District &&
        other.districtId == districtId &&
        other.name == name;
  }

  @override
  int get hashCode => districtId.hashCode ^ name.hashCode;
}
