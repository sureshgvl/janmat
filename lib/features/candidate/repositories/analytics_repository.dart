import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/analytics_model.dart';

abstract class IAnalyticsRepository {
  Future<AnalyticsModel?> getAnalytics(String candidateId);
  Future<bool> updateAnalytics(String candidateId, AnalyticsModel analytics);
  Future<bool> updateAnalyticsFields(String candidateId, Map<String, dynamic> updates);
  Future<void> updateAnalyticsFast(String candidateId, Map<String, dynamic> updateData);
}

class AnalyticsRepository implements IAnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AnalyticsModel?> getAnalytics(String candidateId) async {
    try {
      AppLogger.database('Fetching analytics for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from index first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();

      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId', tag: 'ANALYTICS_REPO');
        return null;
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      // Get candidate document from hierarchical path
      final candidateDoc = await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (!candidateDoc.exists) {
        AppLogger.database('Candidate document not found: $candidateId', tag: 'ANALYTICS_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      if (!data.containsKey('analytics')) {
        AppLogger.database('No analytics found in candidate document', tag: 'ANALYTICS_REPO');
        return null;
      }

      final analyticsData = data['analytics'] as Map<String, dynamic>;
      return AnalyticsModel.fromJson(analyticsData);
    } catch (e) {
      AppLogger.databaseError('Error fetching analytics', tag: 'ANALYTICS_REPO', error: e);
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  @override
  Future<bool> updateAnalytics(String candidateId, AnalyticsModel analytics) async {
    try {
      AppLogger.database('Updating analytics for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final updates = {
        'analytics': analytics.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update(updates);

      AppLogger.database('Analytics updated successfully', tag: 'ANALYTICS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating analytics', tag: 'ANALYTICS_REPO', error: e);
      throw Exception('Failed to update analytics: $e');
    }
  }

  @override
  Future<bool> updateAnalyticsFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('Updating analytics fields for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['analytics.$key'] = value;
      });

      fieldUpdates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update(fieldUpdates);

      AppLogger.database('Analytics fields updated successfully', tag: 'ANALYTICS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating analytics fields', tag: 'ANALYTICS_REPO', error: e);
      throw Exception('Failed to update analytics fields: $e');
    }
  }

  @override
  Future<void> updateAnalyticsFast(String candidateId, Map<String, dynamic> updateData) async {
    try {
      AppLogger.database('🚀 FAST UPDATE: Analytics for $candidateId', tag: 'ANALYTICS_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'ANALYTICS_FAST');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final candidateRef = _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Ensure the data is properly structured for extra_info.analytics
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'analytics') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            value.forEach((fieldKey, fieldValue) {
              structuredUpdateData['analytics.$fieldKey'] = fieldValue;
            });
          } else {
            // If it's not a map, store it as-is (fallback)
            structuredUpdateData[key] = value;
          }
        } else {
          // For other fields like updatedAt, keep them as-is
          structuredUpdateData[key] = value;
        }
      });

      AppLogger.database('   Structured update data: $structuredUpdateData', tag: 'ANALYTICS_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'ANALYTICS_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'ANALYTICS_FAST', error: e);
      throw Exception('Failed to fast update analytics: $e');
    }
  }
}
