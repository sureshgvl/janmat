import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/plan_model.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/plan_card_with_validity_options.dart';

class PlanSelectionScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  final String electionType;

  const PlanSelectionScreen({
    required this.plan,
    required this.electionType,
    super.key,
  });

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  final MonetizationController _controller = Get.find<MonetizationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.plan.name} - Choose Validity Period'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Election Type: ${widget.electionType.replaceAll('_', ' ').toUpperCase()}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Validity Options
            PlanCardWithValidityOptions(
              plan: widget.plan,
              electionType: widget.electionType,
              onPurchase: (plan, validityDays) => _handlePurchase(plan, validityDays),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(SubscriptionPlan plan, int validityDays) async {
    final currentUser = _controller.currentFirebaseUser.value;
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
    final price = plan.pricing[widget.electionType]?[validityDays];
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
          'Purchase ${plan.name} for ${widget.electionType.replaceAll('_', ' ')} election?\n\n'
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
      debugPrint('💳 Starting payment process for plan: ${plan.planId}, election: ${widget.electionType}, validity: $validityDays');
      final success = await _controller.processPaymentWithElection(plan.planId, widget.electionType, validityDays);

      if (success) {
        // Payment initiated successfully - result will be handled by callbacks
        debugPrint('✅ Payment process initiated successfully');
        // Close this screen
        Navigator.of(context).pop();
      } else {
        Get.snackbar(
          'Payment Error',
          _controller.errorMessage.value.isNotEmpty
              ? _controller.errorMessage.value
              : 'Failed to initiate payment. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}

