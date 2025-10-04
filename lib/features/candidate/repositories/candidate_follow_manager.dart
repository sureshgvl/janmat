import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
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
  void invalidateCache(String cacheKey) => _cacheManager.invalidateCache(cacheKey);
  List<String>? _getCachedFollowing(String cacheKey) => _cacheManager.getCachedFollowing(cacheKey);
  void _cacheData(String cacheKey, dynamic data) => _cacheManager.cacheData(cacheKey, data);

  // Helper method for updating candidate index
  Future<void> _updateCandidateIndex(
    String candidateId,
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      await _firestore.collection('candidate_index').doc(candidateId).set({
        'stateId': stateId,
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Failed to update candidate index: $e');
      // Don't throw - this is not critical
    }
  }

  // Follow a candidate - Optimized version with location parameters
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
      // Use provided location parameters if available, otherwise search
      String? candidateStateId = stateId;
      String? candidateDistrictId = districtId;
      String? candidateBodyId = bodyId;
      String? candidateWardId = wardId;

      // If location not provided, try to get from index or search
      if (candidateStateId == null || candidateDistrictId == null ||
          candidateBodyId == null || candidateWardId == null) {

        // First try to get location from index
        final indexDoc = await _firestore
            .collection('candidate_index')
            .doc(candidateId)
            .get();

        if (indexDoc.exists) {
          final indexData = indexDoc.data()!;
          candidateStateId ??= indexData['stateId'];
          candidateDistrictId ??= indexData['districtId'];
          candidateBodyId ??= indexData['bodyId'];
          candidateWardId ??= indexData['wardId'];

          debugPrint(
            '🎯 Using indexed location for follow: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
          );
        } else {
          // Fallback: Search across all states to find the candidate
          debugPrint(
            '🔄 Index not found, searching across all states for candidate',
          );
          final statesSnapshot = await _firestore.collection('states').get();

          for (var stateDoc in statesSnapshot.docs) {
            final districtsSnapshot = await stateDoc.reference.collection('districts').get();

            for (var districtDoc in districtsSnapshot.docs) {
              final bodiesSnapshot = await districtDoc.reference
                  .collection('bodies')
                  .get();

              for (var bodyDoc in bodiesSnapshot.docs) {
                final wardsSnapshot = await bodyDoc.reference
                    .collection('wards')
                    .get();

                for (var wardDoc in wardsSnapshot.docs) {
                  final candidateDoc = await wardDoc.reference
                      .collection('candidates')
                      .doc(candidateId)
                      .get();

                  if (candidateDoc.exists) {
                    candidateStateId = stateDoc.id;
                    candidateDistrictId = districtDoc.id;
                    candidateBodyId = bodyDoc.id;
                    candidateWardId = wardDoc.id;

                    // Update index for future queries
                    await _updateCandidateIndex(
                      candidateId,
                      stateDoc.id,
                      districtDoc.id,
                      bodyDoc.id,
                      wardDoc.id,
                    );
                    break;
                  }
                }
                if (candidateDistrictId != null) break;
              }
              if (candidateDistrictId != null) break;
            }
            if (candidateDistrictId != null) break;
          }
        }
      }

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

          batch.update(candidateRef, {'followersCount': FieldValue.increment(1)});
        } catch (e) {
          debugPrint('⚠️ Failed to update candidate in new structure: $e');
          debugPrint('🔄 Falling back to legacy candidate structure');
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

  // Unfollow a candidate
  Future<void> unfollowCandidate(String userId, String candidateId) async {
    try {
      // First try to get location from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();
      String? candidateStateId;
      String? candidateDistrictId;
      String? candidateBodyId;
      String? candidateWardId;

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        candidateStateId = indexData['stateId']; // Get actual state ID
        if (candidateStateId == null) {
          throw Exception('Candidate $candidateId not found in index or missing state information');
        }
        candidateDistrictId = indexData['districtId'];
        candidateBodyId = indexData['bodyId'];
        candidateWardId = indexData['wardId'];
        debugPrint(
          '🎯 Using indexed location for unfollow: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
        );
      } else {
        // Fallback: Search across all states to find the candidate
        debugPrint(
          '🔄 Index not found, searching across all states for candidate',
        );
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference
                .collection('bodies')
                .get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference
                  .collection('wards')
                  .get();

              for (var wardDoc in wardsSnapshot.docs) {
                final candidateDoc = await wardDoc.reference
                    .collection('candidates')
                    .doc(candidateId)
                    .get();

                if (candidateDoc.exists) {
                  candidateStateId = stateDoc.id; // Get actual state ID
                  candidateDistrictId = districtDoc.id;
                  candidateBodyId = bodyDoc.id;
                  candidateWardId = wardDoc.id;

                  // Update index for future queries
                  await _updateCandidateIndex(
                    candidateId,
                    stateDoc.id,
                    districtDoc.id,
                    bodyDoc.id,
                    wardDoc.id,
                  );
                  break;
                }
              }
              if (candidateDistrictId != null) break;
            }
            if (candidateDistrictId != null) break;
          }
          if (candidateDistrictId != null) break;
        }
      }

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

          batch.update(candidateRef, {'followersCount': FieldValue.increment(-1)});
        } catch (e) {
          debugPrint('⚠️ Failed to update candidate in new structure: $e');
          debugPrint('🔄 Falling back to legacy candidate structure');
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

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(
    String candidateId,
  ) async {
    try {
      // First find the candidate's location in the new state/district/body/ward structure
      // Get candidate's state first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      String? candidateStateId;

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        candidateStateId = indexData['stateId'];
      }

      if (candidateStateId == null) {
        // Fallback: Search across all states to find the candidate
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

              for (var wardDoc in wardsSnapshot.docs) {
                final candidateDoc = await wardDoc.reference.collection('candidates').doc(candidateId).get();

                if (candidateDoc.exists) {
                  candidateStateId = stateDoc.id;
                  break;
                }
              }
              if (candidateStateId != null) break;
            }
            if (candidateStateId != null) break;
          }
          if (candidateStateId != null) break;
        }
      }

      if (candidateStateId == null) {
        debugPrint('⚠️ Candidate not found in any state - followers not available');
        return [];
      }

      final districtsSnapshot = await _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .get();
      String? candidateDistrictId;
      String? candidateBodyId;
      String? candidateWardId;

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference
            .collection('bodies')
            .get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference
              .collection('wards')
              .get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateDoc = await wardDoc.reference
                .collection('candidates')
                .doc(candidateId)
                .get();

            if (candidateDoc.exists) {
              candidateDistrictId = districtDoc.id;
              candidateBodyId = bodyDoc.id;
              candidateWardId = wardDoc.id;
              break;
            }
          }
          if (candidateDistrictId != null) break;
        }
        if (candidateDistrictId != null) break;
      }

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
      debugPrint('⚠️ Candidate not found in new structure - followers not available');
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
      debugPrint(
        '⚡ CACHE HIT: Returning ${cachedFollowing.length} cached following for user $userId',
      );
      return cachedFollowing;
    }

    debugPrint(
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
      debugPrint('💾 Cached ${following.length} following for user $userId');

      return following;
    } catch (e) {
      throw Exception('Failed to get following list: $e');
    }
  }

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
      debugPrint('Error fetching user data for $userId: $e');
      return null;
    }
  }

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(
    String userId,
    String candidateId,
    bool notificationsEnabled,
  ) async {
    try {
      // First find the candidate's location in the new state/district/body/ward structure
      // Get candidate's state first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      String? candidateStateId;

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        candidateStateId = indexData['stateId'];
      }

      if (candidateStateId == null) {
        // Fallback: Search across all states to find the candidate
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

              for (var wardDoc in wardsSnapshot.docs) {
                final candidateDoc = await wardDoc.reference.collection('candidates').doc(candidateId).get();

                if (candidateDoc.exists) {
                  candidateStateId = stateDoc.id;
                  break;
                }
              }
              if (candidateStateId != null) break;
            }
            if (candidateStateId != null) break;
          }
          if (candidateStateId != null) break;
        }
      }

      if (candidateStateId == null) {
        throw Exception('Candidate not found');
      }

      final districtsSnapshot = await _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .get();
      String? candidateDistrictId;
      String? candidateBodyId;
      String? candidateWardId;

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference
            .collection('bodies')
            .get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference
              .collection('wards')
              .get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateDoc = await wardDoc.reference
                .collection('candidates')
                .doc(candidateId)
                .get();

            if (candidateDoc.exists) {
              candidateDistrictId = districtDoc.id;
              candidateBodyId = bodyDoc.id;
              candidateWardId = wardDoc.id;
              break;
            }
          }
          if (candidateDistrictId != null) break;
        }
        if (candidateDistrictId != null) break;
      }

      if (candidateDistrictId == null ||
          candidateBodyId == null ||
          candidateWardId == null) {
        throw Exception('Candidate not found');
      }

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
}

