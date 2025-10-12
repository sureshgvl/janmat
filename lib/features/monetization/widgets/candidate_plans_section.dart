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
      AppLogger.monetization('🔍 [CandidatePlansSection] Checking plan eligibility for highlights...');

      // Ensure user model is loaded
      if (controller.currentUserModel.value == null) {
        AppLogger.monetization('⏳ [CandidatePlansSection] User model not loaded, loading now...');
        await controller.loadUserStatusData();
      }

      // Check user model for premium status
      final userModel = controller.currentUserModel.value;
      if (userModel != null) {
        // Highlight plans are available for any premium candidate (Basic, Gold, Platinum)
        final hasAccess = userModel.premium == true;
        AppLogger.monetization('✅ [CandidatePlansSection] User model check: premium=${userModel.premium}, planId=${userModel.subscriptionPlanId}, hasHighlightAccess=$hasAccess');

        if (hasAccess) {
          AppLogger.monetization('✅ [CandidatePlansSection] User has access to highlight plans');
          return true;
        } else {
          AppLogger.monetization('⚠️ [CandidatePlansSection] User needs premium status for highlights');
          return false;
        }
      }

      // Fallback: check active subscriptions for any premium plan
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetization('❌ [CandidatePlansSection] No current user');
        return false;
      }

      // Check for any active premium subscription (not just platinum)
      final candidateSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'candidate',
      );
      final hasCandidateAccess = candidateSubscription?.isActive ?? false;

      final highlightSubscription = await controller.getActiveSubscription(
        currentUser.uid,
        'highlight',
      );
      final hasHighlightAccess = highlightSubscription?.isActive ?? false;

      final hasAccess = hasCandidateAccess || hasHighlightAccess;
      AppLogger.monetization('✅ [CandidatePlansSection] Subscription check result: $hasAccess (candidate: ${candidateSubscription?.planId}, highlight: ${highlightSubscription?.planId})');
      return hasAccess;
    } catch (e) {
      AppLogger.monetization('❌ [CandidatePlansSection] Error checking plan eligibility: $e');
      return false;
    }
  }

  Widget _buildDisabledPlanCard(SubscriptionPlan plan) {
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
            const Text(
              'Requires Premium Plan',
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
                child: const Text(
                  'Subscribe to Premium First',
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allPlans = controller.plans.toList();

      AppLogger.monetization('📋 [CandidatePlansSection] Total plans loaded: ${allPlans.length}');
      AppLogger.monetization('📋 [CandidatePlansSection] User election type: $userElectionType');
      for (var plan in allPlans) {
        AppLogger.monetization('   Plan: ${plan.name} (${plan.planId}) - Type: ${plan.type}');
        if (plan.pricing.containsKey(userElectionType)) {
          AppLogger.monetization('      ✅ Has pricing for $userElectionType: ${plan.pricing[userElectionType]!.length} options');
        } else {
          AppLogger.monetization('      ❌ No pricing for $userElectionType');
        }
      }

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

      // Separate highlight plans (available to all candidates)
      final highlightPlans = allPlans.where((plan) => plan.type == 'highlight').toList();

      // Separate carousel plans (available to all candidates)
      final carouselPlans = allPlans.where((plan) => plan.type == 'carousel').toList();

      AppLogger.monetization('📊 [CandidatePlansSection] Plan breakdown:');
      AppLogger.monetization('   Free plans: ${freePlans.length}');
      AppLogger.monetization('   Basic plans: ${basicPlans.length}');
      AppLogger.monetization('   Premium plans: ${premiumPlans.length}');
      AppLogger.monetization('   Highlight plans: ${highlightPlans.length}');
      AppLogger.monetization('   Carousel plans: ${carouselPlans.length}');
      AppLogger.monetization('   User election type: $userElectionType');

      final List<Widget> planWidgets = [];

      // Add free plans (no pricing)
      if (freePlans.isNotEmpty) {
        for (final plan in freePlans) {
          planWidgets.add(PlanCard(
            plan: plan,
            controller: controller,
            isCandidatePlan: false,
            onPurchase: null, // Free plans don't need purchase
          ));
          if (plan != freePlans.last) {
            planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
          }
        }
        // Add section separator if there are more plan types
        if (basicPlans.isNotEmpty || premiumPlans.isNotEmpty || highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }
      }

      // Add basic plans (with pricing if available)
      if (basicPlans.isNotEmpty) {
        for (final plan in basicPlans) {
          AppLogger.monetization('🎯 Checking basic plan: ${plan.name} (${plan.planId})');
          AppLogger.monetization('   User Election Type: "$userElectionType"');
          AppLogger.monetization('   Plan pricing keys: ${plan.pricing.keys.toList()}');
          AppLogger.monetization('   Has pricing for user election type: ${plan.pricing.containsKey(userElectionType)}');

          if (userElectionType != null) {
            AppLogger.monetization('   ✅ User election type is not null');
            final hasPricing = plan.pricing.containsKey(userElectionType);
            AppLogger.monetization('   ✅ Plan has pricing for election type: $hasPricing');
            if (hasPricing) {
              final pricingCount = plan.pricing[userElectionType]!.length;
              AppLogger.monetization('   ✅ Pricing count for election type: $pricingCount');
              if (pricingCount > 0) {
                AppLogger.monetization('   ✅✅ Showing PlanCardWithValidityOptions for basic plan');
                // Basic plan with new pricing structure
                planWidgets.add(PlanCardWithValidityOptions(
                  plan: plan,
                  electionType: userElectionType!,
                  onPurchase: onPurchaseWithValidity,
                ));
                continue;
              } else {
                AppLogger.monetization('   ❌ Pricing count is 0');
              }
            } else {
              AppLogger.monetization('   ❌ Plan does not have pricing for user election type');
            }
          } else {
            AppLogger.monetization('   ❌ User election type is null');
          }

          AppLogger.monetization('   ⚠️ Showing regular PlanCard for basic plan');
          // Basic plan without new pricing (legacy)
          planWidgets.add(PlanCard(
            plan: plan,
            controller: controller,
            isCandidatePlan: true,
            onPurchase: () => onPurchase(plan),
          ));

          if (plan != basicPlans.last) {
            planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
          }
        }
        // Add section separator if there are premium plans
        if (premiumPlans.isNotEmpty || highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }
      }

      // Add premium plans (Gold and Platinum - available to all candidates)
      if (premiumPlans.isNotEmpty) {
        for (final plan in premiumPlans) {
          // Gold and Platinum plans are available to all candidates
          if (plan.planId == 'gold_plan' || plan.planId == 'platinum_plan') {
            if (userElectionType != null &&
                plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty) {
              // Show with validity options if pricing is available
              planWidgets.add(PlanCardWithValidityOptions(
                plan: plan,
                electionType: userElectionType!,
                onPurchase: onPurchaseWithValidity,
              ));
            } else {
              // Show regular plan card if no election-specific pricing
              planWidgets.add(PlanCard(
                plan: plan,
                controller: controller,
                isCandidatePlan: true,
                onPurchase: () => onPurchase(plan),
              ));
            }
            if (plan != premiumPlans.last) {
              planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
            }
          } else {
            // Other premium plans - only show if they have pricing for user's election type
            if (userElectionType != null &&
                plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty) {
              planWidgets.add(PlanCardWithValidityOptions(
                plan: plan,
                electionType: userElectionType!,
                onPurchase: onPurchaseWithValidity,
              ));
              if (plan != premiumPlans.last) {
                planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
              }
            }
          }
        }
      }

      // Add highlight plans (only available to Platinum plan holders)
      if (highlightPlans.isNotEmpty) {
        // Add section separator if there are premium plans
        if (premiumPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }

        // Add highlight plans header with feature info
        planWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Professional Highlight Features - Up to 4 banners on home screen',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        for (final plan in highlightPlans) {
          planWidgets.add(FutureBuilder<bool>(
            future: _hasRequiredPlanForHighlights(),
            builder: (context, snapshot) {
              final hasAccess = snapshot.data ?? false;

              if (hasAccess) {
                // Show highlight plan with validity options if pricing is available
                if (userElectionType != null &&
                    plan.pricing.containsKey(userElectionType) &&
                    plan.pricing[userElectionType]!.isNotEmpty) {
                  return PlanCardWithValidityOptions(
                    plan: plan,
                    electionType: userElectionType!,
                    onPurchase: onPurchaseWithValidity,
                  );
                } else {
                  // Fallback to regular plan card
                  return PlanCard(
                    plan: plan,
                    controller: controller,
                    isCandidatePlan: true,
                    onPurchase: () => onPurchase(plan),
                  );
                }
              } else {
                return _buildDisabledPlanCard(plan);
              }
            },
          ));
          if (plan != highlightPlans.last) {
            planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
          }
        }
      }

      // Add carousel plans (available to all candidates)
      if (carouselPlans.isNotEmpty) {
        // Add section separator if there are highlight plans
        if (highlightPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }

        for (final plan in carouselPlans) {
          if (userElectionType != null &&
              plan.pricing.containsKey(userElectionType) &&
              plan.pricing[userElectionType]!.isNotEmpty) {
            planWidgets.add(PlanCardWithValidityOptions(
              plan: plan,
              electionType: userElectionType!,
              onPurchase: onPurchaseWithValidity,
            ));
            if (plan != carouselPlans.last) {
              planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
            }
          }
        }
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
      assert(() {
        debugWidgets.add(const SizedBox(height: 24));
        debugWidgets.add(Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔍 Debug Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text('Total Plans: ${allPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Free Plans: ${freePlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Basic Plans: ${basicPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Premium Plans: ${premiumPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Highlight Plans: ${highlightPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Carousel Plans: ${carouselPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('Election Type: $userElectionType', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Plan Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...allPlans.map((plan) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• ${plan.name} (${plan.planId}) - ${plan.type}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )),
            ],
          ),
        ));
        return true;
      }());

      return Column(children: debugWidgets);
    });
  }
}
