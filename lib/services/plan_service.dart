import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/plan_model.dart'; // Import SubscriptionPlan
import '../utils/app_logger.dart';

// Use SubscriptionPlan instead of the old Plan class

class PlanService {
  static Future<List<SubscriptionPlan>> getAllPlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.monetizationError('Error fetching plans: $e');
      return [];
    }
  }

  static Future<SubscriptionPlan?> getPlanById(String planId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('plans')
          .doc(planId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.monetizationError('Error fetching plan: $e');
      return null;
    }
  }

  static Future<List<SubscriptionPlan>> getCandidatePlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('type', isEqualTo: 'candidate')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.monetizationError('Error fetching candidate plans: $e');
      return [];
    }
  }

  static Future<List<SubscriptionPlan>> getVoterPlans() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .where('type', isEqualTo: 'voter')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.monetizationError('Error fetching voter plans: $e');
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
      final plan = await getUserPlan(userId);
      if (plan == null) return false;

      // Map old feature names to new structure
      switch (featureName) {
        case 'Manifesto CRUD':
        case 'Limited Manifesto':
        case 'Manifesto View':
          return plan.dashboardTabs?.manifesto.enabled ?? false;
        case 'Media Upload':
        case 'Unlimited Media':
        case 'Limited Media':
          return plan.dashboardTabs?.media.enabled ?? false;
        case 'Basic Analytics':
        case 'Advanced Analytics':
          return plan.dashboardTabs?.analytics.enabled ?? false;
        case 'Events Management':
          return plan.dashboardTabs?.events.enabled ?? false;
        case 'Achievements':
          return plan.dashboardTabs?.achievements.enabled ?? false;
        case 'Sponsored Visibility':
          return plan.profileFeatures.sponsoredBanner;
        case 'Priority Support':
          return plan.dashboardTabs?.contact.features.prioritySupport == true;
        case 'Custom Branding':
          return plan.profileFeatures.customBranding == true;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get user's current plan
  static Future<SubscriptionPlan?> getUserPlan(String userId) async {
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
        return await getPlanById('free_plan');
      }

      return await getPlanById(subscriptionPlanId);
    } catch (e) {
      AppLogger.monetizationError('Error getting user plan: $e');
      return null;
    }
  }

  /// Check feature access for free plan
  static Future<bool> _checkFreePlanFeature(String featureName) async {
    final freePlan = await getPlanById('free_plan');
    if (freePlan == null) return false;
    return _isFeatureEnabled(freePlan, featureName);
  }

  /// Check if a feature is enabled in a plan
  static bool _isFeatureEnabled(SubscriptionPlan plan, String featureName) {
    // This method is now obsolete since features are structured differently
    // For backward compatibility, return false
    return false;
  }

  // Specific feature checks for convenience

  static Future<bool> canEditManifesto(String userId) async {
    AppLogger.monetization('Checking manifesto edit permissions for user: $userId');

    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs == null) {
      AppLogger.monetization('No plan found or highlight plan - returning false');
      return false;
    }

    final enabled = plan.dashboardTabs!.manifesto.enabled;
    final hasEditPermission = plan.dashboardTabs!.manifesto.permissions.contains('edit') ||
                             plan.dashboardTabs!.manifesto.permissions.contains('priority');

    AppLogger.monetization('Manifesto enabled: $enabled, has edit permission: $hasEditPermission');
    return enabled && hasEditPermission;
  }

  static Future<bool> canUploadMedia(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs == null) return false;

    return plan.dashboardTabs!.media.enabled &&
           (plan.dashboardTabs!.media.permissions.contains('edit') ||
            plan.dashboardTabs!.media.permissions.contains('upload') ||
            plan.dashboardTabs!.media.permissions.contains('priority'));
  }

  static Future<bool> canViewAnalytics(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs == null) return false;

    return plan.dashboardTabs!.analytics.enabled &&
           plan.dashboardTabs!.analytics.permissions.contains('view');
  }

  static Future<bool> canManageEvents(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs == null) return false;

    return plan.dashboardTabs!.events.enabled &&
           (plan.dashboardTabs!.events.permissions.contains('edit') ||
            plan.dashboardTabs!.events.permissions.contains('manage') ||
            plan.dashboardTabs!.events.permissions.contains('featured'));
  }

  static Future<bool> canDisplayAchievements(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs == null) return false;

    return plan.dashboardTabs!.achievements.enabled &&
           (plan.dashboardTabs!.achievements.permissions.contains('view') ||
            plan.dashboardTabs!.achievements.permissions.contains('edit') ||
            plan.dashboardTabs!.achievements.permissions.contains('featured'));
  }

  static Future<bool> hasSponsoredVisibility(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null) return false;

    return plan.profileFeatures.sponsoredBanner;
  }

  static Future<bool> hasPrioritySupport(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null) return false;

    return plan.dashboardTabs?.contact.features.prioritySupport == true ||
           plan.profileFeatures.adminSupport == true;
  }

  static Future<bool> hasCustomBranding(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null) return false;

    return plan.profileFeatures.customBranding == true;
  }

  /// Get media upload limit based on plan
  static Future<int> getMediaUploadLimit(String userId) async {
    final plan = await getUserPlan(userId);
    if (plan == null || plan.dashboardTabs?.media.enabled != true) return 0;

    return plan.dashboardTabs!.media.maxMediaItems;
  }

}

