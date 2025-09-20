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

    return plan.price == 0 ? 'Free' : 'Upgrade';
  }

  /// Check if a button should be disabled
  static bool shouldDisableButton(SubscriptionPlan plan, String? currentPlanId, bool isCandidatePlan) {
    if (!isCandidatePlan) {
      return plan.price == 0; // No button for free plans
    }

    if (currentPlanId == null) return false;

    // Define plan hierarchy (assuming plan names indicate level)
    final planHierarchy = {
      'basic': 1,
      'gold': 2,
      'platinum': 3,
    };

    final currentPlanLevel = planHierarchy[currentPlanId.toLowerCase()] ?? 0;
    final thisPlanLevel = planHierarchy[plan.name.toLowerCase()] ?? 0;

    // Disable if current plan is same or higher level
    return thisPlanLevel <= currentPlanLevel;
  }

  /// Sort plans by price in ascending order
  static List<SubscriptionPlan> sortPlansByPrice(List<SubscriptionPlan> plans) {
    return plans.toList()..sort((a, b) => a.price.compareTo(b.price));
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
