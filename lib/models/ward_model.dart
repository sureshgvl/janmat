class Ward {
  final String wardId;
  final String cityId;
  final String name;
  final List<String> areas;
  final int seats;

  Ward({
    required this.wardId,
    required this.cityId,
    required this.name,
    required this.areas,
    required this.seats,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      wardId: json['wardId'] ?? '',
      cityId: json['cityId'] ?? '',
      name: json['wardName'] ?? json['name'] ?? '',
      areas: List<String>.from(json['areas'] ?? []),
      seats: json['seats'] ?? 1, // Default to 1 seat
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wardId': wardId,
      'cityId': cityId,
      'name': name,
      'areas': areas,
      'seats': seats,
    };
  }
}