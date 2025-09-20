import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Plan {
  final String planId;
  final String name;
  final String type;
  final int price;
  final int? validityDays;
  final List<Map<String, dynamic>> features;
  final bool isActive;

  Plan({
    required this.planId,
    required this.name,
    required this.type,
    required this.price,
    this.validityDays,
    required this.features,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      planId: json['planId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      price: json['price'] ?? 0,
      validityDays: json['validityDays'],
      features: List<Map<String, dynamic>>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'name': name,
      'type': type,
      'price': price,
      'validityDays': validityDays,
      'features': features,
      'isActive': isActive,
    };
  }
}

class PlanService {
  static Future<List<Plan>> getAllPlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Plan.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching plans: $e');
      return [];
    }
  }

  static Future<Plan?> getPlanById(String planId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .get();

      if (doc.exists) {
        return Plan.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error fetching plan: $e');
      return null;
    }
  }

  static Future<List<Plan>> getCandidatePlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('type', isEqualTo: 'candidate')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Plan.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching candidate plans: $e');
      return [];
    }
  }

  static Future<List<Plan>> getVoterPlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('type', isEqualTo: 'voter')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => Plan.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error fetching voter plans: $e');
      return [];
    }
  }

  // Feature Access Control Methods

  /// Check if a user has access to a specific feature based on their plan
  static Future<bool> hasFeatureAccess(
    String userId,
    String featureName,
  ) async {
    try {
      // Get user's current plan
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final subscriptionPlanId = userData['subscriptionPlanId'];

      // If no subscription plan, check if it's a free plan
      if (subscriptionPlanId == null ||
          subscriptionPlanId == 'candidate_free') {
        return await _checkFreePlanFeature(featureName);
      }

      // Get the plan details
      final plan = await getPlanById(subscriptionPlanId);
      if (plan == null) return false;

      // Check if the feature is enabled in the plan
      return _isFeatureEnabled(plan, featureName);
    } catch (e) {
      return false;
    }
  }

  /// Get user's current plan
  static Future<Plan?> getUserPlan(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final subscriptionPlanId = userData['subscriptionPlanId'];

      if (subscriptionPlanId == null) {
        // Return free plan
        return await getPlanById('candidate_free');
      }

      return await getPlanById(subscriptionPlanId);
    } catch (e) {
      print('Error getting user plan: $e');
      return null;
    }
  }

  /// Check feature access for free plan
  static Future<bool> _checkFreePlanFeature(String featureName) async {
    final freePlan = await getPlanById('candidate_free');
    if (freePlan == null) return false;
    return _isFeatureEnabled(freePlan, featureName);
  }

  /// Check if a feature is enabled in a plan
  static bool _isFeatureEnabled(Plan plan, String featureName) {
    final feature = plan.features.firstWhere(
      (f) => f['name'] == featureName,
      orElse: () => {'enabled': false},
    );
    return feature['enabled'] ?? false;
  }

  // Specific feature checks for convenience

  static Future<bool> canEditManifesto(String userId) async {
    debugPrint('🔍 PLAN SERVICE: Checking manifesto edit permissions for user: $userId');

    // Check if user has full manifesto editing (paid plans)
    final hasCRUD = await hasFeatureAccess(userId, 'Manifesto CRUD');
    debugPrint('🔍 PLAN SERVICE: Manifesto CRUD access: $hasCRUD');
    if (hasCRUD) {
      debugPrint('🔍 PLAN SERVICE: User has Manifesto CRUD - returning true');
      return true;
    }

    // Check if user has limited manifesto editing (free plan)
    final hasLimited = await hasFeatureAccess(userId, 'Limited Manifesto');
    debugPrint('🔍 PLAN SERVICE: Limited Manifesto access: $hasLimited');
    if (hasLimited) {
      debugPrint('🔍 PLAN SERVICE: User has Limited Manifesto - returning true');
      return true;
    }

    // Check if user has manifesto view (basic access)
    final hasView = await hasFeatureAccess(userId, 'Manifesto View');
    debugPrint('🔍 PLAN SERVICE: Manifesto View access: $hasView');
    if (hasView) {
      debugPrint('🔍 PLAN SERVICE: User has Manifesto View - returning true');
      return true;
    }

    debugPrint('🔍 PLAN SERVICE: User has no manifesto permissions - returning false');
    return false;
  }

  static Future<bool> canUploadMedia(String userId) async {
    return await hasFeatureAccess(userId, 'Media Upload') ||
        await hasFeatureAccess(userId, 'Unlimited Media') ||
        await hasFeatureAccess(userId, 'Limited Media');
  }

  static Future<bool> canViewAnalytics(String userId) async {
    return await hasFeatureAccess(userId, 'Basic Analytics') ||
        await hasFeatureAccess(userId, 'Advanced Analytics');
  }

  static Future<bool> canManageEvents(String userId) async {
    return await hasFeatureAccess(userId, 'Events Management');
  }

  static Future<bool> canDisplayAchievements(String userId) async {
    return await hasFeatureAccess(userId, 'Achievements');
  }

  static Future<bool> hasSponsoredVisibility(String userId) async {
    return await hasFeatureAccess(userId, 'Sponsored Visibility');
  }

  static Future<bool> hasPrioritySupport(String userId) async {
    return await hasFeatureAccess(userId, 'Priority Support');
  }

  static Future<bool> hasCustomBranding(String userId) async {
    return await hasFeatureAccess(userId, 'Custom Branding');
  }

  /// Get media upload limit based on plan
  static Future<int> getMediaUploadLimit(String userId) async {
    if (await hasFeatureAccess(userId, 'Unlimited Media')) {
      return -1; // Unlimited
    } else if (await hasFeatureAccess(userId, 'Media Upload')) {
      // Check which plan for specific limits
      final plan = await getUserPlan(userId);
      if (plan?.name == 'Basic') return 10;
      if (plan?.name == 'Gold') return 50;
      return 10; // Default
    } else if (await hasFeatureAccess(userId, 'Limited Media')) {
      return 3; // Free plan
    }
    return 0; // No access
  }
}
