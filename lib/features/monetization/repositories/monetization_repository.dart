import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/plan_model.dart';
import '../../../utils/app_logger.dart';

class MonetizationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Plan Management

  Future<List<SubscriptionPlan>> getAllPlans() async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Fetching all plans from database...');
      final snapshot = await _firestore.collection('plans').get();

      AppLogger.monetization('✅ FIRESTORE: Found ${snapshot.docs.length} plan documents');

      // Debug log each document before processing
      for (var doc in snapshot.docs) {
        AppLogger.monetization('📄 PLAN DOCUMENT: ${doc.id}');
        AppLogger.monetization('   Raw Data: ${doc.data()}');
      }

      final plans = snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        AppLogger.monetization('🔄 PROCESSING PLAN: ${doc.id} with data: $data');
        return SubscriptionPlan.fromJson(data);
      }).toList();

      AppLogger.monetization('✅ FIRESTORE: Successfully processed ${plans.length} plans');
      return plans;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to fetch plans: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to fetch plans: $e');
    }
  }

  Future<List<SubscriptionPlan>> getPlansByType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('plans')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch plans by type: $e');
    }
  }

  Future<SubscriptionPlan?> getPlanById(String planId) async {
    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch plan: $e');
    }
  }

  // Subscription Management

  Future<String> createSubscription(UserSubscription subscription) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Creating subscription for user ${subscription.userId}');
      AppLogger.monetization('   Plan ID: ${subscription.planId}');
      AppLogger.monetization('   Plan Type: ${subscription.planType}');
      AppLogger.monetization('   Amount Paid: ${subscription.amountPaid}');
      AppLogger.monetization('   Is Active: ${subscription.isActive}');

      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toJson());

      AppLogger.monetization('✅ FIRESTORE: Subscription created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to create subscription: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['subscriptionId'] = doc.id;
        return UserSubscription.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user subscriptions: $e');
    }
  }

  Future<UserSubscription?> getActiveSubscription(
    String userId,
    String planType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('planType', isEqualTo: planType)
          .where('isActive', isEqualTo: true)
          .orderBy('purchasedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['subscriptionId'] = snapshot.docs.first.id;
        return UserSubscription.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch active subscription: $e');
    }
  }

  Future<void> updateSubscriptionStatus(
    String subscriptionId,
    bool isActive,
  ) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update subscription status: $e');
    }
  }

  // XP Transaction Management

  Future<String> createXPTransaction(XPTransaction transaction) async {
    try {
      AppLogger.monetization('🔥 FIRESTORE: Creating XP transaction for user ${transaction.userId}');
      AppLogger.monetization('   Amount: ${transaction.amount}');
      AppLogger.monetization('   Type: ${transaction.type}');
      AppLogger.monetization('   Description: ${transaction.description}');

      final docRef = await _firestore
          .collection('xp_transactions')
          .add(transaction.toJson());

      AppLogger.monetization('✅ FIRESTORE: XP transaction created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.monetization('❌ FIRESTORE ERROR: Failed to create XP transaction: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to create XP transaction: $e');
    }
  }

  Future<List<XPTransaction>> getUserXPTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('xp_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['transactionId'] = doc.id;
        return XPTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch XP transactions: $e');
    }
  }

  Future<int> getUserXPBalance(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('xp_transactions')
          .where('userId', isEqualTo: userId)
          .get();

      int balance = 0;
      for (var doc in snapshot.docs) {
        final transaction = XPTransaction.fromJson(doc.data());
        balance += transaction.amount;
      }

      return balance;
    } catch (e) {
      throw Exception('Failed to calculate XP balance: $e');
    }
  }

  Future<void> updateUserXPBalance(String userId, int xpAmount) async {
    try {
      AppLogger.monetization('💰 Updating XP balance for user $userId: $xpAmount');

      // Create transaction record
      final transaction = XPTransaction(
        transactionId: '', // Will be set by Firestore
        userId: userId,
        amount: xpAmount,
        type: xpAmount > 0 ? 'earned' : 'spent',
        description: xpAmount > 0 ? 'XP earned from ad' : 'XP spent',
        timestamp: DateTime.now(),
      );

      final transactionId = await createXPTransaction(transaction);
      AppLogger.monetization('✅ Created XP transaction: $transactionId');

      // Update user XP balance
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'xpPoints': FieldValue.increment(xpAmount)});

      AppLogger.monetization('✅ Updated user XP balance: +$xpAmount');
    } catch (e) {
      AppLogger.monetization('❌ Failed to update XP balance: $e');
      throw Exception('Failed to update XP balance: $e');
    }
  }

  // User Subscription Updates

  Future<void> updateUserSubscription(
    String userId,
    String planId,
    DateTime? expiresAt,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'subscriptionPlanId': planId,
        'subscriptionExpiresAt': expiresAt?.toIso8601String(),
        'premium': true,
      });
    } catch (e) {
      throw Exception('Failed to update user subscription: $e');
    }
  }

  Future<void> upgradeUserToPremiumCandidate(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      // Only update premium status, keep the original role unchanged
      await userRef.update({'premium': true});
    } catch (e) {
      throw Exception('Failed to upgrade user to premium candidate: $e');
    }
  }

  // Analytics and Reporting

  Future<int> getTotalPremiumCandidates() async {
    try {
      // Count users who are candidates AND have premium status
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'candidate')
          .where('premium', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get premium candidates count: $e');
    }
  }

  Future<Map<String, int>> getSubscriptionStats() async {
    try {
      final subscriptions = await _firestore.collection('subscriptions').get();
      final plans = await _firestore.collection('plans').get();

      int totalRevenue = 0;
      int activeSubscriptions = 0;

      for (var doc in subscriptions.docs) {
        final subscription = UserSubscription.fromJson(doc.data());
        if (subscription.isActive) {
          activeSubscriptions++;
          totalRevenue += subscription.amountPaid;
        }
      }

      return {
        'totalSubscriptions': subscriptions.docs.length,
        'activeSubscriptions': activeSubscriptions,
        'totalRevenue': totalRevenue,
        'totalPlans': plans.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get subscription stats: $e');
    }
  }

  // Initialize default plans (run once during app setup)
  Future<void> initializeDefaultPlans() async {
    try {
      AppLogger.monetization('🔧 INITIALIZING DEFAULT PLANS...');
      AppLogger.monetization('   This will create/update all candidate plans + highlight/carousel plans in Firestore');
      final batch = _firestore.batch();

      // Candidate plans - Free, Basic, Gold, Platinum
      final freePlan = _firestore.collection('plans').doc('free_plan');
      batch.set(freePlan, {
        'id': 'free_plan',
        'planId': 'free_plan',
        'name': 'Free',
        'type': 'candidate',
        'price': 0,
        'isActive': true,
        'dashboardTabs': {
          'basicInfo': {
            'enabled': true,
            'permissions': ['view', 'edit'],
          },
          'manifesto': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'textOnly': false,
              'pdfUpload': true,
              'videoUpload': false,
              'promises': true,
              'maxPromises': 2,
            },
          },
          'achievements': {
            'enabled': false,
            'permissions': [],
            'maxAchievements': 0,
          },
          'media': {
            'enabled': true,
            'permissions': ['view', 'edit', 'upload'],
            'maxMediaItems': 1,
            'maxImagesPerItem': 1,
            'maxVideosPerItem': 0,
            'maxYouTubeLinksPerItem': 0,
          },
          'contact': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'basic': true,
              'extended': false,
              'socialLinks': false,
            },
          },
          'events': {
            'enabled': false,
            'permissions': [],
            'maxEvents': 0,
          },
          'analytics': {
            'enabled': false,
            'permissions': [],
          },
        },
        'profileFeatures': {
          'premiumBadge': false,
          'sponsoredBanner': false,
          'highlightCarousel': false,
          'pushNotifications': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      final basicPlan = _firestore.collection('plans').doc('basic_plan');
      batch.set(basicPlan, {
        'id': 'basic_plan',
        'planId': 'basic_plan',
        'name': 'Basic',
        'type': 'candidate',
        'price': 499,
        'isActive': true,
        'dashboardTabs': {
          'basicInfo': {
            'enabled': true,
            'permissions': ['view', 'edit'],
          },
          'manifesto': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'textOnly': false,
              'pdfUpload': true,
              'videoUpload': false,
              'promises': true,
              'maxPromises': 5,
            },
          },
          'achievements': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'maxAchievements': 5,
          },
          'media': {
            'enabled': true,
            'permissions': ['view', 'edit', 'upload'],
            'maxMediaItems': 10,
            'maxImagesPerItem': 5,
            'maxVideosPerItem': 1,
            'maxYouTubeLinksPerItem': 2,
          },
          'contact': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'basic': true,
              'extended': true,
              'socialLinks': true,
            },
          },
          'events': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'maxEvents': 3,
          },
          'analytics': {
            'enabled': true,
            'permissions': ['view'],
            'features': {
              'basic': true,
              'advanced': false,
            },
          },
        },
        'profileFeatures': {
          'premiumBadge': true,
          'sponsoredBanner': false,
          'highlightCarousel': false,
          'pushNotifications': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      final goldPlan = _firestore.collection('plans').doc('gold_plan');
      batch.set(goldPlan, {
        'id': 'gold_plan',
        'planId': 'gold_plan',
        'name': 'Gold',
        'type': 'candidate',
        'price': 1499,
        'isActive': true,
        'dashboardTabs': {
          'basicInfo': {
            'enabled': true,
            'permissions': ['view', 'edit'],
          },
          'manifesto': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'textOnly': false,
              'pdfUpload': true,
              'videoUpload': true,
              'promises': true,
              'maxPromises': 5,
            },
          },
          'achievements': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'maxAchievements': -1,
          },
          'media': {
            'enabled': true,
            'permissions': ['view', 'edit', 'upload'],
            'maxMediaItems': -1,
            'maxImagesPerItem': 10,
            'maxVideosPerItem': 5,
            'maxYouTubeLinksPerItem': 5,
          },
          'contact': {
            'enabled': true,
            'permissions': ['view', 'edit'],
            'features': {
              'basic': true,
              'extended': true,
              'socialLinks': true,
            },
          },
          'events': {
            'enabled': true,
            'permissions': ['view', 'edit', 'manage'],
            'maxEvents': -1,
          },
          'analytics': {
            'enabled': true,
            'permissions': ['view', 'export'],
            'features': {
              'basic': true,
              'advanced': true,
            },
          },
        },
        'profileFeatures': {
          'premiumBadge': true,
          'sponsoredBanner': true,
          'highlightCarousel': true,
          'pushNotifications': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      final platinumPlan = _firestore.collection('plans').doc('platinum_plan');
      batch.set(platinumPlan, {
        'id': 'platinum_plan',
        'planId': 'platinum_plan',
        'name': 'Platinum',
        'type': 'candidate',
        'price': 2999,
        'isActive': true,
        'dashboardTabs': {
          'basicInfo': {
            'enabled': true,
            'permissions': ['view', 'edit'],
          },
          'manifesto': {
            'enabled': true,
            'permissions': ['view', 'edit', 'priority'],
            'features': {
              'textOnly': false,
              'pdfUpload': true,
              'videoUpload': true,
              'promises': true,
              'maxPromises': 10,
              'multipleVersions': true,
            },
          },
          'achievements': {
            'enabled': true,
            'permissions': ['view', 'edit', 'featured'],
            'maxAchievements': -1,
          },
          'media': {
            'enabled': true,
            'permissions': ['view', 'edit', 'upload', 'priority'],
            'maxMediaItems': -1,
            'maxImagesPerItem': -1,
            'maxVideosPerItem': -1,
            'maxYouTubeLinksPerItem': -1,
          },
          'contact': {
            'enabled': true,
            'permissions': ['view', 'edit', 'priority'],
            'features': {
              'basic': true,
              'extended': true,
              'socialLinks': true,
              'prioritySupport': true,
            },
          },
          'events': {
            'enabled': true,
            'permissions': ['view', 'edit', 'manage', 'featured'],
            'maxEvents': -1,
          },
          'analytics': {
            'enabled': true,
            'permissions': ['view', 'export', 'realTime'],
            'features': {
              'basic': true,
              'advanced': true,
              'fullDashboard': true,
              'realTime': true,
            },
          },
        },
        'profileFeatures': {
          'sponsoredBanner': true,
          'pushNotifications': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });


      // Highlight plan (banner only)
      final highlightPlan = _firestore.collection('plans').doc('highlight_plan');
      batch.set(highlightPlan, {
        'id': 'highlight_plan',
        'planId': 'highlight_plan',
        'name': 'Highlight',
        'type': 'highlight',
        'pricing': {
          'municipal_corporation': {'30': 299, '90': 799},
          'municipal_council': {'30': 249, '90': 649},
          'nagar_panchayat': {'30': 199, '90': 549},
          'zila_parishad': {'30': 249, '90': 649},
          'panchayat_samiti': {'30': 199, '90': 549},
          'parliamentary': {'30': 499, '90': 1299},
          'assembly': {'30': 399, '90': 999},
        },
        'isActive': true,
        'profileFeatures': {
          'premiumBadge': false,
          'sponsoredBanner': false,
          'highlightCarousel': true,
          'pushNotifications': false,
        },
        'highlightFeatures': {
          'maxHighlights': 4,
          'priority': 'normal',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Carousel plan (carousel features)
      final carouselPlan = _firestore.collection('plans').doc('carousel_plan');
      batch.set(carouselPlan, {
        'id': 'carousel_plan',
        'planId': 'carousel_plan',
        'name': 'Carousel',
        'type': 'carousel',
        'pricing': {
          'municipal_corporation': {'30': 799, '90': 1999},
          'municipal_council': {'30': 649, '90': 1599},
          'nagar_panchayat': {'30': 499, '90': 1299},
          'zila_parishad': {'30': 699, '90': 1699},
          'panchayat_samiti': {'30': 599, '90': 1499},
          'parliamentary': {'30': 1499, '90': 3499},
          'assembly': {'30': 1199, '90': 2799},
        },
        'isActive': true,
        'profileFeatures': {
          'premiumBadge': false,
          'sponsoredBanner': false,
          'highlightCarousel': true,
          'pushNotifications': false,
          'multipleHighlights': true,
          'carouselPriority': true,
          'exclusivePlacement': false,
        },
        'carouselFeatures': {
          'maxCarouselSlots': 6,
          'priority': 'high',
          'autoRotation': true,
          'customTiming': false,
          'analyticsAccess': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.monetization('✅ DEFAULT PLANS INITIALIZED SUCCESSFULLY');
      AppLogger.monetization('   Created/Updated: Free, Basic, Gold, Platinum, Highlight, Carousel plans');
      AppLogger.monetization('   All plans are now ready for use');
    } catch (e) {
      AppLogger.monetization('❌ FAILED TO INITIALIZE DEFAULT PLANS: $e');
      AppLogger.monetization('   Error Type: ${e.runtimeType}');
      AppLogger.monetization('   Stack Trace: ${StackTrace.current}');
      throw Exception('Failed to initialize default plans: $e');
    }
  }
}

