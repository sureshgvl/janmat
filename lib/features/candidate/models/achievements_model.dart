import 'package:equatable/equatable.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String? photoUrl;
  final DateTime? date;
  final String? category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.photoUrl,
    this.date,
    this.category,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (date != null) 'date': date!.toIso8601String(),
      if (category != null) 'category': category,
    };
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? photoUrl,
    DateTime? date,
    String? category,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      date: date ?? this.date,
      category: category ?? this.category,
    );
  }

  // Getter for backward compatibility
  String? get year => date?.year.toString();
}

class AchievementsModel extends Equatable {
  final List<Achievement>? achievements;

  const AchievementsModel({
    this.achievements,
  });

  factory AchievementsModel.fromJson(Map<String, dynamic> json) {
    return AchievementsModel(
      achievements: json['achievements'] != null
          ? (json['achievements'] as List<dynamic>)
              .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (achievements != null)
        'achievements': achievements!.map((a) => a.toJson()).toList(),
    };
  }

  AchievementsModel copyWith({
    List<Achievement>? achievements,
  }) {
    return AchievementsModel(
      achievements: achievements ?? this.achievements,
    );
  }

  // Getters for backward compatibility
  int get length => achievements?.length ?? 0;
  bool get isNotEmpty => achievements?.isNotEmpty ?? false;
  bool get isEmpty => achievements?.isEmpty ?? true;
  Achievement? operator [](int index) => achievements?[index];

  // Add setter for index assignment
  void operator []=(int index, Achievement value) {
    if (achievements != null && index >= 0 && index < achievements!.length) {
      achievements![index] = value;
    }
  }

  @override
  List<Object?> get props => [achievements];
}
