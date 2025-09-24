import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/plan_model.dart';
import '../../../models/user_model.dart';
import '../../../services/razorpay_service.dart';
import '../repositories/monetization_repository.dart';

class MonetizationController extends GetxController {
  final MonetizationRepository _repository = MonetizationRepository();

  // Reactive variables
  var plans = <SubscriptionPlan>[].obs;
  var userSubscriptions = <UserSubscription>[].obs;
  var xpTransactions = <XPTransaction>[].obs;
  var userXPBalance = 0.obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // User status tracking
  var currentUserModel = Rxn<UserModel>();
  var currentFirebaseUser = Rxn<User>();
  var userStatusLogs = <String>[].obs;

  // Candidate plan progress tracking
  var totalPremiumCandidates = 0.obs;
  var first1000Limit = 1000.obs;

  // Payment mode toggle for testing
  var useMockPayment = true.obs; // Set to false to test real Razorpay

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load plans
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

  Future<void> loadPlans() async {
    try {
      final allPlans = await _repository.getAllPlans();
      plans.value = allPlans;
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
      final subscription = UserSubscription(
        subscriptionId: '',
        userId: userId,
        planId: plan.planId,
        planType: plan.type,
        amountPaid: plan.price,
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

  Future<bool> processPayment(String planId, int amount) async {
    debugPrint('💰 STARTING PAYMENT PROCESS');
    debugPrint('   Plan ID: $planId');
    debugPrint('   Amount: ₹${amount / 100} (${amount} paisa)');

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current user
      debugPrint('👤 Checking user authentication...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ User not authenticated');
        errorMessage.value = 'User not authenticated';
        return false;
      }
      debugPrint('✅ User authenticated: ${currentUser.uid}');

      // Get plan details
      debugPrint('📋 Fetching plan details...');
      final plan = getPlanById(planId);
      if (plan == null) {
        debugPrint('❌ Plan not found: $planId');
        errorMessage.value = 'Plan not found';
        return false;
      }
      debugPrint('✅ Plan found: ${plan.name}');

      // Check if using mock payment or real Razorpay
      if (useMockPayment.value) {
        debugPrint('🎯 USING MOCK PAYMENT MODE');

        // Show payment processing message
        Get.snackbar(
          'Processing Payment',
          'Please wait while we process your payment...',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          showProgressIndicator: true,
        );

        // Simulate payment processing time
        await Future.delayed(const Duration(seconds: 3));

        debugPrint('✅ Mock payment processing completed');

        // Simulate payment success directly
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final paymentId = 'pay_test_$timestamp';
        final orderId = 'order_${planId}_$timestamp';
        final signature = 'test_signature_$timestamp';

        debugPrint('✅ Mock payment successful');
        debugPrint('   Payment ID: $paymentId');
        debugPrint('   Order ID: $orderId');

        // Handle payment success directly
        _handleMockPaymentSuccess(paymentId, orderId, signature, planId);
      } else {
        debugPrint('💳 USING REAL RAZORPAY PAYMENT MODE');

        // Get Razorpay service
        debugPrint('🔧 Getting Razorpay service...');
        final razorpayService = Get.find<RazorpayService>();
        debugPrint('✅ Razorpay service obtained');

        // Create order (in production, this should be done on backend)
        debugPrint('📝 Creating payment order...');
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

        if (orderId == null) {
          debugPrint('⚠️ Order ID is null (test mode) - proceeding without order');
          // In test mode, we can proceed without order ID
          // Razorpay will handle the payment directly
        } else {
          debugPrint('✅ Order created: $orderId');
        }

        // Start Razorpay payment with enhanced options for test mode
        debugPrint('🚀 Starting Razorpay payment with full options...');
        razorpayService.startPayment(
          orderId: orderId ?? 'test_order_${DateTime.now().millisecondsSinceEpoch}',
          amount: amount,
          description: 'Purchase ${plan.name}',
          contact: currentUser.phoneNumber ?? '',
          email: currentUser.email ?? '',
          prefillName: currentUser.displayName,
          notes: {
            'planId': planId,
            'userId': currentUser.uid,
          },
        );

        debugPrint('✅ Razorpay payment initiated with all payment options');
        // Payment result will be handled by callbacks
      }

      return true;
    } catch (e) {
      debugPrint('❌ PAYMENT PROCESS ERROR: $e');
      debugPrint('   Error Type: ${e.runtimeType}');
      debugPrint('   Stack Trace: ${StackTrace.current}');
      errorMessage.value = 'Payment failed: $e';
      return false;
    } finally {
      isLoading.value = false;
      debugPrint('🔄 Payment process loading state reset');
    }
  }

  // Handle successful payment
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('🎉 PAYMENT SUCCESS HANDLER CALLED');
    debugPrint('   Payment ID: ${response.paymentId}');
    debugPrint('   Order ID: ${response.orderId}');
    debugPrint('   Signature: ${response.signature}');

    // Extract notes from response if available
    final orderParts = response.orderId?.split('_') ?? [];
    debugPrint('   Order parts: $orderParts');

    if (orderParts.length >= 2) {
      final planId = orderParts[1]; // Extract planId from orderId
      debugPrint('   Extracted Plan ID: $planId');

      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('   Current User: ${currentUser?.uid ?? 'null'}');

      if (currentUser != null) {
        debugPrint('🔄 Completing purchase after payment...');
        // Complete the purchase
        _completePurchaseAfterPayment(currentUser.uid, planId);
      } else {
        debugPrint('❌ No authenticated user found for completing purchase');
      }
    } else {
      debugPrint('❌ Could not extract plan ID from order ID');
    }

    debugPrint('🔔 Showing success snackbar');
    Get.snackbar(
      'Success',
      'Payment completed successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Handle payment error
  void handlePaymentError(PaymentFailureResponse response) {
    debugPrint('❌ PAYMENT ERROR HANDLER CALLED');
    debugPrint('   Error Code: ${response.code}');
    debugPrint('   Error Message: ${response.message}');

    errorMessage.value = response.message ?? 'Payment failed';
    debugPrint('   Set error message: ${errorMessage.value}');

    debugPrint('🔔 Showing error snackbar');
    Get.snackbar(
      'Payment Failed',
      response.message ?? 'Unknown error occurred',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Handle mock payment success
  void _handleMockPaymentSuccess(String paymentId, String orderId, String signature, String planId) {
    debugPrint('🎉 MOCK PAYMENT SUCCESS HANDLER CALLED');
    debugPrint('   Payment ID: $paymentId');
    debugPrint('   Order ID: $orderId');
    debugPrint('   Signature: $signature');
    debugPrint('   Plan ID: $planId');

    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('   Current User: ${currentUser?.uid ?? 'null'}');

    if (currentUser != null) {
      debugPrint('🔄 Completing purchase after mock payment...');
      // Complete the purchase
      _completePurchaseAfterPayment(currentUser.uid, planId);
    } else {
      debugPrint('❌ No authenticated user found for completing purchase');
    }

    debugPrint('🔔 Showing success snackbar');
    Get.snackbar(
      'Payment Successful!',
      'Your payment has been processed successfully.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Complete purchase after successful payment
  Future<void> _completePurchaseAfterPayment(String userId, String planId) async {
    debugPrint('🔄 COMPLETING PURCHASE AFTER PAYMENT');
    debugPrint('   User ID: $userId');
    debugPrint('   Plan ID: $planId');

    try {
      debugPrint('📋 Getting plan details...');
      final plan = getPlanById(planId);
      if (plan == null) {
        debugPrint('❌ Plan not found, aborting purchase completion');
        return;
      }
      debugPrint('✅ Plan details: ${plan.name} (${plan.type})');

      // Create subscription record
      debugPrint('📝 Creating subscription record...');
      final subscription = UserSubscription(
        subscriptionId: '',
        userId: userId,
        planId: planId,
        planType: plan.type,
        amountPaid: plan.price,
        purchasedAt: DateTime.now(),
        isActive: true,
      );

      final subscriptionId = await _repository.createSubscription(subscription);
      debugPrint('✅ Subscription created with ID: $subscriptionId');

      // Update user based on plan type
      if (plan.type == 'candidate') {
        debugPrint('👤 Upgrading user to premium candidate...');
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          planId,
          null, // One-time subscription
        );
        debugPrint('✅ User upgraded to premium candidate');
      }

      // Reload data
      debugPrint('🔄 Reloading user data...');
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();
      debugPrint('✅ User data reloaded');

      debugPrint('🎉 PURCHASE COMPLETED SUCCESSFULLY');
      debugPrint('   Plan: $planId');
      debugPrint('   User: $userId');
      debugPrint('   Type: ${plan.type}');
    } catch (e) {
      debugPrint('❌ ERROR COMPLETING PURCHASE: $e');
      debugPrint('   Error Type: ${e.runtimeType}');
      debugPrint('   Stack Trace: ${StackTrace.current}');
      errorMessage.value = 'Failed to complete purchase: $e';
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
      debugPrint('🔧 INITIALIZING DEFAULT PLANS...');
      await _repository.initializeDefaultPlans();
      await loadPlans();
      debugPrint('✅ DEFAULT PLANS INITIALIZED SUCCESSFULLY');
    } catch (e) {
      debugPrint('❌ FAILED TO INITIALIZE PLANS: $e');
      errorMessage.value = 'Failed to initialize plans: $e';
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
      _addLog('   Subscription Plan: ${userModel.subscriptionPlanId ?? 'None'}');

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
        _addLog('   - ${subscription.planType}: ${subscription.planId} (${subscription.isActive ? 'Active' : 'Inactive'})');
      }

      // Load XP transactions
      await loadUserXPTransactions(firebaseUser.uid, limit: 10);
      _addLog('   Recent XP Transactions: ${xpTransactions.length}');

      for (var transaction in xpTransactions.take(3)) {
        _addLog('   - ${transaction.type}: ${transaction.amount} XP - ${transaction.description}');
      }

      _addLog('🎉 User status data loaded successfully');

    } catch (e) {
      _addLog('❌ Error loading user status: $e');
      debugPrint('Error loading user status: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    userStatusLogs.add(logMessage);
    debugPrint(logMessage);
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
      'activeSubscriptions': userSubscriptions.where((s) => s.isActive ?? false).length,
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
}
