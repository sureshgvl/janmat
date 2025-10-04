import '../../../models/plan_model.dart';

/// Utility functions for plan management and comparison
class PlanUtils {
  /// Define plan hierarchy levels for comparison
  static const Map<String, int> planHierarchy = {
    'free_plan': 0,
    'basic_plan': 1,
    'gold_plan': 2,
    'platinum_plan': 3,
  };

  /// Check if a user can upgrade to a specific plan
  static bool canUpgradeToPlan(SubscriptionPlan plan, String? currentPlanId) {
    if (currentPlanId == null) return true;
    if (currentPlanId == plan.planId) return false; // Can't upgrade to same plan

    final currentLevel = planHierarchy[currentPlanId] ?? 0;
    final targetLevel = planHierarchy[plan.planId] ?? 0;

    return targetLevel > currentLevel;
  }

  /// Get appropriate button text based on plan status
  static String getButtonText(SubscriptionPlan plan, String? currentPlanId) {
    if (currentPlanId == plan.planId) {
      return 'Current Plan';
    }

    if (!canUpgradeToPlan(plan, currentPlanId)) {
      return 'Already Upgraded';
    }

    // For new pricing system, always show 'Select Plan' for candidate plans
    if (plan.type == 'candidate') {
      return 'Select Plan';
    }

    return 'Upgrade'; // Default for other plan types
  }

  /// Check if a button should be disabled
  static bool shouldDisableButton(SubscriptionPlan plan, String? currentPlanId, bool isCandidatePlan) {
    if (!isCandidatePlan) {
      return false; // XP plans don't have disable logic
    }

    if (currentPlanId == null) return false;

    // For new pricing system, always allow selection (logic handled in UI)
    return false;
  }

  /// Sort plans by name (since pricing is now election-specific)
  static List<SubscriptionPlan> sortPlansByPrice(List<SubscriptionPlan> plans) {
    return plans.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Filter plans by type
  static List<SubscriptionPlan> filterPlansByType(List<SubscriptionPlan> plans, String type) {
    return plans.where((plan) => plan.type == type && plan.isActive).toList();
  }

  /// Get plan level for comparison
  static int getPlanLevel(String planId) {
    return planHierarchy[planId] ?? 0;
  }

  /// Check if plan is current user's plan
  static bool isCurrentPlan(String? currentPlanId, String planId) {
    return currentPlanId == planId;
  }
}

