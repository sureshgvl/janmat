import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/plan_model.dart';
import '../../../utils/app_logger.dart';
import '../controllers/monetization_controller.dart';
import 'plan_card.dart';
import 'plan_card_with_validity_options.dart';

class CandidatePlansSection extends StatelessWidget {
  final MonetizationController controller;
  final String? userElectionType;
  final Function(SubscriptionPlan, int) onPurchaseWithValidity;
  final Function(SubscriptionPlan) onPurchase;

  const CandidatePlansSection({
    super.key,
    required this.controller,
    required this.userElectionType,
    required this.onPurchaseWithValidity,
    required this.onPurchase,
  });

  Future<bool> _hasRequiredPlanForHighlights() async {
    try {
      AppLogger.monetization('🔍 [CandidatePlansSection] Checking plan eligibility for highlights (requires Platinum)...');

      // Ensure user model is loaded
      if (controller.currentUserModel.value == null) {
        AppLogger.monetization('⏳ [CandidatePlansSection] User model not loaded, loading now...');
        await controller.loadUserStatusData();
      }

      // Check user model for Platinum plan
      final userModel = controller.currentUserModel.value;
      if (userModel != null) {
        // Highlight plans require Platinum plan
        final hasAccess = userModel.premium == true &&
                         userModel.subscriptionPlanId == 'platinum_plan';
        AppLogger.monetization('✅ [CandidatePlansSection] User model check: premium=${userModel.premium}, planId=${userModel.subscriptionPlanId}, hasAccess=$hasAccess');

        if (hasAccess) {
          AppLogger.monetization('✅ [CandidatePlansSection] User has Platinum plan - access to highlight plans granted');
          return true;
        } else {
          AppLogger.monetization('⚠️ [CandidatePlansSection] User needs Platinum plan for highlights (current: ${userModel.subscriptionPlanId})');
          return false;
        }
      }

      // Fallback: check active subscriptions for Platinum plan
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetization('❌ [CandidatePlansSection] No current user');
        return false;
      }

      // Check for active Platinum subscription
      final candidateSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'candidate',
      );
      final hasPlatinumAccess = candidateSubscription?.isActive == true &&
                               candidateSubscription?.planId == 'platinum_plan';

      final highlightSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'highlight',
      );
      final hasHighlightAccess = highlightSubscription?.isActive ?? false;

      final hasAccess = hasPlatinumAccess || hasHighlightAccess;
      AppLogger.monetization('✅ [CandidatePlansSection] Subscription check result: $hasAccess (platinum: $hasPlatinumAccess, highlight: ${highlightSubscription?.planId})');
      return hasAccess;
    } catch (e) {
      AppLogger.monetization('❌ [CandidatePlansSection] Error checking plan eligibility: $e');
      return false;
    }
  }

  Future<bool> _hasRequiredPlanForCarousel() async {
    try {
      AppLogger.monetization('🔍 [CandidatePlansSection] Checking plan eligibility for carousel (requires Platinum)...');

      // Ensure user model is loaded
      if (controller.currentUserModel.value == null) {
        AppLogger.monetization('⏳ [CandidatePlansSection] User model not loaded, loading now...');
        await controller.loadUserStatusData();
      }

      // Check user model for Platinum plan
      final userModel = controller.currentUserModel.value;
      if (userModel != null) {
        // Carousel plans require Platinum plan
        final hasAccess = userModel.premium == true &&
                         userModel.subscriptionPlanId == 'platinum_plan';
        AppLogger.monetization('✅ [CandidatePlansSection] User model check: premium=${userModel.premium}, planId=${userModel.subscriptionPlanId}, hasAccess=$hasAccess');

        if (hasAccess) {
          AppLogger.monetization('✅ [CandidatePlansSection] User has Platinum plan - access to carousel plans granted');
          return true;
        } else {
          AppLogger.monetization('⚠️ [CandidatePlansSection] User needs Platinum plan for carousel (current: ${userModel.subscriptionPlanId})');
          return false;
        }
      }

      // Fallback: check active subscriptions for Platinum plan
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetization('❌ [CandidatePlansSection] No current user');
        return false;
      }

      // Check for active Platinum subscription
      final candidateSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'candidate',
      );
      final hasPlatinumAccess = candidateSubscription?.isActive == true &&
                               candidateSubscription?.planId == 'platinum_plan';

      final carouselSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'carousel',
      );
      final hasCarouselAccess = carouselSubscription?.isActive ?? false;

      final hasAccess = hasPlatinumAccess || hasCarouselAccess;
      AppLogger.monetization('✅ [CandidatePlansSection] Subscription check result: $hasAccess (platinum: $hasPlatinumAccess, carousel: ${carouselSubscription?.planId})');
      return hasAccess;
    } catch (e) {
      AppLogger.monetization('❌ [CandidatePlansSection] Error checking plan eligibility: $e');
      return false;
    }
  }

  Widget _buildDisabledPlanCard(SubscriptionPlan plan, String requiredPlan) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Text(
                    'LOCKED',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Requires $requiredPlan or Platinum Plan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null, // Disabled
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  'Subscribe to $requiredPlan First',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _showFreePlans(List<SubscriptionPlan> freePlans) {
    final widgets = <Widget>[];

    for (final plan in freePlans) {
      widgets.add(PlanCard(
        plan: plan,
        controller: controller,
        isCandidatePlan: false,
        onPurchase: null, // Free plans don't need purchase
      ));
      if (plan != freePlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  List<Widget> _showBasicPlans(List<SubscriptionPlan> basicPlans) {
    final widgets = <Widget>[];

    for (final plan in basicPlans) {
      AppLogger.monetization('🎯 Checking basic plan: ${plan.name} (${plan.planId})');

      if (userElectionType != null &&
          plan.pricing.containsKey(userElectionType) &&
          plan.pricing[userElectionType]!.isNotEmpty) {
        AppLogger.monetization('✅✅ Showing PlanCardWithValidityOptions for basic plan');
        widgets.add(PlanCardWithValidityOptions(
          plan: plan,
          electionType: userElectionType!,
          onPurchase: onPurchaseWithValidity,
        ));
      } else {
        AppLogger.monetization('⚠️ Showing regular PlanCard for basic plan');
        widgets.add(PlanCard(
          plan: plan,
          controller: controller,
          isCandidatePlan: true,
          onPurchase: () => onPurchase(plan),
        ));
      }

      if (plan != basicPlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  List<Widget> _showGoldPlans(List<SubscriptionPlan> premiumPlans) {
    final widgets = <Widget>[];
    final goldPlans = premiumPlans.where((plan) => plan.planId == 'gold_plan').toList();
    final currentPlanId = controller.currentUserModel.value?.subscriptionPlanId;

    for (final plan in goldPlans) {
      // If this is the user's current plan, always use PlanCard to show current plan status
      if (currentPlanId == 'gold_plan') {
        widgets.add(PlanCard(
          plan: plan,
          controller: controller,
          isCandidatePlan: true,
          onPurchase: () => onPurchase(plan),
        ));
      } else if (userElectionType != null &&
          plan.pricing.containsKey(userElectionType) &&
          plan.pricing[userElectionType]!.isNotEmpty) {
        widgets.add(PlanCardWithValidityOptions(
          plan: plan,
          electionType: userElectionType!,
          onPurchase: onPurchaseWithValidity,
        ));
      } else {
        widgets.add(PlanCard(
          plan: plan,
          controller: controller,
          isCandidatePlan: true,
          onPurchase: () => onPurchase(plan),
        ));
      }

      if (plan != goldPlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  List<Widget> _showPlatinumPlans(List<SubscriptionPlan> premiumPlans) {
    final widgets = <Widget>[];
    final platinumPlans = premiumPlans.where((plan) => plan.planId == 'platinum_plan').toList();
    final currentPlanId = controller.currentUserModel.value?.subscriptionPlanId;

    for (final plan in platinumPlans) {
      // If this is the user's current plan, always use PlanCard to show current plan status
      if (currentPlanId == 'platinum_plan') {
        widgets.add(PlanCard(
          plan: plan,
          controller: controller,
          isCandidatePlan: true,
          onPurchase: () => onPurchase(plan),
        ));
      } else if (userElectionType != null &&
          plan.pricing.containsKey(userElectionType) &&
          plan.pricing[userElectionType]!.isNotEmpty) {
        widgets.add(PlanCardWithValidityOptions(
          plan: plan,
          electionType: userElectionType!,
          onPurchase: onPurchaseWithValidity,
        ));
      } else {
        widgets.add(PlanCard(
          plan: plan,
          controller: controller,
          isCandidatePlan: true,
          onPurchase: () => onPurchase(plan),
        ));
      }

      if (plan != platinumPlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  List<Widget> _showHighlightPlans(List<SubscriptionPlan> highlightPlans) {
    final widgets = <Widget>[];

    // Add highlight plans header
    widgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Professional Highlight Banner On Home Screen Features',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '• Up to 4 banners on home screen\n• Premium visibility for your campaign\n• Requires Platinum Plan to unlock',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );

    for (final plan in highlightPlans) {
      widgets.add(FutureBuilder<bool>(
        future: _hasRequiredPlanForHighlights(),
        builder: (context, snapshot) {
          final hasAccess = snapshot.data ?? false;
          AppLogger.monetization('🔍 [CandidatePlansSection] Highlight plan ${plan.name}: hasAccess=$hasAccess');

          if (hasAccess) {
            if (userElectionType != null &&
                plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty) {
              AppLogger.monetization('✅ [CandidatePlansSection] Showing PlanCardWithValidityOptions for highlight plan');
              return PlanCardWithValidityOptions(
                plan: plan,
                electionType: userElectionType!,
                onPurchase: onPurchaseWithValidity,
              );
            } else {
              AppLogger.monetization('⚠️ [CandidatePlansSection] Showing regular PlanCard for highlight plan (no pricing)');
              return PlanCard(
                plan: plan,
                controller: controller,
                isCandidatePlan: true,
                onPurchase: () => onPurchase(plan),
              );
            }
          } else {
            AppLogger.monetization('🔒 [CandidatePlansSection] Showing disabled card for highlight plan');
            return _buildDisabledPlanCard(plan, 'Platinum');
          }
        },
      ));

      if (plan != highlightPlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  List<Widget> _showCarouselPlans(List<SubscriptionPlan> carouselPlans) {
    final widgets = <Widget>[];

    // Add carousel plans header
    widgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_carousel, color: Colors.purple[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Carousel Profile on Home Screen',
                    style: TextStyle(
                      color: Colors.purple[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '• Up to 10 carousel slots on home screen\n• Maximum visibility for your campaign\n• Requires Platinum Plan to unlock',
              style: TextStyle(
                color: Colors.purple[700],
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );

    for (final plan in carouselPlans) {
      widgets.add(FutureBuilder<bool>(
        future: _hasRequiredPlanForCarousel(),
        builder: (context, snapshot) {
          final hasAccess = snapshot.data ?? false;
          AppLogger.monetization('🔍 [CandidatePlansSection] Carousel plan ${plan.name}: hasAccess=$hasAccess');

          if (hasAccess) {
            if (userElectionType != null &&
                plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty) {
              AppLogger.monetization('✅ [CandidatePlansSection] Showing PlanCardWithValidityOptions for carousel plan');
              return PlanCardWithValidityOptions(
                plan: plan,
                electionType: userElectionType!,
                onPurchase: onPurchaseWithValidity,
              );
            } else {
              AppLogger.monetization('⚠️ [CandidatePlansSection] Showing regular PlanCard for carousel plan (no pricing)');
              return PlanCard(
                plan: plan,
                controller: controller,
                isCandidatePlan: true,
                onPurchase: () => onPurchase(plan),
              );
            }
          } else {
            AppLogger.monetization('🔒 [CandidatePlansSection] Showing disabled card for carousel plan');
            return _buildDisabledPlanCard(plan, 'Platinum');
          }
        },
      ));

      if (plan != carouselPlans.last) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allPlans = controller.plans.toList();
      final currentPlanId = controller.currentUserModel.value?.subscriptionPlanId;

      AppLogger.monetization('📋 [CandidatePlansSection] Total plans loaded: ${allPlans.length}');
      AppLogger.monetization('📋 [CandidatePlansSection] User election type: $userElectionType');
      AppLogger.monetization('📋 [CandidatePlansSection] Current plan ID: $currentPlanId');

      // Show loading if plans are still being loaded
      if (controller.isLoading.value && allPlans.isEmpty) {
        AppLogger.monetization('⏳ [CandidatePlansSection] Plans still loading...');
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (allPlans.isEmpty) {
        AppLogger.monetization('❌ [CandidatePlansSection] No plans available');
        return const Center(
          child: Text('No plans available'),
        );
      }

      // Separate plans by type
      final freePlans = allPlans.where((plan) => plan.planId == 'free_plan').toList();
      final basicPlans = allPlans.where((plan) => plan.planId == 'basic_plan').toList();
      final premiumPlans = allPlans.where((plan) =>
        plan.type == 'candidate' &&
        plan.planId != 'free_plan' &&
        plan.planId != 'basic_plan'
      ).toList();
      final highlightPlans = allPlans.where((plan) => plan.type == 'highlight').toList();
      final carouselPlans = allPlans.where((plan) => plan.type == 'carousel').toList();

      final List<Widget> planWidgets = [];

      // Show free plans only if user doesn't have a paid plan
      if (freePlans.isNotEmpty && currentPlanId != 'gold_plan' && currentPlanId != 'platinum_plan') {
        planWidgets.addAll(_showFreePlans(freePlans));
        if (basicPlans.isNotEmpty || premiumPlans.isNotEmpty || highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20));
        }
      }

      // Hide lower tier plans if user has Platinum plan
      final hasPlatinumPlan = currentPlanId == 'platinum_plan';

      if (basicPlans.isNotEmpty && !hasPlatinumPlan) {
        planWidgets.addAll(_showBasicPlans(basicPlans));
        if (premiumPlans.isNotEmpty || highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20));
        }
      }

      if (premiumPlans.isNotEmpty) {
        // Show Gold plans only if user doesn't have Platinum
        if (!hasPlatinumPlan) {
          planWidgets.addAll(_showGoldPlans(premiumPlans));
        }
        // Always show Platinum plans (for upgrades or current status)
        planWidgets.addAll(_showPlatinumPlans(premiumPlans));
      }

      if (highlightPlans.isNotEmpty) {
        if (premiumPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20));
        }
        planWidgets.addAll(_showHighlightPlans(highlightPlans));
      }

      if (carouselPlans.isNotEmpty) {
        if (highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20));
        }
        planWidgets.addAll(_showCarouselPlans(carouselPlans));
      }

      AppLogger.monetization('📋 [CandidatePlansSection] Final plan widgets count: ${planWidgets.length}');

      if (planWidgets.isEmpty) {
        AppLogger.monetization('❌ [CandidatePlansSection] No plan widgets to display');
        return const Center(
          child: Text('No plans available'),
        );
      }

      AppLogger.monetization('✅ [CandidatePlansSection] Displaying ${planWidgets.length} plan widgets');

      // Add debug information at the bottom for development
      final debugWidgets = <Widget>[];
      debugWidgets.addAll(planWidgets);

      // Debug section (only in debug mode)
      // assert(() {
      //   debugWidgets.add(const SizedBox(height: 24));
      //   debugWidgets.add(Container(
      //     padding: const EdgeInsets.all(12),
      //     margin: const EdgeInsets.symmetric(horizontal: 16),
      //     decoration: BoxDecoration(
      //       color: Colors.grey[100],
      //       borderRadius: BorderRadius.circular(8),
      //       border: Border.all(color: Colors.grey[300]!),
      //     ),
      //     // child: Column(
      //     //   crossAxisAlignment: CrossAxisAlignment.start,
      //     //   children: [
      //     //     const Text(
      //     //       '🔍 Debug Info',
      //     //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      //     //     ),
      //     //     const SizedBox(height: 8),
      //     //     Text('Total Plans: ${allPlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Free Plans: ${freePlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Basic Plans: ${basicPlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Premium Plans: ${premiumPlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Highlight Plans: ${highlightPlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Carousel Plans: ${carouselPlans.length}', style: const TextStyle(fontSize: 12)),
      //     //     Text('Election Type: $userElectionType', style: const TextStyle(fontSize: 12)),
      //     //     Text('Current Plan: $currentPlanId', style: const TextStyle(fontSize: 12)),
      //     //   ],
      //     // ),
      //   ));
      //   return true;
      // }());

      // Highlight the plans section with a border and background
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Column(children: debugWidgets),
      );
    });
  }
}
