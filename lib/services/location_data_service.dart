import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class LocationDataService {
  static final LocationDataService _instance = LocationDataService._internal();
  static LocationDataService get instance => _instance;

  LocationDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get location names for the given IDs
  Future<Map<String, String>> getLocationNames({
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      AppLogger.common('🔍 Fetching location names for state: $stateId, district: $districtId, body: $bodyId, ward: $wardId');

      final locationNames = <String, String>{};

      // Fetch district name
      if (districtId != null && districtId.isNotEmpty && stateId != null && stateId.isNotEmpty) {
        final districtDoc = await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .get();

        if (districtDoc.exists) {
          locationNames['districtName'] = districtDoc.data()?['name'] ?? districtId;
        } else {
          locationNames['districtName'] = districtId;
        }
      } else if (districtId != null) {
        locationNames['districtName'] = districtId;
      }

      // Fetch body name
      if (bodyId != null && bodyId.isNotEmpty && districtId != null && districtId.isNotEmpty && stateId != null && stateId.isNotEmpty) {
        final bodyDoc = await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .get();

        if (bodyDoc.exists) {
          locationNames['bodyName'] = bodyDoc.data()?['name'] ?? bodyId;
        } else {
          locationNames['bodyName'] = bodyId;
        }
      } else if (bodyId != null) {
        locationNames['bodyName'] = bodyId;
      }

      // Fetch ward name
      if (wardId != null && wardId.isNotEmpty && bodyId != null && bodyId.isNotEmpty && districtId != null && districtId.isNotEmpty && stateId != null && stateId.isNotEmpty) {
        final wardDoc = await _firestore
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .get();

        if (wardDoc.exists) {
          locationNames['wardName'] = wardDoc.data()?['name'] ?? wardId;
        } else {
          locationNames['wardName'] = wardId;
        }
      } else if (wardId != null) {
        locationNames['wardName'] = wardId;
      }

      AppLogger.common('✅ Location names fetched: $locationNames');
      return locationNames;
    } catch (e) {
      AppLogger.commonError('❌ Failed to fetch location names: $e');
      // Return fallback names
      return {
        'districtName': districtId ?? 'N/A',
        'bodyName': bodyId ?? 'N/A',
        'wardName': wardId ?? 'N/A',
      };
    }
  }
}