import 'dart:async';
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<int>> _performanceMetrics = {};

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
        final avgDuration = _performanceMetrics[operationName]!
            .reduce((a, b) => a + b) / _performanceMetrics[operationName]!.length;

        debugPrint('⏱️ $operationName completed in ${duration}ms (avg: ${avgDuration.toStringAsFixed(1)}ms)');
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
        debugPrint('🐌 SLOW OPERATION: $operationName averaging ${avgTime.toStringAsFixed(1)}ms (threshold: ${thresholdMs}ms)');
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

  // Clear all metrics
  void clearMetrics() {
    _timers.clear();
    _performanceMetrics.clear();
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
    final report = PerformanceMonitor().getPerformanceReport();
    debugPrint('📊 Performance Report:');
    report.forEach((operation, metrics) {
      debugPrint('  $operation: ${metrics['average'].toStringAsFixed(1)}ms avg (${metrics['samples']} samples)');
    });
  }
}