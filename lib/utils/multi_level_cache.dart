import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Multi-level caching system with memory, disk, and remote layers
class MultiLevelCache {
  static final MultiLevelCache _instance = MultiLevelCache._internal();
  factory MultiLevelCache() => _instance;

  MultiLevelCache._internal() {
    _initialize();
  }

  final MemoryCache _memoryCache = MemoryCache();
  final DiskCache _diskCache = DiskCache();
  final RemoteCache _remoteCache = RemoteCache();
  final StreamController<CacheEvent> _eventController =
      StreamController<CacheEvent>.broadcast();

  Stream<CacheEvent> get eventStream => _eventController.stream;

  void _initialize() {
    _log(
      '🏗️ MultiLevelCache initialized with 3 layers: Memory → Disk → Remote',
    );
  }

  /// Get data from cache hierarchy
  Future<T?> get<T>(String key) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer('cache_get_$key');

    try {
      // Layer 1: Memory cache (fastest)
      T? value = _memoryCache.get<T>(key);
      if (value != null) {
        _emitEvent(CacheEvent.hit(key, CacheLayer.memory, value));
        monitor.stopTimer('cache_get_$key');
        _log('✅ Memory cache hit for key: $key');
        return value;
      }

      // Layer 2: Disk cache
      value = await _diskCache.get<T>(key);
      if (value != null) {
        // Validate the retrieved value
        if (_isValidCacheValue(value)) {
          // Promote to memory cache
          _memoryCache.set<T>(key, value);
          _emitEvent(CacheEvent.hit(key, CacheLayer.disk, value));
          monitor.stopTimer('cache_get_$key');
          _log('💾 Disk cache hit for key: $key (promoted to memory)');
          return value;
        } else {
          // Corrupted value, remove from cache
          _log('🚨 Corrupted disk cache value for key: $key - removing');
          await _diskCache.remove(key);
        }
      }

      // Layer 3: Remote cache (slowest)
      value = await _remoteCache.get<T>(key);
      if (value != null) {
        // Validate before promoting
        if (_isValidCacheValue(value)) {
          // Promote to higher caches
          _memoryCache.set<T>(key, value);
          await _diskCache.set<T>(key, value);
          _emitEvent(CacheEvent.hit(key, CacheLayer.remote, value));
          monitor.stopTimer('cache_get_$key');
          _log('🌐 Remote cache hit for key: $key (promoted to memory + disk)');
          return value;
        }
      }
    } catch (e, stackTrace) {
      _log('💥 Cache error for key $key: $e\n$stackTrace');
      // Try to clean up corrupted data
      try {
        await remove(key);
      } catch (cleanupError) {
        _log('⚠️ Failed to cleanup corrupted cache key $key: $cleanupError');
      }
    }

    // Cache miss
    _emitEvent(CacheEvent.miss(key));
    monitor.stopTimer('cache_get_$key');
    _log('❌ Cache miss for key: $key');
    return null;
  }

  /// Validate cache value integrity
  bool _isValidCacheValue(dynamic value) {
    if (value == null) return false;

    try {
      // Check if it's a map with expected structure for user data
      if (value is Map<String, dynamic>) {
        // Validate UserModel structure
        if (value.containsKey('user')) {
          final userMap = value['user'];
          if (userMap is Map<String, dynamic>) {
            // Check required UserModel fields
            final requiredFields = ['uid', 'name', 'role'];
            for (final field in requiredFields) {
              if (!userMap.containsKey(field) || userMap[field] == null) {
                _log('🚨 Invalid UserModel cache: missing field $field');
                return false;
              }
            }
            return true;
          }
        }
        // Validate simple values
        if (value.containsKey('candidate') || value.containsKey('data')) {
          return true;
        }
      }

      // For other types, basic null check
      return true;
    } catch (e) {
      _log('🚨 Cache validation error: $e');
      return false;
    }
  }

  /// Get user routing data with instant fallback
  Future<Map<String, dynamic>?> getUserRoutingData(String userId) async {
    final cacheKey = 'user_routing_$userId';

    // Try memory cache first (instant)
    final memoryValue = _memoryCache.get<Map<String, dynamic>>(cacheKey);
    if (memoryValue != null) {
      _log('⚡ Instant memory cache hit for user routing: $userId');
      return memoryValue;
    }

    // Try disk cache (fast)
    final diskValue = await _diskCache.get<Map<String, dynamic>>(cacheKey);
    if (diskValue != null) {
      // Promote to memory
      _memoryCache.set<Map<String, dynamic>>(cacheKey, diskValue);
      _log('💾 Fast disk cache hit for user routing: $userId');
      return diskValue;
    }

    _log('❌ No cached routing data for user: $userId');
    return null;
  }

  /// Set user routing data with high priority
  Future<void> setUserRoutingData(String userId, Map<String, dynamic> routingData) async {
    final cacheKey = 'user_routing_$userId';

    // Set with high priority for instant access
    await set<Map<String, dynamic>>(
      cacheKey,
      routingData,
      priority: CachePriority.high,
      ttl: const Duration(hours: 1), // Cache for 1 hour
    );

    _log('💾 Cached user routing data for: $userId');
  }

  /// Set data in all cache layers with validation
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
  }) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer('cache_set_$key');

    try {
      // Validate value before caching
      if (!_isValidCacheValue(value)) {
        _log('🚨 Invalid value for key: $key - cannot cache');
        return;
      }

      // Set in all layers
      _memoryCache.set<T>(key, value, ttl: ttl, priority: priority);
      await _diskCache.set<T>(key, value, ttl: ttl, priority: priority);
      await _remoteCache.set<T>(key, value, ttl: ttl, priority: priority);

      _emitEvent(CacheEvent.set(key, value, priority));
      monitor.stopTimer('cache_set_$key');

      _log(
        '💾 Set value for key: $key in all cache layers (priority: $priority)',
      );
    } catch (e, stackTrace) {
      _log('💥 Cache set error for key $key: $e\n$stackTrace');
      // Don't rethrow - cache failures shouldn't break app
    }
  }

  /// Remove from all cache layers
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _diskCache.remove(key);
    await _remoteCache.remove(key);

    _emitEvent(CacheEvent.remove(key));
    _log('🗑️ Removed key: $key from all cache layers');
  }

  /// Clear all cache layers
  Future<void> clear() async {
    _memoryCache.clear();
    await _diskCache.clear();
    await _remoteCache.clear();

    _emitEvent(CacheEvent.clear());
    _log('🧹 Cleared all cache layers');
  }

  /// Warm up cache with frequently accessed data
  Future<void> warmup(List<String> keys) async {
    _log('🔥 Warming up cache with ${keys.length} keys');

    final monitor = PerformanceMonitor();
    monitor.startTimer('cache_warmup');

    for (final key in keys) {
      final value = await get(key);
      if (value != null) {
        _log('🔥 Warmed up key: $key');
      }
    }

    monitor.stopTimer('cache_warmup');
    _emitEvent(CacheEvent.warmup(keys.length));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memory': _memoryCache.getStats(),
      'disk': _diskCache.getStats(),
      'remote': _remoteCache.getStats(),
      'overall': {
        'total_requests':
            (_memoryCache.getStats()['total_requests'] +
            _diskCache.getStats()['total_requests'] +
            _remoteCache.getStats()['total_requests']),
        'hit_rate': _calculateOverallHitRate(),
        'average_response_time': _calculateAverageResponseTime(),
      },
    };
  }

  /// Prefetch data based on access patterns
  Future<void> prefetch(
    List<String> keys, {
    CachePriority priority = CachePriority.low,
  }) async {
    _log('🔮 Prefetching ${keys.length} keys');

    for (final key in keys) {
      final value = await _remoteCache.get(key);
      if (value != null) {
        // Store in memory and disk only (not remote again)
        _memoryCache.set(key, value, priority: priority);
        await _diskCache.set(key, value, priority: priority);
        _log('🔮 Prefetched key: $key');
      }
    }

    _emitEvent(CacheEvent.prefetch(keys.length));
  }

  double _calculateOverallHitRate() {
    final memoryStats = _memoryCache.getStats();
    final diskStats = _diskCache.getStats();
    final remoteStats = _remoteCache.getStats();

    final totalHits =
        (memoryStats['hits'] + diskStats['hits'] + remoteStats['hits']) as int;
    final totalRequests =
        (memoryStats['total_requests'] +
                diskStats['total_requests'] +
                remoteStats['total_requests'])
            as int;

    return totalRequests > 0 ? totalHits / totalRequests : 0.0;
  }

  double _calculateAverageResponseTime() {
    final memoryStats = _memoryCache.getStats();
    final diskStats = _diskCache.getStats();
    final remoteStats = _remoteCache.getStats();

    final totalTime =
        (memoryStats['average_response_time'] * memoryStats['total_requests'] +
        diskStats['average_response_time'] * diskStats['total_requests'] +
        remoteStats['average_response_time'] * remoteStats['total_requests']);

    final totalRequests =
        memoryStats['total_requests'] +
        diskStats['total_requests'] +
        remoteStats['total_requests'];

    return totalRequests > 0 ? totalTime / totalRequests : 0.0;
  }

  void _emitEvent(CacheEvent event) {
    _eventController.add(event);
  }

  void _log(String message) {
    if (kDebugMode) {
      AppLogger.common('🏗️ MULTI_CACHE: $message');
    }
  }

  void dispose() {
    _eventController.close();
    _memoryCache.dispose();
    _diskCache.dispose();
    _remoteCache.dispose();
  }
}

/// Memory cache implementation
class MemoryCache {
  final Map<String, CacheEntry> _cache = {};
  final Map<CachePriority, LinkedHashMap<String, String>> _priorityQueues = {
    CachePriority.high: LinkedHashMap<String, String>(),
    CachePriority.normal: LinkedHashMap<String, String>(),
    CachePriority.low: LinkedHashMap<String, String>(),
  };

  int _hits = 0;
  int _misses = 0;
  final List<Duration> _responseTimes = [];

  T? get<T>(String key) {
    final startTime = DateTime.now();
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      _hits++;
      _responseTimes.add(DateTime.now().difference(startTime));
      return entry.value as T;
    }

    _misses++;
    _responseTimes.add(DateTime.now().difference(startTime));
    return null;
  }

  void set<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
  }) {
    final entry = CacheEntry(
      value: value,
      expiryTime: ttl != null ? DateTime.now().add(ttl) : null,
      priority: priority,
    );

    _cache[key] = entry;
    _priorityQueues[priority]![key] = key;

    // Evict low priority items if cache is full
    _evictIfNeeded();
  }

  void remove(String key) {
    _cache.remove(key);
    for (final queue in _priorityQueues.values) {
      queue.remove(key);
    }
  }

  void clear() {
    _cache.clear();
    for (final queue in _priorityQueues.values) {
      queue.clear();
    }
  }

  void _evictIfNeeded() {
    // Simple LRU eviction for low priority items
    const maxSize = 1000;
    if (_cache.length <= maxSize) return;

    final lowPriorityQueue = _priorityQueues[CachePriority.low]!;
    if (lowPriorityQueue.isNotEmpty) {
      final keyToRemove = lowPriorityQueue.keys.first;
      remove(keyToRemove);
    }
  }

  Map<String, dynamic> getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? _hits / totalRequests : 0.0;
    final avgResponseTime = _responseTimes.isNotEmpty
        ? _responseTimes.fold<Duration>(Duration.zero, (a, b) => a + b) ~/
              _responseTimes.length
        : Duration.zero;

    return {
      'size': _cache.length,
      'hits': _hits,
      'misses': _misses,
      'hit_rate': hitRate,
      'total_requests': totalRequests,
      'average_response_time': avgResponseTime.inMicroseconds,
      'priority_distribution': {
        CachePriority.high: _priorityQueues[CachePriority.high]!.length,
        CachePriority.normal: _priorityQueues[CachePriority.normal]!.length,
        CachePriority.low: _priorityQueues[CachePriority.low]!.length,
      },
    };
  }

  void dispose() {
    clear();
  }
}

/// Disk cache implementation
class DiskCache {
  SharedPreferences? _prefs;
  Directory? _cacheDir;
  final Map<String, CacheEntry> _metadata = {};

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
    _cacheDir ??= await getApplicationCacheDirectory();
    await _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    if (_prefs == null) return;
    final metadataJson = _prefs!.getString('disk_cache_metadata');
    if (metadataJson != null) {
      try {
        final metadataMap = jsonDecode(metadataJson) as Map<String, dynamic>;
        _metadata.clear();
        metadataMap.forEach((key, value) {
          final entryMap = value as Map<String, dynamic>;
          _metadata[key] = CacheEntry(
            value: null, // We'll load from file when needed
            expiryTime: entryMap['expiryTime'] != null
                ? DateTime.parse(entryMap['expiryTime'])
                : null,
            priority: CachePriority.values[entryMap['priority'] ?? 1],
          );
        });
      } catch (e) {
        AppLogger.error('Error loading disk cache metadata: $e');
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_prefs == null) return;
    final metadataMap = <String, dynamic>{};
    _metadata.forEach((key, entry) {
      metadataMap[key] = {
        'expiryTime': entry.expiryTime?.toIso8601String(),
        'priority': entry.priority.index,
      };
    });
    await _prefs!.setString('disk_cache_metadata', jsonEncode(metadataMap));
  }

  Future<T?> get<T>(String key) async {
    await _ensureInitialized();

    final metadata = _metadata[key];
    if (metadata != null && !metadata.isExpired) {
      final file = File('${_cacheDir!.path}/$key');
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          return data as T;
        } catch (e) {
          // File corrupted, remove it
          await file.delete();
          _metadata.remove(key);
        }
      }
    }

    return null;
  }

  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
  }) async {
    await _ensureInitialized();

    final entry = CacheEntry(
      value: value,
      expiryTime: ttl != null ? DateTime.now().add(ttl) : null,
      priority: priority,
    );

    _metadata[key] = entry;

    final file = File('${_cacheDir!.path}/$key');
    final content = jsonEncode(value);
    await file.writeAsString(content);

    await _saveMetadata();
  }

  Future<void> remove(String key) async {
    await _ensureInitialized();

    _metadata.remove(key);
    final file = File('${_cacheDir!.path}/$key');
    if (await file.exists()) {
      await file.delete();
    }
    await _saveMetadata();
  }

  Future<void> clear() async {
    await _ensureInitialized();

    _metadata.clear();
    if (_cacheDir != null) {
      final files = _cacheDir!.listSync();
      for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    }
    await _saveMetadata();
  }

  Map<String, dynamic> getStats() {
    return {'size': _metadata.length, 'cache_directory': _cacheDir?.path};
  }

  void dispose() {
    // Disk cache doesn't need explicit disposal
  }
}

/// Remote cache implementation (placeholder for distributed cache)
class RemoteCache {
  final Map<String, CacheEntry> _cache = {};

  Future<T?> get<T>(String key) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      return entry.value as T;
    }

    return null;
  }

  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    CachePriority priority = CachePriority.normal,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 50));

    final entry = CacheEntry(
      value: value,
      expiryTime: ttl != null ? DateTime.now().add(ttl) : null,
      priority: priority,
    );

    _cache[key] = entry;
  }

  Future<void> remove(String key) async {
    await Future.delayed(const Duration(milliseconds: 25));
    _cache.remove(key);
  }

  Future<void> clear() async {
    await Future.delayed(const Duration(milliseconds: 25));
    _cache.clear();
  }

  Map<String, dynamic> getStats() {
    return {'size': _cache.length};
  }

  void dispose() {
    // Remote cache doesn't need explicit disposal
  }
}

/// Cache entry with metadata
class CacheEntry {
  final dynamic value;
  final DateTime? expiryTime;
  final CachePriority priority;
  final DateTime createdAt;

  CacheEntry({
    required this.value,
    this.expiryTime,
    this.priority = CachePriority.normal,
  }) : createdAt = DateTime.now();

  bool get isExpired {
    return expiryTime != null && DateTime.now().isAfter(expiryTime!);
  }

  Duration get age => DateTime.now().difference(createdAt);
}

/// Cache priority levels
enum CachePriority { high, normal, low }

/// Cache layers
enum CacheLayer { memory, disk, remote }

/// Cache event types
enum CacheEventType { hit, miss, set, remove, clear, warmup, prefetch }

/// Cache event for monitoring
class CacheEvent {
  final String key;
  final CacheEventType type;
  final CacheLayer? layer;
  final dynamic value;
  final CachePriority? priority;
  final int? count;
  final DateTime timestamp;

  CacheEvent._({
    required this.key,
    required this.type,
    this.layer,
    this.value,
    this.priority,
    this.count,
  }) : timestamp = DateTime.now();

  factory CacheEvent.hit(String key, CacheLayer layer, dynamic value) {
    return CacheEvent._(
      key: key,
      type: CacheEventType.hit,
      layer: layer,
      value: value,
    );
  }

  factory CacheEvent.miss(String key) {
    return CacheEvent._(key: key, type: CacheEventType.miss);
  }

  factory CacheEvent.set(String key, dynamic value, CachePriority priority) {
    return CacheEvent._(
      key: key,
      type: CacheEventType.set,
      value: value,
      priority: priority,
    );
  }

  factory CacheEvent.remove(String key) {
    return CacheEvent._(key: key, type: CacheEventType.remove);
  }

  factory CacheEvent.clear() {
    return CacheEvent._(key: '', type: CacheEventType.clear);
  }

  factory CacheEvent.warmup(int count) {
    return CacheEvent._(key: '', type: CacheEventType.warmup, count: count);
  }

  factory CacheEvent.prefetch(int count) {
    return CacheEvent._(key: '', type: CacheEventType.prefetch, count: count);
  }

  @override
  String toString() {
    return 'CacheEvent(type: $type, key: $key, layer: $layer, priority: $priority)';
  }
}

/// Cache warming strategies
class CacheWarmingStrategies {
  final MultiLevelCache _cache;

  CacheWarmingStrategies(this._cache);

  /// Warm up based on user behavior patterns
  Future<void> warmupUserPatterns(String userId) async {
    // This would analyze user behavior and warm up relevant data
    final keys = await _predictUserAccessPattern(userId);
    await _cache.warmup(keys);
  }

  /// Warm up based on time-based patterns
  Future<void> warmupTimeBased() async {
    final hour = DateTime.now().hour;
    final keys = await _predictTimeBasedAccess(hour);
    await _cache.warmup(keys);
  }

  /// Warm up based on popularity
  Future<void> warmupPopularData() async {
    final keys = await _getPopularKeys();
    await _cache.warmup(keys);
  }

  Future<List<String>> _predictUserAccessPattern(String userId) async {
    // Placeholder for ML-based prediction
    return ['user_$userId', 'profile_$userId', 'feed_$userId'];
  }

  Future<List<String>> _predictTimeBasedAccess(int hour) async {
    // Predict based on time of day
    if (hour >= 9 && hour <= 17) {
      return ['work_data', 'recent_updates'];
    } else {
      return ['entertainment', 'social_feed'];
    }
  }

  Future<List<String>> _getPopularKeys() async {
    // Get most accessed keys from analytics
    return ['popular_1', 'popular_2', 'popular_3'];
  }
}

/// Cache performance monitor
class CachePerformanceMonitor {
  final MultiLevelCache _cache;
  final StreamController<CacheMetrics> _metricsController =
      StreamController<CacheMetrics>.broadcast();

  Stream<CacheMetrics> get metricsStream => _metricsController.stream;

  CachePerformanceMonitor(this._cache) {
    _startMonitoring();
  }

  void _startMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final stats = _cache.getStats();
      final metrics = CacheMetrics.fromStats(stats);
      _metricsController.add(metrics);
    });
  }

  void dispose() {
    _metricsController.close();
  }
}

/// Cache metrics for monitoring
class CacheMetrics {
  final double overallHitRate;
  final double memoryHitRate;
  final double diskHitRate;
  final double remoteHitRate;
  final Duration averageResponseTime;
  final int totalRequests;
  final Map<String, int> layerDistribution;

  CacheMetrics({
    required this.overallHitRate,
    required this.memoryHitRate,
    required this.diskHitRate,
    required this.remoteHitRate,
    required this.averageResponseTime,
    required this.totalRequests,
    required this.layerDistribution,
  });

  factory CacheMetrics.fromStats(Map<String, dynamic> stats) {
    final memory = stats['memory'] as Map<String, dynamic>;
    final disk = stats['disk'] as Map<String, dynamic>;
    final remote = stats['remote'] as Map<String, dynamic>;
    final overall = stats['overall'] as Map<String, dynamic>;

    return CacheMetrics(
      overallHitRate: overall['hit_rate'] ?? 0.0,
      memoryHitRate: memory['hit_rate'] ?? 0.0,
      diskHitRate: disk['hit_rate'] ?? 0.0,
      remoteHitRate: remote['hit_rate'] ?? 0.0,
      averageResponseTime: Duration(
        microseconds: (overall['average_response_time'] ?? 0).toInt(),
      ),
      totalRequests: overall['total_requests'] ?? 0,
      layerDistribution: {
        'memory': memory['size'] ?? 0,
        'disk': disk['size'] ?? 0,
        'remote': remote['size'] ?? 0,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_hit_rate': overallHitRate,
      'memory_hit_rate': memoryHitRate,
      'disk_hit_rate': diskHitRate,
      'remote_hit_rate': remoteHitRate,
      'average_response_time_ms': averageResponseTime.inMilliseconds,
      'total_requests': totalRequests,
      'layer_distribution': layerDistribution,
    };
  }
}

/// Performance monitor integration
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal();

  final Map<String, DateTime> _timers = {};

  void startTimer(String operation) {
    _timers[operation] = DateTime.now();
  }

  void stopTimer(String operation) {
    final startTime = _timers.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        AppLogger.common('⏱️ $operation took ${duration.inMilliseconds}ms');
      }
    }
  }
}
