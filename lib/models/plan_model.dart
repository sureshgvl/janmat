import 'package:cloud_firestore/cloud_firestore.dart';

class PlanFeature {
  final String name;
  final String description;
  final bool enabled;

  PlanFeature({
    required this.name,
    required this.description,
    required this.enabled,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'enabled': enabled};
  }
}

class SubscriptionPlan {
  final String planId;
  final String name;
  final String type; // 'candidate' or 'voter'
  final int price; // in rupees
  final int? limit; // for candidate plans (first 1000)
  final int? xpAmount; // for voter plans
  final List<PlanFeature> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubscriptionPlan({
    required this.planId,
    required this.name,
    required this.type,
    required this.price,
    this.limit,
    this.xpAmount,
    required this.features,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    DateTime? updatedAt;
    if (json['updatedAt'] is Timestamp) {
      updatedAt = (json['updatedAt'] as Timestamp).toDate();
    } else if (json['updatedAt'] is String) {
      updatedAt = DateTime.parse(json['updatedAt']);
    }

    return SubscriptionPlan(
      planId: json['planId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      price: json['price'] ?? 0,
      limit: json['limit'],
      xpAmount: json['xpAmount'],
      features: json['features'] != null
          ? List<PlanFeature>.from(
              (json['features'] as List).map((x) => PlanFeature.fromJson(x)),
            )
          : [],
      isActive: json['isActive'] ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'name': name,
      'type': type,
      'price': price,
      'limit': limit,
      'xpAmount': xpAmount,
      'features': features.map((x) => x.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SubscriptionPlan copyWith({
    String? planId,
    String? name,
    String? type,
    int? price,
    int? limit,
    int? xpAmount,
    List<PlanFeature>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      planId: planId ?? this.planId,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      limit: limit ?? this.limit,
      xpAmount: xpAmount ?? this.xpAmount,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
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
  final int amountPaid;
  final DateTime purchasedAt;
  final DateTime? expiresAt; // for recurring subscriptions
  final bool isActive;
  final Map<String, dynamic>? metadata; // additional data

  UserSubscription({
    required this.subscriptionId,
    required this.userId,
    required this.planId,
    required this.planType,
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
