import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Background sync manager for offline data synchronization
class BackgroundSyncManager {
  static final BackgroundSyncManager _instance =
      BackgroundSyncManager._internal();
  factory BackgroundSyncManager() => _instance;

  BackgroundSyncManager._internal() {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Timer? _syncTimer;
  bool _isOnline = true;
  final Map<String, dynamic> _pendingOperations = {};
  final Map<String, Completer<void>> _syncCompleters = {};

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  void _initialize() {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Start background sync timer (every 5 minutes when online)
    _startBackgroundSync();

    // Listen to app lifecycle changes
    // Note: In a real implementation, you'd use WidgetsBindingObserver
    // to detect when app goes to background/foreground
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (!wasOnline && _isOnline) {
      // Came back online, trigger sync
      _triggerSync('connectivity_restored');
    } else if (wasOnline && !_isOnline) {
      // Went offline
      _syncStatusController.add(SyncStatus.offline);
    }
  }

  void _startBackgroundSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline && _pendingOperations.isNotEmpty) {
        _performBackgroundSync();
      }
    });
  }

  /// Queue an operation for background sync
  void queueOperation(String operationId, Future<void> Function() operation) {
    _pendingOperations[operationId] = operation;

    if (kDebugMode) {
      debugPrint('📋 Queued background operation: $operationId');
    }

    // If online, try to sync immediately
    if (_isOnline) {
      _triggerSync('immediate');
    }
  }

  /// Trigger manual sync
  Future<void> triggerManualSync() async {
    if (!_isOnline) {
      throw Exception('Cannot sync while offline');
    }

    final completer = Completer<void>();
    _syncCompleters['manual'] = completer;

    _triggerSync('manual');

    return completer.future;
  }

  void _triggerSync(String reason) {
    if (_pendingOperations.isEmpty) return;

    if (kDebugMode) {
      debugPrint('🔄 Triggering background sync (reason: $reason)');
    }

    _syncStatusController.add(SyncStatus.syncing);
    _performBackgroundSync();
  }

  Future<void> _performBackgroundSync() async {
    if (_pendingOperations.isEmpty) {
      _syncStatusController.add(SyncStatus.idle);
      return;
    }

    final operations = Map<String, dynamic>.from(_pendingOperations);
    _pendingOperations.clear();

    int successCount = 0;
    int failureCount = 0;

    for (final entry in operations.entries) {
      final operationId = entry.key;
      final operation = entry.value as Future<void> Function();

      try {
        await operation();
        successCount++;

        if (kDebugMode) {
          debugPrint('✅ Background operation completed: $operationId');
        }
      } catch (e) {
        failureCount++;
        // Re-queue failed operations
        _pendingOperations[operationId] = operation;

        if (kDebugMode) {
          debugPrint('❌ Background operation failed: $operationId - $e');
        }
      }
    }

    // Complete manual sync if it was requested
    final manualCompleter = _syncCompleters.remove('manual');
    if (manualCompleter != null) {
      if (failureCount == 0) {
        manualCompleter.complete();
      } else {
        manualCompleter.completeError(
          Exception('$failureCount operations failed'),
        );
      }
    }

    // Update sync status
    if (_pendingOperations.isEmpty) {
      _syncStatusController.add(SyncStatus.idle);
    } else {
      _syncStatusController.add(SyncStatus.partialFailure);
    }

    if (kDebugMode) {
      debugPrint(
        '📊 Background sync completed: $successCount successful, $failureCount failed',
      );
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'isOnline': _isOnline,
      'pendingOperations': _pendingOperations.length,
      'activeSyncCompleters': _syncCompleters.length,
    };
  }

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingOperations.clear();
    _syncStatusController.add(SyncStatus.idle);

    if (kDebugMode) {
      debugPrint('🧹 Cleared all pending background operations');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Sync status enumeration
enum SyncStatus { idle, syncing, offline, partialFailure }

/// Smart offline queue for Firebase operations
class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._instance;
  factory OfflineQueue() => _instance;

  OfflineQueue._internal();

  final List<QueuedOperation> _queue = [];
  final StreamController<QueueStatus> _queueStatusController =
      StreamController<QueueStatus>.broadcast();

  Stream<QueueStatus> get queueStatusStream => _queueStatusController.stream;

  /// Add operation to offline queue
  void addOperation(QueuedOperation operation) {
    _queue.add(operation);
    _queueStatusController.add(QueueStatus.updated);

    if (kDebugMode) {
      debugPrint('📋 Added operation to offline queue: ${operation.id}');
    }
  }

  /// Process queued operations when back online
  Future<void> processQueue() async {
    if (_queue.isEmpty) return;

    _queueStatusController.add(QueueStatus.processing);

    final operations = List<QueuedOperation>.from(_queue);
    _queue.clear();

    int successCount = 0;
    int failureCount = 0;

    for (final operation in operations) {
      try {
        await operation.execute();
        successCount++;

        if (kDebugMode) {
          debugPrint('✅ Processed queued operation: ${operation.id}');
        }
      } catch (e) {
        failureCount++;
        // Re-queue failed operations
        _queue.add(operation);

        if (kDebugMode) {
          debugPrint(
            '❌ Failed to process queued operation: ${operation.id} - $e',
          );
        }
      }
    }

    _queueStatusController.add(
      failureCount == 0 ? QueueStatus.completed : QueueStatus.partialFailure,
    );

    if (kDebugMode) {
      debugPrint(
        '📊 Queue processing completed: $successCount successful, $failureCount failed',
      );
    }
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    return {
      'queueLength': _queue.length,
      'operationsByType': _queue.fold<Map<String, int>>({}, (map, op) {
        map[op.type] = (map[op.type] ?? 0) + 1;
        return map;
      }),
    };
  }

  /// Clear queue
  void clearQueue() {
    _queue.clear();
    _queueStatusController.add(QueueStatus.cleared);
  }
}

/// Queue status enumeration
enum QueueStatus { updated, processing, completed, partialFailure, cleared }

/// Queued operation model
class QueuedOperation {
  final String id;
  final String type;
  final Future<void> Function() execute;
  final DateTime queuedAt;
  final Map<String, dynamic>? metadata;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.execute,
    this.metadata,
  }) : queuedAt = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'queuedAt': queuedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Predictive caching manager
class PredictiveCacheManager {
  static final PredictiveCacheManager _instance =
      PredictiveCacheManager._internal();
  factory PredictiveCacheManager() => _instance;

  PredictiveCacheManager._internal();

  final Map<String, List<String>> _usagePatterns = {};
  final Map<String, DateTime> _lastAccessed = {};
  final Map<String, int> _accessFrequency = {};

  /// Record user access pattern
  void recordAccess(String userId, String resourceId, String resourceType) {
    final key = '${userId}_$resourceType';

    _usagePatterns[key] ??= [];
    if (!_usagePatterns[key]!.contains(resourceId)) {
      _usagePatterns[key]!.add(resourceId);
    }

    _lastAccessed[resourceId] = DateTime.now();
    _accessFrequency[resourceId] = (_accessFrequency[resourceId] ?? 0) + 1;
  }

  /// Get predictive cache recommendations
  List<String> getRecommendations(
    String userId,
    String resourceType, {
    int limit = 5,
  }) {
    final key = '${userId}_$resourceType';
    final patterns = _usagePatterns[key] ?? [];

    // Sort by access frequency and recency
    final sorted = patterns.toList()
      ..sort((a, b) {
        final freqA = _accessFrequency[a] ?? 0;
        final freqB = _accessFrequency[b] ?? 0;
        if (freqA != freqB) return freqB.compareTo(freqA);

        final lastA = _lastAccessed[a];
        final lastB = _lastAccessed[b];
        if (lastA != null && lastB != null) {
          return lastB.compareTo(lastA);
        }
        return 0;
      });

    return sorted.take(limit).toList();
  }

  /// Preload recommended resources
  Future<void> preloadRecommendations(
    String userId,
    String resourceType,
    Future<void> Function(String) preloadFunction,
  ) async {
    final recommendations = getRecommendations(userId, resourceType);

    for (final resourceId in recommendations) {
      try {
        await preloadFunction(resourceId);

        if (kDebugMode) {
          debugPrint('🔮 Preloaded recommended resource: $resourceId');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to preload resource: $resourceId - $e');
        }
      }
    }
  }

  /// Clean up old access patterns
  void cleanupOldPatterns({Duration maxAge = const Duration(days: 30)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    final toRemove = <String>[];

    _lastAccessed.forEach((resourceId, lastAccess) {
      if (lastAccess.isBefore(cutoff)) {
        toRemove.add(resourceId);
      }
    });

    for (final resourceId in toRemove) {
      _lastAccessed.remove(resourceId);
      _accessFrequency.remove(resourceId);

      // Remove from usage patterns
      _usagePatterns.forEach((key, patterns) {
        patterns.remove(resourceId);
      });
    }

    if (kDebugMode && toRemove.isNotEmpty) {
      debugPrint('🧹 Cleaned up ${toRemove.length} old access patterns');
    }
  }
}

