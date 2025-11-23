import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../utils/app_logger.dart';

/// Configuration for media caching strategy
class MediaCacheConfig {
  final int maxCacheSizeMB;
  final int maxAgeDays;
  final Map<String, int> priorityMapping;
  final Duration cleanupInterval;

  const MediaCacheConfig({
    this.maxCacheSizeMB = 500,
    this.maxAgeDays = 7,
    this.cleanupInterval = const Duration(hours: 24),
  }) : priorityMapping = const {
          'thumbnail': 1,      // Lowest priority
          'profile': 2,        // Medium priority
          'achievement': 3,    // Higher priority
          'candidate': 4,      // High priority
          'upload': 5,         // Highest priority
        };
}

/// Represents a cached media item
class CachedMediaItem {
  final String url;
  final String localPath;
  final String mediaType;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;
  final int accessCount;
  final int fileSizeBytes;
  final String? metadata;

  CachedMediaItem({
    required this.url,
    required this.localPath,
    required this.mediaType,
    required this.cachedAt,
    required this.lastAccessedAt,
    required this.accessCount,
    required this.fileSizeBytes,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'localPath': localPath,
    'mediaType': mediaType,
    'cachedAt': cachedAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'accessCount': accessCount,
    'fileSizeBytes': fileSizeBytes,
    'metadata': metadata,
  };

  factory CachedMediaItem.fromJson(Map<String, dynamic> json) => CachedMediaItem(
    url: json['url'],
    localPath: json['localPath'],
    mediaType: json['mediaType'] ?? 'unknown',
    cachedAt: DateTime.parse(json['cachedAt']),
    lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
    accessCount: json['accessCount'] ?? 0,
    fileSizeBytes: json['fileSizeBytes'] ?? 0,
    metadata: json['metadata'],
  );

  double get fileSizeMB => fileSizeBytes / (1024 * 1024);
}

/// Advanced media cache service with priority-based eviction
class MediaCacheService {
  static MediaCacheService? _instance;
  static const String key = 'media_cache_manager';

  final MediaCacheConfig _config;
  final Map<String, CachedMediaItem> _cacheIndex = {};
  final List<String> _priorityQueue = []; // Simple priority queue

  // Statistics
  final StreamController<Map<String, dynamic>> _cacheStatsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _cleanupTimer;

  MediaCacheService._()
      : _config = const MediaCacheConfig();

  static Future<MediaCacheService> getInstance() async {
    if (_instance == null) {
      _instance = MediaCacheService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    AppLogger.common('🗃️ [MediaCache] Initializing media cache service...', tag: 'CACHE');

    try {
      await _loadCacheIndex();
      _startCleanupTimer();
      _startStatsReporting();
      AppLogger.common('✅ [MediaCache] Cache service initialized', tag: 'CACHE');
    } catch (e) {
      AppLogger.commonError('❌ [MediaCache] Initialization failed', error: e, tag: 'CACHE');
    }
  }

  Future<void> _loadCacheIndex() async {
    // Skip file system operations on web
    if (kIsWeb) {
      AppLogger.common('📱 WEB: [MediaCache] Skipping file system cache on web', tag: 'CACHE');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final indexFile = File(path.join(tempDir.path, 'media_cache_index.json'));

      if (await indexFile.exists()) {
        final jsonStr = await indexFile.readAsString();
        final Map<String, dynamic> indexData = json.decode(jsonStr);

        for (final entry in indexData.entries) {
          try {
            final item = CachedMediaItem.fromJson(entry.value);

            // Verify file still exists
            if (await File(item.localPath).exists()) {
              _cacheIndex[entry.key] = item;
              _priorityQueue.add(entry.key);
            } else {
              AppLogger.common('🗑️ [MediaCache] Removing stale cache entry: ${entry.key}', tag: 'CACHE');
            }
          } catch (e) {
            AppLogger.common('⚠️ [MediaCache] Invalid cache entry: ${entry.key}', tag: 'CACHE');
          }
        }

        // Sort by priority and access time
        _priorityQueue.sort(_priorityComparator);

        AppLogger.common('📊 [MediaCache] Loaded ${_cacheIndex.length} cached items', tag: 'CACHE');
      } else {
        AppLogger.common('📄 [MediaCache] No existing cache index found', tag: 'CACHE');
      }
    } catch (e) {
      AppLogger.commonError('❌ [MediaCache] Failed to load cache index', error: e, tag: 'CACHE');
    }
  }

  int _priorityComparator(String a, String b) {
    final itemA = _cacheIndex[a];
    final itemB = _cacheIndex[b];

    if (itemA == null || itemB == null) return 0;

    // First by media type priority (higher priority wins)
    final aPriority = _config.priorityMapping[itemA.mediaType] ?? 1;
    final bPriority = _config.priorityMapping[itemB.mediaType] ?? 1;
    final priorityDiff = bPriority.compareTo(aPriority);

    if (priorityDiff != 0) return priorityDiff;

    // Then by last access time (more recent wins)
    final accessDiff = itemB.lastAccessedAt.compareTo(itemA.lastAccessedAt);
    if (accessDiff != 0) return accessDiff;

    // Finally by file size (smaller files win)
    return itemA.fileSizeBytes.compareTo(itemB.fileSizeBytes);
  }

  Future<void> _saveCacheIndex() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final indexFile = File(path.join(tempDir.path, 'media_cache_index.json'));

      final indexData = _cacheIndex.map((key, item) =>
          MapEntry(key, item.toJson()));

      await indexFile.writeAsString(json.encode(indexData));
    } catch (e) {
      AppLogger.commonError('❌ [MediaCache] Failed to save cache index', error: e, tag: 'CACHE');
    }
  }

  Future<void> putFile(
    String url,
    File file, {
    String mediaType = 'unknown',
  }) async {
    final fileKey = url.hashCode.toString();
    final fileSize = await file.length();

    final cachedItem = CachedMediaItem(
      url: url,
      localPath: file.path,
      mediaType: mediaType,
      cachedAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      accessCount: 0,
      fileSizeBytes: fileSize,
    );

    _cacheIndex[fileKey] = cachedItem;
    _priorityQueue.add(fileKey);
    _priorityQueue.sort(_priorityComparator);

    await _enforceCacheLimits();
    await _saveCacheIndex();

    AppLogger.common('💾 [MediaCache] Cached $mediaType file: $fileKey (${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB)', tag: 'CACHE');
  }

  File? getFile(String url) {
    final key = url.hashCode.toString();
    final cachedItem = _cacheIndex[key];

    if (cachedItem != null) {
      final file = File(cachedItem.localPath);
      if (file.existsSync()) {
        // Update access statistics
        _cacheIndex[key] = CachedMediaItem(
          url: cachedItem.url,
          localPath: cachedItem.localPath,
          mediaType: cachedItem.mediaType,
          cachedAt: cachedItem.cachedAt,
          lastAccessedAt: DateTime.now(),
          accessCount: cachedItem.accessCount + 1,
          fileSizeBytes: cachedItem.fileSizeBytes,
          metadata: cachedItem.metadata,
        );

        _priorityQueue.sort(_priorityComparator);
        return file;
      } else {
        _cacheIndex.remove(key);
        _priorityQueue.remove(key);
      }
    }
    return null;
  }

  Map<String, dynamic> getCacheStatistics() {
    final totalSize = _cacheIndex.values.fold<int>(0, (sum, item) => sum + item.fileSizeBytes);
    final totalSizeMB = totalSize / (1024 * 1024);

    final typeStats = <String, int>{};
    for (final item in _cacheIndex.values) {
      typeStats[item.mediaType] = (typeStats[item.mediaType] ?? 0) + 1;
    }

    final mostAccessedItem = _cacheIndex.values.isNotEmpty
        ? _cacheIndex.values.reduce((a, b) => a.accessCount > b.accessCount ? a : b)
        : null;

    return {
      'totalItems': _cacheIndex.length,
      'totalSizeMB': totalSizeMB,
      'cacheLimitMB': _config.maxCacheSizeMB,
      'usagePercentage': (totalSizeMB / _config.maxCacheSizeMB * 100),
      'typeDistribution': typeStats,
      'mostAccessedCount': mostAccessedItem?.accessCount ?? 0,
      'averageFileSizeMB': _cacheIndex.isNotEmpty ? totalSizeMB / _cacheIndex.length : 0,
    };
  }

  Stream<Map<String, dynamic>> get cacheStatsStream => _cacheStatsController.stream;

  Future<void> _enforceCacheLimits() async {
    final stats = getCacheStatistics();
    final currentSizeMB = stats['totalSizeMB'] as double;

    if (currentSizeMB <= _config.maxCacheSizeMB) return;

    AppLogger.common('🧹 [MediaCache] Cache over limit (${currentSizeMB.toStringAsFixed(1)}MB/${_config.maxCacheSizeMB}MB), cleaning up...', tag: 'CACHE');

    int deletedCount = 0;
    int freedBytes = 0;

    // Remove items from the end of priority queue (lowest priority)
    while (_priorityQueue.isNotEmpty && currentSizeMB - (freedBytes / (1024 * 1024)) > _config.maxCacheSizeMB) {
      final key = _priorityQueue.removeLast();
      final item = _cacheIndex.remove(key);

      if (item != null) {
        try {
          final file = File(item.localPath);
          if (await file.exists()) {
            await file.delete();
            freedBytes += item.fileSizeBytes;
            deletedCount++;
          }
        } catch (e) {
          AppLogger.common('⚠️ [MediaCache] Failed to delete: ${item.localPath}', tag: 'CACHE');
        }
      }
    }

    AppLogger.common('🗑️ [MediaCache] Cleaned up $deletedCount files, freed ${(freedBytes / (1024 * 1024)).toStringAsFixed(2)}MB', tag: 'CACHE');
    await _saveCacheIndex();
  }

  Future<void> clearCache({bool forced = false}) async {
    if (!forced) {
      AppLogger.common('⚠️ [MediaCache] Clear cache requested but not forced', tag: 'CACHE');
      return;
    }

    AppLogger.common('💥 [MediaCache] Force clearing entire cache...', tag: 'CACHE');

    for (final item in _cacheIndex.values) {
      try {
        final file = File(item.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        AppLogger.common('⚠️ [MediaCache] Failed to delete: ${item.localPath}', tag: 'CACHE');
      }
    }

    _cacheIndex.clear();
    _priorityQueue.clear();
    await _saveCacheIndex();
    AppLogger.common('✅ [MediaCache] Cache cleared', tag: 'CACHE');
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_config.cleanupInterval, (_) async {
      try {
        await _enforceCacheLimits();
      } catch (e) {
        AppLogger.commonError('❌ [MediaCache] Automatic cleanup failed', error: e, tag: 'CACHE');
      }
    });
  }

  void _startStatsReporting() {
    Timer.periodic(const Duration(minutes: 30), (_) {
      if (!_cacheStatsController.isClosed) {
        _cacheStatsController.add(getCacheStatistics());
      }
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cacheStatsController.close();
  }
}
