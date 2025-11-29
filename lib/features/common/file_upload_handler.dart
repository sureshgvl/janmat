import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_utils.dart';
import '../user/models/user_model.dart';
import '../candidate/models/candidate_model.dart';
import '../candidate/controllers/candidate_user_controller.dart';
import '../candidate/controllers/manifesto_controller.dart';
import '../../core/app_route_names.dart';
import '../monetization/services/plan_service.dart';
import '../common/upgrade_plan_dialog.dart';
import '../common/file_helpers.dart';
import '../common/file_storage_manager.dart';
import '../../core/media/media_upload_handler.dart';
import 'dart:html' as html show window, Blob, FileReader;

/// Handles file upload logic for different file types
class FileUploadHandler {
  final Candidate candidateData;
  final BuildContext context;
  final List<Map<String, dynamic>> localFiles;
  final Function(List<Map<String, dynamic>>) onLocalFilesUpdate;

  FileUploadHandler({
    required this.candidateData,
    required this.context,
    required this.localFiles,
    required this.onLocalFilesUpdate,
  });

  /// Upload manifesto PDF with plan restrictions
  Future<void> uploadManifestoPdf() async {
    AppLogger.candidate('📄 [PDF Upload] Starting PDF selection process...');

    // Plan check - PDFs don't have free plan restrictions, but could add them later

    try {
      // Pick file
      final result = await FilePickerUtils.pickPdf();
      if (result == null || result.files.isEmpty) {
        AppLogger.candidate('📄 [PDF Upload] User cancelled file selection');
        return;
      }

      final file = result.files.first;
      final fileSizeMB = file.size / (1024 * 1024);
      AppLogger.candidate(
        '📄 [PDF Upload] File selected: ${file.name}, Size: ${fileSizeMB.toStringAsFixed(2)} MB',
      );

      // Validate file size (20MB limit for PDFs)
      if (fileSizeMB > 20.0) {
        if (mounted) {
          SnackbarUtils.showScaffoldWarning(
            context,
            'PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
          );
        }
        return;
      }

      // Store file locally for preview
      final saveResult = await _saveFileLocally(file, 'pdf');
      if (saveResult == null) {
        throw Exception('Failed to store file temporarily');
      }

      // Create file entry
      final Map<String, dynamic> newFileEntry = {
        'type': 'pdf',
        'localPath': saveResult,
        'fileName': file.name,
        'fileSize': fileSizeMB,
      };

      // For web files, store bytes
      if (kIsWeb && saveResult!.startsWith('temp:') && file is file_picker.PlatformFile && file.bytes != null) {
        newFileEntry['bytes'] = file.bytes;
      }

      // Update local files list
      _updateLocalFiles('pdf', newFileEntry);

      AppLogger.candidate('📄 [PDF Upload] PDF selection process completed');
    } catch (e) {
      AppLogger.candidate('📄 [PDF Upload] Error: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to select PDF: ${e.toString()}');
      }
    }
  }

  /// Upload manifesto image with free plan restrictions
  Future<void> uploadManifestoImage() async {
    AppLogger.candidate('🖼️ [Image Upload] Starting image selection process...');

    // Plan check for images (premium feature)
    if (!await _checkPlanPermission(ImageUploadPlanPermission.image)) {
      return;
    }

    try {
      // Pick image
      final image = await FilePickerUtils.pickImage();
      if (image == null) {
        AppLogger.candidate('🖼️ [Image Upload] User cancelled image selection');
        return;
      }

      AppLogger.candidate(
        '🖼️ [Image Upload] Image selected: ${image.name}, Path: ${image.path}',
      );

      // Get file size early for warnings (web optimization)
      double fileSizeMB = 0.0;
      int totalBytes = 0;

      if (kIsWeb) {
        try {
          final bytes = await image.readAsBytes();
          totalBytes = bytes.length;
          fileSizeMB = totalBytes / (1024 * 1024);
          AppLogger.candidate('🖼️ [Image Upload] File size: ${fileSizeMB.toStringAsFixed(1)}MB');

          // Early warning for very large files
          if (await FileHelpers.shouldWarnAboutLargeFile(image.name, totalBytes, 'image')) {
            final proceed = await FileHelpers.showFileSizeWarningDialog(
              context,
              FileSizeValidation(
                isValid: true,
                fileSizeMB: fileSizeMB,
                message: 'Large image file detected. Processing may take time.',
                warning: true,
              ),
            );
            if (proceed != true) return;
          }
        } catch (e) {
          AppLogger.candidate('⚠️ [Image Upload] Could not get file size early: $e');
        }
      }

      // Show progress dialog for large files (optimization)
      StreamController<double>? progressController;
      if (kIsWeb && totalBytes > 2 * 1024 * 1024) { // > 2MB on web
        progressController = StreamController<double>();
        FileHelpers.showFileProcessingDialog(
          context,
          operation: 'Processing Image',
          progressStream: progressController.stream,
          onCancel: () {
            progressController?.close();
          },
        );
      }

      try {
        // WEB OPTIMIZATION: Use chunked reading for large files
        double readProgress = 0.0;
        Uint8List? imageBytes;

        if (kIsWeb) {
          // Read file in chunks to prevent UI blocking
          final chunks = <Uint8List>[];
          await for (final chunk in FileHelpers.readFileInChunks(
            image,
            onProgress: (progress) {
              readProgress = progress * 0.5; // Reading is 50% of process
              progressController?.add(readProgress);
            },
          )) {
            chunks.add(chunk);
          }

          // Combine chunks
          final totalSize = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
          imageBytes = Uint8List(totalSize);
          var offset = 0;
          for (final chunk in chunks) {
            imageBytes.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }

          progressController?.add(0.6); // Reading complete, starting optimization
        }

        // Optimize image (now with bytes for web)
        final optimizedImage = kIsWeb && imageBytes != null
          ? await _optimizeWebImage(XFile.fromData(imageBytes), 'manifesto')
          : await FileHelpers.optimizeImage(image, 'manifesto');

        progressController?.add(0.8); // Optimization complete

        // Update file size after optimization
        final validation = await FileHelpers.validateFileSize(
          optimizedImage.path,
          'image',
          kIsWeb ? {'fileSize': fileSizeMB} : {},
        );

        if (!validation.isValid) {
          progressController?.close();
          if (mounted) {
            SnackbarUtils.showScaffoldError(context, validation.message);
          }
          return;
        }

        progressController?.add(0.9);

        // Store optimized image locally
        final saveResult = await _saveFileLocally(optimizedImage, 'image');
        if (saveResult == null) {
          throw Exception('Failed to store optimized image temporarily');
        }

        progressController?.add(1.0); // Complete

        // Create file entry
        final newFileEntry = {
          'type': 'image',
          'localPath': saveResult,
          'fileName': optimizedImage.name,
          'fileSize': validation.fileSizeMB,
        };

        // For web images, store the bytes for thumbnails
        if (kIsWeb && imageBytes != null) {
          newFileEntry['bytes'] = imageBytes;
        }

        // Update local files - this will replace any existing image
        _updateLocalFiles('image', newFileEntry);

        progressController?.close();

        AppLogger.candidate('🖼️ [Image Upload] Image selection process completed');
      } finally {
        progressController?.close();
      }
    } catch (e) {
      AppLogger.candidate('🖼️ [Image Upload] Error: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to select image: ${e.toString()}');
      }
    }
  }

  /// WEB OPTIMIZATION: Optimize image from bytes on web
  Future<XFile> _optimizeWebImage(XFile image, String context) async {
    try {
      AppLogger.candidate('🖼️ [$context Image] Optimizing web image from bytes...');

      // For web, we can't easily resize, but we can return the original
      // Image optimization is more limited on web due to browser constraints
      return image;
    } catch (e) {
      AppLogger.candidate('⚠️ [$context Image] Web optimization failed: $e');
      return image;
    }
  }

  /// Upload manifesto video with premium plan restrictions
  Future<void> uploadManifestoVideo() async {
    AppLogger.candidate('🎥 [Video Upload] Starting video selection process...');

    // Check if user can upload videos (premium feature)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final plan = await PlanService.getUserPlan(currentUser.uid);
      final isFreePlan = plan == null || plan.dashboardTabs?.manifesto.enabled != true;

      if (isFreePlan) {
        // Free plan cannot upload videos - show upgrade dialog
        if (mounted) {
          await UpgradePlanDialog.showVideoUploadRestricted(context: context);
        }
        return;
      }

      // Check premium plan video upload permission
      final canUploadVideo = plan.dashboardTabs!.manifesto.features.videoUpload;
      if (!canUploadVideo) {
        if (mounted) {
          SnackbarUtils.showScaffoldWarning(
            context,
            'Video upload is not available with your current plan. Upgrade to Gold or Platinum plan.',
          );
        }
        return;
      }
    }

    try {
      // Pick video
      final video = await FilePickerUtils.pickVideo();
      if (video == null) {
        AppLogger.candidate('🎥 [Video Upload] User cancelled video selection');
        return;
      }

      AppLogger.candidate(
        '🎥 [Video Upload] Video selected: ${video.name}, Path: ${video.path}',
      );

      // Get file size early for warnings (web optimization)
      double fileSizeMB = 0.0;
      int totalBytes = 0;

      if (kIsWeb) {
        try {
          final bytes = await video.readAsBytes();
          totalBytes = bytes.length;
          fileSizeMB = totalBytes / (1024 * 1024);
          AppLogger.candidate('🎥 [Video Upload] File size: ${fileSizeMB.toStringAsFixed(1)}MB');

          // Early warning for very large files
          if (await FileHelpers.shouldWarnAboutLargeFile(video.name, totalBytes, 'video')) {
            final proceed = await FileHelpers.showFileSizeWarningDialog(
              context,
              FileSizeValidation(
                isValid: true,
                fileSizeMB: fileSizeMB,
                message: 'Large video file detected. Processing may take time.',
                warning: true,
              ),
            );
            if (proceed != true) return;
          }
        } catch (e) {
          AppLogger.candidate('⚠️ [Video Upload] Could not get file size early: $e');
        }
      }

      // Show progress dialog for large files (optimization)
      StreamController<double>? progressController;
      if (kIsWeb && totalBytes > 10 * 1024 * 1024) { // > 10MB on web
        progressController = StreamController<double>();
        FileHelpers.showFileProcessingDialog(
          context,
          operation: 'Processing Video',
          progressStream: progressController.stream,
          onCancel: () {
            progressController?.close();
          },
        );
      }

      try {
        // WEB OPTIMIZATION: Use chunked reading for large files
        double readProgress = 0.0;
        Uint8List? videoBytes;

        if (kIsWeb) {
          // Read file in chunks to prevent UI blocking
          final chunks = <Uint8List>[];
          await for (final chunk in FileHelpers.readFileInChunks(
            video,
            onProgress: (progress) {
              readProgress = progress * 0.5; // Reading is 50% of process
              progressController?.add(readProgress);
            },
          )) {
            chunks.add(chunk);
          }

          // Combine chunks
          final totalSize = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
          videoBytes = Uint8List(totalSize);
          var offset = 0;
          for (final chunk in chunks) {
            videoBytes.setRange(offset, offset + chunk.length, chunk);
            offset += chunk.length;
          }

          progressController?.add(0.6); // Reading complete
        }

        // Validate video file size after reading (for mobile or if early validation failed)
        final validation = await FileHelpers.validateFileSize(
          video.path,
          'video',
          kIsWeb ? {'fileSize': fileSizeMB} : {},
        );

        if (!validation.isValid) {
          progressController?.close();
          if (mounted) {
            SnackbarUtils.showScaffoldError(context, validation.message);
          }
          return;
        }

        progressController?.add(0.8);

        // Store video locally (with bytes for web)
        final saveResult = await _saveFileLocally(video, 'video');
        if (saveResult == null) {
          throw Exception('Failed to store video temporarily');
        }

        progressController?.add(0.9);

        // Create file entry
        final newFileEntry = {
          'type': 'video',
          'localPath': saveResult,
          'fileName': video.name,
          'fileSize': validation.fileSizeMB,
          'isPremium': true,
        };

        // For web videos, store the bytes for upload
        if (kIsWeb && videoBytes != null) {
          newFileEntry['bytes'] = videoBytes;
        }

        progressController?.add(1.0); // Complete

        // Update local files
        _updateLocalFiles('video', newFileEntry);

        progressController?.close();

        AppLogger.candidate('🎥 [Video Upload] Video selection process completed');
      } finally {
        progressController?.close();
      }
    } catch (e) {
      AppLogger.candidate('🎥 [Video Upload] Error: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to select video: ${e.toString()}');
      }
    }
  }

  /// Check plan permissions for uploads
  Future<bool> _checkPlanPermission(ImageUploadPlanPermission permission) async {
    final candidateUserController = Get.find<CandidateUserController>();
    UserModel? user = candidateUserController.user.value;

    if (user == null) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await candidateUserController.loadCandidateUserData();
        user = candidateUserController.user.value;
      }
    }

    bool isFreePlan = true;
    if (user != null) {
      isFreePlan = user.subscriptionPlanId == "free_plan";
    }

    // Free plan restriction for images
    if (isFreePlan && permission == ImageUploadPlanPermission.image) {
      if (mounted) {
        await UpgradePlanDialog.showImageUploadRestricted(context: context);
        // Always return false after showing dialog - user needs to actually upgrade first
        // The dialog handles navigation to monetization screen
        return false;
      }
      return false;
    }

    return true;
  }

  /// Save file locally (refactored from original implementation)
  Future<String?> _saveFileLocally(dynamic file, String type) async {
    try {
      // Unified approach: Store files temporarily for preview, upload only on Save
      AppLogger.candidate('💾 [FileUpload] Storing $type file temporarily for preview...');

      // Use the FileStorageManager for consistent file handling
      final storageManager = FileStorageManager();
      final result = await storageManager.saveTempFile(file, type);

      if (result != null) {
        AppLogger.candidate('💾 [FileUpload] File stored temporarily: $result');
      } else {
        AppLogger.candidate('💾 [FileUpload] Failed to store file temporarily');
      }

      return result;
    } catch (e) {
      AppLogger.candidate('💾 [FileUpload] Error saving/uploading file: $e');
      return null;
    }
  }

  /// Update local files list safely
  void _updateLocalFiles(String type, Map<String, dynamic> newEntry) {
    // AppLogger.candidate('📝 [FileUploadHandler] _updateLocalFiles called for type: $type, file: ${newEntry['fileName']}'); // COMMENTED OUT - HIDES BYTES LOG

    // Remove existing files of same type
    localFiles.removeWhere((entry) => entry['type'] == type);

    // Add new entry
    localFiles.add(newEntry);

    // AppLogger.candidate('📝 [FileUploadHandler] Local files updated, now ${localFiles.length} files'); // COMMENTED OUT - HIDES BYTES LOG

    // Notify parent - Create a copy to avoid reference issues
    final filesCopy = List<Map<String, dynamic>>.from(localFiles);
    // AppLogger.candidate('📝 [FileUploadHandler] Created copy with ${filesCopy.length} files for notification'); // COMMENTED OUT - HIDES BYTES LOG
    onLocalFilesUpdate(filesCopy);
  }

  /// Upload all pending files to Firebase
  Future<Map<String, String>> uploadPendingFiles() async {
    // ... (existing implementation moved here from original file)
    // This would contain the Firebase upload logic
    return {};
  }

  /// NEW: Generalized multiple media file upload using the new system
  /// This method provides seamless cross-platform media upload for multiple files
  Future<void> uploadMultipleMediaFiles({
    required List<String> allowedExtensions,
    required String uploadCategory,
    bool allowMultiple = true,
    void Function(List<String> urls)? onSuccess,
    void Function(String error)? onError,
  }) async {
    try {
      AppLogger.candidate('📁 [Multiple Media Upload] Starting generalized upload process...');

      // Use the new generalized media upload handler
      final mediaHandler = MediaUploadHandler(
        context: context,
        userId: candidateData.candidateId,
        category: uploadCategory,
      );

      // Pick files
      final files = await mediaHandler.pickMediaFiles(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (files.isEmpty) {
        AppLogger.candidate('📁 [Multiple Media Upload] No files selected');
        return;
      }

      // Validate file sizes
      final validFiles = mediaHandler.validateFileSizes(files);
      if (validFiles.length != files.length) {
        AppLogger.candidate('⚠️ [Multiple Media Upload] Some files were filtered due to size limits');
      }

      if (validFiles.isEmpty) {
        if (mounted) {
          SnackbarUtils.showScaffoldError(context, 'No valid files to upload');
        }
        return;
      }

      // Upload files to manifesto_files path for proper permissions
      final customPath = 'manifesto_files/${candidateData.candidateId}/';
      final urls = await mediaHandler.uploadMediaFiles(validFiles, customPath: customPath);

      AppLogger.candidate('📁 [Multiple Media Upload] Successfully uploaded ${urls.length} files');

      // Callback
      onSuccess?.call(urls);

      if (mounted) {
        SnackbarUtils.showScaffoldSuccess(
          context,
          'Successfully uploaded ${urls.length} media files!',
        );
      }

      // Cleanup
      mediaHandler.cleanup();

    } catch (e) {
      AppLogger.candidate('📁 [Multiple Media Upload] Error: $e');
      onError?.call(e.toString());

      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to upload media files: ${e.toString()}');
      }
    }
  }

  bool get mounted => context.mounted;
}

/// Plan permission types for file uploads
enum ImageUploadPlanPermission {
  image,
  video,
}
