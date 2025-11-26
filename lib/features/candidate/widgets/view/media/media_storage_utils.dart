import 'package:janmat/utils/app_logger.dart';

/// Utilities for handling media storage operations
/// Following Single Responsibility Principle - only handles storage-related operations
class MediaStorageUtils {
  /// Extract storage path from Firebase Storage URL
  /// 
  /// Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
  /// Returns the decoded storage path, or empty string if extraction fails
  static String extractStoragePath(String firebaseUrl) {
    try {
      final uri = Uri.parse(firebaseUrl);

      // Ensure this is a valid Firebase Storage URL
      if (!uri.host.contains('firebasestorage.googleapis.com') ||
          !uri.path.startsWith('/v0/b/')) {
        AppLogger.candidateError(
          'Invalid Firebase Storage URL format: $firebaseUrl',
        );
        return '';
      }

      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4) {
        AppLogger.candidateError(
          'Firebase URL does not have enough path segments: $firebaseUrl',
        );
        return '';
      }

      // Skip v0/b/bucket/o/ parts to get the actual storage path
      final storagePath = pathSegments.skip(3).join('/');
      final decodedPath = Uri.decodeComponent(storagePath);

      // Validate the extracted path
      if (decodedPath.isEmpty) {
        AppLogger.candidateError(
          'Extracted storage path is empty from: $firebaseUrl',
        );
        return '';
      }

      return decodedPath;
    } catch (e) {
      AppLogger.candidateError(
        'Failed to extract storage path from: $firebaseUrl - Error: $e',
      );
      return '';
    }
  }

  /// Validate if a URL is a Firebase Storage URL
  static bool isFirebaseStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('firebasestorage.googleapis.com');
    } catch (e) {
      return false;
    }
  }

  /// Convert Firebase URL to storage path if possible
  /// Returns null if URL is not a Firebase storage URL or extraction fails
  static String? urlToStoragePath(String firebaseUrl) {
    final storagePath = extractStoragePath(firebaseUrl);
    return storagePath.isNotEmpty ? storagePath : null;
  }

  /// Extract all valid storage paths from a list of URLs
  static List<String> extractValidStoragePaths(List<String> urls) {
    final List<String> validPaths = [];
    
    for (final url in urls) {
      if (isFirebaseStorageUrl(url)) {
        final path = extractStoragePath(url);
        if (path.isNotEmpty) {
          validPaths.add(path);
        }
      }
    }
    
    return validPaths;
  }

  /// Filter URLs to only include Firebase Storage URLs
  static List<String> filterFirebaseUrls(List<String> urls) {
    return urls.where(isFirebaseStorageUrl).toList();
  }

  /// Validate storage path format
  static bool isValidStoragePath(String path) {
    if (path.isEmpty) return false;
    
    // Basic validation - path should not contain certain invalid characters
    // and should be properly formatted
    return !path.contains('..') && // No directory traversal
           !path.startsWith('/') && // Should not start with slash
           !path.endsWith('/'); // Should not end with slash
  }

  /// Generate a clean storage path from components
  static String buildStoragePath(String basePath, String fileName) {
    // Remove leading/trailing slashes and ensure proper formatting
    final cleanBase = basePath.replaceAll(RegExp(r'^/+|/+$'), '');
    final cleanFileName = fileName.replaceAll(RegExp(r'^/+|/+$'), '');
    
    return '$cleanBase/$cleanFileName';
  }

  /// Get file extension from storage path
  static String getFileExtension(String storagePath) {
    final parts = storagePath.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  /// Determine media type from file extension
  static String getMediaTypeFromExtension(String fileName) {
    final extension = getFileExtension(fileName);
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(extension)) {
      return 'video';
    } else if (extension == 'pdf') {
      return 'document';
    }
    
    return 'unknown';
  }

  /// Validate if file name is acceptable for storage
  static bool isValidFileName(String fileName) {
    if (fileName.isEmpty) return false;
    
    // Check for invalid characters
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(fileName)) return false;
    
    // Check length (common limit is 255 characters for file names)
    if (fileName.length > 255) return false;
    
    return true;
  }

  /// Clean file name for storage (remove invalid characters)
  static String cleanFileName(String fileName) {
    // Replace invalid characters with underscores
    String cleaned = fileName.replaceAllMapped(
      RegExp(r'[<>:"/\\|?*]'),
      (match) => '_',
    );
    
    // Remove multiple consecutive underscores
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_');
    
    // Trim underscores from start and end
    cleaned = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Ensure name is not empty after cleaning
    if (cleaned.isEmpty) {
      cleaned = 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return cleaned;
  }
}
