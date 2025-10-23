import 'package:cloud_firestore/cloud_firestore.dart';

class DistrictPromotion {
  final String? id;
  final String promotionId;
  final String partyId;
  final String partyName;
  final String districtId;
  final String districtName;
  final String stateId;
  final String stateName;
  final PromotionContent content;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final PromotionPricing pricing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DistrictPromotion({
    this.id,
    required this.promotionId,
    required this.partyId,
    required this.partyName,
    required this.districtId,
    required this.districtName,
    required this.stateId,
    required this.stateName,
    required this.content,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.pricing,
    this.createdAt,
    this.updatedAt,
  });

  factory DistrictPromotion.fromJson(Map<String, dynamic> json) {
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

    return DistrictPromotion(
      id: json['id'],
      promotionId: json['promotionId'] ?? '',
      partyId: json['partyId'] ?? '',
      partyName: json['partyName'] ?? '',
      districtId: json['districtId'] ?? '',
      districtName: json['districtName'] ?? '',
      stateId: json['stateId'] ?? '',
      stateName: json['stateName'] ?? '',
      content: PromotionContent.fromJson(json['content'] ?? {}),
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : DateTime.parse(json['endDate'] ?? DateTime.now().add(Duration(days: 30)).toIso8601String()),
      isActive: json['isActive'] ?? true,
      pricing: PromotionPricing.fromJson(json['pricing'] ?? {}),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promotionId': promotionId,
      'partyId': partyId,
      'partyName': partyName,
      'districtId': districtId,
      'districtName': districtName,
      'stateId': stateId,
      'stateName': stateName,
      'content': content.toJson(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'pricing': pricing.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  DistrictPromotion copyWith({
    String? id,
    String? promotionId,
    String? partyId,
    String? partyName,
    String? districtId,
    String? districtName,
    String? stateId,
    String? stateName,
    PromotionContent? content,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    PromotionPricing? pricing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DistrictPromotion(
      id: id ?? this.id,
      promotionId: promotionId ?? this.promotionId,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      content: content ?? this.content,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      pricing: pricing ?? this.pricing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class PromotionContent {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? ctaText;
  final String? targetUrl;

  PromotionContent({
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.ctaText,
    this.targetUrl,
  });

  factory PromotionContent.fromJson(Map<String, dynamic> json) {
    return PromotionContent(
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      ctaText: json['ctaText'],
      targetUrl: json['targetUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'ctaText': ctaText,
      'targetUrl': targetUrl,
    };
  }
}

class PromotionPricing {
  final int amount;
  final int duration; // in days

  PromotionPricing({
    required this.amount,
    required this.duration,
  });

  factory PromotionPricing.fromJson(Map<String, dynamic> json) {
    return PromotionPricing(
      amount: json['amount'] ?? 0,
      duration: json['duration'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'duration': duration,
    };
  }
}
