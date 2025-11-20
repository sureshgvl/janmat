import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/theme_constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/plan_model.dart';
import '../../../models/body_model.dart';
import '../../../utils/snackbar_utils.dart';
import '../services/razorpay_service.dart';
import '../../../services/local_database_service.dart';
import '../../highlight/controller/highlight_controller.dart' as hc;
import '../../highlight/services/highlight_service.dart';
import '../../../features/candidate/controllers/candidate_controller.dart';
import '../repositories/monetization_repository.dart';
import '../widgets/plan_purchase_success_dialog.dart';
import '../widgets/plan_benefits_showcase.dart';
import '../widgets/welcome_content_preview.dart';
import '../../../utils/app_logger.dart';

class MonetizationController extends GetxController {
  final MonetizationRepository _repository = MonetizationRepository();

  // Reactive variables
  var plans = <SubscriptionPlan>[].obs;
  var userSubscriptions = <UserSubscription>[].obs;
  var xpTransactions = <XPTransaction>[].obs;
  var userXPBalance = 0.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Session caching
  bool _plansLoaded = false;
  DateTime? _lastPlansLoadTime;

  // User status tracking
  var currentUserModel = Rxn<UserModel>();
  var currentFirebaseUser = Rxn<User>();
  var userStatusLogs = <String>[].obs;

  // Candidate plan progress tracking
  var totalPremiumCandidates = 0.obs;
  var first1000Limit = 1000.obs;

  // Payment mode toggle for testing
  var useMockPayment = true.obs; // Set to false to test real Razorpay

  // Real-time subscription monitoring
  StreamSubscription<DocumentSnapshot>? _subscriptionListener;

  @override
  void onInit() {
    super.onInit();
    // Don't load data on init - let the screen control when to load
    _setupRealtimeSubscriptionMonitoring();
  }

  @override
  void onClose() {
    _subscriptionListener?.cancel();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load plans with retry mechanism
      await loadPlans();

      // Load analytics data
      await loadAnalyticsData();
    } catch (e) {
      errorMessage.value = 'Failed to load data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Plan Management

  Future<void> loadPlans({bool forceRefresh = false}) async {
    try {
      // Check session cache first (unless force refresh)
      if (!forceRefresh && _plansLoaded && _lastPlansLoadTime != null) {
        final timeSinceLastLoad = DateTime.now().difference(_lastPlansLoadTime!);
        // Cache for 30 minutes during session
        if (timeSinceLastLoad.inMinutes < 30) {
          return;
        }
      }

      // Get current user to check role
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      // Get user document to check role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String? ?? 'voter';

      // Load all plans first
      final allPlans = await _repository.getAllPlans();

      // Filter plans based on user role and election type
      List<SubscriptionPlan> filteredPlans;
      if (userRole == 'candidate') {
        // For candidates, get their election type and filter plans
        final userElectionType = await getUserElectionType(currentUser.uid);

        if (userElectionType != null) {
          // Show plans that have pricing for this election type + voter plans + free plans + highlight plans + carousel plans
          filteredPlans = allPlans.where((plan) {
            // Always include voter plans (XP plans)
            if (plan.type == 'voter') return true;

            // Always include free plans
            if (plan.planId == 'free_plan') return true;

            // Always include highlight plans for candidates
            if (plan.type == 'highlight') return true;

            // Always include carousel plans for candidates
            if (plan.type == 'carousel') return true;

            // Include candidate plans that have pricing for user's election type
            return plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty;
          }).toList();
        } else {
          // If election type cannot be determined, show all plans
          filteredPlans = allPlans;
        }
      } else {
        // Voters see only XP plans
        filteredPlans = allPlans.where((plan) => plan.type == 'voter').toList();
      }

      plans.value = filteredPlans;

      // Update cache flags
      _plansLoaded = true;
      _lastPlansLoadTime = DateTime.now();

    } catch (e) {
      errorMessage.value = 'Failed to load plans: $e';
    }
  }

  Future<void> loadPlansByType(String type) async {
    try {
      final typePlans = await _repository.getPlansByType(type);
      plans.value = typePlans;
    } catch (e) {
      errorMessage.value = 'Failed to load plans: $e';
    }
  }

  SubscriptionPlan? getPlanById(String planId) {
    return plans.firstWhereOrNull((plan) => plan.planId == planId);
  }

  // Election Type Derivation using SQLite cache
  Future<String?> getUserElectionType(String userId) async {
    try {
      AppLogger.monetization('🔍 [MonetizationController] Getting election type for user: $userId');

      // Get user document to access electionAreas
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        AppLogger.monetization('❌ [MonetizationController] User document not found for: $userId');
        return kIsWeb ? 'municipal_corporation' : null; // Web fallback
      }

      final userData = userDoc.data()!;
      final electionAreas = userData['electionAreas'] as List<dynamic>?;

      // WEB FALLBACK: If no election areas, assume municipal corporation (most common)
      if (electionAreas == null || electionAreas.isEmpty) {
        AppLogger.monetization('❌ [MonetizationController] No election areas found for user: $userId, using web fallback');
        return kIsWeb ? 'municipal_corporation' : null;
      }

      // For candidates, use the first (and typically only) election area
      final primaryArea = electionAreas[0] as Map<String, dynamic>;
      final bodyId = primaryArea['bodyId'] as String;

      // Get location data from the location map
      final location = userData['location'] as Map<String, dynamic>?;
      final stateId = location?['stateId'] as String?;
      final districtId = location?['districtId'] as String?;

      if (stateId == null || districtId == null) {
        AppLogger.monetization('❌ [MonetizationController] Missing stateId or districtId for user: $userId, using web fallback');
        return kIsWeb ? 'municipal_corporation' : null;
      }

      AppLogger.monetization('📍 [MonetizationController] User location: state=$stateId, district=$districtId, body=$bodyId');

      // Try SQLite cache first for better performance (MOBILE ONLY)
      if (!kIsWeb) {
        try {
          final localDb = LocalDatabaseService();
          final cachedBodies = await localDb.getBodiesForDistrict(districtId);
          final cachedBody = cachedBodies.firstWhereOrNull(
            (body) => body.id == bodyId,
          );

          if (cachedBody != null) {
            final electionType = _mapBodyTypeToElectionType(cachedBody.type);
            AppLogger.monetization('✅ [MonetizationController] Found election type from cache: $electionType (body type: ${cachedBody.type})');
            return electionType;
          }
        } catch (e) {
          AppLogger.monetization('⚠️ [MonetizationController] SQLite cache failed on mobile: $e');
        }
      }

      // Fallback to Firebase if not in cache or on web
      AppLogger.monetization('🔄 [MonetizationController] ${kIsWeb ? 'Web platform' : 'Body not in cache'}, fetching from Firebase...');
      final bodyDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .get();

      if (!bodyDoc.exists) {
        AppLogger.monetization('❌ [MonetizationController] Body document not found: $bodyId, using web fallback');
        return kIsWeb ? 'municipal_corporation' : null;
      }

      final bodyTypeString = bodyDoc.data()?['type'] as String?;
      AppLogger.monetization('📄 [MonetizationController] Body type from Firebase: $bodyTypeString');

      // Convert string to BodyType enum
      BodyType? bodyType;
      switch (bodyTypeString) {
        case 'municipal_corporation':
          bodyType = BodyType.municipal_corporation;
          break;
        case 'municipal_council':
          bodyType = BodyType.municipal_council;
          break;
        case 'nagar_panchayat':
          bodyType = BodyType.nagar_panchayat;
          break;
        case 'zilla_parishad':
          bodyType = BodyType.zilla_parishad;
          break;
        case 'panchayat_samiti':
          bodyType = BodyType.panchayat_samiti;
          break;
        default:
          bodyType = null;
      }

      final electionType = _mapBodyTypeToElectionType(bodyType);
      AppLogger.monetization('✅ [MonetizationController] Final election type: $electionType (body type: $bodyType)');

      // FINAL WEB FALLBACK: If election type is still null, default to municipal corporation
      if (electionType == null && kIsWeb) {
        AppLogger.monetization('⚠️ [MonetizationController] Election type resolved to null on web, using fallback: municipal_corporation');
        return 'municipal_corporation';
      }

      return electionType;
    } catch (e) {
      AppLogger.monetization('❌ [MonetizationController] Error getting election type: $e');

      // EMERGENCY WEB FALLBACK: Return municipal corporation for any error on web
      if (kIsWeb) {
        AppLogger.monetization('⚠️ [MonetizationController] Error occurred on web, using emergency fallback: municipal_corporation');
        return 'municipal_corporation';
      }

      return null;
    }
  }

  String? _mapBodyTypeToElectionType(BodyType? bodyType) {
    if (bodyType == null) return null;

    switch (bodyType) {
      case BodyType.municipal_corporation:
        return 'municipal_corporation';
      case BodyType.municipal_council:
        return 'municipal_council';
      case BodyType.nagar_panchayat:
        return 'nagar_panchayat';
      case BodyType.zilla_parishad:
        return 'zilla_parishad';
      case BodyType.panchayat_samiti:
        return 'panchayat_samiti';
      default:
        return null;
    }
  }

  // User Subscription Management

  Future<void> loadUserSubscriptions(String userId) async {
    try {
      final subscriptions = await _repository.getUserSubscriptions(userId);
      userSubscriptions.value = subscriptions;
    } catch (e) {
      errorMessage.value = 'Failed to load subscriptions: $e';
    }
  }

  Future<UserSubscription?> getActiveSubscription(
    String userId,
    String planType,
  ) async {
    try {
      return await _repository.getActiveSubscription(userId, planType);
    } catch (e) {
      errorMessage.value = 'Failed to get active subscription: $e';
      return null;
    }
  }

  Future<bool> purchaseSubscription(
    String userId,
    SubscriptionPlan plan,
  ) async {
    try {
      isLoading.value = true;

      // Check if user can purchase this plan
      if (plan.type == 'candidate') {
        final canPurchase = await canPurchaseCandidatePlan();
        if (!canPurchase) {
          errorMessage.value = 'Candidate plan limit reached';
          return false;
        }
      }

      // Create subscription record
      // For legacy XP plans, use a default amount (this method is deprecated)
      final amountPaid = plan.type == 'voter'
          ? 0
          : 0; // XP plans are free or have different pricing

      final subscription = UserSubscription(
        subscriptionId: '',
        userId: userId,
        planId: plan.planId,
        planType: plan.type,
        amountPaid: amountPaid,
        purchasedAt: DateTime.now(),
        isActive: true,
      );

      final subscriptionId = await _repository.createSubscription(subscription);

      // Update user based on plan type
      if (plan.type == 'candidate') {
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          plan.planId,
          null,
        ); // One-time subscription
      }

      // Reload data
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to purchase subscription: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // XP Management

  Future<void> loadUserXPBalance(String userId) async {
    try {
      final balance = await _repository.getUserXPBalance(userId);
      userXPBalance.value = balance;
    } catch (e) {
      errorMessage.value = 'Failed to load XP balance: $e';
    }
  }

  Future<void> loadUserXPTransactions(String userId, {int limit = 50}) async {
    try {
      final transactions = await _repository.getUserXPTransactions(
        userId,
        limit: limit,
      );
      xpTransactions.value = transactions;
    } catch (e) {
      errorMessage.value = 'Failed to load XP transactions: $e';
    }
  }

  Future<bool> spendXP(
    String userId,
    int amount,
    String description, {
    String? referenceId,
  }) async {
    try {
      if (userXPBalance.value < amount) {
        errorMessage.value = 'Insufficient XP balance';
        return false;
      }

      await _repository.updateUserXPBalance(userId, -amount);
      await loadUserXPBalance(userId);
      await loadUserXPTransactions(userId);

      return true;
    } catch (e) {
      errorMessage.value = 'Failed to spend XP: $e';
      return false;
    }
  }

  Future<bool> canAffordXP(int amount) async {
    return userXPBalance.value >= amount;
  }

  // Candidate Plan Progress Tracking

  Future<void> loadAnalyticsData() async {
    try {
      final premiumCount = await _repository.getTotalPremiumCandidates();
      totalPremiumCandidates.value = premiumCount;
    } catch (e) {
      errorMessage.value = 'Failed to load analytics: $e';
    }
  }

  Future<bool> canPurchaseCandidatePlan() async {
    try {
      final premiumCount = await _repository.getTotalPremiumCandidates();
      return premiumCount < first1000Limit.value;
    } catch (e) {
      return false;
    }
  }

  int get remainingCandidateSlots =>
      first1000Limit.value - totalPremiumCandidates.value;

  bool get isFirst1000PlanAvailable => remainingCandidateSlots > 0;

  double get candidatePlanProgress =>
      totalPremiumCandidates.value / first1000Limit.value;

  // Payment Integration with Razorpay

  Future<bool> processPaymentWithElection(
    String planId,
    String electionType,
    int validityDays,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return false;
      }

      // Get plan details
      final plan = getPlanById(planId);
      if (plan == null) {
        errorMessage.value = 'Plan not found';
        return false;
      }

      // Calculate amount from pricing structure
      final amount = plan.pricing[electionType]?[validityDays];
      if (amount == null) {
        errorMessage.value =
            'Invalid plan configuration for your election type';
        return false;
      }

      // Check if using mock payment or real Razorpay
      if (useMockPayment.value) {
        // Show payment processing message
        SnackbarUtils.showInfo('Please wait while we process your payment...');

        // Simulate payment processing time
        await Future.delayed(const Duration(seconds: 3));

        // Simulate payment success directly
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final paymentId = 'pay_test_$timestamp';
        final orderId =
            'order_${planId}_${electionType}_${validityDays}_$timestamp';
        final signature = 'test_signature_$timestamp';

        // Handle payment success directly with election data
        _handleMockPaymentSuccessWithElection(
          paymentId,
          orderId,
          signature,
          planId,
          electionType,
          validityDays,
        );
      } else {
        // Get Razorpay service
        final razorpayService = Get.find<RazorpayService>();

        // Create order (in production, this should be done on backend)
        final orderId = await razorpayService.createOrder(
          amount: amount,
          currency: 'INR',
          receipt: 'receipt_$planId',
          notes: {
            'planId': planId,
            'userId': currentUser.uid,
            'electionType': electionType,
            'validityDays': validityDays.toString(),
            'calculatedAmount': amount.toString(),
          },
        );

        // Start Razorpay payment with enhanced options for test mode
        razorpayService.startPayment(
          orderId:
              orderId ??
              'order_${planId}_${electionType}_${validityDays}_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount * 100, // Convert rupees to paisa for Razorpay
          description: 'Purchase $plan.name ($validityDays days)',
          contact: currentUser.phoneNumber ?? '',
          email: currentUser.email ?? '',
          prefillName: currentUser.displayName,
          notes: {
            'planId': planId,
            'userId': currentUser.uid,
            'electionType': electionType,
            'validityDays': validityDays.toString(),
          },
        );

        // Payment result will be handled by callbacks
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Payment failed: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> processPayment(String planId, int amount) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage.value = 'User not authenticated';
        return false;
      }

      // Get plan details
      final plan = getPlanById(planId);
      if (plan == null) {
        errorMessage.value = 'Plan not found';
        return false;
      }

      // Check if using mock payment or real Razorpay
      if (useMockPayment.value) {
        // Show payment processing message
        SnackbarUtils.showInfo('Please wait while we process your payment...');

        // Simulate payment processing time
        await Future.delayed(const Duration(seconds: 3));

        // Simulate payment success directly
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final paymentId = 'pay_test_$timestamp';
        final orderId = 'order_${planId}_$timestamp';
        final signature = 'test_signature_$timestamp';

        // Handle payment success directly
        _handleMockPaymentSuccess(paymentId, orderId, signature, planId);
      } else {
        // Get Razorpay service
        final razorpayService = Get.find<RazorpayService>();

        // Create order (in production, this should be done on backend)
        final orderId = await razorpayService.createOrder(
          amount: amount,
          currency: 'INR',
          receipt: 'receipt_$planId',
          notes: {
            'planId': planId,
            'userId': currentUser.uid,
            'planName': plan.name,
          },
        );

        // Start Razorpay payment with enhanced options for test mode
        razorpayService.startPayment(
          orderId:
              orderId ?? 'test_order_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          description: 'Purchase $plan.name',
          contact: currentUser.phoneNumber ?? '',
          email: currentUser.email ?? '',
          prefillName: currentUser.displayName,
          notes: {'planId': planId, 'userId': currentUser.uid},
        );

        // Payment result will be handled by callbacks
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Payment failed: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Handle successful payment
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    // Extract notes from response if available
    final orderParts = response.orderId?.split('_') ?? [];

    if (orderParts.length >= 2) {
      final planId = orderParts[1]; // Extract planId from orderId

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Complete the purchase
        _completePurchaseAfterPayment(currentUser.uid, planId);
      }
    }

    SnackbarUtils.showSuccess('Payment completed successfully!');
  }

  // Handle payment error
  void handlePaymentError(PaymentFailureResponse response) {
    errorMessage.value = response.message ?? 'Payment failed';

    SnackbarUtils.showError(response.message ?? 'Unknown error occurred');
  }

  // Handle mock payment success
  void _handleMockPaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
    String planId,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Complete the purchase
      _completePurchaseAfterPayment(currentUser.uid, planId);
    }

    SnackbarUtils.showSuccess('Your payment has been processed successfully.');
  }

  // Handle mock payment success with election data
  void _handleMockPaymentSuccessWithElection(
    String paymentId,
    String orderId,
    String signature,
    String planId,
    String electionType,
    int validityDays,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Complete the purchase with election data
      _completePurchaseAfterPaymentWithElection(
        currentUser.uid,
        planId,
        electionType,
        validityDays,
      );
    }

    SnackbarUtils.showSuccess('Your payment has been processed successfully.');
  }

  // Complete purchase after successful payment
  Future<void> _completePurchaseAfterPayment(
    String userId,
    String planId,
  ) async {
    try {
      final plan = getPlanById(planId);
      if (plan == null) {
        return;
      }

      // Create subscription record
      // For legacy method, use default amount (this method is deprecated)
      final amountPaid = plan.type == 'voter' ? 0 : 0;

      final subscription = UserSubscription(
        subscriptionId: '',
        userId: userId,
        planId: planId,
        planType: plan.type,
        amountPaid: amountPaid,
        purchasedAt: DateTime.now(),
        isActive: true,
      );

      // Update user based on plan type
      if (plan.type == 'candidate') {
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          planId,
          null, // One-time subscription
        );
      }

      // Reload data
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();
    } catch (e) {
      errorMessage.value = 'Failed to complete purchase: $e';
    }
  }

  // Complete purchase after successful payment with election data
  Future<void> _completePurchaseAfterPaymentWithElection(
    String userId,
    String planId,
    String electionType,
    int validityDays,
  ) async {
    try {
      final plan = getPlanById(planId);
      if (plan == null) {
        return;
      }

      // Calculate amount from pricing structure
      final amountPaid = plan.pricing[electionType]?[validityDays];
      if (amountPaid == null) {
        return;
      }

      // Calculate expiration date
      final purchasedAt = DateTime.now();
      final expiresAt = purchasedAt.add(Duration(days: validityDays));

      // Create subscription record with election data
      final subscription = UserSubscription(
        subscriptionId: '',
        userId: userId,
        planId: planId,
        planType: plan.type,
        electionType: electionType, // New field
        validityDays: validityDays, // New field
        amountPaid: amountPaid,
        purchasedAt: purchasedAt,
        expiresAt: expiresAt, // New field
        isActive: true,
      );

      await _repository.createSubscription(subscription);

      // Update user based on plan type
      if (plan.type == 'candidate') {
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          planId,
          expiresAt, // Now we have an expiration date
        );

        // For Platinum plan, create welcome content
        if (planId == 'platinum_plan') {
          await _createPlatinumWelcomeContent(userId);
        }
      }

      // For highlight plans, create highlight content
      if (plan.type == 'highlight') {
        await _createHighlightPlanContent(userId, planId, electionType, validityDays);
      }

      // Reload data
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();
    } catch (e) {
      errorMessage.value = 'Failed to complete purchase: $e';
    }

    // Show post-purchase UI after successful completion
    _showPostPurchaseUI(planId, electionType, validityDays);
  }

  Future<void> _showPostPurchaseUI(String planId, String? electionType, int validityDays) async {
    try {
      final plan = getPlanById(planId);
      if (plan == null) return;

      // Show success dialog
      if (Get.context != null) {
        await showDialog(
          context: Get.context!,
          barrierDismissible: false,
          builder: (context) => PlanPurchaseSuccessDialog(
            plan: plan,
            validityDays: validityDays,
            amountPaid: plan.pricing[electionType ?? '']?[validityDays] ?? 0,
            electionType: electionType,
            onContinue: () {
              Navigator.of(context).pop();
              _showWelcomeContent(plan);
            },
          ),
        );
      }
    } catch (e) {
      AppLogger.monetization('Error showing post-purchase UI: $e');
    }
  }

  void _showBenefitsShowcase(SubscriptionPlan plan, int validityDays) {
    Get.to(() => PlanBenefitsShowcase(
      plan: plan,
      validityDays: validityDays,
      onGetStarted: () {
        Get.back();
        _showWelcomeContent(plan);
      },
    ));
  }

  void _showWelcomeContent(SubscriptionPlan plan) {
    // Show welcome content preview for Platinum users
    if (plan.planId == 'platinum_plan' && Get.context != null) {
      showDialog(
        context: Get.context!,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: WelcomeContentPreview(
              userId: FirebaseAuth.instance.currentUser?.uid ?? '',
              onViewFullContent: () {
                Navigator.of(context).pop();
                // Navigate to highlight/banner section
                Get.toNamed('/candidate/highlights');
              },
              onCreateMoreContent: () {
                Navigator.of(context).pop();
                // Navigate to create highlight
                Get.toNamed('/candidate/highlights/create');
              },
            ),
          ),
        ),
      );
    }
  }

  // Create welcome content for Platinum users
  Future<void> _createPlatinumWelcomeContent(String userId) async {
    try {
      // Get candidate controller and retrieve candidate data directly
      final candidateController = Get.find<CandidateController>();
      final candidate = await candidateController.candidateRepository.getCandidateData(userId);
      if (candidate == null) {
        AppLogger.monetization('❌ No candidate data found for user: $userId');
        return;
      }

      AppLogger.monetization('✅ Found candidate data for Platinum content creation: ${candidate.candidateId}');

      // Get highlight controller
      final highlightController = Get.find<hc.HighlightController>();

      // Create Platinum highlight - ensure we use the correct hierarchical path
      AppLogger.monetization('🔥 Creating Platinum highlight for candidate: ${candidate.candidateId}');
      await highlightController.createPlatinumHighlight(
        candidateId: candidate.candidateId,
        districtId: candidate.location.districtId!,
        bodyId: candidate.location.bodyId!,
        wardId: candidate.location.wardId!,
        candidateName: candidate.basicInfo?.fullName ?? 'Candidate',
        party: candidate.party,
        imageUrl: candidate.basicInfo?.photo ?? candidate.photo,
      );

      // Create welcome sponsored post
      await highlightController.createPushFeedItem(
        candidateId: candidate.candidateId,
        wardId: candidate.location.wardId!,
        title: '🎉 Platinum Plan Activated!',
        message:
            '${candidate.basicInfo?.fullName ?? 'The candidate'} is now a Platinum member with maximum visibility!',
        imageUrl: candidate.basicInfo?.photo ?? candidate.photo,
      );

      AppLogger.monetization('✅ Platinum welcome content created successfully');
    } catch (e) {
      AppLogger.monetization('❌ Error creating Platinum welcome content: $e');
    }
  }

  // Create content for highlight plans
  Future<void> _createHighlightPlanContent(String userId, String planId, String? electionType, int validityDays) async {
    try {
      AppLogger.monetization('🎯 ======= CREATING HIGHLIGHT PLAN CONTENT =======');
      AppLogger.monetization('🎯 User ID: $userId, Plan ID: $planId, Election Type: $electionType, Validity: $validityDays days');

      // Get candidate controller and retrieve candidate data directly
      final candidateController = Get.find<CandidateController>();
      AppLogger.monetization('🎯 Getting candidate data for user: $userId');

      final candidate = await candidateController.candidateRepository.getCandidateData(userId);
      if (candidate == null) {
        AppLogger.monetization('❌ No candidate data found for user: $userId');
        return;
      }

      AppLogger.monetization('✅ Found candidate data for highlight plan content creation: ${candidate.candidateId}');
      AppLogger.monetization('📍 Candidate location: ${candidate.location.districtId}/${candidate.location.bodyId}/${candidate.location.wardId}');

      // Get highlight controller
      final highlightController = Get.find<hc.HighlightController>();
      AppLogger.monetization('🎯 HighlightController found, starting highlight creation');

      // Create highlight based on plan type
      if (planId == 'highlight_plan') {
        AppLogger.monetization('🔥 Creating highlight plan content for candidate: ${candidate.candidateId}');

        // Check if candidate already has an existing highlight in their ward
        final existingHighlights = await HighlightService.getHighlightsByCandidateInWard(
          candidateId: candidate.candidateId,
          districtId: candidate.location.districtId!,
          bodyId: candidate.location.bodyId!,
          wardId: candidate.location.wardId!,
        );

        final existingHighlight = existingHighlights.isNotEmpty ? existingHighlights.first : null;

        if (existingHighlight != null) {
          AppLogger.monetization('🔄 Found existing highlight ${existingHighlight.id} for candidate ${candidate.candidateId}, updating instead of creating new');

          // Update existing highlight - preserve clicks and views, update everything else
          await HighlightService.updateExistingHighlight(
            existingHighlight: existingHighlight,
            districtId: candidate.location.districtId!,
            bodyId: candidate.location.bodyId!,
            wardId: candidate.location.wardId!,
            candidateName: candidate.basicInfo?.fullName ?? 'Candidate',
            party: candidate.party,
            imageUrl: candidate.basicInfo?.photo ?? candidate.photo,
            bannerStyle: 'premium',
            callToAction: 'View Profile',
            priorityLevel: 'normal',
            customMessage: null,
            validityDays: validityDays,
            placement: ['top_banner'],
          );

          AppLogger.monetization('✅ Existing highlight updated successfully');
        } else {
          AppLogger.monetization('🆕 No existing highlight found, creating new one');

          // Create new highlight
          await highlightController.createOrUpdatePlatinumHighlight(
            candidateId: candidate.candidateId,
            districtId: candidate.location.districtId!,
            bodyId: candidate.location.bodyId!,
            wardId: candidate.location.wardId!,
            candidateName: candidate.basicInfo?.fullName ?? 'Candidate',
            party: candidate.party,
            imageUrl: candidate.basicInfo?.photo ?? candidate.photo,
            priorityLevel: 'normal', // Default priority for highlight plan
            validityDays: validityDays, // Use the purchased validity days
            placement: ['top_banner'], // Only banner for highlight plans
          );

          // Create welcome sponsored post only for new highlights
          await highlightController.createPushFeedItem(
            candidateId: candidate.candidateId,
            wardId: candidate.location.wardId!,
            title: '🎉 Highlight Plan Activated!',
            message:
                '${candidate.basicInfo?.fullName ?? 'The candidate'} is now visible in highlight banners!',
            imageUrl: candidate.basicInfo?.photo ?? candidate.photo,
          );

          AppLogger.monetization('✅ New highlight created successfully');
        }

        AppLogger.monetization('✅ Highlight plan content created successfully');
      } else {
        AppLogger.monetization('⚠️ Unknown plan ID: $planId, no content created');
      }

      AppLogger.monetization('🎯 ======= HIGHLIGHT PLAN CONTENT CREATION COMPLETED =======\n');
    } catch (e) {
      AppLogger.monetization('❌ Error creating highlight plan content: $e');
      AppLogger.monetization('🎯 ======= HIGHLIGHT PLAN CONTENT CREATION FAILED =======\n');
    }
  }



  // Utility Methods

  void clearError() {
    errorMessage.value = '';
  }

  Future<Map<String, int>> getSubscriptionStats() async {
    try {
      return await _repository.getSubscriptionStats();
    } catch (e) {
      errorMessage.value = 'Failed to get stats: $e';
      return {};
    }
  }

  // Initialize default plans (call this once during app setup)
  Future<void> initializeDefaultPlans() async {
    try {
      AppLogger.monetization('🔧 INITIALIZING DEFAULT PLANS...');
      await _repository.initializeDefaultPlans();
      await loadPlans();
      AppLogger.monetization('✅ DEFAULT PLANS INITIALIZED SUCCESSFULLY');
    } catch (e) {
      AppLogger.monetization('❌ FAILED TO INITIALIZE PLANS: $e');
      errorMessage.value = 'Failed to initialize plans: $e';
    }
  }

  // Force refresh plans (useful for hot reload issues)
  Future<void> refreshPlans() async {
    try {
      AppLogger.monetization('🔄 FORCE REFRESH: Reloading plans after hot reload...');
      isLoading.value = true;
      errorMessage.value = '';

      // Clear session cache
      _plansLoaded = false;
      _lastPlansLoadTime = null;

      // Clear current user model to force re-evaluation
      currentUserModel.value = null;
      currentFirebaseUser.value = null;

      // Reload everything with force refresh
      await loadInitialData();

      AppLogger.monetization('✅ FORCE REFRESH: Plans reloaded successfully');
    } catch (e) {
      AppLogger.monetization('❌ FORCE REFRESH FAILED: $e');
      errorMessage.value = 'Failed to refresh: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // User Status Logging and Display Methods

  Future<void> loadUserStatusData() async {
    try {
      userStatusLogs.clear();
      _addLog('🔍 Loading user status data...');

      // Get Firebase Auth user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      currentFirebaseUser.value = firebaseUser;

      if (firebaseUser == null) {
        _addLog('❌ No authenticated user found');
        return;
      }

      _addLog('✅ Firebase User: ${firebaseUser.uid}');
      _addLog('   Email: ${firebaseUser.email ?? 'Not set'}');
      _addLog('   Phone: ${firebaseUser.phoneNumber ?? 'Not set'}');
      _addLog('   Display Name: ${firebaseUser.displayName ?? 'Not set'}');
      _addLog('   Email Verified: ${firebaseUser.emailVerified}');

      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        _addLog('❌ User document not found in Firestore');
        return;
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromJson(userData);
      currentUserModel.value = userModel;

      _addLog('✅ User Model Loaded:');
      _addLog('   Name: ${userModel.name}');
      _addLog('   Role: ${userModel.role}');
      _addLog('   Premium: ${userModel.premium}');
      _addLog('   XP Points: ${userModel.xpPoints}');
      _addLog('   Profile Completed: ${userModel.profileCompleted}');
      _addLog(
        '   Subscription Plan: ${userModel.subscriptionPlanId ?? 'None'}',
      );

      if (userModel.subscriptionExpiresAt != null) {
        _addLog('   Subscription Expires: ${userModel.subscriptionExpiresAt}');
      }

      if (userModel.isTrialActive) {
        _addLog('   Trial Active: Yes');
        if (userModel.trialExpiresAt != null) {
          _addLog('   Trial Expires: ${userModel.trialExpiresAt}');
        }
      } else {
        _addLog('   Trial Active: No');
      }

      // Load user subscriptions
      await loadUserSubscriptions(firebaseUser.uid);
      _addLog('   Total Subscriptions: ${userSubscriptions.length}');

      for (var subscription in userSubscriptions) {
        _addLog(
          '   - ${subscription.planType}: ${subscription.planId} (${subscription.isActive ? 'Active' : 'Inactive'})',
        );
      }

      // Load XP transactions
      await loadUserXPTransactions(firebaseUser.uid, limit: 10);
      _addLog('   Recent XP Transactions: ${xpTransactions.length}');

      for (var transaction in xpTransactions.take(3)) {
        _addLog(
          '   - ${transaction.type}: ${transaction.amount} XP - ${transaction.description}',
        );
      }

      _addLog('🎉 User status data loaded successfully');
    } catch (e) {
      _addLog('❌ Error loading user status: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    userStatusLogs.add(logMessage);
  }

  // Get user status summary for display
  Map<String, dynamic> getUserStatusSummary() {
    final user = currentUserModel.value;
    final firebaseUser = currentFirebaseUser.value;

    if (user == null || firebaseUser == null) {
      return {
        'isAuthenticated': false,
        'status': 'Not Authenticated',
        'role': 'Unknown',
        'premium': false,
        'xpBalance': 0,
        'subscriptionCount': 0,
        'activeSubscriptions': 0,
        'trialActive': false,
        'profileCompleted': false,
      };
    }

    return {
      'isAuthenticated': true,
      'status': _getUserStatusText(user),
      'role': user.role,
      'premium': user.premium ?? false,
      'xpBalance': user.xpPoints,
      'subscriptionCount': userSubscriptions.length,
      'activeSubscriptions': userSubscriptions
          .where((s) => s.isActive ?? false)
          .length,
      'trialActive': user.isTrialActive ?? false,
      'profileCompleted': user.profileCompleted ?? false,
    };
  }

  String _getUserStatusText(UserModel user) {
    if (user.premium) {
      return 'Premium ${user.role}';
    } else if (user.isTrialActive) {
      return 'Trial ${user.role}';
    } else {
      return 'Basic ${user.role}';
    }
  }

  // Clear logs
  void clearUserStatusLogs() {
    userStatusLogs.clear();
  }

  // Role-based plan access
  bool get showAllPlans {
    final user = currentUserModel.value;
    // Show comparison table for voters, individual cards for candidates
    return user?.role == 'voter';
  }

  bool get showOnlyXPPlans {
    final user = currentUserModel.value;
    return user?.role == 'voter';
  }

  // Premium features visibility - only show for candidates
  bool get showPremiumCard {
    final user = currentUserModel.value;
    return user?.role == 'candidate';
  }

  bool get showPremiumDrawerMenu {
    final user = currentUserModel.value;
    return user?.role == 'candidate';
  }

  String get plansTabText {
    final user = currentUserModel.value;
    return user?.role == 'candidate' ? 'Premium Plans' : 'XP Store';
  }

  String get xpTabText {
    return 'XP Plans';
  }

  // Real-time subscription monitoring
  void _setupRealtimeSubscriptionMonitoring() {
    ever(currentFirebaseUser, (User? user) {
      if (user != null) {
        _startUserSubscriptionListener(user.uid);
      } else {
        _stopUserSubscriptionListener();
      }
    });

    // Start listening if user is already logged in
    if (currentFirebaseUser.value != null) {
      _startUserSubscriptionListener(currentFirebaseUser.value!.uid);
    }
  }

  void _startUserSubscriptionListener(String userId) {
    _subscriptionListener?.cancel(); // Cancel any existing listener

    _subscriptionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            final userModel = UserModel.fromJson(userData);

            // Store previous state for comparison
            final previousUserModel = currentUserModel.value;

            // Update reactive variables
            currentUserModel.value = userModel;

            // Check for all plan type expiries
            _checkForPlanExpiries(previousUserModel, userModel);
          }
        });
  }

  void _checkForPlanExpiries(UserModel? previousUser, UserModel currentUser) {
    final now = DateTime.now();

    // Check Candidate Plan (Gold/Platinum) expiry
    final previousPremium = previousUser?.premium ?? false;
    final currentPremium = currentUser.premium ?? false;

    if (previousPremium && !currentPremium) {
      _handlePlanExpiry('Candidate Plan', 'Your premium plan has expired. Upgrade to continue enjoying premium features.');
    }

    // Check Highlight Banner Plan expiry
    final previousHighlightPlanId = previousUser?.highlightPlanId;
    final currentHighlightPlanId = currentUser.highlightPlanId;
    final highlightExpiry = currentUser.highlightPlanExpiresAt;

    if (previousHighlightPlanId != null &&
        currentHighlightPlanId == null &&
        highlightExpiry != null &&
        now.isAfter(highlightExpiry)) {
      _handlePlanExpiry('Highlight Banner', 'Your highlight banner plan has expired. Renew to maintain banner visibility.');
    }

    // Check Carousel Plan expiry
    final previousCarouselPlanId = previousUser?.carouselPlanId;
    final currentCarouselPlanId = currentUser.carouselPlanId;
    final carouselExpiry = currentUser.carouselPlanExpiresAt;

    if (previousCarouselPlanId != null &&
        currentCarouselPlanId == null &&
        carouselExpiry != null &&
        now.isAfter(carouselExpiry)) {
      _handlePlanExpiry('Carousel Plan', 'Your carousel plan has expired. Renew to continue carousel placement.');
    }

    // Check for upcoming expiries (within 3 days)
    _checkForUpcomingExpiries(currentUser);
  }

  void _handlePlanExpiry(String planType, String message) {
    // Trigger UI refresh
    update();

    // Show expiration notification
    SnackbarUtils.showWarning('$planType Expired: $message');
  }

  void _checkForUpcomingExpiries(UserModel user) {
    final now = DateTime.now();
    const warningDays = 3;

    // Check candidate plan expiry warning
    if (user.subscriptionExpiresAt != null && user.premium == true) {
      final daysUntilExpiry = user.subscriptionExpiresAt!.difference(now).inDays;
      if (daysUntilExpiry <= warningDays && daysUntilExpiry > 0) {
        SnackbarUtils.showCustom(
          title: 'Warning',
          message: 'Your premium plan expires in $daysUntilExpiry days. Renew now to avoid service interruption.',
          backgroundColor: AppColors.snackBarWarning,
          textColor: Colors.black,
          icon: const Icon(Icons.warning, color: Colors.black),
          duration: const Duration(seconds: 3),
        );
      }
    }

    // Check highlight plan expiry warning
    if (user.highlightPlanExpiresAt != null && user.highlightPlanId != null) {
      final daysUntilExpiry = user.highlightPlanExpiresAt!.difference(now).inDays;
      if (daysUntilExpiry <= warningDays && daysUntilExpiry > 0) {
        SnackbarUtils.showWarning('Your highlight banner expires in $daysUntilExpiry days.');
      }
    }

    // Check carousel plan expiry warning
    if (user.carouselPlanExpiresAt != null && user.carouselPlanId != null) {
      final daysUntilExpiry = user.carouselPlanExpiresAt!.difference(now).inDays;
      if (daysUntilExpiry <= warningDays && daysUntilExpiry > 0) {
        SnackbarUtils.showWarning('Your carousel plan expires in $daysUntilExpiry days.');
      }
    }
  }

  void _stopUserSubscriptionListener() {
    _subscriptionListener?.cancel();
    _subscriptionListener = null;
  }
}
