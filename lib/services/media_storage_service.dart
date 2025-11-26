import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/utils/app_logger.dart';

/// Service for handling media storage across platforms
class MediaStorageService {
  static const String _mediaPrefix = 'media_';

  /// Save media locally (platform-aware)
  /// - Web: Returns blob URL as-is (already "local")
  /// - Mobile: Saves to device storage and returns local path
  static Future<String> saveMediaLocally(
    String sourcePath,
    String candidateId,
    String mediaType,
  ) async {
    try {
      if (kIsWeb) {
        // Web: sourcePath is already a blob URL, keep as-is
        AppLogger.candidate('📱 [WEB] Using blob URL as local reference: $sourcePath');
        return sourcePath;
      } else {
        // Mobile: Save file to local storage
        final localPath = await FileUploadService().saveExistingFileLocally(
          sourcePath,
          candidateId,
          '${_mediaPrefix}$mediaType',
        );

        if (localPath == null) {
          throw Exception('Failed to save file locally on mobile');
        }

        AppLogger.candidate('📱 [MOBILE] Saved to local storage: $localPath');
        return localPath;
      }
    } catch (e) {
      AppLogger.candidateError('❌ Failed to save media locally: $e');
      rethrow;
    }
  }

  /// Check if media path is local (not yet uploaded to Firebase)
  static bool isLocalMedia(String path) {
    if (kIsWeb) {
      // Web: blob URLs are local references
      return path.startsWith('blob:');
    } else {
      // Mobile: check if it's a local file path
      return FileUploadService().isLocalPath(path);
    }
  }

  /// Upload local media to Firebase Storage
  static Future<String?> uploadLocalMediaToFirebase(String localPath) async {
    try {
      AppLogger.candidate('⬆️ Uploading to Firebase: $localPath');
      final firebaseUrl = await FileUploadService().uploadLocalPhotoToFirebase(localPath);

      if (firebaseUrl != null) {
        AppLogger.candidate('✅ Successfully uploaded: $firebaseUrl');
        return firebaseUrl;
      } else {
        AppLogger.candidateError('❌ Upload returned null for: $localPath');
        return null;
      }
    } catch (e) {
      AppLogger.candidateError('❌ Failed to upload $localPath: $e');
      return null;
    }
  }

  /// Upload multiple local media files to Firebase
  static Future<List<String>> uploadLocalMediaBatch(
    List<String> localPaths,
    String mediaType,
    Function(String) onProgressUpdate,
  ) async {
    final firebaseUrls = <String>[];

    for (int i = 0; i < localPaths.length; i++) {
      final localPath = localPaths[i];

      // Update progress
      onProgressUpdate('Uploading ${i + 1}/${localPaths.length} $mediaType(s)...');

      // Upload file
      final firebaseUrl = await uploadLocalMediaToFirebase(localPath);

      if (firebaseUrl != null) {
        firebaseUrls.add(firebaseUrl);
      } else {
        // Keep original path if upload fails
        AppLogger.candidateError('⚠️ Keeping original path due to upload failure: $localPath');
        firebaseUrls.add(localPath);
      }
    }

    return firebaseUrls;
  }
}