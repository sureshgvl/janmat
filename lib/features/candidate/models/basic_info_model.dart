import 'package:equatable/equatable.dart';

class BasicInfoModel extends Equatable {
  final String? fullName;
  final DateTime? dateOfBirth;
  final int? age;
  final String? gender;
  final String? education;
  final String? profession;
  final List<String>? languages;
  final int? experienceYears;
  final List<String>? previousPositions;
  final String? photo;

  const BasicInfoModel({
    this.fullName,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.education,
    this.profession,
    this.languages,
    this.experienceYears,
    this.previousPositions,
    this.photo,
  });

  factory BasicInfoModel.fromJson(Map<String, dynamic> json) {
    return BasicInfoModel(
      fullName: json['fullName'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      education: json['education'] as String?,
      profession: json['profession'] as String?,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      experienceYears: json['experienceYears'] as int?,
      previousPositions: json['previousPositions'] != null
          ? List<String>.from(json['previousPositions'])
          : null,
      photo: json['photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (education != null) 'education': education,
      if (profession != null) 'profession': profession,
      if (languages != null) 'languages': languages,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (previousPositions != null) 'previousPositions': previousPositions,
      if (photo != null) 'photo': photo,
    };
  }

  BasicInfoModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    int? age,
    String? gender,
    String? education,
    String? profession,
    List<String>? languages,
    int? experienceYears,
    List<String>? previousPositions,
    String? photo,
  }) {
    return BasicInfoModel(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      education: education ?? this.education,
      profession: profession ?? this.profession,
      languages: languages ?? this.languages,
      experienceYears: experienceYears ?? this.experienceYears,
      previousPositions: previousPositions ?? this.previousPositions,
      photo: photo ?? this.photo,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        dateOfBirth,
        age,
        gender,
        education,
        profession,
        languages,
        experienceYears,
        previousPositions,
        photo,
      ];

  factory BasicInfoModel.empty() {
    return const BasicInfoModel();
  }
}
