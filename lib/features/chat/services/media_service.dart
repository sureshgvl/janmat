import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../utils/app_logger.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload media file to Firebase Storage with automatic compression
  Future<String> uploadMediaFile(
    String roomId,
    String filePath,
    String fileName,
    String contentType,
  ) async {
    try {
      AppLogger.chat('📤 MediaService: Starting upload for: $fileName');

      String finalFilePath = filePath;

      // Compress images before upload
      if (contentType.startsWith('image/')) {
        AppLogger.chat('🗜️ Compressing image before upload...');
        final compressedPath = await compressImage(filePath);
        if (compressedPath != null && compressedPath != filePath) {
          finalFilePath = compressedPath;
          AppLogger.chat('✅ Using compressed image for upload');
        }
      }

      final storageRef = _storage.ref().child('chat_media/$roomId/$fileName');
      final uploadTask = storageRef.putFile(
        File(finalFilePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.chat('✅ MediaService: Upload completed successfully');
      return downloadUrl;
    } catch (e) {
      AppLogger.chat('❌ MediaService: Upload failed: $e');
      throw Exception('Failed to upload media file: $e');
    }
  }

  // Download and cache media file locally
  Future<String?> downloadAndCacheMedia(
    String messageId,
    String remoteUrl,
    String fileName,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      final localPath = path.join(mediaDir.path, fileName);
      final file = File(localPath);

      // Check if file already exists
      if (await file.exists()) {
        return localPath;
      }

      // Download file
      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return localPath;
      } else {
        throw Exception(
          'Failed to download media: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to cache media: $e');
    }
  }

  // Get local media path if available
  Future<String?> getLocalMediaPath(String messageId, String? remoteUrl) async {
    if (remoteUrl == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

    if (!await mediaDir.exists()) {
      return null;
    }

    final fileName = path.basename(remoteUrl);
    final localPath = path.join(mediaDir.path, fileName);
    final file = File(localPath);

    if (await file.exists()) {
      return localPath;
    }

    return null;
  }

  // Clean up old media files (keep files from last 30 days)
  Future<void> cleanupOldMediaFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

      if (!await mediaDir.exists()) return;

      final files = mediaDir.listSync();
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(thirtyDaysAgo)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Silently fail cleanup
    }
  }

  // Get media file size
  Future<int?> getMediaFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }

  // Compress image before upload
  Future<String?> compressImage(
    String filePath, {
    int quality = 80,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      AppLogger.chat('🗜️ MediaService: Starting image compression for: $filePath');

      // Get original file size
      final originalFile = File(filePath);
      final originalSize = await originalFile.length();
      AppLogger.chat('📊 Original file size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Skip compression for very small files
      if (originalSize < 100 * 1024) { // Less than 100KB
        AppLogger.chat('⏭️ File too small for compression, skipping');
        return filePath;
      }

      // Create compressed file path
      final dir = await getTemporaryDirectory();
      final fileName = path.basenameWithoutExtension(filePath);
      final extension = path.extension(filePath);
      final compressedPath = path.join(dir.path, '${fileName}_compressed$extension');

      // Compress the image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        filePath,
        compressedPath,
        quality: quality,
        minWidth: 800,  // Minimum width to maintain quality
        minHeight: 600, // Minimum height to maintain quality
        format: extension.toLowerCase() == '.png' ? CompressFormat.png : CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedSize = await compressedFile.length();
        final compressionRatio = ((originalSize - compressedSize) / originalSize * 100);
        AppLogger.chat('✅ Image compressed successfully');
        AppLogger.chat('📊 Compressed file size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        AppLogger.chat('📊 Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');

        return compressedFile.path;
      } else {
        AppLogger.chat('⚠️ Image compression failed, using original file');
        return filePath;
      }
    } catch (e) {
      AppLogger.chat('❌ Error compressing image: $e');
      // Return original file if compression fails
      return filePath;
    }
  }

  // Generate thumbnail for video
  Future<String?> generateVideoThumbnail(String videoPath) async {
    // TODO: Implement video thumbnail generation
    // For now, return null
    return null;
  }
}

