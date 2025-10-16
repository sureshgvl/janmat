import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictSpotlight {
  final String? id;
  final String? partyId; // Now optional
  final String fullImage; // Changed from imageUrl
  final String? bannerImage; // New optional field for chat rooms
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? version; // New version field for cache invalidation

  DistrictSpotlight({
    this.id,
    this.partyId, // Now optional
    required this.fullImage, // Changed from imageUrl
    this.bannerImage, // New optional field
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.version, // New version field
  });

  factory DistrictSpotlight.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    }

    DateTime? updatedAt;
    if (json['updatedAt'] is Timestamp) {
      updatedAt = (json['updatedAt'] as Timestamp).toDate();
    } else if (json['updatedAt'] is String) {
      updatedAt = DateTime.parse(json['updatedAt']);
    }

    return DistrictSpotlight(
      id: json['id'],
      partyId: json['partyId']?.toString(), // Convert to string if it's an int
      fullImage: json['fullImage'] ?? '', // Changed from imageUrl
      bannerImage: json['bannerImage'], // New optional field
      isActive: json['isActive'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: json['version']?.toString(), // Convert version to string if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partyId': partyId, // Now optional
      'fullImage': fullImage, // Changed from imageUrl
      'bannerImage': bannerImage, // New optional field
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version, // New version field
    };
  }

  DistrictSpotlight copyWith({
    String? id,
    String? partyId,
    String? fullImage, // Changed from imageUrl
    String? bannerImage, // New optional field
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? version, // New version field
  }) {
    return DistrictSpotlight(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      fullImage: fullImage ?? this.fullImage, // Changed from imageUrl
      bannerImage: bannerImage ?? this.bannerImage, // New optional field
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version, // New version field
    );
  }
}