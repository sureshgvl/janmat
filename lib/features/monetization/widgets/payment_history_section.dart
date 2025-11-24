import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/payment_model.dart';
import '../controllers/monetization_controller.dart';

class PaymentHistorySection extends GetView<MonetizationController> {
  const PaymentHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _loadPaymentHistory(),
              icon: const Icon(Icons.refresh_outlined),
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment history list
        Obx(() {
          final payments = controller.paymentHistory;

          if (payments.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No payment history yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your successful payments will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _PaymentHistoryCard(payment: payment);
            },
          );
        }),
      ],
    );
  }

  void _loadPaymentHistory() async {
    final currentUser = controller.currentFirebaseUser.value;
    if (currentUser != null) {
      await controller.loadUserPaymentHistory(currentUser.uid);
    }
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final PaymentTransaction payment;

  const _PaymentHistoryCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isSuccessful = payment.status == 'success';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: isSuccessful ? Colors.white : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment.planName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSuccessful ? Colors.black : Colors.red[700],
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccessful
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSuccessful ? 'Success' : 'Failed',
                    style: TextStyle(
                      color: isSuccessful
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${payment.amountPaid.toInt()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (payment.electionType != null) ...[
                        Text(
                          'Election: ${_formatElectionType(payment.electionType!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (payment.validityDays != null) ...[
                        Text(
                          'Validity: ${payment.validityDays} days',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Timestamp and details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeago.format(payment.paymentDate),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isSuccessful ? Icons.check_circle : Icons.error,
                      color: isSuccessful
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),

            // Payment ID (truncated)
            if (isSuccessful) ...[
              const SizedBox(height: 8),
              Text(
                'Payment ID: ${payment.paymentId}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Failure reason
            if (!isSuccessful && payment.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        payment.failureReason!,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatElectionType(String electionType) {
    return electionType.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
