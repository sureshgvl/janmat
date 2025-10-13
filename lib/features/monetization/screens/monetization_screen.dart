import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/premium_plans_tab.dart';
import '../widgets/xp_plans_tab.dart';
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
  Rx<String?> _userElectionType = Rx<String?>(null);
  late PurchaseHandlers _purchaseHandlers;

  @override
  void initState() {
    super.initState();
    // Only show Premium Plans tab for candidates
    _tabController = TabController(length: 1, vsync: this);
    _loadUserData();
  }

  void _initializePurchaseHandlers() {
    _purchaseHandlers = PurchaseHandlers(
      controller: _controller,
      userElectionType: _userElectionType.value,
      formatElectionType: MonetizationUtils.formatElectionType,
      countEnabledFeatures: MonetizationUtils.countEnabledFeatures,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Tab listener removed since we only have one tab for candidates

  Future<void> _loadUserData() async {
    try {
      AppLogger.monetization('🔄 MONETIZATION SCREEN: Loading user data...');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        AppLogger.monetization('👤 User found: ${currentUser.uid}');
        await _controller.loadUserXPBalance(currentUser.uid);
        await _controller.loadUserStatusData();

        // Get user's election type for plan filtering
        final electionType = await _controller.getUserElectionType(currentUser.uid);
        _userElectionType.value = electionType;
        AppLogger.monetization('🏛️ User election type: $electionType (reactive: ${_userElectionType.value})');

        // Load plans with user data (force refresh to ensure latest data)
        AppLogger.monetization('📋 Loading plans with force refresh...');
        await _controller.loadPlans(forceRefresh: true);
        AppLogger.monetization('📋 Plans loaded. Total plans: ${_controller.plans.length}');

        // Log plan details for debugging
        for (var plan in _controller.plans) {
          AppLogger.monetization('   📋 Plan: ${plan.name} (${plan.planId}) - Type: ${plan.type}');
          if (plan.pricing.containsKey(_userElectionType)) {
            AppLogger.monetization('      💰 Has pricing for $_userElectionType: ${plan.pricing[_userElectionType]!.keys.join(", ")}');
          } else {
            AppLogger.monetization('      ❌ No pricing for $_userElectionType');
          }
        }

        // Initialize purchase handlers with user data
        _initializePurchaseHandlers();

        AppLogger.monetization('✅ User data loaded successfully');
      } else {
        AppLogger.monetization('❌ No authenticated user found in monetization screen');
      }
    } catch (e) {
      AppLogger.monetization('❌ Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final userRole = _controller.currentUserModel.value?.role ?? 'voter';
      final isCandidate = userRole == 'candidate';

      return Scaffold(
         appBar: AppBar(
           title: Text(AppLocalizations.of(context)!.premiumFeatures),
          //  bottom: TabBar(
          //    controller: _tabController,
          //    tabs: _buildTabs(isCandidate),
          //  ),
           actions: [
             IconButton(
               icon: const Icon(Icons.refresh),
               tooltip: 'Refresh Plans',
               onPressed: _refreshPlans,
             ),
            //  if (isCandidate) ...[
            //    IconButton(
            //      icon: const Icon(Icons.settings),
            //      tooltip: 'Settings',
            //      onPressed: () {
            //        // Settings action
            //      },
            //    ),
            // ],
           ],
         ),
         body: LoadingOverlay(
           isLoading: _controller.isLoading.value,
           child: TabBarView(
             controller: _tabController,
             children: _buildTabViews(context, isCandidate),
           ),
         ),
       );
    });
  }

  List<Tab> _buildTabs(bool isCandidate) {
    if (isCandidate) {
      return [
        const Tab(text: 'Premium Plans'),
      ];
    } else {
      return [
        const Tab(text: 'XP Plans'),
      ];
    }
  }

  List<Widget> _buildTabViews(BuildContext context, bool isCandidate) {
    if (isCandidate) {
      return [
        PremiumPlansTab(
          controller: _controller,
          userElectionType: _userElectionType.value,
        ),
      ];
    } else {
      return [
        XpPlansTab(
          controller: _controller,
          isCandidate: false,
        ),
      ];
    }
  }

  // Purchase handlers are now in PurchaseHandlers class

  // Temporary method to initialize default plans (remove after first use)
  void _initializeDefaultPlans() async {
    AppLogger.monetization('🔧 INITIALIZING DEFAULT PLANS FROM MONETIZATION SCREEN...');
    AppLogger.monetization('   User clicked initialize button - starting plan creation process');

    try {
      await _controller.initializeDefaultPlans();
      AppLogger.monetization('✅ INITIALIZATION COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Default plans initialized successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.monetization('❌ INITIALIZATION FAILED: $e');
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
    AppLogger.monetization('🔄 REFRESHING PLANS FROM MONETIZATION SCREEN...');
    AppLogger.monetization('   User clicked refresh button - forcing cache refresh');

    try {
      // Show loading indicator
      setState(() {});

      // Refresh user data and plans
      await _loadUserData();

      AppLogger.monetization('✅ REFRESH COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Premium plans refreshed successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.monetization('❌ REFRESH FAILED: $e');
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
    AppLogger.monetization('🔄 MIGRATING CANDIDATES TO STATE-BASED STRUCTURE...');
    AppLogger.monetization('   User clicked migrate button - moving candidates from old structure');

    try {
      await CandidateMigrationManager.migrateCandidatesToStates();
      await CandidateMigrationManager.verifyMigration();
      AppLogger.monetization('✅ MIGRATION COMPLETED SUCCESSFULLY');
      Get.snackbar(
        'Success',
        'Candidates migrated to new structure!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      AppLogger.monetization('❌ MIGRATION FAILED: $e');
      Get.snackbar(
        'Error',
        'Failed to migrate candidates: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

