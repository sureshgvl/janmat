import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/app_logger.dart';

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String userId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

      // Optimize the image if needed
      final optimizedImage = await _optimizeImageForStorage(image);

      final sanitizedTitle = achievementTitle
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final fileName =
          'achievement_${candidateId}_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('achievement_photos/$fileName');

      final uploadTask = storageRef.putFile(
        File(optimizedImage.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up the temporary optimized file if different from original
      if (optimizedImage.path != image.path) {
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
      AppLogger.commonError('Error uploading file', error: e);
      throw Exception('Failed to upload file: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      AppLogger.commonError('Error deleting file', error: e);
      // Don't throw error for delete failures as file might not exist
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

  // Get local app directory for temporary files
  Future<Directory> _getLocalTempDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final tempDir = Directory('${directory.path}/temp_photos');
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    return tempDir;
  }

  // Save photo to local storage temporarily with smart optimization
  Future<String?> savePhotoLocally(
    String candidateId,
    String achievementTitle,
  ) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Start with good quality
      );

      if (image == null) return null;

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
      AppLogger.commonError('Error saving photo locally', error: e);
      throw Exception('Failed to save photo locally: $e');
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

  // Upload local photo to Firebase Storage
  Future<String?> uploadLocalPhotoToFirebase(String localPath) async {
    try {
      // Remove the 'local:' prefix to get the actual file path
      final actualPath = localPath.replaceFirst('local:', '');
      final file = File(actualPath);

      if (!await file.exists()) {
        throw Exception('Local file not found: $actualPath');
      }

      // Generate Firebase storage path
      final fileName = path.basename(actualPath).replaceFirst('temp_', '');
      final storageRef = _storage.ref().child('achievement_photos/$fileName');

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Delete the local temporary file after successful upload
      await file.delete();

      return downloadUrl;
    } catch (e) {
      AppLogger.commonError('Error uploading local photo to Firebase', error: e);
      throw Exception('Failed to upload local photo to Firebase: $e');
    }
  }

  // Clean up all temporary local photos
  Future<void> cleanupTempPhotos() async {
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
          maxSizeMB = 3.0; // 3MB for videos
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

  // Save existing file to local storage (for media tab)
  Future<String?> saveExistingFileLocally(
    String sourceFilePath,
    String candidateId,
    String fileName,
  ) async {
    try {
      AppLogger.common('Saving existing file locally...', tag: 'LOCAL_STORAGE');

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
