import 'dart:async';
import 'dart:collection';
import 'app_logger.dart';

/// Memory management and cleanup system
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;

  MemoryManager._internal() {
    _initialize();
  }

  final Map<String, WeakReference<Object>> _objectCache = {};
  final Map<String, DateTime> _lastAccessed = {};
  final Map<String, int> _accessFrequency = {};
  final Map<String, ObjectMetadata> _objectMetadata = {};
  final Duration _cleanupInterval = const Duration(minutes: 5);
  final int _maxCacheSize = 1000; // Maximum number of cached objects
  Timer? _cleanupTimer;

  void _initialize() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _performCleanup());
    _log(
      '🧠 MemoryManager initialized with cleanup interval: $_cleanupInterval',
    );
  }

  /// Register an object for memory management
  void registerObject<T>(
    String key,
    T object, {
    Duration? ttl,
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    _objectCache[key] = WeakReference<Object>(object as Object);
    _lastAccessed[key] = DateTime.now();
    _accessFrequency[key] = (_accessFrequency[key] ?? 0) + 1;

    _objectMetadata[key] = ObjectMetadata(
      type: T.toString(),
      category: category,
      ttl: ttl,
      metadata: metadata,
      registeredAt: DateTime.now(),
    );

    _log('📝 Registered object: $key (${T.toString()})');

    // Check if we need to cleanup due to size limits
    if (_objectCache.length > _maxCacheSize) {
      _performCleanup();
    }
  }

  /// Get cached object with access tracking
  T? getCachedObject<T>(String key) {
    final ref = _objectCache[key];
    if (ref != null && ref.target != null) {
      _lastAccessed[key] = DateTime.now();
      _accessFrequency[key] = (_accessFrequency[key] ?? 0) + 1;

      final metadata = _objectMetadata[key];
      if (metadata != null) {
        metadata.accessCount++;
        metadata.lastAccessed = DateTime.now();
      }

      _log('✅ Retrieved cached object: $key (${T.toString()})');
      return ref.target as T;
    }

    _log('❌ Cached object not found or garbage collected: $key');
    return null;
  }

  /// Update cached object
  void updateCachedObject<T>(String key, T newObject) {
    final oldRef = _objectCache[key];
    _objectCache[key] = WeakReference<Object>(newObject as Object);
    _lastAccessed[key] = DateTime.now();

    final metadata = _objectMetadata[key];
    if (metadata != null) {
      metadata.updateCount++;
      metadata.lastUpdated = DateTime.now();
    }

    _log('🔄 Updated cached object: $key (${T.toString()})');

    // Clean up old reference if it exists
    if (oldRef != null) {
      // The old object will be garbage collected automatically due to WeakReference
    }
  }

  /// Remove object from cache
  void removeObject(String key) {
    final removed = _objectCache.remove(key);
    _lastAccessed.remove(key);
    _accessFrequency.remove(key);
    _objectMetadata.remove(key);

    if (removed != null) {
      _log('🗑️ Removed cached object: $key');
    } else {
      _log('⚠️ Object not found for removal: $key');
    }
  }

  /// Clear all cached objects
  void clearCache() {
    final count = _objectCache.length;
    _objectCache.clear();
    _lastAccessed.clear();
    _accessFrequency.clear();
    _objectMetadata.clear();

    _log('🧹 Cleared all cached objects ($count objects removed)');
  }

  /// Clear objects by category
  void clearCategory(String category) {
    final keysToRemove = _objectMetadata.entries
        .where((entry) => entry.value.category == category)
        .map((entry) => entry.key)
        .toList();

    for (final key in keysToRemove) {
      removeObject(key);
    }

    _log(
      '🎯 Cleared category: $category (${keysToRemove.length} objects removed)',
    );
  }

  /// Get memory statistics
  Map<String, dynamic> getMemoryStats() {
    final now = DateTime.now();
    final totalObjects = _objectCache.length;
    final activeObjects = _objectCache.values
        .where((ref) => ref.target != null)
        .length;
    final garbageCollected = totalObjects - activeObjects;

    // Calculate average access frequency
    final totalAccesses = _accessFrequency.values.fold(
      0,
      (sum, freq) => sum + freq,
    );
    final avgAccessFrequency = totalObjects > 0
        ? totalAccesses / totalObjects
        : 0;

    // Calculate cache efficiency
    final categoryStats = _calculateCategoryStats();

    return {
      'total_objects': totalObjects,
      'active_objects': activeObjects,
      'garbage_collected': garbageCollected,
      'cache_efficiency':
          '${(activeObjects / totalObjects * 100).toStringAsFixed(1)}%',
      'average_access_frequency': avgAccessFrequency.toStringAsFixed(2),
      'total_accesses': totalAccesses,
      'category_stats': categoryStats,
      'oldest_object': _findOldestObject(),
      'newest_object': _findNewestObject(),
    };
  }

  Map<String, dynamic> _calculateCategoryStats() {
    final categoryMap = <String, Map<String, dynamic>>{};

    _objectMetadata.forEach((key, metadata) {
      final category = metadata.category ?? 'uncategorized';
      categoryMap[category] ??= {
        'count': 0,
        'active': 0,
        'total_accesses': 0,
        'avg_ttl_hours': 0,
      };

      categoryMap[category]!['count']++;
      if (_objectCache[key]?.target != null) {
        categoryMap[category]!['active']++;
      }
      categoryMap[category]!['total_accesses'] += _accessFrequency[key] ?? 0;

      if (metadata.ttl != null) {
        final ttlHours = metadata.ttl!.inHours;
        categoryMap[category]!['avg_ttl_hours'] =
            (categoryMap[category]!['avg_ttl_hours'] + ttlHours) / 2;
      }
    });

    return categoryMap;
  }

  String? _findOldestObject() {
    if (_lastAccessed.isEmpty) return null;

    final oldest = _lastAccessed.entries.reduce(
      (a, b) => a.value.isBefore(b.value) ? a : b,
    );
    return oldest.key;
  }

  String? _findNewestObject() {
    if (_lastAccessed.isEmpty) return null;

    final newest = _lastAccessed.entries.reduce(
      (a, b) => a.value.isAfter(b.value) ? a : b,
    );
    return newest.key;
  }

  /// Perform cleanup of expired and low-usage objects
  void _performCleanup() {
    final now = DateTime.now();
    final toRemove = <String>[];
    int expiredCount = 0;
    int lowUsageCount = 0;

    _log('🧹 Starting memory cleanup...');

    _objectMetadata.forEach((key, metadata) {
      // Check TTL expiration
      if (metadata.ttl != null) {
        final expirationTime = metadata.registeredAt.add(metadata.ttl!);
        if (now.isAfter(expirationTime)) {
          toRemove.add(key);
          expiredCount++;
          _log('⏰ TTL expired: $key');
          return;
        }
      }

      // Check if object is garbage collected
      if (_objectCache[key]?.target == null) {
        toRemove.add(key);
        _log('🗑️ Garbage collected: $key');
        return;
      }

      // Check low usage (accessed less than once per cleanup interval)
      final accessFreq = _accessFrequency[key] ?? 0;
      final age = now.difference(metadata.registeredAt).inMinutes;
      final expectedAccesses = age / _cleanupInterval.inMinutes;

      if (expectedAccesses > 1 && accessFreq < expectedAccesses * 0.1) {
        toRemove.add(key);
        lowUsageCount++;
        _log('📉 Low usage: $key (accessed $accessFreq times in ${age}min)');
      }
    });

    // Remove identified objects
    for (final key in toRemove) {
      removeObject(key);
    }

    _log(
      '✅ Cleanup completed: removed ${toRemove.length} objects '
      '(expired: $expiredCount, low usage: $lowUsageCount)',
    );
  }

  /// Force garbage collection hint (for debugging)
  void forceGC() {
    _log('🔧 Forcing garbage collection hint...');
    // In Dart, we can't force GC, but we can suggest it
    // This is mainly for debugging purposes
  }

  /// Get detailed object information
  Map<String, dynamic>? getObjectInfo(String key) {
    final metadata = _objectMetadata[key];
    final ref = _objectCache[key];

    if (metadata == null) return null;

    return {
      'key': key,
      'type': metadata.type,
      'category': metadata.category,
      'is_active': ref?.target != null,
      'registered_at': metadata.registeredAt.toIso8601String(),
      'last_accessed': _lastAccessed[key]?.toIso8601String(),
      'access_frequency': _accessFrequency[key] ?? 0,
      'ttl': metadata.ttl?.inMinutes,
      'access_count': metadata.accessCount,
      'update_count': metadata.updateCount,
      'last_updated': metadata.lastUpdated?.toIso8601String(),
      'metadata': metadata.metadata,
    };
  }

  /// Export memory report
  Map<String, dynamic> exportMemoryReport() {
    final stats = getMemoryStats();
    final objectDetails = <String, dynamic>{};

    _objectMetadata.forEach((key, metadata) {
      objectDetails[key] = getObjectInfo(key);
    });

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': stats,
      'objects': objectDetails,
      'recommendations': _generateMemoryRecommendations(stats),
    };
  }

  List<String> _generateMemoryRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];

    final efficiency =
        double.tryParse(
          stats['cache_efficiency'].toString().replaceAll('%', ''),
        ) ??
        0;

    if (efficiency < 70) {
      recommendations.add(
        'Cache efficiency is low (${stats['cache_efficiency']}). Consider increasing TTL or reducing cache size.',
      );
    }

    final activeObjects = stats['active_objects'] as int;
    if (activeObjects > _maxCacheSize * 0.8) {
      recommendations.add(
        'Cache is near capacity ($activeObjects/$_maxCacheSize). Consider increasing max cache size or implementing LRU eviction.',
      );
    }

    final avgFrequency =
        double.tryParse(stats['average_access_frequency']) ?? 0;
    if (avgFrequency < 1) {
      recommendations.add(
        'Low average access frequency (${avgFrequency.toStringAsFixed(2)}). Consider shorter TTL for cached objects.',
      );
    }

    return recommendations;
  }

  void dispose() {
    _cleanupTimer?.cancel();
    clearCache();
    _log('🗑️ MemoryManager disposed');
  }

  void _log(String message) {
    AppLogger.memoryManager(message);
  }
}

/// Object metadata for tracking
class ObjectMetadata {
  final String type;
  final String? category;
  final Duration? ttl;
  final Map<String, dynamic>? metadata;
  final DateTime registeredAt;
  DateTime? lastAccessed;
  DateTime? lastUpdated;
  int accessCount = 0;
  int updateCount = 0;

  ObjectMetadata({
    required this.type,
    this.category,
    this.ttl,
    this.metadata,
    required this.registeredAt,
  });
}

/// Smart cache with LRU eviction
class SmartCache<T> {
  final int _maxSize;
  final Map<String, T> _cache = {};
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();

  SmartCache({int maxSize = 100}) : _maxSize = maxSize;

  /// Get item from cache
  T? get(String key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      _accessOrder.remove(key);
      _accessOrder[key] = DateTime.now();
      return _cache[key];
    }
    return null;
  }

  /// Put item in cache
  void put(String key, T value) {
    if (_cache.containsKey(key)) {
      _cache[key] = value;
      _accessOrder.remove(key);
      _accessOrder[key] = DateTime.now();
    } else {
      if (_cache.length >= _maxSize) {
        // Remove least recently used
        final lruKey = _accessOrder.keys.first;
        _cache.remove(lruKey);
        _accessOrder.remove(lruKey);
      }
      _cache[key] = value;
      _accessOrder[key] = DateTime.now();
    }
  }

  /// Remove item from cache
  void remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Clear cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'max_size': _maxSize,
      'utilization': '${(_cache.length / _maxSize * 100).toStringAsFixed(1)}%',
      'oldest_access': _accessOrder.values.isNotEmpty
          ? _accessOrder.values.first
          : null,
      'newest_access': _accessOrder.values.isNotEmpty
          ? _accessOrder.values.last
          : null,
    };
  }
}

/// Memory pressure monitor
class MemoryPressureMonitor {
  static final MemoryPressureMonitor _instance =
      MemoryPressureMonitor._internal();
  factory MemoryPressureMonitor() => _instance;

  MemoryPressureMonitor._internal();

  final StreamController<MemoryPressureLevel> _pressureController =
      StreamController<MemoryPressureLevel>.broadcast();
  MemoryPressureLevel _currentLevel = MemoryPressureLevel.normal;

  Stream<MemoryPressureLevel> get pressureStream => _pressureController.stream;
  MemoryPressureLevel get currentLevel => _currentLevel;

  /// Monitor memory pressure and emit events
  void monitorPressure() {
    // In a real implementation, this would monitor actual memory usage
    // For now, we'll simulate based on cache size
    final memoryManager = MemoryManager();
    final stats = memoryManager.getMemoryStats();

    final utilization = stats['active_objects'] / (stats['total_objects'] + 1);
    MemoryPressureLevel newLevel;

    if (utilization > 0.9) {
      newLevel = MemoryPressureLevel.critical;
    } else if (utilization > 0.7) {
      newLevel = MemoryPressureLevel.high;
    } else if (utilization > 0.5) {
      newLevel = MemoryPressureLevel.medium;
    } else {
      newLevel = MemoryPressureLevel.normal;
    }

    if (newLevel != _currentLevel) {
      _currentLevel = newLevel;
      _pressureController.add(newLevel);

      AppLogger.memoryManager(
        '⚠️ Memory pressure changed to: $newLevel (${(utilization * 100).toStringAsFixed(1)}% utilization)',
      );
    }
  }

  /// Get memory pressure recommendations
  List<String> getRecommendations(MemoryPressureLevel level) {
    switch (level) {
      case MemoryPressureLevel.critical:
        return [
          'Critical memory pressure! Immediately clear unused caches.',
          'Reduce cache sizes and TTL values.',
          'Consider implementing more aggressive cleanup.',
        ];
      case MemoryPressureLevel.high:
        return [
          'High memory pressure. Clear low-priority caches.',
          'Reduce cache TTL for non-critical data.',
          'Monitor memory usage closely.',
        ];
      case MemoryPressureLevel.medium:
        return [
          'Medium memory pressure. Consider optimizing cache usage.',
          'Review and adjust cache sizes.',
        ];
      case MemoryPressureLevel.normal:
        return ['Memory usage is normal. No action required.'];
    }
  }
}

/// Memory pressure levels
enum MemoryPressureLevel { normal, medium, high, critical }

/// Resource pool for managing reusable objects
class ResourcePool<T> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final void Function(T)? _cleanup;
  final int _maxSize;

  ResourcePool(this._factory, {void Function(T)? cleanup, int maxSize = 10})
    : _cleanup = cleanup,
      _maxSize = maxSize;

  /// Get resource from pool
  T get() {
    T resource;
    if (_available.isNotEmpty) {
      resource = _available.removeLast();
    } else if (_inUse.length < _maxSize) {
      resource = _factory();
    } else {
      throw Exception('Resource pool exhausted (max size: $_maxSize)');
    }

    _inUse.add(resource);
    return resource;
  }

  /// Return resource to pool
  void release(T resource) {
    if (_inUse.remove(resource)) {
      if (_cleanup != null) {
        _cleanup(resource);
      }
      _available.add(resource);
    }
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    return {
      'available': _available.length,
      'in_use': _inUse.length,
      'total': _available.length + _inUse.length,
      'max_size': _maxSize,
      'utilization':
          '${((_inUse.length / _maxSize) * 100).toStringAsFixed(1)}%',
    };
  }

  /// Clear pool
  void clear() {
    _available.clear();
    _inUse.clear();
  }
}
