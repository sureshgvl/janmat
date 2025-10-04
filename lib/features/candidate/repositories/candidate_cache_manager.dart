import 'package:flutter/material.dart';
import '../models/candidate_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/body_model.dart';
import '../../../models/district_model.dart';
import '../../../utils/performance_monitor.dart' as perf_monitor;

class CandidateCacheManager {
  // Enhanced repository-level caching
  static final Map<String, List<Candidate>> _candidateCache = {};
  static final Map<String, List<Ward>> _wardCache = {};
  static final Map<String, List<Body>> _bodyCache = {};
  static final Map<String, List<District>> _districtCache = {};
  static final Map<String, List<String>> _followingCache = {};
  static final Map<String, Map<String, dynamic>> _queryResultCache = {}; // For complex query results
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 15); // Longer than controller cache
  static const Duration _queryCacheValidityDuration = Duration(minutes: 5); // Shorter for query results

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
    } else if (data is List<District>) {
      _districtCache[cacheKey] = List.from(data);
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

  List<District>? _getCachedDistricts(String cacheKey) {
    return _isCacheValid(cacheKey) ? _districtCache[cacheKey] : null;
  }

  List<String>? _getCachedFollowing(String cacheKey) {
    return _isCacheValid(cacheKey) ? _followingCache[cacheKey] : null;
  }

  // Invalidate cache for specific keys
  void invalidateCache(String cacheKey) {
    _candidateCache.remove(cacheKey);
    _wardCache.remove(cacheKey);
    _bodyCache.remove(cacheKey);
    _districtCache.remove(cacheKey);
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
    _districtCache.clear();
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
    debugPrint('🗑️ Invalidated ${keysToRemove.length} query cache entries matching: $pattern');
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
      _districtCache.remove(key);
      _followingCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  // Get enhanced cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalDataSize =
        _candidateCache.values
            .map((candidates) => candidates.length * 1024) // Rough estimate: 1KB per candidate
            .fold(0, (a, b) => a + b) +
        _wardCache.values
            .map((wards) => wards.length * 512) // Rough estimate: 0.5KB per ward
            .fold(0, (a, b) => a + b) +
        _bodyCache.values
            .map((bodies) => bodies.length * 256) // Rough estimate: 0.25KB per body
            .fold(0, (a, b) => a + b) +
        _districtCache.values
            .map((districts) => districts.length * 256) // Rough estimate: 0.25KB per district
            .fold(0, (a, b) => a + b) +
        _followingCache.values
            .map((following) => following.length * 64) // Rough estimate: 64B per following entry
            .fold(0, (a, b) => a + b) +
        _queryResultCache.values
            .map((result) => result.toString().length * 2) // Rough estimate: 2B per char
            .fold(0, (a, b) => a + b);

    return {
      'total_entries': _cacheTimestamps.length,
      'candidate_cache_size': _candidateCache.length,
      'ward_cache_size': _wardCache.length,
      'body_cache_size': _bodyCache.length,
      'district_cache_size': _districtCache.length,
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
    // Get cache statistics from PerformanceMonitor
    final summary = perf_monitor.PerformanceMonitor().getFirebaseSummary();
    final cacheHitRateStr = summary['cache_hit_rate'] as String;
    if (cacheHitRateStr == '0%') return 0.0;

    // Parse percentage string to double
    final percentage = double.tryParse(cacheHitRateStr.replaceAll('%', ''));
    return percentage != null ? percentage / 100.0 : 0.0;
  }

  // Public methods for other managers to use
  Map<String, dynamic>? getCachedQueryResult(String cacheKey) => _getCachedQueryResult(cacheKey);
  void cacheQueryResult(String cacheKey, Map<String, dynamic> result) => _cacheQueryResult(cacheKey, result);
  List<Candidate>? getCachedCandidates(String cacheKey) => _getCachedCandidates(cacheKey);
  List<Ward>? getCachedWards(String cacheKey) => _getCachedWards(cacheKey);
  List<District>? getCachedDistricts(String cacheKey) => _getCachedDistricts(cacheKey);
  List<String>? getCachedFollowing(String cacheKey) => _getCachedFollowing(cacheKey);
  void cacheData(String cacheKey, dynamic data) => _cacheData(cacheKey, data);
}

