import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/unified_file.dart';
import '../services/firebase_uploader.dart';
import 'media_file.dart';

/// Advanced media uploader with progress tracking, cancellation, and retry logic.
class UploadProgress {
  final double percent; // 0.0 → 100.0
  final int transferred; // bytes
  final int total; // bytes
  final double speedKBps; // upload speed
  final Duration eta; // remaining time

  UploadProgress({
    required this.percent,
    required this.transferred,
    required this.total,
    required this.speedKBps,
    required this.eta,
  });
}

class MediaUploaderAdvanced {
  // TODO: Implement cancellation support when FirebaseUploader exposes UploadTask
  // final Map<String, UploadTask> _tasks = {};

  /// Upload multiple files with progress callbacks
  Future<List<String>> uploadFiles(
    List<MediaFile> files, {
    required String userId,
    required String category,
    String? customPath,
    required void Function(String id, UploadProgress progress) onProgress,
    required void Function(String id, String downloadUrl) onComplete,
    required void Function(String id, String error) onError,
  }) async {
    List<String> urls = [];
    List<Future<void>> uploadFutures = [];

    for (final mf in files) {
      final uploadFuture = uploadSingle(
        mf,
        userId: userId,
        category: category,
        customPath: customPath,
        onProgress: (progress) => onProgress(mf.id, progress),
        onComplete: (url) {
          urls.add(url);
          onComplete(mf.id, url);
        },
        onError: (err) => onError(mf.id, err),
      );
      uploadFutures.add(uploadFuture);
    }

    // Wait for all uploads to complete
    await Future.wait(uploadFutures);

    return urls;
  }

  /// Upload single file with progress tracking
  Future<void> uploadSingle(
    MediaFile file, {
    required String userId,
    required String category,
    String? customPath,
    required void Function(UploadProgress progress) onProgress,
    required void Function(String downloadUrl) onComplete,
    required void Function(String error) onError,
  }) async {
    // Create UnifiedFile from MediaFile
    final unifiedFile = UnifiedFile(
      name: file.name,
      size: file.size,
      bytes: file.bytes,
      mimeType: _getMimeType(file.type),
    );

    // Generate storage path
    String storagePath;
    if (customPath != null) {
      // Custom path provided - append filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      storagePath = '$customPath${timestamp}_$cleanName';
    } else {
      // Use recommended path
      storagePath = FirebaseUploader.getRecommendedStoragePath(
        unifiedFile,
        userId,
        category,
      );
    }

    // Create metadata
    final meta = SettableMetadata(
      contentType: _getContentType(file.type),
    );

    // Upload with progress tracking
    final url = await FirebaseUploader.uploadUnifiedFile(
      f: unifiedFile,
      storagePath: storagePath,
      metadata: meta,
      onProgress: (percent) {
        // Convert simple progress to detailed UploadProgress
        final progress = UploadProgress(
          percent: percent,
          transferred: (percent / 100 * file.size).toInt(),
          total: file.size,
          speedKBps: 0.0, // Would need more complex tracking for speed
          eta: Duration.zero, // Would need more complex tracking for ETA
        );
        onProgress(progress);
      },
      onProgressBytes: (transferred, total) {
        // Calculate speed and ETA (simplified)
        final progress = UploadProgress(
          percent: (transferred / total) * 100,
          transferred: transferred,
          total: total,
          speedKBps: 0.0, // Simplified
          eta: Duration.zero, // Simplified
        );
        onProgress(progress);
      },
    );

    if (url != null) {
      onComplete(url);
    } else {
      onError('Upload failed');
    }
  }

  /// Cancel upload by file ID
  void cancelUpload(String fileId) {
    // Note: FirebaseUploader doesn't expose UploadTask directly
    // This would need modification to FirebaseUploader to support cancellation
    // For now, this is a placeholder
  }

  /// Retry upload
  Future<void> retryUpload(
    MediaFile file, {
    required String userId,
    required String category,
    String? customPath,
    required void Function(UploadProgress progress) onProgress,
    required void Function(String downloadUrl) onComplete,
    required void Function(String error) onError,
  }) async {
    return uploadSingle(
      file,
      userId: userId,
      category: category,
      customPath: customPath,
      onProgress: onProgress,
      onComplete: onComplete,
      onError: onError,
    );
  }

  static String _getContentType(String type) {
    switch (type) {
      case "image":
        return "image/jpeg";
      case "pdf":
        return "application/pdf";
      case "video":
        return "video/mp4";
      case "audio":
        return "audio/mpeg";
      default:
        return "application/octet-stream";
    }
  }

  static String _getMimeType(String type) {
    return _getContentType(type);
  }
}