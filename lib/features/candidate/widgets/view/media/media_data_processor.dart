import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';

/// Handles all media data processing responsibilities
/// Following Single Responsibility Principle - only handles data parsing and transformation
class MediaDataProcessor {
  /// Process raw media data from candidate and return sorted MediaItem list
  List<MediaItem> processMediaData(Candidate candidate) {
    List<MediaItem> mediaItems = _parseMediaData(candidate);
    return _sortMediaItems(mediaItems);
  }

  /// Parse raw media data into MediaItem objects
  List<MediaItem> _parseMediaData(Candidate candidate) {
    List<MediaItem> mediaItems = [];

    try {
      final media = candidate.media;

      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Starting media data parsing for candidate: ${candidate.candidateId}');
      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Raw media data type: ${media?.runtimeType}');
      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Raw media data length: ${media?.length ?? "null"}');
      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Raw media data: $media');

      // Check if media is null or empty
      if (media == null || media.isEmpty) {
        AppLogger.candidate('📱 [MEDIA_PROCESSOR] Media is null or empty, returning empty list');
        return [];
      }

      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Media type: ${media.first.runtimeType}');
      AppLogger.candidate('📱 [MEDIA_PROCESSOR] Media length: ${media.length}');

      // Filter out items with invalid blob URLs (temporary fix for corrupted data)
      final validMedia = media.where((item) {
        if (item is Map<String, dynamic>) {
          final images = item['images'] as List<dynamic>? ?? [];
          final hasBlobUrls = images.any((url) => url.toString().startsWith('blob:'));
          if (hasBlobUrls) {
            AppLogger.candidate('⚠️ [MEDIA_PROCESSOR] Filtering out item with blob URLs: ${item['title']}');
            return false;
          }
        }
        return true;
      }).toList();

      AppLogger.candidate('📱 [MEDIA_PROCESSOR] After blob URL filtering: ${validMedia.length} valid items');

      if (validMedia.first is Map<String, dynamic>) {
        // New grouped format - each item is already a MediaItem map
        final List<dynamic> mediaList = validMedia;
        final validItems = mediaList.whereType<Map<String, dynamic>>();

        AppLogger.candidate('📱 [MEDIA_PROCESSOR] Found ${validItems.length} valid map items');

        mediaItems = validItems
            .map((item) {
              try {
                AppLogger.candidate('📱 [MEDIA_PROCESSOR] Processing item: ${item['title']}');
                final parsedItem = MediaItem.fromJson(item);
                AppLogger.candidate('✅ [MEDIA_PROCESSOR] Successfully parsed item: "${parsedItem.title}" with ${parsedItem.images.length} images, ${parsedItem.videos.length} videos, ${parsedItem.youtubeLinks.length} youtube links');

                return parsedItem;
              } catch (e) {
                AppLogger.candidateError(
                  '❌ [MEDIA_PROCESSOR] Error parsing media item "${item['title'] ?? 'unknown'}": $e',
                );
                return null;
              }
            })
            .whereType<MediaItem>()
            .toList();

        AppLogger.candidate('📱 [MEDIA_PROCESSOR] Successfully parsed ${mediaItems.length} valid media items');

        AppLogger.candidate('📱 [MEDIA_PROCESSOR] Final result: ${mediaItems.length} items after filtering');
      } else if (validMedia.first is Media) {
        // Old format - individual Media objects need to be converted to grouped format
        mediaItems = _convertLegacyFormat(validMedia);
      }
    } catch (e) {
      AppLogger.candidateError('Error parsing media data: $e');
      return [];
    }

    return mediaItems;
  }

  /// Convert legacy Media format to modern grouped MediaItem format
  List<MediaItem> _convertLegacyFormat(List<dynamic> media) {
    final Map<String, List<Media>> groupedMedia = {};

    // Group Media objects by title and date
    for (final item in media) {
      final mediaObj = item as Media;
      final title = mediaObj.title ?? 'Untitled';
      final date = mediaObj.uploadedAt ??
          DateTime.now().toIso8601String().split('T')[0];
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

      final mediaItem = MediaItem(
        title: title,
        date: date,
        images: images,
        videos: videos,
        youtubeLinks: youtubeLinks,
      );

      return mediaItem;
    }).whereType<MediaItem>().toList();
  }

  /// Sort media items by date (most recent first)
  List<MediaItem> _sortMediaItems(List<MediaItem> mediaItems) {
    mediaItems.sort((a, b) {
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

    return mediaItems;
  }

  /// Get media items count for display purposes
  int getMediaItemsCount(Candidate candidate) {
    try {
      final media = candidate.media;
      if (media == null || media.isEmpty) return 0;

      if (media.first is Map<String, dynamic>) {
        // New format - count valid MediaItems (applying same blob URL filtering as main parser)
        final validItems = media
            .whereType<Map<String, dynamic>>()
            .where((item) {
              // Apply same blob URL filtering as _parseMediaData
              final images = item['images'] as List<dynamic>? ?? [];
              final hasBlobUrls = images.any((url) => url.toString().startsWith('blob:'));
              if (hasBlobUrls) {
                return false; // Filter out corrupted items
              }

              // Check if item can be parsed
              try {
                MediaItem.fromJson(item);
                return true;
              } catch (e) {
                AppLogger.candidateError('Error parsing media item in count: $e');
                return false;
              }
            });

        AppLogger.candidate('📊 [MEDIA_COUNT] Raw items: ${media.length}, Valid items after filtering: ${validItems.length}');
        return validItems.length;
      } else if (media.first is Media) {
        // Legacy format - group by unique date-title combinations
        final grouped = <String>{};
        for (final item in media) {
          final mediaObj = item as Media;
          final title = mediaObj.title ?? 'Untitled';
          final date = mediaObj.uploadedAt ??
              DateTime.now().toIso8601String().split('T')[0];
          grouped.add('$title|$date');
        }
        return grouped.length;
      }
    } catch (e) {
      AppLogger.candidateError('Error counting media items: $e');
    }
    return 0;
  }

  /// Validate if candidate has valid media data
  bool hasValidMediaData(Candidate candidate) {
    try {
      final media = candidate.media;
      if (media == null || media.isEmpty) return false;
      
      if (media.first is Map<String, dynamic>) {
        // New format validation
        return media.any((item) {
          if (item is Map<String, dynamic>) {
            try {
              final mediaItem = MediaItem.fromJson(item);
              return mediaItem.images.isNotEmpty || 
                     mediaItem.videos.isNotEmpty || 
                     mediaItem.youtubeLinks.isNotEmpty;
            } catch (e) {
              return false;
            }
          }
          return false;
        });
      } else if (media.first is Media) {
        // Legacy format validation
        return media.any((item) {
          final mediaObj = item as Media;
          return mediaObj.url.isNotEmpty;
        });
      }
    } catch (e) {
      AppLogger.candidateError('Error validating media data: $e');
    }
    return false;
  }
}
