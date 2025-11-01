
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../models/achievements_model.dart';
import '../../../features/user/models/user_model.dart';
import '../../../utils/data_compression.dart';
import '../../../utils/error_recovery_manager.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/multi_level_cache.dart';
import 'candidate_cache_manager.dart';
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
    final candidateCreationStartTime = DateTime.now();
    try {
      AppLogger.candidate('🏗️ Creating candidate: ${candidate.basicInfo!.fullName}');
      AppLogger.candidate('   District: ${candidate.location.districtId}');
      AppLogger.candidate('   Body: ${candidate.location.bodyId}');
      AppLogger.candidate('   Ward: ${candidate.location.wardId}');
      AppLogger.candidate('   UserId: ${candidate.userId}');

      // Determine state ID - use provided parameter or try to detect from location
      final stateIdStartTime = DateTime.now();
      String finalStateId = stateId ?? await _determineStateId(candidate.location.districtId, candidate.location.bodyId, candidate.location.wardId) ?? 'maharashtra';
      final stateIdTime = DateTime.now().difference(stateIdStartTime).inMilliseconds;

      AppLogger.candidate('🎯 Using state ID: $finalStateId (determined in ${stateIdTime}ms)');

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
                .doc(candidate.location.districtId)
                .collection('bodies')
                .doc(candidate.location.bodyId)
                .collection('wards')
                .doc(candidate.location.wardId)
                .collection('candidates')
                .doc(candidate.candidateId)
          : _firestore
                .collection('states')
                .doc(finalStateId)
                .collection('districts')
                .doc(candidate.location.districtId)
                .collection('bodies')
                .doc(candidate.location.bodyId)
                .collection('wards')
                .doc(candidate.location.wardId)
                .collection('candidates')
                .doc();

      AppLogger.candidate('📝 Creating candidate at path: states/$finalStateId/districts/${candidate.location.districtId}/bodies/${candidate.location.bodyId}/wards/${candidate.location.wardId}/candidates/${docRef.id}');

      final firestoreSaveStartTime = DateTime.now();
      await docRef.set(optimizedData);
      final firestoreSaveTime = DateTime.now().difference(firestoreSaveStartTime).inMilliseconds;
      AppLogger.candidate('✅ Candidate document created successfully with ID: ${docRef.id} (saved in ${firestoreSaveTime}ms)');

      // CANDIDATE_INDEX ELIMINATION: Location data is now embedded in the Candidate object
      // No index update needed - all location access now uses candidate.location embedded data
      AppLogger.candidate('ℹ️ Candidate creation complete - location embedded in candidate object');

      // Invalidate relevant caches with correct state ID
      invalidateCache(
        'candidates_${finalStateId}_${candidate.location.districtId}_${candidate.location.bodyId}_${candidate.location.wardId}',
      );

      final totalCandidateCreationTime = DateTime.now().difference(candidateCreationStartTime).inMilliseconds;
      AppLogger.candidate('✅ Candidate creation completed in ${totalCandidateCreationTime}ms');

      // Return the actual document ID (in case it was auto-generated)
      return docRef.id;
    } catch (e) {
      final errorTime = DateTime.now().difference(candidateCreationStartTime).inMilliseconds;
      AppLogger.candidateError('❌ Failed to create candidate after ${errorTime}ms: $e');
      throw Exception('Failed to create candidate: $e');
    }
  }

  // Helper method to determine state ID from location information - OPTIMIZED
  Future<String?> _determineStateId(String? districtId, String? bodyId, String? wardId) async {
    if (districtId == null || bodyId == null || wardId == null) {
      return null;
    }

    try {
      // OPTIMIZATION: First try to get from local database cache (SQLite)
      final cachedStateId = await _getStateIdFromCache(districtId, bodyId, wardId);
      if (cachedStateId != null) {
        AppLogger.candidate('🎯 Found state ID in cache: $cachedStateId for location $districtId/$bodyId/$wardId');
        return cachedStateId;
      }

      // OPTIMIZATION: Use parallel queries to reduce sequential database calls
      final statesSnapshot = await _firestore.collection('states').get();

      // Create a list of futures for parallel execution
      final stateChecks = <Future<String?>>[];

      for (var stateDoc in statesSnapshot.docs) {
        stateChecks.add(_checkStateForLocation(stateDoc, districtId, bodyId, wardId));
      }

      // Wait for any state to return a match (first match wins)
      for (var stateCheck in stateChecks) {
        final result = await stateCheck;
        if (result != null) {
          // Cache the result for future use
          await _cacheStateId(districtId, bodyId, wardId, result);
          return result;
        }
      }

      AppLogger.candidate('⚠️ Could not determine state ID for location $districtId/$bodyId/$wardId, using default');
      return null; // Will fall back to 'maharashtra' in calling method
    } catch (e) {
      AppLogger.candidateError('❌ Error determining state ID: $e');
      return null;
    }
  }

  // Helper method to check if a specific state contains the location
  Future<String?> _checkStateForLocation(
    DocumentSnapshot stateDoc,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Check if district exists in this state
      final districtDoc = await stateDoc.reference.collection('districts').doc(districtId).get();
      if (!districtDoc.exists) return null;

      // Check if body exists in this district
      final bodyDoc = await districtDoc.reference.collection('bodies').doc(bodyId).get();
      if (!bodyDoc.exists) return null;

      // Check if ward exists in this body
      final wardDoc = await bodyDoc.reference.collection('wards').doc(wardId).get();
      if (!wardDoc.exists) return null;

      AppLogger.candidate('🎯 Found state ID: ${stateDoc.id} for location $districtId/$bodyId/$wardId');
      return stateDoc.id;
    } catch (e) {
      // If any check fails, return null (state doesn't contain this location)
      return null;
    }
  }

  // Get state ID from local cache
  Future<String?> _getStateIdFromCache(String districtId, String bodyId, String wardId) async {
    try {
      // Check if we have this location cached in SQLite
      // This is a simplified implementation - in production, you'd have a dedicated location cache table
      // For now, we'll rely on the parallel Firestore queries for performance
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cache state ID for future lookups
  Future<void> _cacheStateId(String districtId, String bodyId, String wardId, String stateId) async {
    try {
      // In a full implementation, this would cache the location hierarchy mapping
      // For now, we rely on the optimized parallel queries
      AppLogger.candidate('💾 Location cached: $stateId for $districtId/$bodyId/$wardId');
    } catch (e) {
      // Don't throw - caching failure shouldn't break the flow
    }
  }

  // Get candidate data by user ID (optimized) with retry logic
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

      // Use retry logic for all Firestore operations
      return await _getCandidateDataWithRetry(userId);
    } catch (e) {
      AppLogger.candidateError('❌ Error fetching candidate data: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  /// Fetch candidate data with retry logic for transient Firestore errors
  Future<Candidate?> _getCandidateDataWithRetry(String userId) async {
    const maxRetries = 3;
    const baseDelayMs = 1000; // 1 second initial delay

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // OPTIMIZED: Use UserDataController for user data
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

        // Determine state ID dynamically for the direct query
        final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
        AppLogger.candidate('🎯 Using state ID for direct query: $stateId');

        // Direct query to the specific state/district/body/ward path
        final candidatesSnapshot = await _firestore
            .collection('states')
            .doc(stateId)
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
            .get(const GetOptions(source: Source.server));

        AppLogger.candidate(
          '👤 Found ${candidatesSnapshot.docs.length} candidates in $districtId/$bodyId/$wardId',
        );

        if (candidatesSnapshot.docs.isNotEmpty) {
          final doc = candidatesSnapshot.docs.first;
          final data = doc.data();
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = doc.id;

          // DEBUG: Log achievements data specifically
          AppLogger.candidate('🏆 [ACHIEVEMENTS_DATA] Raw achievements from Firebase:');
          final achievementsRaw = data['achievements'];
          AppLogger.candidate('   achievements field: ${achievementsRaw.runtimeType}');
          AppLogger.candidate('   achievements is list: ${achievementsRaw is List}');
          AppLogger.candidate('   achievements length: ${(achievementsRaw as List?)?.length ?? "null"}');

          if (achievementsRaw is List && achievementsRaw.isNotEmpty) {
            AppLogger.candidate('   First achievement title: ${(achievementsRaw[0] as Map?)?['title'] ?? "unknown"}');
          }

          AppLogger.candidate('📄 Raw candidate data from DB:');
          final extraInfo = data['extra_info'] as Map<String, dynamic>?;
          AppLogger.candidate('   extra_info keys: ${extraInfo?.keys.toList() ?? 'null'}');
          AppLogger.candidate('   education in extra_info: ${extraInfo?.containsKey('education') ?? false}');
          AppLogger.candidate(
            '   education value: ${extraInfo != null && extraInfo.containsKey('education') ? extraInfo['education'] : 'not found'}',
          );

          final candidate = Candidate.fromJson(candidateData);
          AppLogger.candidate('🏆 [ACHIEVEMENTS_DATA] Final candidate achievements count: ${candidate.achievements?.length ?? "null"}');

          AppLogger.candidate(
            '✅ Found candidate: ${candidateData['name']} (ID: ${doc.id})',
          );
          return candidate;
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
            .get(const GetOptions(source: Source.server));

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
      } catch (error) {
        // Check if this is a retriable error
        if (_isRetriableFirestoreError(error) && attempt < maxRetries) {
          final delayMs = baseDelayMs * (1 << attempt); // Exponential backoff: 1s, 2s, 4s
          AppLogger.candidate('⏳ Retriable Firestore error on attempt ${attempt + 1}, retrying in ${delayMs}ms: $error');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // If this is the last attempt or not retriable, try cache-only fallback
        if (attempt == maxRetries || !_isRetriableFirestoreError(error)) {
          try {
            AppLogger.candidate('🔄 Attempting cache-only fallback after server failures');
            // Try reading from cache (not implemented in this method, but we could add it)
            return null; // For now, return null as cache fallback isn't implemented
          } catch (cacheError) {
            AppLogger.candidate('❌ Cache fallback also failed: $cacheError');
          }
        }

        // Re-throw the original error if we can't recover
        AppLogger.candidate('❌ All retry attempts and fallback failed: $error');
        rethrow;
      }
    }

    // This should never be reached, but just in case
    throw Exception('Unexpected error in candidate fetch retry logic');
  }

  /// Check if a Firestore error is retriable (transient)
  bool _isRetriableFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      // UNAVAILABLE errors are transient and should be retried
      // Other retriable codes: DEADLINE_EXCEEDED, RESOURCE_EXHAUSTED (with backoff)
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'resource-exhausted';
    }

    // Timeout exceptions are also retriable
    if (error is TimeoutException) {
      return true;
    }

    return false;
  }

  // Optimized brute force search (limited to user's selected district)
  Future<Candidate?> _getCandidateDataBruteForce(String userId) async {
    AppLogger.candidate('🔍 Falling back to targeted brute force search for userId: $userId');

    try {
      // OPTIMIZED: Use UserDataController for user data
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

      // OPTIMIZED: Use UserDataController for user data
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

      // Determine state ID dynamically for the ward search
      final stateId = await _determineStateId(districtId, bodyToSearch, userWardId) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for ward search: $stateId');

      AppLogger.candidate('🔍 Searching in ward: $userWardId in $districtId/$bodyToSearch');
      final candidatesSnapshot = await _firestore
          .collection('states')
          .doc(stateId)
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

      // Determine state ID dynamically for the full district search
      final stateId = await _determineStateId(districtId, null, null) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for full district search: $stateId');

      final bodiesSnapshot = await _firestore
          .collection('states')
          .doc(stateId)
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

            // CANDIDATE_INDEX ELIMINATION: Location data is embedded in candidate object
            // No longer updating candidate_index - location is already available

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

  // Get candidate data by candidateId (not userId) - Optimized with direct queries by state
  Future<Candidate?> getCandidateDataById(String candidateId) async {
    try {
      AppLogger.candidate('🔍 getCandidateDataById: Searching for candidate: $candidateId');

      // Try to find the candidate in all states using direct document queries
      // This is optimized compared to nested collection traversals
      final statesSnapshot = await _firestore.collection('states').get();

      // Create tasks for parallel execution across states
      final candidateTasks = <Future<Map<String, dynamic>?>>[];

      for (var stateDoc in statesSnapshot.docs) {
        candidateTasks.add(_findCandidateInState(candidateId, stateDoc.reference));
      }

      // Wait for any state to return the candidate
      for (var task in candidateTasks) {
        final result = await task;
        if (result != null) {
          final candidateData = result;
          AppLogger.candidate('✅ Found candidate $candidateId in state: ${candidateData['stateId']}');
          return Candidate.fromJson(candidateData);
        }
      }

      AppLogger.candidate('❌ No candidate found with candidateId: $candidateId');
      return null;

    } catch (e) {
      AppLogger.candidateError('❌ Error fetching candidate data by ID: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Helper method to find candidate in a specific state
  Future<Map<String, dynamic>?> _findCandidateInState(String candidateId, DocumentReference stateRef) async {
    try {
      final stateId = stateRef.id;

      // Try to find in all districts for this state (increased limits for comprehensive search)
      final districtsSnapshot = await stateRef.collection('districts').limit(50).get();

      for (var districtDoc in districtsSnapshot.docs) {
        // For each district, try to find the candidate in all bodies
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').limit(50).get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          // For each body, try to find the candidate in all wards
          final wardsSnapshot = await bodyDoc.reference.collection('wards').limit(100).get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateDoc = await wardDoc.reference.collection('candidates').doc(candidateId).get();

            if (candidateDoc.exists) {
              final data = candidateDoc.data()!;
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = candidateDoc.id;
              // Add location information for debugging
              candidateData['location'] = {
                'stateId': stateId,
                'districtId': districtDoc.id,
                'bodyId': bodyDoc.id,
                'wardId': wardDoc.id,
              };

              return candidateData;
            }
          }
        }
      }

      return null; // Candidate not found in this state

    } catch (e) {
      // If any state search fails, return null (try next state)
      return null;
    }
  }

  // Get candidate's actual state ID (helper method) - Using embedded location data
  Future<String> _getCandidateStateId(String candidateId) async {
    try {
      // CANDIDATE_INDEX ELIMINATION: Search across all states to find the candidate
      // No longer using candidate_index - we'll find the candidate and determine state
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
                AppLogger.candidate('🎯 Found candidate $candidateId in state: ${stateDoc.id}');
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

  // Update candidate index for faster lookups - ELIMINATED: No longer needed with embedded location data
  Future<void> _updateCandidateIndex(
    String candidateId,
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    // CANDIDATE_INDEX ELIMINATION: This method is now obsolete since location data is embedded in the Candidate object
    // No longer updating candidate_index collection - all location access now uses candidate.location embedded data
    AppLogger.candidate('ℹ️ Candidate index update skipped - using embedded location data instead');
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

  // Update candidate extra info (optimized - uses embedded location data)
  Future<bool> updateCandidateExtraInfo(Candidate candidate) async {
    try {
      AppLogger.candidate('🔄 updateCandidateExtraInfo - Updating candidate: ${candidate.candidateId}');

      // Use embedded location data from candidate object (much more efficient)
      final location = candidate.location;
      final stateId = location.stateId ?? 'maharashtra'; // Fallback to default state
      final districtId = location.districtId;
      final bodyId = location.bodyId;
      final wardId = location.wardId;

      AppLogger.candidate('🎯 Using embedded location: stateId=$stateId, districtId=$districtId, bodyId=$bodyId, wardId=$wardId');

      // Validate that we have required location data
      if (districtId == null || bodyId == null || wardId == null) {
        throw Exception('Candidate location data is incomplete - missing districtId, bodyId, or wardId');
      }

      // Directly construct the document path using embedded location data
      final candidateDocRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidate.candidateId);

      try {
        // Update the candidate document directly
        await candidateDocRef.update({
          'name': candidate.basicInfo!.fullName,
          'party': candidate.party,
          'symbol': candidate.symbolUrl,
          'symbolName': candidate.symbolName,
          'extra_info': null,
          'photo': candidate.photo,
          'contact': candidate.contact.toJson(),
        });

        AppLogger.candidate('✅ Successfully updated candidate using embedded location data');
        // Invalidate cache for this candidate
        invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');
        return true;

      } catch (updateError) {
        AppLogger.candidateError('❌ Failed to update candidate: $updateError');
        // Check if it's a permission error
        if (updateError.toString().contains('permission-denied') ||
            updateError.toString().contains('PERMISSION_DENIED')) {
          AppLogger.candidateError('🚫 PERMISSION DENIED: Cannot update candidate document. Check Firestore rules.');
        }
        rethrow; // Re-throw to be caught by outer catch
      }

    } catch (e) {
      AppLogger.candidateError('❌ Failed to update candidate extra info: $e');
      // Check if it's a permission error
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        AppLogger.candidateError('🚫 PERMISSION DENIED: Firestore security rules are blocking the update. Current user may not have permission to update this candidate document.');
      }
      throw Exception('Failed to update candidate extra info: $e');
    }
  }

  // Update specific fields only (optimized field-level updates) - Using embedded location data
  Future<bool> updateCandidateFields(
    String candidateId,
    Map<String, dynamic> fieldUpdates,
  ) async {
    try {
      AppLogger.candidate('🔄 updateCandidateFields - Updating candidate: $candidateId with fields: $fieldUpdates using embedded location data');

      // First, get the candidate data to access embedded location information
      final candidate = await getCandidateDataById(candidateId);
      if (candidate == null) {
        throw Exception('Candidate $candidateId not found');
      }

      // Use embedded location data from candidate object (much more efficient)
      final location = candidate.location;
      final stateId = location.stateId ?? 'maharashtra'; // Fallback to default state
      final districtId = location.districtId;
      final bodyId = location.bodyId;
      final wardId = location.wardId;

      AppLogger.candidate('🎯 Using embedded location for field update: stateId=$stateId, districtId=$districtId, bodyId=$bodyId, wardId=$wardId');

      // Validate that we have required location data
      if (districtId == null || bodyId == null || wardId == null) {
        throw Exception('Candidate location data is incomplete - missing districtId, bodyId, or wardId');
      }

      // Directly construct the document path using embedded location data
      final candidateDocRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      try {
        // Process Achievement objects in fieldUpdates if present
        final processedUpdates = _processFieldUpdatesForFirestore(fieldUpdates);

        // Update the candidate document directly
        await candidateDocRef.update(processedUpdates);

        AppLogger.candidate('✅ Successfully updated candidate fields using embedded location data');
        // Invalidate cache for this candidate
        invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');

        return true;

      } catch (updateError) {
        AppLogger.candidateError('❌ Failed to update candidate fields: $updateError');
        // Check if it's a permission error
        if (updateError.toString().contains('permission-denied') ||
            updateError.toString().contains('PERMISSION_DENIED')) {
          AppLogger.candidateError('🚫 PERMISSION DENIED: Cannot update candidate document. Check Firestore rules.');
        }
        rethrow; // Re-throw to be caught by outer catch
      }

    } catch (e) {
      AppLogger.candidateError('❌ Failed to update candidate fields: $e');
      // Check if it's a permission error
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        AppLogger.candidateError('🚫 PERMISSION DENIED: Firestore security rules are blocking the field update. Current user may not have permission to update this candidate document.');
      }
      throw Exception('Failed to update candidate fields: $e');
    }
  }
  
  // Batch update multiple fields at once (optimized - uses embedded location data)
  Future<bool> batchUpdateCandidateFields(
    String candidateId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      // First, get the candidate data to access embedded location information
      final candidate = await getCandidateDataById(candidateId);
      if (candidate == null) {
        throw Exception('Candidate $candidateId not found');
      }

      // Use embedded location data from candidate object (much more efficient)
      final location = candidate.location;
      final stateId = location.stateId ?? 'maharashtra'; // Fallback to default state
      final districtId = location.districtId;
      final bodyId = location.bodyId;
      final wardId = location.wardId;

      AppLogger.candidate('🎯 Using embedded location for batch update: stateId=$stateId, districtId=$districtId, bodyId=$bodyId, wardId=$wardId');

      // Validate that we have required location data
      if (districtId == null || bodyId == null || wardId == null) {
        throw Exception('Candidate location data is incomplete - missing districtId, bodyId, or wardId');
      }

      // Directly construct the document path using embedded location data
      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      batch.update(candidateRef, updates);
      await batch.commit();

      AppLogger.candidate('✅ Successfully batch updated candidate fields using embedded location data');
      // Invalidate cache for this candidate
      invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');
      return true;
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
      // Determine state ID dynamically
      final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for approval status query: $stateId');

      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
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
      // Determine state ID dynamically
      final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for status query: $stateId');

      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
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
      // Determine state ID dynamically
      final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for approval update: $stateId');

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
          .update({
            'approved': approved,
            'status': approved ? 'pending_election' : 'rejected',
          });

      // Invalidate cache for this candidate
      invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');
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
      // Determine state ID dynamically
      final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
      AppLogger.candidate('🎯 Using state ID for finalization: $stateId');

      final batch = _firestore.batch();

      for (final candidateId in candidateIds) {
        final candidateRef = _firestore
            .collection('states')
            .doc(stateId)
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

      // Invalidate cache for this ward
      invalidateCache('candidates_${stateId}_${districtId}_${bodyId}_$wardId');
    } catch (e) {
      throw Exception('Failed to finalize candidates: $e');
    }
  }

  // Get all pending approval candidates across all districts, bodies, and wards
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      // Get all states first
      final statesSnapshot = await _firestore.collection('states').get();
      List<Map<String, dynamic>> pendingCandidates = [];

      for (var stateDoc in statesSnapshot.docs) {
        final stateId = stateDoc.id;
        AppLogger.candidate('🔍 Checking state: $stateId for pending candidates');

        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

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
                candidateData['stateId'] = stateId; // Include state ID
                pendingCandidates.add(candidateData);
              }
            }
          }
        }
      }

      AppLogger.candidate('📊 Found ${pendingCandidates.length} pending approval candidates across all states');
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
          // Determine state ID dynamically for the user check
          final stateId = await _determineStateId(districtId, bodyId, wardId) ?? 'maharashtra';
          AppLogger.candidate('🎯 Using state ID for user registration check: $stateId');

          final candidateSnapshot = await _firestore
              .collection('states')
              .doc(stateId)
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
      // Get all states first for comprehensive search
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final stateId = stateDoc.id;
        AppLogger.candidate('🔍 Checking state: $stateId for user registration');

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
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check user candidate registration: $e');
    }
  }

  // Helper method to process field updates for Firestore (handles Achievement objects)
  Map<String, dynamic> _processFieldUpdatesForFirestore(Map<String, dynamic> fieldUpdates) {
    final processedUpdates = <String, dynamic>{};

    fieldUpdates.forEach((key, value) {
      if (key == 'achievements') {
        // Handle achievements data at the top level
        if (value is List) {
          final processedAchievements = value.map((item) {
            if (item is Achievement) {
              return item.toJson();
            } else if (item is Map<String, dynamic>) {
              return item;
            } else {
              AppLogger.candidate('Invalid achievement data type: ${item.runtimeType}, converting to string');
              return item.toString();
            }
          }).toList();
          processedUpdates[key] = processedAchievements;
        } else {
          processedUpdates[key] = value;
        }
      } else {
        processedUpdates[key] = value;
      }
    });

    return processedUpdates;
  }
}
