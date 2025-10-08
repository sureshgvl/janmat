import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/utils/app_logger.dart';

/// A/B Testing Framework for Firebase optimization experiments
class ABTestingFramework {
  static final ABTestingFramework _instance = ABTestingFramework._internal();
  factory ABTestingFramework() => _instance;

  ABTestingFramework._internal() {
    _initialize();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, ABTest> _activeTests = {};
  final Map<String, ABTestVariant> _userVariants = {};
  final Random _random = Random();

  void _initialize() {
    _loadActiveTests();
    _log('🧪 A/B Testing Framework initialized');
  }

  /// Create a new A/B test
  Future<void> createTest(
    String testId,
    String name,
    String description,
    List<ABTestVariant> variants, {
    DateTime? startDate,
    DateTime? endDate,
    int? targetSampleSize,
    Map<String, dynamic>? targetingRules,
  }) async {
    final test = ABTest(
      id: testId,
      name: name,
      description: description,
      variants: variants,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      targetSampleSize: targetSampleSize,
      targetingRules: targetingRules,
    );

    _activeTests[testId] = test;

    // Save to Firestore
    await _saveTestToFirestore(test);

    _log('✅ Created A/B test: $testId with ${variants.length} variants');
  }

  /// Get variant for current user
  ABTestVariant getVariantForUser(String testId, {String? userId}) {
    final userIdentifier = userId ?? _auth.currentUser?.uid ?? 'anonymous';
    final cacheKey = '${testId}_$userIdentifier';

    // Check cache first
    if (_userVariants.containsKey(cacheKey)) {
      return _userVariants[cacheKey]!;
    }

    final test = _activeTests[testId];
    if (test == null) {
      _log('⚠️ Test not found: $testId, returning default variant');
      return ABTestVariant.defaultVariant;
    }

    // Check if user is eligible for this test
    if (!test.isUserEligible(userIdentifier)) {
      _log('🚫 User not eligible for test: $testId');
      return ABTestVariant.defaultVariant;
    }

    // Assign variant based on consistent hashing
    final variant = _assignVariantConsistently(test, userIdentifier);
    _userVariants[cacheKey] = variant;

    _log(
      '🎯 Assigned variant ${variant.id} for user $userIdentifier in test $testId',
    );
    return variant;
  }

  /// Track conversion/event for a test
  Future<void> trackConversion(
    String testId,
    String metricName,
    double value, {
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    final userIdentifier = userId ?? _auth.currentUser?.uid ?? 'anonymous';
    final variant = getVariantForUser(testId, userId: userIdentifier);

    // Update local metrics
    variant.trackMetric(metricName, value);

    // Update test metrics
    final test = _activeTests[testId];
    if (test != null) {
      test.trackConversion(variant.id, metricName, value);
    }

    // Save to Firestore
    await _saveConversionToFirestore(
      testId,
      variant.id,
      metricName,
      value,
      userIdentifier,
      metadata,
    );

    _log(
      '📊 Tracked conversion: $metricName = $value for test $testId, variant ${variant.id}',
    );
  }

  /// Get test results
  Map<String, dynamic> getTestResults(String testId) {
    final test = _activeTests[testId];
    if (test == null) {
      return {'error': 'Test not found'};
    }

    return test.getResults();
  }

  /// End a test and declare winner
  Future<void> endTest(String testId, {String? winnerVariantId}) async {
    final test = _activeTests[testId];
    if (test == null) return;

    test.endDate = DateTime.now();
    test.winnerVariantId = winnerVariantId;

    await _saveTestToFirestore(test);
    _activeTests.remove(testId);

    _log(
      '🏁 Ended test: $testId${winnerVariantId != null ? ' (winner: $winnerVariantId)' : ''}',
    );
  }

  /// Get all active tests
  List<ABTest> getActiveTests() {
    return _activeTests.values.toList();
  }

  /// Assign variant using consistent hashing
  ABTestVariant _assignVariantConsistently(ABTest test, String userIdentifier) {
    // Simple consistent hashing using user ID hash
    final hash = userIdentifier.hashCode.abs();
    final variantIndex = hash % test.variants.length;
    return test.variants[variantIndex];
  }

  /// Check if test is still active
  bool isTestActive(String testId) {
    final test = _activeTests[testId];
    if (test == null) return false;

    final now = DateTime.now();
    if (test.startDate.isAfter(now)) return false;
    if (test.endDate != null && test.endDate!.isBefore(now)) return false;

    return true;
  }

  /// Load active tests from Firestore
  Future<void> _loadActiveTests() async {
    try {
      final snapshot = await _firestore
          .collection('ab_tests')
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final test = ABTest.fromJson(data);
        _activeTests[test.id] = test;
      }

      _log('📥 Loaded ${snapshot.docs.length} active A/B tests');
    } catch (e) {
      _log('❌ Failed to load active tests: $e');
    }
  }

  /// Save test to Firestore
  Future<void> _saveTestToFirestore(ABTest test) async {
    try {
      await _firestore.collection('ab_tests').doc(test.id).set(test.toJson());
      _log('💾 Saved test ${test.id} to Firestore');
    } catch (e) {
      _log('❌ Failed to save test ${test.id}: $e');
    }
  }

  /// Save conversion to Firestore
  Future<void> _saveConversionToFirestore(
    String testId,
    String variantId,
    String metricName,
    double value,
    String userId,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      await _firestore.collection('ab_conversions').add({
        'testId': testId,
        'variantId': variantId,
        'metricName': metricName,
        'value': value,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'metadata': metadata,
      });
    } catch (e) {
      _log('❌ Failed to save conversion: $e');
    }
  }

  /// Get testing statistics
  Map<String, dynamic> getTestingStats() {
    return {
      'active_tests': _activeTests.length,
      'total_users': _userVariants.length,
      'test_details': _activeTests.map(
        (id, test) => MapEntry(id, {
          'name': test.name,
          'variants': test.variants.length,
          'participants': test.getTotalParticipants(),
          'start_date': test.startDate.toIso8601String(),
          'end_date': test.endDate?.toIso8601String(),
        }),
      ),
    };
  }

  void _log(String message) {
    if (kDebugMode) {
      AppLogger.common('🧪 AB_TEST: $message');
    }
  }
}

/// A/B Test model
class ABTest {
  final String id;
  final String name;
  final String description;
  final List<ABTestVariant> variants;
  final DateTime startDate;
  DateTime? endDate;
  final int? targetSampleSize;
  final Map<String, dynamic>? targetingRules;
  String? winnerVariantId;

  final Map<String, Map<String, double>> _conversionMetrics = {};

  ABTest({
    required this.id,
    required this.name,
    required this.description,
    required this.variants,
    required this.startDate,
    this.endDate,
    this.targetSampleSize,
    this.targetingRules,
  });

  /// Check if user is eligible for this test
  bool isUserEligible(String userId) {
    // Simple eligibility check - can be extended with complex rules
    if (targetingRules == null) return true;

    // Example: check user role, location, etc.
    final userRole = targetingRules!['userRole'];
    if (userRole != null) {
      // In a real implementation, you'd check the user's actual role
      // For now, we'll assume all users are eligible
    }

    return true;
  }

  /// Track conversion for a variant
  void trackConversion(String variantId, String metricName, double value) {
    _conversionMetrics[variantId] ??= {};
    _conversionMetrics[variantId]![metricName] =
        (_conversionMetrics[variantId]![metricName] ?? 0) + value;
  }

  /// Get test results
  Map<String, dynamic> getResults() {
    final results = <String, dynamic>{};
    final variantResults = <String, dynamic>{};

    for (final variant in variants) {
      final metrics = _conversionMetrics[variant.id] ?? {};
      variantResults[variant.id] = {
        'name': variant.name,
        'metrics': metrics,
        'total_conversions': metrics.values.fold(
          0.0,
          (sum, value) => sum + value,
        ),
      };
    }

    results['variants'] = variantResults;
    results['winner'] = _determineWinner();
    results['confidence'] = _calculateConfidence();
    results['test_duration'] = DateTime.now().difference(startDate).inDays;

    return results;
  }

  /// Get total participants across all variants
  int getTotalParticipants() {
    return variants.fold(0, (sum, variant) => sum + variant.participantCount);
  }

  String? _determineWinner() {
    if (winnerVariantId != null) return winnerVariantId;

    // Simple winner determination based on total conversions
    String? bestVariant;
    double bestScore = 0;

    for (final variant in variants) {
      final metrics = _conversionMetrics[variant.id] ?? {};
      final score = metrics.values.fold(0.0, (sum, value) => sum + value);

      if (score > bestScore) {
        bestScore = score;
        bestVariant = variant.id;
      }
    }

    return bestVariant;
  }

  double _calculateConfidence() {
    // Simplified confidence calculation
    // In a real implementation, you'd use statistical significance tests
    final totalConversions = variants.fold(0.0, (sum, variant) {
      final metrics = _conversionMetrics[variant.id] ?? {};
      return sum + metrics.values.fold(0.0, (s, v) => s + v);
    });

    return totalConversions > 100 ? 0.95 : 0.5; // Simplified
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'variants': variants.map((v) => v.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'targetSampleSize': targetSampleSize,
      'targetingRules': targetingRules,
      'winnerVariantId': winnerVariantId,
      'status': endDate == null ? 'active' : 'completed',
    };
  }

  factory ABTest.fromJson(Map<String, dynamic> json) {
    return ABTest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      variants: (json['variants'] as List)
          .map((v) => ABTestVariant.fromJson(v))
          .toList(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      targetSampleSize: json['targetSampleSize'],
      targetingRules: json['targetingRules'],
    );
  }
}

/// A/B Test Variant model
class ABTestVariant {
  final String id;
  final String name;
  final Map<String, dynamic> configuration;
  final Map<String, double> metrics = {};
  int participantCount = 0;

  static final defaultVariant = ABTestVariant(
    id: 'default',
    name: 'Default',
    configuration: {},
  );

  ABTestVariant({
    required this.id,
    required this.name,
    required this.configuration,
  });

  /// Track a metric for this variant
  void trackMetric(String metricName, double value) {
    metrics[metricName] = (metrics[metricName] ?? 0) + value;
    participantCount++;
  }

  /// Get metric value
  double getMetric(String metricName) {
    return metrics[metricName] ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'configuration': configuration,
      'metrics': metrics,
      'participantCount': participantCount,
    };
  }

  factory ABTestVariant.fromJson(Map<String, dynamic> json) {
    final variant = ABTestVariant(
      id: json['id'],
      name: json['name'],
      configuration: json['configuration'] ?? {},
    );

    variant.metrics.addAll(
      (json['metrics'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    );
    variant.participantCount = json['participantCount'] ?? 0;

    return variant;
  }
}

/// Firebase optimization A/B test variants
class FirebaseOptimizationVariants {
  /// Cache TTL variants
  static List<ABTestVariant> get cacheTtlVariants => [
    ABTestVariant(
      id: 'cache_short',
      name: 'Short Cache (5min)',
      configuration: {'cacheTtlMinutes': 5},
    ),
    ABTestVariant(
      id: 'cache_medium',
      name: 'Medium Cache (15min)',
      configuration: {'cacheTtlMinutes': 15},
    ),
    ABTestVariant(
      id: 'cache_long',
      name: 'Long Cache (60min)',
      configuration: {'cacheTtlMinutes': 60},
    ),
  ];

  /// Batch size variants
  static List<ABTestVariant> get batchSizeVariants => [
    ABTestVariant(
      id: 'batch_small',
      name: 'Small Batch (10)',
      configuration: {'batchSize': 10},
    ),
    ABTestVariant(
      id: 'batch_medium',
      name: 'Medium Batch (25)',
      configuration: {'batchSize': 25},
    ),
    ABTestVariant(
      id: 'batch_large',
      name: 'Large Batch (50)',
      configuration: {'batchSize': 50},
    ),
  ];

  /// Retry strategy variants
  static List<ABTestVariant> get retryStrategyVariants => [
    ABTestVariant(
      id: 'retry_conservative',
      name: 'Conservative Retry',
      configuration: {'retryStrategy': 'conservative'},
    ),
    ABTestVariant(
      id: 'retry_progressive',
      name: 'Progressive Retry',
      configuration: {'retryStrategy': 'progressive'},
    ),
    ABTestVariant(
      id: 'retry_aggressive',
      name: 'Aggressive Retry',
      configuration: {'retryStrategy': 'aggressive'},
    ),
  ];

  /// Compression variants
  static List<ABTestVariant> get compressionVariants => [
    ABTestVariant(
      id: 'compression_off',
      name: 'No Compression',
      configuration: {'compressionEnabled': false},
    ),
    ABTestVariant(
      id: 'compression_on',
      name: 'With Compression',
      configuration: {'compressionEnabled': true},
    ),
  ];
}

/// A/B Test runner for Firebase optimizations
class FirebaseOptimizationTester {
  final ABTestingFramework _abFramework = ABTestingFramework();

  /// Run cache TTL optimization test
  Future<void> runCacheTtlTest() async {
    await _abFramework.createTest(
      'cache_ttl_optimization',
      'Cache TTL Optimization',
      'Test different cache TTL values for optimal performance',
      FirebaseOptimizationVariants.cacheTtlVariants,
      targetSampleSize: 1000,
    );
  }

  /// Run batch size optimization test
  Future<void> runBatchSizeTest() async {
    await _abFramework.createTest(
      'batch_size_optimization',
      'Batch Size Optimization',
      'Test different batch sizes for optimal Firebase operations',
      FirebaseOptimizationVariants.batchSizeVariants,
      targetSampleSize: 1000,
    );
  }

  /// Run retry strategy test
  Future<void> runRetryStrategyTest() async {
    await _abFramework.createTest(
      'retry_strategy_optimization',
      'Retry Strategy Optimization',
      'Test different retry strategies for failed operations',
      FirebaseOptimizationVariants.retryStrategyVariants,
      targetSampleSize: 1000,
    );
  }

  /// Run compression test
  Future<void> runCompressionTest() async {
    await _abFramework.createTest(
      'compression_optimization',
      'Data Compression Optimization',
      'Test data compression for reduced payload sizes',
      FirebaseOptimizationVariants.compressionVariants,
      targetSampleSize: 1000,
    );
  }

  /// Get current user's test variant for a specific optimization
  ABTestVariant getUserVariant(String testId) {
    return _abFramework.getVariantForUser(testId);
  }

  /// Track performance metric for current test
  Future<void> trackMetric(
    String testId,
    String metricName,
    double value,
  ) async {
    await _abFramework.trackConversion(testId, metricName, value);
  }

  /// Get test results
  Map<String, dynamic> getTestResults(String testId) {
    return _abFramework.getTestResults(testId);
  }

  /// End test and get winner
  Future<String?> endTest(String testId) async {
    final results = _abFramework.getTestResults(testId);
    final winner = results['winner'] as String?;
    await _abFramework.endTest(testId, winnerVariantId: winner);
    return winner;
  }
}

/// Statistical significance calculator
class StatisticalSignificanceCalculator {
  /// Calculate statistical significance between two variants
  static Map<String, dynamic> calculateSignificance(
    double variantAValue,
    double variantBValue,
    int variantASampleSize,
    int variantBSampleSize,
  ) {
    // Simplified statistical significance calculation
    // In a real implementation, you'd use proper statistical tests

    final meanA = variantAValue / variantASampleSize;
    final meanB = variantBValue / variantBSampleSize;

    final varianceA = (variantAValue * (1 - meanA)) / variantASampleSize;
    final varianceB = (variantBValue * (1 - meanB)) / variantBSampleSize;

    final standardError = sqrt(
      varianceA / variantASampleSize + varianceB / variantBSampleSize,
    );
    final zScore = (meanB - meanA) / standardError;
    final pValue = 1 - _normalCDF(zScore.abs());
    final confidence = (1 - pValue) * 100;

    return {
      'z_score': zScore,
      'p_value': pValue,
      'confidence_level': '${confidence.toStringAsFixed(1)}%',
      'is_significant': pValue < 0.05,
      'effect_size': meanB - meanA,
      'relative_improvement': meanA != 0 ? ((meanB - meanA) / meanA * 100) : 0,
    };
  }

  /// Normal cumulative distribution function approximation
  static double _normalCDF(double x) {
    // Abramowitz & Stegun approximation
    final a1 = 0.254829592;
    final a2 = -0.284496736;
    final a3 = 1.421413741;
    final a4 = -1.453152027;
    final a5 = 1.061405429;
    final p = 0.3275911;

    final sign = x < 0 ? -1 : 1;
    x = x.abs();

    final t = 1.0 / (1.0 + p * x);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);

    return 0.5 * (1.0 + sign * y);
  }

  static double sqrt(double x) => x < 0 ? double.nan : _sqrtPositive(x);

  static double _sqrtPositive(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double exp(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}

