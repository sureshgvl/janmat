import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _performanceMetrics = {};

  // Firebase operation tracking
  final Map<String, int> _firebaseReadCount = {};
  final Map<String, int> _firebaseWriteCount = {};
  final Map<String, int> _cacheHitCount = {};
  final Map<String, int> _cacheMissCount = {};

  // Start timing an operation
  void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();

    if (kDebugMode) {
      debugPrint('⏱️ Started timing: $operationName');
    }
  }

  // Stop timing and log the result
  void stopTimer(String operationName) {
    final timer = _timers[operationName];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;

      // Store metrics for analysis
      _performanceMetrics[operationName] ??= [];
      _performanceMetrics[operationName]!.add(duration);

      // Keep only last 10 measurements
      if (_performanceMetrics[operationName]!.length > 10) {
        _performanceMetrics[operationName]!.removeAt(0);
      }

      if (kDebugMode) {
        final avgDuration =
            _performanceMetrics[operationName]!.reduce((a, b) => a + b) /
            _performanceMetrics[operationName]!.length;

        debugPrint(
          '⏱️ $operationName completed in ${duration}ms (avg: ${avgDuration.toStringAsFixed(1)}ms)',
        );
      }

      _timers.remove(operationName);
    }
  }

  // Get average performance for an operation
  double getAverageTime(String operationName) {
    final metrics = _performanceMetrics[operationName];
    if (metrics == null || metrics.isEmpty) return 0.0;

    return metrics.reduce((a, b) => a + b) / metrics.length;
  }

  // Log slow operations (over threshold)
  void logSlowOperation(String operationName, int thresholdMs) {
    final avgTime = getAverageTime(operationName);
    if (avgTime > thresholdMs) {
      if (kDebugMode) {
        debugPrint(
          '🐌 SLOW OPERATION: $operationName averaging ${avgTime.toStringAsFixed(1)}ms (threshold: ${thresholdMs}ms)',
        );
      }
    }
  }

  // Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};

    _performanceMetrics.forEach((operation, times) {
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) / times.length;
        final min = times.reduce((a, b) => a < b ? a : b);
        final max = times.reduce((a, b) => a > b ? a : b);

        report[operation] = {
          'average': avg,
          'min': min,
          'max': max,
          'samples': times.length,
        };
      }
    });

    return report;
  }

  // Track Firebase read operations
  void trackFirebaseRead(String collection, int count) {
    _firebaseReadCount[collection] =
        (_firebaseReadCount[collection] ?? 0) + count;

    if (kDebugMode) {
      debugPrint(
        '📖 Firebase Read: $collection (+$count) - Total: ${_firebaseReadCount[collection]}',
      );
    }
  }

  // Track Firebase write operations
  void trackFirebaseWrite(String collection, int count) {
    _firebaseWriteCount[collection] =
        (_firebaseWriteCount[collection] ?? 0) + count;

    if (kDebugMode) {
      debugPrint(
        '✏️ Firebase Write: $collection (+$count) - Total: ${_firebaseWriteCount[collection]}',
      );
    }
  }

  // Track cache hits
  void trackCacheHit(String cacheType) {
    _cacheHitCount[cacheType] = (_cacheHitCount[cacheType] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint(
        '⚡ Cache Hit: $cacheType - Total: ${_cacheHitCount[cacheType]}',
      );
    }
  }

  // Track cache misses
  void trackCacheMiss(String cacheType) {
    _cacheMissCount[cacheType] = (_cacheMissCount[cacheType] ?? 0) + 1;

    if (kDebugMode) {
      debugPrint(
        '🔄 Cache Miss: $cacheType - Total: ${_cacheMissCount[cacheType]}',
      );
    }
  }

  // Get Firebase operation summary
  Map<String, dynamic> getFirebaseSummary() {
    final totalReads = _firebaseReadCount.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalWrites = _firebaseWriteCount.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalCacheHits = _cacheHitCount.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalCacheMisses = _cacheMissCount.values.fold(
      0,
      (sum, count) => sum + count,
    );

    return {
      'total_reads': totalReads,
      'total_writes': totalWrites,
      'total_cache_hits': totalCacheHits,
      'total_cache_misses': totalCacheMisses,
      'cache_hit_rate': totalCacheHits + totalCacheMisses > 0
          ? '${(totalCacheHits / (totalCacheHits + totalCacheMisses) * 100).toStringAsFixed(1)}%'
          : '0%',
      'read_breakdown': _firebaseReadCount,
      'write_breakdown': _firebaseWriteCount,
      'cache_hit_breakdown': _cacheHitCount,
      'cache_miss_breakdown': _cacheMissCount,
    };
  }

  // Enhanced performance report with Firebase metrics
  Map<String, dynamic> getEnhancedPerformanceReport() {
    final baseReport = getPerformanceReport();
    final firebaseSummary = getFirebaseSummary();

    return {
      'performance_metrics': baseReport,
      'firebase_operations': firebaseSummary,
      'optimization_score': _calculateOptimizationScore(firebaseSummary),
    };
  }

  // Calculate optimization score based on cache hit rate and operation efficiency
  double _calculateOptimizationScore(Map<String, dynamic> firebaseSummary) {
    final cacheHitRate = firebaseSummary['cache_hit_rate'];
    final hitRateValue = cacheHitRate != '0%'
        ? double.parse(cacheHitRate.replaceAll('%', ''))
        : 0.0;

    // Score based on cache hit rate (0-100)
    double score = hitRateValue;

    // Bonus for low Firebase operations (assuming efficient batching)
    final totalOps =
        firebaseSummary['total_reads'] + firebaseSummary['total_writes'];
    if (totalOps < 50) score += 10; // Bonus for low operation count
    if (totalOps < 20) score += 10; // Extra bonus for very efficient usage

    return score.clamp(0.0, 100.0);
  }

  // Clear all metrics
  void clearMetrics() {
    _timers.clear();
    _performanceMetrics.clear();
    _firebaseReadCount.clear();
    _firebaseWriteCount.clear();
    _cacheHitCount.clear();
    _cacheMissCount.clear();
  }
}

// Convenience functions for easy use
void startPerformanceTimer(String operationName) {
  PerformanceMonitor().startTimer(operationName);
}

void stopPerformanceTimer(String operationName) {
  PerformanceMonitor().stopTimer(operationName);
}

void logPerformanceReport() {
  if (kDebugMode) {
    final report = PerformanceMonitor().getEnhancedPerformanceReport();
    debugPrint('📊 Enhanced Performance Report:');

    // Performance metrics
    final perfMetrics = report['performance_metrics'] as Map<String, dynamic>;
    if (perfMetrics.isNotEmpty) {
      debugPrint('⏱️ Operation Timings:');
      perfMetrics.forEach((operation, metrics) {
        debugPrint(
          '  $operation: ${metrics['average'].toStringAsFixed(1)}ms avg (${metrics['samples']} samples)',
        );
      });
    }

    // Firebase operations
    final firebaseOps = report['firebase_operations'] as Map<String, dynamic>;
    debugPrint('🔥 Firebase Operations:');
    debugPrint(
      '  Reads: ${firebaseOps['total_reads']}, Writes: ${firebaseOps['total_writes']}',
    );
    debugPrint('  Cache Hit Rate: ${firebaseOps['cache_hit_rate']}');

    // Optimization score
    final score = report['optimization_score'] as double;
    debugPrint('🎯 Optimization Score: ${score.toStringAsFixed(1)}/100');

    if (score >= 80) {
      debugPrint('✅ Excellent optimization! Keep up the great work.');
    } else if (score >= 60) {
      debugPrint('👍 Good optimization. Consider further improvements.');
    } else {
      debugPrint(
        '⚠️ Room for optimization. Focus on caching and batch operations.',
      );
    }
  }
}

