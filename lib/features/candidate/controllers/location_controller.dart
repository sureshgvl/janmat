import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../models/state_model.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';

class LocationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable values
  final RxString selectedStateId = ''.obs;
  final RxString selectedDistrictId = ''.obs;
  final RxString selectedBodyId = ''.obs;
  final Rx<Body?> selectedBody = Rx<Body?>(null);
  final Rx<Ward?> selectedWard = Rx<Ward?>(null);

  // Data collections
  final RxList<State> states = <State>[].obs;
  final RxList<District> districts = <District>[].obs;
  final RxMap<String, List<Body>> districtBodies = <String, List<Body>>{}.obs;
  final RxMap<String, List<Ward>> bodyWards = <String, List<Ward>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.candidate('LocationController initialized');
  }

  Future<void> initialize() async {
    try {
      AppLogger.candidate('Initializing location data...');
      await loadStates();
      AppLogger.candidate('Location data initialized successfully');
    } catch (e) {
      AppLogger.candidateError('Failed to initialize location data: $e');
    }
  }

  Future<void> loadStates() async {
    try {
      final snapshot = await _firestore.collection('states').get();
      states.value = snapshot.docs.map((doc) => State.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
      AppLogger.candidate('Loaded ${states.length} states');
    } catch (e) {
      AppLogger.candidateError('Failed to load states: $e');
    }
  }

  Future<void> loadDistricts(String stateId) async {
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .get();
      districts.value = snapshot.docs.map((doc) => District.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
      selectedStateId.value = stateId;
      AppLogger.candidate('Loaded ${districts.length} districts for state $stateId');
    } catch (e) {
      AppLogger.candidateError('Failed to load districts: $e');
    }
  }

  Future<void> loadBodies(String stateId, String districtId) async {
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();
      final bodies = snapshot.docs.map((doc) => Body.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
      districtBodies[districtId] = bodies;
      selectedDistrictId.value = districtId;
      AppLogger.candidate('Loaded ${bodies.length} bodies for district $districtId');
    } catch (e) {
      AppLogger.candidateError('Failed to load bodies: $e');
    }
  }

  Future<void> loadWards(String stateId, String districtId, String bodyId) async {
    try {
      final cacheKey = '${districtId}_$bodyId';
      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();
      final wards = snapshot.docs.map((doc) => Ward.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
      bodyWards[cacheKey] = wards;
      selectedBodyId.value = bodyId;
      AppLogger.candidate('Loaded ${wards.length} wards for body $bodyId');
    } catch (e) {
      AppLogger.candidateError('Failed to load wards: $e');
    }
  }

  Future<void> selectState(String stateId) async {
    selectedStateId.value = stateId;
    selectedDistrictId.value = '';
    selectedBodyId.value = '';
    selectedBody.value = null;
    selectedWard.value = null;
    districts.clear();
    districtBodies.clear();
    bodyWards.clear();
    await loadDistricts(stateId);
    AppLogger.candidate('Selected state: $stateId');
  }

  Future<void> selectDistrict(String districtId) async {
    selectedDistrictId.value = districtId;
    selectedBodyId.value = '';
    selectedBody.value = null;
    selectedWard.value = null;
    bodyWards.clear();
    await loadBodies(selectedStateId.value, districtId);
    AppLogger.candidate('Selected district: $districtId');
  }

  Future<void> selectBody(String bodyId) async {
    selectedBodyId.value = bodyId;
    selectedWard.value = null;
    final bodies = districtBodies[selectedDistrictId.value] ?? [];
    selectedBody.value = bodies.firstWhereOrNull((body) => body.id == bodyId);
    await loadWards(selectedStateId.value, selectedDistrictId.value, bodyId);
    AppLogger.candidate('Selected body: $bodyId');
  }

  void selectWard(Ward? ward) {
    selectedWard.value = ward;
    AppLogger.candidate('Selected ward: ${ward?.name ?? 'null'}');
  }

  Future<void> setInitialDistrict(String districtId) async {
    try {
      // Find the state that contains this district
      for (var state in states) {
        final stateId = state.id;
        final districtSnapshot = await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .get();

        if (districtSnapshot.exists) {
          await loadDistricts(stateId);
          selectedDistrictId.value = districtId;
          AppLogger.candidate('Set initial district: $districtId in state $stateId');
          break;
        }
      }
    } catch (e) {
      AppLogger.candidateError('Failed to set initial district: $e');
    }
  }

  Future<void> setInitialBody(String bodyId) async {
    if (selectedStateId.value.isEmpty || selectedDistrictId.value.isEmpty) {
      AppLogger.candidate('Cannot set initial body: state or district not selected');
      return;
    }

    try {
      await loadBodies(selectedStateId.value, selectedDistrictId.value);
      selectedBodyId.value = bodyId;
      final bodies = districtBodies[selectedDistrictId.value] ?? [];
      selectedBody.value = bodies.firstWhereOrNull((body) => body.id == bodyId);
      AppLogger.candidate('Set initial body: $bodyId');
    } catch (e) {
      AppLogger.candidateError('Failed to set initial body: $e');
    }
  }

  Future<void> setInitialWard(String wardId) async {
    if (selectedStateId.value.isEmpty || selectedDistrictId.value.isEmpty || selectedBodyId.value.isEmpty) {
      AppLogger.candidate('Cannot set initial ward: state, district, or body not selected');
      return;
    }

    try {
      await loadWards(selectedStateId.value, selectedDistrictId.value, selectedBodyId.value);
      final cacheKey = '${selectedDistrictId.value}_${selectedBodyId.value}';
      final wards = bodyWards[cacheKey] ?? [];
      final ward = wards.firstWhereOrNull((w) => w.id == wardId);
      if (ward != null) {
        selectedWard.value = ward;
        AppLogger.candidate('Set initial ward: ${ward.name}');
      }
    } catch (e) {
      AppLogger.candidateError('Failed to set initial ward: $e');
    }
  }

  Future<void> forceRefreshDistricts() async {
    if (selectedStateId.value.isNotEmpty) {
      await loadDistricts(selectedStateId.value);
      AppLogger.candidate('Force refreshed districts');
    }
  }

  void clearSelection() {
    selectedDistrictId.value = '';
    selectedBodyId.value = '';
    selectedBody.value = null;
    selectedWard.value = null;
    districts.clear();
    districtBodies.clear();
    bodyWards.clear();
    AppLogger.candidate('Cleared location selection');
  }
}