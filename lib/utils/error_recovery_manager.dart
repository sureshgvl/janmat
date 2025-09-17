import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connection_optimizer.dart';

/// Circuit breaker states
enum CircuitState {
  closed, // Normal operation
  open, // Failing, requests rejected
  halfOpen, // Testing if service recovered
}

/// Circuit breaker for Firebase operations
class CircuitBreaker {
  final String _operationId;
  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailure;
  DateTime? _lastSuccess;
  final int _failureThreshold;
  final int _successThreshold;
  final Duration _timeout;
  final Duration _retryTimeout;

  CircuitBreaker(
    this._operationId, {
    int failureThreshold = 5,
    int successThreshold = 3,
    Duration timeout = const Duration(seconds: 30),
    Duration retryTimeout = const Duration(seconds: 60),
  }) : _failureThreshold = failureThreshold,
       _successThreshold = successThreshold,
       _timeout = timeout,
       _retryTimeout = retryTimeout;

  bool get isClosed => _state == CircuitState.closed;
  bool get isOpen => _state == CircuitState.open;
  bool get isHalfOpen => _state == CircuitState.halfOpen;

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (isOpen) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
        _log(
          '🔄 Circuit breaker HALF-OPEN: Testing service recovery for $_operationId',
        );
      } else {
        _log('❌ Circuit breaker OPEN: Rejecting request for $_operationId');
        throw CircuitBreakerException(
          'Circuit breaker is open for $_operationId',
        );
      }
    }

    try {
      final result = await operation().timeout(_timeout);
      _recordSuccess();
      return result;
    } catch (e) {
      _recordFailure();
      _log('💥 Operation failed in circuit breaker: $_operationId - $e');
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailure == null) return true;
    return DateTime.now().difference(_lastFailure!) > _retryTimeout;
  }

  void _recordSuccess() {
    _successCount++;
    _lastSuccess = DateTime.now();

    if (isHalfOpen && _successCount >= _successThreshold) {
      _state = CircuitState.closed;
      _failureCount = 0;
      _successCount = 0;
      _log('✅ Circuit breaker CLOSED: Service recovered for $_operationId');
    } else if (isClosed) {
      _log('✅ Operation successful: $_operationId');
    }
  }

  void _recordFailure() {
    _failureCount++;
    _lastFailure = DateTime.now();

    if (_failureCount >= _failureThreshold) {
      _state = CircuitState.open;
      _log(
        '🚫 Circuit breaker OPEN: Too many failures for $_operationId ($_failureCount/$_failureThreshold)',
      );
    } else {
      _log(
        '⚠️ Operation failed: $_operationId ($_failureCount/$_failureThreshold)',
      );
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🔌 CIRCUIT: $message');
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'operationId': _operationId,
      'state': _state.toString(),
      'failureCount': _failureCount,
      'successCount': _successCount,
      'lastFailure': _lastFailure?.toIso8601String(),
      'lastSuccess': _lastSuccess?.toIso8601String(),
      'failureThreshold': _failureThreshold,
      'successThreshold': _successThreshold,
    };
  }
}

/// Advanced error recovery manager with multiple strategies
class ErrorRecoveryManager {
  static final ErrorRecoveryManager _instance =
      ErrorRecoveryManager._internal();
  factory ErrorRecoveryManager() => _instance;

  ErrorRecoveryManager._internal() {
    _initialize();
  }

  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  final Map<String, RetryStrategy> _retryStrategies = {};

  void _initialize() {
    _log('🚀 Error Recovery Manager initialized');
  }

  /// Execute operation with circuit breaker and retry logic
  Future<T> executeWithRecovery<T>(
    String operationId,
    Future<T> Function() operation, {
    RetryStrategy? retryStrategy,
    bool useCircuitBreaker = true,
  }) async {
    final strategy = retryStrategy ?? _getDefaultRetryStrategy(operationId);

    if (useCircuitBreaker) {
      final breaker = _getCircuitBreaker(operationId);
      return breaker.execute(
        () => _executeWithRetry(operationId, operation, strategy),
      );
    } else {
      return _executeWithRetry(operationId, operation, strategy);
    }
  }

  Future<T> _executeWithRetry<T>(
    String operationId,
    Future<T> Function() operation,
    RetryStrategy strategy,
  ) async {
    Exception? lastException;
    int attempt = 0;

    while (attempt < strategy.maxRetries) {
      attempt++;

      try {
        _log(
          '🔄 Attempting operation: $operationId (attempt $attempt/${strategy.maxRetries})',
        );
        final result = await operation().timeout(strategy.timeout);
        _log('✅ Operation successful: $operationId (attempt $attempt)');
        return result;
      } catch (e) {
        lastException = e as Exception;
        _log('❌ Operation failed: $operationId (attempt $attempt) - $e');

        // Check if error is retryable
        if (!strategy.shouldRetry(e, attempt)) {
          _log('🛑 Non-retryable error for $operationId: $e');
          break;
        }

        // Calculate delay based on strategy and connection quality
        final baseDelay = strategy.getDelay(attempt);
        final connectionDelay = _connectionOptimizer.getOptimalRetryDelay(
          attempt,
        );
        final delay = baseDelay + connectionDelay;

        _log('⏳ Retrying $operationId in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }

    _log('💥 All retry attempts exhausted for $operationId');
    throw lastException ??
        Exception('Operation failed after ${strategy.maxRetries} attempts');
  }

  CircuitBreaker _getCircuitBreaker(String operationId) {
    return _circuitBreakers[operationId] ??= CircuitBreaker(operationId);
  }

  RetryStrategy _getDefaultRetryStrategy(String operationId) {
    return _retryStrategies[operationId] ??= ProgressiveRetryStrategy();
  }

  /// Configure custom retry strategy for operation
  void setRetryStrategy(String operationId, RetryStrategy strategy) {
    _retryStrategies[operationId] = strategy;
    _log('⚙️ Custom retry strategy set for $operationId');
  }

  /// Get recovery statistics
  Map<String, dynamic> getRecoveryStats() {
    final circuitStats = <String, dynamic>{};
    _circuitBreakers.forEach((id, breaker) {
      circuitStats[id] = breaker.getStats();
    });

    return {
      'circuitBreakers': circuitStats,
      'retryStrategies': _retryStrategies.keys.toList(),
      'connectionQuality': _connectionOptimizer.currentQuality.toString(),
    };
  }

  /// Reset circuit breaker for operation
  void resetCircuitBreaker(String operationId) {
    final breaker = _circuitBreakers[operationId];
    if (breaker != null) {
      breaker._state = CircuitState.closed;
      breaker._failureCount = 0;
      breaker._successCount = 0;
      _log('🔄 Circuit breaker reset for $operationId');
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🛡️ RECOVERY: $message');
    }
  }
}

/// Retry strategy interface
abstract class RetryStrategy {
  int get maxRetries;
  Duration get timeout;

  bool shouldRetry(Exception error, int attempt);
  Duration getDelay(int attempt);
}

/// Progressive retry strategy with exponential backoff
class ProgressiveRetryStrategy implements RetryStrategy {
  @override
  int get maxRetries => 3;

  @override
  Duration get timeout => const Duration(seconds: 10);

  @override
  bool shouldRetry(Exception error, int attempt) {
    // Don't retry certain errors
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission-denied') ||
        errorString.contains('not-found') ||
        errorString.contains('invalid-argument') ||
        errorString.contains('unauthenticated')) {
      return false;
    }
    return attempt < maxRetries;
  }

  @override
  Duration getDelay(int attempt) {
    // Exponential backoff: 1s, 2s, 4s
    return Duration(seconds: 1 << (attempt - 1));
  }
}

/// Aggressive retry strategy for critical operations
class AggressiveRetryStrategy implements RetryStrategy {
  @override
  int get maxRetries => 5;

  @override
  Duration get timeout => const Duration(seconds: 5);

  @override
  bool shouldRetry(Exception error, int attempt) {
    final errorString = error.toString().toLowerCase();
    // Only skip retry for truly non-recoverable errors
    return !errorString.contains('permission-denied') &&
        !errorString.contains('not-found');
  }

  @override
  Duration getDelay(int attempt) {
    // Shorter delays: 0.5s, 1s, 2s, 4s, 8s
    return Duration(milliseconds: 500 * (1 << (attempt - 1)));
  }
}

/// Conservative retry strategy for non-critical operations
class ConservativeRetryStrategy implements RetryStrategy {
  @override
  int get maxRetries => 2;

  @override
  Duration get timeout => const Duration(seconds: 15);

  @override
  bool shouldRetry(Exception error, int attempt) {
    final errorString = error.toString().toLowerCase();
    // Very conservative - only retry network errors
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('unavailable');
  }

  @override
  Duration getDelay(int attempt) {
    // Longer delays: 3s, 6s
    return Duration(seconds: 3 * attempt);
  }
}

/// Custom exception for circuit breaker
class CircuitBreakerException implements Exception {
  final String message;
  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

/// Firebase-specific error recovery
class FirebaseErrorRecovery {
  static final FirebaseErrorRecovery _instance =
      FirebaseErrorRecovery._internal();
  factory FirebaseErrorRecovery() => _instance;

  FirebaseErrorRecovery._internal();

  final ErrorRecoveryManager _recoveryManager = ErrorRecoveryManager();

  /// Execute Firestore operation with recovery
  Future<T> executeFirestoreOperation<T>(
    String operationId,
    Future<T> Function() operation, {
    RetryStrategy? retryStrategy,
  }) async {
    return _recoveryManager.executeWithRecovery(
      'firestore_$operationId',
      operation,
      retryStrategy: retryStrategy ?? ProgressiveRetryStrategy(),
    );
  }

  /// Execute Firebase Storage operation with recovery
  Future<T> executeStorageOperation<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    return _recoveryManager.executeWithRecovery(
      'storage_$operationId',
      operation,
      retryStrategy:
          AggressiveRetryStrategy(), // Storage operations are more critical
    );
  }

  /// Execute Firebase Auth operation with recovery
  Future<T> executeAuthOperation<T>(
    String operationId,
    Future<T> Function() operation,
  ) async {
    return _recoveryManager.executeWithRecovery(
      'auth_$operationId',
      operation,
      retryStrategy:
          ConservativeRetryStrategy(), // Auth operations are sensitive
      useCircuitBreaker: false, // Don't use circuit breaker for auth
    );
  }

  /// Get recovery statistics
  Map<String, dynamic> getStats() {
    return _recoveryManager.getRecoveryStats();
  }
}
