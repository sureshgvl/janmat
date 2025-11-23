import 'dart:convert';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/state_model.dart' as state_model;
import '../../../utils/app_logger.dart';

class LocationController extends GetxController {
  late SharedPreferences _prefs;
  bool _isFirstLoad = true; // Track if this is first load after app restart

  // Reactive state
  final RxString selectedStateId = 'maharashtra'.obs;
  final Rx<String?> selectedDistrictId = Rx<String?>(null);
  final Rx<String?> selectedBodyId = Rx<String?>(null);
  final Rx<Ward?> selectedWard = Rx<Ward?>(null);

  // Data collections
  final RxList<state_model.State> states = <state_model.State>[].obs;
  final RxList<District> districts = <District>[].obs;
  final RxMap<String, List<Body>> districtBodies = <String, List<Body>>{}.obs;
  final RxMap<String, List<Ward>> bodyWards = <String, List<Ward>>{}.obs;

  // Loading states
  final RxBool isLoadingStates = true.obs;
  final RxBool isLoadingDistricts = true.obs;
  final RxBool isLoadingBodies = false.obs;
  final RxBool isLoadingWards = false.obs;

  // Error states
  final Rx<String?> statesError = Rx<String?>(null);
  final Rx<String?> districtsError = Rx<String?>(null);
  final Rx<String?> bodiesError = Rx<String?>(null);
  final Rx<String?> wardsError = Rx<String?>(null);

  // Cache keys
  static const String _districtsCacheKey = 'location_districts';
  static const String _districtCacheTimeKey = 'location_districts_time';
  static const String _bodiesCacheKey = 'location_bodies';
  static const String _wardsCacheKey = 'location_wards';
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  @override
  void onClose() {
    // Clear reactive state
    selectedStateId.close();
    selectedDistrictId?.close();
    selectedBodyId?.close();
    selectedWard.close();
    states.close();
    districts.close();
    districtBodies.close();
    bodyWards.close();
    isLoadingStates.close();
    isLoadingDistricts.close();
    isLoadingBodies.close();
    isLoadingWards.close();
    statesError?.close();
    districtsError?.close();
    bodiesError?.close();
    wardsError?.close();
    super.onClose();
  }

  /// Initialize the SharedPreferences and load initial data
  Future<void> initialize() async {
    try {
      AppLogger.core('🚀 LOCATION CONTROLLER: Initializing LocationController');
      AppLogger.core('🚀 LOCATION CONTROLLER: Default state: ${selectedStateId.value}');
      _prefs = await SharedPreferences.getInstance();
      AppLogger.core('🚀 LOCATION CONTROLLER: SharedPreferences initialized');
      await loadStates();
      await loadDistricts();
      _isFirstLoad = false; // Mark as initialized
      AppLogger.core('🚀 LOCATION CONTROLLER: Initialization complete');
    } catch (e) {
      AppLogger.core('🚀 LOCATION CONTROLLER ERROR: Failed to initialize: $e');
      statesError?.value = 'Failed to initialize: $e';
      districtsError?.value = 'Failed to initialize: $e';
      isLoadingStates.value = false;
      isLoadingDistricts.value = false;
    }
  }

  /// Load all states
  Future<void> loadStates() async {
    isLoadingStates.value = true;
    statesError?.value = null;

    try {
      final statesSnapshot = await FirebaseFirestore.instance.collection('states').get();

      final loadedStates = statesSnapshot.docs.map((doc) {
        final data = doc.data();
        return state_model.State.fromJson({'id': doc.id, ...data});
      }).toList();

      // Filter out inactive states
      final activeStates = loadedStates.where((state) => state.isActive != false).toList();

      states.assignAll(activeStates);
      AppLogger.core('🏛️ LOCATION CONTROLLER: Loaded ${activeStates.length} active states');
    } catch (e) {
      AppLogger.core('🏛️ LOCATION CONTROLLER ERROR: Failed to load states: $e');
      statesError?.value = 'Failed to load states: $e';
      states.clear();
    } finally {
      isLoadingStates.value = false;
    }
  }

  /// Load districts for the current state with caching
  Future<void> loadDistricts() async {
    isLoadingDistricts.value = true;
    districtsError?.value = null;

    try {
      List<District> loadedDistricts = [];

      // Check cache if this is not first load
      if (!_isFirstLoad) {
        AppLogger.core('🏙️ LOCATION CONTROLLER: Checking cache for districts...');
        final cachedJson = _prefs.getString(_districtsCacheKey);
        final cacheTime = _prefs.getInt(_districtCacheTimeKey);

        if (cachedJson != null && cacheTime != null) {
          final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
          final isCacheValid = DateTime.now().difference(lastCacheTime) < _cacheValidityDuration;

          if (isCacheValid) {
            final cachedList = json.decode(cachedJson) as List;
            loadedDistricts = cachedList.map((item) => District.fromJson(item as Map<String, dynamic>)).toList();
            AppLogger.core('🏙️ LOCATION CONTROLLER: ✅ CACHE HIT: Loaded ${loadedDistricts.length} districts from cache');
          } else {
            AppLogger.core('🏙️ LOCATION CONTROLLER: ⏰ CACHE EXPIRED: Removing stale cache');
            await _prefs.remove(_districtsCacheKey);
            await _prefs.remove(_districtCacheTimeKey);
          }
        }
      }

      // Fetch from Firebase if no valid cache or first load
      if (loadedDistricts.isEmpty) {
        AppLogger.core('🏙️ LOCATION CONTROLLER: 🔥 Fetching districts from Firebase...');
        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(selectedStateId.value)
            .collection('districts')
            .get();

        loadedDistricts = districtsSnapshot.docs.map((doc) {
          final data = doc.data();
          return District.fromJson({'id': doc.id, ...data});
        }).toList();

        AppLogger.core('🏙️ LOCATION CONTROLLER: 🔥 Loaded ${loadedDistricts.length} districts from Firebase');

        // If no districts found, try to populate sample districts for Maharashtra
        if (loadedDistricts.isEmpty && selectedStateId.value == 'maharashtra') {
          AppLogger.core('🏙️ LOCATION CONTROLLER: No districts found for Maharashtra, adding sample districts...');
          try {
            await FirebaseFirestore.instance.collection('states').doc('maharashtra').collection('districts').doc('dharashiv').set({
              'name': 'धाराशिव',
              'marathiName': 'धाराशिव',
              'isActive': true,
            });
            AppLogger.core('🏙️ LOCATION CONTROLLER: Added sample district Dharashiv for Maharashtra');

            // Reload after adding sample
            final retrySnapshot = await FirebaseFirestore.instance
                .collection('states')
                .doc(selectedStateId.value)
                .collection('districts')
                .get();

            loadedDistricts = retrySnapshot.docs.map((doc) {
              final data = doc.data();
              return District.fromJson({'id': doc.id, ...data});
            }).toList();
            AppLogger.core('🏙️ LOCATION CONTROLLER: After adding sample, loaded ${loadedDistricts.length} districts');
          } catch (e) {
            AppLogger.core('🏙️ LOCATION CONTROLLER ERROR: Failed to add sample district: $e');
          }
        }

        // Cache the results if we have data
        if (loadedDistricts.isNotEmpty) {
          final districtsJson = json.encode(loadedDistricts.map((d) => d.toJson()).toList());
          await _prefs.setString(_districtsCacheKey, districtsJson);
          await _prefs.setInt(_districtCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
          AppLogger.core('🏙️ LOCATION CONTROLLER: 💾 Cached districts in SharedPreferences');
        }
      }

      // Debug logging to see what districts are loaded
      AppLogger.core('🏙️ LOCATION CONTROLLER: Final districts loaded: ${loadedDistricts.length}');
      for (final district in loadedDistricts.take(5)) { // Limit to first 5 to avoid spam
        AppLogger.core('🏙️   - ${district.id}: ${district.name}, isActive: ${district.isActive}');
      }

      // Filter to only active districts (include districts where isActive is null or true, exclude false)
      final activeDistricts = loadedDistricts.where((district) => district.isActive != false).toList();
      districts.assignAll(activeDistricts);
      AppLogger.core('🏙️ LOCATION CONTROLLER: Filtered to ${activeDistricts.length} active districts');
    } catch (e) {
      AppLogger.core('🏙️ LOCATION CONTROLLER ERROR: Failed to load districts: $e');
      districtsError?.value = 'Failed to load districts: $e';
      districts.clear();
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  /// Load bodies for a specific district with local state caching
  Future<void> loadBodiesForDistrict(String districtId) async {
    if (districtBodies.containsKey(districtId)) {
      AppLogger.core('🏢 LOCATION CONTROLLER: Using cached bodies for district: $districtId');
      return;
    }

    isLoadingBodies.value = true;
    bodiesError?.value = null;

    try {
      AppLogger.core('🏢 LOCATION CONTROLLER: Loading bodies from Firebase for $districtId');

      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId.value)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      final bodies = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': selectedStateId.value,
          ...data,
        });
      }).toList();

      districtBodies[districtId] = bodies;
      AppLogger.core('🏢 LOCATION CONTROLLER: Loaded ${bodies.length} bodies for district: $districtId');
    } catch (e) {
      AppLogger.core('🏢 LOCATION CONTROLLER ERROR: Failed to load bodies for district $districtId: $e');
      bodiesError?.value = 'Failed to load areas: $e';
    } finally {
      isLoadingBodies.value = false;
    }
  }

  /// Load wards for a specific district and body with local state caching
  Future<void> loadWardsForBody(String districtId, String bodyId) async {
    final cacheKey = '${districtId}_$bodyId';

    if (bodyWards.containsKey(cacheKey)) {
      AppLogger.core('🏠 LOCATION CONTROLLER: Using cached wards for $districtId/$bodyId');
      return;
    }

    isLoadingWards.value = true;
    wardsError?.value = null;

    try {
      AppLogger.core('🏠 LOCATION CONTROLLER: Loading wards from Firebase for $districtId/$bodyId');

      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId.value)
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
          'stateId': selectedStateId.value,
        });
      }).toList();

      bodyWards[cacheKey] = wards;
      AppLogger.core('🏠 LOCATION CONTROLLER: Loaded ${wards.length} wards for $districtId/$bodyId');
    } catch (e) {
      AppLogger.core('🏠 LOCATION CONTROLLER ERROR: Failed to load wards for $districtId/$bodyId: $e');
      wardsError?.value = 'Failed to load wards: $e';
    } finally {
      isLoadingWards.value = false;
    }
  }

  /// Select a state and reload districts
  Future<void> selectState(String? stateId) async {
    if (stateId == selectedStateId.value) return;

    selectedStateId.value = stateId ?? 'maharashtra';
    selectedDistrictId?.value = null;
    selectedBodyId?.value = null;
    selectedWard.value = null;

    // Clear dependent data
    districtBodies.clear();
    bodyWards.clear();

    if (stateId != null) {
      await loadDistricts();
    }

    AppLogger.core('🎯 LOCATION CONTROLLER: Selected state: $stateId');
  }

  /// Select a district and load its bodies
  Future<void> selectDistrict(String? districtId) async {
    if (districtId == selectedDistrictId?.value) return;

    selectedDistrictId?.value = districtId;
    selectedBodyId?.value = null;
    selectedWard.value = null;

    // Clear dependent data
    bodyWards.clear();

    if (districtId != null) {
      await loadBodiesForDistrict(districtId);
    }

    AppLogger.core('🎯 LOCATION CONTROLLER: Selected district: $districtId');
  }

  /// Select a body and load its wards
  Future<void> selectBody(String? bodyId) async {
    if (bodyId == selectedBodyId?.value) return;

    selectedBodyId?.value = bodyId;
    selectedWard.value = null;

    if (bodyId != null && selectedDistrictId?.value != null) {
      await loadWardsForBody(selectedDistrictId!.value!, bodyId);
    }

    AppLogger.core('🎯 LOCATION CONTROLLER: Selected body: $bodyId');
  }

  /// Select a ward
  void selectWard(Ward? ward) {
    selectedWard.value = ward;
    AppLogger.core('🎯 LOCATION CONTROLLER: Selected ward: ${ward?.name ?? 'null'}');
  }

  /// Set initial values (useful for deep linking)
  Future<void> setInitialValues({
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // Set district first
      if (districtId != null && districts.any((d) => d.id == districtId)) {
        await selectDistrict(districtId);

        // Set body if provided
        if (bodyId != null && districtBodies[districtId]?.any((b) => b.id == bodyId) == true) {
          await selectBody(bodyId);

          // Set ward if provided
          if (wardId != null) {
            final ward = bodyWards['${districtId}_$bodyId']?.firstWhere(
              (w) => w.id == wardId,
              orElse: () => Ward(id: '', name: '', areas: [], districtId: '', bodyId: '', stateId: ''),
            );
            if (ward != null && ward.id.isNotEmpty) {
              selectWard(ward);
            }
          }
        }
      }

      AppLogger.core('🎯 LOCATION CONTROLLER: Set initial location values: district=$districtId, body=$bodyId, ward=$wardId');
    } catch (e) {
      AppLogger.core('🎯 LOCATION CONTROLLER ERROR: Failed to set initial values: $e');
    }
  }

  /// Clear all selections
  void clearSelections() {
    selectedDistrictId?.value = null;
    selectedBodyId?.value = null;
    selectedWard.value = null;
    bodyWards.clear();

    // Clear errors
    districtsError?.value = null;
    bodiesError?.value = null;
    wardsError?.value = null;

    AppLogger.core('🧹 LOCATION CONTROLLER: Cleared all location selections');
  }

  /// Check if a complete location is selected (district + body + ward)
  bool get hasCompleteSelection =>
      selectedDistrictId?.value != null &&
      selectedBodyId?.value != null &&
      selectedWard.value != null;

  /// Get the currently selected district
  District? get selectedDistrict {
    if (selectedDistrictId?.value == null) return null;
    return districts.firstWhereOrNull((d) => d.id == selectedDistrictId!.value);
  }

  /// Get the currently selected body
  Body? get selectedBody {
    if (selectedDistrictId?.value == null || selectedBodyId?.value == null) return null;
    return districtBodies[selectedDistrictId!.value]?.firstWhereOrNull((b) => b.id == selectedBodyId!.value);
  }

  /// Get available bodies for the selected district
  List<Body> get availableBodies {
    if (selectedDistrictId?.value == null) return [];
    return districtBodies[selectedDistrictId!.value] ?? [];
  }

  /// Get available wards for the selected district and body
  List<Ward> get availableWards {
    if (selectedDistrictId?.value == null || selectedBodyId?.value == null) return [];
    final cacheKey = '${selectedDistrictId!.value}_${selectedBodyId!.value}';
    return bodyWards[cacheKey] ?? [];
  }

  /// Refresh location data
  Future<void> refresh() async {
    clearSelections();
    await loadDistricts();
    AppLogger.core('🔄 LOCATION CONTROLLER: Refreshed location data');
  }

  /// Force refresh districts data (bypass cache)
  Future<void> forceRefreshDistricts() async {
    isLoadingDistricts.value = true;
    districtsError?.value = null;

    try {
      // Clear cache first
      await _prefs.remove(_districtsCacheKey);
      await _prefs.remove(_districtCacheTimeKey);

      AppLogger.core('🏙️ LOCATION CONTROLLER: 🔄 Force refreshing districts from Firebase...');

      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId.value)
          .collection('districts')
          .get();

      final loadedDistricts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({'id': doc.id, ...data});
      }).toList();

      // If no districts found, try to populate sample districts for Maharashtra
      if (loadedDistricts.isEmpty && selectedStateId.value == 'maharashtra') {
        AppLogger.core('🏙️ LOCATION CONTROLLER: No districts found for Maharashtra, adding sample districts...');
        try {
          await FirebaseFirestore.instance.collection('states').doc('maharashtra').collection('districts').doc('dharashiv').set({
            'name': 'धाराशिव',
            'marathiName': 'धाराशिव',
            'isActive': true,
          });
          AppLogger.core('🏙️ LOCATION CONTROLLER: Added sample district Dharashiv for Maharashtra');

          // Reload after adding sample
          final retrySnapshot = await FirebaseFirestore.instance
              .collection('states')
              .doc(selectedStateId.value)
              .collection('districts')
              .get();

          loadedDistricts.clear();
          loadedDistricts.addAll(retrySnapshot.docs.map((doc) {
            final data = doc.data();
            return District.fromJson({'id': doc.id, ...data});
          }).toList());
        } catch (e) {
          AppLogger.core('🏙️ LOCATION CONTROLLER ERROR: Failed to add sample district: $e');
        }
      }

      // Cache the fresh results
      if (loadedDistricts.isNotEmpty) {
        final districtsJson = json.encode(loadedDistricts.map((d) => d.toJson()).toList());
        await _prefs.setString(_districtsCacheKey, districtsJson);
        await _prefs.setInt(_districtCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      }

      // Debug logging to see what districts are loaded
      AppLogger.core('🏙️ LOCATION CONTROLLER: Force loaded ${loadedDistricts.length} districts:');
      for (final district in loadedDistricts.take(5)) { // Limit to first 5 to avoid spam
        AppLogger.core('🏙️   - ${district.id}: ${district.name}, isActive: ${district.isActive}');
      }

      // Filter to only active districts (include districts where isActive is null or true, exclude false)
      final activeDistricts = loadedDistricts.where((district) => district.isActive != false).toList();
      districts.assignAll(activeDistricts);
      AppLogger.core('🏙️ LOCATION CONTROLLER: Force filtered to ${activeDistricts.length} active districts');
    } catch (e) {
      AppLogger.core('🏙️ LOCATION CONTROLLER ERROR: Failed to force load districts: $e');
      districtsError?.value = 'Failed to load districts: $e';
      districts.clear();
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final allKeys = _prefs.getKeys();
    final locationKeys = allKeys.where((key) => key.startsWith('location_')).toList();

    int districtsCount = 0;
    DateTime? districtsCacheTime;
    bool districtsCacheValid = false;

    final districtsJson = _prefs.getString(_districtsCacheKey);
    if (districtsJson != null) {
      try {
        final cachedList = json.decode(districtsJson) as List;
        districtsCount = cachedList.length;

        final cacheTime = _prefs.getInt(_districtCacheTimeKey);
        if (cacheTime != null) {
          districtsCacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
          districtsCacheValid = DateTime.now().difference(districtsCacheTime) < _cacheValidityDuration;
        }
      } catch (e) {
        // Ignore decode errors
      }
    }

    return {
      'cache_provider': 'SharedPreferences',
      'location_keys_count': locationKeys.length,
      'districts_cached': districtsCount,
      'districts_cache_time': districtsCacheTime?.toIso8601String(),
      'districts_cache_valid': districtsCacheValid,
      'cache_validity_hours': _cacheValidityDuration.inHours,
    };
  }

  /// Clear location caches
  Future<void> clearCaches() async {
    final allKeys = _prefs.getKeys();
    final locationKeys = allKeys.where((key) => key.startsWith('location_')).toList();

    for (final key in locationKeys) {
      await _prefs.remove(key);
    }

    // Also clear local state
    districts.clear();
    districtBodies.clear();
    bodyWards.clear();

    // Reset first load flag to force fresh fetch next time
    _isFirstLoad = true;

    AppLogger.core('🧹 LOCATION CONTROLLER: Cleared location caches in SharedPreferences');
  }

  /// Set initial district (for deep linking)
  Future<void> setInitialDistrict(String districtId) async {
    await selectDistrict(districtId);
  }

  /// Set initial body (for deep linking)
  Future<void> setInitialBody(String bodyId) async {
    await selectBody(bodyId);
  }

  /// Set initial ward (for deep linking)
  Future<void> setInitialWard(String wardId) async {
    if (selectedDistrictId.value != null && selectedBodyId.value != null) {
      final cacheKey = '${selectedDistrictId.value}_${selectedBodyId.value}';
      final ward = bodyWards[cacheKey]?.firstWhere(
        (w) => w.id == wardId,
        orElse: () => Ward(id: '', name: '', areas: [], districtId: '', bodyId: '', stateId: ''),
      );
      if (ward != null && ward.id.isNotEmpty) {
        selectWard(ward);
      }
    }
  }
}
