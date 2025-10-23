import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/media_model.dart';

abstract class IMediaRepository {
  Future<List<Media>?> getMedia(String candidateId);
  Future<bool> updateMedia(String candidateId, List<Media> media);
  Future<bool> updateMediaFields(String candidateId, Map<String, dynamic> updates);
  Future<void> updateMediaFast(String candidateId, Map<String, dynamic> updateData);
}

class MediaRepository implements IMediaRepository {
  final FirebaseFirestore _firestore;

  MediaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Media>?> getMedia(String candidateId) async {
    try {
      AppLogger.database('Fetching media for candidate: $candidateId', tag: 'MEDIA_REPO');

      // Get candidate location from index first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();

      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId', tag: 'MEDIA_REPO');
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
        AppLogger.database('Candidate document not found: $candidateId', tag: 'MEDIA_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      if (!data.containsKey('media')) {
        AppLogger.database('No media found in candidate document', tag: 'MEDIA_REPO');
        return null;
      }

      final mediaData = data['media'] as List<dynamic>;
      return mediaData.map((item) => Media.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.databaseError('Error fetching media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to fetch media: $e');
    }
  }

  @override
  Future<bool> updateMedia(String candidateId, List<Media> media) async {
    try {
      AppLogger.database('Updating media for candidate: $candidateId', tag: 'MEDIA_REPO');

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
        'media': media.map((item) => item.toJson()).toList(),
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

      AppLogger.database('Media updated successfully', tag: 'MEDIA_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to update media: $e');
    }
  }

  @override
  Future<bool> updateMediaFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('Updating media fields for candidate: $candidateId', tag: 'MEDIA_REPO');

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
        fieldUpdates['media.$key'] = value;
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

      AppLogger.database('Media fields updated successfully', tag: 'MEDIA_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating media fields', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to update media fields: $e');
    }
  }

  @override
  Future<void> updateMediaFast(String candidateId, Map<String, dynamic> updateData) async {
    try {
      AppLogger.database('🚀 FAST UPDATE: Media for $candidateId', tag: 'MEDIA_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'MEDIA_FAST');

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

      // Ensure the data is properly structured for extra_info.media
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'media') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            value.forEach((fieldKey, fieldValue) {
              structuredUpdateData['media.$fieldKey'] = fieldValue;
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

      AppLogger.database('   Structured update data: $structuredUpdateData', tag: 'MEDIA_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'MEDIA_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'MEDIA_FAST', error: e);
      throw Exception('Failed to fast update media: $e');
    }
  }
}
