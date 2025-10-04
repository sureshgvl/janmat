import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data compression manager for Firebase operations
class DataCompressionManager {
  static final DataCompressionManager _instance =
      DataCompressionManager._internal();
  factory DataCompressionManager() => _instance;

  DataCompressionManager._internal() {
    _initialize();
  }

  // Compression mappings for common field names
  static const Map<String, String> _fieldMappings = {
    // Candidate fields
    'candidateId': 'cid',
    'userId': 'uid',
    'name': 'n',
    'party': 'p',
    'symbol': 's',
    'photo': 'ph',
    'manifesto': 'm',
    'contact': 'c',
    'extra_info': 'ei',
    'followersCount': 'fc',
    'approved': 'ap',
    'status': 'st',
    'districtId': 'did',
    'bodyId': 'bid',
    'wardId': 'wid',
    'area': 'a',
    'createdAt': 'ca',
    'updatedAt': 'ua',

    // Contact fields
    'phone': 'ph',
    'email': 'em',
    'address': 'ad',

    // Extra info fields
    'bio': 'b',
    'education': 'ed',
    'age': 'ag',
    'gender': 'g',
    'experience': 'ex',
    'achievements': 'ach',

    // Chat fields
    'roomId': 'rid',
    'title': 't',
    'description': 'd',
    'type': 'ty',
    'createdBy': 'cb',
    'messageId': 'mid',
    'text': 'txt',
    'senderId': 'sid',
    'timestamp': 'ts',
    'readBy': 'rb',
    'reactions': 'r',
    'isDeleted': 'del',

    // Poll fields
    'pollId': 'pid',
    'question': 'q',
    'options': 'opt',
    'votes': 'v',
    'userVotes': 'uv',
    'totalVotes': 'tv',
  };

  // Reverse mappings for decompression
  final Map<String, String> _reverseMappings = {};

  void _initialize() {
    _reverseMappings.addAll(_fieldMappings.map((k, v) => MapEntry(v, k)));
    _log(
      '🗜️ DataCompressionManager initialized with ${_fieldMappings.length} field mappings',
    );
  }

  /// Compress data for storage
  Map<String, dynamic> compress(Map<String, dynamic> data) {
    final compressed = <String, dynamic>{};
    int originalSize = _calculateSize(data);
    int compressedFields = 0;

    data.forEach((key, value) {
      final compressedKey = _fieldMappings[key] ?? key;

      if (compressedKey != key) {
        compressedFields++;
      }

      // Recursively compress nested objects
      if (value is Map<String, dynamic>) {
        compressed[compressedKey] = compress(value);
      } else if (value is List) {
        compressed[compressedKey] = value.map((item) {
          return item is Map<String, dynamic> ? compress(item) : item;
        }).toList();
      } else {
        compressed[compressedKey] = value;
      }
    });

    int compressedSize = _calculateSize(compressed);
    double compressionRatio = originalSize > 0
        ? (compressedSize / originalSize)
        : 1.0;

    _log(
      '🗜️ Compressed $compressedFields fields, ratio: ${(compressionRatio * 100).toStringAsFixed(1)}%',
    );

    return compressed;
  }

  /// Decompress data for use
  Map<String, dynamic> decompress(Map<String, dynamic> data) {
    final decompressed = <String, dynamic>{};

    data.forEach((key, value) {
      final originalKey = _reverseMappings[key] ?? key;

      // Recursively decompress nested objects
      if (value is Map<String, dynamic>) {
        decompressed[originalKey] = decompress(value);
      } else if (value is List) {
        decompressed[originalKey] = value.map((item) {
          return item is Map<String, dynamic> ? decompress(item) : item;
        }).toList();
      } else {
        decompressed[originalKey] = value;
      }
    });

    return decompressed;
  }

  /// Calculate approximate size of data in bytes
  int _calculateSize(dynamic data) {
    if (data is Map) {
      return data.entries.fold<int>(0, (size, entry) {
        return (size + entry.key.length + _calculateSize(entry.value)).toInt();
      });
    } else if (data is List) {
      return data.fold<int>(
        0,
        (size, item) => (size + _calculateSize(item)).toInt(),
      );
    } else if (data is String) {
      return data.length * 2; // UTF-16 approximation
    } else if (data is num) {
      return 8; // 64-bit number
    } else if (data is bool) {
      return 1;
    } else {
      return 16; // Default object size
    }
  }

  /// Get compression statistics
  Map<String, dynamic> getCompressionStats() {
    return {
      'totalMappings': _fieldMappings.length,
      'compressionRatio': _calculateAverageCompressionRatio(),
      'fieldMappings': _fieldMappings,
    };
  }

  double _calculateAverageCompressionRatio() {
    // Calculate average compression ratio based on field name lengths
    int totalOriginalLength = 0;
    int totalCompressedLength = 0;

    _fieldMappings.forEach((original, compressed) {
      totalOriginalLength += original.length;
      totalCompressedLength += compressed.length;
    });

    return totalOriginalLength > 0
        ? totalCompressedLength / totalOriginalLength
        : 1.0;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🗜️ COMPRESSION: $message');
    }
  }
}

/// Selective field loader for optimized data fetching
class SelectiveFieldLoader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCompressionManager _compressionManager = DataCompressionManager();

  /// Load only specific fields from a document
  Future<Map<String, dynamic>?> loadFields(
    String collection,
    String documentId,
    List<String> fields, {
    bool useCompression = true,
  }) async {
    _log(
      '🔍 Loading selective fields: ${fields.join(', ')} from $collection/$documentId',
    );

    final monitor = PerformanceMonitor();
    monitor.startTimer('selective_field_load');

    try {
      final docRef = _firestore.collection(collection).doc(documentId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        _log('❌ Document not found: $collection/$documentId');
        monitor.stopTimer('selective_field_load');
        return null;
      }

      final data = snapshot.data()!;
      final selectedData = <String, dynamic>{};

      for (final field in fields) {
        if (data.containsKey(field)) {
          selectedData[field] = data[field];
        }
      }

      monitor.trackFirebaseRead(collection, 1);
      monitor.stopTimer('selective_field_load');

      final result = useCompression
          ? _compressionManager.decompress(selectedData)
          : selectedData;
      _log(
        '✅ Loaded ${selectedData.length} fields (${result.length} after processing)',
      );

      return result;
    } catch (e) {
      monitor.stopTimer('selective_field_load');
      _log('❌ Failed to load selective fields: $e');
      rethrow;
    }
  }

  /// Load multiple documents with selective fields
  Future<List<Map<String, dynamic>>> loadMultipleFields(
    String collection,
    List<String> documentIds,
    List<String> fields, {
    bool useCompression = true,
  }) async {
    _log('🔍 Loading selective fields from ${documentIds.length} documents');

    final monitor = PerformanceMonitor();
    monitor.startTimer('multiple_selective_load');

    try {
      final results = <Map<String, dynamic>>[];

      // Process in batches to avoid Firestore limits
      const batchSize = 10;
      for (var i = 0; i < documentIds.length; i += batchSize) {
        final batchIds = documentIds.sublist(
          i,
          i + batchSize > documentIds.length
              ? documentIds.length
              : i + batchSize,
        );

        final batchFutures = batchIds.map(
          (id) => loadFields(
            collection,
            id,
            fields,
            useCompression: useCompression,
          ),
        );

        final batchResults = await Future.wait(batchFutures);
        results.addAll(
          batchResults
              .where((result) => result != null)
              .cast<Map<String, dynamic>>(),
        );
      }

      monitor.trackFirebaseRead(collection, results.length);
      monitor.stopTimer('multiple_selective_load');

      _log('✅ Loaded fields from ${results.length} documents');
      return results;
    } catch (e) {
      monitor.stopTimer('multiple_selective_load');
      _log('❌ Failed to load multiple selective fields: $e');
      rethrow;
    }
  }

  /// Query with selective fields
  Future<List<Map<String, dynamic>>> queryWithFields(
    String collection,
    List<String> fields, {
    Query Function(Query)? queryBuilder,
    int? limit,
    bool useCompression = true,
  }) async {
    _log('🔍 Querying with selective fields: ${fields.join(', ')}');

    final monitor = PerformanceMonitor();
    monitor.startTimer('query_selective_fields');

    try {
      Query query = _firestore.collection(collection);

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final selectedData = <String, dynamic>{};

        for (final field in fields) {
          if (data.containsKey(field)) {
            selectedData[field] = data[field];
          }
        }

        if (selectedData.isNotEmpty) {
          results.add(
            useCompression
                ? _compressionManager.decompress(selectedData)
                : selectedData,
          );
        }
      }

      monitor.trackFirebaseRead(collection, results.length);
      monitor.stopTimer('query_selective_fields');

      _log('✅ Queried ${results.length} documents with selective fields');
      return results;
    } catch (e) {
      monitor.stopTimer('query_selective_fields');
      _log('❌ Failed to query with selective fields: $e');
      rethrow;
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🎯 SELECTIVE: $message');
    }
  }
}

/// Smart data serializer for efficient storage
class SmartDataSerializer {
  final DataCompressionManager _compressionManager = DataCompressionManager();

  /// Serialize data with optimization
  String serialize(
    Map<String, dynamic> data, {
    bool compress = true,
    bool pretty = false,
  }) {
    final processedData = compress ? _compressionManager.compress(data) : data;
    final jsonString = pretty
        ? JsonEncoder.withIndent('  ').convert(processedData)
        : jsonEncode(processedData);

    _log(
      '📝 Serialized data: ${jsonString.length} chars, compressed: $compress',
    );
    return jsonString;
  }

  /// Deserialize data with optimization
  Map<String, dynamic> deserialize(
    String jsonString, {
    bool decompress = true,
  }) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final result = decompress ? _compressionManager.decompress(data) : data;

    _log(
      '📖 Deserialized data: ${result.length} fields, decompressed: $decompress',
    );
    return result;
  }

  /// Calculate data size metrics
  Map<String, dynamic> calculateSizeMetrics(Map<String, dynamic> data) {
    final compressed = _compressionManager.compress(data);
    final originalJson = jsonEncode(data);
    final compressedJson = jsonEncode(compressed);

    final originalSize = originalJson.length;
    final compressedSize = compressedJson.length;
    final compressionRatio = originalSize > 0
        ? compressedSize / originalSize
        : 1.0;
    final savings = originalSize - compressedSize;

    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'savings': savings,
      'savingsPercentage': originalSize > 0
          ? (savings / originalSize * 100)
          : 0,
    };
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('📊 SERIALIZER: $message');
    }
  }
}

/// Firebase data optimizer for automatic optimization
class FirebaseDataOptimizer {
  final DataCompressionManager _compressionManager = DataCompressionManager();
  final SelectiveFieldLoader _selectiveLoader = SelectiveFieldLoader();
  final SmartDataSerializer _serializer = SmartDataSerializer();

  /// Optimize document before saving
  Map<String, dynamic> optimizeForSave(Map<String, dynamic> data) {
    _log('💾 Optimizing document for save');

    // Separate FieldValue objects from regular data
    final fieldValues = <String, FieldValue>{};
    final regularData = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is FieldValue) {
        fieldValues[key] = value;
      } else {
        regularData[key] = value;
      }
    });

    // Only optimize regular data
    Map<String, dynamic> optimizedData;
    if (regularData.isNotEmpty) {
      final metrics = _serializer.calculateSizeMetrics(regularData);
      final shouldCompress =
          metrics['compressionRatio'] < 0.8; // Compress if >20% savings

      if (shouldCompress) {
        optimizedData = _compressionManager.compress(regularData);
        _log(
          '✅ Document optimized: ${(metrics['savingsPercentage'] as double).toStringAsFixed(1)}% size reduction',
        );
      } else {
        _log('ℹ️ Document size acceptable, no compression needed');
        optimizedData = regularData;
      }
    } else {
      optimizedData = {};
    }

    // Merge back FieldValue objects
    optimizedData.addAll(fieldValues);

    return optimizedData;
  }

  /// Optimize document after loading
  Map<String, dynamic> optimizeAfterLoad(Map<String, dynamic> data) {
    _log('📖 Optimizing document after load');

    // Check if data is compressed
    final hasCompressedFields = data.keys.any(
      (key) => _compressionManager._reverseMappings.containsKey(key),
    );

    if (hasCompressedFields) {
      final optimized = _compressionManager.decompress(data);
      _log('✅ Document decompressed for use');
      return optimized;
    } else {
      _log('ℹ️ Document already in readable format');
      return data;
    }
  }

  /// Smart query optimization
  Future<List<Map<String, dynamic>>> smartQuery(
    String collection, {
    List<String>? fields,
    Query Function(Query)? queryBuilder,
    int? limit,
    bool optimizeFields = true,
  }) async {
    _log('🧠 Executing smart query on $collection');

    if (fields != null && optimizeFields) {
      // Use selective field loading
      return _selectiveLoader.queryWithFields(
        collection,
        fields,
        queryBuilder: queryBuilder,
        limit: limit,
      );
    } else {
      // Use regular query
      Query query = FirebaseFirestore.instance.collection(collection);

      if (queryBuilder != null) {
        query = queryBuilder(query);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      _log('✅ Smart query returned ${results.length} documents');
      return results;
    }
  }

  /// Get optimization statistics
  Map<String, dynamic> getOptimizationStats() {
    return {
      'compressionStats': _compressionManager.getCompressionStats(),
      'serializerMetrics': {}, // Could be extended
    };
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('🚀 OPTIMIZER: $message');
    }
  }
}

/// Performance monitor integration
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal();

  final Map<String, DateTime> _timers = {};
  final Map<String, int> _firebaseReads = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  void startTimer(String operation) {
    _timers[operation] = DateTime.now();
  }

  void stopTimer(String operation) {
    final startTime = _timers.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      if (kDebugMode) {
        debugPrint('⏱️ $operation took ${duration.inMilliseconds}ms');
      }
    }
  }

  void trackFirebaseRead(String collection, int count) {
    _firebaseReads[collection] = (_firebaseReads[collection] ?? 0) + count;
  }

  void trackCacheHit(String cacheType) {
    _cacheHits[cacheType] = (_cacheHits[cacheType] ?? 0) + 1;
  }

  void trackCacheMiss(String cacheType) {
    _cacheMisses[cacheType] = (_cacheMisses[cacheType] ?? 0) + 1;
  }

  Map<String, dynamic> getFirebaseSummary() {
    final totalReads = _firebaseReads.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalCacheHits = _cacheHits.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final totalCacheMisses = _cacheMisses.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final cacheHitRate = totalCacheHits + totalCacheMisses > 0
        ? totalCacheHits / (totalCacheHits + totalCacheMisses)
        : 0.0;

    return {
      'total_reads': totalReads,
      'read_breakdown': _firebaseReads,
      'total_cache_hits': totalCacheHits,
      'total_cache_misses': totalCacheMisses,
      'cache_hit_rate': '${(cacheHitRate * 100).toStringAsFixed(1)}%',
      'optimization_score': _calculateOptimizationScore(cacheHitRate),
    };
  }

  double _calculateOptimizationScore(double cacheHitRate) {
    // Score based on cache hit rate (0-100)
    return (cacheHitRate * 100).clamp(0, 100);
  }
}

