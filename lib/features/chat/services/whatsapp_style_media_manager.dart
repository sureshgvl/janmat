import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// import 'package:gallery_saver/gallery_saver.dart'; // Temporarily disabled due to http version conflict
import '../../../utils/app_logger.dart';

enum MediaType { image, video, audio, document }

class WhatsAppStyleMediaManager {
  static const String _appMediaFolder = 'JanMat';

  // Save media to device storage (gallery saving temporarily disabled due to package conflicts)
  Future<String> saveMediaToGallery(
    String messageId,
    Uint8List bytes,
    String fileName,
    MediaType type,
  ) async {
    try {
      AppLogger.chat('📱 WhatsAppStyleMediaManager: Saving media to storage - $messageId, $fileName');

      // Determine file extension
      final extension = _getFileExtension(fileName);

      // For now, save to external storage (gallery saving disabled due to package conflicts)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('External storage not available');
      }

      final appMediaDir = Directory(path.join(externalDir.path, _appMediaFolder));
      await appMediaDir.create(recursive: true);

      final filePath = path.join(appMediaDir.path, '${_appMediaFolder}_$messageId$extension');
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      AppLogger.chat('✅ WhatsAppStyleMediaManager: Media saved to external storage: $filePath');
      AppLogger.chat('ℹ️ WhatsAppStyleMediaManager: Gallery saving temporarily disabled due to package conflicts');

      return filePath;
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to save media: $e');
      rethrow;
    }
  }

  // Save media locally for app use (separate from gallery)
  Future<String> saveMediaLocally(
    String messageId,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));
      await mediaDir.create(recursive: true);

      final extension = _getFileExtension(fileName);
      final filePath = path.join(mediaDir.path, '$messageId$extension');
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      AppLogger.chat('💾 WhatsAppStyleMediaManager: Media saved locally: $filePath');
      return filePath;
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to save media locally: $e');
      rethrow;
    }
  }

  // Get local media path for display
  Future<String?> getLocalMediaPath(String messageId, String originalFileName) async {
    try {
      // First check app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

      if (mediaDir.existsSync()) {
        final extension = _getFileExtension(originalFileName);
        final localFile = File(path.join(mediaDir.path, '$messageId$extension'));

        if (localFile.existsSync()) {
          return localFile.path;
        }
      }

      // Fallback: check external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final appMediaDir = Directory(path.join(externalDir.path, _appMediaFolder));

        if (appMediaDir.existsSync()) {
          final files = appMediaDir.listSync().whereType<File>();
          final matchingFile = files.firstWhere(
            (file) => path.basenameWithoutExtension(file.path).endsWith(messageId),
            orElse: () => null as File,
          );

          if (matchingFile != null) {
            return matchingFile.path;
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to get local media path: $e');
      return null;
    }
  }

  // Check if media exists locally
  Future<bool> isMediaAvailableLocally(String messageId, String originalFileName) async {
    final localPath = await getLocalMediaPath(messageId, originalFileName);
    return localPath != null;
  }

  // Download and cache media locally
  Future<String?> downloadAndCacheMedia(
    String messageId,
    String remoteUrl,
    String originalFileName,
  ) async {
    try {
      AppLogger.chat('⬇️ WhatsAppStyleMediaManager: Downloading media: $remoteUrl');

      // Download bytes (you'll need to implement HTTP client)
      final bytes = await _downloadFile(remoteUrl);
      if (bytes == null) return null;

      // Save locally for app use
      final localPath = await saveMediaLocally(messageId, bytes, originalFileName);

      // Also save to gallery if it's media (optional - based on user preference)
      final type = _determineMediaType(originalFileName);
      if (type == MediaType.image || type == MediaType.video) {
        try {
          await saveMediaToGallery(messageId, bytes, originalFileName, type);
          AppLogger.chat('🖼️ WhatsAppStyleMediaManager: Media also saved to gallery');
        } catch (e) {
          AppLogger.chat('⚠️ WhatsAppStyleMediaManager: Gallery save failed, but local save succeeded: $e');
        }
      }

      return localPath;
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to download and cache media: $e');
      return null;
    }
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      int totalSize = 0;
      int fileCount = 0;

      // Check app documents
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

      if (mediaDir.existsSync()) {
        final files = mediaDir.listSync(recursive: true).whereType<File>();
        fileCount += files.length;
        for (final file in files) {
          totalSize += file.lengthSync();
        }
      }

      // Check external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final appMediaDir = Directory(path.join(externalDir.path, _appMediaFolder));

        if (appMediaDir.existsSync()) {
          final files = appMediaDir.listSync(recursive: true).whereType<File>();
          fileCount += files.length;
          for (final file in files) {
            totalSize += file.lengthSync();
          }
        }
      }

      return {
        'totalFiles': fileCount,
        'totalSizeBytes': totalSize,
        'totalSizeMB': totalSize / (1024 * 1024),
        'appDocumentsPath': mediaDir.path,
        'externalPath': externalDir?.path,
      };
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to get storage stats: $e');
      return {'error': e.toString()};
    }
  }

  // Clean up old media files
  Future<void> cleanupOldMedia({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final cutoffDate = DateTime.now().subtract(maxAge);

      // Clean app documents
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(path.join(appDir.path, 'chat_media'));

      if (mediaDir.existsSync()) {
        final files = mediaDir.listSync(recursive: true).whereType<File>();
        for (final file in files) {
          if (file.lastModifiedSync().isBefore(cutoffDate)) {
            await file.delete();
            AppLogger.chat('🗑️ WhatsAppStyleMediaManager: Deleted old media file: ${file.path}');
          }
        }
      }

      AppLogger.chat('✅ WhatsAppStyleMediaManager: Media cleanup completed');
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to cleanup old media: $e');
    }
  }

  // Helper methods
  String _getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  String _getMimeType(MediaType type, String extension) {
    switch (type) {
      case MediaType.image:
        return 'image/${extension.substring(1)}';
      case MediaType.video:
        return 'video/${extension.substring(1)}';
      case MediaType.audio:
        return 'audio/${extension.substring(1)}';
      case MediaType.document:
        return 'application/${extension.substring(1)}';
    }
  }

  MediaType _determineMediaType(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      return MediaType.image;
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return MediaType.video;
    } else if (['.mp3', '.m4a', '.aac', '.wav'].contains(extension)) {
      return MediaType.audio;
    } else {
      return MediaType.document;
    }
  }

  Future<Uint8List?> _downloadFile(String url) async {
    try {
      AppLogger.chat('⬇️ WhatsAppStyleMediaManager: Downloading from: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        AppLogger.chat('✅ WhatsAppStyleMediaManager: Downloaded ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        AppLogger.chat('❌ WhatsAppStyleMediaManager: Failed to download - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleMediaManager: Download error: $e');
      return null;
    }
  }
}
