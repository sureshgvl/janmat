import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:janmat/utils/app_logger.dart';

/// Connection quality levels
enum ConnectionQuality { offline, poor, moderate, good, excellent }

/// Network-aware Firebase operation optimizer
class ConnectionOptimizer {
  static final ConnectionOptimizer _instance = ConnectionOptimizer._internal();
  factory ConnectionOptimizer() => _instance;

  ConnectionOptimizer._internal() {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  ConnectionQuality _currentQuality = ConnectionQuality.good;
  final StreamController<ConnectionQuality> _qualityController =
      StreamController<ConnectionQuality>.broadcast();

  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;
  ConnectionQuality get currentQuality => _currentQuality;

  void _initialize() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _determineConnectionQuality();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _determineConnectionQuality();
  }

  Future<void> _determineConnectionQuality() async {
    try {
      final result = await _connectivity.checkConnectivity();

      ConnectionQuality newQuality;
      switch (result) {
        case ConnectivityResult.none:
          newQuality = ConnectionQuality.offline;
          break;
        case ConnectivityResult.mobile:
          // For mobile, we assume moderate quality unless we can measure it
          newQuality = ConnectionQuality.moderate;
          break;
        case ConnectivityResult.wifi:
          // WiFi typically provides better quality
          newQuality = ConnectionQuality.good;
          break;
        case ConnectivityResult.ethernet:
          newQuality = ConnectionQuality.excellent;
          break;
        default:
          newQuality = ConnectionQuality.moderate;
      }

      if (newQuality != _currentQuality) {
        _currentQuality = newQuality;
        _qualityController.add(newQuality);

        if (kDebugMode) {
          AppLogger.common('🌐 Connection quality changed to: $newQuality');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error determining connection quality: $e');
    }
  }

  /// Get optimal batch size based on connection quality
  int getOptimalBatchSize() {
    switch (_currentQuality) {
      case ConnectionQuality.offline:
        return 1; // No batching when offline
      case ConnectionQuality.poor:
        return 5; // Small batches for poor connection
      case ConnectionQuality.moderate:
        return 10; // Medium batches
      case ConnectionQuality.good:
        return 20; // Larger batches
      case ConnectionQuality.excellent:
        return 50; // Maximum batching
    }
  }

  /// Get optimal cache TTL based on connection quality
  Duration getOptimalCacheTTL() {
    switch (_currentQuality) {
      case ConnectionQuality.offline:
        return const Duration(hours: 24); // Longer cache when offline
      case ConnectionQuality.poor:
        return const Duration(hours: 6); // Moderate cache
      case ConnectionQuality.moderate:
        return const Duration(hours: 2);
      case ConnectionQuality.good:
        return const Duration(hours: 1);
      case ConnectionQuality.excellent:
        return const Duration(
          minutes: 30,
        ); // Shorter cache for fast connections
    }
  }

  /// Check if real-time listeners should be enabled
  bool shouldEnableRealtime() {
    return _currentQuality != ConnectionQuality.offline &&
        _currentQuality != ConnectionQuality.poor;
  }

  /// Get optimal retry delay based on connection quality
  Duration getOptimalRetryDelay(int attemptNumber) {
    final baseDelay = switch (_currentQuality) {
      ConnectionQuality.offline => const Duration(seconds: 30),
      ConnectionQuality.poor => const Duration(seconds: 10),
      ConnectionQuality.moderate => const Duration(seconds: 5),
      ConnectionQuality.good => const Duration(seconds: 2),
      ConnectionQuality.excellent => const Duration(seconds: 1),
    };

    // Exponential backoff
    return baseDelay * (1 << (attemptNumber - 1));
  }

  /// Check if operation should be attempted based on connection quality
  bool shouldAttemptOperation() {
    return _currentQuality != ConnectionQuality.offline;
  }

  void dispose() {
    _qualityController.close();
  }
}

/// Advanced retry mechanism with connection awareness
class SmartRetryManager {
  final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  final Map<String, int> _retryCounts = {};

  Future<T> executeWithSmartRetry<T>(
    String operationId,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration? customTimeout,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetries) {
      attempt++;

      // Check if we should attempt the operation
      if (!_connectionOptimizer.shouldAttemptOperation()) {
        throw Exception('Operation cancelled: No internet connection');
      }

      try {
        final timeout = customTimeout ?? _getTimeoutForAttempt(attempt);
        final result = await operation().timeout(timeout);
        _retryCounts.remove(operationId); // Success, clear retry count
        return result;
      } catch (e) {
        lastException = e as Exception;

        if (kDebugMode) {
          AppLogger.error(
            '🔄 Retry attempt $attempt/$maxRetries for $operationId failed: $e',
          );
        }

        // Don't retry on certain errors
        if (_isNonRetryableError(e)) {
          break;
        }

        // Wait before retrying
        if (attempt < maxRetries) {
          final delay = _connectionOptimizer.getOptimalRetryDelay(attempt);
          await Future.delayed(delay);
        }
      }
    }

    _retryCounts[operationId] = (_retryCounts[operationId] ?? 0) + attempt;
    throw lastException ??
        Exception('Operation failed after $maxRetries attempts');
  }

  Duration _getTimeoutForAttempt(int attempt) {
    // Progressive timeout increase
    return Duration(seconds: 10 + (attempt * 5));
  }

  bool _isNonRetryableError(dynamic error) {
    // Define errors that shouldn't be retried
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission-denied') ||
        errorString.contains('not-found') ||
        errorString.contains('invalid-argument') ||
        errorString.contains('unauthenticated');
  }

  int getRetryCount(String operationId) {
    return _retryCounts[operationId] ?? 0;
  }

  void resetRetryCount(String operationId) {
    _retryCounts.remove(operationId);
  }
}

