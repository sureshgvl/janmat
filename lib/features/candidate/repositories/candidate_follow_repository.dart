import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/data_compression.dart';
import '../../../utils/error_recovery_manager.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/multi_level_cache.dart';
import '../../../utils/app_logger.dart';

class CandidateFollowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCompressionManager _compressionManager = DataCompressionManager();
  final FirebaseDataOptimizer _dataOptimizer = FirebaseDataOptimizer();

  // Optimization systems
  final ErrorRecoveryManager _errorRecovery = ErrorRecoveryManager();
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final MultiLevelCache _cache = MultiLevelCache();




  // Follow a candidate - Optimized version with location params
  Future<void> followCandidate(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? candidateUserId, // The candidate's userId for following collection
  }) async {
    try {
      // Use provided location IDs or defaults
      final candidateStateId = stateId ?? 'maharashtra';
      final candidateDistrictId = districtId!;
      final candidateBodyId = bodyId!;
      final candidateWardId = wardId!;

      AppLogger.candidate(
        'Following candidate at location: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final batch = _firestore.batch();

      // Add to candidate's followers subcollection using embedded location
      final candidateFollowersRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.set(candidateFollowersRef, {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
      });

      // Update candidate's followers count
      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, {'followersCount': FieldValue.increment(1)});

      // Add to user's following subcollection (always in users collection)
      // Use candidateUserId as document ID so we can look up users later
      final followingDocId = candidateUserId ?? candidateId;
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(followingDocId);

      batch.set(userFollowingRef, {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
      });

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'followingCount': FieldValue.increment(1)});

      await batch.commit();

      AppLogger.candidate('Successfully followed candidate: $candidateId');
    } catch (e) {
      AppLogger.candidateError('Failed to follow candidate: $e');
      throw Exception('Failed to follow candidate: $e');
    }
  }

  // Unfollow a candidate - Using location params
  Future<void> unfollowCandidate(String userId, String candidateId, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? candidateUserId, // The candidate's userId for following collection
  }) async {
    try {
      // Use provided location IDs or defaults
      final candidateStateId = stateId ?? 'maharashtra';
      final candidateDistrictId = districtId!;
      final candidateBodyId = bodyId!;
      final candidateWardId = wardId!;

      AppLogger.candidate(
        'Unfollowing candidate at location: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final batch = _firestore.batch();

      // Remove from candidate's followers subcollection using embedded location
      final candidateFollowersRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.delete(candidateFollowersRef);

      // Update candidate's followers count
      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, {'followersCount': FieldValue.increment(-1)});

      // Remove from user's following subcollection
      // Try both candidateId (legacy) and candidateUserId (new) for backward compatibility
      final userFollowingRef1 = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      final userFollowingRef2 = candidateUserId != null && candidateUserId != candidateId
          ? _firestore
              .collection('users')
              .doc(userId)
              .collection('following')
              .doc(candidateUserId)
          : null;

      batch.delete(userFollowingRef1);
      if (userFollowingRef2 != null) {
        batch.delete(userFollowingRef2);
      }

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'followingCount': FieldValue.increment(-1)});

      await batch.commit();

      AppLogger.candidate('Successfully unfollowed candidate: $candidateId');
    } catch (e) {
      AppLogger.candidateError('Failed to unfollow candidate: $e');
      throw Exception('Failed to unfollow candidate: $e');
    }
  }

  // Check if user is following a candidate - FIXED: Handle both candidateId and candidateUserId storage
  Future<bool> isUserFollowingCandidate(
    String userId,
    String candidateId, {
    String? candidateUserId, // Also check this if provided
  }) async {
    try {
      // Try both possible document IDs (backward compatibility): candidateId or candidateUserId
      final candidateIdDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId)
          .get();

      if (candidateIdDoc.exists) {
        return true;
      }

      // Also check candidateUserId if provided (for newer follow operations)
      if (candidateUserId != null && candidateUserId != candidateId) {
        final candidateUserIdDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('following')
            .doc(candidateUserId)
            .get();

        return candidateUserIdDoc.exists;
      }

      return false;
    } catch (e) {
      AppLogger.candidateError('Failed to check follow status: $e');
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Get followers list for a candidate - Using location params
  Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // Use provided location IDs or defaults
      final candidateStateId = stateId ?? 'maharashtra';
      final candidateDistrictId = districtId!;
      final candidateBodyId = bodyId!;
      final candidateWardId = wardId!;

      AppLogger.candidate(
        'Getting followers for candidate at location: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final snapshot = await _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .orderBy('followedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.candidateError('Failed to get followers: $e');
      throw Exception('Failed to get followers: $e');
    }
  }

  // Get following list for a user
  Future<List<Map<String, dynamic>>> getUserFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .orderBy('followedAt', descending: true)
          .get();

      final following = snapshot.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id; // The document ID is the candidate ID being followed
        return data;
      }).toList();

      AppLogger.candidate('Retrieved ${following.length} following for user $userId');
      return following;
    } catch (e) {
      AppLogger.candidateError('Failed to get following list: $e');
      throw Exception('Failed to get following list: $e');
    }
  }

  // Update notification settings for a follow relationship - Using location params
  Future<void> updateFollowNotificationSettings(String userId, String candidateId, bool notificationsEnabled, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // Use provided location IDs or defaults
      final candidateStateId = stateId ?? 'maharashtra';
      final candidateDistrictId = districtId!;
      final candidateBodyId = bodyId!;
      final candidateWardId = wardId!;

      AppLogger.candidate(
        'Updating notifications for candidate at location: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final batch = _firestore.batch();

      // Update in candidate's followers subcollection using embedded location
      final candidateFollowersRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateDistrictId)
          .collection('bodies')
          .doc(candidateBodyId)
          .collection('wards')
          .doc(candidateWardId)
          .collection('candidates')
          .doc(candidateId)
          .collection('followers')
          .doc(userId);

      batch.set(candidateFollowersRef, {
        'notificationsEnabled': notificationsEnabled,
        'followedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update in user's following subcollection
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.set(userFollowingRef, {
        'notificationsEnabled': notificationsEnabled,
        'followedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      AppLogger.candidate('Updated notification settings for candidate: $candidateId');
    } catch (e) {
      AppLogger.candidateError('Failed to update notification settings: $e');
      throw Exception('Failed to update notification settings: $e');
    }
  }
}
