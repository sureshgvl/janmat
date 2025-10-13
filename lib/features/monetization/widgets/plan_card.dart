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
    final subscriptionExpiresAt = userModel?.subscriptionExpiresAt;

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

            // Show expiration countdown for current plan
            if (isCurrentPlan && subscriptionExpiresAt != null)
              _buildExpirationCountdown(context, subscriptionExpiresAt),

            // Price display logic
            if (plan.planId == 'free_plan') ...[
              const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ] else if (plan.type == 'voter') ...[
              const Text(
                'XP Points',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ] else ...[
              // For candidate plans without new pricing structure
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context)!.features,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ..._buildFeatureList(),

            const SizedBox(height: 16),

            // Show current plan status for active plans (instead of button)
            if (isCurrentPlan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Center(
                  child: Text(
                    _getCurrentPlanDisplayText(currentPlanId),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              )
            // Show button for non-current plans
            else
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

            // Show message for disabled buttons (only for non-current plans)
            if (shouldDisableButton && !isCurrentPlan)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _getDisabledButtonMessage(currentPlanId),
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
    // Free plans are always available (unless already active)
    if (plan.planId == 'free_plan') {
      return currentPlanId == 'free_plan';
    }

    // XP plans don't disable buttons
    if (!isCandidatePlan) {
      return false;
    }

    // Highlight and carousel plans are separate purchases, not part of hierarchy
    if (plan.type == 'highlight' || plan.type == 'carousel') {
      return false; // These plans are always available (if user has access)
    }

    if (currentPlanId == null) return false;

    // Check plan hierarchy for main candidate plans (free, basic, gold, platinum)
    return _isLowerOrEqualPlan(currentPlanId, plan.planId);
  }

  // Define plan hierarchy (higher number = higher tier)
  int _getPlanLevel(String planId) {
    switch (planId) {
      case 'free_plan': return 0;
      case 'basic_plan': return 1;
      case 'gold_plan': return 2;
      case 'platinum_plan': return 3;
      default: return 0;
    }
  }

  // Check if current plan is higher or equal to target plan
  bool _isLowerOrEqualPlan(String currentPlanId, String targetPlanId) {
    return _getPlanLevel(currentPlanId) >= _getPlanLevel(targetPlanId);
  }

  String _getDisabledButtonMessage(String? currentPlanId) {
    if (currentPlanId == plan.planId) {
      return 'This is your current active plan';
    }

    if (currentPlanId != null && _isLowerOrEqualPlan(currentPlanId, plan.planId)) {
      final currentLevel = _getPlanLevel(currentPlanId);
      final targetLevel = _getPlanLevel(plan.planId);
      if (currentLevel > targetLevel) {
        return 'You have a higher plan active';
      } else {
        return 'This plan is already active';
      }
    }

    return 'Plan not available';
  }

  String _getCurrentPlanDisplayText(String? currentPlanId) {
    if (currentPlanId == plan.planId) {
      switch (plan.planId) {
        case 'free_plan':
          return 'Free Plan Active';
        case 'basic_plan':
          return 'Basic Plan Active';
        case 'gold_plan':
          return 'Gold Plan Active';
        case 'platinum_plan':
          return 'Platinum Plan Active';
        default:
          return 'Current Plan';
      }
    }
    return '';
  }

  String _getButtonText(BuildContext context, String? currentPlanId) {
    // Free plans
    if (plan.planId == 'free_plan') {
      return currentPlanId == 'free_plan' ? 'Active Free Plan' : 'Activate Free Plan';
    }

    // XP plans
    if (!isCandidatePlan) {
      return 'Buy Now';
    }

    // Candidate plans
    if (currentPlanId == plan.planId) {
      return 'Current Plan';
    }

    if (_shouldDisableButton(currentPlanId)) {
      return 'Already Active';
    }

    // Determine if this is an upgrade or downgrade
    if (currentPlanId != null && _getPlanLevel(currentPlanId) < _getPlanLevel(plan.planId)) {
      return 'Upgrade';
    }

    return AppLocalizations.of(context)!.upgradeToPremium;
  }

  List<Widget> _buildFeatureList() {
    final features = <Widget>[];

    // Dashboard Tabs Features (only for candidate plans)
    if (plan.dashboardTabs != null) {
      if (plan.dashboardTabs!.basicInfo.enabled) {
        features.add(_buildFeatureItem('Basic Info', true));
      }

      if (plan.dashboardTabs!.manifesto.enabled) {
        features.add(_buildFeatureItem('Manifesto', true));
        if (plan.dashboardTabs!.manifesto.features.pdfUpload) {
          features.add(_buildFeatureItem('  • PDF Upload', true));
        }
        if (plan.dashboardTabs!.manifesto.features.videoUpload) {
          features.add(_buildFeatureItem('  • Video Upload', true));
        }
        if (plan.dashboardTabs!.manifesto.features.promises) {
          features.add(_buildFeatureItem('  • Promises (${plan.dashboardTabs!.manifesto.features.maxPromises})', true));
        }
        if (plan.dashboardTabs!.manifesto.features.multipleVersions == true) {
          features.add(_buildFeatureItem('  • Multiple Versions', true));
        }
      }

      if (plan.dashboardTabs!.achievements.enabled) {
        final max = plan.dashboardTabs!.achievements.maxAchievements == -1 ? 'Unlimited' : plan.dashboardTabs!.achievements.maxAchievements.toString();
        features.add(_buildFeatureItem('Achievements ($max)', true));
      }

      if (plan.dashboardTabs!.media.enabled) {
        final max = plan.dashboardTabs!.media.maxMediaItems == -1 ? 'Unlimited' : plan.dashboardTabs!.media.maxMediaItems.toString();
        features.add(_buildFeatureItem('Media ($max items)', true));
      }

      if (plan.dashboardTabs!.contact.enabled) {
        features.add(_buildFeatureItem('Contact', true));
        if (plan.dashboardTabs!.contact.features.extended) {
          features.add(_buildFeatureItem('  • Extended Info', true));
        }
        if (plan.dashboardTabs!.contact.features.socialLinks) {
          features.add(_buildFeatureItem('  • Social Links', true));
        }
        if (plan.dashboardTabs!.contact.features.prioritySupport == true) {
          features.add(_buildFeatureItem('  • Priority Support', true));
        }
      }

      if (plan.dashboardTabs!.events.enabled) {
        final max = plan.dashboardTabs!.events.maxEvents == -1 ? 'Unlimited' : plan.dashboardTabs!.events.maxEvents.toString();
        features.add(_buildFeatureItem('Events ($max)', true));
      }

      if (plan.dashboardTabs!.analytics.enabled) {
        features.add(_buildFeatureItem('Analytics', true));
        if (plan.dashboardTabs!.analytics.features?.advanced == true) {
          features.add(_buildFeatureItem('  • Advanced', true));
        }
        if (plan.dashboardTabs!.analytics.features?.fullDashboard == true) {
          features.add(_buildFeatureItem('  • Full Dashboard', true));
        }
        if (plan.dashboardTabs!.analytics.features?.realTime == true) {
          features.add(_buildFeatureItem('  • Real-time', true));
        }
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

  Widget _buildExpirationCountdown(BuildContext context, DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 16),
            const SizedBox(width: 6),
            Text(
              'Plan Expired',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;

    String timeText;
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (days > 0) {
      timeText = '$days day${days > 1 ? 's' : ''} left';
      backgroundColor = Colors.blue[50]!;
      borderColor = Colors.blue[200]!;
      textColor = Colors.blue[700]!;
    } else if (hours > 0) {
      timeText = '$hours hour${hours > 1 ? 's' : ''} left';
      backgroundColor = Colors.orange[50]!;
      borderColor = Colors.orange[200]!;
      textColor = Colors.orange[700]!;
    } else {
      final minutes = difference.inMinutes % 60;
      timeText = '$minutes minute${minutes > 1 ? 's' : ''} left';
      backgroundColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
      textColor = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            'Expires in $timeText',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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

    // Add confirmation dialog for free plan activation when user has paid plan
    if (plan.planId == 'free_plan') {
      final currentPlanId = controller.currentUserModel.value?.subscriptionPlanId;
      if (currentPlanId != null && currentPlanId != 'free_plan') {
        final shouldDowngrade = await _showDowngradeConfirmation(context, currentPlanId);
        if (!shouldDowngrade) {
          return; // User cancelled the downgrade
        }
      }
    }

    // This would typically trigger the purchase flow
    debugPrint('Purchasing plan: ${plan.planId}');
  }

  Future<bool> _showDowngradeConfirmation(BuildContext context, String currentPlanId) async {
    final currentPlanName = _getPlanDisplayName(currentPlanId);
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Plan Change'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You currently have $currentPlanName active. Are you sure you want to downgrade to the Free Plan?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: You will lose all premium features and may lose access to paid content.',
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Downgrade'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _getPlanDisplayName(String planId) {
    switch (planId) {
      case 'free_plan': return 'Free Plan';
      case 'basic_plan': return 'Basic Plan';
      case 'gold_plan': return 'Gold Plan';
      case 'platinum_plan': return 'Platinum Plan';
      default: return 'Unknown Plan';
    }
  }
}

