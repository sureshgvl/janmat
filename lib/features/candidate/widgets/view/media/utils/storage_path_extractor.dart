/// Utility class for extracting Firebase Storage paths from URLs
class StoragePathExtractor {
  StoragePathExtractor._();

  /// Extract Firebase storage path from a Firebase Storage URL
  /// 
  /// Expected URL format: 
  /// https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
  /// 
  /// Returns empty string if extraction fails
  static String extractFromFirebaseUrl(String firebaseUrl) {
    try {
      final uri = Uri.parse(firebaseUrl);

      // Ensure this is a valid Firebase Storage URL
      if (!uri.host.contains('firebasestorage.googleapis.com') ||
          !uri.path.startsWith('/v0/b/')) {
        return '';
      }

      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4) {
        return '';
      }

      // Skip v0/b/bucket/o/ parts to get the actual storage path
      final storagePath = pathSegments.skip(3).join('/');
      final decodedPath = Uri.decodeComponent(storagePath);

      // Validate the extracted path
      if (decodedPath.isEmpty) {
        return '';
      }

      return decodedPath;
    } catch (e) {
      return '';
    }
  }

  /// Check if a URL is a valid Firebase Storage URL
  static bool isFirebaseStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('firebasestorage.googleapis.com') &&
             uri.path.startsWith('/v0/b/');
    } catch (e) {
      return false;
    }
  }

  /// Check if a URL is a local/relative path (not a full URL)
  static bool isLocalPath(String url) {
    return url.startsWith('/') || 
           url.startsWith('./') || 
           url.startsWith('../') ||
           (!url.startsWith('http://') && !url.startsWith('https://'));
  }

  /// Extract bucket name from Firebase Storage URL
  static String extractBucketName(String firebaseUrl) {
    try {
      final uri = Uri.parse(firebaseUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2 && pathSegments[0] == 'v0' && pathSegments[1] == 'b') {
        return pathSegments[2];
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }
}
