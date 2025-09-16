import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool roleSelected;
  final bool profileCompleted;
  final String wardId;
  final String? districtId;
  final String? bodyId;
  final String? area;
  final int xpPoints;
  final bool premium;
  final String? subscriptionPlanId; // current active subscription
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;
  // Trial fields for candidates
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final bool isTrialActive;
  final bool hasConvertedFromTrial;
  final String? photoURL;
  final int followingCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.roleSelected,
    required this.profileCompleted,
    required this.wardId,
    this.districtId,
    this.bodyId,
    this.area,
    required this.xpPoints,
    required this.premium,
    this.subscriptionPlanId,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.photoURL,
    this.followingCount = 0,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.isTrialActive = false,
    this.hasConvertedFromTrial = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? subscriptionExpiresAt;
    if (json['subscriptionExpiresAt'] is Timestamp) {
      subscriptionExpiresAt = (json['subscriptionExpiresAt'] as Timestamp).toDate();
    } else if (json['subscriptionExpiresAt'] is String) {
      subscriptionExpiresAt = DateTime.parse(json['subscriptionExpiresAt']);
    }

    // Parse trial dates
    DateTime? trialStartedAt;
    DateTime? trialExpiresAt;
    if (json['trialStartedAt'] != null) {
      if (json['trialStartedAt'] is Timestamp) {
        trialStartedAt = (json['trialStartedAt'] as Timestamp).toDate();
      } else if (json['trialStartedAt'] is String) {
        trialStartedAt = DateTime.parse(json['trialStartedAt']);
      }
    }
    if (json['trialExpiresAt'] != null) {
      if (json['trialExpiresAt'] is Timestamp) {
        trialExpiresAt = (json['trialExpiresAt'] as Timestamp).toDate();
      } else if (json['trialExpiresAt'] is String) {
        trialExpiresAt = DateTime.parse(json['trialExpiresAt']);
      }
    }

    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'voter',
      roleSelected: json['roleSelected'] ?? false,
      profileCompleted: json['profileCompleted'] ?? false,
      wardId: json['wardId'] ?? '',
      districtId: json['districtId'],
      bodyId: json['bodyId'],
      area: json['area'],
      xpPoints: json['xpPoints'] ?? 0,
      premium: json['premium'] ?? false,
      subscriptionPlanId: json['subscriptionPlanId'],
      subscriptionExpiresAt: subscriptionExpiresAt,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      photoURL: json['photoURL'],
      followingCount: json['followingCount']?.toInt() ?? 0,
      trialStartedAt: trialStartedAt,
      trialExpiresAt: trialExpiresAt,
      isTrialActive: json['isTrialActive'] ?? false,
      hasConvertedFromTrial: json['hasConvertedFromTrial'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'roleSelected': roleSelected,
      'profileCompleted': profileCompleted,
      'wardId': wardId,
      'districtId': districtId,
      'bodyId': bodyId,
      'area': area,
      'xpPoints': xpPoints,
      'premium': premium,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'photoURL': photoURL,
      'followingCount': followingCount,
      'trialStartedAt': trialStartedAt?.toIso8601String(),
      'trialExpiresAt': trialExpiresAt?.toIso8601String(),
      'isTrialActive': isTrialActive,
      'hasConvertedFromTrial': hasConvertedFromTrial,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? role,
    bool? roleSelected,
    bool? profileCompleted,
    String? wardId,
    String? districtId,
    String? bodyId,
    String? area,
    int? xpPoints,
    bool? premium,
    String? subscriptionPlanId,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
    String? photoURL,
    int? followingCount,
    DateTime? trialStartedAt,
    DateTime? trialExpiresAt,
    bool? isTrialActive,
    bool? hasConvertedFromTrial,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      roleSelected: roleSelected ?? this.roleSelected,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      wardId: wardId ?? this.wardId,
      districtId: districtId ?? this.districtId,
      bodyId: bodyId ?? this.bodyId,
      area: area ?? this.area,
      xpPoints: xpPoints ?? this.xpPoints,
      premium: premium ?? this.premium,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      photoURL: photoURL ?? this.photoURL,
      followingCount: followingCount ?? this.followingCount,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      hasConvertedFromTrial: hasConvertedFromTrial ?? this.hasConvertedFromTrial,
    );
  }
}
