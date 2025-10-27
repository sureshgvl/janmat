import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlights_model.dart';
import '../models/candidate_model.dart';

class HighlightsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get highlights for a specific candidate
  Future<HighlightsModel?> getCandidateHighlights(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching highlights for candidate: $candidateId');

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
        AppLogger.database('Candidate document not found: $candidateId');
        return HighlightsModel(highlights: []);
      }

      final candidateData = candidateDoc.data()!;

      if (!candidateData.containsKey('highlights')) {
        AppLogger.database('No highlights found in candidate document');
        return HighlightsModel(highlights: []);
      }

      final highlightsData = candidateData['highlights'] as List<dynamic>;
      final highlights = highlightsData
          .map((item) => HighlightData.fromJson(item as Map<String, dynamic>))
          .toList();

      return HighlightsModel(highlights: highlights);
    } catch (e) {
      AppLogger.databaseError('Error fetching candidate highlights: $e');
      return null;
    }
  }

  /// Update highlight for a candidate
  Future<bool> updateCandidateHighlight(String candidateId, HighlightData highlightData, Candidate candidate) async {
    try {
      AppLogger.database('Updating highlight for candidate: $candidateId');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updateData = {
        'highlights': [highlightData.toJson()],
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

      // Check if document exists, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        await candidateRef.set({
          ...updateData,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updateData);
      }

      AppLogger.database('Highlight updated successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating candidate highlight: $e');
      return false;
    }
  }

  /// Delete highlight for a candidate
  Future<bool> deleteCandidateHighlight(String candidateId, Candidate candidate) async {
    try {
      AppLogger.database('Deleting highlight for candidate: $candidateId');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updateData = {
        'highlights': [],
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

      // Check if document exists, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        await candidateRef.set({
          ...updateData,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updateData);
      }

      AppLogger.database('Highlight deleted successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error deleting candidate highlight: $e');
      return false;
    }
  }

  /// Save highlights for a candidate (full save)
  Future<bool> saveHighlights(Candidate candidate, HighlightsModel highlights) async {
    try {
      final candidateId = candidate.candidateId;
      AppLogger.database('Saving highlights for candidate: $candidateId');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updateData = {
        'highlights': highlights.highlights?.map((h) => h.toJson()).toList() ?? [],
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

      // Check if document exists, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        await candidateRef.set({
          ...updateData,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updateData);
      }

      AppLogger.database('Highlights saved successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error saving highlights: $e');
      return false;
    }
  }

  /// Update highlights fields for a candidate
  Future<bool> updateHighlightsFields(Candidate candidate, Map<String, dynamic> updates) async {
    try {
      final candidateId = candidate.candidateId;
      AppLogger.database('Updating highlights fields for candidate: $candidateId');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updateData = {
        ...updates,
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

      // Check if document exists, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        await candidateRef.set({
          ...updateData,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updateData);
      }

      AppLogger.database('Highlights fields updated successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating highlights fields: $e');
      return false;
    }
  }

}
