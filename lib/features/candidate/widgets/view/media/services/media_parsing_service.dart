/// Service class for parsing and converting media data
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';

class MediaParsingService {
  MediaParsingService._();

  /// Parse media data and convert to MediaItem objects
  /// Supports both old format (individual Media objects) and new format (grouped MediaItem maps)
  static List<MediaItem> parseMediaData(dynamic media) {
    List<MediaItem> mediaItems = [];
    
    try {
      // Check if media is null or empty
      if (media == null) {
        return [];
      }

      if (media.isEmpty) {
        return [];
      }

      if (media is! List) {
        return [];
      }

      final List<dynamic> mediaList = media;
      if (mediaList.isEmpty) {
        return [];
      }

      // Check the first item to determine format
      final firstItem = mediaList.first;

      if (firstItem is Map<String, dynamic>) {
        // New grouped format - each item is already a MediaItem map
        final validItems = mediaList.whereType<Map<String, dynamic>>();

        mediaItems = validItems
            .map((item) {
              try {
                final parsedItem = MediaItem.fromJson(item);
                return parsedItem;
              } catch (e) {
                AppLogger.candidateError('Error parsing media item: $e');
                return null;
              }
            })
            .whereType<MediaItem>()
            .toList();
      } else if (firstItem is Media) {
        // Old format - individual Media objects need to be converted to grouped format
        mediaItems = _convertLegacyFormat(mediaList);
      } else {
        AppLogger.candidateError('Unexpected media item format: ${firstItem.runtimeType}');
        mediaItems = [];
      }
    } catch (e) {
      AppLogger.candidateError('Error parsing media data: $e');
      mediaItems = [];
    }

    return mediaItems;
  }

  /// Convert legacy format (individual Media objects) to new grouped format
  static List<MediaItem> _convertLegacyFormat(List<dynamic> mediaList) {
    final Map<String, List<Media>> groupedMedia = {};

    for (final item in mediaList) {
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
    return groupedMedia.entries.map((entry) {
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

      return MediaItem(
        title: title,
        date: date,
        images: images,
        videos: videos,
        youtubeLinks: youtubeLinks,
      );
    }).toList();
  }

  /// Convert MediaItem back to JSON format for storage
  static List<Map<String, dynamic>> convertToJsonFormat(List<MediaItem> mediaItems) {
    return mediaItems.map((item) => item.toJson()).toList();
  }

  /// Extract all media URLs from MediaItem objects
  static List<String> extractAllMediaUrls(List<MediaItem> mediaItems) {
    final allUrls = <String>[];
    
    for (final item in mediaItems) {
      allUrls.addAll(item.images);
      allUrls.addAll(item.videos);
      allUrls.addAll(item.youtubeLinks);
    }
    
    return allUrls;
  }

  /// Get Firebase storage URLs only (exclude local paths and blob URLs)
  static List<String> getFirebaseStorageUrls(List<String> urls) {
    return urls.where((url) => 
        !url.startsWith('blob:') && 
        url.contains('firebasestorage.googleapis.com')
    ).toList();
  }

  /// Validate media item data
  static bool isValidMediaItem(MediaItem item) {
    return item.title.isNotEmpty &&
           item.date.isNotEmpty &&
           (item.images.isNotEmpty || 
            item.videos.isNotEmpty || 
            item.youtubeLinks.isNotEmpty);
  }

  /// Get media summary statistics
  static Map<String, int> getMediaStats(List<MediaItem> mediaItems) {
    int totalImages = 0;
    int totalVideos = 0;
    int totalYoutubeLinks = 0;
    int totalLikes = 0;
    int totalComments = 0;

    for (final item in mediaItems) {
      totalImages += item.images.length;
      totalVideos += item.videos.length;
      totalYoutubeLinks += item.youtubeLinks.length;
      totalLikes += item.likeCount;
      totalComments += item.commentCount;
    }

    return {
      'totalItems': mediaItems.length,
      'totalImages': totalImages,
      'totalVideos': totalVideos,
      'totalYoutubeLinks': totalYoutubeLinks,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
    };
  }
}
