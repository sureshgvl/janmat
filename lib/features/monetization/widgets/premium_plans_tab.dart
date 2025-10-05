import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
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
    debugPrint('🏗️ PremiumPlansTab: Building with electionType: $userElectionType');

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

          // Premium Plans Section
          CandidatePlansSection(
            controller: controller,
            userElectionType: userElectionType,
            onPurchaseWithValidity: (plan, validityDays) =>
              _handlePurchaseWithValidity(context, plan, validityDays),
            onPurchase: (plan) =>
              _handlePurchase(context, plan),
          ),

          const SizedBox(height: 24),

          // Debug Info (only in debug mode)
          _buildDebugInfo(),
        ],
      ),
    );
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
          'Select a validity period to unlock premium features',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Obx(() {
      final allPlans = controller.plans.toList();

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
                '🔍 Debug Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text('Total Plans: ${allPlans.length}', style: const TextStyle(fontSize: 12)),
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
        );
        return true;
      }());

      return debugWidget;
    });
  }

  void _handlePurchaseWithValidity(BuildContext context, dynamic plan, int validityDays) {
    debugPrint('PremiumPlansTab: Purchase with validity - ${plan.name}, $validityDays days');

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
        title: Text('Purchase ${plan.name}'),
        content: Text(
          'Purchase ${plan.name} for ${userElectionType?.replaceAll('_', ' ').toUpperCase() ?? 'MUNICIPAL CORPORATION'} election?\n\n'
          'Validity: $validityDays days\n'
          'Expires: ${expiryDate.toString().split(' ')[0]}\n'
          'Amount: ₹${price}\n\n'
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
      // Start the payment process with election type and validity days
      debugPrint('💳 Starting payment process for plan: ${plan.planId}, election: ${userElectionType}, validity: $validityDays');
      final success = await controller.processPaymentWithElection(plan.planId, userElectionType ?? 'municipal_corporation', validityDays);

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

  void _handlePurchase(BuildContext context, dynamic plan) {
    // This will be handled by the parent screen
    debugPrint('PremiumPlansTab: Purchase - ${plan.name}');
  }
}