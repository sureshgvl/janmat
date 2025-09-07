class City {
  final String cityId;
  final String name;
  final String state;
  final int population;
  final List<String> wardIds;

  City({
    required this.cityId,
    required this.name,
    required this.state,
    required this.population,
    required this.wardIds,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['cityId'] ?? '',
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      population: json['population'] ?? 0,
      wardIds: List<String>.from(json['wardIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityId': cityId,
      'name': name,
      'state': state,
      'population': population,
      'wardIds': wardIds,
    };
  }
}