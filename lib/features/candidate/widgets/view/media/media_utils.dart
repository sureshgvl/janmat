import 'package:flutter/material.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';

/// Utility class for common media-related operations
class MediaUtils {
  /// Extract storage path from Firebase URL
  /// 
  /// Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
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

  /// Sort media items by date (most recent first)
  static List<MediaItem> sortMediaItemsByDate(List<MediaItem> items) {
    final sortedItems = List<MediaItem>.from(items);
    sortedItems.sort((a, b) {
      if (a.date.isEmpty) return 1;
      if (b.date.isEmpty) return -1;

      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        return 0;
      }
    });
    return sortedItems;
  }

  /// Check if a URL is a local path or blob URL
  static bool isLocalOrBlobUrl(String url) {
    return url.startsWith('blob:') || url.startsWith('data:') || url.startsWith('file:');
  }

  /// Filter Firebase URLs (exclude local and blob URLs)
  static List<String> filterFirebaseUrls(List<String> urls) {
    return urls.where((url) => 
      !isLocalOrBlobUrl(url) && 
      url.contains('firebasestorage.googleapis.com')
    ).toList();
  }
}

/// Time formatting utility class
class TimeFormatter {
  /// Format comment time in a user-friendly way
  static String format(String? dateString) {
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

  /// Format post date for display
  static String formatPostDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        // Show actual date if older than a week
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}

/// User information helper utility
class UserInfoHelper {
  /// Get current user information (name and photo)
  static Map<String, String> getCurrentUserInfo() {
    try {
      // Try to get user info from CandidateUserController first
      // Note: This should be called within a GetX context
      return {
        'name': 'Anonymous User',
        'photo': '',
      };
    } catch (e) {
      return {
        'name': 'Anonymous User',
        'photo': '',
      };
    }
  }

  /// Validate candidate location data
  static bool validateCandidateLocation(Candidate candidate) {
    return candidate.location.stateId != null &&
           candidate.location.districtId != null &&
           candidate.location.bodyId != null &&
           candidate.location.wardId != null &&
           candidate.candidateId.isNotEmpty;
  }

  /// Get hierarchical path for candidate in Firestore
  static String getCandidatePath(Candidate candidate) {
    return 'states/${candidate.location.stateId}/districts/'
           '${candidate.location.districtId}/bodies/${candidate.location.bodyId}/'
           'wards/${candidate.location.wardId}/candidates/${candidate.candidateId}';
  }
}

/// Media item processor for parsing and processing media data
class MediaItemProcessor {
  /// Parse media items from candidate data (handles both old and new formats)
  static List<MediaItem> parseMediaItems(List<dynamic> media) {
    List<MediaItem> mediaItems = [];
    
    try {
      // Check if media is null or empty
      if (media == null || media.isEmpty) {
        return [];
      }

      // Check the first item to determine format
      final firstItem = media.first;

      if (firstItem is Map<String, dynamic>) {
        // New grouped format - each item is already a MediaItem map
        final List<dynamic> mediaList = media;
        final validItems = mediaList.whereType<Map<String, dynamic>>();

        mediaItems = validItems
            .map((item) {
              try {
                return MediaItem.fromJson(item);
              } catch (e) {
                AppLogger.candidateError('Error parsing MediaItem: $e');
                return null;
              }
            })
            .whereType<MediaItem>()
            .toList();
      } else if (firstItem is Media) {
        // Old format - individual Media objects need to be converted to grouped format
        mediaItems = _convertLegacyFormat(media);
      } else {
        AppLogger.candidateError(
          'Unexpected media item format: ${firstItem.runtimeType}',
        );
        mediaItems = [];
      }
    } catch (e) {
      AppLogger.candidateError('Error parsing media data: $e');
      mediaItems = [];
    }

    return mediaItems;
  }

  /// Convert legacy Media format to grouped MediaItem format
  static List<MediaItem> _convertLegacyFormat(List<dynamic> media) {
    final Map<String, List<Media>> groupedMedia = {};

    for (final item in media) {
      final mediaObj = item as Media;
      final title = mediaObj.title ?? 'Untitled';
      final date = mediaObj.uploadedAt ?? DateTime.now().toIso8601String().split('T')[0];
      final groupKey = '$title|$date';

      if (!groupedMedia.containsKey(groupKey)) {
        groupedMedia[groupKey] = [];
      }
      groupedMedia[groupKey]!.add(mediaObj);
    }

    // Convert grouped Media objects to MediaItem objects
    final List<MediaItem> mediaItems = [];
    for (final entry in groupedMedia.entries) {
      final keyParts = entry.key.split('|');
      final title = keyParts[0];
      final date = keyParts[1];

      final List<String> images = [];
      final List<String> videos = [];
      final List<String> youtubeLinks = [];

      for (final mediaObj in entry.value) {
        switch (mediaObj.type) {
          case 'image':
            images.add(mediaObj.url);
            break;
          case 'video':
            videos.add(mediaObj.url);
            break;
          case 'youtube':
            youtubeLinks.add(mediaObj.url);
            break;
        }
      }

      mediaItems.add(
        MediaItem(
          title: title,
          date: date,
          images: images,
          videos: videos,
          youtubeLinks: youtubeLinks,
        ),
      );
    }

    return mediaItems;
  }
}

/// Engagement counter utility for displaying like and comment counts
class EngagementCounter {
  static Widget buildLikeCount(int likeCount) {
    if (likeCount == 0) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.thumb_up, color: Colors.blue, size: 14),
        const SizedBox(width: 4),
        Text(
          '$likeCount',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static Widget buildCommentCount(int commentCount) {
    if (commentCount == 0) return const SizedBox.shrink();
    
    return Text(
      '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static Widget buildEngagementSummary(int likeCount, int commentCount) {
    if (likeCount == 0 && commentCount == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (likeCount > 0) ...[
            buildLikeCount(likeCount),
            if (commentCount > 0) ...[
              const SizedBox(width: 16),
            ],
          ],
          if (commentCount > 0) ...[
            buildCommentCount(commentCount),
          ],
        ],
      ),
    );
  }
}
