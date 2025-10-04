import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/plan_model.dart';
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allPlans = controller.plans.toList();

      if (allPlans.isEmpty) {
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
        if (basicPlans.isNotEmpty || premiumPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }
      }

      // Add basic plans (with pricing if available)
      if (basicPlans.isNotEmpty) {
        for (final plan in basicPlans) {
          debugPrint('🎯 Checking basic plan: ${plan.name} (${plan.planId})');
          debugPrint('   Election Type: $userElectionType');
          debugPrint('   Has pricing for election type: ${plan.pricing.containsKey(userElectionType)}');
          debugPrint('   Pricing keys: ${plan.pricing.keys.toList()}');

          if (userElectionType != null &&
              plan.pricing.containsKey(userElectionType) &&
              plan.pricing[userElectionType]!.isNotEmpty) {
            debugPrint('   ✅ Showing PlanCardWithValidityOptions for basic plan');
            // Basic plan with new pricing structure
            planWidgets.add(PlanCardWithValidityOptions(
              plan: plan,
              electionType: userElectionType!,
              onPurchase: onPurchaseWithValidity,
            ));
          } else {
            debugPrint('   ⚠️ Showing regular PlanCard for basic plan (no pricing or election type)');
            // Basic plan without new pricing (legacy)
            planWidgets.add(PlanCard(
              plan: plan,
              controller: controller,
              isCandidatePlan: true,
              onPurchase: () => onPurchase(plan),
            ));
          }
          if (plan != basicPlans.last) {
            planWidgets.add(const SizedBox(height: 12)); // Reduced spacing within section
          }
        }
        // Add section separator if there are premium plans
        if (premiumPlans.isNotEmpty) {
          planWidgets.add(const SizedBox(height: 20)); // Section separator
        }
      }

      // Add premium plans (with validity options)
      if (premiumPlans.isNotEmpty) {
        for (final plan in premiumPlans) {
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
          } else {
            // Plan without pricing for user's election type - don't show
            continue;
          }
        }
      }

      if (planWidgets.isEmpty) {
        return const Center(
          child: Text('No plans available for your election type'),
        );
      }

      return Column(children: planWidgets);
    });
  }
}

