import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload media file to Firebase Storage
  Future<String> uploadMediaFile(String roomId, String filePath, String fileName, String contentType) async {
    try {
      final storageRef = _storage.ref().child('chat_media/$roomId/$fileName');
      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media file: $e');
    }
  }

  // Download and cache media file locally
  Future<String?> downloadAndCacheMedia(String messageId, String remoteUrl, String fileName) async {
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
        throw Exception('Failed to download media: HTTP ${response.statusCode}');
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
  Future<String?> compressImage(String filePath, {int quality = 80, int maxWidth = 1920, int maxHeight = 1080}) async {
    // TODO: Implement image compression using flutter_image_compress
    // For now, return original path
    return filePath;
  }

  // Generate thumbnail for video
  Future<String?> generateVideoThumbnail(String videoPath) async {
    // TODO: Implement video thumbnail generation
    // For now, return null
    return null;
  }
}