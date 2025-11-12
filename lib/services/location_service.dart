import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/district_model.dart';
import '../models/body_model.dart';
import '../models/ward_model.dart';
import 'local_database_service.dart';
import '../utils/app_logger.dart';

/// Service responsible for location data management (districts, bodies, wards).
/// Handles caching, fetching, and persistence of location data.
class LocationService {
  final LocalDatabaseService _localDatabase = LocalDatabaseService();
  late SharedPreferences _prefs;

  static const String _districtsCacheKey = 'cached_districts';
  static const String _bodiesCacheKey = 'cached_bodies';
  static const String _wardsCacheKey = 'cached_wards';
  static const String _cacheTimestampKey = 'location_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Load districts for a given state, with caching support
  Future<List<District>> loadDistricts(String stateId) async {
    // Try SQLite cache first
    final cachedDistricts = await _loadDistrictsFromSQLite(stateId);
    if (cachedDistricts.isNotEmpty) {
      AppLogger.candidate('⚡ CACHE HIT: Loaded ${cachedDistricts.length} districts from SQLite');
      return cachedDistricts;
    }

    // Cache miss - load from Firestore
    AppLogger.candidate('🔄 Loading districts from Firestore for state: $stateId');
    try {
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .get();

      final districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({'id': doc.id, ...data});
      }).toList();

      AppLogger.candidate('✅ Loaded ${districts.length} districts from Firebase');

      // Cache in SQLite for future use
      await _localDatabase.insertDistricts(districts);

      return districts;
    } catch (e) {
      AppLogger.candidateError('Error loading districts from Firebase: $e');
      return [];
    }
  }

  /// Load bodies for a specific district
  Future<List<Body>> loadBodiesForDistrict(String stateId, String districtId) async {
    // Try SQLite cache first
    final cachedBodies = await _loadBodiesFromSQLite(districtId);
    if (cachedBodies.isNotEmpty) {
      AppLogger.candidate('⚡ CACHE HIT: Loaded ${cachedBodies.length} bodies from SQLite for district $districtId');
      return cachedBodies;
    }

    // Cache miss - load from Firestore
    AppLogger.candidate('🔄 Loading bodies from Firestore for district: $districtId');
    try {
      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      final bodies = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': stateId,
          ...data,
        });
      }).toList();

      AppLogger.candidate('✅ Loaded ${bodies.length} bodies from Firebase for district $districtId');

      // Cache in SQLite
      await _localDatabase.insertBodies(bodies);

      return bodies;
    } catch (e) {
      AppLogger.candidateError('Error loading bodies for district $districtId: $e');
      return [];
    }
  }

  /// Load wards for a specific district and body
  Future<List<Ward>> loadWardsForBody(String stateId, String districtId, String bodyId) async {
    final cacheKey = '${districtId}_$bodyId';

    // Try SQLite cache first
    final cachedWards = await _loadWardsFromSQLite(districtId, bodyId, cacheKey);
    if (cachedWards.isNotEmpty) {
      AppLogger.candidate('⚡ CACHE HIT: Loaded ${cachedWards.length} wards from SQLite for $districtId/$bodyId');
      return cachedWards;
    }

    // Cache miss - load from Firestore
    AppLogger.candidate('🔄 Loading wards from Firestore for $districtId/$bodyId');
    try {
      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
      }).toList();

      AppLogger.candidate('✅ Loaded ${wards.length} wards from Firebase for $districtId/$bodyId');

      // Cache in SQLite
      await _localDatabase.insertWards(wards);

      return wards;
    } catch (e) {
      AppLogger.candidateError('Error loading wards for $districtId/$bodyId: $e');
      return [];
    }
  }

  /// Check if location cache is valid
  bool _isCacheValid() {
    final timestamp = _prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  /// Load districts from SQLite cache
  Future<List<District>> _loadDistrictsFromSQLite(String stateId) async {
    try {
      // Check cache validity
      final lastUpdate = await _localDatabase.getLastUpdateTime('districts');
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      if (!isCacheValid) {
        AppLogger.candidate('🔄 Districts cache expired or missing');
        return [];
      }

      final db = await _localDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.districtsTable,
        where: 'stateId = ?',
        whereArgs: [stateId],
      );

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 No districts found in SQLite for state: $stateId');
        return [];
      }

      final districts = maps.map((map) => District.fromJson(map)).toList();
      AppLogger.candidate('✅ CACHE HIT: Loaded ${districts.length} districts from SQLite for state: $stateId');

      return districts;
    } catch (e) {
      AppLogger.candidateError('Error loading districts from SQLite: $e');
      return [];
    }
  }

  /// Load bodies from SQLite cache
  Future<List<Body>> _loadBodiesFromSQLite(String districtId) async {
    try {
      // Check cache validity
      final lastUpdate = await _localDatabase.getLastUpdateTime('bodies');
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      if (!isCacheValid) {
        AppLogger.candidate('🔄 Bodies cache expired or missing');
        return [];
      }

      final db = await _localDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.bodiesTable,
        where: 'districtId = ?',
        whereArgs: [districtId],
      );

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 No bodies found in SQLite for district: $districtId');
        return [];
      }

      final bodies = maps.map((map) => Body.fromJson(map)).toList();
      AppLogger.candidate('✅ CACHE HIT: Loaded ${bodies.length} bodies from SQLite for district: $districtId');

      return bodies;
    } catch (e) {
      AppLogger.candidateError('Error loading bodies from SQLite: $e');
      return [];
    }
  }

  /// Load wards from SQLite cache
  Future<List<Ward>> _loadWardsFromSQLite(String districtId, String bodyId, String cacheKey) async {
    try {
      // Check cache validity
      final lastUpdate = await _localDatabase.getLastUpdateTime('wards');
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      if (!isCacheValid) {
        AppLogger.candidate('🔄 Wards cache expired or missing');
        return [];
      }

      final db = await _localDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.wardsTable,
        where: 'districtId = ? AND bodyId = ?',
        whereArgs: [districtId, bodyId],
      );

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 No wards found in SQLite for $districtId/$bodyId');
        return [];
      }

      final wards = maps.map((map) => Ward.fromJson(map)).toList();
      AppLogger.candidate('✅ CACHE HIT: Loaded ${wards.length} wards from SQLite for $districtId/$bodyId');

      return wards;
    } catch (e) {
      AppLogger.candidateError('Error loading wards from SQLite: $e');
      return [];
    }
  }

  /// Clear all location caches
  Future<void> clearCaches() async {
    try {
      await _prefs.remove(_districtsCacheKey);
      await _prefs.remove(_bodiesCacheKey);
      await _prefs.remove(_wardsCacheKey);
      await _prefs.remove(_cacheTimestampKey);

      // Clear SQLite caches
      final db = await _localDatabase.database;
      await db.delete(LocalDatabaseService.districtsTable);
      await db.delete(LocalDatabaseService.bodiesTable);
      await db.delete(LocalDatabaseService.wardsTable);

      AppLogger.candidate('🧹 Cleared all location caches');
    } catch (e) {
      AppLogger.candidateError('Error clearing location caches: $e');
    }
  }

  /// Get cache status for debugging
  Future<Map<String, dynamic>> getCacheStatus() async {
    final districtsLastUpdate = await _localDatabase.getLastUpdateTime('districts');
    final bodiesLastUpdate = await _localDatabase.getLastUpdateTime('bodies');
    final wardsLastUpdate = await _localDatabase.getLastUpdateTime('wards');

    return {
      'districts_cache_age': districtsLastUpdate != null
          ? DateTime.now().difference(districtsLastUpdate).inMinutes
          : null,
      'bodies_cache_age': bodiesLastUpdate != null
          ? DateTime.now().difference(bodiesLastUpdate).inMinutes
          : null,
      'wards_cache_age': wardsLastUpdate != null
          ? DateTime.now().difference(wardsLastUpdate).inMinutes
          : null,
      'cache_validity_hours': _cacheValidityDuration.inHours,
    };
  }
}
