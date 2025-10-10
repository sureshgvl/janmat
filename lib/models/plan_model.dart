import 'package:cloud_firestore/cloud_firestore.dart';

// Dashboard Tab Features
class BasicInfoTab {
  final bool enabled;
  final List<String> permissions;

  BasicInfoTab({
    required this.enabled,
    required this.permissions,
  });

  factory BasicInfoTab.fromJson(Map<String, dynamic> json) {
    return BasicInfoTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
    };
  }
}

class ManifestoTab {
  final bool enabled;
  final List<String> permissions;
  final ManifestoFeatures features;

  ManifestoTab({
    required this.enabled,
    required this.permissions,
    required this.features,
  });

  factory ManifestoTab.fromJson(Map<String, dynamic> json) {
    return ManifestoTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      features: ManifestoFeatures.fromJson(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'features': features.toJson(),
    };
  }
}

class ManifestoFeatures {
  final bool textOnly;
  final bool pdfUpload;
  final bool videoUpload;
  final bool promises;
  final int maxPromises;
  final bool? multipleVersions;

  ManifestoFeatures({
    required this.textOnly,
    required this.pdfUpload,
    required this.videoUpload,
    required this.promises,
    required this.maxPromises,
    this.multipleVersions,
  });

  factory ManifestoFeatures.fromJson(Map<String, dynamic> json) {
    return ManifestoFeatures(
      textOnly: json['textOnly'] ?? false,
      pdfUpload: json['pdfUpload'] ?? false,
      videoUpload: json['videoUpload'] ?? false,
      promises: json['promises'] ?? false,
      maxPromises: json['maxPromises'] ?? 0,
      multipleVersions: json['multipleVersions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'textOnly': textOnly,
      'pdfUpload': pdfUpload,
      'videoUpload': videoUpload,
      'promises': promises,
      'maxPromises': maxPromises,
      'multipleVersions': multipleVersions,
    };
  }
}

class AchievementsTab {
  final bool enabled;
  final List<String> permissions;
  final int maxAchievements;

  AchievementsTab({
    required this.enabled,
    required this.permissions,
    required this.maxAchievements,
  });

  factory AchievementsTab.fromJson(Map<String, dynamic> json) {
    return AchievementsTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      maxAchievements: json['maxAchievements'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'maxAchievements': maxAchievements,
    };
  }
}

class MediaTab {
  final bool enabled;
  final List<String> permissions;
  final int maxMediaItems;
  final int maxImagesPerItem;
  final int maxVideosPerItem;
  final int maxYouTubeLinksPerItem;

  MediaTab({
    required this.enabled,
    required this.permissions,
    required this.maxMediaItems,
    required this.maxImagesPerItem,
    required this.maxVideosPerItem,
    required this.maxYouTubeLinksPerItem,
  });

  factory MediaTab.fromJson(Map<String, dynamic> json) {
    return MediaTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      maxMediaItems: json['maxMediaItems'] ?? 0,
      maxImagesPerItem: json['maxImagesPerItem'] ?? 0,
      maxVideosPerItem: json['maxVideosPerItem'] ?? 0,
      maxYouTubeLinksPerItem: json['maxYouTubeLinksPerItem'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'maxMediaItems': maxMediaItems,
      'maxImagesPerItem': maxImagesPerItem,
      'maxVideosPerItem': maxVideosPerItem,
      'maxYouTubeLinksPerItem': maxYouTubeLinksPerItem,
    };
  }
}

class ContactTab {
  final bool enabled;
  final List<String> permissions;
  final ContactFeatures features;

  ContactTab({
    required this.enabled,
    required this.permissions,
    required this.features,
  });

  factory ContactTab.fromJson(Map<String, dynamic> json) {
    return ContactTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      features: ContactFeatures.fromJson(json['features'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'features': features.toJson(),
    };
  }
}

class ContactFeatures {
  final bool basic;
  final bool extended;
  final bool socialLinks;
  final bool? prioritySupport;

  ContactFeatures({
    required this.basic,
    required this.extended,
    required this.socialLinks,
    this.prioritySupport,
  });

  factory ContactFeatures.fromJson(Map<String, dynamic> json) {
    return ContactFeatures(
      basic: json['basic'] ?? false,
      extended: json['extended'] ?? false,
      socialLinks: json['socialLinks'] ?? false,
      prioritySupport: json['prioritySupport'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basic': basic,
      'extended': extended,
      'socialLinks': socialLinks,
      'prioritySupport': prioritySupport,
    };
  }
}

class EventsTab {
  final bool enabled;
  final List<String> permissions;
  final int maxEvents;

  EventsTab({
    required this.enabled,
    required this.permissions,
    required this.maxEvents,
  });

  factory EventsTab.fromJson(Map<String, dynamic> json) {
    return EventsTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      maxEvents: json['maxEvents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'maxEvents': maxEvents,
    };
  }
}

class AnalyticsTab {
  final bool enabled;
  final List<String> permissions;
  final AnalyticsFeatures? features;

  AnalyticsTab({
    required this.enabled,
    required this.permissions,
    this.features,
  });

  factory AnalyticsTab.fromJson(Map<String, dynamic> json) {
    return AnalyticsTab(
      enabled: json['enabled'] ?? false,
      permissions: List<String>.from(json['permissions'] ?? []),
      features: json['features'] != null ? AnalyticsFeatures.fromJson(json['features']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'permissions': permissions,
      'features': features?.toJson(),
    };
  }
}

class AnalyticsFeatures {
  final bool basic;
  final bool advanced;
  final bool? fullDashboard;
  final bool? realTime;

  AnalyticsFeatures({
    required this.basic,
    required this.advanced,
    this.fullDashboard,
    this.realTime,
  });

  factory AnalyticsFeatures.fromJson(Map<String, dynamic> json) {
    return AnalyticsFeatures(
      basic: json['basic'] ?? false,
      advanced: json['advanced'] ?? false,
      fullDashboard: json['fullDashboard'],
      realTime: json['realTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basic': basic,
      'advanced': advanced,
      'fullDashboard': fullDashboard,
      'realTime': realTime,
    };
  }
}

class DashboardTabs {
  final BasicInfoTab basicInfo;
  final ManifestoTab manifesto;
  final AchievementsTab achievements;
  final MediaTab media;
  final ContactTab contact;
  final EventsTab events;
  final AnalyticsTab analytics;

  DashboardTabs({
    required this.basicInfo,
    required this.manifesto,
    required this.achievements,
    required this.media,
    required this.contact,
    required this.events,
    required this.analytics,
  });

  factory DashboardTabs.fromJson(Map<String, dynamic> json) {
    return DashboardTabs(
      basicInfo: BasicInfoTab.fromJson(json['basicInfo'] ?? {}),
      manifesto: ManifestoTab.fromJson(json['manifesto'] ?? {}),
      achievements: AchievementsTab.fromJson(json['achievements'] ?? {}),
      media: MediaTab.fromJson(json['media'] ?? {}),
      contact: ContactTab.fromJson(json['contact'] ?? {}),
      events: EventsTab.fromJson(json['events'] ?? {}),
      analytics: AnalyticsTab.fromJson(json['analytics'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basicInfo': basicInfo.toJson(),
      'manifesto': manifesto.toJson(),
      'achievements': achievements.toJson(),
      'media': media.toJson(),
      'contact': contact.toJson(),
      'events': events.toJson(),
      'analytics': analytics.toJson(),
    };
  }
}

class ProfileFeatures {
  final bool premiumBadge;
  final bool sponsoredBanner;
  final bool highlightCarousel;
  final bool pushNotifications;
  final bool? multipleHighlights;
  final bool? adminSupport;
  final bool? customBranding;

  ProfileFeatures({
    required this.premiumBadge,
    required this.sponsoredBanner,
    required this.highlightCarousel,
    required this.pushNotifications,
    this.multipleHighlights,
    this.adminSupport,
    this.customBranding,
  });

  factory ProfileFeatures.fromJson(Map<String, dynamic> json) {
    return ProfileFeatures(
      premiumBadge: json['premiumBadge'] ?? false,
      sponsoredBanner: json['sponsoredBanner'] ?? false,
      highlightCarousel: json['highlightCarousel'] ?? false,
      pushNotifications: json['pushNotifications'] ?? false,
      multipleHighlights: json['multipleHighlights'],
      adminSupport: json['adminSupport'],
      customBranding: json['customBranding'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'premiumBadge': premiumBadge,
      'sponsoredBanner': sponsoredBanner,
      'highlightCarousel': highlightCarousel,
      'pushNotifications': pushNotifications,
      'multipleHighlights': multipleHighlights,
      'adminSupport': adminSupport,
      'customBranding': customBranding,
    };
  }
}

// Carousel-specific features
class CarouselFeatures {
  final int maxCarouselSlots;
  final String priority; // 'normal', 'high', 'urgent', 'exclusive'
  final bool autoRotation;
  final bool customTiming;
  final bool analyticsAccess;

  CarouselFeatures({
    required this.maxCarouselSlots,
    required this.priority,
    required this.autoRotation,
    required this.customTiming,
    required this.analyticsAccess,
  });

  factory CarouselFeatures.fromJson(Map<String, dynamic> json) {
    return CarouselFeatures(
      maxCarouselSlots: json['maxCarouselSlots'] ?? 6,
      priority: json['priority'] ?? 'normal',
      autoRotation: json['autoRotation'] ?? false,
      customTiming: json['customTiming'] ?? false,
      analyticsAccess: json['analyticsAccess'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxCarouselSlots': maxCarouselSlots,
      'priority': priority,
      'autoRotation': autoRotation,
      'customTiming': customTiming,
      'analyticsAccess': analyticsAccess,
    };
  }
}

// Highlight-specific features
class HighlightFeatures {
  final int maxHighlights;
  final String priority; // 'normal', 'high', 'urgent'

  HighlightFeatures({
    required this.maxHighlights,
    required this.priority,
  });

  factory HighlightFeatures.fromJson(Map<String, dynamic> json) {
    return HighlightFeatures(
      maxHighlights: json['maxHighlights'] ?? 4,
      priority: json['priority'] ?? 'normal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxHighlights': maxHighlights,
      'priority': priority,
    };
  }
}

class SubscriptionPlan {
  final String id;
  final String planId;
  final String name;
  final String type; // 'candidate', 'highlight', or 'carousel'
  final Map<String, Map<int, int>> pricing; // electionType -> validityDays -> price
  final bool isActive;
  final DashboardTabs? dashboardTabs; // Only for candidate plans
  final ProfileFeatures profileFeatures;
  final HighlightFeatures? highlightFeatures; // Only for highlight plans
  final CarouselFeatures? carouselFeatures; // For highlight and carousel plans
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.planId,
    required this.name,
    required this.type,
    required this.pricing,
    required this.isActive,
    this.dashboardTabs, // Optional for highlight plans
    required this.profileFeatures,
    this.highlightFeatures, // Optional for candidate plans
    this.carouselFeatures, // Optional for candidate plans, required for highlight/carousel plans
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
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

    // Handle pricing structure - convert from Firestore format
    Map<String, Map<int, int>> pricing = {};
    if (json['pricing'] != null) {
      final pricingJson = json['pricing'] as Map<String, dynamic>;
      pricingJson.forEach((electionType, validityMap) {
        if (validityMap is Map) {
          pricing[electionType] = {};
          validityMap.forEach((days, price) {
            pricing[electionType]![int.parse(days.toString())] = price as int;
          });
        }
      });
    }

    final planType = json['type'] ?? '';

    return SubscriptionPlan(
      id: json['id'] ?? '',
      planId: json['planId'] ?? '',
      name: json['name'] ?? '',
      type: planType,
      pricing: pricing,
      isActive: json['isActive'] ?? true,
      dashboardTabs: planType == 'candidate' ? DashboardTabs.fromJson(json['dashboardTabs'] ?? {}) : null,
      profileFeatures: ProfileFeatures.fromJson(json['profileFeatures'] ?? {}),
      highlightFeatures: planType == 'highlight' ? HighlightFeatures.fromJson(json['highlightFeatures'] ?? {}) : null,
      carouselFeatures: (planType == 'highlight' || planType == 'carousel') ? CarouselFeatures.fromJson(json['carouselFeatures'] ?? {}) : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert pricing to Firestore-compatible format
    Map<String, dynamic> pricingJson = {};
    pricing.forEach((electionType, validityMap) {
      pricingJson[electionType] = validityMap.map((days, price) => MapEntry(days.toString(), price));
    });

    final json = {
      'id': id,
      'planId': planId,
      'name': name,
      'type': type,
      'pricing': pricingJson,
      'isActive': isActive,
      'profileFeatures': profileFeatures.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };

    // Add optional fields based on plan type
    if (dashboardTabs != null) {
      json['dashboardTabs'] = dashboardTabs!.toJson();
    }
    if (highlightFeatures != null) {
      json['highlightFeatures'] = highlightFeatures!.toJson();
    }
    if (carouselFeatures != null) {
      json['carouselFeatures'] = carouselFeatures!.toJson();
    }

    return json;
  }

  SubscriptionPlan copyWith({
    String? id,
    String? planId,
    String? name,
    String? type,
    Map<String, Map<int, int>>? pricing,
    bool? isActive,
    DashboardTabs? dashboardTabs,
    ProfileFeatures? profileFeatures,
    HighlightFeatures? highlightFeatures,
    CarouselFeatures? carouselFeatures,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      type: type ?? this.type,
      pricing: pricing ?? this.pricing,
      isActive: isActive ?? this.isActive,
      dashboardTabs: dashboardTabs ?? this.dashboardTabs,
      profileFeatures: profileFeatures ?? this.profileFeatures,
      highlightFeatures: highlightFeatures ?? this.highlightFeatures,
      carouselFeatures: carouselFeatures ?? this.carouselFeatures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserSubscription {
  final String subscriptionId;
  final String userId;
  final String planId;
  final String planType; // 'candidate' or 'voter'
  final String? electionType; // election type for candidate plans
  final int? validityDays; // validity period in days
  final int amountPaid;
  final DateTime purchasedAt;
  final DateTime? expiresAt; // calculated from validityDays
  final bool isActive;
  final Map<String, dynamic>? metadata; // additional data

  UserSubscription({
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.planType,
    this.electionType,
    this.validityDays,
    required this.amountPaid,
    required this.purchasedAt,
    this.expiresAt,
    required this.isActive,
    this.metadata,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    DateTime purchasedAt;
    if (json['purchasedAt'] is Timestamp) {
      purchasedAt = (json['purchasedAt'] as Timestamp).toDate();
    } else if (json['purchasedAt'] is String) {
      purchasedAt = DateTime.parse(json['purchasedAt']);
    } else {
      purchasedAt = DateTime.now();
    }

    DateTime? expiresAt;
    if (json['expiresAt'] is Timestamp) {
      expiresAt = (json['expiresAt'] as Timestamp).toDate();
    } else if (json['expiresAt'] is String) {
      expiresAt = DateTime.parse(json['expiresAt']);
    }

    return UserSubscription(
      subscriptionId: json['subscriptionId'] ?? '',
      userId: json['userId'] ?? '',
      planId: json['planId'] ?? '',
      planType: json['planType'] ?? '',
      electionType: json['electionType'],
      validityDays: json['validityDays'],
      amountPaid: json['amountPaid'] ?? 0,
      purchasedAt: purchasedAt,
      expiresAt: expiresAt,
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'userId': userId,
      'planId': planId,
      'planType': planType,
      'electionType': electionType,
      'validityDays': validityDays,
      'amountPaid': amountPaid,
      'purchasedAt': purchasedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }
}

class XPTransaction {
  final String transactionId;
  final String userId;
  final int amount; // positive for earned, negative for spent
  final String type; // 'purchase', 'earned', 'spent'
  final String description;
  final DateTime timestamp;
  final String? referenceId; // payment ID, poll ID, etc.

  XPTransaction({
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.referenceId,
  });

  factory XPTransaction.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    return XPTransaction(
      transactionId: json['transactionId'] ?? '',
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: timestamp,
      referenceId: json['referenceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'referenceId': referenceId,
    };
  }
}

