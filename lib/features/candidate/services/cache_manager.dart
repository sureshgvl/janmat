import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../../services/local_database_service.dart';
import '../../../utils/app_logger.dart';

/// Unified cache manager for location and candidate data.
/// Handles both SQLite and SharedPreferences caching strategies.
class CacheManager {
  final LocalDatabaseService _localDatabase = LocalDatabaseService();
  late SharedPreferences _prefs;

  static const Duration _defaultCacheValidity = Duration(hours: 24);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if cache is valid for a given key
  Future<bool> isCacheValid(String cacheKey, {Duration? validityDuration}) async {
    final duration = validityDuration ?? _defaultCacheValidity;
    final lastUpdate = await _localDatabase.getLastUpdateTime(cacheKey);

    if (lastUpdate == null) return false;

    final isValid = DateTime.now().difference(lastUpdate) < duration;
    AppLogger.candidate('Cache validation for "$cacheKey": ${isValid ? 'VALID' : 'EXPIRED'} (age: ${DateTime.now().difference(lastUpdate).inMinutes}min)');

    return isValid;
  }

  /// Update cache metadata timestamp
  Future<void> updateCacheTimestamp(String cacheKey) async {
    await _localDatabase.updateCacheMetadata(cacheKey);
    AppLogger.candidate('Updated cache timestamp for: $cacheKey');
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      // Clear SharedPreferences caches
      await _prefs.clear();

      // Clear SQLite caches (selective clearing)
      final db = await _localDatabase.database;
      await db.delete(LocalDatabaseService.districtsTable);
      await db.delete(LocalDatabaseService.bodiesTable);
      await db.delete(LocalDatabaseService.wardsTable);
      await db.delete(LocalDatabaseService.candidatesTable);
      await db.delete(LocalDatabaseService.cacheMetadataTable);

      AppLogger.candidate('🧹 Cleared all caches (SharedPreferences + SQLite)');
    } catch (e) {
      AppLogger.candidateError('Error clearing caches: $e');
    }
  }

  /// Clear location-specific caches
  Future<void> clearLocationCaches() async {
    try {
      // Clear SharedPreferences location caches
      const locationKeys = [
        'cached_districts',
        'cached_bodies',
        'cached_wards',
        'location_cache_timestamp',
      ];

      for (final key in locationKeys) {
        await _prefs.remove(key);
      }

      // Clear SQLite location caches
      final db = await _localDatabase.database;
      await db.delete(LocalDatabaseService.districtsTable);
      await db.delete(LocalDatabaseService.bodiesTable);
      await db.delete(LocalDatabaseService.wardsTable);

      AppLogger.candidate('🧹 Cleared location caches');
    } catch (e) {
      AppLogger.candidateError('Error clearing location caches: $e');
    }
  }

  /// Clear candidate-specific caches
  Future<void> clearCandidateCaches() async {
    try {
      final db = await _localDatabase.database;
      await db.delete(LocalDatabaseService.candidatesTable);

      // Clear candidate-related cache metadata
      final metadataToRemove = <String>[];
      final allMetadata = await db.query(LocalDatabaseService.cacheMetadataTable);
      for (final row in allMetadata) {
        final key = row['cache_key'] as String;
        if (key.startsWith('candidates_')) {
          metadataToRemove.add(key);
        }
      }

      for (final key in metadataToRemove) {
        await db.delete(
          LocalDatabaseService.cacheMetadataTable,
          where: 'cache_key = ?',
          whereArgs: [key],
        );
      }

      AppLogger.candidate('🧹 Cleared candidate caches');
    } catch (e) {
      AppLogger.candidateError('Error clearing candidate caches: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final db = await _localDatabase.database;

      final districtCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.districtsTable}'),
      ) ?? 0;

      final bodyCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.bodiesTable}'),
      ) ?? 0;

      final wardCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.wardsTable}'),
      ) ?? 0;

      final candidateCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.candidatesTable}'),
      ) ?? 0;

      final metadataCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.cacheMetadataTable}'),
      ) ?? 0;

      // Get SharedPreferences stats
      final prefsKeys = _prefs.getKeys();
      final prefsDataSize = prefsKeys.length;

      return {
        'sqlite_stats': {
          'districts': districtCount,
          'bodies': bodyCount,
          'wards': wardCount,
          'candidates': candidateCount,
          'metadata_entries': metadataCount,
        },
        'shared_prefs_stats': {
          'keys_count': prefsDataSize,
          'sample_keys': prefsKeys.take(5).toList(),
        },
        'cache_validity_hours': _defaultCacheValidity.inHours,
      };
    } catch (e) {
      AppLogger.candidateError('Error getting cache stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Force refresh cache for a specific key
  Future<void> invalidateCache(String cacheKey) async {
    try {
      final db = await _localDatabase.database;
      await db.delete(
        LocalDatabaseService.cacheMetadataTable,
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
      );

      // Also remove from SharedPreferences if it's a location cache
      if (cacheKey.contains('location') || cacheKey.contains('district') ||
          cacheKey.contains('body') || cacheKey.contains('ward')) {
        await _prefs.remove(cacheKey);
      }

      AppLogger.candidate('Invalidated cache for key: $cacheKey');
    } catch (e) {
      AppLogger.candidateError('Error invalidating cache for $cacheKey: $e');
    }
  }

  /// Get last update time for a cache key
  Future<DateTime?> getLastUpdateTime(String cacheKey) async {
    return await _localDatabase.getLastUpdateTime(cacheKey);
  }

  /// Check if any location data is cached
  Future<bool> hasLocationData() async {
    try {
      final db = await _localDatabase.database;

      final districtCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.districtsTable}'),
      ) ?? 0;

      final bodyCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.bodiesTable}'),
      ) ?? 0;

      final wardCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${LocalDatabaseService.wardsTable}'),
      ) ?? 0;

      return districtCount > 0 || bodyCount > 0 || wardCount > 0;
    } catch (e) {
      AppLogger.candidateError('Error checking location data: $e');
      return false;
    }
  }

  /// Get cache size estimate (in KB)
  Future<double> getCacheSizeEstimate() async {
    try {
      final stats = await getCacheStats();
      final sqliteStats = stats['sqlite_stats'] as Map<String, dynamic>;

      // Rough estimate: each record ~1KB
      final totalRecords = sqliteStats.values.fold<int>(0, (sum, count) => sum + (count as int));

      // Add SharedPreferences size estimate
      final prefsSize = (stats['shared_prefs_stats'] as Map<String, dynamic>)['keys_count'] as int;

      return (totalRecords + prefsSize) * 1.0; // KB estimate
    } catch (e) {
      AppLogger.candidateError('Error estimating cache size: $e');
      return 0.0;
    }
  }
}
