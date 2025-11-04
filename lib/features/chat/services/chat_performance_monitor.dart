import 'dart:async';
import 'dart:collection';
import '../../../utils/app_logger.dart';
import 'background_cache_warmer.dart';
import 'whatsapp_style_message_cache.dart';
import 'persistent_chat_room_cache.dart';
import 'whatsapp_style_chat_cache.dart';

class PerformanceMetric {
  final String metricName;
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.metricName,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'metricName': metricName,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

class CachePerformanceSnapshot {
  final int memoryCacheHits;
  final int diskCacheHits;
  final int localStorageHits;
  final int networkRequests;
  final int totalRequests;
  final Duration averageLoadTime;
  final DateTime timestamp;

  CachePerformanceSnapshot({
    required this.memoryCacheHits,
    required this.diskCacheHits,
    required this.localStorageHits,
    required this.networkRequests,
    required this.totalRequests,
    required this.averageLoadTime,
    required this.timestamp,
  });

  double get cacheHitRate => totalRequests > 0 ? (memoryCacheHits + diskCacheHits + localStorageHits) / totalRequests : 0.0;

  Map<String, dynamic> toJson() => {
    'memoryCacheHits': memoryCacheHits,
    'diskCacheHits': diskCacheHits,
    'localStorageHits': localStorageHits,
    'networkRequests': networkRequests,
    'totalRequests': totalRequests,
    'cacheHitRate': cacheHitRate,
    'averageLoadTimeMs': averageLoadTime.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ChatPerformanceMonitor {
  final WhatsAppStyleMessageCache _messageCache;
  final PersistentChatRoomCache _roomCache;
  final WhatsAppStyleChatCache _chatCache;
  final BackgroundCacheWarmer _cacheWarmer;

  // Metrics storage
  final List<PerformanceMetric> _metrics = [];
  final List<CachePerformanceSnapshot> _cacheSnapshots = [];
  final Queue<Duration> _recentLoadTimes = Queue<Duration>();

  // Performance tracking
  int _memoryCacheHits = 0;
  int _diskCacheHits = 0;
  int _localStorageHits = 0;
  int _networkRequests = 0;
  int _totalRequests = 0;

  // Timers and streams
  Timer? _snapshotTimer;
  StreamSubscription? _messageCacheSubscription;
  StreamSubscription? _roomCacheSubscription;

  // Configuration
  static const Duration _snapshotInterval = Duration(minutes: 5);
  static const int _maxMetricsHistory = 1000;
  static const int _maxSnapshotsHistory = 100;
  static const int _maxLoadTimesHistory = 100;

  ChatPerformanceMonitor({
    required WhatsAppStyleMessageCache messageCache,
    required PersistentChatRoomCache roomCache,
    required WhatsAppStyleChatCache chatCache,
    required BackgroundCacheWarmer cacheWarmer,
  }) : _messageCache = messageCache,
       _roomCache = roomCache,
       _chatCache = chatCache,
       _cacheWarmer = cacheWarmer;

  // Initialize performance monitoring
  Future<void> initialize() async {
    AppLogger.chat('📊 ChatPerformanceMonitor: Initializing performance monitoring');

    // Start periodic snapshots
    _startPeriodicSnapshots();

    // Set up cache performance tracking
    _setupCacheMonitoring();

    // Record initial metrics
    await _recordInitialMetrics();

    AppLogger.chat('✅ ChatPerformanceMonitor: Initialized successfully');
  }

  // Start periodic performance snapshots
  void _startPeriodicSnapshots() {
    _snapshotTimer = Timer.periodic(_snapshotInterval, (timer) {
      _takePerformanceSnapshot();
    });
    AppLogger.chat('⏰ ChatPerformanceMonitor: Started periodic snapshots every ${_snapshotInterval.inMinutes} minutes');
  }

  // Set up cache performance monitoring
  void _setupCacheMonitoring() {
    // Monitor message cache performance
    // Note: In a real implementation, you'd modify the cache classes to emit performance events
    // For now, we'll use polling and estimation
    AppLogger.chat('👁️ ChatPerformanceMonitor: Cache monitoring setup (polling-based)');
  }

  // Record initial performance metrics
  Future<void> _recordInitialMetrics() async {
    // Record startup metrics
    _recordMetric('app_startup_time', DateTime.now().millisecondsSinceEpoch.toDouble(), 'ms',
      metadata: {'event': 'performance_monitor_initialized'});

    // Record cache stats
    await _recordCacheStats();

    // Record memory usage estimate
    _recordMetric('estimated_memory_usage', 0.0, 'MB',
      metadata: {'component': 'chat_system', 'note': 'baseline_measurement'});
  }

  // Take performance snapshot
  void _takePerformanceSnapshot() {
    final snapshot = CachePerformanceSnapshot(
      memoryCacheHits: _memoryCacheHits,
      diskCacheHits: _diskCacheHits,
      localStorageHits: _localStorageHits,
      networkRequests: _networkRequests,
      totalRequests: _totalRequests,
      averageLoadTime: _calculateAverageLoadTime(),
      timestamp: DateTime.now(),
    );

    _cacheSnapshots.add(snapshot);

    // Keep only recent snapshots
    if (_cacheSnapshots.length > _maxSnapshotsHistory) {
      _cacheSnapshots.removeRange(0, _cacheSnapshots.length - _maxSnapshotsHistory);
    }

    AppLogger.chat('📸 ChatPerformanceMonitor: Performance snapshot taken - Hit Rate: ${(snapshot.cacheHitRate * 100).toStringAsFixed(1)}%');

    // Reset counters for next snapshot period
    _resetCounters();
  }

  // Record a performance metric
  void _recordMetric(String name, double value, String unit, {Map<String, dynamic> metadata = const {}}) {
    final metric = PerformanceMetric(
      metricName: name,
      value: value,
      unit: unit,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _metrics.add(metric);

    // Keep only recent metrics
    if (_metrics.length > _maxMetricsHistory) {
      _metrics.removeRange(0, _metrics.length - _maxMetricsHistory);
    }

    AppLogger.chat('📊 ChatPerformanceMonitor: Recorded metric - $name: $value $unit');
  }

  // Record message load time
  void recordMessageLoadTime(String roomId, Duration loadTime, String source) {
    _recentLoadTimes.add(loadTime);
    if (_recentLoadTimes.length > _maxLoadTimesHistory) {
      _recentLoadTimes.removeFirst();
    }

    // Update cache hit counters based on source
    _totalRequests++;
    switch (source) {
      case 'memory_cache':
        _memoryCacheHits++;
        break;
      case 'disk_cache':
        _diskCacheHits++;
        break;
      case 'local_storage':
        _localStorageHits++;
        break;
      case 'network':
        _networkRequests++;
        break;
    }

    _recordMetric('message_load_time', loadTime.inMilliseconds.toDouble(), 'ms',
      metadata: {'roomId': roomId, 'source': source});
  }

  // Record cache operation
  void recordCacheOperation(String operation, String cacheType, Duration duration, {bool success = true}) {
    _recordMetric('cache_operation_time', duration.inMilliseconds.toDouble(), 'ms',
      metadata: {
        'operation': operation,
        'cacheType': cacheType,
        'success': success,
      });
  }

  // Record background warmup performance
  void recordWarmupPerformance(CacheWarmupMetrics metrics) {
    _recordMetric('background_warmup_rooms', metrics.roomsWarmed.toDouble(), 'count',
      metadata: {'duration': metrics.warmupTime.inMilliseconds});
    _recordMetric('background_warmup_messages', metrics.messagesWarmed.toDouble(), 'count',
      metadata: {'duration': metrics.warmupTime.inMilliseconds});
    _recordMetric('background_warmup_time', metrics.warmupTime.inMilliseconds.toDouble(), 'ms');
  }

  // Record cache statistics
  Future<void> _recordCacheStats() async {
    try {
      // Message cache stats
      final messageStats = await _messageCache.getStorageStats();
      _recordMetric('message_cache_size', (messageStats['total']?['sizeMB'] ?? 0.0), 'MB');

      // Room cache stats
      final roomStats = await _roomCache.getCacheStats();
      _recordMetric('room_cache_entries', 0.0, 'count',
        metadata: {'cache_type': roomStats['cache_type'] ?? 'unknown'});

      // Chat cache stats
      final chatStats = await _chatCache.getStorageStats();
      _recordMetric('chat_cache_size', (chatStats['totalSizeMB'] ?? 0.0), 'MB');

      // Background warmer stats
      final warmerStats = _cacheWarmer.getWarmupStats();
      _recordMetric('warmup_queue_length', (warmerStats['warmupQueueLength'] ?? 0).toDouble(), 'count');
      _recordMetric('recently_warmed_rooms', (warmerStats['recentlyWarmedRooms'] ?? 0).toDouble(), 'count');

    } catch (e) {
      AppLogger.chat('❌ ChatPerformanceMonitor: Failed to record cache stats: $e');
    }
  }

  // Calculate average load time
  Duration _calculateAverageLoadTime() {
    if (_recentLoadTimes.isEmpty) return Duration.zero;

    final totalMs = _recentLoadTimes.fold(0, (sum, time) => sum + time.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ _recentLoadTimes.length);
  }

  // Reset performance counters
  void _resetCounters() {
    _memoryCacheHits = 0;
    _diskCacheHits = 0;
    _localStorageHits = 0;
    _networkRequests = 0;
    _totalRequests = 0;
  }

  // Get comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    final recentMetrics = _metrics.where((m) =>
      m.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1)))
    ).toList();

    final latestSnapshot = _cacheSnapshots.isNotEmpty ? _cacheSnapshots.last : null;

    // Calculate averages
    final loadTimeMetrics = recentMetrics.where((m) => m.metricName == 'message_load_time').toList();
    final avgLoadTime = loadTimeMetrics.isNotEmpty
        ? loadTimeMetrics.map((m) => m.value).reduce((a, b) => a + b) / loadTimeMetrics.length
        : 0.0;

    final cacheOpMetrics = recentMetrics.where((m) => m.metricName == 'cache_operation_time').toList();
    final avgCacheOpTime = cacheOpMetrics.isNotEmpty
        ? cacheOpMetrics.map((m) => m.value).reduce((a, b) => a + b) / cacheOpMetrics.length
        : 0.0;

    return {
      'summary': {
        'totalMetrics': _metrics.length,
        'recentMetrics1h': recentMetrics.length,
        'totalSnapshots': _cacheSnapshots.length,
        'averageLoadTimeMs': avgLoadTime,
        'averageCacheOpTimeMs': avgCacheOpTime,
        'cacheHitRate': latestSnapshot?.cacheHitRate ?? 0.0,
      },
      'cachePerformance': latestSnapshot?.toJson() ?? {},
      'recentMetrics': recentMetrics.take(10).map((m) => m.toJson()).toList(),
      'recommendations': _generateOptimizationRecommendations(),
      'systemHealth': _assessSystemHealth(),
    };
  }

  // Generate optimization recommendations
  List<String> _generateOptimizationRecommendations() {
    final recommendations = <String>[];
    final latestSnapshot = _cacheSnapshots.isNotEmpty ? _cacheSnapshots.last : null;

    if (latestSnapshot != null) {
      final hitRate = latestSnapshot.cacheHitRate;

      if (hitRate < 0.7) {
        recommendations.add('⚠️ Low cache hit rate (${(hitRate * 100).toStringAsFixed(1)}%). Consider increasing background warming frequency.');
      }

      if (latestSnapshot.averageLoadTime > const Duration(milliseconds: 500)) {
        recommendations.add('🐌 Slow average load time (${latestSnapshot.averageLoadTime.inMilliseconds}ms). Consider optimizing cache layers.');
      }

      if (latestSnapshot.networkRequests > latestSnapshot.totalRequests * 0.3) {
        recommendations.add('🌐 High network usage. Consider pre-warming more rooms or increasing cache TTL.');
      }
    }

    // Check warmup performance
    final warmerStats = _cacheWarmer.getWarmupStats();
    final queueLength = warmerStats['warmupQueueLength'] ?? 0;
    if (queueLength > 5) {
      recommendations.add('📋 Long warmup queue (${queueLength} items). Consider increasing concurrent warmup limit.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ System performing optimally. No optimization recommendations at this time.');
    }

    return recommendations;
  }

  // Assess system health
  Map<String, dynamic> _assessSystemHealth() {
    final latestSnapshot = _cacheSnapshots.isNotEmpty ? _cacheSnapshots.last : null;
    final health = <String, dynamic>{};

    if (latestSnapshot != null) {
      // Cache health
      final hitRate = latestSnapshot.cacheHitRate;
      health['cacheHealth'] = hitRate > 0.8 ? 'excellent' : hitRate > 0.6 ? 'good' : 'needs_improvement';

      // Performance health
      final avgLoadTime = latestSnapshot.averageLoadTime.inMilliseconds;
      health['performanceHealth'] = avgLoadTime < 200 ? 'excellent' : avgLoadTime < 500 ? 'good' : 'needs_improvement';

      // Network health
      final networkRatio = latestSnapshot.totalRequests > 0 ? latestSnapshot.networkRequests / latestSnapshot.totalRequests : 0.0;
      health['networkHealth'] = networkRatio < 0.2 ? 'excellent' : networkRatio < 0.4 ? 'good' : 'needs_improvement';
    }

    // Overall health score
    final healthScores = health.values.where((v) => v is String).map((v) {
      switch (v) {
        case 'excellent': return 3;
        case 'good': return 2;
        case 'needs_improvement': return 1;
        default: return 0;
      }
    }).toList();

    final avgHealthScore = healthScores.isNotEmpty ? healthScores.reduce((a, b) => a + b) / healthScores.length : 0.0;
    health['overallHealth'] = avgHealthScore > 2.5 ? 'excellent' : avgHealthScore > 1.5 ? 'good' : 'needs_improvement';

    return health;
  }

  // Export performance data for analysis
  Map<String, dynamic> exportPerformanceData({Duration? timeRange}) {
    final cutoff = timeRange != null
        ? DateTime.now().subtract(timeRange)
        : DateTime.now().subtract(const Duration(hours: 24));

    final relevantMetrics = _metrics.where((m) => m.timestamp.isAfter(cutoff)).toList();
    final relevantSnapshots = _cacheSnapshots.where((s) => s.timestamp.isAfter(cutoff)).toList();

    return {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'timeRange': timeRange?.inHours ?? 24,
      'metrics': relevantMetrics.map((m) => m.toJson()).toList(),
      'cacheSnapshots': relevantSnapshots.map((s) => s.toJson()).toList(),
      'summary': getPerformanceReport(),
    };
  }

  // Get real-time metrics for dashboard
  Map<String, dynamic> getRealtimeMetrics() {
    final latestSnapshot = _cacheSnapshots.isNotEmpty ? _cacheSnapshots.last : null;

    return {
      'currentCacheHitRate': latestSnapshot?.cacheHitRate ?? 0.0,
      'currentAverageLoadTime': _calculateAverageLoadTime().inMilliseconds,
      'activeWarmup': _cacheWarmer.getWarmupStats()['currentlyWarming'] ?? false,
      'warmupQueueLength': _cacheWarmer.getWarmupStats()['warmupQueueLength'] ?? 0,
      'totalMetricsCollected': _metrics.length,
      'memoryCacheHits': _memoryCacheHits,
      'diskCacheHits': _diskCacheHits,
      'localStorageHits': _localStorageHits,
      'networkRequests': _networkRequests,
      'lastSnapshotTime': latestSnapshot?.timestamp.toIso8601String(),
    };
  }

  // Force performance snapshot
  void forceSnapshot() {
    AppLogger.chat('🔧 ChatPerformanceMonitor: Forcing performance snapshot');
    _takePerformanceSnapshot();
  }

  // Clear old performance data
  void cleanupOldData({Duration maxAge = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(maxAge);

    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));
    _cacheSnapshots.removeWhere((s) => s.timestamp.isBefore(cutoff));

    AppLogger.chat('🧹 ChatPerformanceMonitor: Cleaned up data older than ${maxAge.inDays} days');
  }

  // Stop performance monitoring
  void stop() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _messageCacheSubscription?.cancel();
    _roomCacheSubscription?.cancel();

    AppLogger.chat('🛑 ChatPerformanceMonitor: Stopped performance monitoring');
  }

  // Dispose resources
  void dispose() {
    stop();
    _metrics.clear();
    _cacheSnapshots.clear();
    _recentLoadTimes.clear();

    AppLogger.chat('✅ ChatPerformanceMonitor: Disposed');
  }
}
