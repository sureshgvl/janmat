import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../controllers/monetization_controller.dart';

class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final MonetizationController controller;
  final bool isCandidatePlan;
  final VoidCallback? onPurchase;

  const PlanCard({
    super.key,
    required this.plan,
    required this.controller,
    this.isCandidatePlan = false,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final isLimitedOffer =
        isCandidatePlan && controller.isFirst1000PlanAvailable;

    // Get current user's plan information
    final userModel = controller.currentUserModel.value;
    final currentPlanId = userModel?.subscriptionPlanId;
    final isCurrentPlan = currentPlanId == plan.planId;

    // Determine if upgrade button should be disabled
    final shouldDisableButton = _shouldDisableButton(currentPlanId);
    final buttonText = _getButtonText(context, currentPlanId);

    return Card(
      elevation: isCurrentPlan ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan ? Colors.blue : Colors.transparent,
          width: isCurrentPlan ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCurrentPlan ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
                if (isLimitedOffer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIMITED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '₹${plan.price}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLimitedOffer ? Colors.orange : (isCurrentPlan ? Colors.blue : Colors.green),
              ),
            ),

            if (plan.xpAmount != null)
              Text(
                '${plan.xpAmount} XP Points',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.features,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      feature.enabled ? Icons.check_circle : Icons.cancel,
                      color: feature.enabled ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Only show button if not disabled for free plans
            if (!shouldDisableButton || plan.price > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: shouldDisableButton ? null : (onPurchase ?? () => _handlePurchase(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: shouldDisableButton
                        ? Colors.grey
                        : (isLimitedOffer ? Colors.orange : Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: shouldDisableButton ? 0 : 2,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Show message for disabled buttons
            if (shouldDisableButton && plan.price > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  isCurrentPlan
                      ? 'This is your current active plan'
                      : 'You have already upgraded to a higher plan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldDisableButton(String? currentPlanId) {
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

  String _getButtonText(BuildContext context, String? currentPlanId) {
    if (!isCandidatePlan) {
      return plan.price == 0 ? 'Free' : AppLocalizations.of(context)!.buyNow;
    }

    if (currentPlanId == plan.planId) {
      return 'Current Plan';
    }

    if (_shouldDisableButton(currentPlanId)) {
      return 'Already Upgraded';
    }

    return AppLocalizations.of(context)!.upgradeToPremium;
  }

  void _handlePurchase(BuildContext context) async {
    // Default purchase handling - can be overridden by parent
    if (onPurchase != null) {
      onPurchase!();
      return;
    }

    // Default implementation
    final currentUser = controller.currentFirebaseUser.value;
    if (currentUser == null) {
      // Handle error - could use a callback or snackbar
      return;
    }

    // This would typically trigger the purchase flow
    debugPrint('Purchasing plan: ${plan.planId}');
  }
}
