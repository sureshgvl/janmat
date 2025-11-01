import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_logger.dart';
import '../candidate/models/candidate_model.dart';
import '../monetization/services/plan_service.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/features/candidate/candidate_localizations.dart';

class FileUploadSection extends StatefulWidget {
  final Candidate candidateData;
  final bool isEditing;
  final Function(String) onManifestoPdfChange;
  final Function(String) onManifestoImageChange;
  final Function(String) onManifestoVideoChange;
  final Function(List<Map<String, dynamic>>) onLocalFilesUpdate;

  const FileUploadSection({
    super.key,
    required this.candidateData,
    required this.isEditing,
    required this.onManifestoPdfChange,
    required this.onManifestoImageChange,
    required this.onManifestoVideoChange,
    required this.onLocalFilesUpdate,
  });

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  bool _isUploadingPdf = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  final List<Map<String, dynamic>> _localFiles = [];

  Future<void> _uploadManifestoPdf() async {
    AppLogger.candidate('📄 [PDF Upload] Starting PDF selection process...');

    setState(() {
      _isUploadingPdf = true;
    });

    try {
      // Step 1: Pick file from device
      AppLogger.candidate('📄 [PDF Upload] Step 1: Picking file from device...');
      file_picker.FilePickerResult? result = await file_picker
          .FilePicker
          .platform
          .pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );

      if (result == null || result.files.isEmpty) {
        AppLogger.candidate('📄 [PDF Upload] User cancelled file selection');
        setState(() {
          _isUploadingPdf = false;
        });
        return;
      }

      final file = result.files.first;
      final fileSize = file.size;
      final fileSizeMB = fileSize / (1024 * 1024);

      AppLogger.candidate(
        '📄 [PDF Upload] File selected: ${file.name}, Size: ${fileSizeMB.toStringAsFixed(2)} MB',
      );

      // Step 2: Validate file size locally
      AppLogger.candidate('📄 [PDF Upload] Step 2: Validating file size...');
      if (fileSizeMB > 20.0) {
        AppLogger.candidate(
          '📄 [PDF Upload] File too large: ${fileSizeMB.toStringAsFixed(1)}MB > 20MB limit',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isUploadingPdf = false;
        });
        return;
      }

      AppLogger.candidate('📄 [PDF Upload] File size validation passed');

      // Step 3: Save to local storage and show to user
      AppLogger.candidate('📄 [PDF Upload] Step 3: Saving to local storage...');
      final localPath = await _saveFileLocally(file, 'pdf');
      if (localPath == null) {
        AppLogger.candidate('📄 [PDF Upload] Failed to save locally');
        throw Exception('Failed to save file locally');
      }
      AppLogger.candidate('📄 [PDF Upload] Saved locally at: $localPath');

      // Check if we already have a PDF in local files (shouldn't happen due to UI logic, but safety check)
      final existingPdfIndex = _localFiles.indexWhere((f) => f['type'] == 'pdf');
      if (existingPdfIndex != -1) {
        // Remove existing PDF before adding new one
        final existingPath = _localFiles[existingPdfIndex]['localPath'] as String;
        await _cleanupLocalFile(existingPath);
        _localFiles.removeAt(existingPdfIndex);
      }

      // Add to local files list for visual display (prevent duplicates)
      setState(() {
        final existingIndex = _localFiles.indexWhere((f) => f['type'] == 'pdf');
        if (existingIndex != -1) {
          // Replace existing PDF file
          _localFiles[existingIndex] = {
            'type': 'pdf',
            'localPath': localPath,
            'fileName': file.name,
            'fileSize': fileSizeMB,
          };
        } else {
          // Add new PDF file
          _localFiles.add({
            'type': 'pdf',
            'localPath': localPath,
            'fileName': file.name,
            'fileSize': fileSizeMB,
          });
        }
      });

      widget.onLocalFilesUpdate(_localFiles);

      AppLogger.candidate('📄 [PDF Upload] PDF saved locally and added to display list');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF selected and ready for upload. Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      AppLogger.candidate('📄 [PDF Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPdf = false;
      });
      AppLogger.candidate('📄 [PDF Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoImage() async {
    AppLogger.candidate('🖼️ [Image Upload] Starting image selection process...');

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Step 1: Pick image from gallery
      AppLogger.candidate('🖼️ [Image Upload] Step 1: Picking image from gallery...');
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        AppLogger.candidate('🖼️ [Image Upload] User cancelled image selection');
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      AppLogger.candidate(
        '🖼️ [Image Upload] Image selected: ${image.name}, Path: ${image.path}',
      );

      // Step 2: Optimize image for manifesto (higher quality than achievements)
      AppLogger.candidate(
        '🖼️ [Image Upload] Step 2: Optimizing image for manifesto...',
      );
      final optimizedImage = await _optimizeManifestoImage(image);
      AppLogger.candidate('🖼️ [Image Upload] Image optimization completed');

      // Step 3: Validate file size with optimized image
      AppLogger.candidate(
        '🖼️ [Image Upload] Step 3: Validating optimized file size...',
      );
      final validation = await _validateManifestoFileSize(
        optimizedImage.path,
        'image',
      );

      if (!validation.isValid) {
        AppLogger.candidate('🖼️ [Image Upload] File too large after optimization');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Show warning for large files
      if (validation.warning) {
        final proceed = await _showFileSizeWarningDialog(validation);
        if (proceed != true) {
          AppLogger.candidate('🖼️ [Image Upload] User cancelled after size warning');
          setState(() {
            _isUploadingImage = false;
          });
          return;
        }
      }

      AppLogger.candidate('🖼️ [Image Upload] File size validation passed');

      // Step 4: Save optimized image to local storage
      AppLogger.candidate(
        '🖼️ [Image Upload] Step 4: Saving optimized image to local storage...',
      );
      final localPath = await _saveFileLocally(optimizedImage, 'image');
      if (localPath == null) {
        AppLogger.candidate('🖼️ [Image Upload] Failed to save locally');
        throw Exception('Failed to save optimized image locally');
      }
      AppLogger.candidate('🖼️ [Image Upload] Saved locally at: $localPath');

      // Check if we already have an image in local files (shouldn't happen due to UI logic, but safety check)
      final existingImageIndex = _localFiles.indexWhere((f) => f['type'] == 'image');
      if (existingImageIndex != -1) {
        // Remove existing image before adding new one
        final existingPath = _localFiles[existingImageIndex]['localPath'] as String;
        await _cleanupLocalFile(existingPath);
        _localFiles.removeAt(existingImageIndex);
      }

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'image',
          'localPath': localPath,
          'fileName': optimizedImage.name,
          'fileSize': validation.fileSizeMB,
        });
      });

      widget.onLocalFilesUpdate(_localFiles);

      AppLogger.candidate(
        '🖼️ [Image Upload] Optimized image saved locally and added to display list',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image optimized and ready for upload (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      AppLogger.candidate('🖼️ [Image Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
      AppLogger.candidate('🖼️ [Image Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoVideo() async {
    AppLogger.candidate('🎥 [Video Upload] Starting video selection process...');

    // Check if user can upload videos based on their plan
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final plan = await PlanService.getUserPlan(currentUser.uid);
      if (plan != null && plan.dashboardTabs?.manifesto.enabled == true) {
        final canUploadVideo = plan.dashboardTabs!.manifesto.features.videoUpload;

        if (!canUploadVideo) {
          // Show upgrade message using snackbar
          final candidateLocalizations = CandidateLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(candidateLocalizations?.translate('videoUploadNotAvailableMessage') ?? 'Video upload is not available with your current plan. Upgrade to Gold or Platinum plan to add videos to your manifesto.'),
              action: SnackBarAction(
                label: candidateLocalizations?.translate('upgradeToGold') ?? 'Upgrade to Gold',
                onPressed: () {
                  // TODO: Navigate to monetization screen
                  // Get.to(() => const MonetizationScreen());
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      // Step 1: Pick video from gallery
      AppLogger.candidate('🎥 [Video Upload] Step 1: Picking video from gallery...');
      final ImagePicker imagePicker = ImagePicker();
      final XFile? video = await imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          minutes: 5,
        ), // Limit to 5 minutes for manifesto videos
      );

      if (video == null) {
        AppLogger.candidate('🎥 [Video Upload] User cancelled video selection');
        setState(() {
          _isUploadingVideo = false;
        });
        return;
      }

      AppLogger.candidate(
        '🎥 [Video Upload] Video selected: ${video.name}, Path: ${video.path}',
      );

      // Step 2: Validate video file size
      AppLogger.candidate('🎥 [Video Upload] Step 2: Validating video file size...');
      final validation = await _validateManifestoFileSize(video.path, 'video');

      if (!validation.isValid) {
        AppLogger.candidate('🎥 [Video Upload] File too large');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isUploadingVideo = false;
        });
        return;
      }

      // Show warning for large files
      if (validation.warning) {
        final proceed = await _showFileSizeWarningDialog(validation);
        if (proceed != true) {
          AppLogger.candidate('🎥 [Video Upload] User cancelled after size warning');
          setState(() {
            _isUploadingVideo = false;
          });
          return;
        }
      }

      AppLogger.candidate('🎥 [Video Upload] File size validation passed');

      // Step 3: Save video to local storage
      AppLogger.candidate('🎥 [Video Upload] Step 3: Saving video to local storage...');
      final localPath = await _saveFileLocally(video, 'video');
      if (localPath == null) {
        AppLogger.candidate('🎥 [Video Upload] Failed to save locally');
        throw Exception('Failed to save video locally');
      }
      AppLogger.candidate('🎥 [Video Upload] Saved locally at: $localPath');

      // Check if we already have a video in local files (shouldn't happen due to UI logic, but safety check)
      final existingVideoIndex = _localFiles.indexWhere((f) => f['type'] == 'video');
      if (existingVideoIndex != -1) {
        // Remove existing video before adding new one
        final existingPath = _localFiles[existingVideoIndex]['localPath'] as String;
        await _cleanupLocalFile(existingPath);
        _localFiles.removeAt(existingVideoIndex);
      }

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'video',
          'localPath': localPath,
          'fileName': video.name,
          'fileSize': validation.fileSizeMB,
          'isPremium': true, // Always premium for videos
        });
      });

      widget.onLocalFilesUpdate(_localFiles);

      AppLogger.candidate(
        '🎥 [Video Upload] Video saved locally and added to display list',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video selected and ready for upload (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      AppLogger.candidate('🎥 [Video Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingVideo = false;
      });
      AppLogger.candidate('🎥 [Video Upload] Selection process completed');
    }
  }

  // Local storage helper methods
  Future<String?> _saveFileLocally(dynamic file, String type) async {
    try {
      AppLogger.candidate('💾 [Local Storage] Saving $type file locally...');

      // Clean up old temp files first (keep only files from last 30 minutes)
      await _cleanupOldTempFiles();

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/manifesto_temp');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
        AppLogger.candidate(
          '💾 [Local Storage] Created temp directory: ${localDir.path}',
        );
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = widget.candidateData.userId ?? 'unknown_user';
      final fileName =
          'temp_${type}_${userId}_$timestamp.${type == 'pdf' ? 'pdf' : 'tmp'}';
      final localPath = '${localDir.path}/$fileName';

      // Save file locally
      if (file is file_picker.PlatformFile) {
        if (file.bytes != null) {
          // Web platform
          final localFile = File(localPath);
          await localFile.writeAsBytes(file.bytes!);
          AppLogger.candidate('💾 [Local Storage] Saved web file to: $localPath');
        } else if (file.path != null) {
          // Mobile platform
          await File(file.path!).copy(localPath);
          AppLogger.candidate('💾 [Local Storage] Copied mobile file to: $localPath');
        }
      } else if (file is XFile) {
        // Image picker file
        await File(file.path).copy(localPath);
        AppLogger.candidate('💾 [Local Storage] Copied image file to: $localPath');
      }

      AppLogger.candidate('💾 [Local Storage] File saved successfully at: $localPath');
      return localPath;
    } catch (e) {
      AppLogger.candidate('💾 [Local Storage] Error saving file locally: $e');
      return null;
    }
  }

  // Clean up old temporary files (older than 30 minutes)
  Future<void> _cleanupOldTempFiles() async {
    try {
      AppLogger.candidate('🧹 [Cache Cleanup] Starting cache cleanup...');

      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/manifesto_temp');

      if (!await localDir.exists()) {
        AppLogger.candidate('🧹 [Cache Cleanup] Temp directory does not exist, nothing to clean');
        return;
      }

      final files = await localDir.list().toList();
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));
      int cleanedCount = 0;
      int totalSize = 0;

      for (final entity in files) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffTime)) {
              final size = stat.size;
              await entity.delete();
              cleanedCount++;
              totalSize += size;
              AppLogger.candidate('🧹 [Cache Cleanup] Deleted old file: ${entity.path} (${(size / (1024 * 1024)).toStringAsFixed(2)} MB)');
            }
          } catch (e) {
            AppLogger.candidate('⚠️ [Cache Cleanup] Failed to delete ${entity.path}: $e');
          }
        }
      }

      if (cleanedCount > 0) {
        AppLogger.candidate('🧹 [Cache Cleanup] Cleaned up $cleanedCount old files, freed ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB');
      } else {
        AppLogger.candidate('🧹 [Cache Cleanup] No old files to clean');
      }
    } catch (e) {
      AppLogger.candidate('⚠️ [Cache Cleanup] Error during cache cleanup: $e');
    }
  }

  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      AppLogger.candidate('🧹 [Local Storage] Cleaning up local file: $localPath');
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.candidate('🧹 [Local Storage] Local file deleted successfully');
      } else {
        AppLogger.candidate('🧹 [Local Storage] Local file not found, nothing to clean');
      }
    } catch (e) {
      AppLogger.candidate('🧹 [Local Storage] Error cleaning up local file: $e');
    }
  }

  // File size validation for manifesto files
  Future<FileSizeValidation> _validateManifestoFileSize(
    String filePath,
    String type,
  ) async {
    try {
      final file = File(filePath.replaceFirst('local:', ''));
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      switch (type) {
        case 'pdf':
          if (fileSizeMB > 20.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message:
                  'PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
              recommendation:
                  'Please choose a smaller PDF or compress the current one.',
            );
          } else if (fileSizeMB > 10.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message:
                  'Large PDF detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation:
                  'Consider compressing the PDF for faster uploads.',
              warning: true,
            );
          }
          break;

        case 'image':
          if (fileSizeMB > 10.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message:
                  'Image file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 10MB.',
              recommendation:
                  'Please choose a smaller image or compress the current one.',
            );
          } else if (fileSizeMB > 5.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message:
                  'Large image detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation:
                  'Consider compressing the image for faster uploads.',
              warning: true,
            );
          }
          break;

        case 'video':
          if (fileSizeMB > 100.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message:
                  'Video file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 100MB.',
              recommendation:
                  'Please choose a smaller video or compress the current one.',
            );
          } else if (fileSizeMB > 50.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message:
                  'Large video detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation:
                  'Consider compressing the video for faster uploads.',
              warning: true,
            );
          }
          break;
      }

      return FileSizeValidation(
        isValid: true,
        fileSizeMB: fileSizeMB,
        message:
            'File size is acceptable (${fileSizeMB.toStringAsFixed(1)}MB).',
        recommendation: null,
      );
    } catch (e) {
      return FileSizeValidation(
        isValid: false,
        fileSizeMB: 0,
        message: 'Unable to validate file size: $e',
        recommendation: 'Please try again or choose a different file.',
      );
    }
  }

  // Show file size warning dialog
  Future<bool?> _showFileSizeWarningDialog(
    FileSizeValidation validation,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Size Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.message),
            if (validation.recommendation != null) ...[
              const SizedBox(height: 8),
              Text(
                validation.recommendation!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'File size: ${validation.fileSizeMB.toStringAsFixed(1)}MB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose Different File'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  // Optimize image for manifesto (higher quality than achievements)
  Future<XFile> _optimizeManifestoImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      AppLogger.candidate(
        '🖼️ [Manifesto Image] Original size: ${fileSizeMB.toStringAsFixed(2)} MB',
      );

      // Manifesto images need higher quality than achievement photos
      int quality = 85; // Higher than achievements (80)
      int? maxWidth;
      int? maxHeight;

      if (fileSizeMB > 8.0) {
        // Very large files (>8MB) - moderate optimization for manifesto
        quality = 75;
        maxWidth = 1600;
        maxHeight = 1600;
        AppLogger.candidate(
          '🖼️ [Manifesto Image] Large file detected (>8MB), applying moderate optimization',
        );
      } else if (fileSizeMB > 4.0) {
        // Large files (4-8MB) - light optimization
        quality = 80;
        maxWidth = 2000;
        maxHeight = 2000;
        AppLogger.candidate(
          '🖼️ [Manifesto Image] Large file detected (4-8MB), applying light optimization',
        );
      } else {
        // Small files - no optimization needed
        AppLogger.candidate(
          '🖼️ [Manifesto Image] File size acceptable, no optimization needed',
        );
        return image;
      }

      // Get the original image temp path for cleanup
      final originalTempPath = image.path;
      AppLogger.candidate('🖼️ [Manifesto Image] Original temp path: $originalTempPath');

      // Create optimized version
      final ImagePicker imagePicker = ImagePicker();
      final optimizedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (optimizedImage != null) {
        final optimizedFile = File(optimizedImage.path);
        final optimizedSize = await optimizedFile.length();
        final optimizedSizeMB = optimizedSize / (1024 * 1024);

        AppLogger.candidate(
          '🖼️ [Manifesto Image] Optimized size: ${optimizedSizeMB.toStringAsFixed(2)} MB (${((fileSize - optimizedSize) / fileSize * 100).toStringAsFixed(1)}% reduction)',
        );

        // If optimization created a different file, clean up the original temp file
        if (optimizedImage.path != originalTempPath) {
          AppLogger.candidate('🖼️ [Manifesto Image] Cleaning up original temp file');
          try {
            await _cleanupLocalFile(originalTempPath);
          } catch (cleanupError) {
            AppLogger.candidate('⚠️ [Manifesto Image] Failed to cleanup original temp file: $cleanupError');
          }
        }

        return optimizedImage;
      }

      // If optimization failed, return original
      AppLogger.candidate('⚠️ [Manifesto Image] Optimization returned null, using original');
      return image;
    } catch (e) {
      AppLogger.candidate(
        '⚠️ [Manifesto Image] Optimization failed, using original: $e',
      );
      return image;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return const SizedBox.shrink();

    // Check if files already exist in database OR are pending local upload
    final hasPdfInDb = widget.candidateData.manifestoData?.pdfUrl != null &&
                       widget.candidateData.manifestoData!.pdfUrl!.isNotEmpty;
    final hasImageInDb = widget.candidateData.manifestoData?.image != null &&
                         widget.candidateData.manifestoData!.image!.isNotEmpty;
    final hasVideoInDb = widget.candidateData.manifestoData?.videoUrl != null &&
                         widget.candidateData.manifestoData!.videoUrl!.isNotEmpty;

    // Check if files are pending local upload (only allow one per type)
    final hasPdfLocal = _localFiles.where((file) => file['type'] == 'pdf').isNotEmpty;
    final hasImageLocal = _localFiles.where((file) => file['type'] == 'image').isNotEmpty;
    final hasVideoLocal = _localFiles.where((file) => file['type'] == 'video').isNotEmpty;

    // Combine database and local checks
    final hasPdf = hasPdfInDb || hasPdfLocal;
    final hasImage = hasImageInDb || hasImageLocal;
    final hasVideo = hasVideoInDb || hasVideoLocal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // PDF Upload Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasPdf ? Colors.grey.shade100 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasPdf ? Colors.grey.shade300 : Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: hasPdf ? Colors.grey.shade500 : Colors.red.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPdf ? 'PDF Already Added' : AppLocalizations.of(context)!.uploadPdf,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasPdf ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        Text(
                          hasPdf ? 'One PDF allowed per manifesto' : AppLocalizations.of(context)!.pdfFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasPdf ? Colors.grey.shade500 : Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (!hasPdf && !_isUploadingPdf) ? _uploadManifestoPdf : null,
                    icon: _isUploadingPdf
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(hasPdf ? 'PDF Added' : 'Choose PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasPdf ? Colors.grey.shade400 : Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Image Upload Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasImage ? Colors.grey.shade100 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasImage ? Colors.grey.shade300 : Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image,
                    color: hasImage ? Colors.grey.shade500 : Colors.green.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasImage ? 'Image Already Added' : AppLocalizations.of(context)!.uploadImage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasImage ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        Text(
                          hasImage ? 'One image allowed per manifesto' : AppLocalizations.of(context)!.imageFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasImage ? Colors.grey.shade500 : Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (!hasImage && !_isUploadingImage)
                        ? _uploadManifestoImage
                        : null,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.photo_camera),
                    label: Text(hasImage ? 'Image Added' : 'Choose Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasImage ? Colors.grey.shade400 : Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Video Upload Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasVideo ? Colors.grey.shade100 : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasVideo ? Colors.grey.shade300 : Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_call,
                    color: hasVideo ? Colors.grey.shade500 : Colors.purple.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasVideo ? 'Video Already Added' : AppLocalizations.of(context)!.uploadVideo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: hasVideo ? Colors.grey.shade600 : Colors.black87,
                          ),
                        ),
                        Text(
                          hasVideo ? 'One video allowed per manifesto' : AppLocalizations.of(context)!.videoFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasVideo ? Colors.grey.shade500 : Colors.purple.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (!hasVideo && !_isUploadingVideo)
                        ? _uploadManifestoVideo
                        : null,
                    icon: _isUploadingVideo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.videocam),
                    label: Text(hasVideo ? 'Video Added' : 'Choose Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasVideo ? Colors.grey.shade400 : Colors.purple.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Display locally stored files (ready for upload)
        if (_localFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pending, color: Colors.amber.shade700, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.filesReadyForUpload(_localFiles.length),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.filesUploadMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ..._localFiles.map((localFile) {
                  final type = localFile['type'] as String;
                  final fileName = localFile['fileName'] as String;
                  final fileSize = localFile['fileSize'] as double;
                  final localPath = localFile['localPath'] as String;

                  IconData icon;
                  Color color;
                  switch (type) {
                    case 'pdf':
                      icon = Icons.picture_as_pdf;
                      color = Colors.red;
                      break;
                    case 'image':
                      icon = Icons.image;
                      color = Colors.green;
                      break;
                    case 'video':
                      icon = Icons.video_call;
                      color = Colors.purple;
                      break;
                    default:
                      icon = Icons.file_present;
                      color = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${fileSize.toStringAsFixed(2)} MB • Ready for upload',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _localFiles.remove(localFile);
                              });
                              widget.onLocalFilesUpdate(_localFiles);
                              // Clean up the local file
                              _cleanupLocalFile(localPath);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$fileName removed from upload queue',
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            tooltip: 'Remove from upload queue',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// File size validation result class
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
