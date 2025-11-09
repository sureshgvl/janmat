
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/plan_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../controllers/monetization_controller.dart';
import '../screens/plan_selection_screen.dart';

class PlanComparisonTable extends StatelessWidget {
  final MonetizationController controller;

  const PlanComparisonTable({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final candidatePlans = controller.plans
          .where((plan) => plan.type == 'candidate' && plan.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)); // Sort by name instead of price

      if (candidatePlans.isEmpty) {
        return _buildEmptyState();
      }

      return _buildModernComparisonView(context, candidatePlans);
    });
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No plans available at the moment',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernComparisonView(BuildContext context, List<SubscriptionPlan> plans) {
    final userModel = controller.currentUserModel.value;
    final currentPlanId = userModel?.subscriptionPlanId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.compare_arrows,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compare Plans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Choose the perfect plan for your needs',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Plans List - Better for mobile scrolling
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final isCurrentPlan = currentPlanId == plan.planId;
            final isPopular = index == 1; // First plan after free gets popular badge

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < plans.length - 1 ? 16 : 0, // No bottom padding for last item
              ),
              child: _buildPlanCard(context, plan, isCurrentPlan, isPopular),
            );
          },
        ),

        const SizedBox(height: 16),

        // Feature Comparison Section
        _buildFeatureComparisonSection(context, plans),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, bool isCurrentPlan, bool isPopular) {
    final canUpgrade = _canUpgradeToPlan(plan, controller.currentUserModel.value?.subscriptionPlanId);

    return Container(
      width: double.infinity, // Full width for list view
      constraints: const BoxConstraints(minHeight: 160), // Minimum height for consistency
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.grey.shade300)).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.grey.shade200),
            width: isCurrentPlan ? 2 : (isPopular ? 2 : 1),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isCurrentPlan
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Name Section - Centered with grey background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Plan Name
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCurrentPlan ? Colors.blue.shade800 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Badge positioned at top-right
                      if (isPopular || isCurrentPlan)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPopular ? Colors.orange : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isPopular ? 'POPULAR' : 'ACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Validity info for active plans
                if (isCurrentPlan && controller.currentUserModel.value?.subscriptionExpiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Valid till ${_formatExpiryDate(controller.currentUserModel.value!.subscriptionExpiresAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Key features preview - centered
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.center, // Center align the chips
                    children: _getKeyFeatures(plan).take(3).map((feature) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feature['name'] as String,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        ),
                      ),
                    ).toList(),
                  ),
                ),

                // Only show price and button for non-free plans
                if (plan.planId != 'free_plan') ...[
                  const SizedBox(height: 16),

                  // Price with validity period - centered
                  Center(
                    child: Builder(
                      builder: (context) {
                        final firebaseUser = controller.currentFirebaseUser.value;
                        final userId = firebaseUser?.uid ?? '';

                        return FutureBuilder<String?>(
                          future: controller.getUserElectionType(userId),
                          builder: (context, snapshot) {
                            final electionType = snapshot.data ?? 'municipal_corporation';
                            final pricing = plan.pricing[electionType];
                            final sevenDayPrice = pricing?[7] ?? pricing?.values.first ?? 99;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹$sevenDayPrice',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentPlan ? Colors.blue.shade600 : Colors.green.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '7 days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button - Full width at bottom
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canUpgrade ? () => _handlePurchase(context, plan) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canUpgrade
                            ? (isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.green))
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: canUpgrade ? 2 : 0,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: Text(
                        _getButtonText(plan, controller.currentUserModel.value?.subscriptionPlanId),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureComparisonSection(BuildContext context, List<SubscriptionPlan> plans) {
    // Define the comprehensive feature comparison list
    final featureComparison = [
      {'name': 'Basic Profile', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Basic Info', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Basic Contact', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Short Bio', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Limited Manifesto', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Limited Media', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Follower Count', 'free': true, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Full Manifesto', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Cover Photo', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Enhanced Media', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Limited Achievements', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Extended Contact', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Limited Events', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Basic Analytics', 'free': false, 'basic': true, 'gold': true, 'platinum': true},
      {'name': 'Carousel Highlight', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Video Manifesto', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Unlimited Media', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Unlimited Achievements', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Full Events', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Push Notifications', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Highlight Feature', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Advanced Analytics', 'free': false, 'basic': false, 'gold': true, 'platinum': true},
      {'name': 'Exclusive Banner', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Unlimited Everything', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Multiple Highlights', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Full Analytics Dashboard', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Chat Priority', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Premium Badge', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
      {'name': 'Admin Support', 'free': false, 'basic': false, 'gold': false, 'platinum': true},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.list_alt,
              color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Detailed Feature Comparison',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 0,
              headingRowHeight: 40,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 50,
              columns: [
                DataColumn(
                  label: Text(
                    'Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                ...plans.map((plan) => DataColumn(
                  label: Container(
                    width: 80,
                    alignment: Alignment.center,
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
              rows: featureComparison.map((feature) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          feature['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    ...plans.map((plan) {
                      // Map plan names to feature keys
                      final planKey = plan.name.toLowerCase().contains('free') ? 'free' :
                                    plan.name.toLowerCase().contains('basic') ? 'basic' :
                                    plan.name.toLowerCase().contains('gold') ? 'gold' : 'platinum';

                      final isEnabled = feature[planKey] as bool;

                      return DataCell(
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: isEnabled
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                )
                              : const SizedBox.shrink(), // Hide X marks, only show ticks
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _canUpgradeToPlan(SubscriptionPlan plan, String? currentPlanId) {
    if (currentPlanId == null) return true;
    if (currentPlanId == plan.planId) return false; // Can't upgrade to same plan

    // Define plan hierarchy
    final planHierarchy = {
      'free_plan': 0,
      'basic_plan': 1,
      'gold_plan': 2,
      'platinum_plan': 3,
    };

    final currentLevel = planHierarchy[currentPlanId] ?? 0;
    final targetLevel = planHierarchy[plan.planId] ?? 0;

    return targetLevel > currentLevel;
  }

  String _getButtonText(SubscriptionPlan plan, String? currentPlanId) {
    if (currentPlanId == plan.planId) {
      return 'Current Plan';
    }

    if (!_canUpgradeToPlan(plan, currentPlanId)) {
      return 'Already Upgraded';
    }

    return 'Check and Purchase'; // Updated button text
  }

  String _formatExpiryDate(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.inDays > 0) {
      return '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Expired';
    }
  }

  List<Map<String, dynamic>> _getKeyFeatures(SubscriptionPlan plan) {
    final features = <Map<String, dynamic>>[];

    // Dashboard Tabs (only for candidate plans)
    if (plan.dashboardTabs != null) {
      if (plan.dashboardTabs!.manifesto.enabled) {
        features.add({'name': 'Manifesto', 'enabled': true});
      }
      if (plan.dashboardTabs!.achievements.enabled) {
        features.add({'name': 'Achievements', 'enabled': true});
      }
      if (plan.dashboardTabs!.media.enabled) {
        features.add({'name': 'Media Upload', 'enabled': true});
      }
      if (plan.dashboardTabs!.events.enabled) {
        features.add({'name': 'Events', 'enabled': true});
      }
      if (plan.dashboardTabs!.analytics.enabled) {
        features.add({'name': 'Analytics', 'enabled': true});
      }
    }

    // Profile Features
    if (plan.profileFeatures.premiumBadge) {
      features.add({'name': 'Premium Badge', 'enabled': true});
    }
    if (plan.profileFeatures.sponsoredBanner) {
      features.add({'name': 'Sponsored Banner', 'enabled': true});
    }
    if (plan.profileFeatures.highlightCarousel) {
      features.add({'name': 'Highlight Carousel', 'enabled': true});
    }
    if (plan.profileFeatures.pushNotifications) {
      features.add({'name': 'Push Notifications', 'enabled': true});
    }

    return features;
  }

  void _handlePurchase(BuildContext context, SubscriptionPlan plan) async {
    final currentUser = controller.currentFirebaseUser.value;
    if (currentUser == null) {
      SnackbarUtils.showError('Please login to make a purchase');
      return;
    }

    // For new pricing system, navigate to plan selection with validity options
    AppLogger.monetization('🔄 Navigating to plan selection for: ${plan.planId}');

    // Get user's election type
    final electionType = await controller.getUserElectionType(currentUser.uid) ?? 'municipal_corporation';

    // Navigate to plan selection screen with validity options
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanSelectionScreen(
          plan: plan,
          electionType: electionType,
        ),
      ),
    );
  }

}
