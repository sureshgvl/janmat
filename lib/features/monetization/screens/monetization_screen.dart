import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/plan_comparison_table.dart';
import '../widgets/plan_card.dart';
import '../widgets/election_type_banner.dart';
import '../widgets/candidate_plans_section.dart';
import '../widgets/user_status_section.dart';
import '../widgets/xp_balance_section.dart';
import '../widgets/xp_usage_info.dart';
import '../utils/plan_utils.dart';
import '../utils/purchase_handlers.dart';
import '../utils/monetization_utils.dart';
import '../../common/loading_overlay.dart';
import '../../../utils/migrate_candidates_to_states.dart';

class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen>
    with SingleTickerProviderStateMixin {
  final MonetizationController _controller = Get.put(MonetizationController());
  late TabController _tabController;
  String? _userElectionType;
  late PurchaseHandlers _purchaseHandlers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserData();
  }

  void _initializePurchaseHandlers() {
    _purchaseHandlers = PurchaseHandlers(
      controller: _controller,
      userElectionType: _userElectionType,
      formatElectionType: MonetizationUtils.formatElectionType,
      countEnabledFeatures: MonetizationUtils.countEnabledFeatures,
    );
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
    try {
      debugPrint('🔄 MONETIZATION SCREEN: Loading user data...');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        debugPrint('👤 User found: ${currentUser.uid}');
        await _controller.loadUserXPBalance(currentUser.uid);
        await _controller.loadUserStatusData();

        // Get user's election type for plan filtering
        _userElectionType = await _controller.getUserElectionType(currentUser.uid);
        debugPrint('🏛️ User election type: $_userElectionType');

        // Initialize purchase handlers with user data
        _initializePurchaseHandlers();

        debugPrint('✅ User data loaded successfully');
      } else {
        debugPrint('❌ No authenticated user found in monetization screen');
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
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
            Obx(() => Tab(text: _controller.plansTabText)),
            Tab(text: 'My Status'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Initialize Default Plans',
            onPressed: _initializeDefaultPlans,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh Plans (Hot Reload Fix)',
            onPressed: _refreshPlans,
          ),
          IconButton(
            icon: const Icon(Icons.move_up),
            tooltip: 'Migrate Candidates to States',
            onPressed: _migrateCandidates,
          ),
        ],
      ),
      body: Obx(() {
        return LoadingOverlay(
          isLoading: _controller.isLoading.value,
          child: TabBarView(
            controller: _tabController,
            children: [
              Obx(() => _controller.showAllPlans ? _buildPlansComparison() : _buildCandidatePlans()),
              _buildUserStatus(),
            ],
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

  Widget _buildCandidatePlans() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Election Type Banner
          if (_userElectionType != null) ...[
            ElectionTypeBanner(
              electionType: _userElectionType!,
              formatElectionType: MonetizationUtils.formatElectionType,
            ),
            const SizedBox(height: 12),
          ],

          // Section Header - Compact
          const Text(
            'Premium Plans',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Select a validity period to unlock premium features',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const SizedBox(height: 12),

          // Candidate Plans Section
          CandidatePlansSection(
            controller: _controller,
            userElectionType: _userElectionType,
            onPurchaseWithValidity: (plan, validityDays) =>
              _purchaseHandlers.handlePurchaseWithValidity(context, plan, validityDays),
            onPurchase: (plan) =>
              _purchaseHandlers.handlePurchase(context, plan),
          ),

          const SizedBox(height: 24),

          // XP Plans Section (for voters who might also want XP)
          if (_controller.showOnlyXPPlans) ...[
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'XP Plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            XPBalanceSection(controller: _controller),
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
                  onPurchase: () => _purchaseHandlers.handlePurchase(context, plan),
                )).toList(),
              );
            }),

            const SizedBox(height: 16),
            XPUsageInfo(),
          ],
        ],
      ),
    );
  }

  // Purchase handlers are now in PurchaseHandlers class

  // Temporary method to initialize default plans (remove after first use)
  void _initializeDefaultPlans() async {
    debugPrint('🔧 INITIALIZING DEFAULT PLANS FROM MONETIZATION SCREEN...');
    debugPrint('   User clicked initialize button - starting plan creation process');

    try {
      await _controller.initializeDefaultPlans();
      debugPrint('✅ INITIALIZATION COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Default plans initialized successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ INITIALIZATION FAILED: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize plans: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to refresh plans (useful for hot reload issues)
  void _refreshPlans() async {
    debugPrint('🔄 REFRESHING PLANS FROM MONETIZATION SCREEN...');
    debugPrint('   User clicked refresh button - fixing hot reload issues');

    try {
      await _controller.refreshPlans();
      debugPrint('✅ REFRESH COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Plans refreshed successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ REFRESH FAILED: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh plans: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method to migrate candidates to new state-based structure
  void _migrateCandidates() async {
    debugPrint('🔄 MIGRATING CANDIDATES TO STATE-BASED STRUCTURE...');
    debugPrint('   User clicked migrate button - moving candidates from old structure');

    try {
      await CandidateMigrationManager.migrateCandidatesToStates();
      await CandidateMigrationManager.verifyMigration();
      debugPrint('✅ MIGRATION COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Candidates migrated to new structure!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('❌ MIGRATION FAILED: $e');
      Get.snackbar(
        'Error',
        'Failed to migrate candidates: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Utility methods are now in MonetizationUtils class

  Widget _buildUserStatus() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Status Section
          UserStatusSection(controller: _controller),

          const SizedBox(height: 24),

          // XP Balance Section (for voters)
          if (_controller.showOnlyXPPlans) ...[
            XPBalanceSection(controller: _controller),
            const SizedBox(height: 24),
          ],

          // XP Usage Info (for voters)
          if (_controller.showOnlyXPPlans) ...[
            XPUsageInfo(),
          ],
        ],
      ),
    );
  }
}

