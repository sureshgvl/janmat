// lib/core/services/cache_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A comprehensive caching service that works across web and mobile platforms.
/// Provides caching for both structured data (via Hive) and media files (via flutter_cache_manager).
class CacheService {
  static const String _structuredDataBox = 'structured_data_box';
  static const String _userPreferencesBox = 'user_preferences_box';
  static const String _mediaCacheBox = 'media_cache_box';

  // Cache expiration times
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  static const Duration _mediaCacheExpiry = Duration(days: 7);
  static const Duration _userDataCacheExpiry = Duration(hours: 12);

  /// Initialize all caching services
  static Future<void> initialize() async {
    try {
      // Initialize Hive for structured data caching
      await Hive.initFlutter();
      
      // Open boxes for different data types
      await Future.wait([
        Hive.openBox(_structuredDataBox),
        Hive.openBox(_userPreferencesBox),
        Hive.openBox(_mediaCacheBox),
      ]);

      debugPrint('CacheService: All caching services initialized successfully');
    } catch (e) {
      debugPrint('CacheService: Initialization error: $e');
      rethrow;
    }
  }

  // ================================
  // STRUCTURED DATA CACHING (Hive)
  // ================================

  /// Save structured data (candidate info, manifesto, etc.)
  static Future<void> saveData(String key, Map<String, dynamic> data, {String? boxName}) async {
    try {
      final boxNameToUse = boxName ?? _structuredDataBox;
      final box = Hive.box(boxNameToUse);
      
      // Add timestamp for cache invalidation
      final dataWithTimestamp = {
        ...data,
        '_cachedAt': DateTime.now().toIso8601String(),
        '_cacheExpiry': _defaultCacheExpiry.inMilliseconds,
      };
      
      await box.put(key, dataWithTimestamp);
      debugPrint('CacheService: Saved structured data for key: $key');
    } catch (e) {
      debugPrint('CacheService: Save data error for key $key: $e');
      rethrow;
    }
  }

  /// Retrieve structured data
  static Future<Map<String, dynamic>?> getData(String key, {String? boxName, Duration? maxAge}) async {
    try {
      final boxNameToUse = boxName ?? _structuredDataBox;
      final box = Hive.box(boxNameToUse);
      
      final cached = box.get(key);
      if (cached == null) {
        debugPrint('CacheService: No cached data found for key: $key');
        return null;
      }

      final data = Map<String, dynamic>.from(cached as Map);
      final cachedAt = DateTime.tryParse(data['_cachedAt'] ?? '');
      final cacheExpiry = Duration(milliseconds: data['_cacheExpiry'] ?? _defaultCacheExpiry.inMilliseconds);
      final maxAgeToUse = maxAge ?? cacheExpiry;

      if (cachedAt == null) {
        return data;
      }

      final age = DateTime.now().difference(cachedAt);
      if (age > maxAgeToUse) {
        debugPrint('CacheService: Cached data expired for key: $key');
        await box.delete(key);
        return null;
      }

      // Remove internal cache metadata before returning
      data.remove('_cachedAt');
      data.remove('_cacheExpiry');
      
      debugPrint('CacheService: Retrieved cached data for key: $key (age: ${age.inMinutes}min)');
      return data;
    } catch (e) {
      debugPrint('CacheService: Get data error for key $key: $e');
      return null;
    }
  }

  /// Delete cached data
  static Future<void> deleteData(String key, {String? boxName}) async {
    try {
      final boxNameToUse = boxName ?? _structuredDataBox;
      final box = Hive.box(boxNameToUse);
      await box.delete(key);
      debugPrint('CacheService: Deleted cached data for key: $key');
    } catch (e) {
      debugPrint('CacheService: Delete data error for key $key: $e');
      rethrow;
    }
  }

  /// Clear all cached structured data
  static Future<void> clearStructuredData({String? boxName}) async {
    try {
      final boxNameToUse = boxName ?? _structuredDataBox;
      final box = Hive.box(boxNameToUse);
      await box.clear();
      debugPrint('CacheService: Cleared all structured data from $boxNameToUse');
    } catch (e) {
      debugPrint('CacheService: Clear structured data error: $e');
      rethrow;
    }
  }

  // ================================
  // USER PREFERENCES CACHING
  // ================================

  /// Save user preferences (language, theme, settings)
  static Future<void> saveUserPreference(String key, dynamic value) async {
    try {
      final box = Hive.box(_userPreferencesBox);
      await box.put(key, value);
      debugPrint('CacheService: Saved user preference: $key');
    } catch (e) {
      debugPrint('CacheService: Save user preference error for $key: $e');
      rethrow;
    }
  }

  /// Get user preference
  static T? getUserPreference<T>(String key) {
    try {
      final box = Hive.box(_userPreferencesBox);
      final value = box.get(key);
      debugPrint('CacheService: Retrieved user preference: $key');
      return value as T?;
    } catch (e) {
      debugPrint('CacheService: Get user preference error for $key: $e');
      return null;
    }
  }

  // ================================
  // MEDIA CACHING (flutter_cache_manager)
  // ================================

  /// Cache media file from URL
  static Future<String?> cacheMediaFromUrl(String url, {String? key}) async {
    try {
      final cacheManager = DefaultCacheManager();
      final file = await cacheManager.getSingleFile(url);
      
      // Store cache info for management
      final cacheBox = Hive.box(_mediaCacheBox);
      final cacheKey = key ?? url;
      await cacheBox.put(cacheKey, {
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
        'expiry': _mediaCacheExpiry.inMilliseconds,
      });
      
      debugPrint('CacheService: Cached media from URL: $url');
      return url; // Return URL for reference
    } catch (e) {
      debugPrint('CacheService: Cache media error for URL $url: $e');
      return null;
    }
  }

  /// Get cached media file path - Simple approach that works with flutter_cache_manager
  static Future<String?> getCachedMediaPath(String url, {String? key}) async {
    try {
      // flutter_cache_manager handles caching automatically, just return the URL
      debugPrint('CacheService: Requesting media for URL: $url');
      return url; // Return URL for reference
    } catch (e) {
      debugPrint('CacheService: Get cached media error for URL $url: $e');
      return null;
    }
  }

  /// Clear expired media cache
  static Future<void> clearExpiredMediaCache() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      
      // Clear media cache tracking data
      final cacheBox = Hive.box(_mediaCacheBox);
      final now = DateTime.now();
      
      final keysToDelete = <String>[];
      for (final key in cacheBox.keys) {
        final data = cacheBox.get(key) as Map?;
        if (data != null) {
          final cachedAt = DateTime.tryParse(data['cachedAt'] ?? '');
          final expiry = Duration(milliseconds: data['expiry'] ?? _mediaCacheExpiry.inMilliseconds);
          
          if (cachedAt != null && now.difference(cachedAt) > expiry) {
            keysToDelete.add(key.toString());
          }
        }
      }
      
      for (final key in keysToDelete) {
        await cacheBox.delete(key);
      }
      
      debugPrint('CacheService: Cleared ${keysToDelete.length} expired media cache entries');
    } catch (e) {
      debugPrint('CacheService: Clear expired media cache error: $e');
      rethrow;
    }
  }

  // ================================
  // CANDIDATE-SPECIFIC CACHING
  // ================================

  /// Cache candidate basic information
  static Future<void> saveCandidateInfo(String candidateId, Map<String, dynamic> candidateInfo) async {
    final key = 'candidate_$candidateId';
    await saveData(key, candidateInfo, boxName: _structuredDataBox);
  }

  /// Get cached candidate information
  static Future<Map<String, dynamic>?> getCachedCandidateInfo(String candidateId) async {
    final key = 'candidate_$candidateId';
    return await getData(key, boxName: _structuredDataBox, maxAge: _userDataCacheExpiry);
  }

  /// Cache candidate manifesto
  static Future<void> saveCandidateManifesto(String candidateId, Map<String, dynamic> manifesto) async {
    final key = 'manifesto_$candidateId';
    await saveData(key, manifesto, boxName: _structuredDataBox);
  }

  /// Get cached candidate manifesto
  static Future<Map<String, dynamic>?> getCachedCandidateManifesto(String candidateId) async {
    final key = 'manifesto_$candidateId';
    return await getData(key, boxName: _structuredDataBox, maxAge: _userDataCacheExpiry);
  }

  // ================================
  // CACHE MANAGEMENT
  // ================================

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final structuredBox = Hive.box(_structuredDataBox);
      final preferencesBox = Hive.box(_userPreferencesBox);
      final mediaBox = Hive.box(_mediaCacheBox);
      
      return {
        'structured_data_count': structuredBox.length,
        'user_preferences_count': preferencesBox.length,
        'media_cache_count': mediaBox.length,
        'cache_service_version': '1.0.0',
      };
    } catch (e) {
      debugPrint('CacheService: Get cache stats error: $e');
      return {};
    }
  }

  /// Clear all caches (nuclear option)
  static Future<void> clearAllCaches() async {
    try {
      await Future.wait([
        clearStructuredData(),
        clearExpiredMediaCache(),
        Hive.box(_userPreferencesBox).clear(),
      ]);
      
      debugPrint('CacheService: All caches cleared successfully');
    } catch (e) {
      debugPrint('CacheService: Clear all caches error: $e');
      rethrow;
    }
  }
}
