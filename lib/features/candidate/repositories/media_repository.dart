import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/media_model.dart';
import '../models/candidate_model.dart';

abstract class IMediaRepository {
  Future<List<Media>?> getMedia(Candidate candidate);
  Future<List<Map<String, dynamic>>?> getMediaGrouped(Candidate candidate);
  Future<bool> updateMedia(String candidateId, List<Media> media, Candidate candidate);
  Future<bool> updateMediaWithCandidate(String candidateId, List<Media> media, Candidate candidate);
  Future<bool> updateMediaGrouped(String candidateId, List<Map<String, dynamic>> groupedMedia, Candidate candidate);
  Future<bool> updateMediaFields(Candidate candidate, Map<String, dynamic> updates);
  Future<void> updateMediaFast(Candidate candidate, Map<String, dynamic> updateData);
}

class MediaRepository implements IMediaRepository {
  final FirebaseFirestore _firestore;

  MediaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Media>?> getMedia(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching media for candidate: $candidateId', tag: 'MEDIA_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'MEDIA_REPO');

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
        AppLogger.database('Candidate document not found: $candidateId', tag: 'MEDIA_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      if (!data.containsKey('media')) {
        AppLogger.database('No media found in candidate document', tag: 'MEDIA_REPO');
        return null;
      }

      final mediaData = data['media'] as List<dynamic>;
      // Check if media data is in grouped format (List<Map<String, dynamic>>)
      if (mediaData.isNotEmpty && mediaData.first is Map<String, dynamic>) {
        final firstItem = mediaData.first as Map<String, dynamic>;
        if (firstItem.containsKey('title') && firstItem.containsKey('images')) {
          AppLogger.database('Media data is in grouped format, returning legacy conversion for backward compatibility', tag: 'MEDIA_REPO');
          // Convert grouped format to individual Media objects for backward compatibility with existing callers
          final List<Media> result = [];
          for (final item in mediaData) {
            final itemMap = item as Map<String, dynamic>;
            final title = itemMap['title'] ?? 'Untitled';
            final date = itemMap['date'] ?? DateTime.now().toIso8601String().split('T')[0];
            final images = List<String>.from(itemMap['images'] ?? []);
            final videos = List<String>.from(itemMap['videos'] ?? []);
            final youtubeLinks = List<String>.from(itemMap['youtubeLinks'] ?? []);

            for (final imageUrl in images) {
              result.add(Media(
                url: imageUrl,
                caption: '$title - $date',
                title: title,
                type: 'image',
                uploadedAt: date,
              ));
            }
            for (final videoUrl in videos) {
              result.add(Media(
                url: videoUrl,
                caption: '$title - $date',
                title: title,
                type: 'video',
                uploadedAt: date,
              ));
            }
            for (final youtubeUrl in youtubeLinks) {
              result.add(Media(
                url: youtubeUrl,
                caption: '$title - $date',
                title: title,
                type: 'youtube',
                uploadedAt: date,
              ));
            }
          }
          return result;
        }
      }

      // Fallback: return as individual Media objects if already in that format
      return mediaData.map((item) => Media.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.databaseError('Error fetching media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to fetch media: $e');
    }
  }

  /// Get grouped media data (List<Map<String, dynamic>>) - new method for view widget
  Future<List<Map<String, dynamic>>?> getMediaGrouped(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching grouped media for candidate: $candidateId', tag: 'MEDIA_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      // Get candidate document from hierarchical path
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
        AppLogger.database('Candidate document not found: $candidateId', tag: 'MEDIA_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      if (!data.containsKey('media')) {
        AppLogger.database('No media found in candidate document', tag: 'MEDIA_REPO');
        return null;
      }

      final mediaData = data['media'] as List<dynamic>;
      return mediaData.map((item) => item as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.databaseError('Error fetching grouped media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to fetch grouped media: $e');
    }
  }

  @override
  Future<bool> updateMedia(String candidateId, List<Media> media, Candidate candidate) async {
    try {
      AppLogger.database('Updating media for candidate: $candidateId', tag: 'MEDIA_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updates = {
        'media': media.map((item) => item.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
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
          .update(updates);

      AppLogger.database('Media updated successfully', tag: 'MEDIA_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to update media: $e');
    }
  }

  @override
  Future<bool> updateMediaWithCandidate(String candidateId, List<Media> media, Candidate candidate) async {
    return updateMedia(candidateId, media, candidate);
  }

  /// Update media using grouped format (List<Map<String, dynamic>>) instead of individual Media objects
  Future<bool> updateMediaGrouped(String candidateId, List<Map<String, dynamic>> groupedMedia, Candidate candidate) async {
    try {
      AppLogger.database('Updating grouped media for candidate: $candidateId', tag: 'MEDIA_REPO');
      AppLogger.database('Grouped media items: ${groupedMedia.length}', tag: 'MEDIA_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      // Store the grouped media data directly
      final updates = {
        'media': groupedMedia,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
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
          .update(updates);

      AppLogger.database('Grouped media updated successfully', tag: 'MEDIA_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating grouped media', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to update grouped media: $e');
    }
  }

  @override
  Future<bool> updateMediaFields(Candidate candidate, Map<String, dynamic> updates) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating media fields for candidate: $candidateId', tag: 'MEDIA_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['media.$key'] = value;
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
        AppLogger.database('Document does not exist, creating new document', tag: 'MEDIA_REPO');
        await candidateRef.set({
          ...fieldUpdates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(fieldUpdates);
      }

      AppLogger.database('Media fields updated successfully', tag: 'MEDIA_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating media fields', tag: 'MEDIA_REPO', error: e);
      throw Exception('Failed to update media fields: $e');
    }
  }

  @override
  Future<void> updateMediaFast(Candidate candidate, Map<String, dynamic> updateData) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST UPDATE: Media for $candidateId', tag: 'MEDIA_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'MEDIA_FAST');

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

      AppLogger.database('   Candidate document exists: $documentExists', tag: 'MEDIA_FAST');

      if (!documentExists) {
        AppLogger.database('❌ CANDIDATE DOCUMENT NOT FOUND - Creating new document', tag: 'MEDIA_FAST');

        // Create the candidate document with the media data
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

        AppLogger.database('   Creating document with data: $candidateData', tag: 'MEDIA_FAST');
        await candidateRef.set(candidateData);

        AppLogger.database('✅ CANDIDATE DOCUMENT CREATED with media data', tag: 'MEDIA_FAST');
        return;
      }

      // Document exists, update it
      // Ensure the data is properly structured for media
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'media') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            AppLogger.database('   Processing media map with keys: ${value.keys.toList()}', tag: 'MEDIA_FAST');
            value.forEach((fieldKey, fieldValue) {
              structuredUpdateData['media.$fieldKey'] = fieldValue;
            });
          } else {
            // If it's not a map, store it as-is (fallback)
            AppLogger.database('   Media data is not a map, storing as-is', tag: 'MEDIA_FAST');
            structuredUpdateData[key] = value;
          }
        } else {
          // For other fields like updatedAt, keep them as-is
          structuredUpdateData[key] = value;
        }
      });

      AppLogger.database('   Final structured update data: $structuredUpdateData', tag: 'MEDIA_FAST');
      AppLogger.database('   Attempting Firestore update...', tag: 'MEDIA_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'MEDIA_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'MEDIA_FAST', error: e);
      throw Exception('Failed to fast update media: $e');
    }
  }
}
