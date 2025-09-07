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
  final DateTime createdAt;
  final String? photoURL;

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
    required this.createdAt,
    this.photoURL,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      photoURL: json['photoURL'],
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
      'createdAt': createdAt.toIso8601String(),
      'photoURL': photoURL,
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
    DateTime? createdAt,
    String? photoURL,
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
      createdAt: createdAt ?? this.createdAt,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}