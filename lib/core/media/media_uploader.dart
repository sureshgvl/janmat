import 'package:firebase_storage/firebase_storage.dart';
import '../models/unified_file.dart';
import '../services/firebase_uploader.dart';
import 'media_file.dart';

/// Firebase-based media uploader for multiple files.
/// Uses the existing FirebaseUploader service for consistency.
class MediaUploader {
  /// Upload multiple MediaFiles to Firebase Storage
  static Future<List<String>> uploadFiles(
    List<MediaFile> files, {
    required String userId,
    required String category,
    String? customPath,
  }) async {
    List<String> urls = [];

    for (final file in files) {
      final url = await _uploadSingle(file, userId, category, customPath);
      urls.add(url);
    }

    return urls;
  }

  /// Upload single MediaFile
  static Future<String> uploadSingle(
    MediaFile file, {
    required String userId,
    required String category,
    String? customPath,
  }) async {
    return await _uploadSingle(file, userId, category, customPath);
  }

  static Future<String> _uploadSingle(MediaFile file, String userId, String category, String? customPath) async {
    // Create UnifiedFile from MediaFile for compatibility
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

    // Upload using existing FirebaseUploader
    final url = await FirebaseUploader.uploadUnifiedFile(
      f: unifiedFile,
      storagePath: storagePath,
      metadata: meta,
    );

    if (url == null) {
      throw Exception('Failed to upload ${file.name}');
    }

    return url;
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