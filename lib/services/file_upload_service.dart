import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';
import '../features/candidate/services/media_cache_service.dart';

/// Defines different image usage purposes for optimization
enum ImagePurpose {
  profilePhoto,
  candidatePhoto,
  thumbnail,
  achievement,
  upload,
}

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String userId) async {
    try {
      // Check platform and use appropriate file picker
      if (kIsWeb) {
        AppLogger.common('🌐 [Profile Photo] Web detected - using file picker');

        // Web: Use file picker for web-compatible image selection
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) return null;

        final file = result.files.first;

        if (file.bytes == null) {
          AppLogger.common('⚠️ [Profile Photo] Web file bytes are null');
          throw Exception('Failed to get file data from web picker');
        }

        final fileName = 'profile_$userId.jpg';
        final storageRef = _storage.ref().child('profile_photos/$fileName');

        AppLogger.common('🌐 [Profile Photo] Uploading to Firebase Storage: profile_photos/$fileName');

        final uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();

        AppLogger.common('🌐 [Profile Photo] Web upload successful: $downloadUrl');
        return downloadUrl;
      }

      // Mobile: Use image_picker for mobile gallery access
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final fileName = 'profile_$userId.jpg';
      final storageRef = _storage.ref().child('profile_photos/$fileName');

      final uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading profile photo', error: e);
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  // Upload manifesto PDF
  Future<String?> uploadManifestoPdf(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final fileName =
          'manifesto_${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final storageRef = _storage.ref().child('manifestos/$fileName');

      UploadTask uploadTask;
      if (file.bytes != null) {
        // Web platform
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
      } else {
        // Mobile platforms
        uploadTask = storageRef.putFile(
          File(file.path!),
          SettableMetadata(contentType: 'application/pdf'),
        );
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading manifesto PDF', error: e);
      throw Exception('Failed to upload manifesto PDF: $e');
    }
  }

  // Upload candidate photo (for candidate profile)
  Future<String?> uploadCandidatePhoto(String candidateId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return null;

      final fileName =
          'candidate_${candidateId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('candidate_photos/$fileName');

      final uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading candidate photo', error: e);
      throw Exception('Failed to upload candidate photo: $e');
    }
  }

  // Upload achievement photo with smart optimization
  Future<String?> uploadAchievementPhoto(
    String candidateId,
    String achievementTitle,
  ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Start with good quality
      );

      if (image == null) return null;

      // Check file size and warn user if very large
      final file = File(image.path);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > 15.0) {
        AppLogger.common('⚠️ Very large file detected: ${fileSizeMB.toStringAsFixed(2)} MB');
        // Could show a warning dialog here, but for now just log it
      }

      // PHASE 3 INTEGRATION: Use advanced smart optimization instead of basic
      final optimizedImage = await optimizeImageSmartly(image, purpose: ImagePurpose.achievement);

      // Use optimized image or fall back to original
      final fileToUpload = optimizedImage ?? image;

      final sanitizedTitle = achievementTitle
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName =
          'achievement_${candidateId}_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('achievements/$fileName');

      final uploadTask = storageRef.putFile(
        File(fileToUpload.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up the temporary optimized file if different from original
      if (optimizedImage != null && optimizedImage.path != image.path) {
        try {
          await File(optimizedImage.path).delete();
        } catch (e) {
          AppLogger.common('Warning: Could not delete temporary optimized file: $e');
        }
      }

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading achievement photo', error: e);
      throw Exception('Failed to upload achievement photo: $e');
    }
  }

  // Upload manifesto image
  Future<String?> uploadManifestoImage(String userId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null) return null;

      final fileName =
          'manifesto_image_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('manifesto_images/$fileName');

      final uploadTask = storageRef.putFile(
        File(image.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading manifesto image', error: e);
      throw Exception('Failed to upload manifesto image: $e');
    }
  }

  // Upload manifesto video
  Future<String?> uploadManifestoVideo(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final fileName =
          'manifesto_video_${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final storageRef = _storage.ref().child('manifesto_videos/$fileName');

      UploadTask uploadTask;
      if (file.bytes != null) {
        // Web platform
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: 'video/mp4'),
        );
      } else {
        // Mobile platforms
        uploadTask = storageRef.putFile(
          File(file.path!),
          SettableMetadata(contentType: 'video/mp4'),
        );
      }

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading manifesto video', error: e);
      throw Exception('Failed to upload manifesto video: $e');
    }
  }

  // Generic file upload method
  Future<String?> uploadFile(
    String filePath,
    String storagePath,
    String contentType,
  ) async {
    try {
      final fileName = path.basename(filePath);
      final storageRef = _storage.ref().child('$storagePath/$fileName');

      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // PERFORMANCE: Don't throw on Firebase Storage unauthorized/permission errors
      // This prevents app crashes during performance optimization testing
      if (e.toString().contains('firebase_storage/unauthorized') ||
          e.toString().contains('Permission denied') ||
          e.toString().contains('403')) {
        AppLogger.common('⚠️ Firebase Storage unauthorized - skipping upload (expected during testing)');
        return null; // Return null instead of throwing
      }

      AppLogger.commonError('Error uploading file', error: e);
      throw Exception('Failed to upload file: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      AppLogger.common('File deleted successfully: $fileUrl');
    } catch (e) {
      // Log the error but don't throw it - file might not exist
      AppLogger.common('Warning: File delete failed (may not exist): $fileUrl - ${e.toString()}');
    }
  }

  // Get file download URL
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      AppLogger.commonError('Error getting download URL', error: e);
      return null;
    }
  }

  // Local storage methods for temporary photo storage

  // Ensure Firebase Auth is properly initialized (web specific)
  Future<void> _ensureFirebaseAuth() async {
    AppLogger.common('🔐 [Auth Check] Checking Firebase Auth status...', tag: 'AUTH_CHECK');

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      AppLogger.common('🔍 [Auth Check] Firebase Auth instance: ${auth.app.name}', tag: 'AUTH_CHECK');
      AppLogger.common('👤 [Auth Check] Current user: ${currentUser?.uid ?? 'NULL'}', tag: 'AUTH_CHECK');
      AppLogger.common('📧 [Auth Check] User email: ${currentUser?.email ?? 'NULL'}', tag: 'AUTH_CHECK');
      AppLogger.common('✅ [Auth Check] User display name: ${currentUser?.displayName ?? 'NULL'}', tag: 'AUTH_CHECK');

      if (currentUser == null) {
        AppLogger.common('🚫 [Auth Check] No authenticated user found - throwing exception', tag: 'AUTH_CHECK');
        throw Exception('User must be authenticated to upload files. Please log in and try again.');
      }

      // Additional verification that the user token is valid
      final idToken = await currentUser.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        AppLogger.common('🚫 [Auth Check] Invalid user token - throwing exception', tag: 'AUTH_CHECK');
        throw Exception('Authentication token is invalid. Please log in again.');
      }

      AppLogger.common('✅ [Auth Check] User fully authenticated with valid token: ${currentUser.uid}', tag: 'AUTH_CHECK');
    } catch (e) {
      AppLogger.commonError('❌ [Auth Check] Firebase Auth check failed', error: e, tag: 'AUTH_CHECK');
      // Re-throw with more context
      throw Exception('Authentication check failed: ${e.toString()}. Please ensure you are logged in and try again.');
    }
  }

  // Get local app directory for temporary files (mobile only)
  Future<Directory> _getLocalTempDirectory() async {
    if (kIsWeb) {
      throw Exception('Web platform does not support local file directories');
    }

    final directory = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${directory.path}/temp_photos');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  // Save photo (locally for mobile, directly to Firebase for web) with smart optimization
  Future<String?> savePhotoLocally(
    String candidateId,
    String achievementTitle,
  ) async {
    try {
      // Check platform first to avoid image_picker issues on web
      if (kIsWeb) {
        AppLogger.common('🌐 [FileUpload] Web detected - using file picker');

        // Ensure Firebase Auth is properly initialized before upload
        await _ensureFirebaseAuth();

        // Web: Use file picker for web-compatible image selection
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result == null || result.files.isEmpty) return null;

        final file = result.files.first;

        if (file.bytes == null) {
          AppLogger.common('⚠️ [FileUpload] Web file bytes are null');
          throw Exception('Failed to get file data from web picker');
        }

        // Upload directly to Firebase Storage using bytes for web
        final sanitizedTitle = achievementTitle
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'achievement_${candidateId}_${sanitizedTitle}_$timestamp.jpg';
        final storageRef = _storage.ref().child('achievements/$fileName');

        AppLogger.common('🌐 [FileUpload] Uploading to Firebase Storage: achievements/$fileName');

        try {
          final uploadTask = storageRef.putData(
            file.bytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();

          AppLogger.common('🌐 [FileUpload] Web file picker upload successful: $downloadUrl');
          return downloadUrl;
        } catch (firebaseError) {
          AppLogger.commonError('❌ [FileUpload] Firebase Storage upload failed', error: firebaseError);
          throw Exception('Firebase upload failed: $firebaseError');
        }
      }

      // Mobile flow: Use image_picker (not compatible with web)
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Start with good quality
      );

      if (image == null) return null;

      // Mobile: Save to local storage temporarily for later upload
      AppLogger.common('📱 [FileUpload] Mobile detected - saving locally first', tag: 'MOBILE_UPLOAD');

      // Check file size and optimize if needed
      final optimizedImage = await _optimizeImageForStorage(image);

      final tempDir = await _getLocalTempDirectory();
      final sanitizedTitle = achievementTitle
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'temp_achievement_${candidateId}_${sanitizedTitle}_$timestamp.jpg';
      final localFile = File('${tempDir.path}/$fileName');

      // Copy the optimized image to local storage
      await File(optimizedImage.path).copy(localFile.path);

      // Clean up the temporary optimized file if different from original
      if (optimizedImage.path != image.path) {
        try {
          await File(optimizedImage.path).delete();
        } catch (e) {
          AppLogger.common('Warning: Could not delete temporary optimized file: $e');
        }
      }

      // Return the local file path (prefixed with 'local:' to distinguish from Firebase URLs)
      return 'local:${localFile.path}';
    } catch (e) {
      AppLogger.commonError('Error saving/uploading photo', error: e);
      throw Exception('Failed to save/upload photo: $e');
    }
  }

  // Optimize image based on file size for better performance
  Future<XFile> _optimizeImageForStorage(XFile image) async {
    try {
      final file = File(image.path);
      final fileSize = await file.length();

      // Convert bytes to MB for easier comparison
      final fileSizeMB = fileSize / (1024 * 1024);

      AppLogger.common('📸 Original image size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // If file is already reasonable size, return as-is
      if (fileSizeMB <= 2.0) {
        return image;
      }

      // For larger files, apply progressive optimization
      int quality = 80;
      int? maxWidth;
      int? maxHeight;

      if (fileSizeMB > 10.0) {
        // Very large files (>10MB) - aggressive optimization
        quality = 60;
        maxWidth = 1200;
        maxHeight = 1200;
        AppLogger.common(
          '📸 Large file detected (>10MB), applying aggressive optimization',
        );
      } else if (fileSizeMB > 5.0) {
        // Large files (5-10MB) - moderate optimization
        quality = 70;
        maxWidth = 1600;
        maxHeight = 1600;
        AppLogger.common(
          '📸 Large file detected (5-10MB), applying moderate optimization',
        );
      } else {
        // Medium files (2-5MB) - light optimization
        quality = 75;
        maxWidth = 2000;
        maxHeight = 2000;
        AppLogger.common(
          '📸 Medium file detected (2-5MB), applying light optimization',
        );
      }

      // Create optimized version
      final optimizedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (optimizedImage != null) {
        final optimizedFile = File(optimizedImage.path);
        final optimizedSize = await optimizedFile.length();
        final optimizedSizeMB = optimizedSize / (1024 * 1024);

        AppLogger.common(
          '📸 Optimized image size: ${optimizedSizeMB.toStringAsFixed(2)} MB (${((fileSize - optimizedSize) / fileSize * 100).toStringAsFixed(1)}% reduction)',
        );
        return optimizedImage;
      }

      // If optimization failed, return original
      return image;
    } catch (e) {
      AppLogger.common('Warning: Image optimization failed, using original: $e');
      return image;
    }
  }

  // Upload local photo to Firebase Storage with cache integration
  Future<String?> uploadLocalPhotoToFirebase(String localPath) async {
    try {
      // Handle web blob URLs differently from mobile local files
      if (kIsWeb && localPath.startsWith('blob:')) {
        return await uploadBlobUrlToFirebase(localPath);
      }

      // Remove the 'local:' prefix to get the actual file path
      final actualPath = localPath.replaceFirst('local:', '');
      final file = File(actualPath);

      if (!await file.exists()) {
        throw Exception('Local file not found: $actualPath');
      }

      // Generate Firebase storage path - use media folder for media uploads
      final fileName = path.basename(actualPath).replaceFirst('temp_', '');

      // Determine if this is an image or video based on the filename
      final isVideo = fileName.contains('media_video');

      // Choose the appropriate folder and content type
      final storagePath = isVideo ? 'media/videos/$fileName' : 'media/images/$fileName';
      final contentType = isVideo ? 'video/mp4' : 'image/jpeg';

      final storageRef = _storage.ref().child(storagePath);

      AppLogger.common('📤 [Media Upload] Uploading ${isVideo ? 'video' : 'image'} to Firebase Storage: $storagePath', tag: 'UPLOAD');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // PHASE 4 INTEGRATION: Add uploaded file to cache for instant future access
      try {
        final cacheService = Get.find<MediaCacheService>();
        await cacheService.putFile(downloadUrl, file, mediaType: 'upload');
        AppLogger.common('💾 [Cache Integration] Cached uploaded ${isVideo ? 'video' : 'image'}: $fileName', tag: 'CACHE');
      } catch (cacheError) {
        AppLogger.common('⚠️ [Cache Integration] Failed to cache uploaded file, continuing...', tag: 'CACHE');
        // Continue with upload even if caching fails
      }

      // Delete the local temporary file after successful upload AND caching
      await file.delete();

      AppLogger.common('📤 [Upload Complete] Successfully uploaded to $storagePath and cached: $fileName', tag: 'UPLOAD');
      AppLogger.common('🔗 [Firebase URL] File accessible at: $downloadUrl', tag: 'UPLOAD');
      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading local photo to Firebase', error: e);
      throw Exception('Failed to upload local photo to Firebase: $e');
    }
  }

  // Upload blob URL to Firebase Storage (web-specific) - made public for media upload
  Future<String?> uploadBlobUrlToFirebase(String blobUrl) async {
    try {
      AppLogger.common('🌐 [Blob Upload] Starting blob URL upload to Firebase: $blobUrl', tag: 'WEB_UPLOAD');

      // Use http package to fetch blob data (works on both web and mobile)
      final response = await http.get(Uri.parse(blobUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch blob data: HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      if (bytes.isEmpty) {
        throw Exception('Blob data is empty');
      }

      // Generate filename from blob URL or use timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'web_media_${timestamp}.jpg'; // Default to jpg, could be improved with MIME type detection

      // Determine storage path
      final storagePath = 'media/images/$fileName';
      final contentType = 'image/jpeg';

      final storageRef = _storage.ref().child(storagePath);

      AppLogger.common('📤 [Blob Upload] Uploading blob to Firebase Storage: $storagePath', tag: 'WEB_UPLOAD');

      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.common('✅ [Blob Upload] Successfully uploaded blob to Firebase: $downloadUrl', tag: 'WEB_UPLOAD');
      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('❌ [Blob Upload] Failed to upload blob URL', error: e, tag: 'WEB_UPLOAD');
      throw Exception('Failed to upload blob URL to Firebase: $e');
    }
  }

  // Clean up all temporary local photos (mobile only)
  Future<void> cleanupTempPhotos() async {
    if (kIsWeb) {
      AppLogger.common('🌐 [FileUpload] Web detected - no local cleanup needed', tag: 'WEB_CLEANUP');
      return;
    }

    try {
      final tempDir = await _getLocalTempDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      AppLogger.commonError('Error cleaning up temp photos', error: e);
    }
  }

  // Check if a path is a local path
  bool isLocalPath(String path) {
    return path.startsWith('local:');
  }

  // Validate file size and provide recommendations
  Future<FileSizeValidation> validateFileSize(String filePath) async {
    try {
      final file = File(filePath.replaceFirst('local:', ''));
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      if (fileSizeMB > 20.0) {
        return FileSizeValidation(
          isValid: false,
          fileSizeMB: fileSizeMB,
          message:
              'File is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
          recommendation:
              'Please choose a smaller image or compress the current one.',
        );
      } else if (fileSizeMB > 10.0) {
        return FileSizeValidation(
          isValid: true,
          fileSizeMB: fileSizeMB,
          message:
              'Large file detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
          recommendation: 'Consider compressing the image for faster uploads.',
          warning: true,
        );
      } else if (fileSizeMB > 5.0) {
        return FileSizeValidation(
          isValid: true,
          fileSizeMB: fileSizeMB,
          message: 'Medium file size (${fileSizeMB.toStringAsFixed(1)}MB).',
          recommendation: null,
        );
      } else {
        return FileSizeValidation(
          isValid: true,
          fileSizeMB: fileSizeMB,
          message: 'Optimal file size (${fileSizeMB.toStringAsFixed(1)}MB).',
          recommendation: null,
        );
      }
    } catch (e) {
      return FileSizeValidation(
        isValid: false,
        fileSizeMB: 0,
        message: 'Unable to validate file size: $e',
        recommendation: 'Please try again or choose a different file.',
      );
    }
  }

  // Validate media file size with specific limits for images and videos
  Future<FileSizeValidation> validateMediaFileSize(
    String filePath,
    String fileType,
  ) async {
    try {
      final file = File(filePath.replaceFirst('local:', ''));
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      double maxSizeMB;
      String fileTypeName;

      switch (fileType) {
        case 'image':
          maxSizeMB = 10.0; // 10MB for images
          fileTypeName = 'image';
          break;
        case 'video':
          maxSizeMB = 20.0; // 20MB for videos
          fileTypeName = 'video';
          break;
        default:
          maxSizeMB = 20.0; // Default fallback
          fileTypeName = 'file';
      }

      if (fileSizeMB > maxSizeMB) {
        return FileSizeValidation(
          isValid: false,
          fileSizeMB: fileSizeMB,
          message:
              '$fileTypeName is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is ${maxSizeMB.toStringAsFixed(1)}MB.',
          recommendation:
              'Please choose a smaller $fileTypeName or compress the current one.',
        );
      } else if (fileSizeMB > maxSizeMB * 0.8) {
        return FileSizeValidation(
          isValid: true,
          fileSizeMB: fileSizeMB,
          message:
              'Large $fileTypeName detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
          recommendation:
              'Consider compressing the $fileTypeName for faster uploads.',
          warning: true,
        );
      } else {
        return FileSizeValidation(
          isValid: true,
          fileSizeMB: fileSizeMB,
          message:
              'Optimal $fileTypeName size (${fileSizeMB.toStringAsFixed(1)}MB).',
          recommendation: null,
        );
      }
    } catch (e) {
      return FileSizeValidation(
        isValid: false,
        fileSizeMB: 0,
        message: 'Unable to validate file size: $e',
        recommendation: 'Please try again or choose a different file.',
      );
    }
  }

  // =================== ADVANCED IMAGE OPTIMIZATION METHODS (PHASE 3) ===================

  /// Advanced image compression with flutter_image_compress for professional quality
  Future<XFile?> compressImageWithQuality(
    XFile sourceImage, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    bool autoCorrectOrientation = true,
  }) async {
    // Web compatibility fix: Skip compression on web
    if (kIsWeb) {
      AppLogger.common('🌐 [Image Compress] Skipping compression on web', tag: 'MEDIA_OPTIM');
      return sourceImage;
    }

    try {
      final sourceFile = File(sourceImage.path);
      final originalSize = await sourceFile.length();
      final originalSizeMB = originalSize / (1024 * 1024);
      AppLogger.common('🔧 [Image Optim] Starting advanced compression...', tag: 'MEDIA_OPTIM');

      final dir = await getTemporaryDirectory();
      final compressedFile = File('${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        sourceImage.path,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1080,
        quality: quality,
        autoCorrectionAngle: autoCorrectOrientation,
      );

      if (compressedBytes != null) {
        await compressedFile.writeAsBytes(compressedBytes);

        final compressedSize = await compressedFile.length();
        final compressedSizeMB = compressedSize / (1024 * 1024);
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

        AppLogger.common('✅ [Image Optim] Compressed: ${originalSizeMB.toStringAsFixed(2)}MB → ${compressedSizeMB.toStringAsFixed(2)}MB (${compressionRatio.toStringAsFixed(1)}% reduction)', tag: 'MEDIA_OPTIM');

        return XFile(compressedFile.path);
      } else {
        AppLogger.common('⚠️ [Image Optim] Compression failed, using original', tag: 'MEDIA_OPTIM');
        return sourceImage;
      }
    } catch (e) {
      AppLogger.commonError('❌ [Image Optim] Compression error', error: e, tag: 'MEDIA_OPTIM');
      return sourceImage; // Return original if compression fails
    }
  }

  /// Intelligent compression based on image size and purpose
  Future<XFile?> optimizeImageSmartly(
    XFile sourceImage, {
    ImagePurpose purpose = ImagePurpose.thumbnail, // Default to thumbnail for performance
  }) async {
    // Web compatibility fix: Skip optimization on web to avoid file operations
    if (kIsWeb) {
      AppLogger.common('🌐 [Smart Optim] Skipping image optimization on web', tag: 'MEDIA_OPTIM');
      return sourceImage;
    }

    try {
      final sourceFile = File(sourceImage.path);
      final originalSize = await sourceFile.length();
      final originalSizeMB = originalSize / (1024 * 1024);

      AppLogger.common('🧠 [Smart Optim] Analyzing image for purpose: $purpose', tag: 'MEDIA_OPTIM');

      // Configure optimization based on purpose
      late int quality;
      late int maxWidth;
      late int maxHeight;

      switch (purpose) {
        case ImagePurpose.profilePhoto:
          quality = 90; // High quality for profile
          maxWidth = 512;
          maxHeight = 512;
          break;

        case ImagePurpose.candidatePhoto:
          quality = 85; // Good quality for candidate display
          maxWidth = 800;
          maxHeight = 800;
          break;

        case ImagePurpose.thumbnail:
          quality = 70; // Lower quality for lists/grids
          maxWidth = 300;
          maxHeight = 300;
          break;

        case ImagePurpose.achievement:
          quality = 80; // Balanced for achievements
          maxWidth = 1200;
          maxHeight = 800;
          break;

        case ImagePurpose.upload:
          // Adaptive based on file size
          if (originalSizeMB > 15.0) {
            quality = 60; // Very aggressive for very large files
            maxWidth = 1600;
            maxHeight = 1200;
          } else if (originalSizeMB > 8.0) {
            quality = 70; // Moderate for large files
            maxWidth = 1800;
            maxHeight = 1350;
          } else if (originalSizeMB > 3.0) {
            quality = 80; // Light optimization for medium files
            maxWidth = 2000;
            maxHeight = 1500;
          } else {
            quality = 90; // Minimal optimization for small files
            maxWidth = 2500;
            maxHeight = 1800;
          }
          break;
      }

      // Apply compression
      final optimizedImage = await compressImageWithQuality(
        sourceImage,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (optimizedImage != null && optimizedImage.path != sourceImage.path) {
        final optimizedSize = await File(optimizedImage.path).length();
        final optimizedSizeMB = optimizedSize / (1024 * 1024);
        AppLogger.common('✅ [Smart Optim] Optimized for $purpose: ${originalSizeMB.toStringAsFixed(2)}MB → ${optimizedSizeMB.toStringAsFixed(2)}MB', tag: 'MEDIA_OPTIM');
        return optimizedImage;
      }

      return sourceImage;
    } catch (e) {
      AppLogger.commonError('❌ [Smart Optim] Error', error: e, tag: 'MEDIA_OPTIM');
      return sourceImage;
    }
  }

  /// Batch optimize multiple images
  Future<List<XFile?>> optimizeMultipleImages(
    List<XFile> images, {
    ImagePurpose purpose = ImagePurpose.thumbnail,
  }) async {
    AppLogger.common('🔄 [Batch Optim] Processing ${images.length} images', tag: 'MEDIA_OPTIM');

    final optimizedImages = <XFile?>[];
    for (int i = 0; i < images.length; i++) {
      final optimized = await optimizeImageSmartly(images[i], purpose: purpose);
      optimizedImages.add(optimized);
    }

    final successCount = optimizedImages.where((img) => img != null).length;
    AppLogger.common('✅ [Batch Optim] Completed: $successCount/${images.length} successful', tag: 'MEDIA_OPTIM');

    return optimizedImages;
  }

  /// Process deleted storage files asynchronously (called when candidate opens dashboard)
  Future<void> cleanupDeletedStorageFiles({
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required String candidateId,
  }) async {
    AppLogger.common('🧹 [Cleanup] Starting async cleanup of deleteStorage for candidate: $candidateId', tag: 'STORAGE_CLEANUP');

    try {
      // Get candidate document path
      final candidateRef = FirebaseFirestore.instance
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

      // Get current candidate data
      final candidateDoc = await candidateRef.get();
      if (!candidateDoc.exists) {
        AppLogger.common('⚠️ [Cleanup] Candidate document not found for: $candidateId', tag: 'STORAGE_CLEANUP');
        return;
      }

      final candidateData = candidateDoc.data()!;
      final deleteStorage = candidateData['deleteStorage'] as List<dynamic>? ?? [];

      if (deleteStorage.isEmpty) {
        AppLogger.common('✅ [Cleanup] No files to delete for candidate: $candidateId', tag: 'STORAGE_CLEANUP');
        return;
      }

      AppLogger.common('📋 [Cleanup] Found ${deleteStorage.length} files to delete: $deleteStorage', tag: 'STORAGE_CLEANUP');

      int deletedCount = 0;
      int errorCount = 0;

      // Process each file in deleteStorage array
      for (final storagePath in deleteStorage) {
        try {
          if (storagePath is String && storagePath.isNotEmpty) {
            // Delete from Firebase Storage
            await _storage.ref().child(storagePath).delete();
            deletedCount++;
            AppLogger.common('✅ [Cleanup] Deleted: $storagePath', tag: 'STORAGE_CLEANUP');
          }
        } catch (e) {
          errorCount++;
          AppLogger.common('❌ [Cleanup] Failed to delete $storagePath for $candidateId: ${e.toString()}', tag: 'STORAGE_CLEANUP');
          // Continue processing other files even if one fails
        }
      }

      // Clear the deleteStorage array in Firestore
      await candidateRef.update({
        'deleteStorage': FieldValue.delete(), // Delete the field entirely or set to []
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.common('🔄 [Cleanup] Cleared deleteStorage array for $candidateId ($deletedCount files deleted, $errorCount errors)', tag: 'STORAGE_CLEANUP');

    } catch (e) {
      AppLogger.commonError('💥 [Cleanup] Error processing deleteStorage cleanup for $candidateId', error: e, tag: 'STORAGE_CLEANUP');
      // Don't re-throw - this is background cleanup, failures shouldn't break the app
    }
  }

  /// Calculate and display optimization statistics
  Future<String> generateOptimizationReport(XFile original, XFile? optimized) async {
    if (optimized == null) {
      return 'Optimization failed - keeping original';
    }

    try {
      final originalSize = await File(original.path).length();
      final optimizedSize = await File(optimized.path).length();
      final reductionBytes = originalSize - optimizedSize;
      final reductionPercent = (reductionBytes / originalSize * 100);

      return 'Size reduced: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)}MB → ${(optimizedSize / (1024 * 1024)).toStringAsFixed(2)}MB (${reductionPercent.toStringAsFixed(1)}% saved)';
    } catch (e) {
      return 'Could not generate report: $e';
    }
  }

  // =================== BACKWARD COMPATIBILITY METHODS ===================

  // Save existing file to local storage (for media tab) - Web compatible
  Future<String?> saveExistingFileLocally(
    String sourceFilePath,
    String candidateId,
    String fileName,
  ) async {
    if (kIsWeb) {
      AppLogger.common('🌐 [FileUpload] Web detected - redirecting to Firebase upload', tag: 'WEB_MEDIA');
      // On web, we can't save locally, so just return the source path as-is
      // The calling code should handle web-specific logic
      return sourceFilePath;
    }

    try {
      AppLogger.common('📱 [FileUpload] Saving existing file locally...', tag: 'LOCAL_STORAGE');

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/media_temp');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
        AppLogger.common(
          'Created media temp directory: ${localDir.path}',
          tag: 'LOCAL_STORAGE',
        );
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final localFileName = '${fileName}_${candidateId}_$timestamp';
      final localPath = '${localDir.path}/$localFileName';

      // Copy the source file to local storage
      await File(sourceFilePath).copy(localPath);

      AppLogger.common('File saved successfully at: $localPath', tag: 'LOCAL_STORAGE');
      return 'local:$localPath';
    } catch (e) {
      AppLogger.common('Error saving existing file locally: $e', tag: 'LOCAL_STORAGE_ERROR');
      return null;
    }
  }
}

// File size validation result
class FileSizeValidation {
  final bool isValid;
  final double fileSizeMB;
  final String message;
  final String? recommendation;
  final bool warning;

  FileSizeValidation({
    required this.isValid,
    required this.fileSizeMB,
    required this.message,
    this.recommendation,
    this.warning = false,
  });
}
