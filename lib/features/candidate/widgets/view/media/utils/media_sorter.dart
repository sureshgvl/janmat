/// Utility class for sorting media items
import 'package:janmat/features/candidate/models/media_model.dart';

class MediaSorter {
  MediaSorter._();

  /// Sort media items by date (most recent first)
  static List<MediaItem> sortByDateMostRecentFirst(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
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

  /// Sort media items by date (oldest first)
  static List<MediaItem> sortByDateOldestFirst(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
    sortedItems.sort((a, b) {
      if (a.date.isEmpty) return 1;
      if (b.date.isEmpty) return -1;

      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateA.compareTo(dateB); // Oldest first
      } catch (e) {
        return 0;
      }
    });

    return sortedItems;
  }

  /// Sort media items by title (alphabetically)
  static List<MediaItem> sortByTitleAlphabetical(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
    sortedItems.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return sortedItems;
  }

  /// Sort media items by number of likes (most liked first)
  static List<MediaItem> sortByMostLiked(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
    sortedItems.sort((a, b) {
      return b.likeCount.compareTo(a.likeCount);
    });

    return sortedItems;
  }

  /// Sort media items by number of comments (most commented first)
  static List<MediaItem> sortByMostCommented(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
    sortedItems.sort((a, b) {
      return b.commentCount.compareTo(a.commentCount);
    });

    return sortedItems;
  }

  /// Sort media items by media type (images, videos, youtube links)
  static List<MediaItem> sortByMediaType(List<MediaItem> mediaItems) {
    final sortedItems = List<MediaItem>.from(mediaItems);
    
    sortedItems.sort((a, b) {
      // Define priority order: images > videos > youtube links
      int getMediaTypePriority(MediaItem item) {
        if (item.images.isNotEmpty) return 0;
        if (item.videos.isNotEmpty) return 1;
        if (item.youtubeLinks.isNotEmpty) return 2;
        return 3;
      }

      return getMediaTypePriority(a).compareTo(getMediaTypePriority(b));
    });

    return sortedItems;
  }

  /// Group media items by year-month
  static Map<String, List<MediaItem>> groupByYearMonth(List<MediaItem> mediaItems) {
    final grouped = <String, List<MediaItem>>{};
    
    for (final item in mediaItems) {
      try {
        final date = DateTime.parse(item.date);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(item);
      } catch (e) {
        // Add to "Unknown" group if date parsing fails
        if (!grouped.containsKey('Unknown')) {
          grouped['Unknown'] = [];
        }
        grouped['Unknown']!.add(item);
      }
    }

    return grouped;
  }
}
