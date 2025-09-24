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

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.features,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ..._buildFeatureList(),

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

  List<Widget> _buildFeatureList() {
    final features = <Widget>[];

    // Dashboard Tabs Features
    if (plan.dashboardTabs.basicInfo.enabled) {
      features.add(_buildFeatureItem('Basic Info', true));
    }

    if (plan.dashboardTabs.manifesto.enabled) {
      features.add(_buildFeatureItem('Manifesto', true));
      if (plan.dashboardTabs.manifesto.features.pdfUpload) {
        features.add(_buildFeatureItem('  • PDF Upload', true));
      }
      if (plan.dashboardTabs.manifesto.features.videoUpload) {
        features.add(_buildFeatureItem('  • Video Upload', true));
      }
      if (plan.dashboardTabs.manifesto.features.promises) {
        features.add(_buildFeatureItem('  • Promises (${plan.dashboardTabs.manifesto.features.maxPromises})', true));
      }
      if (plan.dashboardTabs.manifesto.features.multipleVersions == true) {
        features.add(_buildFeatureItem('  • Multiple Versions', true));
      }
    }

    if (plan.dashboardTabs.achievements.enabled) {
      final max = plan.dashboardTabs.achievements.maxAchievements == -1 ? 'Unlimited' : plan.dashboardTabs.achievements.maxAchievements.toString();
      features.add(_buildFeatureItem('Achievements ($max)', true));
    }

    if (plan.dashboardTabs.media.enabled) {
      final max = plan.dashboardTabs.media.maxMediaItems == -1 ? 'Unlimited' : plan.dashboardTabs.media.maxMediaItems.toString();
      features.add(_buildFeatureItem('Media ($max items)', true));
    }

    if (plan.dashboardTabs.contact.enabled) {
      features.add(_buildFeatureItem('Contact', true));
      if (plan.dashboardTabs.contact.features.extended) {
        features.add(_buildFeatureItem('  • Extended Info', true));
      }
      if (plan.dashboardTabs.contact.features.socialLinks) {
        features.add(_buildFeatureItem('  • Social Links', true));
      }
      if (plan.dashboardTabs.contact.features.prioritySupport == true) {
        features.add(_buildFeatureItem('  • Priority Support', true));
      }
    }

    if (plan.dashboardTabs.events.enabled) {
      final max = plan.dashboardTabs.events.maxEvents == -1 ? 'Unlimited' : plan.dashboardTabs.events.maxEvents.toString();
      features.add(_buildFeatureItem('Events ($max)', true));
    }

    if (plan.dashboardTabs.analytics.enabled) {
      features.add(_buildFeatureItem('Analytics', true));
      if (plan.dashboardTabs.analytics.features?.advanced == true) {
        features.add(_buildFeatureItem('  • Advanced', true));
      }
      if (plan.dashboardTabs.analytics.features?.fullDashboard == true) {
        features.add(_buildFeatureItem('  • Full Dashboard', true));
      }
      if (plan.dashboardTabs.analytics.features?.realTime == true) {
        features.add(_buildFeatureItem('  • Real-time', true));
      }
    }

    // Profile Features
    if (plan.profileFeatures.premiumBadge) {
      features.add(_buildFeatureItem('Premium Badge', true));
    }
    if (plan.profileFeatures.sponsoredBanner) {
      features.add(_buildFeatureItem('Sponsored Banner', true));
    }
    if (plan.profileFeatures.highlightCarousel) {
      features.add(_buildFeatureItem('Highlight Carousel', true));
    }
    if (plan.profileFeatures.pushNotifications) {
      features.add(_buildFeatureItem('Push Notifications', true));
    }
    if (plan.profileFeatures.multipleHighlights == true) {
      features.add(_buildFeatureItem('Multiple Highlights', true));
    }
    if (plan.profileFeatures.adminSupport == true) {
      features.add(_buildFeatureItem('Admin Support', true));
    }
    if (plan.profileFeatures.customBranding == true) {
      features.add(_buildFeatureItem('Custom Branding', true));
    }

    return features;
  }

  Widget _buildFeatureItem(String name, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
