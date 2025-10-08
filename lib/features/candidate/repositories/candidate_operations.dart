
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/candidate_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/data_compression.dart';
import '../../../utils/error_recovery_manager.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/multi_level_cache.dart';
import 'candidate_cache_manager.dart';
import 'candidate_state_manager.dart';
import '../../../utils/app_logger.dart';

class CandidateOperations {
  final FirebaseFirestore _firestore;
  final DataCompressionManager _compressionManager;
  final FirebaseDataOptimizer _dataOptimizer;
  final ErrorRecoveryManager _errorRecovery;
  final AdvancedAnalyticsManager _analytics;
  final MultiLevelCache _cache;
  final CandidateCacheManager _cacheManager;


  CandidateOperations(
    this._firestore,
    this._compressionManager,
    this._dataOptimizer,
    this._errorRecovery,
    this._analytics,
    this._cache,
    this._cacheManager,
  );

  // Delegate cache methods to cache manager
  void invalidateCache(String cacheKey) => _cacheManager.invalidateCache(cacheKey);

  // Create a new candidate (self-registration) - Updated with proper state handling
  Future<String> createCandidate(Candidate candidate, {String? stateId}) async {
    try {
      AppLogger.candidate('🏗️ Creating candidate: ${candidate.name}');
      AppLogger.candidate('   District: ${candidate.districtId}');
      AppLogger.candidate('   Body: ${candidate.bodyId}');
      AppLogger.candidate('   Ward: ${candidate.wardId}');
      AppLogger.candidate('   UserId: ${candidate.userId}');

      // Determine state ID - use provided parameter or try to detect from location
      String finalStateId = stateId ?? await _determineStateId(candidate.districtId, candidate.bodyId, candidate.wardId) ?? 'maharashtra';

      AppLogger.candidate('🎯 Using state ID: $finalStateId');

      final candidateData = candidate.toJson();
      candidateData['approved'] = false; // Default to not approved
      candidateData['status'] = 'pending_election'; // Default status
      candidateData['createdAt'] = FieldValue.serverTimestamp();

      // Optimize data for storage (compress if beneficial)
      final optimizedData = _dataOptimizer.optimizeForSave(candidateData);

      // Use the candidateId if provided, otherwise let Firestore generate one
      final docRef =
          candidate.candidateId.isNotEmpty &&
              !candidate.candidateId.startsWith('temp_')
          ? _firestore
                .collection('states')
                .doc(finalStateId)
                .collection('districts')
                .doc(candidate.districtId)
                .collection('bodies')
                .doc(candidate.bodyId)
                .collection('wards')
                .doc(candidate.wardId)
                .collection('candidates')
                .doc(candidate.candidateId)
          : _firestore
                .collection('states')
                .doc(finalStateId)
                .collection('districts')
                .doc(candidate.districtId)
                .collection('bodies')
                .doc(candidate.bodyId)
                .collection('wards')
                .doc(candidate.wardId)
                .collection('candidates')
                .doc();

      AppLogger.candidate('📝 Creating candidate at path: states/$finalStateId/districts/${candidate.districtId}/bodies/${candidate.bodyId}/wards/${candidate.wardId}/candidates/${docRef.id}');

      await docRef.set(optimizedData);
      AppLogger.candidate('✅ Candidate document created successfully with ID: ${docRef.id}');

      // Update candidate index for faster lookups with correct state ID
      await _updateCandidateIndex(
        docRef.id,
        finalStateId, // Use actual state ID instead of hardcoded value
        candidate.districtId,
        candidate.bodyId,
        candidate.wardId,
      );

      // Invalidate relevant caches with correct state ID
      invalidateCache(
        'candidates_${finalStateId}_${candidate.districtId}_${candidate.bodyId}_${candidate.wardId}',
      );

      // Return the actual document ID (in case it was auto-generated)
      return docRef.id;
    } catch (e) {
      AppLogger.candidateError('❌ Failed to create candidate: $e');
      throw Exception('Failed to create candidate: $e');
    }
  }

  // Helper method to determine state ID from location information
  Future<String?> _determineStateId(String? districtId, String? bodyId, String? wardId) async {
    if (districtId == null || bodyId == null || wardId == null) {
      return null;
    }

    try {
      // Try to find the state by searching through the hierarchy
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          if (districtDoc.id == districtId) {
            final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

            for (var bodyDoc in bodiesSnapshot.docs) {
              if (bodyDoc.id == bodyId) {
                final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

                for (var wardDoc in wardsSnapshot.docs) {
                  if (wardDoc.id == wardId) {
                    AppLogger.candidate('🎯 Found state ID: ${stateDoc.id} for location $districtId/$bodyId/$wardId');
                    return stateDoc.id;
                  }
                }
              }
            }
          }
        }
      }

      AppLogger.candidate('⚠️ Could not determine state ID for location $districtId/$bodyId/$wardId, using default');
      return null; // Will fall back to 'maharashtra' in calling method
    } catch (e) {
      AppLogger.candidateError('❌ Error determining state ID: $e');
      return null;
    }
  }

  // Get candidate data by user ID (optimized)
  Future<Candidate?> getCandidateData(String userId) async {
    try {
      AppLogger.candidate(
        '🔍 Candidate Repository: Searching for candidate data for userId: $userId',
      );

      // Check if user is still authenticated before proceeding
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        AppLogger.candidate('🚫 User authentication lost during candidate data fetch, aborting');
        return null;
      }

      // First, get the user's districtId, bodyId and wardId from their user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        AppLogger.candidate('❌ User document not found for userId: $userId');
        AppLogger.candidate(
          '🔄 Falling back to brute force search due to missing user document',
        );
        // Fallback to brute force search if user document doesn't exist
        return await _getCandidateDataBruteForce(userId);
      }

      final userData = userDoc.data()!;
      final userModel = UserModel.fromJson(userData);
      String? districtId = userModel.districtId;
      String? bodyId = userModel.bodyId;
      String? wardId = userModel.wardId;

      if (districtId == null ||
          wardId == null ||
          districtId.isEmpty ||
          wardId.isEmpty) {
        AppLogger.candidate(
          '⚠️ User has no districtId or wardId, falling back to brute force search',
        );
        // Fallback to the old method if location info is missing
        return await _getCandidateDataBruteForce(userId);
      }

      AppLogger.candidate(
        '🎯 Direct search: District: $districtId, Body: $bodyId, Ward: $wardId',
      );

      // Direct query to the specific state/district/body/ward path
      final candidatesSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(
            bodyId ?? '',
          ) // Empty string if bodyId is null for backward compatibility
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      AppLogger.candidate(
        '👤 Found ${candidatesSnapshot.docs.length} candidates in $districtId/$bodyId/$wardId',
      );

      if (candidatesSnapshot.docs.isNotEmpty) {
        final doc = candidatesSnapshot.docs.first;
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;

        AppLogger.candidate('📄 Raw candidate data from DB:');
        final extraInfo = data['extra_info'] as Map<String, dynamic>?;
        AppLogger.candidate('   extra_info keys: ${extraInfo?.keys.toList() ?? 'null'}');
        AppLogger.candidate('   education in extra_info: ${extraInfo?.containsKey('education') ?? false}');
        AppLogger.candidate(
          '   education value: ${extraInfo != null && extraInfo.containsKey('education') ? extraInfo['education'] : 'not found'}',
        );

        AppLogger.candidate(
          '✅ Found candidate: ${candidateData['name']} (ID: ${doc.id})',
        );
        return Candidate.fromJson(candidateData);
      }

      AppLogger.candidate(
        '❌ No candidate found in user\'s district/body/ward: $districtId/$bodyId/$wardId',
      );

      // Fallback: Check legacy /candidates collection
      AppLogger.candidate('🔄 Checking legacy /candidates collection for userId: $userId');

      // First try exact match
      final legacyCandidateDoc = await _firestore
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (legacyCandidateDoc.docs.isNotEmpty) {
        final doc = legacyCandidateDoc.docs.first;
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;

        AppLogger.candidate(
          '✅ Found candidate in legacy collection: ${candidateData['name']} (ID: ${doc.id})',
        );
        AppLogger.candidate('   userId in doc: ${candidateData['userId']}');

        // Update user document with location info for future use
        await ensureUserDocumentExists(
          userId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
        );

        return Candidate.fromJson(candidateData);
      }

      // If no exact match, try to find any candidate documents to debug
      AppLogger.candidate('🔍 No exact match, checking all candidates in legacy collection...');
      final allCandidates = await _firestore.collection('candidates').limit(10).get();
      AppLogger.candidate('📊 Found ${allCandidates.docs.length} total candidates in legacy collection');

      for (var doc in allCandidates.docs) {
        final data = doc.data();
        AppLogger.candidate('   Candidate ${doc.id}: userId=${data['userId']}, name=${data['name']}');
      }

      AppLogger.candidate('❌ No candidate found in legacy collection either');
      return null;
    } catch (e) {
      AppLogger.candidateError('❌ Error fetching candidate data: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Optimized brute force search (limited to user's selected district)
  Future<Candidate?> _getCandidateDataBruteForce(String userId) async {
    AppLogger.candidate('🔍 Falling back to targeted brute force search for userId: $userId');

    try {
      // First try to get user's selected location from their profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      String? userStateId;
      String? userDistrictId;
      String? userBodyId;

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);
        userStateId = userModel.stateId;
        userDistrictId = userModel.districtId;
        userBodyId = userModel.bodyId;
        final userWardId = userModel.wardId;

        AppLogger.candidate('🎯 Found user location: State: $userStateId, District: $userDistrictId, Body: $userBodyId, Ward: $userWardId');
      }

      // If user has selected a district, search only in that district
      if (userDistrictId != null && userDistrictId.isNotEmpty) {
        AppLogger.candidate('🎯 Searching only in user\'s selected district: $userDistrictId');
        return await _searchInSpecificDistrict(userId, userDistrictId, userBodyId);
      }

      // Fallback: Search in user's state (limited scope)
      final searchStateId = userStateId ?? 'maharashtra'; // Temporary default
      AppLogger.candidate('🔍 Searching in user\'s state: $searchStateId');

      final districtsSnapshot = await _firestore
          .collection('states')
          .doc(searchStateId)
          .collection('districts')
          .limit(5) // Limit to first 5 districts for performance
          .get();
      AppLogger.candidate('📊 Found ${districtsSnapshot.docs.length} districts to search in $searchStateId (limited to 5)');

      for (var districtDoc in districtsSnapshot.docs) {
        AppLogger.candidate('🔍 Searching district: ${districtDoc.id}');
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').limit(3).get();
        AppLogger.candidate('📊 Found ${bodiesSnapshot.docs.length} bodies in district ${districtDoc.id} (limited to 3)');

        for (var bodyDoc in bodiesSnapshot.docs) {
          AppLogger.candidate('🔍 Searching body: ${bodyDoc.id} in district ${districtDoc.id}');
          final wardsSnapshot = await bodyDoc.reference.collection('wards').limit(5).get();
          AppLogger.candidate('📊 Found ${wardsSnapshot.docs.length} wards in ${districtDoc.id}/${bodyDoc.id} (limited to 5)');

          for (var wardDoc in wardsSnapshot.docs) {
            AppLogger.candidate('🔍 Searching ward: ${wardDoc.id} in ${districtDoc.id}/${bodyDoc.id}');
            final candidatesSnapshot = await wardDoc.reference
                .collection('candidates')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

            if (candidatesSnapshot.docs.isNotEmpty) {
              final doc = candidatesSnapshot.docs.first;
              final data = doc.data();
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = doc.id;

              // Update user document with district/body/ward info for future use
              await ensureUserDocumentExists(
                userId,
                districtId: districtDoc.id,
                bodyId: bodyDoc.id,
                wardId: wardDoc.id,
              );

              AppLogger.candidate('✅ Found candidate via targeted search: ${candidateData['name']} (ID: ${doc.id}) in ${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}');
              return Candidate.fromJson(candidateData);
            }
          }
        }
      }

      AppLogger.candidate('❌ No candidate found via targeted brute force search');
      return null;
    } catch (e) {
      AppLogger.candidateError('❌ Error in targeted brute force search: $e');
      return null;
    }
  }

  // Helper method to search in a specific district
  Future<Candidate?> _searchInSpecificDistrict(String userId, String districtId, String? bodyId) async {
    try {
      AppLogger.candidate('🎯 Searching in specific district: $districtId');

      // First get user's ward from their electionAreas
      final userDoc = await _firestore.collection('users').doc(userId).get();
      String? userWardId;

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);
        userWardId = userModel.wardId;
      }

      if (userWardId == null) {
        AppLogger.candidate('⚠️ User has no ward information, falling back to full search');
        // Fallback to old method if no ward info
        return await _searchInSpecificDistrictFull(userId, districtId, bodyId);
      }

      AppLogger.candidate('🎯 User ward: $userWardId, searching only in this ward');

      // If user has selected a specific body, only search in that body
      final bodyToSearch = bodyId ?? 'pune_m_cop'; // Default fallback

      AppLogger.candidate('🔍 Searching in ward: $userWardId in $districtId/$bodyToSearch');
      final candidatesSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyToSearch)
          .collection('wards')
          .doc(userWardId)
          .collection('candidates')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (candidatesSnapshot.docs.isNotEmpty) {
        final doc = candidatesSnapshot.docs.first;
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;

        AppLogger.candidate('✅ Found candidate in user\'s ward: ${candidateData['name']} (ID: ${doc.id}) in $districtId/$bodyToSearch/$userWardId');
        return Candidate.fromJson(candidateData);
      }

      AppLogger.candidate('❌ No candidate found in user\'s ward: $districtId/$bodyToSearch/$userWardId');
      return null;
    } catch (e) {
      AppLogger.candidate('❌ Error searching in specific district: $e');
      return null;
    }
  }

  // Fallback method for full district search (old behavior)
  Future<Candidate?> _searchInSpecificDistrictFull(String userId, String districtId, String? bodyId) async {
    try {
      AppLogger.candidate('🔍 Falling back to full district search: $districtId');

      final bodiesSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      AppLogger.candidate('📊 Found ${bodiesSnapshot.docs.length} bodies in district $districtId');

      for (var bodyDoc in bodiesSnapshot.docs) {
        // If user has selected a specific body, only search in that body
        if (bodyId != null && bodyDoc.id != bodyId) {
          continue;
        }

        AppLogger.candidate('🔍 Searching body: ${bodyDoc.id} in district $districtId');
        final wardsSnapshot = await bodyDoc.reference.collection('wards').get();
        AppLogger.candidate('📊 Found ${wardsSnapshot.docs.length} wards in $districtId/${bodyDoc.id}');

        for (var wardDoc in wardsSnapshot.docs) {
          AppLogger.candidate('🔍 Searching ward: ${wardDoc.id} in $districtId/${bodyDoc.id}');
          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (candidatesSnapshot.docs.isNotEmpty) {
            final doc = candidatesSnapshot.docs.first;
            final data = doc.data();
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;

            // Update user document with body/ward info for future use
            await ensureUserDocumentExists(
              userId,
              districtId: districtId,
              bodyId: bodyDoc.id,
              wardId: wardDoc.id,
            );

            AppLogger.candidate('✅ Found candidate in specific district: ${candidateData['name']} (ID: ${doc.id}) in $districtId/${bodyDoc.id}/${wardDoc.id}');
            return Candidate.fromJson(candidateData);
          }
        }
      }

      AppLogger.candidate('❌ No candidate found in specific district: $districtId');
      return null;
    } catch (e) {
      AppLogger.candidate('❌ Error searching in specific district: $e');
      return null;
    }

    AppLogger.candidate('❌ No candidate found via targeted brute force search');
    return null;
  }

  // Get candidate data by candidateId (not userId) - Optimized version
  Future<Candidate?> getCandidateDataById(String candidateId) async {
    try {
      AppLogger.candidate(
        '🔍 Candidate Repository: Searching for candidate data by candidateId: $candidateId',
      );

      // First, try to get location metadata from candidate index (if exists)
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final stateId = indexData['stateId']; // Use dynamic state ID
        if (stateId == null) {
          throw Exception('Candidate $candidateId not found in index or missing state information');
        }
        final districtId = indexData['districtId'];
        final bodyId = indexData['bodyId'];
        final wardId = indexData['wardId'];

        AppLogger.candidate('🎯 Found location metadata: $stateId/$districtId/$bodyId/$wardId');

        // Direct query using location metadata
        final candidateDoc = await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .doc(candidateId)
            .get();

        if (candidateDoc.exists) {
          final data = candidateDoc.data()!;
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = candidateDoc.id;

          AppLogger.candidate(
            '✅ Found candidate: ${candidateData['name']} (ID: ${candidateDoc.id})',
          );
          return Candidate.fromJson(candidateData);
        }
      }

      // Fallback: Search across all states to find the candidate
      AppLogger.candidate('🔄 Index not found, searching across all states for candidate');
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
                final data = candidateDoc.data()!;
                final candidateData = Map<String, dynamic>.from(data);
                candidateData['candidateId'] = candidateDoc.id;

                // Update index for future queries
                await _updateCandidateIndex(
                  candidateId,
                  stateDoc.id, // Use actual state ID
                  districtDoc.id,
                  bodyDoc.id,
                  wardDoc.id,
                );

                AppLogger.candidate(
                  '✅ Found candidate: ${candidateData['name']} (ID: ${candidateDoc.id}) in ${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}',
                );
                return Candidate.fromJson(candidateData);
              }
            }
          }
        }
      }

      AppLogger.candidate('❌ No candidate found with candidateId: $candidateId');
      return null;
    } catch (e) {
      AppLogger.candidateError('❌ Error fetching candidate data by ID: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

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
      AppLogger.candidate('❌ Failed to get candidate state ID: $e');
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
      AppLogger.candidate('⚠️ Failed to update candidate index: $e');
      // Don't throw - this is not critical
    }
  }

  // Create or update user document with basic info
  Future<void> ensureUserDocumentExists(
    String userId, {
    String? districtId,
    String? bodyId,
    String? wardId,
    String? cityId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        AppLogger.candidate('📝 Creating user document for $userId');
        await userRef.set({
          'districtId': districtId ?? '',
          'bodyId': bodyId ?? '',
          'wardId': wardId ?? '',
          'cityId': cityId ?? '', // Keep for backward compatibility
          'createdAt': FieldValue.serverTimestamp(),
          'followingCount': 0,
        });
      } else if ((districtId != null && bodyId != null && wardId != null) ||
          (cityId != null && wardId != null)) {
        // Update existing document with location info if provided
        final userData = userDoc.data() ?? {};
        final needsUpdate =
            (districtId != null && userData['districtId'] != districtId) ||
            (bodyId != null && userData['bodyId'] != bodyId) ||
            (userData['wardId'] != wardId) ||
            (cityId != null && userData['cityId'] != cityId);

        if (needsUpdate) {
          AppLogger.candidate(
            '🔄 Updating user document for $userId with location info',
          );
          await userRef.update({
            'districtId': districtId ?? userData['districtId'] ?? '',
            'bodyId': bodyId ?? userData['bodyId'] ?? '',
            'wardId': wardId ?? userData['wardId'] ?? '',
            'cityId':
                cityId ??
                userData['cityId'] ??
                '', // Keep for backward compatibility
          });
        }
      }
    } catch (e) {
      AppLogger.candidate('❌ Error ensuring user document exists: $e');
      // Don't throw here as this is a non-critical operation
    }
  }

  // Update candidate extra info (legacy - saves entire object)
  Future<bool> updateCandidateExtraInfo(Candidate candidate) async {
    try {
      // Find the candidate's location in the new state/district/body/ward structure
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .get();
      bool foundInNewStructure = false;

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
                .doc(candidate.candidateId)
                .get();

            if (candidateDoc.exists) {
              // Found the candidate, update it
              await wardDoc.reference
                  .collection('candidates')
                  .doc(candidate.candidateId)
                  .update({
                    'name': candidate.name,
                    'party': candidate.party,
                    'symbol': candidate.symbolUrl,
                    'symbolName': candidate.symbolName,
                    'extra_info': candidate.extraInfo?.toJson(),
                    'photo': candidate.photo,
                    'manifesto': candidate.manifesto,
                    'contact': candidate.contact.toJson(),
                  });
              foundInNewStructure = true;
              return true;
            }
          }
        }
      }

      // If not found in new structure, try legacy collection
      if (!foundInNewStructure) {
        AppLogger.candidate('🔄 Candidate not found in new structure, trying legacy collection');
        final legacyDocRef = _firestore.collection('candidates').doc(candidate.candidateId);
        final legacyDoc = await legacyDocRef.get();

        if (legacyDoc.exists) {
          await legacyDocRef.update({
            'name': candidate.name,
            'party': candidate.party,
            'symbol': candidate.symbolUrl,
            'symbolName': candidate.symbolName,
            'extra_info': candidate.extraInfo?.toJson(),
            'photo': candidate.photo,
            'manifesto': candidate.manifesto,
            'contact': candidate.contact.toJson(),
          });
          AppLogger.candidate('✅ Successfully updated candidate in legacy collection');
          return true;
        }
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to update candidate extra info: $e');
    }
  }

  // Update specific fields only (optimized field-level updates)
  Future<bool> updateCandidateFields(
    String candidateId,
    Map<String, dynamic> fieldUpdates,
  ) async {
    try {
      // First, try to get location from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final districtId = indexData['districtId'];
        final bodyId = indexData['bodyId'];
        final wardId = indexData['wardId'];

        AppLogger.candidate(
          '🎯 Using indexed location for update: $districtId/$bodyId/$wardId',
        );

        // Get the actual state ID for this candidate
        final stateId = await _getCandidateStateId(candidateId);

        // Direct update using location metadata
        await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .doc(candidateId)
            .update(fieldUpdates);

        // Invalidate cache for this candidate
        invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');

        return true;
      }

      // Fallback: Optimized brute force search
      AppLogger.candidate(
        '🔄 Index not found, using optimized brute force search for update',
      );
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .get();

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
              // Found the candidate, update only specified fields
              await wardDoc.reference
                  .collection('candidates')
                  .doc(candidateId)
                  .update(fieldUpdates);

              // Update index and invalidate cache
              await _updateCandidateIndex(
                candidateId,
                'maharashtra', // Temporary default - should be dynamic
                districtDoc.id,
                bodyDoc.id,
                wardDoc.id,
              );
              invalidateCache(
                'candidates_maharashtra_${districtDoc.id}_${bodyDoc.id}_${wardDoc.id}',
              );

              return true;
            }
          }
        }
      }

      // If not found in new structure, try legacy collection
      AppLogger.candidate('🔄 Candidate not found in new structure, trying legacy collection');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);
      final legacyDoc = await legacyDocRef.get();

      if (legacyDoc.exists) {
        await legacyDocRef.update(fieldUpdates);
        AppLogger.candidate('✅ Successfully updated candidate in legacy collection');
        return true;
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to update candidate fields: $e');
    }
  }

  // Update specific extra_info fields (most common use case)
  Future<bool> updateCandidateExtraInfoFields(
    String candidateId,
    Map<String, dynamic> extraInfoUpdates,
  ) async {
    try {
      AppLogger.candidate(
        '🔄 updateCandidateExtraInfoFields - Input: $extraInfoUpdates',
      );

      // Convert extra_info field updates to dot notation
      final fieldUpdates = <String, dynamic>{};

      extraInfoUpdates.forEach((key, value) {
        // Handle nested basic_info fields
        if (['profession', 'languages', 'experienceYears', 'previousPositions', 'age', 'gender', 'education', 'dateOfBirth'].contains(key)) {
          fieldUpdates['extra_info.basic_info.$key'] = value;
          AppLogger.candidate('   Converting $key -> extra_info.basic_info.$key = $value');
        } else {
          fieldUpdates['extra_info.$key'] = value;
          AppLogger.candidate('   Converting $key -> extra_info.$key = $value');
        }
      });

      AppLogger.candidate('   Final field updates: $fieldUpdates');

      // Try to update in new structure first
      try {
        final success = await updateCandidateFields(candidateId, fieldUpdates);
        if (success) return true;
      } catch (e) {
        AppLogger.candidate('⚠️ Failed to update in new structure: $e');
      }

      // Fallback: Update in legacy collection
      AppLogger.candidate('🔄 Falling back to legacy collection update');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);

      // Check if candidate exists in legacy collection
      final legacyDoc = await legacyDocRef.get();
      if (!legacyDoc.exists) {
        throw Exception('Candidate not found in legacy collection either');
      }

      await legacyDocRef.update(fieldUpdates);
      AppLogger.candidate('✅ Successfully updated candidate in legacy collection');

      return true;
    } catch (e) {
      throw Exception('Failed to update candidate extra info fields: $e');
    }
  }

  // Batch update multiple fields at once
  Future<bool> batchUpdateCandidateFields(
    String candidateId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      // Find the candidate's location in the new state/district/body/ward structure
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
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
        final candidateRef = _firestore
            .collection('states')
            .doc('maharashtra') // Temporary default - should be dynamic
            .collection('districts')
            .doc(candidateDistrictId)
            .collection('bodies')
            .doc(candidateBodyId)
            .collection('wards')
            .doc(candidateWardId)
            .collection('candidates')
            .doc(candidateId);

        batch.update(candidateRef, updates);
        await batch.commit();
        return true;
      }

      // Fallback: Try legacy collection
      AppLogger.candidate('🔄 Candidate not found in new structure, trying legacy collection');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);
      final legacyDoc = await legacyDocRef.get();

      if (legacyDoc.exists) {
        batch.update(legacyDocRef, updates);
        await batch.commit();
        AppLogger.candidate('✅ Successfully updated candidate in legacy collection');
        return true;
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to batch update candidate fields: $e');
    }
  }

  // Get candidates by approval status
  Future<List<Candidate>> getCandidatesByApprovalStatus(
    String districtId,
    String bodyId,
    String wardId,
    bool approved,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('approved', isEqualTo: approved)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;
        return Candidate.fromJson(candidateData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch candidates by approval status: $e');
    }
  }

  // Get candidates by status (pending_election or finalized)
  Future<List<Candidate>> getCandidatesByStatus(
    String districtId,
    String bodyId,
    String wardId,
    String status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .where('status', isEqualTo: status)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;
        return Candidate.fromJson(candidateData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch candidates by status: $e');
    }
  }

  // Approve or reject a candidate
  Future<void> updateCandidateApproval(
    String districtId,
    String bodyId,
    String wardId,
    String candidateId,
    bool approved,
  ) async {
    try {
      await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update({
            'approved': approved,
            'status': approved ? 'pending_election' : 'rejected',
          });
    } catch (e) {
      throw Exception('Failed to update candidate approval: $e');
    }
  }

  // Switch candidates from provisional to finalized
  Future<void> finalizeCandidates(
    String districtId,
    String bodyId,
    String wardId,
    List<String> candidateIds,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final candidateId in candidateIds) {
        final candidateRef = _firestore
            .collection('states')
            .doc('maharashtra') // Temporary default - should be dynamic
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .doc(candidateId);

        batch.update(candidateRef, {'status': 'finalized', 'approved': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to finalize candidates: $e');
    }
  }

  // Get all pending approval candidates across all districts, bodies, and wards
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .get();
      List<Map<String, dynamic>> pendingCandidates = [];

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidatesSnapshot = await wardDoc.reference
                .collection('candidates')
                .where('approved', isEqualTo: false)
                .get();

            for (var candidateDoc in candidatesSnapshot.docs) {
              final data = candidateDoc.data();
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = candidateDoc.id;
              candidateData['districtId'] = districtDoc.id;
              candidateData['bodyId'] = bodyDoc.id;
              candidateData['wardId'] = wardDoc.id;
              pendingCandidates.add(candidateData);
            }
          }
        }
      }

      return pendingCandidates;
    } catch (e) {
      throw Exception('Failed to fetch pending approval candidates: $e');
    }
  }

  // Check if user has already registered as a candidate
  Future<bool> hasUserRegisteredAsCandidate(String userId) async {
    try {
      // First check if user has district/body/ward info
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);
        String? districtId = userModel.districtId;
        String? bodyId = userModel.bodyId;
        String? wardId = userModel.wardId;

        // If user has location info, check directly in that ward
        if (districtId != null &&
            bodyId != null &&
            wardId != null &&
            districtId.isNotEmpty &&
            bodyId.isNotEmpty &&
            wardId.isNotEmpty) {
          final candidateSnapshot = await _firestore
              .collection('states')
              .doc('maharashtra') // Temporary default - should be dynamic
              .collection('districts')
              .doc(districtId)
              .collection('bodies')
              .doc(bodyId)
              .collection('wards')
              .doc(wardId)
              .collection('candidates')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (candidateSnapshot.docs.isNotEmpty) {
            return true;
          }
        }
      }

      // Fallback: search through all districts, bodies, and wards
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // Temporary default - should be dynamic
          .collection('districts')
          .get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference
            .collection('bodies')
            .get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference
              .collection('wards')
              .get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateSnapshot = await wardDoc.reference
                .collection('candidates')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

            if (candidateSnapshot.docs.isNotEmpty) {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check user candidate registration: $e');
    }
  }
}

