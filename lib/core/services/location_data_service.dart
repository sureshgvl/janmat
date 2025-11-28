import 'package:janmat/models/state_model.dart' as state_model;
import 'package:janmat/models/district_model.dart';
import 'package:janmat/models/body_model.dart';
import 'package:janmat/models/ward_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import 'cache_service.dart';

/// Service for loading location data (states, districts, bodies, wards) with cache-first approach.
/// Used by different screens throughout the app for efficient data retrieval.
/// Profile completion screen uses fresh-only approach to ensure latest data during registration.
class LocationDataService {
  // Singleton pattern
  static final LocationDataService _instance = LocationDataService._internal();
  factory LocationDataService() => _instance;
  LocationDataService._internal();

  /// Load states with cache-first approach - for use by screens other than profile completion
  Future<List<state_model.State>> loadStatesCached() async {
    try {
      AppLogger.common('🔍 [LOCATION_DATA] Loading states (cache-first approach)');

      // Try cache first
      final cachedStatesMap = await CacheService.getData('states');
      if (cachedStatesMap != null) {
        final statesMap = Map<String, Map<String, dynamic>>.from(cachedStatesMap);
        final states = statesMap.values.map((stateData) {
          return state_model.State.fromJson(stateData);
        }).where((state) => state.isActive != false).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${states.length} states from cache');
        return states;
      }

      // Cache miss - load from Firestore and cache
      AppLogger.common('📡 [LOCATION_DATA] States cache miss, loading from Firestore');

      final statesSnapshot = await FirebaseFirestore.instance.collection('states').get();

      if (statesSnapshot.docs.isNotEmpty) {
        final allStatesMap = <String, Map<String, dynamic>>{};

        for (final doc in statesSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          final stateData = {'id': doc.id, ...serializableData};
          allStatesMap[doc.id] = stateData;
        }

        // Cache for future use
        await CacheService.saveData('states', allStatesMap);

        final states = allStatesMap.values.map((stateData) {
          return state_model.State.fromJson(stateData);
        }).where((state) => state.isActive != false).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${states.length} states from Firestore and cached');
        return states;
      }

      return [];
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to load states', error: e);
      return [];
    }
  }

  /// Load districts for a specific state with cache-first approach
  Future<List<District>> loadDistrictsForStateCached(String stateId) async {
    try {
      AppLogger.common('🔍 [LOCATION_DATA] Loading districts for state: $stateId (cache-first)');

      // Try cache first
      final cacheKey = 'districts_$stateId';
      final cachedDistrictsMap = await CacheService.getData(cacheKey);
      if (cachedDistrictsMap != null) {
        final districtsMap = Map<String, Map<String, dynamic>>.from(cachedDistrictsMap);
        final districts = districtsMap.values.map((districtData) {
          return District.fromJson(districtData);
        }).where((district) => district.isActive != false).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${districts.length} districts from cache for state $stateId');
        return districts;
      }

      // Cache miss - load from Firestore
      AppLogger.common('📡 [LOCATION_DATA] Districts cache miss for state $stateId, loading from Firestore');

      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .get();

      if (districtsSnapshot.docs.isNotEmpty) {
        final allDistrictsMap = <String, Map<String, dynamic>>{};

        for (final doc in districtsSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          final districtData = {'id': doc.id, 'stateId': stateId, ...serializableData};
          allDistrictsMap[doc.id] = districtData;
        }

        // Cache for future use
        await CacheService.saveData(cacheKey, allDistrictsMap);

        final districts = allDistrictsMap.values.map((districtData) {
          return District.fromJson(districtData);
        }).where((district) => district.isActive != false).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${districts.length} districts from Firestore and cached for state $stateId');
        return districts;
      }

      return [];
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to load districts for state $stateId', error: e);
      return [];
    }
  }

  /// Load bodies for a specific district with cache-first approach
  Future<List<Body>> loadBodiesForDistrictCached(String stateId, String districtId) async {
    try {
      AppLogger.common('🔍 [LOCATION_DATA] Loading bodies for district: $districtId (cache-first)');

      // Try cache first
      final cacheKey = 'bodies_${stateId}_${districtId}';
      final cachedBodiesMap = await CacheService.getData(cacheKey);
      if (cachedBodiesMap != null) {
        final bodiesMap = Map<String, Map<String, dynamic>>.from(cachedBodiesMap);
        final bodies = bodiesMap.values.map((bodyData) {
          return Body.fromJson(bodyData);
        }).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${bodies.length} bodies from cache for district $districtId');
        return bodies;
      }

      // Cache miss - load from Firestore
      AppLogger.common('📡 [LOCATION_DATA] Bodies cache miss for district $districtId, loading from Firestore');

      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      if (bodiesSnapshot.docs.isNotEmpty) {
        final allBodiesMap = <String, Map<String, dynamic>>{};

        for (final doc in bodiesSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          final bodyData = {
            'id': doc.id,
            'districtId': districtId,
            'stateId': stateId,
            ...serializableData,
          };
          allBodiesMap[doc.id] = bodyData;
        }

        // Cache for future use
        await CacheService.saveData(cacheKey, allBodiesMap);

        final bodies = allBodiesMap.values.map((bodyData) {
          return Body.fromJson(bodyData);
        }).toList();

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${bodies.length} bodies from Firestore and cached for district $districtId');
        return bodies;
      }

      return [];
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to load bodies for district $districtId', error: e);
      return [];
    }
  }

  /// Load wards for a specific body with cache-first approach
  Future<List<Ward>> loadWardsForBodyCached(String stateId, String districtId, String bodyId) async {
    try {
      AppLogger.common('🔍 [LOCATION_DATA] Loading wards for body: $bodyId (cache-first)');

      // Try cache first
      final cacheKey = 'wards_${stateId}_${districtId}_${bodyId}';
      final cachedWardsMap = await CacheService.getData(cacheKey);
      if (cachedWardsMap != null) {
        final wardsMap = Map<String, Map<String, dynamic>>.from(cachedWardsMap);
        final wards = wardsMap.values.map((wardData) {
          return Ward.fromJson(wardData);
        }).toList();

        // Sort wards by ward number
        wards.sort((a, b) {
          final aNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(a.id.toLowerCase())?.group(1) ?? '0') ?? 0;
          final bNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(b.id.toLowerCase())?.group(1) ?? '0') ?? 0;
          return aNumber.compareTo(bNumber);
        });

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${wards.length} wards from cache for body $bodyId');
        return wards;
      }

      // Cache miss - load from Firestore
      AppLogger.common('📡 [LOCATION_DATA] Wards cache miss for body $bodyId, loading from Firestore');

      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      if (wardsSnapshot.docs.isNotEmpty) {
        final allWardsMap = <String, Map<String, dynamic>>{};

        for (final doc in wardsSnapshot.docs) {
          final data = doc.data();
          // Remove Timestamp fields that can't be serialized to cache
          final serializableData = Map<String, dynamic>.from(data);
          serializableData.remove('createdAt');
          serializableData.remove('updatedAt');
          final wardData = {
            ...serializableData,
            'id': doc.id,
            'districtId': districtId,
            'bodyId': bodyId,
            'stateId': stateId,
          };
          allWardsMap[doc.id] = wardData;
        }

        // Cache for future use
        await CacheService.saveData(cacheKey, allWardsMap);

        final wards = allWardsMap.values.map((wardData) {
          return Ward.fromJson(wardData);
        }).toList();

        // Sort wards by ward number
        wards.sort((a, b) {
          final aNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(a.id.toLowerCase())?.group(1) ?? '0') ?? 0;
          final bNumber = int.tryParse(RegExp(r'ward_(\d+)').firstMatch(b.id.toLowerCase())?.group(1) ?? '0') ?? 0;
          return aNumber.compareTo(bNumber);
        });

        AppLogger.common('✅ [LOCATION_DATA] Loaded ${wards.length} wards from Firestore and cached for body $bodyId');
        return wards;
      }

      return [];
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to load wards for body $bodyId', error: e);
      return [];
    }
  }

  /// Get a specific state by ID with cache-first approach
  Future<state_model.State?> getStateById(String stateId) async {
    try {
      final states = await loadStatesCached();
      return states.firstWhere((state) => state.id == stateId);
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to get state by ID: $stateId', error: e);
      return null;
    }
  }

  /// Get a specific district by ID with cache-first approach
  Future<District?> getDistrictById(String stateId, String districtId) async {
    try {
      final districts = await loadDistrictsForStateCached(stateId);
      return districts.firstWhere((district) => district.id == districtId);
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to get district by ID: $districtId', error: e);
      return null;
    }
  }

  /// Get a specific body by ID with cache-first approach
  Future<Body?> getBodyById(String stateId, String districtId, String bodyId) async {
    try {
      final bodies = await loadBodiesForDistrictCached(stateId, districtId);
      return bodies.firstWhere((body) => body.id == bodyId);
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to get body by ID: $bodyId', error: e);
      return null;
    }
  }

  /// Get a specific ward by ID with cache-first approach
  Future<Ward?> getWardById(String stateId, String districtId, String bodyId, String wardId) async {
    try {
      final wards = await loadWardsForBodyCached(stateId, districtId, bodyId);
      return wards.firstWhere((ward) => ward.id == wardId);
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to get ward by ID: $wardId', error: e);
      return null;
    }
  }

  /// Resolve location names from IDs - useful for displaying location info when names are not available
  Future<String> resolveLocationNames(String stateId, String districtId, String bodyId, String wardId) async {
    try {
      final locationParts = <String>[];

      // Get state name
      final state = await getStateById(stateId);
      if (state != null) {
        locationParts.add(state.name);
      }

      // Get district name
      final district = await getDistrictById(stateId, districtId);
      if (district != null) {
        locationParts.add(district.name);
      }

      // Get body name
      final body = await getBodyById(stateId, districtId, bodyId);
      if (body != null) {
        locationParts.add(body.name);
      }

      // Get ward name (or fallback to ID if name not available)
      final ward = await getWardById(stateId, districtId, bodyId, wardId);
      if (ward != null && ward.name.isNotEmpty) {
        locationParts.add(ward.name);
      } else {
        locationParts.add(wardId); // Fallback to ID
      }

      return locationParts.join(', ');
    } catch (e) {
      AppLogger.commonError('❌ [LOCATION_DATA] Failed to resolve location names', error: e);
      return '$stateId, $districtId, $bodyId, $wardId'; // Fallback to IDs
    }
  }

  /// Get location display name - returns ward name if available, or full location path
  Future<String> getLocationDisplayName({
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    final ward = await getWardById(stateId, districtId, bodyId, wardId);
    if (ward != null && ward.name.isNotEmpty) {
      return ward.name;
    }

    // If ward name not available, get full location path
    return resolveLocationNames(stateId, districtId, bodyId, wardId);
  }
}
