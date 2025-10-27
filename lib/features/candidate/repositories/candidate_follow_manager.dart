import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../notifications/services/notification_manager.dart';
import '../../notifications/models/notification_type.dart';
import '../models/candidate_model.dart';
import 'candidate_cache_manager.dart';
import 'candidate_state_manager.dart';

class CandidateFollowManager {
  final FirebaseFirestore _firestore;
  final CandidateCacheManager _cacheManager;
  final CandidateStateManager _stateManager;

  CandidateFollowManager(
    this._firestore,
    this._cacheManager,
    this._stateManager,
  );

  // Delegate cache methods to cache manager
  void invalidateCache(String cacheKey) =>
      _cacheManager.invalidateCache(cacheKey);
  List<String>? _getCachedFollowing(String cacheKey) =>
      _cacheManager.getCachedFollowing(cacheKey);
  void _cacheData(String cacheKey, dynamic data) =>
      _cacheManager.cacheData(cacheKey, data);

  Future<void> followCandidate(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
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
        '🎯 Using provided location for follow: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final batch = _firestore.batch();

      if (candidateDistrictId != null &&
          candidateBodyId != null &&
          candidateWardId != null) {
        // Found in new structure - use new structure paths
        try {
          // Add to candidate's followers subcollection
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

          batch.update(candidateRef, {
            'followersCount': FieldValue.increment(1),
          });
        } catch (e) {
          AppLogger.candidate('⚠️ Failed to update candidate in new structure: $e');
          AppLogger.candidate('🔄 Falling back to legacy candidate structure');
        }
      }

      // Note: Legacy structure fallback removed - using new state-based structure only
      // Candidates are now stored in states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/candidates/{candidateId}

      // Add to user's following subcollection (always in users collection)
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.set(userFollowingRef, {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': notificationsEnabled,
      });

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'followingCount': FieldValue.increment(1)});

      await batch.commit();

      // Send notification to candidate about new follower
      try {
        await _sendNewFollowerNotification(userId, candidateId);
      } catch (e) {
        AppLogger.candidate('⚠️ Failed to send follow notification: $e');
        // Don't fail the follow operation if notification fails
      }

      // Invalidate relevant caches
      invalidateCache('following_$userId');
      if (candidateStateId != null) {
        invalidateCache(
          'candidates_${candidateStateId}_${candidateDistrictId}_${candidateBodyId}_$candidateWardId',
        );
      }
    } catch (e) {
      throw Exception('Failed to follow candidate: $e');
    }
  }

  Future<void> unfollowCandidate(String userId, String candidateId, {
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
        '🎯 Using provided location for unfollow: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      // Now use the location we found above to create the batch operations
      final batch = _firestore.batch();

      if (candidateDistrictId != null &&
          candidateBodyId != null &&
          candidateWardId != null) {
        // Found in new structure - use new structure paths
        try {
          // Remove from candidate's followers subcollection
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

          batch.update(candidateRef, {
            'followersCount': FieldValue.increment(-1),
          });
        } catch (e) {
          AppLogger.candidate('⚠️ Failed to update candidate in new structure: $e');
          AppLogger.candidate('🔄 Falling back to legacy candidate structure');
        }
      }

      // Note: Legacy structure fallback removed - using new state-based structure only
      // Candidates are now stored in states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/candidates/{candidateId}

      // Remove from user's following subcollection (always in users collection)
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.delete(userFollowingRef);

      // Update user's following count
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'followingCount': FieldValue.increment(-1)});

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow candidate: $e');
    }
  }

  // Check if user is following a candidate
  Future<bool> isUserFollowingCandidate(
    String userId,
    String candidateId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Get followers list for a candidate - Now uses candidate.location directly!
  Future<List<Map<String, dynamic>>> getCandidateFollowers(
    Candidate candidate,
  ) async {
    final candidateId = candidate.candidateId;
    try {
      // Get location directly from candidate object (no more searching!)
      final candidateStateId = candidate.location.stateId ?? 'maharashtra';
      final candidateDistrictId = candidate.location.districtId!;
      final candidateBodyId = candidate.location.bodyId!;
      final candidateWardId = candidate.location.wardId!;

      AppLogger.candidate(
        '🎯 Using candidate.location for followers: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      if (candidateDistrictId != null &&
          candidateBodyId != null &&
          candidateWardId != null) {
        // Found in new structure
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
      }

      // Candidate not in new structure - followers functionality may not be available
      AppLogger.candidate(
        '⚠️ Candidate not found in new structure - followers not available',
      );
      return [];
    } catch (e) {
      throw Exception('Failed to get followers: $e');
    }
  }

  // Get following list for a user
  Future<List<String>> getUserFollowing(String userId) async {
    final cacheKey = 'following_$userId';

    // Check cache first
    final cachedFollowing = _getCachedFollowing(cacheKey);
    if (cachedFollowing != null) {
      AppLogger.candidate(
        '⚡ CACHE HIT: Returning ${cachedFollowing.length} cached following for user $userId',
      );
      return cachedFollowing;
    }

    AppLogger.candidate(
      '🔍 CACHE MISS: Fetching following list for user $userId from Firebase',
    );
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      final following = snapshot.docs.map((doc) => doc.id).toList();

      // Cache the results
      _cacheData(cacheKey, following);
      AppLogger.candidate('💾 Cached ${following.length} following for user $userId');

      return following;
    } catch (e) {
      throw Exception('Failed to get following list: $e');
    }
  }

  // OPTIMIZED: Use UserController for user data
  // Get user data by user ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['uid'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      AppLogger.candidateError('Error fetching user data for $userId: $e');
      return null;
    }
  }

  // Update notification settings for a follow relationship - Now uses candidate.location directly!
  Future<void> updateFollowNotificationSettings(
    String userId,
    Candidate candidate,
    bool notificationsEnabled,
  ) async {
    final candidateId = candidate.candidateId;
    try {
      // Get location directly from candidate object (no more expensive lookups!)
      final candidateStateId = candidate.location.stateId ?? 'maharashtra';
      final candidateDistrictId = candidate.location.districtId!;
      final candidateBodyId = candidate.location.bodyId!;
      final candidateWardId = candidate.location.wardId!;

      AppLogger.candidate(
        '🎯 Using candidate.location for notification settings: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
      );

      final batch = _firestore.batch();

      // Update in candidate's followers subcollection (use set with merge to handle both create and update)
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
        'followedAt': FieldValue.serverTimestamp(), // Ensure timestamp exists
      }, SetOptions(merge: true));

      // Update in user's following subcollection (use set with merge to handle both create and update)
      final userFollowingRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(candidateId);

      batch.set(userFollowingRef, {
        'notificationsEnabled': notificationsEnabled,
        'followedAt': FieldValue.serverTimestamp(), // Ensure timestamp exists
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // OPTIMIZED: Use UserController for user data
  // Send notification to candidate when someone follows them
  Future<void> _sendNewFollowerNotification(String followerId, String candidateId) async {
    try {
      // Get follower name
      final followerDoc = await _firestore.collection('users').doc(followerId).get();
      final followerName = followerDoc.data()?['name'] ?? 'Someone';

      // Get candidate info to find their user ID
      // First try to find the candidate document to get the userId
      final candidateQuery = await _firestore
          .collectionGroup('candidates')
          .where('id', isEqualTo: candidateId)
          .limit(1)
          .get();

      if (candidateQuery.docs.isNotEmpty) {
        final candidateData = candidateQuery.docs.first.data();
        final candidateUserId = candidateData['userId'];

        if (candidateUserId != null && candidateUserId != followerId) {
          // Send notification using NotificationManager
          final notificationManager = NotificationManager();
          await notificationManager.sendNotification(
            type: NotificationType.newFollower,
            title: 'New Follower',
            body: '$followerName started following you',
            data: {
              'followerId': followerId,
              'followerName': followerName,
              'candidateId': candidateId,
              'type': 'new_follower',
            },
          );

          AppLogger.candidate('✅ Sent new follower notification to candidate: $candidateUserId');
        }
      }
    } catch (e) {
      AppLogger.candidate('⚠️ Failed to send new follower notification: $e');
      // Don't throw - this shouldn't break the follow operation
    }
  }
}
