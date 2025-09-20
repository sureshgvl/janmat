import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/plan_model.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/plan_comparison_table.dart';
import '../widgets/plan_card.dart';
import '../widgets/user_status_section.dart';
import '../widgets/xp_balance_section.dart';
import '../widgets/xp_usage_info.dart';
import '../utils/plan_utils.dart';
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
      await _controller.loadUserStatusData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumFeatures),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Premium Plans'),
            Tab(text: 'XP Store'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Initialize Default Plans',
            onPressed: _initializeDefaultPlans,
          ),
        ],
      ),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: _controller.isLoading.value,
          child: TabBarView(
            controller: _tabController,
            children: [_buildPlansComparison(), _buildVoterPlans()],
          ),
        );
      }),
    );
  }

  Widget _buildPlansComparison() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Status Section
          UserStatusSection(controller: _controller),

          const SizedBox(height: 24),

          // Plans Comparison Section
          PlanComparisonTable(controller: _controller),
        ],
      ),
    );
  }

  Widget _buildVoterPlans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // XP Balance Section
          XPBalanceSection(controller: _controller),

          const SizedBox(height: 24),

          // XP Plans Section
          Text(
            'Buy XP Points',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Obx(() {
            final voterPlans = PlanUtils.filterPlansByType(_controller.plans, 'voter');

            if (voterPlans.isEmpty) {
              return const Center(
                child: Text('No XP plans available at the moment'),
              );
            }

            return Column(
              children: voterPlans.map((plan) => PlanCard(
                plan: plan,
                controller: _controller,
                isCandidatePlan: false,
                onPurchase: () => _handlePurchase(plan),
              )).toList(),
            );
          }),

          const SizedBox(height: 24),

          // XP Usage Info
          XPUsageInfo(),
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
          '${plan.features.length} premium features will be unlocked.\n\n'
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
      final success = await _controller.processPayment(plan.planId, plan.price);

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

  // Temporary method to initialize default plans (remove after first use)
  void _initializeDefaultPlans() async {
    debugPrint('🔧 INITIALIZING DEFAULT PLANS FROM MONETIZATION SCREEN...');
    await _controller.initializeDefaultPlans();
    Get.snackbar(
      'Success',
      'Default plans initialized successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
