import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user_model.dart';
import '../controllers/monetization_controller.dart';

class UserStatusSection extends StatelessWidget {
  final MonetizationController controller;

  const UserStatusSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final statusSummary = controller.getUserStatusSummary();
      final userModel = controller.currentUserModel.value;

      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Account Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _buildStatusBadge(statusSummary),
                ],
              ),

              const SizedBox(height: 16),

              // Payment Mode Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: controller.useMockPayment.value
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.useMockPayment.value
                        ? Colors.green[200]!
                        : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          controller.useMockPayment.value
                              ? Icons.check_circle
                              : Icons.warning,
                          color: controller.useMockPayment.value
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Mode: ${controller.useMockPayment.value ? 'Mock (Testing)' : 'Real Razorpay'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: controller.useMockPayment.value
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: controller.useMockPayment.value,
                          onChanged: (value) {
                            controller.useMockPayment.value = value;
                            Get.snackbar(
                              'Payment Mode Changed',
                              value
                                  ? 'Now using Mock Payment (for testing)'
                                  : 'Now using Real Razorpay Payment',
                              backgroundColor: value
                                  ? Colors.green
                                  : Colors.orange,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                            );
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.useMockPayment.value
                          ? 'Mock mode simulates payment without Razorpay dialog. Use this for testing the complete flow.'
                          : 'Real mode shows actual Razorpay payment dialog with all payment options. Use this to test production UI.',
                      style: TextStyle(
                        fontSize: 12,
                        color: controller.useMockPayment.value
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // User Info
              if (userModel != null) ...[
                _buildStatusItem(Icons.person, 'Name', userModel.name),
                _buildStatusItem(Icons.phone, 'Phone', userModel.phone),
                _buildStatusItem(Icons.verified_user, 'Role', userModel.role),
                _buildStatusItem(
                  Icons.star,
                  'XP Balance',
                  '${userModel.xpPoints} XP',
                ),
                _buildStatusItem(
                  Icons.workspace_premium,
                  'Premium Status',
                  userModel.premium ? 'Premium' : 'Basic',
                ),
                if (userModel.subscriptionPlanId != null)
                  _buildStatusItem(
                    Icons.subscriptions,
                    'Current Plan',
                    userModel.subscriptionPlanId!,
                  ),
                if (userModel.isTrialActive)
                  _buildStatusItem(Icons.timer, 'Trial Status', 'Active'),
                _buildStatusItem(
                  Icons.check_circle,
                  'Profile Complete',
                  userModel.profileCompleted ? 'Yes' : 'No',
                ),
              ],

              const SizedBox(height: 16),

              // Subscription Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Subscriptions',
                      statusSummary['subscriptionCount'].toString(),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      statusSummary['activeSubscriptions'].toString(),
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Debug Logs Section
              ExpansionTile(
                title: const Text(
                  'Debug Logs',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.userStatusLogs.length,
                      itemBuilder: (context, index) {
                        final log = controller.userStatusLogs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 16,
                          ),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () => controller.clearUserStatusLogs(),
                      child: const Text('Clear Logs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusBadge(Map<String, dynamic> statusSummary) {
    final isPremium = statusSummary['premium'] as bool? ?? false;
    final isTrial = statusSummary['trialActive'] as bool? ?? false;

    Color badgeColor;
    String badgeText;

    if (isPremium) {
      badgeColor = Colors.green;
      badgeText = 'PREMIUM';
    } else if (isTrial) {
      badgeColor = Colors.orange;
      badgeText = 'TRIAL';
    } else {
      badgeColor = Colors.grey;
      badgeText = 'BASIC';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

