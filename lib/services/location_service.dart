import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/district_model.dart';
import '../models/body_model.dart';
import '../models/ward_model.dart';
import '../utils/app_logger.dart';

/// Service responsible for location data management (districts, bodies, wards).
/// Handles caching, fetching, and persistence of location data.
class LocationService {
  late SharedPreferences _prefs;

  static const String _districtsCacheKey = 'cached_districts';
  static const String _bodiesCacheKey = 'cached_bodies';
  static const String _wardsCacheKey = 'cached_wards';
  static const String _cacheTimestampKey = 'location_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Load districts for a given state
  Future<List<District>> loadDistricts(String stateId, {bool forceReload = false}) async {
    AppLogger.core('🏙️ LOCATION SERVICE: Loading districts for state: $stateId');

    // Load from Firestore
    AppLogger.core('🏙️ LOCATION SERVICE: 🔄 Loading districts from Firestore for state: $stateId');
    try {
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .get();

      AppLogger.core('🏙️ LOCATION SERVICE: 📊 Firestore query returned ${districtsSnapshot.docs.length} documents');

      final districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        final district = District.fromJson({'id': doc.id, ...data});
        AppLogger.core('🏙️ LOCATION SERVICE:   - Document ID: ${doc.id}, Data: ${data.toString().substring(0, min(100, data.toString().length))}');
        return district;
      }).toList();

      AppLogger.core('🏙️ LOCATION SERVICE: ✅ Successfully loaded ${districts.length} districts from Firebase');

      return districts;
    } catch (e) {
      AppLogger.core('🏙️ LOCATION SERVICE ERROR: ❌ Error loading districts from Firebase: $e');
      return [];
    }
  }

  /// Load bodies for a specific district
  Future<List<Body>> loadBodiesForDistrict(String stateId, String districtId) async {
    AppLogger.core('🏢 LOCATION SERVICE: Loading bodies for state: $stateId, district: $districtId');

    // Load from Firestore
    AppLogger.core('🏢 LOCATION SERVICE: 🔄 Loading bodies from Firestore for state: $stateId, district: $districtId');
    try {
      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      AppLogger.core('🏢 LOCATION SERVICE: 📊 Firestore query returned ${bodiesSnapshot.docs.length} bodies documents');

      final bodies = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        final body = Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': stateId,
          ...data,
        });
        AppLogger.core('🏢 LOCATION SERVICE:   - Document ID: ${doc.id}, Name: ${body.name ?? 'N/A'}');
        return body;
      }).toList();

      AppLogger.core('🏢 LOCATION SERVICE: ✅ Successfully loaded ${bodies.length} bodies from Firebase for district $districtId');

      return bodies;
    } catch (e) {
      AppLogger.core('🏢 LOCATION SERVICE ERROR: ❌ Error loading bodies from Firebase for district $districtId: $e');
      return [];
    }
  }

  /// Load wards for a specific district and body
  Future<List<Ward>> loadWardsForBody(String stateId, String districtId, String bodyId) async {
    AppLogger.core('🏠 LOCATION SERVICE: Loading wards for state: $stateId, district: $districtId, body: $bodyId');

    // Load from Firestore
    AppLogger.core('🏠 LOCATION SERVICE: 🔄 Loading wards from Firestore for $stateId/$districtId/$bodyId');
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

      AppLogger.core('🏠 LOCATION SERVICE: 📊 Firestore query returned ${wardsSnapshot.docs.length} ward documents');

      final wards = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        final ward = Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
        AppLogger.core('🏠 LOCATION SERVICE:   - Document ID: ${doc.id}, Name: ${ward.name ?? 'N/A'}');
        return ward;
      }).toList();

      AppLogger.core('🏠 LOCATION SERVICE: ✅ Successfully loaded ${wards.length} wards from Firebase for $districtId/$bodyId');

      return wards;
    } catch (e) {
      AppLogger.core('🏠 LOCATION SERVICE ERROR: ❌ Error loading wards from Firebase for $districtId/$bodyId: $e');
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


  /// Clear all location caches
  Future<void> clearCaches() async {
    try {
      await _prefs.remove(_districtsCacheKey);
      await _prefs.remove(_bodiesCacheKey);
      await _prefs.remove(_wardsCacheKey);
      await _prefs.remove(_cacheTimestampKey);

      AppLogger.candidate('🧹 Cleared all location caches');
    } catch (e) {
      AppLogger.candidateError('Error clearing location caches: $e');
    }
  }

  /// Get cache status for debugging
  Future<Map<String, dynamic>> getCacheStatus() async {
    return {
      'cache_validity_hours': _cacheValidityDuration.inHours,
    };
  }
}
