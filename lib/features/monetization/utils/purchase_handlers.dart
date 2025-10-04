import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/plan_model.dart';
import '../controllers/monetization_controller.dart';

class PurchaseHandlers {
  final MonetizationController _controller;
  final String? _userElectionType;
  final String Function(String) _formatElectionType;
  final int Function(SubscriptionPlan) _countEnabledFeatures;

  PurchaseHandlers({
    required MonetizationController controller,
    required String? userElectionType,
    required String Function(String) formatElectionType,
    required int Function(SubscriptionPlan) countEnabledFeatures,
  })  : _controller = controller,
        _userElectionType = userElectionType,
        _formatElectionType = formatElectionType,
        _countEnabledFeatures = countEnabledFeatures;

  Future<void> handlePurchase(BuildContext context, SubscriptionPlan plan) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
          'Are you sure you want to purchase ${plan.name}?\n\n'
          '${_countEnabledFeatures(plan)} premium features will be unlocked.\n\n'
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
      // For XP plans, use the old single price method
      final success = await _controller.processPayment(plan.planId, 0); // Will be updated

      if (success) {
        // Payment initiated successfully - result will be handled by callbacks
        debugPrint('✅ Payment process initiated successfully');
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

  Future<void> handlePurchaseWithValidity(BuildContext context, SubscriptionPlan plan, int validityDays) async {
    final currentUser = FirebaseAuth.instance.currentUser;
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
    final price = plan.pricing[_userElectionType]?[validityDays];
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
          'Purchase ${plan.name} for ${_formatElectionType(_userElectionType!)} election?\n\n'
          'Validity: $validityDays days\n'
          'Expires: ${expiryDate.toString().split(' ')[0]}\n'
          'Amount: ₹${price}\n\n' // Price in rupees (no division)
          '${_countEnabledFeatures(plan)} premium features will be unlocked.\n\n'
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
      debugPrint('💳 Starting payment process for plan: ${plan.planId}, election: $_userElectionType, validity: $validityDays');
      final success = await _controller.processPaymentWithElection(plan.planId, _userElectionType!, validityDays);

      if (success) {
        // Payment initiated successfully - result will be handled by callbacks
        debugPrint('✅ Payment process initiated successfully');
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

