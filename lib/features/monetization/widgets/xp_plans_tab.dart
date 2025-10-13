import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/plan_card.dart';
import '../widgets/xp_balance_section.dart';
import '../widgets/xp_usage_info.dart';
import '../utils/plan_utils.dart';

class XpPlansTab extends StatelessWidget {
  final MonetizationController controller;
  final bool isCandidate;

  const XpPlansTab({
    super.key,
    required this.controller,
    this.isCandidate = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          _buildSectionHeader(context),

          const SizedBox(height: 16),

          // XP Balance Section (for voters)
          if (!isCandidate) ...[
            XPBalanceSection(controller: controller),
            const SizedBox(height: 24),
          ],

          // XP Plans Section
          _buildXpPlansSection(context),

          const SizedBox(height: 24),

          // XP Usage Info
          XPUsageInfo(),

          // Debug Info (only in debug mode)
          //_buildDebugInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCandidate ? 'XP Points Plans' : AppLocalizations.of(context)!.premiumFeatures,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          isCandidate
              ? 'Earn XP points to unlock additional features'
              : 'Purchase XP points to unlock premium features',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildXpPlansSection(BuildContext context) {
    return Obx(() {
      final voterPlans = PlanUtils.filterPlansByType(controller.plans, 'voter');

      if (controller.isLoading.value && voterPlans.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (voterPlans.isEmpty) {
        return const Center(
          child: Text('No XP plans available at the moment'),
        );
      }

      return Column(
        children: voterPlans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlanCard(
            plan: plan,
            controller: controller,
            isCandidatePlan: false,
            onPurchase: () => _handlePurchase(context, plan),
          ),
        )).toList(),
      );
    });
  }

  Widget _buildDebugInfo() {
    return Obx(() {
      final voterPlans = PlanUtils.filterPlansByType(controller.plans, 'voter');

      // Debug section (only in debug mode)
      Widget debugWidget = const SizedBox.shrink();
      assert(() {
        debugWidget = Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔍 XP Plans Debug Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text('XP Plans Count: ${voterPlans.length}', style: const TextStyle(fontSize: 12)),
              Text('User Role: ${isCandidate ? 'Candidate' : 'Voter'}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text('XP Plan Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...voterPlans.map((plan) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• ${plan.name} (${plan.planId}) - ₹${plan.pricing.values.first.values.first}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )),
            ],
          ),
        );
        return true;
      }());

      return debugWidget;
    });
  }

  void _handlePurchase(BuildContext context, dynamic plan) {
    // This will be handled by the parent screen
    AppLogger.monetization('XpPlansTab: Purchase XP plan - ${plan.name}');
  }
}
