import '../../../utils/app_logger.dart';
import '../../../services/file_upload_service.dart';
import '../models/highlights_model.dart';

/// Service responsible for coordinating photo upload operations.
/// Follows Single Responsibility Principle - handles only photo uploads.
class PhotoUploadCoordinator {
  final FileUploadService _fileUploadService = FileUploadService();

  /// Check if there are local photos that need to be uploaded
  bool hasLocalPhotos(List<dynamic>? achievements, HighlightData? highlight) {
    try {
      // Check achievements photos
      if (achievements != null && achievements.isNotEmpty) {
        for (final achievement in achievements) {
          if (achievement.photoUrl != null && _fileUploadService.isLocalPath(achievement.photoUrl!)) {
            return true;
          }
        }
      }

      // Check highlight banner
      if (highlight != null && highlight.imageUrl != null && _fileUploadService.isLocalPath(highlight.imageUrl!)) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Upload local photos to Firebase before saving
  Future<void> uploadLocalPhotos({
    List<dynamic>? achievements,
    HighlightData? highlight,
    Map<String, dynamic>? changedExtraInfoFields,
  }) async {
    try {
      AppLogger.database('Starting photo upload coordination', tag: 'PHOTO_UPLOAD_COORDINATOR');

      // Upload banner image if it's a local path
      await _uploadLocalBannerImageToFirebase(highlight, changedExtraInfoFields);

      // Upload achievement photos
      if (achievements != null) {
        await _uploadLocalAchievementPhotosToFirebase(achievements, changedExtraInfoFields);
      }

      AppLogger.database('Photo upload coordination completed', tag: 'PHOTO_UPLOAD_COORDINATOR');
    } catch (e) {
      AppLogger.databaseError('Error in photo upload coordination', tag: 'PHOTO_UPLOAD_COORDINATOR', error: e);
      rethrow;
    }
  }

  /// Upload local banner image to Firebase
  Future<void> _uploadLocalBannerImageToFirebase(
    HighlightData? highlight,
    Map<String, dynamic>? changedExtraInfoFields,
  ) async {
    try {
      if (highlight == null || highlight.imageUrl == null) return;

      if (_fileUploadService.isLocalPath(highlight.imageUrl!)) {
        AppLogger.database('Uploading local banner image to Firebase', tag: 'PHOTO_UPLOAD_COORDINATOR');

        final firebaseUrl = await _fileUploadService.uploadLocalPhotoToFirebase(highlight.imageUrl!);

        if (firebaseUrl != null) {
          // Update the highlight with the Firebase URL
          final updatedHighlight = HighlightData(
            enabled: highlight.enabled,
            title: highlight.title,
            message: highlight.message,
            imageUrl: firebaseUrl,
            priority: highlight.priority,
            expiresAt: highlight.expiresAt,
            bannerStyle: highlight.bannerStyle,
            callToAction: highlight.callToAction,
            priorityLevel: highlight.priorityLevel,
            targetLocations: highlight.targetLocations,
            showAnalytics: highlight.showAnalytics,
            customMessage: highlight.customMessage,
          );

          // Update the changed fields if highlight was modified
          if (changedExtraInfoFields != null && changedExtraInfoFields.containsKey('highlight')) {
            final highlightJson = changedExtraInfoFields['highlight'] as Map<String, dynamic>;
            highlightJson['imageUrl'] = firebaseUrl;
            highlightJson['image_url'] = firebaseUrl; // Also update the legacy field
          }

          AppLogger.database('Successfully uploaded banner image to Firebase: $firebaseUrl', tag: 'PHOTO_UPLOAD_COORDINATOR');
        }
      }
    } catch (e) {
      AppLogger.databaseError('Failed to upload banner image to Firebase', tag: 'PHOTO_UPLOAD_COORDINATOR', error: e);
      rethrow;
    }
  }

  /// Upload local achievement photos to Firebase
  Future<void> _uploadLocalAchievementPhotosToFirebase(
    List<dynamic> achievements,
    Map<String, dynamic>? changedExtraInfoFields,
  ) async {
    for (int i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      if (achievement?.photoUrl != null && _fileUploadService.isLocalPath(achievement!.photoUrl!)) {
        AppLogger.database(
          'Uploading local photo for achievement: ${achievement?.title ?? 'Unknown'}',
          tag: 'PHOTO_UPLOAD_COORDINATOR',
        );

        try {
          final firebaseUrl = await _fileUploadService.uploadLocalPhotoToFirebase(achievement!.photoUrl!);

          if (firebaseUrl != null) {
            // Update the achievement with the Firebase URL
            achievements[i] = achievement.copyWith(photoUrl: firebaseUrl);

            // Also update the changed fields if this achievement was modified
            if (changedExtraInfoFields != null && changedExtraInfoFields.containsKey('achievements')) {
              final achievementsJson = changedExtraInfoFields['achievements'] as List<dynamic>;
              if (i < achievementsJson.length && achievementsJson[i] is Map<String, dynamic>) {
                (achievementsJson[i] as Map<String, dynamic>)['photoUrl'] = firebaseUrl;
              }
            }

            AppLogger.database(
              'Successfully uploaded photo for: ${achievement.title ?? 'Unknown'}',
              tag: 'PHOTO_UPLOAD_COORDINATOR',
            );
          }
        } catch (e) {
          AppLogger.databaseError('Failed to upload photo for ${achievement?.title ?? 'Unknown'}', tag: 'PHOTO_UPLOAD_COORDINATOR', error: e);
          // Continue with other photos even if one fails
        }
      }
    }
  }

  /// Get file upload service instance
  FileUploadService getFileUploadService() {
    return _fileUploadService;
  }
}
