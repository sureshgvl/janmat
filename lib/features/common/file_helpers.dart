import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../../utils/app_logger.dart';

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

/// Utility class for file operations across the app
class FileHelpers {
  // Web optimization: Chunk size for reading large files
  static const int _chunkSizeKb = 64; // 64KB chunks
  static const Duration _chunkReadDelay = Duration(milliseconds: 10); // Prevent UI blocking
  /// Validate file size with type-specific limits
  static Future<FileSizeValidation> validateFileSize(
    String filePath,
    String type,
    Map<String, dynamic> fileEntry,
  ) async {
    try {
      double fileSizeMB;

      if (kIsWeb) {
        // Web: Get file size from stored data
        final storedSize = fileEntry['fileSize'];
        if (storedSize is double) {
          fileSizeMB = storedSize;
        } else {
          // Fallback to bytes calculation
          final bytes = fileEntry['bytes'] as Uint8List?;
          fileSizeMB = bytes != null ? bytes.length / (1024 * 1024) : 0.0;
        }
      } else {
        // Mobile: Get file size from local file
        final file = File(filePath.replaceFirst('local:', ''));
        final fileSize = await file.length();
        fileSizeMB = fileSize / (1024 * 1024);
      }

      return _getValidationForType(type, fileSizeMB);
    } catch (e) {
      AppLogger.candidate('📏 [File Size Validation] Error: $e');
      return FileSizeValidation(
        isValid: false,
        fileSizeMB: 0.0,
        message: 'Failed to validate file size: ${e.toString()}',
        recommendation: 'Please try selecting the file again.',
      );
    }
  }

  static FileSizeValidation _getValidationForType(String type, double fileSizeMB) {
    switch (type) {
      case 'pdf':
        if (fileSizeMB > 20.0) {
          return FileSizeValidation(
            isValid: false,
            fileSizeMB: fileSizeMB,
            message: 'PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
            recommendation: 'Please choose a smaller PDF or compress the current one.',
          );
        } else if (fileSizeMB > 10.0) {
          return FileSizeValidation(
            isValid: true,
            fileSizeMB: fileSizeMB,
            message: 'Large PDF detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
            recommendation: 'Consider compressing the PDF for faster uploads.',
            warning: true,
          );
        }
        break;

      case 'image':
        if (fileSizeMB > 10.0) {
          return FileSizeValidation(
            isValid: false,
            fileSizeMB: fileSizeMB,
            message: 'Image file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 10MB.',
            recommendation: 'Please choose a smaller image or compress the current one.',
          );
        } else if (fileSizeMB > 5.0) {
          return FileSizeValidation(
            isValid: true,
            fileSizeMB: fileSizeMB,
            message: 'Large image detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
            recommendation: 'Consider compressing the image for faster uploads.',
            warning: true,
          );
        }
        break;

      case 'video':
        if (fileSizeMB > 100.0) {
          return FileSizeValidation(
            isValid: false,
            fileSizeMB: fileSizeMB,
            message: 'Video file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 100MB.',
            recommendation: 'Please choose a smaller video or compress the current one.',
          );
        } else if (fileSizeMB > 50.0) {
          return FileSizeValidation(
            isValid: true,
            fileSizeMB: fileSizeMB,
            message: 'Large video detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
            recommendation: 'Consider compressing the video for faster uploads.',
            warning: true,
          );
        }
        break;
    }

    return FileSizeValidation(
      isValid: true,
      fileSizeMB: fileSizeMB,
      message: 'File size is acceptable (${fileSizeMB.toStringAsFixed(1)}MB).',
      recommendation: null,
    );
  }

  /// Optimize image for different use cases
  static Future<XFile> optimizeImage(
    XFile image,
    String context, // 'manifesto' or 'achievement'
  ) async {
    try {
      double fileSizeMB = 0.0;

      if (kIsWeb) {
        // Web: Get file size from bytes if possible
        try {
          final bytes = await image.readAsBytes();
          fileSizeMB = bytes.length / (1024 * 1024);
          AppLogger.candidate(
            '🖼️ [$context Image] Original size: ${fileSizeMB.toStringAsFixed(2)} MB',
          );
        } catch (e) {
          AppLogger.candidate(
            '🖼️ [$context Image] Unable to get file size on web, proceeding with optimization',
          );
        }
      } else {
        // Mobile: Get file size from local file
        final file = File(image.path);
        final fileSize = await file.length();
        fileSizeMB = fileSize / (1024 * 1024);

        AppLogger.candidate(
          '🖼️ [$context Image] Original size: ${fileSizeMB.toStringAsFixed(2)} MB',
        );
      }

      // Different optimization settings for different contexts
      int quality = context == 'manifesto' ? 85 : 80;
      int? maxWidth;
      int? maxHeight;

      if (fileSizeMB > (context == 'manifesto' ? 8.0 : 4.0)) {
        quality = context == 'manifesto' ? 75 : 70;
        maxWidth = context == 'manifesto' ? 1600 : 1200;
        maxHeight = context == 'manifesto' ? 1600 : 1200;
        AppLogger.candidate(
          '🖼️ [$context Image] Large file detected, applying optimization',
        );
      } else {
        // File size acceptable, no optimization needed
        AppLogger.candidate(
          '🖼️ [$context Image] File size acceptable, no optimization needed',
        );
        return image;
      }

      // Create optimized version
      final ImagePicker imagePicker = ImagePicker();
      final optimizedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: quality,
      );

      if (optimizedImage != null && !kIsWeb) {
        // Calculate compression ratio (only on mobile)
        final optimizedFile = File(optimizedImage.path);
        final optimizedSize = await optimizedFile.length();
        final optimizedSizeMB = optimizedSize / (1024 * 1024);

        AppLogger.candidate(
          '🖼️ [$context Image] Optimized size: ${optimizedSizeMB.toStringAsFixed(2)} MB (${(((fileSizeMB - optimizedSizeMB) / fileSizeMB) * 100).toStringAsFixed(1)}% reduction)',
        );
      }

      return optimizedImage ?? image;
    } catch (e) {
      AppLogger.candidate(
        '⚠️ [$context Image] Optimization failed, using original: $e',
      );
      return image;
    }
  }

  /// Show file size warning dialog
  static Future<bool?> showFileSizeWarningDialog(
    BuildContext context,
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

  /// Get file icon based on type
  static (IconData icon, Color color) getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return (Icons.picture_as_pdf, Colors.red);
      case 'image':
        return (Icons.image, Colors.green);
      case 'video':
        return (Icons.video_call, Colors.purple);
      default:
        return (Icons.file_present, Colors.grey);
    }
  }

  /// Get filename from different sources
  static String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Unknown File';
    } catch (e) {
      return 'Unknown File';
    }
  }

  /// WEB OPTIMIZATION: Read large files in chunks to prevent UI blocking
  /// Returns a stream of byte chunks for progressive processing
  static Stream<Uint8List> readFileInChunks(
    dynamic file, {
    void Function(double progress)? onProgress,
    Duration? delayBetweenChunks,
  }) async* {
    try {
      AppLogger.candidate('📄 [Chunked Read] Starting chunked file reading...');

      if (!kIsWeb) {
        // For mobile, read the entire file at once (no issue)
        if (file is File) {
          final bytes = await file.readAsBytes();
          yield bytes;
          onProgress?.call(1.0);
          return;
        } else if (file is XFile) {
          final bytes = await file.readAsBytes();
          yield bytes;
          onProgress?.call(1.0);
          return;
        }
      }

      // Web: Read file in chunks
      dynamic webFile;

      if (file is file_picker.PlatformFile && file.bytes != null) {
        webFile = file.bytes;
      } else if (file is XFile) {
        webFile = await file.readAsBytes();
      } else if (file is Uint8List) {
        webFile = file;
      } else {
        throw Exception('Unsupported file type for chunked reading');
      }

      if (webFile is! Uint8List) {
        throw Exception('Cannot read file - not a Uint8List');
      }

      final totalBytes = webFile.length;
      final chunkSizeBytes = _chunkSizeKb * 1024; // Convert KB to bytes
      var readBytes = 0;

      AppLogger.candidate('📄 [Chunked Read] File size: $totalBytes bytes, chunk size: $chunkSizeBytes bytes');

      while (readBytes < totalBytes) {
        final remainingBytes = totalBytes - readBytes;
        final currentChunkSize = min(chunkSizeBytes, remainingBytes);

        // Extract chunk
        final chunk = Uint8List(currentChunkSize);
        for (var i = 0; i < currentChunkSize; i++) {
          chunk[i] = webFile[readBytes + i];
        }

        readBytes += currentChunkSize;

        // Report progress
        final progress = readBytes / totalBytes;
        onProgress?.call(progress);

        AppLogger.candidate('📄 [Chunked Read] Read chunk: ${chunk.length} bytes (${(progress * 100).toStringAsFixed(1)}% complete)');

        yield chunk;

        // Small delay to prevent blocking UI
        if (delayBetweenChunks != null) {
          await Future.delayed(delayBetweenChunks);
        } else if (chunkSizeBytes >= 64 * 1024) { // Only delay for large chunks
          await Future.delayed(_chunkReadDelay);
        }
      }

      AppLogger.candidate('📄 [Chunked Read] Completed reading file in chunks');

    } catch (e) {
      AppLogger.candidate('❌ [Chunked Read] Error reading file in chunks: $e');
      rethrow;
    }
  }

  /// WEB OPTIMIZATION: Validate large files without loading entire content
  static Future<bool> shouldWarnAboutLargeFile(String fileName, int fileSizeBytes, String type) async {
    final fileSizeMB = fileSizeBytes / (1024 * 1024);

    // Web-specific warnings for different file types
    switch (type) {
      case 'pdf':
        if (fileSizeMB > 10.0) {
          AppLogger.candidate('⚠️ [Web Warning] Large PDF detected: ${fileSizeMB.toStringAsFixed(1)}MB');
          return true;
        }
        break;

      case 'image':
        if (fileSizeMB > 5.0) {
          AppLogger.candidate('⚠️ [Web Warning] Large image detected: ${fileSizeMB.toStringAsFixed(1)}MB');
          return true;
        }
        break;

      case 'video':
        if (fileSizeMB > 50.0) {
          AppLogger.candidate('⚠️ [Web Warning] Large video detected: ${fileSizeMB.toStringAsFixed(1)}MB');
          return true;
        }
        break;
    }

    return false;
  }

  /// WEB OPTIMIZATION: Progress callback for file processing
  static void showFileProcessingDialog(
    BuildContext context, {
    required String operation,
    required Stream<double> progressStream,
    required VoidCallback onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FileProcessingDialog(
        operation: operation,
        progressStream: progressStream,
        onCancel: onCancel,
      ),
    );
  }
}

/// Progress dialog for file processing operations
class FileProcessingDialog extends StatefulWidget {
  final String operation;
  final Stream<double> progressStream;
  final VoidCallback onCancel;

  const FileProcessingDialog({
    super.key,
    required this.operation,
    required this.progressStream,
    required this.onCancel,
  });

  @override
  State<FileProcessingDialog> createState() => _FileProcessingDialogState();
}

class _FileProcessingDialogState extends State<FileProcessingDialog> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.progressStream.listen((progress) {
      if (mounted) {
        setState(() => _progress = progress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.operation}...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 16),
          Text('${(_progress * 100).toStringAsFixed(1)}% complete'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Basic file picker utilities
class FilePickerUtils {
  /// Pick single PDF file
  static Future<file_picker.FilePickerResult?> pickPdf() async {
    return await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
  }

  /// Pick single image
  static Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
  }

  /// Pick single video
  static Future<XFile?> pickVideo() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
  }
}
