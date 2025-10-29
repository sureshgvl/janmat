import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/features/candidate/models/location_model.dart';


enum ElectionType {
  regular,
  zp,
  ps,
}

class ElectionArea {
  final String bodyId;
  final String wardId;
  final String? area;
  final ElectionType type;

  const ElectionArea({
    required this.bodyId,
    required this.wardId,
    this.area,
    required this.type,
  });

  factory ElectionArea.fromJson(Map<String, dynamic> json) {
    return ElectionArea(
      bodyId: json['bodyId'] ?? '',
      wardId: json['wardId'] ?? '',
      area: json['area'],
      type: ElectionType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'regular'),
        orElse: () => ElectionType.regular,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyId': bodyId,
      'wardId': wardId,
      'area': area,
      'type': type.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ElectionArea &&
        other.bodyId == bodyId &&
        other.wardId == wardId &&
        other.area == area &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(bodyId, wardId, area, type);
}

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool roleSelected;
  final bool profileCompleted;
  final LocationModel? location;
  final List<ElectionArea> electionAreas;

  // Backward compatibility getters
  String? get stateId => location?.stateId;
  String? get districtId => location?.districtId;
  String? get bodyId => location?.bodyId;
  String? get wardId => location?.wardId;

  String? get area {
    if (electionAreas.isNotEmpty) {
      return electionAreas.first.area;
    }
    return null;
  }

  String? get zpBodyId {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.zp).bodyId;
    } catch (e) {
      return null;
    }
  }

  String? get zpWardId {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.zp).wardId;
    } catch (e) {
      return null;
    }
  }

  String? get zpArea {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.zp).area;
    } catch (e) {
      return null;
    }
  }

  String? get psBodyId {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.ps).bodyId;
    } catch (e) {
      return null;
    }
  }

  String? get psWardId {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.ps).wardId;
    } catch (e) {
      return null;
    }
  }

  String? get psArea {
    try {
      return electionAreas.firstWhere((area) => area.type == ElectionType.ps).area;
    } catch (e) {
      return null;
    }
  }
  final int xpPoints;
  final bool premium;
  final String? subscriptionPlanId; // current active candidate subscription
  final DateTime? subscriptionExpiresAt;
  // Highlight plan fields
  final String? highlightPlanId; // active highlight plan subscription
  final DateTime? highlightPlanExpiresAt;
  final int highlightSlotsUsed; // usage tracking for highlight slots
  // Carousel plan fields
  final String? carouselPlanId; // active carousel plan subscription
  final DateTime? carouselPlanExpiresAt;
  final int carouselSlotsUsed; // usage tracking for carousel slots
  final DateTime createdAt;
  // Trial fields for candidates
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final bool isTrialActive;
  final bool hasConvertedFromTrial;
  final String? photoURL;
  final int followingCount;

  // Getter to get primary ward ID (for backward compatibility)
  String get primaryWardId {
    if (electionAreas.isNotEmpty) {
      return electionAreas.first.wardId;
    }
    return ''; // fallback
  }

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.roleSelected,
    required this.profileCompleted,
    this.location,
    this.electionAreas = const [],
    required this.xpPoints,
    required this.premium,
    this.subscriptionPlanId,
    this.subscriptionExpiresAt,
    // Highlight plan fields
    this.highlightPlanId,
    this.highlightPlanExpiresAt,
    this.highlightSlotsUsed = 0,
    // Carousel plan fields
    this.carouselPlanId,
    this.carouselPlanExpiresAt,
    this.carouselSlotsUsed = 0,
    required this.createdAt,
    this.photoURL,
    this.followingCount = 0,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.isTrialActive = false,
    this.hasConvertedFromTrial = false,
    // Deprecated fields for backward compatibility
    @Deprecated('Use location.districtId instead') String? districtId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? subscriptionExpiresAt;
    if (json['subscriptionExpiresAt'] is Timestamp) {
      subscriptionExpiresAt = (json['subscriptionExpiresAt'] as Timestamp)
          .toDate();
    } else if (json['subscriptionExpiresAt'] is String) {
      subscriptionExpiresAt = DateTime.parse(json['subscriptionExpiresAt']);
    }

    // Parse highlight plan dates
    DateTime? highlightPlanExpiresAt;
    if (json['highlightPlanExpiresAt'] is Timestamp) {
      highlightPlanExpiresAt = (json['highlightPlanExpiresAt'] as Timestamp).toDate();
    } else if (json['highlightPlanExpiresAt'] is String) {
      highlightPlanExpiresAt = DateTime.parse(json['highlightPlanExpiresAt']);
    }

    // Parse carousel plan dates
    DateTime? carouselPlanExpiresAt;
    if (json['carouselPlanExpiresAt'] is Timestamp) {
      carouselPlanExpiresAt = (json['carouselPlanExpiresAt'] as Timestamp).toDate();
    } else if (json['carouselPlanExpiresAt'] is String) {
      carouselPlanExpiresAt = DateTime.parse(json['carouselPlanExpiresAt']);
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

    // Handle migration from old structure to new structure
    List<ElectionArea> areas = [];

    if (json.containsKey('electionAreas') && json['electionAreas'] != null) {
      // New structure
      areas = (json['electionAreas'] as List<dynamic>?)
          ?.map((e) => ElectionArea.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
    } else {
      // Migrate from old structure
      areas = _migrateFromOldStructure(json);
    }

    // CRITICAL SAFETY CHECK: A user document should NEVER be without a role
    // If role is missing, this indicates a data corruption issue
    if (!json.containsKey('role') || json['role'] == null || json['role'].toString().trim().isEmpty) {
      // Log the critical data integrity issue - this should never happen for valid users
      print('🚨 CRITICAL DATA CORRUPTION: User document ${json['uid']} is missing role field! This indicates background operations are corrupting user data.');
      // Default to empty string to force role re-selection rather than assume 'voter'
    }

    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: json['role'] ?? '',
      roleSelected: json['roleSelected'] ?? false,
      profileCompleted: json['profileCompleted'] ?? false,
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : LocationModel(
              stateId: json['stateId'],
              districtId: json['districtId'],
              bodyId: json['bodyId'],
              wardId: json['wardId'],
            ),
      electionAreas: areas,
      xpPoints: json['xpPoints'] ?? 0,
      premium: json['premium'] ?? false,
      subscriptionPlanId: json['subscriptionPlanId'],
      subscriptionExpiresAt: subscriptionExpiresAt,
      // Highlight plan fields
      highlightPlanId: json['highlightPlanId'],
      highlightPlanExpiresAt: highlightPlanExpiresAt,
      highlightSlotsUsed: json['highlightSlotsUsed'] ?? 0,
      // Carousel plan fields
      carouselPlanId: json['carouselPlanId'],
      carouselPlanExpiresAt: carouselPlanExpiresAt,
      carouselSlotsUsed: json['carouselSlotsUsed'] ?? 0,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      photoURL: json['photoURL'],
      followingCount: json['followingCount']?.toInt() ?? 0,
      trialStartedAt: trialStartedAt,
      trialExpiresAt: trialExpiresAt,
      isTrialActive: json['isTrialActive'] ?? false,
      hasConvertedFromTrial: json['hasConvertedFromTrial'] ?? false,
    );
  }

  // Helper method to migrate from old structure
  static List<ElectionArea> _migrateFromOldStructure(Map<String, dynamic> json) {
    List<ElectionArea> areas = [];

    // Migrate regular election area
    if (json.containsKey('bodyId') && json['bodyId'] != null && json['bodyId'].toString().isNotEmpty) {
      areas.add(ElectionArea(
        bodyId: json['bodyId'],
        wardId: json['wardId'] ?? '',
        area: json['area'],
        type: ElectionType.regular,
      ));
    }

    // Migrate ZP election area
    if (json.containsKey('zpBodyId') && json['zpBodyId'] != null && json['zpBodyId'].toString().isNotEmpty) {
      areas.add(ElectionArea(
        bodyId: json['zpBodyId'],
        wardId: json['zpWardId'] ?? '',
        area: json['zpArea'],
        type: ElectionType.zp,
      ));
    }

    // Migrate PS election area
    if (json.containsKey('psBodyId') && json['psBodyId'] != null && json['psBodyId'].toString().isNotEmpty) {
      areas.add(ElectionArea(
        bodyId: json['psBodyId'],
        wardId: json['psWardId'] ?? '',
        area: json['psArea'],
        type: ElectionType.ps,
      ));
    }

    return areas;
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
      'location': location?.toJson(),
      'electionAreas': electionAreas.map((e) => e.toJson()).toList(),
      'xpPoints': xpPoints,
      'premium': premium,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      // Highlight plan fields
      'highlightPlanId': highlightPlanId,
      'highlightPlanExpiresAt': highlightPlanExpiresAt?.toIso8601String(),
      'highlightSlotsUsed': highlightSlotsUsed,
      // Carousel plan fields
      'carouselPlanId': carouselPlanId,
      'carouselPlanExpiresAt': carouselPlanExpiresAt?.toIso8601String(),
      'carouselSlotsUsed': carouselSlotsUsed,
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
    LocationModel? location,
    List<ElectionArea>? electionAreas,
    int? xpPoints,
    bool? premium,
    String? subscriptionPlanId,
    DateTime? subscriptionExpiresAt,
    // Highlight plan fields
    String? highlightPlanId,
    DateTime? highlightPlanExpiresAt,
    int? highlightSlotsUsed,
    // Carousel plan fields
    String? carouselPlanId,
    DateTime? carouselPlanExpiresAt,
    int? carouselSlotsUsed,
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
      location: location ?? this.location,
      electionAreas: electionAreas ?? this.electionAreas,
      xpPoints: xpPoints ?? this.xpPoints,
      premium: premium ?? this.premium,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      // Highlight plan fields
      highlightPlanId: highlightPlanId ?? this.highlightPlanId,
      highlightPlanExpiresAt: highlightPlanExpiresAt ?? this.highlightPlanExpiresAt,
      highlightSlotsUsed: highlightSlotsUsed ?? this.highlightSlotsUsed,
      // Carousel plan fields
      carouselPlanId: carouselPlanId ?? this.carouselPlanId,
      carouselPlanExpiresAt: carouselPlanExpiresAt ?? this.carouselPlanExpiresAt,
      carouselSlotsUsed: carouselSlotsUsed ?? this.carouselSlotsUsed,
      createdAt: createdAt ?? this.createdAt,
      photoURL: photoURL ?? this.photoURL,
      followingCount: followingCount ?? this.followingCount,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      hasConvertedFromTrial:
          hasConvertedFromTrial ?? this.hasConvertedFromTrial,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      // Handle milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }
}
