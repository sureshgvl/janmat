import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/plan_model.dart';
import '../../../models/user_model.dart';
import '../../../models/body_model.dart';
import '../../../services/razorpay_service.dart';
import '../../../services/local_database_service.dart';
import '../../../controllers/highlight_controller.dart';
import '../repositories/monetization_repository.dart';
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
    AppLogger.monetization('Initializing...', tag: 'MONETIZATION_CONTROLLER');
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

      AppLogger.monetization('Starting initial data load...', tag: 'MONETIZATION_CONTROLLER');

      // Load plans with retry mechanism
      await loadPlans();

      // Load analytics data
      await loadAnalyticsData();

      AppLogger.monetization('Initial data load completed', tag: 'MONETIZATION_CONTROLLER');
    } catch (e) {
      AppLogger.monetizationError('Failed to load initial data', tag: 'MONETIZATION_CONTROLLER', error: e);
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
          AppLogger.monetization('📋 Using cached plans (loaded ${_lastPlansLoadTime!.toIso8601String()})');
          return;
        }
      }

      AppLogger.monetization('Loading plans based on user role and election type...', tag: 'MONETIZATION_CONTROLLER');

      // Get current user to check role
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetizationError('No authenticated user found', tag: 'MONETIZATION_CONTROLLER');
        return;
      }

      // Get user document to check role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        AppLogger.monetizationError('User document not found', tag: 'MONETIZATION_CONTROLLER');
        return;
      }

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String? ?? 'voter';

      AppLogger.monetization('User Role: $userRole', tag: 'MONETIZATION_CONTROLLER');

      // Load all plans first
      final allPlans = await _repository.getAllPlans();

      // Filter plans based on user role and election type
      List<SubscriptionPlan> filteredPlans;
      if (userRole == 'candidate') {
        // For candidates, get their election type and filter plans
        final userElectionType = await getUserElectionType(currentUser.uid);
        AppLogger.monetization('🏛️ CANDIDATE USER: Election type: $userElectionType');

        if (userElectionType != null) {
          // Show plans that have pricing for this election type + voter plans + free plans + highlight plans
          filteredPlans = allPlans.where((plan) {
            // Always include voter plans (XP plans)
            if (plan.type == 'voter') return true;

            // Always include free plans
            if (plan.planId == 'free_plan') return true;

            // Always include highlight plans for candidates
            if (plan.type == 'highlight') return true;

            // Include candidate plans that have pricing for user's election type
            return plan.pricing.containsKey(userElectionType) &&
                plan.pricing[userElectionType]!.isNotEmpty;
          }).toList();

          AppLogger.monetization(
            '🏛️ CANDIDATE USER: Showing ${filteredPlans.length} plans for election type: $userElectionType',
          );
        } else {
          // If election type cannot be determined, show all plans
          filteredPlans = allPlans;
          AppLogger.monetization(
            '🏛️ CANDIDATE USER: Could not determine election type, showing all ${allPlans.length} plans',
          );
        }
      } else {
        // Voters see only XP plans
        filteredPlans = allPlans.where((plan) => plan.type == 'voter').toList();
        AppLogger.monetization(
          '🗳️ VOTER USER: Showing only ${filteredPlans.length} XP plans',
        );
      }

      plans.value = filteredPlans;

      // Update cache flags
      _plansLoaded = true;
      _lastPlansLoadTime = DateTime.now();

      AppLogger.monetization(
        '✅ MONETIZATION CONTROLLER: Successfully loaded ${filteredPlans.length} plans for $userRole (cached: $_plansLoaded)',
      );

      // Debug log each plan with all its features
      for (var plan in allPlans) {
        AppLogger.monetization('📋 PLAN DETAILS: ${plan.name} (${plan.planId})');
        AppLogger.monetization('   💰 Type: ${plan.type} (pricing structure updated)');
        AppLogger.monetization('   🏷️  Type: ${plan.type}');
        AppLogger.monetization('   ✅ Active: ${plan.isActive}');

        // Dashboard Tabs Debug (only for candidate plans)
        if (plan.dashboardTabs != null) {
          AppLogger.monetization('   📊 DASHBOARD TABS:');
          AppLogger.monetization(
            '      🏠 Basic Info: ${plan.dashboardTabs!.basicInfo.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.basicInfo.permissions}',
          );

          AppLogger.monetization(
            '      📄 Manifesto: ${plan.dashboardTabs!.manifesto.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.manifesto.permissions}',
          );
          AppLogger.monetization(
            '         Features: TextOnly=${plan.dashboardTabs!.manifesto.features.textOnly}, PDF=${plan.dashboardTabs!.manifesto.features.pdfUpload}, Video=${plan.dashboardTabs!.manifesto.features.videoUpload}',
          );
          AppLogger.monetization(
            '         Promises: ${plan.dashboardTabs!.manifesto.features.promises ? '✅' : '❌'} (Max: ${plan.dashboardTabs!.manifesto.features.maxPromises})',
          );

          AppLogger.monetization(
            '      🏆 Achievements: ${plan.dashboardTabs!.achievements.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.achievements.permissions} (Max: ${plan.dashboardTabs!.achievements.maxAchievements})',
          );

          AppLogger.monetization(
            '      📸 Media: ${plan.dashboardTabs!.media.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.media.permissions}',
          );
          AppLogger.monetization(
            '         Limits: ${plan.dashboardTabs!.media.maxMediaItems} items, ${plan.dashboardTabs!.media.maxImagesPerItem} img, ${plan.dashboardTabs!.media.maxVideosPerItem} vid, ${plan.dashboardTabs!.media.maxYouTubeLinksPerItem} links',
          );

          AppLogger.monetization(
            '      📞 Contact: ${plan.dashboardTabs!.contact.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.contact.permissions}',
          );
          AppLogger.monetization(
            '         Features: Basic=${plan.dashboardTabs!.contact.features.basic}, Extended=${plan.dashboardTabs!.contact.features.extended}, Social=${plan.dashboardTabs!.contact.features.socialLinks}, Priority=${plan.dashboardTabs!.contact.features.prioritySupport}',
          );

          AppLogger.monetization(
            '      🎪 Events: ${plan.dashboardTabs!.events.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.events.permissions} (Max: ${plan.dashboardTabs!.events.maxEvents})',
          );

          AppLogger.monetization(
            '      📈 Analytics: ${plan.dashboardTabs!.analytics.enabled ? '✅' : '❌'} - Permissions: ${plan.dashboardTabs!.analytics.permissions}',
          );
          if (plan.dashboardTabs!.analytics.features != null) {
            AppLogger.monetization(
              '         Features: Basic=${plan.dashboardTabs!.analytics.features!.basic}, Advanced=${plan.dashboardTabs!.analytics.features!.advanced}, Full=${plan.dashboardTabs!.analytics.features!.fullDashboard}, RealTime=${plan.dashboardTabs!.analytics.features!.realTime}',
            );
          }
        } else {
          AppLogger.monetization('   📊 DASHBOARD TABS: None (Highlight Plan)');
        }

        // Profile Features Debug
        AppLogger.monetization('   👤 PROFILE FEATURES:');
        AppLogger.monetization(
          '      🏷️  Premium Badge: ${plan.profileFeatures.premiumBadge}',
        );
        AppLogger.monetization(
          '      📢 Sponsored Banner: ${plan.profileFeatures.sponsoredBanner}',
        );
        AppLogger.monetization(
          '      🎠 Highlight Carousel: ${plan.profileFeatures.highlightCarousel}',
        );
        AppLogger.monetization(
          '      📱 Push Notifications: ${plan.profileFeatures.pushNotifications}',
        );
        AppLogger.monetization(
          '      🎯 Multiple Highlights: ${plan.profileFeatures.multipleHighlights}',
        );
        AppLogger.monetization(
          '      👨‍💼 Admin Support: ${plan.profileFeatures.adminSupport}',
        );
        AppLogger.monetization(
          '      🎨 Custom Branding: ${plan.profileFeatures.customBranding}',
        );

        // Log pricing structure
        AppLogger.monetization('   💰 PRICING STRUCTURE:');
        if (plan.pricing.isEmpty) {
          AppLogger.monetization('      ❌ No pricing data available');
        } else {
          plan.pricing.forEach((electionType, validityPricing) {
            AppLogger.monetization('      🗳️  Election Type: $electionType');
            if (validityPricing.isEmpty) {
              AppLogger.monetization('         ❌ No validity periods');
            } else {
              validityPricing.forEach((days, price) {
                AppLogger.monetization('         ⏰ $days days: ₹$price');
              });
            }
          });
        }

        AppLogger.monetization(
          '   ──────────────────────────────────────────────────────────',
        );
      }
    } catch (e) {
      AppLogger.monetization('❌ MONETIZATION CONTROLLER: Failed to load plans: $e');
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
      AppLogger.monetization('🔍 Getting election type for user: $userId');

      // Get user document to access electionAreas
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        AppLogger.monetization('❌ User document not found');
        return null;
      }

      final userData = userDoc.data()!;
      final electionAreas = userData['electionAreas'] as List<dynamic>?;

      if (electionAreas == null || electionAreas.isEmpty) {
        AppLogger.monetization('⚠️ No election areas found for user');
        return null;
      }

      // For candidates, use the first (and typically only) election area
      final primaryArea = electionAreas[0] as Map<String, dynamic>;
      final bodyId = primaryArea['bodyId'] as String;

      final stateId = userData['stateId'];
      final districtId = userData['districtId'];

      if (stateId == null || districtId == null) {
        AppLogger.monetization('⚠️ Missing stateId or districtId');
        return null;
      }

      // Try SQLite cache first for better performance
      AppLogger.monetization('🔍 Checking SQLite cache for body: $bodyId');
      final localDb = LocalDatabaseService();
      final cachedBodies = await localDb.getBodiesForDistrict(districtId);
      final cachedBody = cachedBodies.firstWhereOrNull(
        (body) => body.id == bodyId,
      );

      if (cachedBody != null) {
        AppLogger.monetization('✅ Found body in SQLite cache: ${cachedBody.type}');
        return _mapBodyTypeToElectionType(cachedBody.type);
      }

      // Fallback to Firebase if not in cache
      AppLogger.monetization('⚠️ Body not in cache, querying Firebase...');
      final bodyDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .get();

      if (!bodyDoc.exists) {
        AppLogger.monetization('❌ Body document not found in Firebase');
        return null;
      }

      final bodyTypeString = bodyDoc.data()?['type'] as String?;
      AppLogger.monetization('✅ Retrieved body type from Firebase: $bodyTypeString');

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

      return _mapBodyTypeToElectionType(bodyType);
    } catch (e) {
      AppLogger.monetization('❌ Error getting user election type: $e');
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
        AppLogger.monetization('⚠️ Unknown body type: $bodyType');
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
    AppLogger.monetization('STARTING PAYMENT PROCESS WITH ELECTION DATA', tag: 'PAYMENT');
    AppLogger.monetization('Plan ID: $planId', tag: 'PAYMENT');
    AppLogger.monetization('Election Type: $electionType', tag: 'PAYMENT');
    AppLogger.monetization('Validity Days: $validityDays', tag: 'PAYMENT');

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current user
      AppLogger.monetization('👤 Checking user authentication...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetization('❌ User not authenticated');
        errorMessage.value = 'User not authenticated';
        return false;
      }
      AppLogger.monetization('✅ User authenticated: ${currentUser.uid}');

      // Get plan details
      AppLogger.monetization('📋 Fetching plan details...');
      final plan = getPlanById(planId);
      if (plan == null) {
        AppLogger.monetization('❌ Plan not found: $planId');
        errorMessage.value = 'Plan not found';
        return false;
      }
      AppLogger.monetization('✅ Plan found: ${plan.name}');

      // Calculate amount from pricing structure
      final amount = plan.pricing[electionType]?[validityDays];
      if (amount == null) {
        AppLogger.monetization(
          '❌ Invalid pricing for election type $electionType and validity $validityDays',
        );
        errorMessage.value =
            'Invalid plan configuration for your election type';
        return false;
      }
      AppLogger.monetization('✅ Calculated amount: ₹$amount');

      // Check if using mock payment or real Razorpay
      if (useMockPayment.value) {
        AppLogger.monetization('🎯 USING MOCK PAYMENT MODE');

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

        AppLogger.monetization('✅ Mock payment processing completed');

        // Simulate payment success directly
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final paymentId = 'pay_test_$timestamp';
        final orderId =
            'order_${planId}_${electionType}_${validityDays}_$timestamp';
        final signature = 'test_signature_$timestamp';

        AppLogger.monetization('✅ Mock payment successful');
        AppLogger.monetization('   Payment ID: $paymentId');
        AppLogger.monetization('   Order ID: $orderId');

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
        AppLogger.monetization('💳 USING REAL RAZORPAY PAYMENT MODE');

        // Get Razorpay service
        AppLogger.monetization('🔧 Getting Razorpay service...');
        final razorpayService = Get.find<RazorpayService>();
        AppLogger.monetization('✅ Razorpay service obtained');

        // Create order (in production, this should be done on backend)
        AppLogger.monetization('📝 Creating payment order...');
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

        if (orderId == null) {
          AppLogger.monetization(
            '⚠️ Order ID is null (test mode) - proceeding without order',
          );
          // In test mode, we can proceed without order ID
          // Razorpay will handle the payment directly
        } else {
          AppLogger.monetization('✅ Order created: $orderId');
        }

        // Start Razorpay payment with enhanced options for test mode
        AppLogger.monetization('🚀 Starting Razorpay payment with full options...');
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

        AppLogger.monetization('✅ Razorpay payment initiated with all payment options');
        // Payment result will be handled by callbacks
      }

      return true;
    } catch (e) {
      AppLogger.monetizationError('PAYMENT PROCESS ERROR', tag: 'PAYMENT', error: e);
      AppLogger.monetization('Error Type: ${e.runtimeType}', tag: 'PAYMENT');
      AppLogger.monetization('Stack Trace: ${StackTrace.current}', tag: 'PAYMENT');
      errorMessage.value = 'Payment failed: $e';
      return false;
    } finally {
      isLoading.value = false;
      AppLogger.monetization('Payment process loading state reset', tag: 'PAYMENT');
    }
  }

  Future<bool> processPayment(String planId, int amount) async {
    AppLogger.monetization('💰 STARTING PAYMENT PROCESS');
    AppLogger.monetization('   Plan ID: $planId');
    AppLogger.monetization('   Amount: ₹${amount}');

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get current user
      AppLogger.monetization('Checking user authentication...', tag: 'PAYMENT');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.monetizationError('User not authenticated', tag: 'PAYMENT');
        errorMessage.value = 'User not authenticated';
        return false;
      }
      AppLogger.monetization('User authenticated: ${currentUser.uid}', tag: 'PAYMENT');

      // Get plan details
      AppLogger.monetization('Fetching plan details...', tag: 'PAYMENT');
      final plan = getPlanById(planId);
      if (plan == null) {
        AppLogger.monetizationError('Plan not found: $planId', tag: 'PAYMENT');
        errorMessage.value = 'Plan not found';
        return false;
      }
      AppLogger.monetization('Plan found: ${plan.name}', tag: 'PAYMENT');

      // Check if using mock payment or real Razorpay
      if (useMockPayment.value) {
        AppLogger.monetization('USING MOCK PAYMENT MODE', tag: 'PAYMENT');

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

        AppLogger.monetization('Mock payment processing completed', tag: 'PAYMENT');

        // Simulate payment success directly
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final paymentId = 'pay_test_$timestamp';
        final orderId = 'order_${planId}_$timestamp';
        final signature = 'test_signature_$timestamp';

        AppLogger.monetization('Mock payment successful', tag: 'PAYMENT');
        AppLogger.monetization('Payment ID: $paymentId', tag: 'PAYMENT');
        AppLogger.monetization('Order ID: $orderId', tag: 'PAYMENT');

        // Handle payment success directly
        _handleMockPaymentSuccess(paymentId, orderId, signature, planId);
      } else {
        AppLogger.monetization('USING REAL RAZORPAY PAYMENT MODE', tag: 'PAYMENT');

        // Get Razorpay service
        AppLogger.monetization('Getting Razorpay service...', tag: 'PAYMENT');
        final razorpayService = Get.find<RazorpayService>();
        AppLogger.monetization('Razorpay service obtained', tag: 'PAYMENT');

        // Create order (in production, this should be done on backend)
        AppLogger.monetization('📝 Creating payment order...');
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
          AppLogger.monetization(
            '⚠️ Order ID is null (test mode) - proceeding without order',
          );
          // In test mode, we can proceed without order ID
          // Razorpay will handle the payment directly
        } else {
          AppLogger.monetization('✅ Order created: $orderId');
        }

        // Start Razorpay payment with enhanced options for test mode
        AppLogger.monetization('🚀 Starting Razorpay payment with full options...');
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

        AppLogger.monetization('✅ Razorpay payment initiated with all payment options');
        // Payment result will be handled by callbacks
      }

      return true;
    } catch (e) {
      AppLogger.monetization('❌ PAYMENT PROCESS ERROR: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      errorMessage.value = 'Payment failed: $e';
      return false;
    } finally {
      isLoading.value = false;
      AppLogger.monetization('🔄 Payment process loading state reset');
    }
  }

  // Handle successful payment
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    AppLogger.monetization('🎉 PAYMENT SUCCESS HANDLER CALLED');
    AppLogger.monetization('   Payment ID: ${response.paymentId}');
    AppLogger.monetization('   Order ID: ${response.orderId}');
    AppLogger.monetization('   Signature: ${response.signature}');

    // Extract notes from response if available
    final orderParts = response.orderId?.split('_') ?? [];
    AppLogger.monetization('   Order parts: $orderParts');

    if (orderParts.length >= 2) {
      final planId = orderParts[1]; // Extract planId from orderId
      AppLogger.monetization('   Extracted Plan ID: $planId');

      final currentUser = FirebaseAuth.instance.currentUser;
      AppLogger.monetization('   Current User: ${currentUser?.uid ?? 'null'}');

      if (currentUser != null) {
        AppLogger.monetization('🔄 Completing purchase after payment...');
        // Complete the purchase
        _completePurchaseAfterPayment(currentUser.uid, planId);
      } else {
        AppLogger.monetization('❌ No authenticated user found for completing purchase');
      }
    } else {
      AppLogger.monetization('❌ Could not extract plan ID from order ID');
    }

    AppLogger.monetization('🔔 Showing success snackbar');
    Get.snackbar(
      'Success',
      'Payment completed successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Handle payment error
  void handlePaymentError(PaymentFailureResponse response) {
    AppLogger.monetization('❌ PAYMENT ERROR HANDLER CALLED');
    AppLogger.monetization('   Error Code: ${response.code}');
    AppLogger.monetization('   Error Message: ${response.message}');

    errorMessage.value = response.message ?? 'Payment failed';
    AppLogger.monetization('   Set error message: ${errorMessage.value}');

    AppLogger.monetization('🔔 Showing error snackbar');
    Get.snackbar(
      'Payment Failed',
      response.message ?? 'Unknown error occurred',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Handle mock payment success
  void _handleMockPaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
    String planId,
  ) {
    AppLogger.monetization('🎉 MOCK PAYMENT SUCCESS HANDLER CALLED');
    AppLogger.monetization('   Payment ID: $paymentId');
    AppLogger.monetization('   Order ID: $orderId');
    AppLogger.monetization('   Signature: $signature');
    AppLogger.monetization('   Plan ID: $planId');

    final currentUser = FirebaseAuth.instance.currentUser;
    AppLogger.monetization('   Current User: ${currentUser?.uid ?? 'null'}');

    if (currentUser != null) {
      AppLogger.monetization('🔄 Completing purchase after mock payment...');
      // Complete the purchase
      _completePurchaseAfterPayment(currentUser.uid, planId);
    } else {
      AppLogger.monetization('❌ No authenticated user found for completing purchase');
    }

    AppLogger.monetization('🔔 Showing success snackbar');
    Get.snackbar(
      'Payment Successful!',
      'Your payment has been processed successfully.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
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
    AppLogger.monetization('🎉 MOCK PAYMENT SUCCESS HANDLER WITH ELECTION CALLED');
    AppLogger.monetization('   Payment ID: $paymentId');
    AppLogger.monetization('   Order ID: $orderId');
    AppLogger.monetization('   Signature: $signature');
    AppLogger.monetization('   Plan ID: $planId');
    AppLogger.monetization('   Election Type: $electionType');
    AppLogger.monetization('   Validity Days: $validityDays');

    final currentUser = FirebaseAuth.instance.currentUser;
    AppLogger.monetization('   Current User: ${currentUser?.uid ?? 'null'}');

    if (currentUser != null) {
      AppLogger.monetization(
        '🔄 Completing purchase after mock payment with election data...',
      );
      // Complete the purchase with election data
      _completePurchaseAfterPaymentWithElection(
        currentUser.uid,
        planId,
        electionType,
        validityDays,
      );
    } else {
      AppLogger.monetization('❌ No authenticated user found for completing purchase');
    }

    AppLogger.monetization('🔔 Showing success snackbar');
    Get.snackbar(
      'Payment Successful!',
      'Your payment has been processed successfully.',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Complete purchase after successful payment
  Future<void> _completePurchaseAfterPayment(
    String userId,
    String planId,
  ) async {
    AppLogger.monetization('🔄 COMPLETING PURCHASE AFTER PAYMENT');
    AppLogger.monetization('   User ID: $userId');
    AppLogger.monetization('   Plan ID: $planId');

    try {
      AppLogger.monetization('📋 Getting plan details...');
      final plan = getPlanById(planId);
      if (plan == null) {
        AppLogger.monetization('❌ Plan not found, aborting purchase completion');
        return;
      }
      AppLogger.monetization('✅ Plan details: ${plan.name} (${plan.type})');

      // Create subscription record
      AppLogger.monetization('📝 Creating subscription record...');
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

      AppLogger.monetization('✅ Subscription created');

      // Update user based on plan type
      if (plan.type == 'candidate') {
        AppLogger.monetization('👤 Upgrading user to premium candidate...');
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          planId,
          null, // One-time subscription
        );
        AppLogger.monetization('✅ User upgraded to premium candidate');
      }

      // Reload data
      AppLogger.monetization('🔄 Reloading user data...');
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();
      AppLogger.monetization('✅ User data reloaded');

      AppLogger.monetization('🎉 PURCHASE COMPLETED SUCCESSFULLY');
      AppLogger.monetization('   Plan: $planId');
      AppLogger.monetization('   User: $userId');
      AppLogger.monetization('   Type: ${plan.type}');
    } catch (e) {
      AppLogger.monetization('❌ ERROR COMPLETING PURCHASE: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
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
    AppLogger.monetization('🔄 COMPLETING PURCHASE AFTER PAYMENT WITH ELECTION DATA');
    AppLogger.monetization('   User ID: $userId');
    AppLogger.monetization('   Plan ID: $planId');
    AppLogger.monetization('   Election Type: $electionType');
    AppLogger.monetization('   Validity Days: $validityDays');

    try {
      AppLogger.monetization('📋 Getting plan details...');
      final plan = getPlanById(planId);
      if (plan == null) {
        AppLogger.monetization('❌ Plan not found, aborting purchase completion');
        return;
      }
      AppLogger.monetization('✅ Plan details: ${plan.name} (${plan.type})');

      // Calculate amount from pricing structure
      final amountPaid = plan.pricing[electionType]?[validityDays];
      if (amountPaid == null) {
        AppLogger.monetization('❌ Invalid pricing, aborting purchase completion');
        return;
      }

      // Calculate expiration date
      final purchasedAt = DateTime.now();
      final expiresAt = purchasedAt.add(Duration(days: validityDays));

      // Create subscription record with election data
      AppLogger.monetization('📝 Creating subscription record with election data...');
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
      AppLogger.monetization('✅ Subscription created');

      // Update user based on plan type
      if (plan.type == 'candidate') {
        AppLogger.monetization('👤 Upgrading user to premium candidate...');
        await _repository.upgradeUserToPremiumCandidate(userId);
        await _repository.updateUserSubscription(
          userId,
          planId,
          expiresAt, // Now we have an expiration date
        );
        AppLogger.monetization('✅ User upgraded to premium candidate with expiration');

        // For Platinum plan, create welcome content
        if (planId == 'platinum_plan') {
          await _createPlatinumWelcomeContent(userId);
        }
      }

      // Reload data
      AppLogger.monetization('🔄 Reloading user data...');
      await loadUserSubscriptions(userId);
      await loadAnalyticsData();
      AppLogger.monetization('✅ User data reloaded');

      AppLogger.monetization('🎉 PURCHASE COMPLETED SUCCESSFULLY WITH ELECTION DATA');
      AppLogger.monetization('   Plan: $planId');
      AppLogger.monetization('   User: $userId');
      AppLogger.monetization('   Election Type: $electionType');
      AppLogger.monetization('   Validity Days: $validityDays');
      AppLogger.monetization('   Expires: $expiresAt');
    } catch (e) {
      AppLogger.monetization('❌ ERROR COMPLETING PURCHASE WITH ELECTION DATA: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      errorMessage.value = 'Failed to complete purchase: $e';
    }
  }

  // Create welcome content for Platinum users
  Future<void> _createPlatinumWelcomeContent(String userId) async {
    try {
      AppLogger.monetization('🏆 Creating Platinum welcome content for user: $userId');

      // Get candidate data
      final candidateData = await _getCandidateDataForUser(userId);
      if (candidateData == null) {
        AppLogger.monetization('⚠️ No candidate data found for Platinum welcome content');
        return;
      }

      // Get highlight controller
      final highlightController = Get.find<HighlightController>();

      // Create Platinum highlight
      await highlightController.createPlatinumHighlight(
        candidateId: candidateData['candidateId'],
        districtId: candidateData['districtId'],
        bodyId: candidateData['bodyId'],
        wardId: candidateData['wardId'],
        candidateName: candidateData['name'],
        party: candidateData['party'] ?? 'Independent',
        imageUrl: candidateData['photo'],
      );

      // Create welcome sponsored post
      await highlightController.createPushFeedItem(
        candidateId: candidateData['candidateId'],
        wardId: candidateData['wardId'],
        title: '🎉 Platinum Plan Activated!',
        message:
            '${candidateData['name']} is now a Platinum member with maximum visibility!',
        imageUrl: candidateData['photo'],
      );

      AppLogger.monetization('✅ Platinum welcome content created');
    } catch (e) {
      AppLogger.monetization('❌ Error creating Platinum welcome content: $e');
    }
  }

  // Get candidate data for a user
  Future<Map<String, dynamic>?> _getCandidateDataForUser(String userId) async {
    try {
      AppLogger.monetization('🔍 Looking for candidate data for user: $userId');

      // Get user document to find candidate location
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        AppLogger.monetization('❌ User document not found');
        return null;
      }

      final userData = userDoc.data()!;
      final electionAreas = userData['electionAreas'] as List<dynamic>?;

      if (electionAreas == null || electionAreas.isEmpty) {
        AppLogger.monetization('⚠️ No election areas found for user');
        return null;
      }

      // Use first election area
      final primaryArea = electionAreas[0] as Map<String, dynamic>;
      final bodyId = primaryArea['bodyId'] as String;
      final wardId = primaryArea['wardId'] as String;

      // Get candidate data from the old structure (for now)
      final candidateQuery = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(userData['districtId'])
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (candidateQuery.docs.isEmpty) {
        AppLogger.monetization('❌ No candidate found for user');
        return null;
      }

      final candidateData = candidateQuery.docs.first.data();
      candidateData['candidateId'] = candidateQuery.docs.first.id;

      AppLogger.monetization('✅ Found candidate: ${candidateData['name']}');
      return candidateData;
    } catch (e) {
      AppLogger.monetization('❌ Error getting candidate data: $e');
      return null;
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
      AppLogger.monetization('Error loading user status: $e');
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    userStatusLogs.add(logMessage);
    AppLogger.monetization(logMessage);
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

  String get plansTabText {
    final user = currentUserModel.value;
    return user?.role == 'candidate' ? 'Premium Plans' : 'XP Store';
  }

  String get xpTabText {
    return 'XP Plans';
  }

  // Real-time subscription monitoring
  void _setupRealtimeSubscriptionMonitoring() {
    AppLogger.monetization('🔄 Setting up real-time subscription monitoring...');

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
    AppLogger.monetization('👂 Starting user subscription listener for: $userId');

    _subscriptionListener?.cancel(); // Cancel any existing listener

    _subscriptionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            final userModel = UserModel.fromJson(userData);

            // Update reactive variables
            currentUserModel.value = userModel;

            // Check if subscription just expired
            final previousPremium = currentUserModel.value?.premium ?? false;
            final currentPremium = userModel.premium ?? false;

            if (previousPremium && !currentPremium) {
              AppLogger.monetization('⚠️ Subscription expired - user downgraded to free plan');
              // Trigger UI refresh
              update();

              // Show expiration notification
              Get.snackbar(
                'Plan Expired',
                'Your premium plan has expired. Upgrade to continue enjoying premium features.',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
            }
          }
        }, onError: (error) {
          AppLogger.monetization('❌ Error in user subscription listener: $error');
        });
  }

  void _stopUserSubscriptionListener() {
    AppLogger.monetization('🔇 Stopping user subscription listener');
    _subscriptionListener?.cancel();
    _subscriptionListener = null;
  }
}
