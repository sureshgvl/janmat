import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import '../utils/chat_constants.dart';

class MediaUtils {
  // Check if file is supported image
  static bool isSupportedImage(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    return ChatConstants.supportedImageExtensions.contains(extension);
  }

  // Check if file is supported video
  static bool isSupportedVideo(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    return ChatConstants.supportedVideoExtensions.contains(extension);
  }

  // Check if file is supported audio
  static bool isSupportedAudio(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    return ChatConstants.supportedAudioExtensions.contains(extension);
  }

  // Get MIME type from file path
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  // Get file size
  static Future<int?> getFileSize(String filePath) async {
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

  // Check if file size is within limits
  static Future<bool> isValidFileSize(String filePath, {int maxSize = ChatConstants.maxFileSize}) async {
    final size = await getFileSize(filePath);
    return size != null && size <= maxSize;
  }

  // Generate unique file name
  static String generateUniqueFileName(String originalName, String messageId) {
    final extension = path.extension(originalName);
    final baseName = path.basenameWithoutExtension(originalName);
    return '${messageId}_${baseName}_$extension';
  }

  // Get file extension from MIME type
  static String? getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'audio/mpeg':
        return 'mp3';
      case 'audio/wav':
        return 'wav';
      case 'audio/aac':
        return 'aac';
      case 'video/mp4':
        return 'mp4';
      case 'video/quicktime':
        return 'mov';
      default:
        return null;
    }
  }

  // Validate media file
  static Future<String?> validateMediaFile(String filePath) async {
    if (!await File(filePath).exists()) {
      return 'File does not exist';
    }

    if (!await isValidFileSize(filePath)) {
      return 'File is too large (max ${ChatConstants.maxFileSize ~/ (1024 * 1024)}MB)';
    }

    final mimeType = getMimeType(filePath);
    if (mimeType == null) {
      return 'Unsupported file type';
    }

    if (!isSupportedImage(filePath) &&
        !isSupportedVideo(filePath) &&
        !isSupportedAudio(filePath)) {
      return 'Unsupported file format';
    }

    return null; // Valid
  }

  // Get media type from file path
  static String getMediaType(String filePath) {
    if (isSupportedImage(filePath)) {
      return 'image';
    } else if (isSupportedVideo(filePath)) {
      return 'video';
    } else if (isSupportedAudio(filePath)) {
      return 'audio';
    } else {
      return 'unknown';
    }
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Check if file is image
  static bool isImage(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType != null && mimeType.startsWith('image/');
  }

  // Check if file is video
  static bool isVideo(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType != null && mimeType.startsWith('video/');
  }

  // Check if file is audio
  static bool isAudio(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType != null && mimeType.startsWith('audio/');
  }

  // Get image dimensions (placeholder - would need image processing library)
  static Future<Map<String, int>?> getImageDimensions(String filePath) async {
    // TODO: Implement with image processing library
    // For now, return null
    return null;
  }

  // Compress image (placeholder - would need image processing library)
  static Future<String?> compressImage(String filePath, {int quality = 80}) async {
    // TODO: Implement with flutter_image_compress
    // For now, return original path
    return filePath;
  }

  // Generate video thumbnail (placeholder - would need video processing library)
  static Future<String?> generateVideoThumbnail(String videoPath) async {
    // TODO: Implement with video processing library
    // For now, return null
    return null;
  }
}