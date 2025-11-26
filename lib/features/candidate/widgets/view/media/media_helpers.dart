import 'package:janmat/utils/app_logger.dart';

// Extract storage path from Firebase URL
String _extractStoragePath(String firebaseUrl) {
  try {
    // Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
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

String formatCommentTime(String? dateString) {
  if (dateString == null) return '';

  try {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return '';
  }
}