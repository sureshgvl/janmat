import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../core/app_theme.dart';
import '../controllers/monetization_controller.dart';
import '../widgets/premium_plans_tab.dart';
import '../utils/purchase_handlers.dart';
import '../utils/monetization_utils.dart';
import '../../common/loading_overlay.dart';

class MonetizationScreen extends StatefulWidget {
  const MonetizationScreen({super.key});

  @override
  State<MonetizationScreen> createState() => _MonetizationScreenState();
}

class _MonetizationScreenState extends State<MonetizationScreen> {
  final MonetizationController _controller = Get.put(MonetizationController());
  final Rx<String?> _userElectionType = Rx<String?>(null);
  late PurchaseHandlers _purchaseHandlers;

  @override
  void initState() {
    super.initState();
    // Test all logging methods to ensure they work on web
    AppLogger.monetization('📱 MonetizationScreen: initState called');
    AppLogger.common('🔧 MONETIZATION_SCREEN: Common log test');
    AppLogger.core('🏗️ MONETIZATION_SCREEN: Core log test');
    // Force show=true and test modified candidate method
    AppLogger.candidate('👥 MONETIZATION_SCREEN: Candidate log test', isShow: true);
    AppLogger.ui('🎨 MONETIZATION_SCREEN: UI log test');
    AppLogger.network('🌐 MONETIZATION_SCREEN: Network log test');
    AppLogger.cache('🏗️ MONETIZATION_SCREEN: Cache log test');
    AppLogger.database('💾 MONETIZATION_SCREEN: Database log test');
    AppLogger.performance('⚡ MONETIZATION_SCREEN: Performance log test');
    print('🐛 MANUAL PRINT: If you see this, console logging works!');

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
           actions: [
             IconButton(
               icon: const Icon(Icons.refresh),
               tooltip: AppLocalizations.of(context)!.refreshPlans,
               onPressed: _refreshPlans,
             ),
           ],
         ),
         backgroundColor: AppTheme.homeBackgroundColor,
         body: LoadingOverlay(
           isLoading: _controller.isLoading.value,
           child: PremiumPlansTab(
             controller: _controller,
             userElectionType: _userElectionType.value,
           ),
         ),
       );
    });
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
      SnackbarUtils.showSuccess(AppLocalizations.of(context)!.premiumPlansRefreshed);
    } catch (e) {
      AppLogger.monetization('❌ REFRESH FAILED: $e');
      SnackbarUtils.showError('Failed to refresh plans: $e');
    }
  }
}
