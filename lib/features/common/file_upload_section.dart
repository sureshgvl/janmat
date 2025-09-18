import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../candidate/models/candidate_model.dart';
import '../../services/file_upload_service.dart';
import '../../l10n/app_localizations.dart';

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
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploadingPdf = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  final List<Map<String, dynamic>> _localFiles = [];

  Future<void> _uploadManifestoPdf() async {
    debugPrint('📄 [PDF Upload] Starting PDF selection process...');

    setState(() {
      _isUploadingPdf = true;
    });

    try {
      // Step 1: Pick file from device
      debugPrint('📄 [PDF Upload] Step 1: Picking file from device...');
      file_picker.FilePickerResult? result = await file_picker
          .FilePicker
          .platform
          .pickFiles(
            type: file_picker.FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );

      if (result == null || result.files.isEmpty) {
        debugPrint('📄 [PDF Upload] User cancelled file selection');
        setState(() {
          _isUploadingPdf = false;
        });
        return;
      }

      final file = result.files.first;
      final fileSize = file.size;
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint(
        '📄 [PDF Upload] File selected: ${file.name}, Size: ${fileSizeMB.toStringAsFixed(2)} MB',
      );

      // Step 2: Validate file size locally
      debugPrint('📄 [PDF Upload] Step 2: Validating file size...');
      if (fileSizeMB > 20.0) {
        debugPrint(
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

      debugPrint('📄 [PDF Upload] File size validation passed');

      // Step 3: Save to local storage and show to user
      debugPrint('📄 [PDF Upload] Step 3: Saving to local storage...');
      final localPath = await _saveFileLocally(file, 'pdf');
      if (localPath == null) {
        debugPrint('📄 [PDF Upload] Failed to save locally');
        throw Exception('Failed to save file locally');
      }
      debugPrint('📄 [PDF Upload] Saved locally at: $localPath');

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'pdf',
          'localPath': localPath,
          'fileName': file.name,
          'fileSize': fileSizeMB,
        });
      });

      widget.onLocalFilesUpdate(_localFiles);

      debugPrint('📄 [PDF Upload] PDF saved locally and added to display list');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF selected and ready for upload. Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('📄 [PDF Upload] Error: $e');
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
      debugPrint('📄 [PDF Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoImage() async {
    debugPrint('🖼️ [Image Upload] Starting image selection process...');

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Step 1: Pick image from gallery
      debugPrint('🖼️ [Image Upload] Step 1: Picking image from gallery...');
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('🖼️ [Image Upload] User cancelled image selection');
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      debugPrint(
        '🖼️ [Image Upload] Image selected: ${image.name}, Path: ${image.path}',
      );

      // Step 2: Optimize image for manifesto (higher quality than achievements)
      debugPrint(
        '🖼️ [Image Upload] Step 2: Optimizing image for manifesto...',
      );
      final optimizedImage = await _optimizeManifestoImage(image);
      debugPrint('🖼️ [Image Upload] Image optimization completed');

      // Step 3: Validate file size with optimized image
      debugPrint(
        '🖼️ [Image Upload] Step 3: Validating optimized file size...',
      );
      final validation = await _validateManifestoFileSize(
        optimizedImage.path,
        'image',
      );

      if (!validation.isValid) {
        debugPrint('🖼️ [Image Upload] File too large after optimization');
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
          debugPrint('🖼️ [Image Upload] User cancelled after size warning');
          setState(() {
            _isUploadingImage = false;
          });
          return;
        }
      }

      debugPrint('🖼️ [Image Upload] File size validation passed');

      // Step 4: Save optimized image to local storage
      debugPrint(
        '🖼️ [Image Upload] Step 4: Saving optimized image to local storage...',
      );
      final localPath = await _saveFileLocally(optimizedImage, 'image');
      if (localPath == null) {
        debugPrint('🖼️ [Image Upload] Failed to save locally');
        throw Exception('Failed to save optimized image locally');
      }
      debugPrint('🖼️ [Image Upload] Saved locally at: $localPath');

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

      debugPrint(
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
      debugPrint('🖼️ [Image Upload] Error: $e');
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
      debugPrint('🖼️ [Image Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoVideo() async {
    debugPrint('🎥 [Video Upload] Starting video selection process...');

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      // Step 1: Pick video from gallery
      debugPrint('🎥 [Video Upload] Step 1: Picking video from gallery...');
      final ImagePicker imagePicker = ImagePicker();
      final XFile? video = await imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          minutes: 5,
        ), // Limit to 5 minutes for manifesto videos
      );

      if (video == null) {
        debugPrint('🎥 [Video Upload] User cancelled video selection');
        setState(() {
          _isUploadingVideo = false;
        });
        return;
      }

      debugPrint(
        '🎥 [Video Upload] Video selected: ${video.name}, Path: ${video.path}',
      );

      // Step 2: Validate video file size
      debugPrint('🎥 [Video Upload] Step 2: Validating video file size...');
      final validation = await _validateManifestoFileSize(video.path, 'video');

      if (!validation.isValid) {
        debugPrint('🎥 [Video Upload] File too large');
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
          debugPrint('🎥 [Video Upload] User cancelled after size warning');
          setState(() {
            _isUploadingVideo = false;
          });
          return;
        }
      }

      debugPrint('🎥 [Video Upload] File size validation passed');

      // Step 3: Save video to local storage
      debugPrint('🎥 [Video Upload] Step 3: Saving video to local storage...');
      final localPath = await _saveFileLocally(video, 'video');
      if (localPath == null) {
        debugPrint('🎥 [Video Upload] Failed to save locally');
        throw Exception('Failed to save video locally');
      }
      debugPrint('🎥 [Video Upload] Saved locally at: $localPath');

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

      debugPrint(
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
      debugPrint('🎥 [Video Upload] Error: $e');
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
      debugPrint('🎥 [Video Upload] Selection process completed');
    }
  }

  // Local storage helper methods
  Future<String?> _saveFileLocally(dynamic file, String type) async {
    try {
      debugPrint('💾 [Local Storage] Saving $type file locally...');

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/manifesto_temp');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
        debugPrint(
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
          debugPrint('💾 [Local Storage] Saved web file to: $localPath');
        } else if (file.path != null) {
          // Mobile platform
          await File(file.path!).copy(localPath);
          debugPrint('💾 [Local Storage] Copied mobile file to: $localPath');
        }
      } else if (file is XFile) {
        // Image picker file
        await File(file.path).copy(localPath);
        debugPrint('💾 [Local Storage] Copied image file to: $localPath');
      }

      debugPrint('💾 [Local Storage] File saved successfully at: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('💾 [Local Storage] Error saving file locally: $e');
      return null;
    }
  }

  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      debugPrint('🧹 [Local Storage] Cleaning up local file: $localPath');
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🧹 [Local Storage] Local file deleted successfully');
      } else {
        debugPrint('🧹 [Local Storage] Local file not found, nothing to clean');
      }
    } catch (e) {
      debugPrint('🧹 [Local Storage] Error cleaning up local file: $e');
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

      debugPrint(
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
        debugPrint(
          '🖼️ [Manifesto Image] Large file detected (>8MB), applying moderate optimization',
        );
      } else if (fileSizeMB > 4.0) {
        // Large files (4-8MB) - light optimization
        quality = 80;
        maxWidth = 2000;
        maxHeight = 2000;
        debugPrint(
          '🖼️ [Manifesto Image] Large file detected (4-8MB), applying light optimization',
        );
      } else {
        // Small files - no optimization needed
        debugPrint(
          '🖼️ [Manifesto Image] File size acceptable, no optimization needed',
        );
        return image;
      }

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

        debugPrint(
          '🖼️ [Manifesto Image] Optimized size: ${optimizedSizeMB.toStringAsFixed(2)} MB (${((fileSize - optimizedSize) / fileSize * 100).toStringAsFixed(1)}% reduction)',
        );
        return optimizedImage;
      }

      // If optimization failed, return original
      return image;
    } catch (e) {
      debugPrint(
        '⚠️ [Manifesto Image] Optimization failed, using original: $e',
      );
      return image;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.uploadFiles,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // PDF Upload Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.uploadPdf,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.pdfFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_isUploadingPdf ? _uploadManifestoPdf : null,
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
                    label: const Text('Choose PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.image, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.uploadImage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.imageFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_isUploadingImage
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
                    label: const Text('Choose Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
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
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.video_call,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.uploadVideo,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.videoFileLimit,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_isUploadingVideo
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
                    label: const Text('Choose Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
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
