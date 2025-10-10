import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import 'candidate_cache_manager.dart';
import '../../../utils/app_logger.dart';

class CandidateStateManager {
  final FirebaseFirestore _firestore;
  final CandidateCacheManager _cacheManager;


  CandidateStateManager(this._firestore, this._cacheManager);

  // Get all states
  Future<List<Map<String, dynamic>>> getAllStates() async {
    const cacheKey = 'all_states';

    // Check cache first
    final cachedStates = _cacheManager.getCachedQueryResult(cacheKey);
    if (cachedStates != null) {
      AppLogger.candidate('⚡ CACHE HIT: Returning ${cachedStates.length} cached states');
      return cachedStates['states'] as List<Map<String, dynamic>>;
    }

    AppLogger.candidate('🔍 CACHE MISS: Fetching all states from Firebase');
    try {
      final snapshot = await _firestore.collection('states').get();
      AppLogger.candidate('📊 getAllStates: Found ${snapshot.docs.length} states');

      final states = snapshot.docs.map((doc) {
        final data = doc.data();
        final stateData = Map<String, dynamic>.from(data);
        stateData['stateId'] = doc.id;

        AppLogger.candidate('🏛️ State: ${stateData['name'] ?? 'Unknown'} (ID: ${doc.id})');
        return stateData;
      }).toList();

      // Cache the results
      _cacheManager.cacheQueryResult(cacheKey, {'states': states});
      AppLogger.candidate('💾 Cached ${states.length} states');

      return states;
    } catch (e) {
      AppLogger.candidateError('❌ getAllStates: Failed to fetch states: $e');
      throw Exception('Failed to fetch states: $e');
    }
  }

  // Get state by ID
  Future<Map<String, dynamic>?> getStateById(String stateId) async {
    final cacheKey = 'state_$stateId';

    // Check cache first
    final cachedState = _cacheManager.getCachedQueryResult(cacheKey);
    if (cachedState != null) {
      AppLogger.candidate('⚡ CACHE HIT: Returning cached state $stateId');
      return cachedState['state'] as Map<String, dynamic>;
    }

    AppLogger.candidate('🔍 CACHE MISS: Fetching state $stateId from Firebase');
    try {
      final doc = await _firestore.collection('states').doc(stateId).get();

      if (doc.exists) {
        final data = doc.data()!;
        final stateData = Map<String, dynamic>.from(data);
        stateData['stateId'] = doc.id;

        // Cache the result
        _cacheManager.cacheQueryResult(cacheKey, {'state': stateData});
        AppLogger.candidate('💾 Cached state $stateId');

        return stateData;
      }

      AppLogger.candidate('❌ State $stateId not found');
      return null;
    } catch (e) {
      AppLogger.candidateError('❌ getStateById: Failed to fetch state: $e');
      throw Exception('Failed to fetch state: $e');
    }
  }

  // Validate state exists and is active
  Future<bool> validateState(String stateId) async {
    try {
      final state = await getStateById(stateId);
      return state != null && (state['isActive'] ?? true);
    } catch (e) {
      AppLogger.candidateError('❌ validateState: Failed to validate state: $e');
      return false;
    }
  }


  // Get wards for a district and body in a specific state
  Future<List<Ward>> getWardsByDistrictAndBody(
    String stateId,
    String districtId,
    String bodyId,
  ) async {
    final cacheKey = 'wards_${stateId}_${districtId}_$bodyId';

    // Check cache first
    final cachedWards = _cacheManager.getCachedWards(cacheKey);
    if (cachedWards != null) {
      AppLogger.candidate(
        '⚡ CACHE HIT: Returning ${cachedWards.length} cached wards for $stateId/$districtId/$bodyId',
      );
      return cachedWards;
    }

    AppLogger.candidate(
      '🔍 CACHE MISS: Fetching wards for $stateId/$districtId/$bodyId from Firebase',
    );
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = snapshot.docs.map((doc) {
        final data = doc.data();
        final wardData = Map<String, dynamic>.from(data);
        wardData['wardId'] = doc.id;
        wardData['districtId'] = districtId;
        wardData['bodyId'] = bodyId;
        return Ward.fromJson(wardData);
      }).toList();

      // Cache the results
      _cacheManager.cacheData(cacheKey, wards);
      AppLogger.candidate('💾 Cached ${wards.length} wards for $stateId/$districtId/$bodyId');

      return wards;
    } catch (e) {
      throw Exception('Failed to fetch wards: $e');
    }
  }

  // Get all districts for a specific state
  Future<List<District>> getAllDistricts(String stateId) async {
    final cacheKey = 'districts_$stateId';

    // Check cache first
    final cachedDistricts = _cacheManager.getCachedDistricts(cacheKey);
    if (cachedDistricts != null) {
      AppLogger.candidate('⚡ CACHE HIT: Returning ${cachedDistricts.length} cached districts for state $stateId');
      return cachedDistricts;
    }

    AppLogger.candidate('🔍 CACHE MISS: Fetching all districts for state $stateId from Firebase');
    try {
      final snapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .get();
      AppLogger.candidate('📊 getAllDistricts: Found ${snapshot.docs.length} districts in state $stateId');

      final districts = snapshot.docs.map((doc) {
        final data = doc.data();
        final districtData = Map<String, dynamic>.from(data);
        districtData['districtId'] = doc.id;

        AppLogger.candidate(
          '🏛️ District: ${districtData['name'] ?? 'Unknown'} (ID: ${doc.id}) in state $stateId',
        );

        return District.fromJson(districtData);
      }).toList();

      // Cache the results
      _cacheManager.cacheData(cacheKey, districts);
      AppLogger.candidate('💾 Cached ${districts.length} districts for state $stateId');

      AppLogger.candidate('✅ getAllDistricts: Successfully loaded ${districts.length} districts for state $stateId');
      return districts;
    } catch (e) {
      AppLogger.candidateError('❌ getAllDistricts: Failed to fetch districts for state $stateId: $e');
      throw Exception('Failed to fetch districts: $e');
    }
  }
}

