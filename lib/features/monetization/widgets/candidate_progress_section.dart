import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/monetization_controller.dart';

class CandidateProgressSection extends StatelessWidget {
  final MonetizationController controller;

  const CandidateProgressSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = controller.candidatePlanProgress;
      final remaining = controller.remainingCandidateSlots;
      final isAvailable = controller.isFirst1000PlanAvailable;

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? 'Limited Time Offer!' : 'Plan Sold Out!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                isAvailable
                    ? 'Only ₹1,999 for first 1,000 candidates!'
                    : '₹1,999 plan is now sold out. ₹5,000 plan available.',
                style: const TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 16),

              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAvailable ? Colors.orange : Colors.red,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.totalPremiumCandidates.value} candidates upgraded',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    isAvailable ? '$remaining slots left' : 'Sold out',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (isAvailable && remaining <= 100)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only $remaining slots remaining! Upgrade now before price increases.',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

