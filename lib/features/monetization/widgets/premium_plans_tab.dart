import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../controllers/monetization_controller.dart';
import 'candidate_plans_section.dart';

class PremiumPlansTab extends StatelessWidget {
  final MonetizationController controller;
  final String? userElectionType;

  const PremiumPlansTab({
    super.key,
    required this.controller,
    this.userElectionType,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.monetization('🏗️ PremiumPlansTab: Building with electionType: $userElectionType');

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final hasPlans = controller.plans.isNotEmpty;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Election Type Banner
            if (userElectionType != null) ...[
              _buildElectionTypeBanner(context, userElectionType!),
              const SizedBox(height: 12),
            ],

            // Section Header
            _buildSectionHeader(context),

            const SizedBox(height: 12),

            // Loading indicator while loading plans
            if (isLoading && !hasPlans) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading premium plans...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // Premium Plans Section
            else if (hasPlans) ...[
              CandidatePlansSection(
                controller: controller,
                userElectionType: userElectionType,
                onPurchaseWithValidity: (plan, validityDays) =>
                  _handlePurchaseWithValidity(context, plan, validityDays),
                onPurchase: (plan) =>
                  _handlePurchase(context, plan),
              ),
            ]
            // No plans available
            else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No premium plans available at the moment.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Debug Info (only in debug mode)
            //_buildDebugInfo(),
          ],
        ),
      );
    });
  }

  Widget _buildElectionTypeBanner(BuildContext context, String electionType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Election Type: ${electionType.replaceAll('_', ' ').toUpperCase()}',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.premiumFeatures,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.selectValidityPeriod,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  void _handlePurchaseWithValidity(BuildContext context, dynamic plan, int validityDays) {
    AppLogger.monetization('PremiumPlansTab: Purchase with validity - ${plan.name}, $validityDays days');

    // Show purchase confirmation directly (skip PlanSelectionScreen since validity is already selected)
    _showPurchaseConfirmation(context, plan, validityDays);
  }

  void _showPurchaseConfirmation(BuildContext context, dynamic plan, int validityDays) async {
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

    // Get price from plan pricing
    final price = plan.pricing[userElectionType ?? 'municipal_corporation']?[validityDays];
    if (price == null) {
      Get.snackbar(
        'Error',
        'Invalid plan configuration',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final expiryDate = DateTime.now().add(Duration(days: validityDays));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.purchasePlan(plan.name)),
        content: Text(
          '${AppLocalizations.of(context)!.purchasePlan(plan.name)} ${userElectionType?.replaceAll('_', ' ').toUpperCase() ?? 'MUNICIPAL CORPORATION'}?\n\n'
          '${AppLocalizations.of(context)!.validityDays(validityDays)}\n'
          '${AppLocalizations.of(context)!.expiresOn(expiryDate.toString().split(' ')[0])}\n'
          '${AppLocalizations.of(context)!.amount(price)}\n\n'
          '${AppLocalizations.of(context)!.securePaymentGateway}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.proceedToPayment),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Start the payment process with election type and validity days
      AppLogger.monetization('💳 Starting payment process for plan: ${plan.planId}, election: $userElectionType, validity: $validityDays');
      final success = await controller.processPaymentWithElection(plan.planId, userElectionType ?? 'municipal_corporation', validityDays);

      if (success) {
        // Payment initiated successfully - result will be handled by callbacks
        AppLogger.monetization('✅ Payment process initiated successfully');
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

  void _handlePurchase(BuildContext context, dynamic plan) {
    // This will be handled by the parent screen
    AppLogger.monetization('PremiumPlansTab: Purchase - ${plan.name}');
  }
}
