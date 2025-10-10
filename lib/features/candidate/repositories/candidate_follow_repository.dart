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


  // Get candidate's actual state ID (helper method)
  Future<String> _getCandidateStateId(String candidateId) async {
    try {
      // First try to get from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final stateId = indexData['stateId'];
        if (stateId != null && stateId.isNotEmpty) {
          return stateId;
        }
      }

      // Fallback: Search across all states to find the candidate
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidateDoc = await wardDoc.reference
                  .collection('candidates')
                  .doc(candidateId)
                  .get();

              if (candidateDoc.exists) {
                return stateDoc.id; // Return the actual state ID
              }
            }
          }
        }
      }

      // Candidate not found in any state
      throw Exception('Candidate $candidateId not found in any state');
    } catch (e) {
      AppLogger.candidateError('Failed to get candidate state ID: $e');
      throw Exception('Unable to determine candidate state: $e');
    }
  }

  // Update candidate index for faster lookups
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
      AppLogger.candidate('Failed to update candidate index: $e');
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

          AppLogger.candidate(
            'Using indexed location for follow: $candidateStateId/$candidateDistrictId/$candidateBodyId/$candidateWardId',
          );
        } else {
          // Fallback: Search across all states to find the candidate
          AppLogger.candidate(
            'Index not found, searching across all states for candidate',
          );
          final statesSnapshot = await _firestore.collection('states').get();

          for (var stateDoc in statesSnapshot.docs) {
            final districtsSnapshot = await stateDoc.reference.collection('districts').get();

            for (var districtDoc in districtsSnapshot.docs) {
              final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

              for (var bodyDoc in bodiesSnapshot.docs) {
                final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

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

      // Ensure we have a valid state ID
      if (candidateStateId == null || candidateStateId!.isEmpty) {
        candidateStateId = await _getCandidateStateId(candidateId);
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
          AppLogger.candidate('Failed to update candidate in new structure: $e');
          AppLogger.candidate('Falling back to legacy candidate structure');
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

      AppLogger.candidate('Successfully followed candidate: $candidateId');
    } catch (e) {
      AppLogger.candidateError('Failed to follow candidate: $e');
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
        candidateStateId = indexData['stateId'];
        candidateDistrictId = indexData['districtId'];
        candidateBodyId = indexData['bodyId'];
        candidateWardId = indexData['wardId'];

        if (candidateStateId == null || candidateStateId!.isEmpty) {
          candidateStateId = await _getCandidateStateId(candidateId);
        }
      } else {
        // Fallback: Search across all states to find the candidate
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

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

      // Ensure we have a valid state ID
      if (candidateStateId == null || candidateStateId!.isEmpty) {
        candidateStateId = await _getCandidateStateId(candidateId);
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
          AppLogger.candidate('Failed to update candidate in new structure: $e');
        }
      }

      // Note: Legacy structure fallback removed - using new state-based structure only
      // Candidates are now stored in states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/candidates/{candidateId}

      // Remove from user's following subcollection
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

      AppLogger.candidate('Successfully unfollowed candidate: $candidateId');
    } catch (e) {
      AppLogger.candidateError('Failed to unfollow candidate: $e');
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
      AppLogger.candidateError('Failed to check follow status: $e');
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(
    String candidateId,
  ) async {
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
        candidateStateId = indexData['stateId'];
        candidateDistrictId = indexData['districtId'];
        candidateBodyId = indexData['bodyId'];
        candidateWardId = indexData['wardId'];

        if (candidateStateId == null || candidateStateId!.isEmpty) {
          candidateStateId = await _getCandidateStateId(candidateId);
        }
      } else {
        // Fallback: Search across all states
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

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

      // Ensure we have a valid state ID
      if (candidateStateId == null || candidateStateId!.isEmpty) {
        candidateStateId = await _getCandidateStateId(candidateId);
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
      AppLogger.candidate('Candidate not found in new structure - followers not available');
      return [];
    } catch (e) {
      AppLogger.candidateError('Failed to get followers: $e');
      throw Exception('Failed to get followers: $e');
    }
  }

  // Get following list for a user
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      final following = snapshot.docs.map((doc) => doc.id).toList();
      AppLogger.candidate('Retrieved ${following.length} following for user $userId');
      return following;
    } catch (e) {
      AppLogger.candidateError('Failed to get following list: $e');
      throw Exception('Failed to get following list: $e');
    }
  }

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(
    String userId,
    String candidateId,
    bool notificationsEnabled,
  ) async {
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
        candidateStateId = indexData['stateId'];
        candidateDistrictId = indexData['districtId'];
        candidateBodyId = indexData['bodyId'];
        candidateWardId = indexData['wardId'];

        if (candidateStateId == null || candidateStateId!.isEmpty) {
          candidateStateId = await _getCandidateStateId(candidateId);
        }
      } else {
        // Fallback: Search across all states
        final statesSnapshot = await _firestore.collection('states').get();

        for (var stateDoc in statesSnapshot.docs) {
          final districtsSnapshot = await stateDoc.reference.collection('districts').get();

          for (var districtDoc in districtsSnapshot.docs) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

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

      // Ensure we have a valid state ID
      if (candidateStateId == null || candidateStateId!.isEmpty) {
        candidateStateId = await _getCandidateStateId(candidateId);
      }

      if (candidateDistrictId == null ||
          candidateBodyId == null ||
          candidateWardId == null) {
        throw Exception('Candidate not found');
      }

      final batch = _firestore.batch();

      // Update in candidate's followers subcollection
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

