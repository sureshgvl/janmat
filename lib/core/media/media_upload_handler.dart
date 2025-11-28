import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../utils/app_logger.dart';
import '../../utils/snackbar_utils.dart';
import 'media_file.dart';
import 'media_picker.dart';
import 'media_uploader.dart';
import 'media_uploader_advanced.dart';

/// Progress dialog for media uploads
class MediaUploadProgressDialog extends StatefulWidget {
  final List<MediaFile> files;
  final String userId;
  final String category;
  final String? customPath;

  // Prevent multiple dialog instances
  static bool _dialogShowing = false;

  const MediaUploadProgressDialog({
    super.key,
    required this.files,
    required this.userId,
    required this.category,
    this.customPath,
  });

  @override
  State<MediaUploadProgressDialog> createState() => _MediaUploadProgressDialogState();
}

class _MediaUploadProgressDialogState extends State<MediaUploadProgressDialog> {
  final Map<String, UploadProgress> _progressMap = {};
  final Map<String, String> _completedUrls = {};
  final Map<String, String> _errors = {};
  bool _isUploading = true;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    final uploader = MediaUploaderAdvanced();

    try {
      await uploader.uploadFiles(
        widget.files,
        userId: widget.userId,
        category: widget.category,
        customPath: widget.customPath,
        onProgress: (fileId, progress) {
          if (mounted) {
            setState(() {
              _progressMap[fileId] = progress;
            });
          }
        },
        onComplete: (fileId, url) {
          if (mounted) {
            setState(() {
              _completedUrls[fileId] = url;
            });
            // Check if all uploads are complete
            if (_completedUrls.length + _errors.length >= widget.files.length) {
              _finishUpload();
            }
          }
        },
        onError: (fileId, error) {
          if (mounted) {
            setState(() {
              _errors[fileId] = error;
            });
            // Check if all uploads are complete
            if (_completedUrls.length + _errors.length >= widget.files.length) {
              _finishUpload();
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        SnackbarUtils.showScaffoldError(context, 'Upload failed: ${e.toString()}');
        Navigator.of(context).pop([]);
      }
    }
  }

  void _finishUpload() {
    setState(() {
      _isUploading = false;
    });

    // Return URLs in the same order as input files
    final orderedUrls = <String>[];
    for (final file in widget.files) {
      final url = _completedUrls[file.id];
      if (url != null) {
        orderedUrls.add(url);
      }
    }

    // Close dialog after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(orderedUrls);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isUploading ? 'Uploading Files...' : 'Upload Complete'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.files.map((file) {
              final progress = _progressMap[file.id];
              final isCompleted = _completedUrls.containsKey(file.id);
              final hasError = _errors.containsKey(file.id);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    if (progress != null && !isCompleted && !hasError) ...[
                      LinearProgressIndicator(value: progress.percent / 100),
                      const SizedBox(height: 2),
                      Text(
                        '${progress.percent.toStringAsFixed(1)}% • ${(progress.transferred / 1024).toStringAsFixed(1)}/${(progress.total / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ] else if (isCompleted) ...[
                      const LinearProgressIndicator(value: 1.0),
                      const Text(
                        'Completed',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ] else if (hasError) ...[
                      LinearProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.red.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                      ),
                      Text(
                        'Failed: ${_errors[file.id]}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ] else ...[
                      const LinearProgressIndicator(),
                      const Text(
                        'Preparing...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        if (!_isUploading)
          TextButton(
            onPressed: () {
              // Return URLs in the same order as input files
              final orderedUrls = <String>[];
              for (final file in widget.files) {
                final url = _completedUrls[file.id];
                if (url != null) {
                  orderedUrls.add(url);
                }
              }
              Navigator.of(context).pop(orderedUrls);
            },
            child: const Text('Close'),
          ),
      ],
    );
  }
}

/// Generalized media upload handler that works across all platforms
/// Provides a unified interface for picking and uploading multiple media files
class MediaUploadHandler {
  final BuildContext context;
  final String userId;
  final String category;

  // Prevent multiple simultaneous uploads
  static bool _isUploading = false;

  MediaUploadHandler({
    required this.context,
    required this.userId,
    required this.category,
  });

  /// Pick multiple media files
  Future<List<MediaFile>> pickMediaFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      AppLogger.candidate('📁 [Media Picker] Starting media file selection...');

      final files = await MediaPicker.pickFiles(
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (files.isEmpty) {
        AppLogger.candidate('📁 [Media Picker] User cancelled selection');
        return [];
      }

      AppLogger.candidate('📁 [Media Picker] Selected ${files.length} files');
      return files;
    } catch (e) {
      AppLogger.candidate('📁 [Media Picker] Error: $e');
      if (context.mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to pick files: ${e.toString()}');
      }
      return [];
    }
  }

  /// Upload multiple media files with basic progress
  Future<List<String>> uploadMediaFiles(List<MediaFile> files, {String? customPath}) async {
    try {
      AppLogger.candidate('☁️ [Media Upload] Starting upload of ${files.length} files...');

      final urls = await MediaUploader.uploadFiles(
        files,
        userId: userId,
        category: category,
        customPath: customPath,
      );

      AppLogger.candidate('☁️ [Media Upload] Successfully uploaded ${urls.length} files');
      return urls;
    } catch (e) {
      AppLogger.candidate('☁️ [Media Upload] Error: $e');
      if (context.mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to upload files: ${e.toString()}');
      }
      return [];
    }
  }

  /// Upload multiple media files with advanced progress tracking
  Future<List<String>> uploadMediaFilesAdvanced(
    List<MediaFile> files, {
    String? customPath,
    required void Function(String id, UploadProgress progress) onProgress,
    required void Function(String id, String downloadUrl) onComplete,
    required void Function(String id, String error) onError,
  }) async {
    try {
      AppLogger.candidate('☁️ [Media Upload Advanced] Starting advanced upload of ${files.length} files...');

      final uploader = MediaUploaderAdvanced();
      final urls = await uploader.uploadFiles(
        files,
        userId: userId,
        category: category,
        customPath: customPath,
        onProgress: onProgress,
        onComplete: onComplete,
        onError: onError,
      );

      AppLogger.candidate('☁️ [Media Upload Advanced] Completed upload of ${urls.length} files');
      return urls;
    } catch (e) {
      AppLogger.candidate('☁️ [Media Upload Advanced] Error: $e');
      if (context.mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to upload files: ${e.toString()}');
      }
      return [];
    }
  }

  /// Upload multiple media files with progress dialog
  Future<List<String>> uploadMediaFilesWithProgressDialog(
    List<MediaFile> files, {
    String? customPath,
  }) async {
    // Prevent multiple simultaneous uploads
    if (_isUploading || MediaUploadProgressDialog._dialogShowing) {
      debugPrint('⚠️ [MediaUploadHandler] Upload already in progress, skipping duplicate request');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload already in progress. Please wait.')),
        );
      }
      return [];
    }

    if (!context.mounted) return [];

    _isUploading = true;
    MediaUploadProgressDialog._dialogShowing = true;

    try {
      // Show progress dialog and wait for result
      final urls = await showDialog<List<String>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => MediaUploadProgressDialog(
          files: files,
          userId: userId,
          category: category,
          customPath: customPath,
        ),
      );

      // Return the URLs from the dialog, or empty list if dialog was dismissed
      return urls ?? [];
    } finally {
      _isUploading = false;
      MediaUploadProgressDialog._dialogShowing = false;
    }
  }

  /// Pick and upload media files in one step
  Future<List<String>> pickAndUploadMediaFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    final files = await pickMediaFiles(
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );

    if (files.isEmpty) return [];

    return await uploadMediaFiles(files);
  }

  /// Validate file sizes before upload
  List<MediaFile> validateFileSizes(List<MediaFile> files, {
    double maxImageSizeMB = 10.0,
    double maxVideoSizeMB = 100.0,
    double maxPdfSizeMB = 20.0,
    double maxOtherSizeMB = 50.0,
  }) {
    final validFiles = <MediaFile>[];

    for (final file in files) {
      final sizeMB = file.size / (1024 * 1024);
      double maxSize;

      switch (file.type) {
        case 'image':
          maxSize = maxImageSizeMB;
          break;
        case 'video':
          maxSize = maxVideoSizeMB;
          break;
        case 'pdf':
          maxSize = maxPdfSizeMB;
          break;
        default:
          maxSize = maxOtherSizeMB;
      }

      if (sizeMB <= maxSize) {
        validFiles.add(file);
      } else {
        AppLogger.candidate('⚠️ [Validation] File ${file.name} too large: ${sizeMB.toStringAsFixed(1)}MB > ${maxSize}MB');
        if (context.mounted) {
          SnackbarUtils.showScaffoldWarning(
            context,
            '${file.name} is too large (${sizeMB.toStringAsFixed(1)}MB). Maximum allowed: ${maxSize}MB.',
          );
        }
      }
    }

    return validFiles;
  }

  /// Clean up temporary web files
  void cleanup() {
    if (kIsWeb) {
      MediaPicker.clearWebTemp();
      AppLogger.candidate('🧹 [Cleanup] Cleared web temporary files');
    }
  }
}