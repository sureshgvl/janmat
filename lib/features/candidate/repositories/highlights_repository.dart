import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlights_model.dart';

class HighlightsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get highlights for a specific candidate
  Future<HighlightsModel?> getCandidateHighlights(String candidateId) async {
    try {
      AppLogger.database('Fetching highlights for candidate: $candidateId');

      // Get candidate location from index first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();

      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId');
        return HighlightsModel(highlights: []);
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
  Future<bool> updateCandidateHighlight(String candidateId, HighlightData highlightData) async {
    try {
      AppLogger.database('Updating highlight for candidate: $candidateId');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId');
        return false;
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final updateData = {
        'highlights': [highlightData.toJson()],
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
          .update(updateData);

      AppLogger.database('Highlight updated successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating candidate highlight: $e');
      return false;
    }
  }

  /// Delete highlight for a candidate
  Future<bool> deleteCandidateHighlight(String candidateId) async {
    try {
      AppLogger.database('Deleting highlight for candidate: $candidateId');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId');
        return false;
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final updateData = {
        'highlights': [],
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
          .update(updateData);

      AppLogger.database('Highlight deleted successfully for candidate: $candidateId');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error deleting candidate highlight: $e');
      return false;
    }
  }

}