import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Advanced analytics and usage tracking system
class AdvancedAnalyticsManager {
  static final AdvancedAnalyticsManager _instance =
      AdvancedAnalyticsManager._internal();
  factory AdvancedAnalyticsManager() => _instance;

  AdvancedAnalyticsManager._internal() {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  final Map<String, UsageMetrics> _metrics = {};
  final Map<String, UserSession> _activeSessions = {};
  final StreamController<AnalyticsEvent> _eventController =
      StreamController<AnalyticsEvent>.broadcast();

  Stream<AnalyticsEvent> get eventStream => _eventController.stream;

  void _initialize() {
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    _log('📊 AdvancedAnalyticsManager initialized');
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((result) => result != ConnectivityResult.none);
    _trackConnectivityEvent(isOnline);
  }

  /// Track Firebase operation
  void trackFirebaseOperation(
    String operation,
    String collection,
    int itemCount, {
    Duration? duration,
    bool success = true,
    String? error,
  }) {
    final key = '$operation:$collection';
    _metrics[key] ??= UsageMetrics();

    final metrics = _metrics[key]!;
    metrics.totalOperations++;
    metrics.totalItems += itemCount;
    metrics.lastUsed = DateTime.now();

    if (success) {
      metrics.successCount++;
    } else {
      metrics.errorCount++;
      if (error != null) {
        metrics.errors[error] = (metrics.errors[error] ?? 0) + 1;
      }
    }

    if (duration != null) {
      metrics.totalDuration += duration;
      if (metrics.maxDuration == null || duration > metrics.maxDuration!) {
        metrics.maxDuration = duration;
      }
      if (metrics.minDuration == null || duration < metrics.minDuration!) {
        metrics.minDuration = duration;
      }
    }

    _eventController.add(
      FirebaseOperationEvent(
        operation: operation,
        collection: collection,
        itemCount: itemCount,
        duration: duration,
        success: success,
        error: error,
      ),
    );

    _log(
      '🔥 Tracked Firebase operation: $operation on $collection ($itemCount items, ${success ? 'success' : 'failed'})',
    );
  }

  /// Track user session
  void startUserSession(String userId, String userRole) {
    final session = UserSession(
      userId: userId,
      userRole: userRole,
      startTime: DateTime.now(),
    );

    _activeSessions[userId] = session;
    _log('🎯 Started user session for $userId ($userRole)');
  }

  void endUserSession(String userId) {
    final session = _activeSessions.remove(userId);
    if (session != null) {
      session.endTime = DateTime.now();
      _saveSessionData(session);
      _log(
        '🏁 Ended user session for $userId (duration: ${session.duration.inMinutes}min)',
      );
    }
  }

  /// Track user interaction
  void trackUserInteraction(
    String interactionType,
    String screenName, {
    String? elementId,
    Map<String, dynamic>? metadata,
  }) {
    final event = UserInteractionEvent(
      interactionType: interactionType,
      screenName: screenName,
      elementId: elementId,
      metadata: metadata,
    );

    _eventController.add(event);

    // Update session data if user is active
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final session = _activeSessions[currentUser.uid];
      if (session != null) {
        session.interactions++;
        session.lastActivity = DateTime.now();
      }
    }

    _log('👆 Tracked user interaction: $interactionType on $screenName');
  }

  /// Track performance metrics
  void trackPerformanceMetric(
    String metricName,
    double value, {
    String? category,
    Map<String, dynamic>? context,
  }) {
    final event = PerformanceMetricEvent(
      metricName: metricName,
      value: value,
      category: category,
      context: context,
    );

    _eventController.add(event);
    _log('📈 Tracked performance metric: $metricName = $value');
  }

  /// Track connectivity event
  void _trackConnectivityEvent(bool isOnline) {
    final event = ConnectivityEvent(isOnline: isOnline);

    _eventController.add(event);
    _log('🌐 Connectivity changed: ${isOnline ? 'online' : 'offline'}');
  }

  /// Track cache performance
  void trackCachePerformance(
    String cacheType,
    bool isHit,
    Duration? accessTime, {
    int? itemCount,
  }) {
    final event = CachePerformanceEvent(
      cacheType: cacheType,
      isHit: isHit,
      accessTime: accessTime,
      itemCount: itemCount,
    );

    _eventController.add(event);

    // Update metrics
    final key = 'cache:$cacheType';
    _metrics[key] ??= UsageMetrics();

    final metrics = _metrics[key]!;
    if (isHit) {
      metrics.cacheHits++;
    } else {
      metrics.cacheMisses++;
    }

    _log(
      '💾 Cache ${isHit ? 'hit' : 'miss'}: $cacheType (${itemCount ?? 0} items)',
    );
  }

  /// Get comprehensive analytics report
  Map<String, dynamic> getAnalyticsReport() {
    final report = <String, dynamic>{};
    final now = DateTime.now();

    // Firebase operations summary
    final firebaseOps = _metrics.entries
        .where((e) => e.key.contains(':'))
        .toList();
    report['firebase_operations'] = firebaseOps
        .map((e) => {'operation': e.key, 'metrics': e.value.toJson()})
        .toList();

    // Cache performance summary
    final cacheOps = _metrics.entries
        .where((e) => e.key.startsWith('cache:'))
        .toList();
    report['cache_performance'] = cacheOps
        .map(
          (e) => {
            'cache_type': e.key.substring(6),
            'metrics': e.value.toJson(),
          },
        )
        .toList();

    // User sessions summary
    report['active_sessions'] = _activeSessions.length;
    report['session_details'] = _activeSessions.values
        .map((s) => s.toJson())
        .toList();

    // Performance insights
    report['performance_insights'] = _generatePerformanceInsights();

    // Usage patterns
    report['usage_patterns'] = _generateUsagePatterns();

    return report;
  }

  Map<String, dynamic> _generatePerformanceInsights() {
    final insights = <String, dynamic>{};

    // Calculate average operation times
    final operationsWithTiming = _metrics.values.where(
      (m) => m.totalOperations > 0 && m.averageDuration != null,
    );
    if (operationsWithTiming.isNotEmpty) {
      final avgDurations = operationsWithTiming.map(
        (m) => m.averageDuration!.inMilliseconds,
      );
      insights['average_operation_time_ms'] =
          avgDurations.reduce((a, b) => a + b) / avgDurations.length;
    }

    // Calculate cache hit rates
    final cacheMetrics = _metrics.values.where(
      (m) => m.cacheHits + m.cacheMisses > 0,
    );
    if (cacheMetrics.isNotEmpty) {
      final totalHits = cacheMetrics.fold(0, (sum, m) => sum + m.cacheHits);
      final totalMisses = cacheMetrics.fold(0, (sum, m) => sum + m.cacheMisses);
      final hitRate = totalHits / (totalHits + totalMisses);
      insights['overall_cache_hit_rate'] =
          '${(hitRate * 100).toStringAsFixed(1)}%';
    }

    // Error rate analysis
    final operationsWithErrors = _metrics.values.where(
      (m) => m.totalOperations > 0,
    );
    if (operationsWithErrors.isNotEmpty) {
      final totalOps = operationsWithErrors.fold(
        0,
        (sum, m) => sum + m.totalOperations,
      );
      final totalErrors = operationsWithErrors.fold(
        0,
        (sum, m) => sum + m.errorCount,
      );
      final errorRate = totalErrors / totalOps;
      insights['overall_error_rate'] =
          '${(errorRate * 100).toStringAsFixed(2)}%';
    }

    return insights;
  }

  Map<String, dynamic> _generateUsagePatterns() {
    final patterns = <String, dynamic>{};

    // Most used operations
    final sortedOps = _metrics.entries.toList()
      ..sort(
        (a, b) => b.value.totalOperations.compareTo(a.value.totalOperations),
      );

    patterns['most_used_operations'] = sortedOps
        .take(5)
        .map(
          (e) => {'operation': e.key, 'usage_count': e.value.totalOperations},
        )
        .toList();

    // Peak usage times (based on timestamps)
    final timestamps = _metrics.values
        .where((m) => m.lastUsed != null)
        .map((m) => m.lastUsed!.hour)
        .toList();

    if (timestamps.isNotEmpty) {
      final hourCounts = <int, int>{};
      for (final hour in timestamps) {
        hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      }

      final peakHour = hourCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      patterns['peak_usage_hour'] = peakHour;
    }

    return patterns;
  }

  /// Save session data to Firestore
  Future<void> _saveSessionData(UserSession session) async {
    try {
      await _firestore.collection('user_sessions').add({
        'userId': session.userId,
        'userRole': session.userRole,
        'startTime': session.startTime,
        'endTime': session.endTime,
        'duration': session.duration.inMinutes,
        'interactions': session.interactions,
        'lastActivity': session.lastActivity,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _log('💾 Saved session data for user ${session.userId}');
    } catch (e) {
      _log('❌ Failed to save session data: $e');
    }
  }

  /// Export analytics data
  Future<String> exportAnalyticsData() async {
    final report = getAnalyticsReport();
    // In a real implementation, this would format and export the data
    return 'Analytics export would be implemented here';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📊 ANALYTICS: $message');
    }
  }

  void dispose() {
    _eventController.close();
  }
}

/// Usage metrics for tracking operations
class UsageMetrics {
  int totalOperations = 0;
  int totalItems = 0;
  int successCount = 0;
  int errorCount = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  Duration totalDuration = Duration.zero;
  Duration? maxDuration;
  Duration? minDuration;
  DateTime? lastUsed;
  final Map<String, int> errors = {};

  Duration? get averageDuration {
    return totalOperations > 0 ? totalDuration ~/ totalOperations : null;
  }

  double get successRate {
    return totalOperations > 0 ? successCount / totalOperations : 0.0;
  }

  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOperations': totalOperations,
      'totalItems': totalItems,
      'successCount': successCount,
      'errorCount': errorCount,
      'successRate': '${(successRate * 100).toStringAsFixed(1)}%',
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'cacheHitRate': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
      'averageDuration': averageDuration?.inMilliseconds,
      'maxDuration': maxDuration?.inMilliseconds,
      'minDuration': minDuration?.inMilliseconds,
      'lastUsed': lastUsed?.toIso8601String(),
      'topErrors': errors.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..take(3)
        ..map((e) => {'error': e.key, 'count': e.value}),
    };
  }
}

/// User session tracking
class UserSession {
  final String userId;
  final String userRole;
  final DateTime startTime;
  DateTime? endTime;
  int interactions = 0;
  DateTime? lastActivity;

  UserSession({
    required this.userId,
    required this.userRole,
    required this.startTime,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userRole': userRole,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': duration.inMinutes,
      'interactions': interactions,
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }
}

/// Analytics event base class
abstract class AnalyticsEvent {
  final DateTime timestamp;

  AnalyticsEvent({DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Firebase operation event
class FirebaseOperationEvent extends AnalyticsEvent {
  final String operation;
  final String collection;
  final int itemCount;
  final Duration? duration;
  final bool success;
  final String? error;

  FirebaseOperationEvent({
    required this.operation,
    required this.collection,
    required this.itemCount,
    this.duration,
    required this.success,
    this.error,
  });
}

/// User interaction event
class UserInteractionEvent extends AnalyticsEvent {
  final String interactionType;
  final String screenName;
  final String? elementId;
  final Map<String, dynamic>? metadata;

  UserInteractionEvent({
    required this.interactionType,
    required this.screenName,
    this.elementId,
    this.metadata,
  });
}

/// Performance metric event
class PerformanceMetricEvent extends AnalyticsEvent {
  final String metricName;
  final double value;
  final String? category;
  final Map<String, dynamic>? context;

  PerformanceMetricEvent({
    required this.metricName,
    required this.value,
    this.category,
    this.context,
  });
}

/// Connectivity event
class ConnectivityEvent extends AnalyticsEvent {
  final bool isOnline;

  ConnectivityEvent({required this.isOnline});
}

/// Cache performance event
class CachePerformanceEvent extends AnalyticsEvent {
  final String cacheType;
  final bool isHit;
  final Duration? accessTime;
  final int? itemCount;

  CachePerformanceEvent({
    required this.cacheType,
    required this.isHit,
    this.accessTime,
    this.itemCount,
  });
}

/// Real-time analytics dashboard
class AnalyticsDashboard {
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final StreamController<Map<String, dynamic>> _dashboardController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get dashboardStream =>
      _dashboardController.stream;

  void startRealtimeUpdates() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      final report = _analytics.getAnalyticsReport();
      _dashboardController.add(report);
    });

    _log('📊 Started real-time analytics dashboard updates');
  }

  void stopRealtimeUpdates() {
    _dashboardController.close();
    _log('📊 Stopped real-time analytics dashboard updates');
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📈 DASHBOARD: $message');
    }
  }
}

/// Usage pattern analyzer
class UsagePatternAnalyzer {
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();

  /// Analyze user behavior patterns
  Map<String, dynamic> analyzeUserPatterns(String userId) {
    // This would analyze historical data for the specific user
    // For now, return a placeholder structure
    return {
      'userId': userId,
      'patterns': {
        'most_active_hours': [9, 10, 11, 14, 15, 16],
        'preferred_features': ['chat', 'candidates', 'events'],
        'average_session_duration': 25, // minutes
        'interaction_frequency': 'high',
      },
      'recommendations': [
        'Consider push notifications during active hours',
        'Promote frequently used features',
        'Optimize for mobile usage patterns',
      ],
    };
  }

  /// Predict user engagement
  Map<String, dynamic> predictEngagement(String userId) {
    // Simple prediction based on current patterns
    return {
      'userId': userId,
      'engagement_score': 0.85, // 0-1 scale
      'predicted_actions': [
        'View candidate profiles',
        'Participate in chat rooms',
        'Follow candidates',
      ],
      'confidence': 0.72,
    };
  }

  /// Generate personalized recommendations
  List<String> generateRecommendations(String userId) {
    final patterns = analyzeUserPatterns(userId);

    return [
      'Based on your usage patterns, try exploring ${patterns['patterns']['preferred_features'][0]} more often',
      'You are most active between ${patterns['patterns']['most_active_hours'][0]}:00-${patterns['patterns']['most_active_hours'][2]}:00',
      'Consider enabling notifications for ${patterns['patterns']['preferred_features'][1]} updates',
    ];
  }
}
