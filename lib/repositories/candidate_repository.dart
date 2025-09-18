import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/candidate_model.dart';
import '../models/ward_model.dart';
import '../models/city_model.dart';
import '../utils/data_compression.dart';
import '../utils/error_recovery_manager.dart';
import '../utils/advanced_analytics.dart';
import '../utils/multi_level_cache.dart';
import '../utils/performance_monitor.dart' as perf_monitor;
import '../models/body_model.dart';

class CandidateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCompressionManager _compressionManager = DataCompressionManager();
  final FirebaseDataOptimizer _dataOptimizer = FirebaseDataOptimizer();

  // Optimization systems
  final ErrorRecoveryManager _errorRecovery = ErrorRecoveryManager();
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final MultiLevelCache _cache = MultiLevelCache();

  // Enhanced repository-level caching
  static final Map<String, List<Candidate>> _candidateCache = {};
  static final Map<String, List<Ward>> _wardCache = {};
  static final Map<String, List<Body>> _bodyCache = {};
  static final Map<String, List<City>> _cityCache = {};
  static final Map<String, List<String>> _followingCache = {};
  static final Map<String, Map<String, dynamic>> _queryResultCache =
      {}; // For complex query results
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(
    minutes: 15,
  ); // Longer than controller cache
  static const Duration _queryCacheValidityDuration = Duration(
    minutes: 5,
  ); // Shorter for query results

  // Check if cache is valid
  bool _isCacheValid(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) return false;
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  // Check if query cache is valid (shorter TTL)
  bool _isQueryCacheValid(String cacheKey) {
    if (!_cacheTimestamps.containsKey(cacheKey)) return false;
    final cacheTime = _cacheTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _queryCacheValidityDuration;
  }

  // Cache query results with metadata
  void _cacheQueryResult(String cacheKey, Map<String, dynamic> result) {
    _queryResultCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  // Get cached query result
  Map<String, dynamic>? _getCachedQueryResult(String cacheKey) {
    return _isQueryCacheValid(cacheKey) ? _queryResultCache[cacheKey] : null;
  }

  // Generate cache key for complex queries
  String _generateQueryCacheKey(String operation, Map<String, dynamic> params) {
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final paramString = sortedParams
        .map((e) => '${e.key}:${e.value}')
        .join('_');
    return 'query_${operation}_${paramString.hashCode}';
  }

  // Cache data with timestamp
  void _cacheData(String cacheKey, dynamic data) {
    if (data is List<Candidate>) {
      _candidateCache[cacheKey] = List.from(data);
    } else if (data is List<Ward>) {
      _wardCache[cacheKey] = List.from(data);
    } else if (data is List<Body>) {
      _bodyCache[cacheKey] = List.from(data);
    } else if (data is List<City>) {
      _cityCache[cacheKey] = List.from(data);
    } else if (data is List<String>) {
      _followingCache[cacheKey] = List.from(data);
    }
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  // Get cached data
  List<Candidate>? _getCachedCandidates(String cacheKey) {
    return _isCacheValid(cacheKey) ? _candidateCache[cacheKey] : null;
  }

  List<Ward>? _getCachedWards(String cacheKey) {
    return _isCacheValid(cacheKey) ? _wardCache[cacheKey] : null;
  }

  List<Body>? _getCachedBodies(String cacheKey) {
    return _isCacheValid(cacheKey) ? _bodyCache[cacheKey] : null;
  }

  List<City>? _getCachedCities(String cacheKey) {
    return _isCacheValid(cacheKey) ? _cityCache[cacheKey] : null;
  }

  List<String>? _getCachedFollowing(String cacheKey) {
    return _isCacheValid(cacheKey) ? _followingCache[cacheKey] : null;
  }

  // Invalidate cache for specific keys
  void invalidateCache(String cacheKey) {
    _candidateCache.remove(cacheKey);
    _wardCache.remove(cacheKey);
    _bodyCache.remove(cacheKey);
    _cityCache.remove(cacheKey);
    _followingCache.remove(cacheKey);
    _queryResultCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    debugPrint('🗑️ Invalidated cache for key: $cacheKey');
  }

  // Invalidate all cache
  void invalidateAllCache() {
    _candidateCache.clear();
    _wardCache.clear();
    _bodyCache.clear();
    _cityCache.clear();
    _followingCache.clear();
    _queryResultCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🗑️ Invalidated all cache');
  }

  // Invalidate query cache by pattern
  void invalidateQueryCache(String pattern) {
    final keysToRemove = _queryResultCache.keys
        .where((key) => key.contains(pattern))
        .toList();
    for (final key in keysToRemove) {
      _queryResultCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    debugPrint(
      '🗑️ Invalidated ${keysToRemove.length} query cache entries matching: $pattern',
    );
  }

  // Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheValidityDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _candidateCache.remove(key);
      _wardCache.remove(key);
      _bodyCache.remove(key);
      _cityCache.remove(key);
      _followingCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  // Batch: Get multiple candidates by IDs
  Future<List<Candidate?>> getCandidatesByIds(List<String> candidateIds) async {
    try {
      debugPrint('📦 BATCH: Fetching ${candidateIds.length} candidates by IDs');

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
            final candidateDoc = await _firestore
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

      debugPrint(
        '✅ BATCH: Retrieved ${candidates.where((c) => c != null).length}/${candidateIds.length} candidates',
      );
      return candidates;
    } catch (e) {
      debugPrint('❌ BATCH: Failed to get candidates by IDs: $e');
      throw Exception('Failed to get candidates by IDs: $e');
    }
  }

  // Batch: Update multiple candidates with same field updates
  Future<void> batchUpdateCandidates(
    List<String> candidateIds,
    Map<String, dynamic> fieldUpdates,
  ) async {
    try {
      debugPrint(
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
          final candidateRef = _firestore
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
            'candidates_${location['districtId']}_${location['bodyId']}_${location['wardId']}',
          );
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        debugPrint('✅ BATCH: Successfully updated $updateCount candidates');
      } else {
        debugPrint('⚠️ BATCH: No candidates found to update');
      }
    } catch (e) {
      debugPrint('❌ BATCH: Failed to batch update candidates: $e');
      throw Exception('Failed to batch update candidates: $e');
    }
  }

  // Batch: Get user data and following in single operation
  Future<Map<String, dynamic>> getUserDataAndFollowing(String userId) async {
    try {
      debugPrint('📦 BATCH: Fetching user data and following together');

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

      debugPrint(
        '✅ BATCH: Retrieved user data and ${following.length} following',
      );
      return {'user': userData, 'following': following};
    } catch (e) {
      debugPrint('❌ BATCH: Failed to get user data and following: $e');
      throw Exception('Failed to get user data and following: $e');
    }
  }

  // Get enhanced cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalDataSize =
        _candidateCache.values
            .map(
              (candidates) => candidates.length * 1024,
            ) // Rough estimate: 1KB per candidate
            .fold(0, (a, b) => a + b) +
        _wardCache.values
            .map(
              (wards) => wards.length * 512,
            ) // Rough estimate: 0.5KB per ward
            .fold(0, (a, b) => a + b) +
        _bodyCache.values
            .map(
              (bodies) => bodies.length * 256,
            ) // Rough estimate: 0.25KB per body
            .fold(0, (a, b) => a + b) +
        _cityCache.values
            .map(
              (cities) => cities.length * 256,
            ) // Rough estimate: 0.25KB per city
            .fold(0, (a, b) => a + b) +
        _followingCache.values
            .map(
              (following) => following.length * 64,
            ) // Rough estimate: 64B per following entry
            .fold(0, (a, b) => a + b) +
        _queryResultCache.values
            .map(
              (result) => result.toString().length * 2,
            ) // Rough estimate: 2B per char
            .fold(0, (a, b) => a + b);

    return {
      'total_entries': _cacheTimestamps.length,
      'candidate_cache_size': _candidateCache.length,
      'ward_cache_size': _wardCache.length,
      'body_cache_size': _bodyCache.length,
      'city_cache_size': _cityCache.length,
      'following_cache_size': _followingCache.length,
      'query_cache_size': _queryResultCache.length,
      'cache_size_mb': totalDataSize / (1024 * 1024),
      'cache_hit_rate': _calculateCacheHitRate(),
      'oldest_entry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest_entry': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // Calculate cache hit rate (simplified)
  double _calculateCacheHitRate() {
    // This would need to be tracked with actual hit/miss counters
    // For now, return a placeholder
    return 0.85; // 85% hit rate as example
  }

  // Get candidates by ward with advanced optimizations
  Future<List<Candidate>> getCandidatesByWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    final monitor = perf_monitor.PerformanceMonitor();
    monitor.startTimer('getCandidatesByWard');

    final cacheKey = 'candidates_${districtId}_${bodyId}_$wardId';

    // Check multi-level cache first
    final cachedData = await _cache.get<List<Candidate>>(cacheKey);
    if (cachedData != null) {
      _analytics.trackFirebaseOperation(
        'cache_hit',
        'candidates',
        cachedData.length,
      );
      monitor.stopTimer('getCandidatesByWard');
      debugPrint(
        '⚡ MULTI_CACHE HIT: Returning ${cachedData.length} cached candidates for ward $wardId',
      );
      return cachedData;
    }

    // Check legacy cache as fallback
    final cachedCandidates = _getCachedCandidates(cacheKey);
    if (cachedCandidates != null) {
      monitor.trackCacheHit('candidate_ward');
      monitor.stopTimer('getCandidatesByWard');
      debugPrint(
        '⚡ LEGACY CACHE HIT: Returning ${cachedCandidates.length} cached candidates for ward $wardId',
      );
      return cachedCandidates;
    }

    monitor.trackCacheMiss('candidate_ward');
    debugPrint(
      '🔍 CACHE MISS: Fetching candidates for $districtId/$bodyId/$wardId from Firebase',
    );

    try {
      // Use error recovery for Firebase operation
      final snapshot = await _errorRecovery.executeWithRecovery(
        'get_candidates_by_ward',
        () async {
          return await _firestore
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

      debugPrint(
        '📊 getCandidatesByWard: Found ${snapshot.docs.length} candidates in $districtId/$bodyId/$wardId',
      );

      final candidates = snapshot.docs.map((doc) {
        final data = doc.data();
        // Decompress data if it was compressed during storage
        final decompressedData = _dataOptimizer.optimizeAfterLoad(data);
        final candidateData = Map<String, dynamic>.from(decompressedData);
        candidateData['candidateId'] = doc.id;

        // Log candidate details
        debugPrint('👤 Candidate: ${candidateData['name']} (ID: ${doc.id})');
        debugPrint('   Party: ${candidateData['party']}');
        debugPrint('   UserId: ${candidateData['userId']}');
        debugPrint('   District: $districtId, Body: $bodyId, Ward: $wardId');
        debugPrint('   Approved: ${candidateData['approved'] ?? false}');
        debugPrint('   Status: ${candidateData['status'] ?? 'unknown'}');

        return Candidate.fromJson(candidateData);
      }).toList();

      // Cache in both systems
      await _cache.set(cacheKey, candidates, ttl: Duration(minutes: 15));
      _cacheData(cacheKey, candidates); // Legacy cache
      debugPrint(
        '💾 Cached ${candidates.length} candidates for ward $wardId in both cache systems',
      );

      monitor.stopTimer('getCandidatesByWard');
      debugPrint(
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
      debugPrint('❌ getCandidatesByWard: Failed to fetch candidates: $e');
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
        debugPrint(
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

    debugPrint(
      '🔍 CACHE MISS: Fetching candidates for city $cityId from Firebase (limit: $limit)',
    );
    try {
      final wardsSnapshot = await _firestore
          .collection('districts')
          .doc(cityId) // Using cityId as districtId for backward compatibility
          .collection('bodies')
          .doc('default') // Default body
          .collection('wards')
          .get();

      debugPrint(
        '📊 getCandidatesByCity: Found ${wardsSnapshot.docs.length} wards in city $cityId',
      );
      List<Candidate> allCandidates = [];

      for (var wardDoc in wardsSnapshot.docs) {
        debugPrint('🔍 getCandidatesByCity: Checking ward: ${wardDoc.id}');
        final candidatesSnapshot = await wardDoc.reference
            .collection('candidates')
            .get();
        debugPrint(
          '📊 getCandidatesByCity: Found ${candidatesSnapshot.docs.length} candidates in ward ${wardDoc.id}',
        );

        final candidates = candidatesSnapshot.docs.map((doc) {
          final data = doc.data();
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = doc.id;

          // Log candidate details
          debugPrint(
            '👤 Candidate in $cityId/${wardDoc.id}: ${candidateData['name']} (ID: ${doc.id})',
          );
          debugPrint('   Party: ${candidateData['party']}');
          debugPrint('   UserId: ${candidateData['userId']}');
          debugPrint('   Approved: ${candidateData['approved'] ?? false}');
          debugPrint('   Status: ${candidateData['status'] ?? 'unknown'}');

          return Candidate.fromJson(candidateData);
        }).toList();
        allCandidates.addAll(candidates);
      }

      // Cache all candidates if no pagination was requested
      if (startAfter == null) {
        _cacheData(cacheKey, allCandidates);
        debugPrint(
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

      debugPrint(
        '✅ getCandidatesByCity: Returning ${paginatedCandidates.length} candidates ($startIndex-${endIndex - 1} of ${allCandidates.length})',
      );

      return {
        'candidates': paginatedCandidates,
        'lastDoc': lastDoc,
        'hasMore': hasMore,
      };
    } catch (e) {
      debugPrint('❌ getCandidatesByCity: Failed to fetch candidates: $e');
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

  // Get wards for a city
  Future<List<Ward>> getWardsByCity(String cityId) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final wardData = Map<String, dynamic>.from(data);
        wardData['wardId'] = doc.id;
        wardData['cityId'] = cityId;
        return Ward.fromJson(wardData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

  // Get wards for a district and body
  Future<List<Ward>> getWardsByDistrictAndBody(
    String districtId,
    String bodyId,
  ) async {
    final cacheKey = 'wards_${districtId}_$bodyId';

    // Check cache first
    final cachedWards = _getCachedWards(cacheKey);
    if (cachedWards != null) {
      debugPrint(
        '⚡ CACHE HIT: Returning ${cachedWards.length} cached wards for $districtId/$bodyId',
      );
      return cachedWards;
    }

    debugPrint(
      '🔍 CACHE MISS: Fetching wards for $districtId/$bodyId from Firebase',
    );
    try {
      final snapshot = await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = snapshot.docs.map((doc) {
        final data = doc.data();
        final wardData = Map<String, dynamic>.from(data);
        wardData['wardId'] = doc.id;
        wardData['districtId'] = districtId;
        wardData['bodyId'] = bodyId;
        return Ward.fromJson(wardData);
      }).toList();

      // Cache the results
      _cacheData(cacheKey, wards);
      debugPrint('💾 Cached ${wards.length} wards for $districtId/$bodyId');

      return wards;
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

  // Get all cities
  Future<List<City>> getAllCities() async {
    const cacheKey = 'all_cities';

    // Check cache first
    final cachedCities = _getCachedCities(cacheKey);
    if (cachedCities != null) {
      debugPrint('⚡ CACHE HIT: Returning ${cachedCities.length} cached cities');
      return cachedCities;
    }

    debugPrint('🔍 CACHE MISS: Fetching all cities from Firebase');
    try {
      final snapshot = await _firestore.collection('cities').get();
      debugPrint('📊 getAllCities: Found ${snapshot.docs.length} cities');

      final cities = snapshot.docs.map((doc) {
        final data = doc.data();
        final cityData = Map<String, dynamic>.from(data);
        cityData['cityId'] = doc.id;

        debugPrint(
          '🏙️ City: ${cityData['name'] ?? 'Unknown'} (ID: ${doc.id})',
        );
        debugPrint('   State: ${cityData['state'] ?? 'Unknown'}');
        debugPrint('   Population: ${cityData['population'] ?? 'Unknown'}');

        return City.fromJson(cityData);
      }).toList();

      // Cache the results
      _cacheData(cacheKey, cities);
      debugPrint('💾 Cached ${cities.length} cities');

      debugPrint('✅ getAllCities: Successfully loaded ${cities.length} cities');
      return cities;
    } catch (e) {
      debugPrint('❌ getAllCities: Failed to fetch cities: $e');
      throw Exception('Failed to fetch cities: $e');
    }
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
      debugPrint('🔍 Searching candidates: "$query" (limit: $limit)');

      List<Candidate> candidates = [];
      DocumentSnapshot? lastDoc;

      if (cityId != null && wardId != null) {
        // Search in specific ward with pagination
        Query queryRef = _firestore
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
        debugPrint(
          '⚠️ Global search with pagination - limiting to first 100 candidates for performance',
        );

        final districtsSnapshot = await _firestore
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

      debugPrint(
        '✅ Found ${filteredCandidates.length} candidates matching "$query"',
      );

      return {
        'candidates': filteredCandidates,
        'lastDoc': lastDoc,
        'hasMore': filteredCandidates.length == limit,
      };
    } catch (e) {
      debugPrint('❌ Failed to search candidates: $e');
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

  // Get candidate data by user ID (optimized)
  Future<Candidate?> getCandidateData(String userId) async {
    try {
      debugPrint(
        '🔍 Candidate Repository: Searching for candidate data for userId: $userId',
      );

      // First, get the user's districtId, bodyId and wardId from their user document
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('❌ User document not found for userId: $userId');
        debugPrint(
          '🔄 Falling back to brute force search due to missing user document',
        );
        // Fallback to brute force search if user document doesn't exist
        return await _getCandidateDataBruteForce(userId);
      }

      final userData = userDoc.data()!;
      final districtId =
          userData['districtId'] ??
          userData['cityId']; // Backward compatibility
      final bodyId = userData['bodyId'];
      final wardId = userData['wardId'];

      if (districtId == null ||
          wardId == null ||
          districtId.isEmpty ||
          wardId.isEmpty) {
        debugPrint(
          '⚠️ User has no districtId or wardId, falling back to brute force search',
        );
        // Fallback to the old method if location info is missing
        return await _getCandidateDataBruteForce(userId);
      }

      debugPrint(
        '🎯 Direct search: District: $districtId, Body: $bodyId, Ward: $wardId',
      );

      // Direct query to the specific district/body/ward path
      final candidatesSnapshot = await _firestore
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

      debugPrint(
        '👤 Found ${candidatesSnapshot.docs.length} candidates in $districtId/$bodyId/$wardId',
      );

      if (candidatesSnapshot.docs.isNotEmpty) {
        final doc = candidatesSnapshot.docs.first;
        final data = doc.data();
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = doc.id;

        debugPrint('📄 Raw candidate data from DB:');
        final extraInfo = data['extra_info'] as Map<String, dynamic>?;
        debugPrint('   extra_info keys: ${extraInfo?.keys.toList() ?? 'null'}');
        debugPrint(
          '   education in extra_info: ${extraInfo?.containsKey('education') ?? false}',
        );
        debugPrint(
          '   education value: ${extraInfo != null && extraInfo.containsKey('education') ? extraInfo['education'] : 'not found'}',
        );

        debugPrint(
          '✅ Found candidate: ${candidateData['name']} (ID: ${doc.id})',
        );
        return Candidate.fromJson(candidateData);
      }

      debugPrint(
        '❌ No candidate found in user\'s district/body/ward: $districtId/$bodyId/$wardId',
      );

      // Fallback: Check legacy /candidates collection
      debugPrint('🔄 Checking legacy /candidates collection for userId: $userId');

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

        debugPrint(
          '✅ Found candidate in legacy collection: ${candidateData['name']} (ID: ${doc.id})',
        );
        debugPrint('   userId in doc: ${candidateData['userId']}');

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
      debugPrint('🔍 No exact match, checking all candidates in legacy collection...');
      final allCandidates = await _firestore.collection('candidates').limit(10).get();
      debugPrint('📊 Found ${allCandidates.docs.length} total candidates in legacy collection');

      for (var doc in allCandidates.docs) {
        final data = doc.data();
        debugPrint('   Candidate ${doc.id}: userId=${data['userId']}, name=${data['name']}');
      }

      debugPrint('❌ No candidate found in legacy collection either');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching candidate data: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Fallback brute force search (for backward compatibility)
  Future<Candidate?> _getCandidateDataBruteForce(String userId) async {
    debugPrint('🔍 Falling back to brute force search for userId: $userId');
    final citiesSnapshot = await _firestore.collection('cities').get();
    debugPrint('📊 Found ${citiesSnapshot.docs.length} cities to search');

    for (var cityDoc in citiesSnapshot.docs) {
      debugPrint('🔍 Searching city: ${cityDoc.id}');
      final wardsSnapshot = await cityDoc.reference.collection('wards').get();
      debugPrint(
        '📊 Found ${wardsSnapshot.docs.length} wards in city ${cityDoc.id}',
      );

      for (var wardDoc in wardsSnapshot.docs) {
        debugPrint('🔍 Searching ward: ${wardDoc.id} in city ${cityDoc.id}');
        final candidatesSnapshot = await wardDoc.reference
            .collection('candidates')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        debugPrint(
          '👤 Found ${candidatesSnapshot.docs.length} candidates in ${cityDoc.id}/${wardDoc.id}',
        );

        // Debug: Check all candidates in this ward to see their userIds
        if (candidatesSnapshot.docs.isEmpty) {
          final allCandidates = await wardDoc.reference
              .collection('candidates')
              .get();
          debugPrint(
            '📋 Total candidates in ${cityDoc.id}/${wardDoc.id}: ${allCandidates.docs.length}',
          );
          for (var doc in allCandidates.docs) {
            final data = doc.data();
            final candidateUserId = data['userId'];
            debugPrint('   Candidate ${doc.id}: userId = $candidateUserId');
          }
        }

        if (candidatesSnapshot.docs.isNotEmpty) {
          final doc = candidatesSnapshot.docs.first;
          final data = doc.data();
          final candidateData = Map<String, dynamic>.from(data);
          candidateData['candidateId'] = doc.id;

          // Update user document with city/ward info for future use
          await ensureUserDocumentExists(
            userId,
            cityId: cityDoc.id,
            wardId: wardDoc.id,
          );

          debugPrint(
            '✅ Found candidate via brute force: ${candidateData['name']} (ID: ${doc.id}) in ${cityDoc.id}/${wardDoc.id}',
          );
          return Candidate.fromJson(candidateData);
        }
      }
    }

    debugPrint('❌ No candidate found via brute force search');
    return null;
  }

  // Update candidate extra info (legacy - saves entire object)
  Future<bool> updateCandidateExtraInfo(Candidate candidate) async {
    try {
      // Find the candidate's location in the new district/body/ward structure
      final districtsSnapshot = await _firestore.collection('districts').get();
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
                    'symbol': candidate.symbol,
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
        debugPrint('🔄 Candidate not found in new structure, trying legacy collection');
        final legacyDocRef = _firestore.collection('candidates').doc(candidate.candidateId);
        final legacyDoc = await legacyDocRef.get();

        if (legacyDoc.exists) {
          await legacyDocRef.update({
            'name': candidate.name,
            'party': candidate.party,
            'symbol': candidate.symbol,
            'extra_info': candidate.extraInfo?.toJson(),
            'photo': candidate.photo,
            'manifesto': candidate.manifesto,
            'contact': candidate.contact.toJson(),
          });
          debugPrint('✅ Successfully updated candidate in legacy collection');
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

        debugPrint(
          '🎯 Using indexed location for update: $districtId/$bodyId/$wardId',
        );

        // Direct update using location metadata
        await _firestore
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
        invalidateCache('candidates_${districtId}_${bodyId}_$wardId');

        return true;
      }

      // Fallback: Optimized brute force search
      debugPrint(
        '🔄 Index not found, using optimized brute force search for update',
      );
      final districtsSnapshot = await _firestore.collection('districts').get();

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
                districtDoc.id,
                bodyDoc.id,
                wardDoc.id,
              );
              invalidateCache(
                'candidates_${districtDoc.id}_${bodyDoc.id}_${wardDoc.id}',
              );

              return true;
            }
          }
        }
      }

      // If not found in new structure, try legacy collection
      debugPrint('🔄 Candidate not found in new structure, trying legacy collection');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);
      final legacyDoc = await legacyDocRef.get();

      if (legacyDoc.exists) {
        await legacyDocRef.update(fieldUpdates);
        debugPrint('✅ Successfully updated candidate in legacy collection');
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
      debugPrint(
        '🔄 updateCandidateExtraInfoFields - Input: $extraInfoUpdates',
      );

      // Convert extra_info field updates to dot notation
      final fieldUpdates = <String, dynamic>{};

      extraInfoUpdates.forEach((key, value) {
        fieldUpdates['extra_info.$key'] = value;
        debugPrint('   Converting $key -> extra_info.$key = $value');
      });

      debugPrint('   Final field updates: $fieldUpdates');

      // Try to update in new structure first
      try {
        final success = await updateCandidateFields(candidateId, fieldUpdates);
        if (success) return true;
      } catch (e) {
        debugPrint('⚠️ Failed to update in new structure: $e');
      }

      // Fallback: Update in legacy collection
      debugPrint('🔄 Falling back to legacy collection update');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);

      // Check if candidate exists in legacy collection
      final legacyDoc = await legacyDocRef.get();
      if (!legacyDoc.exists) {
        throw Exception('Candidate not found in legacy collection either');
      }

      await legacyDocRef.update(fieldUpdates);
      debugPrint('✅ Successfully updated candidate in legacy collection');

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

      // Find the candidate's location in the new district/body/ward structure
      final districtsSnapshot = await _firestore.collection('districts').get();
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
      debugPrint('🔄 Candidate not found in new structure, trying legacy collection');
      final legacyDocRef = _firestore.collection('candidates').doc(candidateId);
      final legacyDoc = await legacyDocRef.get();

      if (legacyDoc.exists) {
        batch.update(legacyDocRef, updates);
        await batch.commit();
        debugPrint('✅ Successfully updated candidate in legacy collection');
        return true;
      }

      throw Exception('Candidate not found');
    } catch (e) {
      throw Exception('Failed to batch update candidate fields: $e');
    }
  }

  // Follow/Unfollow System Methods

  // Follow a candidate - Optimized version
  Future<void> followCandidate(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
  }) async {
    try {
      // First try to get location from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();
      String? candidateDistrictId;
      String? candidateBodyId;
      String? candidateWardId;

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        candidateDistrictId = indexData['districtId'];
        candidateBodyId = indexData['bodyId'];
        candidateWardId = indexData['wardId'];
        debugPrint(
          '🎯 Using indexed location for follow: $candidateDistrictId/$candidateBodyId/$candidateWardId',
        );
      } else {
        // Fallback: Optimized brute force search
        debugPrint(
          '🔄 Index not found, using optimized brute force search for follow',
        );
        final districtsSnapshot = await _firestore
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
                candidateDistrictId = districtDoc.id;
                candidateBodyId = bodyDoc.id;
                candidateWardId = wardDoc.id;

                // Update index for future queries
                await _updateCandidateIndex(
                  candidateId,
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
      }

      final batch = _firestore.batch();

      if (candidateDistrictId != null &&
          candidateBodyId != null &&
          candidateWardId != null) {
        // Found in new structure - use new structure paths
        // Add to candidate's followers subcollection
        final candidateFollowersRef = _firestore
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
            .collection('districts')
            .doc(candidateDistrictId)
            .collection('bodies')
            .doc(candidateBodyId)
            .collection('wards')
            .doc(candidateWardId)
            .collection('candidates')
            .doc(candidateId);

        batch.update(candidateRef, {'followersCount': FieldValue.increment(1)});
      } else {
        // Candidate not in new structure - followers functionality may not be available
        debugPrint('⚠️ Candidate not found in new structure for follow - followers may not be updated');
      }

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
      invalidateCache(
        'candidates_${candidateDistrictId}_${candidateBodyId}_$candidateWardId',
      );
    } catch (e) {
      throw Exception('Failed to follow candidate: $e');
    }
  }

  // Unfollow a candidate
  Future<void> unfollowCandidate(String userId, String candidateId) async {
    try {
      // First find the candidate's location in the new district/body/ward structure
      final districtsSnapshot = await _firestore.collection('districts').get();
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

      final batch = _firestore.batch();

      if (candidateDistrictId != null &&
          candidateBodyId != null &&
          candidateWardId != null) {
        // Found in new structure - use new structure paths
        // Remove from candidate's followers subcollection
        final candidateFollowersRef = _firestore
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
            .collection('districts')
            .doc(candidateDistrictId)
            .collection('bodies')
            .doc(candidateBodyId)
            .collection('wards')
            .doc(candidateWardId)
            .collection('candidates')
            .doc(candidateId);

        batch.update(candidateRef, {'followersCount': FieldValue.increment(-1)});
      } else {
        // Candidate not in new structure, might be in legacy - but followers are handled differently
        debugPrint('⚠️ Candidate not found in new structure for unfollow - followers may not be updated');
      }

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
      // First find the candidate's location in the new district/body/ward structure
      final districtsSnapshot = await _firestore.collection('districts').get();
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

  // Get candidate data by candidateId (not userId) - Optimized version
  Future<Candidate?> getCandidateDataById(String candidateId) async {
    try {
      debugPrint(
        '🔍 Candidate Repository: Searching for candidate data by candidateId: $candidateId',
      );

      // First, try to get location metadata from candidate index (if exists)
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final districtId = indexData['districtId'];
        final bodyId = indexData['bodyId'];
        final wardId = indexData['wardId'];

        debugPrint('🎯 Found location metadata: $districtId/$bodyId/$wardId');

        // Direct query using location metadata
        final candidateDoc = await _firestore
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

          debugPrint(
            '✅ Found candidate: ${candidateData['name']} (ID: ${candidateDoc.id})',
          );
          return Candidate.fromJson(candidateData);
        }
      }

      // Fallback: Optimized brute force search with early termination
      debugPrint('🔄 Index not found, using optimized brute force search');
      final districtsSnapshot = await _firestore.collection('districts').get();

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
                districtDoc.id,
                bodyDoc.id,
                wardDoc.id,
              );

              debugPrint(
                '✅ Found candidate: ${candidateData['name']} (ID: ${candidateDoc.id}) in ${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}',
              );
              return Candidate.fromJson(candidateData);
            }
          }
        }
      }

      debugPrint('❌ No candidate found with candidateId: $candidateId');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching candidate data by ID: $e');
      throw Exception('Failed to fetch candidate data: $e');
    }
  }

  // Update candidate index for faster lookups
  Future<void> _updateCandidateIndex(
    String candidateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      await _firestore.collection('candidate_index').doc(candidateId).set({
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
        debugPrint('📝 Creating user document for $userId');
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
          debugPrint(
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
      debugPrint('❌ Error ensuring user document exists: $e');
      // Don't throw here as this is a non-critical operation
    }
  }

  // Provisional Candidate Management Methods

  // Create a new candidate (self-registration)
  Future<String> createCandidate(Candidate candidate) async {
    try {
      debugPrint('🏗️ Creating candidate: ${candidate.name}');
      debugPrint('   District: ${candidate.districtId}');
      debugPrint('   Body: ${candidate.bodyId}');
      debugPrint('   Ward: ${candidate.wardId}');
      debugPrint('   UserId: ${candidate.userId}');

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
                .collection('districts')
                .doc(candidate.districtId)
                .collection('bodies')
                .doc(candidate.bodyId)
                .collection('wards')
                .doc(candidate.wardId)
                .collection('candidates')
                .doc(candidate.candidateId)
          : _firestore
                .collection('districts')
                .doc(candidate.districtId)
                .collection('bodies')
                .doc(candidate.bodyId)
                .collection('wards')
                .doc(candidate.wardId)
                .collection('candidates')
                .doc();

      debugPrint('📝 Creating candidate at path: districts/${candidate.districtId}/bodies/${candidate.bodyId}/wards/${candidate.wardId}/candidates/${docRef.id}');

      await docRef.set(optimizedData);
      debugPrint('✅ Candidate document created successfully with ID: ${docRef.id}');

      // Update candidate index for faster lookups
      await _updateCandidateIndex(
        docRef.id,
        candidate.districtId,
        candidate.bodyId,
        candidate.wardId,
      );

      // Invalidate relevant caches
      invalidateCache(
        'candidates_${candidate.districtId}_${candidate.bodyId}_${candidate.wardId}',
      );

      // Return the actual document ID (in case it was auto-generated)
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create candidate: $e');
      throw Exception('Failed to create candidate: $e');
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

  // Get all pending approval candidates across all cities and wards
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      final citiesSnapshot = await _firestore.collection('cities').get();
      List<Map<String, dynamic>> pendingCandidates = [];

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('approved', isEqualTo: false)
              .get();

          for (var candidateDoc in candidatesSnapshot.docs) {
            final data = candidateDoc.data();
            final candidateData = Map<String, dynamic>.from(data);
            candidateData['candidateId'] = candidateDoc.id;
            candidateData['cityId'] = cityDoc.id;
            candidateData['wardId'] = wardDoc.id;
            pendingCandidates.add(candidateData);
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
        final districtId = userData['districtId'];
        final bodyId = userData['bodyId'];
        final wardId = userData['wardId'];

        // If user has location info, check directly in that ward
        if (districtId != null &&
            bodyId != null &&
            wardId != null &&
            districtId.isNotEmpty &&
            bodyId.isNotEmpty &&
            wardId.isNotEmpty) {
          final candidateSnapshot = await _firestore
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
      final districtsSnapshot = await _firestore.collection('districts').get();

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

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(
    String userId,
    String candidateId,
    bool notificationsEnabled,
  ) async {
    try {
      // First find the candidate's location in the new district/body/ward structure
      final districtsSnapshot = await _firestore.collection('districts').get();
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

  // Debug method: Log all candidates across the entire system
  Future<void> logAllCandidatesInSystem() async {
    try {
      debugPrint('🔍 ===== SYSTEM CANDIDATE AUDIT =====');
      debugPrint('🔍 Scanning all cities, wards, and candidates...');

      final citiesSnapshot = await _firestore.collection('cities').get();
      debugPrint('📊 Total cities in system: ${citiesSnapshot.docs.length}');

      int totalCandidates = 0;
      int totalWards = 0;

      for (var cityDoc in citiesSnapshot.docs) {
        debugPrint('🏙️ ===== CITY: ${cityDoc.id} =====');
        final cityData = cityDoc.data();
        debugPrint('   Name: ${cityData['name'] ?? 'Unknown'}');
        debugPrint('   State: ${cityData['state'] ?? 'Unknown'}');

        final wardsSnapshot = await cityDoc.reference.collection('wards').get();
        debugPrint('📊 Wards in ${cityDoc.id}: ${wardsSnapshot.docs.length}');
        totalWards += wardsSnapshot.docs.length;

        for (var wardDoc in wardsSnapshot.docs) {
          debugPrint('🏛️ ===== WARD: ${wardDoc.id} in ${cityDoc.id} =====');
          final wardData = wardDoc.data();
          debugPrint('   Name: ${wardData['name'] ?? 'Unknown'}');
          debugPrint('   Population: ${wardData['population'] ?? 'Unknown'}');

          final candidatesSnapshot = await wardDoc.reference
              .collection('candidates')
              .get();
          debugPrint(
            '👥 Candidates in ${cityDoc.id}/${wardDoc.id}: ${candidatesSnapshot.docs.length}',
          );
          totalCandidates += candidatesSnapshot.docs.length;

          for (var candidateDoc in candidatesSnapshot.docs) {
            final candidateData = candidateDoc.data();
            debugPrint('👤 ===== CANDIDATE =====');
            debugPrint('   ID: ${candidateDoc.id}');
            debugPrint('   Name: ${candidateData['name'] ?? 'Unknown'}');
            debugPrint('   Party: ${candidateData['party'] ?? 'Unknown'}');
            debugPrint('   UserId: ${candidateData['userId'] ?? 'Unknown'}');
            debugPrint('   Approved: ${candidateData['approved'] ?? false}');
            debugPrint('   Status: ${candidateData['status'] ?? 'unknown'}');
            debugPrint('   Followers: ${candidateData['followersCount'] ?? 0}');
            debugPrint('   Symbol: ${candidateData['symbol'] ?? 'Unknown'}');

            // Log extra info if available
            final extraInfo =
                candidateData['extra_info'] as Map<String, dynamic>?;
            if (extraInfo != null) {
              debugPrint('   📋 Extra Info:');
              debugPrint('      Bio: ${extraInfo['bio'] ?? 'Not set'}');
              debugPrint(
                '      Education: ${extraInfo['education'] ?? 'Not set'}',
              );
              debugPrint('      Age: ${extraInfo['age'] ?? 'Not set'}');
              debugPrint('      Gender: ${extraInfo['gender'] ?? 'Not set'}');
            }

            debugPrint('   ====================');
          }

          if (candidatesSnapshot.docs.isEmpty) {
            debugPrint('⚠️ No candidates found in ${cityDoc.id}/${wardDoc.id}');
          }
        }

        debugPrint('🏙️ ===== END CITY: ${cityDoc.id} =====');
      }

      debugPrint('🔍 ===== SYSTEM AUDIT SUMMARY =====');
      debugPrint('📊 Total Cities: ${citiesSnapshot.docs.length}');
      debugPrint('📊 Total Wards: $totalWards');
      debugPrint('👥 Total Candidates: $totalCandidates');
      debugPrint('✅ Audit completed successfully');
    } catch (e) {
      debugPrint('❌ Error during system audit: $e');
    }
  }
}
