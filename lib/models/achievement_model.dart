class Achievement {
  final String title;
  final String description;
  final int year;
  final String? photoUrl;

  Achievement({
    required this.title,
    required this.description,
    required this.year,
    this.photoUrl,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'year': year,
      'photoUrl': photoUrl,
    };
  }

  Achievement copyWith({
    String? title,
    String? description,
    int? year,
    String? photoUrl,
  }) {
    return Achievement(
      title: title ?? this.title,
      description: description ?? this.description,
      year: year ?? this.year,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  String toString() {
    return '$title: $description (${year.toString()})';
  }
}