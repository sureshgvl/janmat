import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/candidate_model.dart';
import '../../../features/user/models/user_model.dart';
import '../../../utils/performance_monitor.dart' as perf_monitor;
import '../../../utils/data_compression.dart';
import '../../../utils/error_recovery_manager.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/multi_level_cache.dart';
import '../../../utils/app_logger.dart';
import 'candidate_cache_manager.dart';
import 'candidate_state_manager.dart';
import 'candidate_operations.dart';
import 'candidate_follow_manager.dart';

class CandidateSearchManager {
  final FirebaseFirestore _firestore;
  final FirebaseDataOptimizer _dataOptimizer;
  final ErrorRecoveryManager _errorRecovery;
  final AdvancedAnalyticsManager _analytics;
  final MultiLevelCache _cache;
  final CandidateCacheManager _cacheManager;
  final CandidateStateManager _stateManager;
  final CandidateOperations _operations;
  final CandidateFollowManager _followManager;

  // State configuration
  static const String DEFAULT_STATE_ID = 'maharashtra';

  CandidateSearchManager(
    this._firestore,
    this._dataOptimizer,
    this._errorRecovery,
    this._analytics,
    this._cache,
    this._cacheManager,
    this._stateManager,
    this._operations,
    this._followManager,
  );

  // Delegate cache methods to cache manager
  void invalidateCache(String cacheKey) => _cacheManager.invalidateCache(cacheKey);
  List<Candidate>? _getCachedCandidates(String cacheKey) => _cacheManager.getCachedCandidates(cacheKey);
  void _cacheData(String cacheKey, dynamic data) => _cacheManager.cacheData(cacheKey, data);

  // Delegate to operations manager
  Future<Candidate?> getCandidateDataById(String candidateId) => _operations.getCandidateDataById(candidateId);

  // Delegate to follow manager
  Future<List<String>> getUserFollowing(String userId) => _followManager.getUserFollowing(userId);

  // OPTIMIZED: Use UserDataController for user data
  // Get candidates for a user based on their election areas (NEW METHOD)
  Future<List<Candidate>> getCandidatesForUser(UserModel user) async {
    try {
      AppLogger.candidate('🔍 Getting candidates for user: ${user.uid}');
      AppLogger.candidate('📊 User has ${user.electionAreas.length} election areas');

      List<Candidate> allCandidates = [];

      for (ElectionArea area in user.electionAreas) {
        AppLogger.candidate('🔍 Searching in area: ${area.type.name} - ${area.wardId}');

        try {
          final candidates = await getCandidatesByWard(
            user.districtId ?? '',
            area.bodyId,
            area.wardId,
          );
          allCandidates.addAll(candidates);
          AppLogger.candidate('✅ Found ${candidates.length} candidates in ${area.wardId}');
        } catch (e) {
          AppLogger.candidate('⚠️ Error searching in ${area.wardId}: $e');
          // Continue with other areas even if one fails
        }
      }

      AppLogger.candidate('✅ Total candidates found: ${allCandidates.length}');
      return allCandidates;
    } catch (e) {
      AppLogger.candidateError('Error getting candidates for user: $e');
      throw Exception('Failed to get candidates for user: $e');
    }
  }

  // Get candidates by ward with advanced optimizations
  Future<List<Candidate>> getCandidatesByWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    final monitor = perf_monitor.PerformanceMonitor();
    monitor.startTimer('getCandidatesByWard');

    // For now, assume candidates are in default state, but cache key is more generic
    final cacheKey = 'candidates_${districtId}_${bodyId}_$wardId';

    // Check multi-level cache first
    final cachedData = await _cache.get<List<Candidate>>(cacheKey);
    if (cachedData != null) {
      _analytics.trackFirebaseOperation(
        'cache_hit',
        'candidates',
        cachedData.length,
      );
      monitor.trackCacheHit('candidate_ward');
      monitor.stopTimer('getCandidatesByWard');
      AppLogger.candidate(
        '⚡ MULTI_CACHE HIT: Returning ${cachedData.length} cached candidates for ward $wardId',
      );
      return cachedData;
    }

    // Check legacy cache as fallback
    final cachedCandidates = _getCachedCandidates(cacheKey);
    if (cachedCandidates != null) {
      monitor.trackCacheHit('candidate_ward');
      monitor.stopTimer('getCandidatesByWard');
      AppLogger.candidate(
        '⚡ LEGACY CACHE HIT: Returning ${cachedCandidates.length} cached candidates for ward $wardId',
      );
      return cachedCandidates;
    }

    monitor.trackCacheMiss('candidate_ward');
    AppLogger.candidate(
      '🔍 CACHE MISS: Fetching candidates for $DEFAULT_STATE_ID/$districtId/$bodyId/$wardId from Firebase',
    );

    try {
      // Use error recovery for Firebase operation
      final snapshot = await _errorRecovery.executeWithRecovery(
        'get_candidates_by_ward',
        () async {
          return await _firestore
              .collection('states')
              .doc(DEFAULT_STATE_ID)
              .collection('districts')
              .doc(districtId)
              .collection('bodies')
              .doc(bodyId)
              .collection('wards')
              .doc(wardId)
              .collection('candidates')
              .get();
        },
      );

      monitor.trackFirebaseRead('candidates', snapshot.docs.length);
      _analytics.trackFirebaseOperation(
        'read',
        'candidates',
        snapshot.docs.length,
        success: true,
      );

      AppLogger.candidate(
        '📊 getCandidatesByWard: Found ${snapshot.docs.length} candidates in $DEFAULT_STATE_ID/$districtId/$bodyId/$wardId',
      );

      final candidates = snapshot.docs.map((doc) {
        final data = doc.data();
        // Decompress data if it was compressed during storage
        final decompressedData = _dataOptimizer.optimizeAfterLoad(data);
        final candidateData = Map<String, dynamic>.from(decompressedData);
        candidateData['candidateId'] = doc.id;

        // Log candidate details
        AppLogger.candidate('👤 Candidate: ${candidateData['name']} (ID: ${doc.id})');
        AppLogger.candidate('   Party: ${candidateData['party']}');
        AppLogger.candidate('   UserId: ${candidateData['userId']}');
        AppLogger.candidate('   State: $DEFAULT_STATE_ID, District: $districtId, Body: $bodyId, Ward: $wardId');
        AppLogger.candidate('   Approved: ${candidateData['approved'] ?? false}');
        AppLogger.candidate('   Status: ${candidateData['status'] ?? 'unknown'}');

        return Candidate.fromJson(candidateData);
      }).toList();

      // Cache in both systems
      await _cache.set(cacheKey, candidates, ttl: Duration(minutes: 15));
      _cacheData(cacheKey, candidates); // Legacy cache
      AppLogger.candidate(
        '💾 Cached ${candidates.length} candidates for ward $wardId in both cache systems',
      );

      monitor.stopTimer('getCandidatesByWard');
      AppLogger.candidate(
        '✅ getCandidatesByWard: Successfully loaded ${candidates.length} candidates',
      );
      return candidates;
    } catch (e) {
      // Track failed operation
      _analytics.trackFirebaseOperation(
        'read',
        'candidates',
        0,
        success: false,
        error: e.toString(),
      );

      monitor.stopTimer('getCandidatesByWard');
      AppLogger.candidateError('Failed to fetch candidates: $e');
      throw Exception('Failed to fetch candidates: $e');
    }
  }

  // Get candidates for a city with pagination
  Future<Map<String, dynamic>> getCandidatesByCityPaginated(
    String cityId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    final cacheKey = 'candidates_city_$cityId';

    // Check cache first (only if no pagination)
    if (startAfter == null) {
      final cachedCandidates = _getCachedCandidates(cacheKey);
      if (cachedCandidates != null) {
        AppLogger.candidate(
          '⚡ CACHE HIT: Returning ${cachedCandidates.length} cached candidates for city $cityId',
        );
        return {
          'candidates': cachedCandidates.take(limit).toList(),
          'lastDoc': cachedCandidates.length > limit
              ? cachedCandidates[limit - 1] as DocumentSnapshot?
              : null,
          'hasMore': cachedCandidates.length > limit,
        };
      }
    }

    AppLogger.candidate(
      '🔍 CACHE MISS: Fetching candidates for city $cityId from Firebase (limit: $limit)',
    );
    try {
      final wardsSnapshot = await _firestore
          .collection('states')
          .doc(DEFAULT_STATE_ID)
          .collection('districts')
          .doc(cityId) // Using cityId as districtId for backward compatibility
          .collection('bodies')
          .doc('default') // Default body
          .collection('wards')
          .get();

      AppLogger.candidate(
        '📊 getCandidatesByCity: Found ${wardsSnapshot.docs.length} wards in city $cityId',
      );
      List<Candidate> allCandidates = [];

      for (var wardDoc in wardsSnapshot.docs) {
        AppLogger.candidate('🔍 getCandidatesByCity: Checking ward: ${wardDoc.id}');
        final candidatesSnapshot = await wardDoc.reference
            .collection('candidates')
            .get();
        AppLogger.candidate(
          '📊 getCandidatesByCity: Found ${candidatesSnapshot.docs.length} candidates in ward ${wardDoc.id}',
        );

        final candidates = candidatesSnapshot.docs.map((doc) {
          final data = doc.data();
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = doc.id;

          // Log candidate details
          AppLogger.candidate(
            '👤 Candidate in $cityId/${wardDoc.id}: ${candidateData['name']} (ID: ${doc.id})',
          );
          AppLogger.candidate('   Party: ${candidateData['party']}');
          AppLogger.candidate('   UserId: ${candidateData['userId']}');
          AppLogger.candidate('   Approved: ${candidateData['approved'] ?? false}');
          AppLogger.candidate('   Status: ${candidateData['status'] ?? 'unknown'}');

          return Candidate.fromJson(candidateData);
        }).toList();
        allCandidates.addAll(candidates);
      }

      // Cache all candidates if no pagination was requested
      if (startAfter == null) {
        _cacheData(cacheKey, allCandidates);
        AppLogger.candidate(
          '💾 Cached ${allCandidates.length} candidates for city $cityId',
        );
      }

      // Apply pagination
      final startIndex = startAfter != null
          ? allCandidates.indexWhere((c) => c.candidateId == startAfter.id) + 1
          : 0;
      final endIndex = startIndex + limit;
      final paginatedCandidates = allCandidates.sublist(
        startIndex,
        endIndex > allCandidates.length ? allCandidates.length : endIndex,
      );

      final lastDoc = paginatedCandidates.isNotEmpty
          ? paginatedCandidates.last as DocumentSnapshot?
          : null;
      final hasMore = endIndex < allCandidates.length;

      AppLogger.candidate(
        '✅ getCandidatesByCity: Returning ${paginatedCandidates.length} candidates ($startIndex-${endIndex - 1} of ${allCandidates.length})',
      );

      return {
        'candidates': paginatedCandidates,
        'lastDoc': lastDoc,
        'hasMore': hasMore,
      };
    } catch (e) {
      AppLogger.candidateError('Failed to fetch candidates: $e');
      throw Exception('Failed to fetch candidates: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<List<Candidate>> getCandidatesByCity(String cityId) async {
    final result = await getCandidatesByCityPaginated(
      cityId,
      limit: 1000,
    ); // Large limit for backward compatibility
    return result['candidates'] as List<Candidate>;
  }

  // Search candidates by name with pagination
  Future<Map<String, dynamic>> searchCandidatesPaginated(
    String query, {
    String? cityId,
    String? wardId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      AppLogger.candidate('🔍 Searching candidates: "$query" (limit: $limit)');

      List<Candidate> candidates = [];
      DocumentSnapshot? lastDoc;

      if (cityId != null && wardId != null) {
        // Search in specific ward with pagination
        Query queryRef = _firestore
            .collection('states')
            .doc(DEFAULT_STATE_ID)
            .collection('districts')
            .doc(
              cityId,
            ) // Using cityId as districtId for backward compatibility
            .collection('bodies')
            .doc('default') // Default body for now
            .collection('wards')
            .doc(wardId)
            .collection('candidates')
            .limit(limit);

        if (startAfter != null) {
          queryRef = queryRef.startAfterDocument(startAfter);
        }

        final snapshot = await queryRef.get();

        candidates = snapshot.docs.map((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = doc.id;
          return Candidate.fromJson(candidateData);
        }).toList();

        lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      } else if (cityId != null) {
        // Search in all wards of a city with pagination
        final wardsSnapshot = await _firestore
            .collection('states')
            .doc(DEFAULT_STATE_ID)
            .collection('districts')
            .doc(cityId)
            .collection('bodies')
            .doc('default')
            .collection('wards')
            .get();

        // For pagination across multiple collections, we need to collect from all wards
        // and then apply pagination to the combined results
        List<Candidate> allCandidates = [];

        for (var wardDoc in wardsSnapshot.docs) {
          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .get();
          final wardCandidates = candidatesSnapshot.docs.map((doc) {
            final data = doc.data();
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = doc.id;
            return Candidate.fromJson(candidateData);
          }).toList();
          allCandidates.addAll(wardCandidates);
        }

        // Apply pagination to combined results
        final startIndex = startAfter != null
            ? allCandidates.indexWhere((c) => c.candidateId == startAfter.id) +
                  1
            : 0;
        final endIndex = startIndex + limit;
        candidates = allCandidates.sublist(
          startIndex,
          endIndex > allCandidates.length ? allCandidates.length : endIndex,
        );

        lastDoc = candidates.isNotEmpty
            ? candidates.last as DocumentSnapshot?
            : null;
      } else {
        // Search across all cities and wards with pagination (limited scope for performance)
        AppLogger.candidate(
          '⚠️ Global search with pagination - limiting to first 100 candidates for performance',
        );

        final districtsSnapshot = await _firestore
            .collection('states')
            .doc(DEFAULT_STATE_ID)
            .collection('districts')
            .limit(5)
            .get(); // Limit districts
        List<Candidate> allCandidates = [];

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference
              .collection('bodies')
              .limit(3)
              .get(); // Limit bodies

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference
                .collection('wards')
                .limit(5)
                .get(); // Limit wards

            for (var wardDoc in wardsSnapshot.docs) {
              final candidatesSnapshot = await wardDoc.reference
                  .collection('candidates')
                  .limit(10)
                  .get(); // Limit per ward
              final wardCandidates = candidatesSnapshot.docs.map((doc) {
                final data = doc.data();
                final candidateData = Map<String, dynamic>.from(data);
                candidateData['candidateId'] = doc.id;
                return Candidate.fromJson(candidateData);
              }).toList();
              allCandidates.addAll(wardCandidates);

              if (allCandidates.length >= 100) break; // Safety limit
            }
            if (allCandidates.length >= 100) break;
          }
          if (allCandidates.length >= 100) break;
        }

        // Apply pagination to combined results
        final startIndex = startAfter != null
            ? allCandidates.indexWhere((c) => c.candidateId == startAfter.id) +
                  1
            : 0;
        final endIndex = startIndex + limit;
        candidates = allCandidates.sublist(
          startIndex,
          endIndex > allCandidates.length ? allCandidates.length : endIndex,
        );

        lastDoc = candidates.isNotEmpty
            ? candidates.last as DocumentSnapshot?
            : null;
      }

      // Filter by search query
      final filteredCandidates = candidates
          .where(
            (candidate) =>
                candidate.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      AppLogger.candidate(
        '✅ Found ${filteredCandidates.length} candidates matching "$query"',
      );

      return {
        'candidates': filteredCandidates,
        'lastDoc': lastDoc,
        'hasMore': filteredCandidates.length == limit,
      };
    } catch (e) {
      AppLogger.candidateError('Failed to search candidates: $e');
      throw Exception('Failed to search candidates: $e');
    }
  }

  // Legacy search method for backward compatibility
  Future<List<Candidate>> searchCandidates(
    String query, {
    String? cityId,
    String? wardId,
  }) async {
    final result = await searchCandidatesPaginated(
      query,
      cityId: cityId,
      wardId: wardId,
      limit: 100,
    );
    return result['candidates'] as List<Candidate>;
  }

  // Batch: Get multiple candidates by IDs
  Future<List<Candidate?>> getCandidatesByIds(List<String> candidateIds) async {
    try {
      AppLogger.candidate('📦 BATCH: Fetching ${candidateIds.length} candidates by IDs');

      final candidates = <Candidate?>[];
      final batchSize = 10; // Firestore limit for 'in' queries

      // Process in batches to avoid Firestore limits
      for (var i = 0; i < candidateIds.length; i += batchSize) {
        final batchIds = candidateIds.sublist(
          i,
          i + batchSize > candidateIds.length
              ? candidateIds.length
              : i + batchSize,
        );

        // Try to get from index first
        final indexResults = await Future.wait(
          batchIds.map(
            (id) => _firestore.collection('candidate_index').doc(id).get(),
          ),
        );

        final locationMap = <String, Map<String, dynamic>>{};
        final missingIds = <String>[];

        for (var j = 0; j < batchIds.length; j++) {
          final id = batchIds[j];
          final indexDoc = indexResults[j];

          if (indexDoc.exists) {
            locationMap[id] = indexDoc.data()!;
          } else {
            missingIds.add(id);
          }
        }

        // Batch read candidates with known locations
        if (locationMap.isNotEmpty) {
          final batchReads = locationMap.entries.map((entry) async {
            final location = entry.value;
            final stateId = location['stateId'] ?? DEFAULT_STATE_ID; // Use dynamic state ID
            final candidateDoc = await _firestore
                .collection('states')
                .doc(stateId)
                .collection('districts')
                .doc(location['districtId'])
                .collection('bodies')
                .doc(location['bodyId'])
                .collection('wards')
                .doc(location['wardId'])
                .collection('candidates')
                .doc(entry.key)
                .get();

            if (candidateDoc.exists) {
              final data = candidateDoc.data()!;
              final candidateData = Map<String, dynamic>.from(data);
              candidateData['candidateId'] = candidateDoc.id;
              return Candidate.fromJson(candidateData);
            }
            return null;
          });

          final batchResults = await Future.wait(batchReads);
          candidates.addAll(batchResults);
        }

        // Handle missing IDs with optimized search
        for (final id in missingIds) {
          final candidate = await getCandidateDataById(id);
          candidates.add(candidate);
        }
      }

      AppLogger.candidate(
        '✅ BATCH: Retrieved ${candidates.where((c) => c != null).length}/${candidateIds.length} candidates',
      );
      return candidates;
    } catch (e) {
      AppLogger.candidateError('Failed to get candidates by IDs: $e');
      throw Exception('Failed to get candidates by IDs: $e');
    }
  }

  // Batch: Update multiple candidates with same field updates
  Future<void> batchUpdateCandidates(
    List<String> candidateIds,
    Map<String, dynamic> fieldUpdates,
  ) async {
    try {
      AppLogger.candidate(
        '📦 BATCH: Updating ${candidateIds.length} candidates with ${fieldUpdates.length} fields',
      );

      final batch = _firestore.batch();
      var updateCount = 0;

      for (final candidateId in candidateIds) {
        // Get location from index
        final indexDoc = await _firestore
            .collection('candidate_index')
            .doc(candidateId)
            .get();

        if (indexDoc.exists) {
          final location = indexDoc.data()!;
          final stateId = location['stateId'] ?? DEFAULT_STATE_ID; // Use dynamic state ID
          final candidateRef = _firestore
              .collection('states')
              .doc(stateId)
              .collection('districts')
              .doc(location['districtId'])
              .collection('bodies')
              .doc(location['bodyId'])
              .collection('wards')
              .doc(location['wardId'])
              .collection('candidates')
              .doc(candidateId);

          batch.update(candidateRef, fieldUpdates);
          updateCount++;

          // Invalidate cache for this candidate
          invalidateCache(
            'candidates_${stateId}_${location['districtId']}_${location['bodyId']}_${location['wardId']}',
          );
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.candidate('✅ BATCH: Successfully updated $updateCount candidates');
      } else {
        AppLogger.candidate('⚠️ BATCH: No candidates found to update');
      }
    } catch (e) {
      AppLogger.candidateError('Failed to batch update candidates: $e');
      throw Exception('Failed to batch update candidates: $e');
    }
  }

  // Batch: Get user data and following in single operation
  Future<Map<String, dynamic>> getUserDataAndFollowing(String userId) async {
    try {
      AppLogger.candidate('📦 BATCH: Fetching user data and following together');

      final results = await Future.wait([
        _firestore.collection('users').doc(userId).get(),
        getUserFollowing(userId),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final following = results[1] as List<String>;

      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;
      }

      AppLogger.candidate(
        '✅ BATCH: Retrieved user data and ${following.length} following',
      );
      return {'user': userData, 'following': following};
    } catch (e) {
      AppLogger.candidateError('Failed to get user data and following: $e');
      throw Exception('Failed to get user data and following: $e');
    }
  }

  // Debug method: Log all candidates across the entire system
  Future<void> logAllCandidatesInSystem() async {
    try {
      AppLogger.candidate('🔍 ===== SYSTEM CANDIDATE AUDIT =====');
      AppLogger.candidate('🔍 Scanning all states, districts, bodies, wards, and candidates...');

      final districtsSnapshot = await _firestore
          .collection('states')
          .doc(DEFAULT_STATE_ID)
          .collection('districts')
          .get();
      AppLogger.candidate('📊 Total districts in system: ${districtsSnapshot.docs.length}');

      int totalCandidates = 0;
      int totalWards = 0;
      int totalBodies = 0;

      for (var districtDoc in districtsSnapshot.docs) {
        AppLogger.candidate('🏙️ ===== DISTRICT: ${districtDoc.id} =====');
        final districtData = districtDoc.data();
        AppLogger.candidate('   Name: ${districtData['name'] ?? 'Unknown'}');
        AppLogger.candidate('   State: ${districtData['state'] ?? 'Unknown'}');

        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();
        AppLogger.candidate('📊 Bodies in ${districtDoc.id}: ${bodiesSnapshot.docs.length}');
        totalBodies += bodiesSnapshot.docs.length;

        for (var bodyDoc in bodiesSnapshot.docs) {
          AppLogger.candidate('🏛️ ===== BODY: ${bodyDoc.id} in ${districtDoc.id} =====');
          final bodyData = bodyDoc.data();
          AppLogger.candidate('   Name: ${bodyData['name'] ?? 'Unknown'}');

          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();
          AppLogger.candidate('📊 Wards in ${districtDoc.id}/${bodyDoc.id}: ${wardsSnapshot.docs.length}');
          totalWards += wardsSnapshot.docs.length;

          for (var wardDoc in wardsSnapshot.docs) {
            AppLogger.candidate('🏛️ ===== WARD: ${wardDoc.id} in ${districtDoc.id}/${bodyDoc.id} =====');
            final wardData = wardDoc.data();
            AppLogger.candidate('   Name: ${wardData['name'] ?? 'Unknown'}');
            AppLogger.candidate('   Population: ${wardData['population'] ?? 'Unknown'}');

            final candidatesSnapshot = await wardDoc.reference
                .collection('candidates')
                .get();
            AppLogger.candidate(
              '👥 Candidates in ${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}: ${candidatesSnapshot.docs.length}',
            );
            totalCandidates += candidatesSnapshot.docs.length;

            for (var candidateDoc in candidatesSnapshot.docs) {
              final candidateData = candidateDoc.data();
              AppLogger.candidate('👤 ===== CANDIDATE =====');
              AppLogger.candidate('   ID: ${candidateDoc.id}');
              AppLogger.candidate('   Name: ${candidateData['name'] ?? 'Unknown'}');
              AppLogger.candidate('   Party: ${candidateData['party'] ?? 'Unknown'}');
              AppLogger.candidate('   UserId: ${candidateData['userId'] ?? 'Unknown'}');
              AppLogger.candidate('   Approved: ${candidateData['approved'] ?? false}');
              AppLogger.candidate('   Status: ${candidateData['status'] ?? 'unknown'}');
              AppLogger.candidate('   Followers: ${candidateData['followersCount'] ?? 0}');
              AppLogger.candidate('   Symbol: ${candidateData['symbol'] ?? 'Unknown'}');

              // Log extra info if available
              final extraInfo =
                  candidateData['extra_info'] as Map<String, dynamic>?;
              if (extraInfo != null) {
                AppLogger.candidate('   📋 Extra Info:');
                AppLogger.candidate('      Bio: ${extraInfo['bio'] ?? 'Not set'}');
                AppLogger.candidate(
                  '      Education: ${extraInfo['education'] ?? 'Not set'}',
                );
                AppLogger.candidate('      Age: ${extraInfo['age'] ?? 'Not set'}');
                AppLogger.candidate('      Gender: ${extraInfo['gender'] ?? 'Not set'}');
              }

              AppLogger.candidate('   ====================');
            }

            if (candidatesSnapshot.docs.isEmpty) {
              AppLogger.candidate('⚠️ No candidates found in ${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}');
            }
          }

          AppLogger.candidate('🏛️ ===== END BODY: ${bodyDoc.id} =====');
        }

        AppLogger.candidate('🏙️ ===== END DISTRICT: ${districtDoc.id} =====');
      }

      AppLogger.candidate('🔍 ===== SYSTEM AUDIT SUMMARY =====');
      AppLogger.candidate('📊 Total Districts: ${districtsSnapshot.docs.length}');
      AppLogger.candidate('📊 Total Bodies: $totalBodies');
      AppLogger.candidate('📊 Total Wards: $totalWards');
      AppLogger.candidate('👥 Total Candidates: $totalCandidates');
      AppLogger.candidate('✅ Audit completed successfully');
    } catch (e) {
      AppLogger.candidateError('Error during system audit: $e');
    }
  }
}

