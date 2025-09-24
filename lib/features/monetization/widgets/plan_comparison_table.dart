import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/plan_model.dart';
import '../controllers/monetization_controller.dart';

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
        ..sort((a, b) => a.price.compareTo(b.price));

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
                        color: Colors.white.withOpacity(0.9),
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

        // Plans Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 1 : (plans.length > 3 ? 3 : plans.length),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isSmallScreen ? 0.8 : 0.9,
              ),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                final isCurrentPlan = currentPlanId == plan.planId;
                final isPopular = index == 1; // Middle plan is popular

                return _buildPlanCard(context, plan, isCurrentPlan, isPopular);
              },
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.grey.shade300)).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.grey.shade200),
            width: isCurrentPlan ? 2 : (isPopular ? 2 : 1),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isCurrentPlan
                ? LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
          ),
          child: Column(
            children: [
              // Plan Header
              if (isPopular) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (isCurrentPlan) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CURRENT PLAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Plan Name
              Text(
                plan.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPlan ? Colors.blue.shade800 : Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Price
              Text(
                '₹${plan.price}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPlan ? Colors.blue.shade600 : Colors.green.shade600,
                ),
              ),

              // XP Amount removed for candidate plans

              const SizedBox(height: 20),

              // Features Preview
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Key Features',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._getKeyFeatures(plan).take(3).map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            feature['enabled'] as bool ? Icons.check_circle : Icons.cancel,
                            color: feature['enabled'] as bool ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature['name'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (_getKeyFeatures(plan).length > 3)
                      Text(
                        '+${_getKeyFeatures(plan).length - 3} more features',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canUpgrade ? () => _handlePurchase(context, plan) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canUpgrade
                        ? (isCurrentPlan ? Colors.blue : (isPopular ? Colors.orange : Colors.green))
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: canUpgrade ? 4 : 0,
                  ),
                  child: Text(
                    _getButtonText(plan, controller.currentUserModel.value?.subscriptionPlanId),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
              dataRowHeight: 50,
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
                      Container(
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

    return plan.price == 0 ? 'Free' : 'Upgrade';
  }

  List<Map<String, dynamic>> _getKeyFeatures(SubscriptionPlan plan) {
    final features = <Map<String, dynamic>>[];

    // Dashboard Tabs
    if (plan.dashboardTabs.manifesto.enabled) {
      features.add({'name': 'Manifesto', 'enabled': true});
    }
    if (plan.dashboardTabs.achievements.enabled) {
      features.add({'name': 'Achievements', 'enabled': true});
    }
    if (plan.dashboardTabs.media.enabled) {
      features.add({'name': 'Media Upload', 'enabled': true});
    }
    if (plan.dashboardTabs.events.enabled) {
      features.add({'name': 'Events', 'enabled': true});
    }
    if (plan.dashboardTabs.analytics.enabled) {
      features.add({'name': 'Analytics', 'enabled': true});
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
      Get.snackbar(
        'Error',
        'Please login to make a purchase',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${plan.name}'),
        content: Text(
          'Are you sure you want to purchase ${plan.name} for ₹${plan.price}?\n\n'
          '${_getKeyFeatures(plan).length} premium features will be unlocked.\n\n'
          'You will be redirected to our secure payment gateway.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Start the payment process with Razorpay
      debugPrint('💳 Starting payment process for plan: ${plan.planId}');
      final success = await controller.processPayment(plan.planId, plan.price);

      if (success) {
        // Payment initiated successfully - result will be handled by callbacks
        debugPrint('✅ Payment process initiated successfully');
      } else {
        Get.snackbar(
          'Payment Error',
          controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Failed to initiate payment. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
