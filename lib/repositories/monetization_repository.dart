import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/plan_model.dart';

class MonetizationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Plan Management

  Future<List<SubscriptionPlan>> getAllPlans() async {
    try {
      final snapshot = await _firestore.collection('plans').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['planId'] = doc.id;
        return SubscriptionPlan.fromJson(data);
      }).toList();
    } catch (e) {
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
      final docRef = await _firestore
          .collection('subscriptions')
          .add(subscription.toJson());
      return docRef.id;
    } catch (e) {
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
      final docRef = await _firestore
          .collection('xp_transactions')
          .add(transaction.toJson());
      return docRef.id;
    } catch (e) {
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
      debugPrint('💰 Updating XP balance for user $userId: $xpAmount');

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
      debugPrint('✅ Created XP transaction: $transactionId');

      // Update user XP balance
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({'xpPoints': FieldValue.increment(xpAmount)});

      debugPrint('✅ Updated user XP balance: +$xpAmount');
    } catch (e) {
      debugPrint('❌ Failed to update XP balance: $e');
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
      await userRef.update({'role': 'candidate_premium', 'premium': true});
    } catch (e) {
      throw Exception('Failed to upgrade user to premium candidate: $e');
    }
  }

  // Analytics and Reporting

  Future<int> getTotalPremiumCandidates() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'candidate_premium')
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
      final batch = _firestore.batch();

      // Candidate plans
      final candidateFirst1000 = _firestore
          .collection('plans')
          .doc('candidate_first_1000');
      batch.set(candidateFirst1000, {
        'name': 'Premium Candidate (First 1000)',
        'type': 'candidate',
        'price': 1999,
        'limit': 1000,
        'features': [
          {
            'name': 'Manifesto CRUD',
            'description': 'Create and edit manifesto',
            'enabled': true,
          },
          {
            'name': 'Media Upload',
            'description': 'Upload images and videos',
            'enabled': true,
          },
          {
            'name': 'Contact Info',
            'description': 'Display contact information',
            'enabled': true,
          },
          {
            'name': 'Followers Analytics',
            'description': 'View follower statistics',
            'enabled': true,
          },
          {
            'name': 'Sponsored Tag',
            'description': 'Get sponsored visibility',
            'enabled': true,
          },
        ],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final candidateAfter1000 = _firestore
          .collection('plans')
          .doc('candidate_after_1000');
      batch.set(candidateAfter1000, {
        'name': 'Premium Candidate',
        'type': 'candidate',
        'price': 5000,
        'features': [
          {
            'name': 'Manifesto CRUD',
            'description': 'Create and edit manifesto',
            'enabled': true,
          },
          {
            'name': 'Media Upload',
            'description': 'Upload images and videos',
            'enabled': true,
          },
          {
            'name': 'Contact Info',
            'description': 'Display contact information',
            'enabled': true,
          },
          {
            'name': 'Followers Analytics',
            'description': 'View follower statistics',
            'enabled': true,
          },
          {
            'name': 'Sponsored Tag',
            'description': 'Get sponsored visibility',
            'enabled': true,
          },
        ],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Voter XP plan
      final voterXP100 = _firestore.collection('plans').doc('voter_xp_100');
      batch.set(voterXP100, {
        'name': 'XP Pack (100 XP)',
        'type': 'voter',
        'price': 299,
        'xpAmount': 100,
        'features': [
          {
            'name': 'Unlock Premium Content',
            'description': 'Access premium candidate content',
            'enabled': true,
          },
          {
            'name': 'Join Chat Rooms',
            'description': 'Participate in premium chat rooms',
            'enabled': true,
          },
          {
            'name': 'Vote in Polls',
            'description': 'Vote in exclusive polls',
            'enabled': true,
          },
          {
            'name': 'Reward Other Voters',
            'description': 'Give XP to other users',
            'enabled': true,
          },
        ],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize default plans: $e');
    }
  }
}
