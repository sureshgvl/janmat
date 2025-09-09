import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TrialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Start a 3-day trial for a new candidate
  Future<void> startTrialForCandidate(String userId) async {
    final now = DateTime.now();
    final trialExpiresAt = now.add(const Duration(days: 3));

    try {
      await _firestore.collection('users').doc(userId).update({
        'trialStartedAt': now.toIso8601String(),
        'trialExpiresAt': trialExpiresAt.toIso8601String(),
        'isTrialActive': true,
        'hasConvertedFromTrial': false,
        'premium': true, // Grant premium access during trial
      });

    debugPrint('✅ Started 3-day trial for candidate: $userId, expires: $trialExpiresAt');
    } catch (e) {
    debugPrint('❌ Failed to start trial for candidate: $e');
      throw Exception('Failed to start trial: $e');
    }
  }

  /// Check if user has an active trial
  Future<bool> isTrialActive(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final isTrialActive = data['isTrialActive'] ?? false;
      final trialExpiresAt = data['trialExpiresAt'];

      if (!isTrialActive || trialExpiresAt == null) return false;

      // Parse expiration date
      DateTime expiresAt;
      if (trialExpiresAt is Timestamp) {
        expiresAt = trialExpiresAt.toDate();
      } else if (trialExpiresAt is String) {
        expiresAt = DateTime.parse(trialExpiresAt);
      } else {
        return false;
      }

      // Check if trial is still valid
      return DateTime.now().isBefore(expiresAt);
    } catch (e) {
    debugPrint('❌ Error checking trial status: $e');
      return false;
    }
  }

  /// Get remaining trial days
  Future<int> getTrialDaysRemaining(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      final data = userDoc.data()!;
      final trialExpiresAt = data['trialExpiresAt'];

      if (trialExpiresAt == null) return 0;

      // Parse expiration date
      DateTime expiresAt;
      if (trialExpiresAt is Timestamp) {
        expiresAt = trialExpiresAt.toDate();
      } else if (trialExpiresAt is String) {
        expiresAt = DateTime.parse(trialExpiresAt);
      } else {
        return 0;
      }

      final now = DateTime.now();
      if (now.isAfter(expiresAt)) return 0;

      return expiresAt.difference(now).inDays + 1; // +1 to include current day
    } catch (e) {
    debugPrint('❌ Error getting trial days remaining: $e');
      return 0;
    }
  }

  /// End trial and revoke premium access
  Future<void> endTrial(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isTrialActive': false,
        'premium': false, // Revoke premium access
      });

    debugPrint('✅ Ended trial for user: $userId');
    } catch (e) {
    debugPrint('❌ Failed to end trial: $e');
      throw Exception('Failed to end trial: $e');
    }
  }

  /// Convert trial user to paid premium
  Future<void> convertTrialToPaid(String userId, {String? planId}) async {
    try {
      final Map<String, dynamic> updates = {
        'hasConvertedFromTrial': true,
        'isTrialActive': false,
        'premium': true,
      };

      if (planId != null) {
        updates['subscriptionPlanId'] = planId;
      }

      await _firestore.collection('users').doc(userId).update(updates);

    debugPrint('✅ Converted trial to paid for user: $userId');
    } catch (e) {
    debugPrint('❌ Failed to convert trial to paid: $e');
      throw Exception('Failed to convert trial: $e');
    }
  }

  /// Check if user has expired trial that needs cleanup
  Future<bool> hasExpiredTrial(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final isTrialActive = data['isTrialActive'] ?? false;
      final trialExpiresAt = data['trialExpiresAt'];

      if (!isTrialActive || trialExpiresAt == null) return false;

      // Parse expiration date
      DateTime expiresAt;
      if (trialExpiresAt is Timestamp) {
        expiresAt = trialExpiresAt.toDate();
      } else if (trialExpiresAt is String) {
        expiresAt = DateTime.parse(trialExpiresAt);
      } else {
        return false;
      }

      // Check if trial has expired
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
    debugPrint('❌ Error checking expired trial: $e');
      return false;
    }
  }

  /// Clean up expired trials (call this periodically or on login)
  Future<void> cleanupExpiredTrials(String userId) async {
    try {
      final hasExpired = await hasExpiredTrial(userId);
      if (hasExpired) {
        await endTrial(userId);
      debugPrint('🧹 Cleaned up expired trial for user: $userId');
      }
    } catch (e) {
    debugPrint('❌ Error cleaning up expired trial: $e');
    }
  }

  /// Get trial statistics for analytics
  Future<Map<String, int>> getTrialStats() async {
    try {
      final users = await _firestore.collection('users').get();

      int activeTrials = 0;
      int expiredTrials = 0;
      int convertedTrials = 0;
      int totalTrials = 0;

      for (var doc in users.docs) {
        final data = doc.data();
        final isTrialActive = data['isTrialActive'] ?? false;
        final hasConverted = data['hasConvertedFromTrial'] ?? false;
        final trialExpiresAt = data['trialExpiresAt'];

        if (trialExpiresAt != null) {
          totalTrials++;

          if (hasConverted) {
            convertedTrials++;
          } else if (isTrialActive) {
            // Check if still active
            DateTime expiresAt;
            if (trialExpiresAt is Timestamp) {
              expiresAt = trialExpiresAt.toDate();
            } else if (trialExpiresAt is String) {
              expiresAt = DateTime.parse(trialExpiresAt);
            } else {
              continue;
            }

            if (DateTime.now().isBefore(expiresAt)) {
              activeTrials++;
            } else {
              expiredTrials++;
            }
          }
        }
      }

      return {
        'totalTrials': totalTrials,
        'activeTrials': activeTrials,
        'expiredTrials': expiredTrials,
        'convertedTrials': convertedTrials,
      };
    } catch (e) {
    debugPrint('❌ Error getting trial stats: $e');
      return {
        'totalTrials': 0,
        'activeTrials': 0,
        'expiredTrials': 0,
        'convertedTrials': 0,
      };
    }
  }
}