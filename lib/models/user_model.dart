import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final String wardId;
  final String cityId;
  final int xpPoints;
  final bool premium;
  final String? subscriptionPlanId; // current active subscription
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;
  final String? photoURL;
  final int followingCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.wardId,
    required this.cityId,
    required this.xpPoints,
    required this.premium,
    this.subscriptionPlanId,
    this.subscriptionExpiresAt,
    required this.createdAt,
    this.photoURL,
    this.followingCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? subscriptionExpiresAt;
    if (json['subscriptionExpiresAt'] is Timestamp) {
      subscriptionExpiresAt = (json['subscriptionExpiresAt'] as Timestamp).toDate();
    } else if (json['subscriptionExpiresAt'] is String) {
      subscriptionExpiresAt = DateTime.parse(json['subscriptionExpiresAt']);
    }

    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'voter',
      wardId: json['wardId'] ?? '',
      cityId: json['cityId'] ?? '',
      xpPoints: json['xpPoints'] ?? 0,
      premium: json['premium'] ?? false,
      subscriptionPlanId: json['subscriptionPlanId'],
      subscriptionExpiresAt: subscriptionExpiresAt,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      photoURL: json['photoURL'],
      followingCount: json['followingCount']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'wardId': wardId,
      'cityId': cityId,
      'xpPoints': xpPoints,
      'premium': premium,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'photoURL': photoURL,
      'followingCount': followingCount,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? wardId,
    String? cityId,
    int? xpPoints,
    bool? premium,
    String? subscriptionPlanId,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
    String? photoURL,
    int? followingCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      wardId: wardId ?? this.wardId,
      cityId: cityId ?? this.cityId,
      xpPoints: xpPoints ?? this.xpPoints,
      premium: premium ?? this.premium,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      photoURL: photoURL ?? this.photoURL,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}