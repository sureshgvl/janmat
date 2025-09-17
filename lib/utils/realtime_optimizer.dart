import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'performance_monitor.dart';

/// Optimized real-time listener manager
class RealtimeOptimizer {
  static final RealtimeOptimizer _instance = RealtimeOptimizer._internal();
  factory RealtimeOptimizer() => _instance;

  RealtimeOptimizer._internal();

  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final Map<String, DateTime> _subscriptionStartTimes = {};
  final Map<String, int> _subscriptionEventCounts = {};
  final Map<String, Duration?> _subscriptionLifespans = {};

  /// Register a new real-time subscription with optimization
  StreamSubscription<T> registerSubscription<T>(
    String subscriptionId,
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool cancelOnError = false,
    Duration? lifespan,
  }) {
    // Cancel existing subscription if it exists
    cancelSubscription(subscriptionId);

    final subscription = stream.listen(
      (data) {
        _subscriptionEventCounts[subscriptionId] =
            (_subscriptionEventCounts[subscriptionId] ?? 0) + 1;
        onData(data);

        // Check if subscription should be cancelled due to lifespan
        if (lifespan != null &&
            _subscriptionStartTimes.containsKey(subscriptionId)) {
          final elapsed = DateTime.now().difference(
            _subscriptionStartTimes[subscriptionId]!,
          );
          if (elapsed >= lifespan) {
            if (kDebugMode) {
              debugPrint(
                '⏰ Cancelling subscription $subscriptionId due to lifespan expiration',
              );
            }
            cancelSubscription(subscriptionId);
          }
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _activeSubscriptions[subscriptionId] = subscription;
    _subscriptionStartTimes[subscriptionId] = DateTime.now();
    _subscriptionLifespans[subscriptionId] = lifespan;

    if (kDebugMode) {
      debugPrint('📡 Registered real-time subscription: $subscriptionId');
    }

    return subscription;
  }

  /// Cancel a specific subscription
  void cancelSubscription(String subscriptionId) {
    final subscription = _activeSubscriptions[subscriptionId];
    if (subscription != null) {
      subscription.cancel();
      _activeSubscriptions.remove(subscriptionId);
      _subscriptionStartTimes.remove(subscriptionId);
      _subscriptionLifespans.remove(subscriptionId);

      final eventCount = _subscriptionEventCounts[subscriptionId] ?? 0;
      _subscriptionEventCounts.remove(subscriptionId);

      if (kDebugMode) {
        debugPrint(
          '🛑 Cancelled subscription $subscriptionId (processed $eventCount events)',
        );
      }
    }
  }

  /// Cancel all subscriptions
  void cancelAllSubscriptions() {
    for (final subscriptionId in _activeSubscriptions.keys.toList()) {
      cancelSubscription(subscriptionId);
    }

    if (kDebugMode) {
      debugPrint(
        '🧹 Cancelled all ${_activeSubscriptions.length} subscriptions',
      );
    }
  }

  /// Cancel subscriptions by pattern
  void cancelSubscriptionsByPattern(String pattern) {
    final matchingIds = _activeSubscriptions.keys
        .where((id) => id.contains(pattern))
        .toList();

    for (final id in matchingIds) {
      cancelSubscription(id);
    }

    if (kDebugMode && matchingIds.isNotEmpty) {
      debugPrint(
        '🎯 Cancelled ${matchingIds.length} subscriptions matching pattern: $pattern',
      );
    }
  }

  /// Get subscription statistics
  Map<String, dynamic> getSubscriptionStats() {
    final now = DateTime.now();
    final stats = <String, dynamic>{};

    for (final subscriptionId in _activeSubscriptions.keys) {
      final startTime = _subscriptionStartTimes[subscriptionId];
      final lifespan = _subscriptionLifespans[subscriptionId];
      final eventCount = _subscriptionEventCounts[subscriptionId] ?? 0;

      if (startTime != null) {
        final duration = now.difference(startTime);
        final isExpired = lifespan != null && duration >= lifespan;

        stats[subscriptionId] = {
          'duration': duration,
          'eventCount': eventCount,
          'lifespan': lifespan,
          'isExpired': isExpired,
          'eventsPerMinute': duration.inMinutes > 0
              ? eventCount / duration.inMinutes
              : eventCount,
        };
      }
    }

    return {
      'activeSubscriptions': _activeSubscriptions.length,
      'subscriptionDetails': stats,
      'totalEventsProcessed': _subscriptionEventCounts.values.fold(
        0,
        (sum, count) => sum + count,
      ),
    };
  }

  /// Optimize subscription based on usage patterns
  void optimizeSubscription(String subscriptionId) {
    final stats = getSubscriptionStats();
    final subscriptionStats = stats['subscriptionDetails'][subscriptionId];

    if (subscriptionStats != null) {
      final eventCount = subscriptionStats['eventCount'] as int;
      final eventsPerMinute = subscriptionStats['eventsPerMinute'] as double;

      // Cancel low-activity subscriptions
      if (eventsPerMinute < 0.1 && eventCount < 5) {
        if (kDebugMode) {
          debugPrint(
            '⚡ Optimizing: Cancelling low-activity subscription $subscriptionId',
          );
        }
        cancelSubscription(subscriptionId);
      }
    }
  }

  /// Clean up expired subscriptions
  void cleanupExpiredSubscriptions() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final subscriptionId in _subscriptionLifespans.keys) {
      final lifespan = _subscriptionLifespans[subscriptionId];
      final startTime = _subscriptionStartTimes[subscriptionId];

      if (lifespan != null && startTime != null) {
        if (now.difference(startTime) >= lifespan) {
          expiredIds.add(subscriptionId);
        }
      }
    }

    for (final id in expiredIds) {
      cancelSubscription(id);
    }

    if (kDebugMode && expiredIds.isNotEmpty) {
      debugPrint('🧽 Cleaned up ${expiredIds.length} expired subscriptions');
    }
  }
}

/// Smart Firestore query builder with optimization
class OptimizedFirestoreQuery {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Query _buildOptimizedQuery({
    required String collection,
    List<String>? orderBy,
    Map<String, dynamic>? whereClauses,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore.collection(collection);

    // Apply where clauses efficiently
    if (whereClauses != null) {
      // Sort where clauses by selectivity (equality first, then range)
      final sortedClauses = whereClauses.entries.toList()
        ..sort((a, b) {
          // Equality queries are more selective
          final aIsEquality = a.value is! List && a.value != null;
          final bIsEquality = b.value is! List && b.value != null;
          if (aIsEquality && !bIsEquality) return -1;
          if (!aIsEquality && bIsEquality) return 1;
          return 0;
        });

      for (final clause in sortedClauses) {
        if (clause.value is List) {
          // Range query
          final range = clause.value as List;
          if (range.length >= 2) {
            query = query.where(clause.key, isGreaterThanOrEqualTo: range[0]);
            if (range.length >= 3) {
              query = query.where(clause.key, isLessThanOrEqualTo: range[2]);
            }
          }
        } else if (clause.value != null) {
          // Equality query
          query = query.where(clause.key, isEqualTo: clause.value);
        }
      }
    }

    // Apply ordering
    if (orderBy != null) {
      for (final field in orderBy) {
        query = query.orderBy(field);
      }
    }

    // Apply pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  /// Execute optimized query with caching
  Future<QuerySnapshot> executeOptimizedQuery({
    required String collection,
    List<String>? orderBy,
    Map<String, dynamic>? whereClauses,
    int? limit,
    DocumentSnapshot? startAfter,
    Duration? cacheTimeout,
  }) async {
    final query = _buildOptimizedQuery(
      collection: collection,
      orderBy: orderBy,
      whereClauses: whereClauses,
      limit: limit,
      startAfter: startAfter,
    );

    // Add performance monitoring
    final monitor = PerformanceMonitor();
    monitor.startTimer('firestore_query_$collection');

    try {
      final snapshot = await query.get();
      monitor.trackFirebaseRead(collection, snapshot.docs.length);
      monitor.stopTimer('firestore_query_$collection');

      if (kDebugMode) {
        debugPrint(
          '🔍 Optimized query on $collection returned ${snapshot.docs.length} documents',
        );
      }

      return snapshot;
    } catch (e) {
      monitor.stopTimer('firestore_query_$collection');
      rethrow;
    }
  }

  /// Create optimized real-time listener
  Stream<QuerySnapshot> createOptimizedListener({
    required String collection,
    List<String>? orderBy,
    Map<String, dynamic>? whereClauses,
    int? limit,
    String? listenerId,
    Duration? lifespan,
  }) {
    final query = _buildOptimizedQuery(
      collection: collection,
      orderBy: orderBy,
      whereClauses: whereClauses,
      limit: limit,
    );

    final stream = query.snapshots();

    if (listenerId != null) {
      final optimizer = RealtimeOptimizer();

      return stream.transform(
        StreamTransformer<QuerySnapshot, QuerySnapshot>.fromHandlers(
          handleData: (data, sink) {
            // Track listener activity
            optimizer.registerSubscription(listenerId, Stream.value(data), (
              QuerySnapshot snapshot,
            ) {
              sink.add(snapshot);
            }, lifespan: lifespan);
          },
        ),
      );
    }

    return stream;
  }
}
