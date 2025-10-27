import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/analytics_model.dart';
import '../models/candidate_model.dart';

abstract class IAnalyticsRepository {
  Future<AnalyticsModel?> getAnalytics(Candidate candidate);
  Future<bool> updateAnalytics(Candidate candidate, AnalyticsModel analytics);
  Future<bool> updateAnalyticsFields(Candidate candidate, Map<String, dynamic> updates);
  Future<void> updateAnalyticsFast(Candidate candidate, Map<String, dynamic> updateData);
}

class AnalyticsRepository implements IAnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AnalyticsModel?> getAnalytics(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching analytics for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      // Get candidate document from hierarchical path - using states path to match other repos
      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)
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
  Future<bool> updateAnalytics(Candidate candidate, AnalyticsModel analytics) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating analytics for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updates = {
        'analytics': analytics.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Check if document exists first, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        await candidateRef.set({
          ...updates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updates);
      }

      AppLogger.database('Analytics updated successfully', tag: 'ANALYTICS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating analytics', tag: 'ANALYTICS_REPO', error: e);
      throw Exception('Failed to update analytics: $e');
    }
  }

  @override
  Future<bool> updateAnalyticsFields(Candidate candidate, Map<String, dynamic> updates) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating analytics fields for candidate: $candidateId', tag: 'ANALYTICS_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['analytics.$key'] = value;
      });

      fieldUpdates['updatedAt'] = FieldValue.serverTimestamp();

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Check if document exists first, like other repos do
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('Document does not exist, creating new document', tag: 'ANALYTICS_REPO');
        await candidateRef.set({
          ...fieldUpdates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(fieldUpdates);
      }

      AppLogger.database('Analytics fields updated successfully', tag: 'ANALYTICS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating analytics fields', tag: 'ANALYTICS_REPO', error: e);
      throw Exception('Failed to update analytics fields: $e');
    }
  }

  @override
  Future<void> updateAnalyticsFast(Candidate candidate, Map<String, dynamic> updateData) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST UPDATE: Analytics for $candidateId', tag: 'ANALYTICS_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'ANALYTICS_FAST');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Check if candidate document exists first
      final candidateDoc = await candidateRef.get();
      final documentExists = candidateDoc.exists;

      AppLogger.database('   Candidate document exists: $documentExists', tag: 'ANALYTICS_FAST');

      if (!documentExists) {
        AppLogger.database('❌ CANDIDATE DOCUMENT NOT FOUND - Creating new document', tag: 'ANALYTICS_FAST');

        // Create the candidate document with the analytics data
        final Map<String, dynamic> candidateData = {
          'candidateId': candidateId,
          'userId': candidate.candidateId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'approved': false,
          'sponsored': false,
          ...updateData,
        };

        AppLogger.database('   Creating document with data: $candidateData', tag: 'ANALYTICS_FAST');
        await candidateRef.set(candidateData);

        AppLogger.database('✅ CANDIDATE DOCUMENT CREATED with analytics data', tag: 'ANALYTICS_FAST');
        return;
      }

      // Document exists, update it
      // Ensure the data is properly structured for analytics
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'analytics') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            AppLogger.database('   Processing analytics map with keys: ${value.keys.toList()}', tag: 'ANALYTICS_FAST');
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

      AppLogger.database('   Final structured update data: $structuredUpdateData', tag: 'ANALYTICS_FAST');
      AppLogger.database('   Attempting Firestore update...', tag: 'ANALYTICS_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'ANALYTICS_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'ANALYTICS_FAST', error: e);
      throw Exception('Failed to fast update analytics: $e');
    }
  }
}
