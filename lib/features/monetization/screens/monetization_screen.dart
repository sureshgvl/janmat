import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/monetization_controller.dart';
import '../../../models/plan_model.dart';
import '../../common/loading_overlay.dart';

class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen>
    with SingleTickerProviderStateMixin {
  final MonetizationController _controller = Get.put(MonetizationController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Load user data when switching to voter tab (index 1)
    if (_tabController.index == 1) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _controller.loadUserXPBalance(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'For Candidates'),
            Tab(text: 'For Voters'),
          ],
        ),
      ),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: _controller.isLoading.value,
          child: TabBarView(
            controller: _tabController,
            children: [_buildCandidatePlans(), _buildVoterPlans()],
          ),
        );
      }),
    );
  }

  Widget _buildCandidatePlans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Section
          _buildCandidateProgressSection(),

          const SizedBox(height: 24),

          // Plans Section
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Obx(() {
            final candidatePlans = _controller.plans
                .where((plan) => plan.type == 'candidate' && plan.isActive)
                .toList();

            if (candidatePlans.isEmpty) {
              return const Center(
                child: Text('No plans available at the moment'),
              );
            }

            return Column(
              children: candidatePlans
                  .map((plan) => _buildPlanCard(plan))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCandidateProgressSection() {
    return Obx(() {
      final progress = _controller.candidatePlanProgress;
      final remaining = _controller.remainingCandidateSlots;
      final isAvailable = _controller.isFirst1000PlanAvailable;

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
                    '${_controller.totalPremiumCandidates.value} candidates upgraded',
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

  Widget _buildVoterPlans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Balance Section
          _buildXPBalanceSection(),

          const SizedBox(height: 24),

          // XP Plans Section
          const Text(
            'Buy XP Points',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Obx(() {
            final voterPlans = _controller.plans
                .where((plan) => plan.type == 'voter' && plan.isActive)
                .toList();

            if (voterPlans.isEmpty) {
              return const Center(
                child: Text('No XP plans available at the moment'),
              );
            }

            return Column(
              children: voterPlans.map((plan) => _buildPlanCard(plan)).toList(),
            );
          }),

          const SizedBox(height: 24),

          // XP Usage Info
          _buildXPUsageInfo(),
        ],
      ),
    );
  }

  Widget _buildXPBalanceSection() {
    return Obx(() {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.stars, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your XP Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_controller.userXPBalance.value} XP',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCandidatePlan = plan.type == 'candidate';
    final isLimitedOffer =
        isCandidatePlan && _controller.isFirst1000PlanAvailable;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLimitedOffer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIMITED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              '₹${plan.price}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isLimitedOffer ? Colors.orange : Colors.green,
              ),
            ),

            if (plan.xpAmount != null)
              Text(
                '${plan.xpAmount} XP Points',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),

            const SizedBox(height: 16),

            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      feature.enabled ? Icons.check_circle : Icons.cancel,
                      color: feature.enabled ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handlePurchase(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLimitedOffer ? Colors.orange : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isCandidatePlan ? 'Upgrade to Premium' : 'Buy Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPUsageInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to use XP Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildXPUsageItem(
              Icons.lock_open,
              'Unlock Premium Content',
              'Access exclusive candidate manifestos and media',
            ),

            _buildXPUsageItem(
              Icons.chat,
              'Join Premium Chat Rooms',
              'Participate in candidate-only discussions',
            ),

            _buildXPUsageItem(
              Icons.poll,
              'Vote in Exclusive Polls',
              'Influence decisions with premium voting rights',
            ),

            _buildXPUsageItem(
              Icons.favorite,
              'Reward Other Voters',
              'Give XP points to helpful community members',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXPUsageItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(SubscriptionPlan plan) async {
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
          'Are you sure you want to purchase ${plan.name} for ₹${plan.price}?\n\n'
          '${plan.features.length} premium features will be unlocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Process the purchase
      final success = await _controller.purchaseSubscription(
        currentUser.uid,
        plan,
      );

      if (success) {
        Get.snackbar(
          'Success',
          '${plan.name} purchased successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh user data
        await _loadUserData();
      } else {
        Get.snackbar(
          'Error',
          _controller.errorMessage.value.isNotEmpty
              ? _controller.errorMessage.value
              : 'Purchase failed. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }
}
