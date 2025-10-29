import 'dart:convert';

void main() {
  // Simulate the Firebase data structure you provided
  final firebaseMediaData = [
    {
      "added_date": null,
      "date": "2025-10-28",
      "images": [
        "https://firebasestorage.googleapis.com/v0/b/janmat-8e831.firebasestorage.app/o/manifesto_files%2Fmedia_image_kbiM3lVHdeskjBjRTlp0_1761657801653?alt=media&token=146e792b-c123-4981-b5e2-5b5d12cc5fdc",
        "https://firebasestorage.googleapis.com/v0/b/janmat-8e831.firebasestorage.app/o/manifesto_files%2Fmedia_image_kbiM3lVHdeskjBjRTlp0_1761657801838?alt=media&token=113cb85d-06a6-4b06-83ef-bb0ad20f82b5",
        "https://firebasestorage.googleapis.com/v0/b/janmat-8e831.firebasestorage.app/o/manifesto_files%2Fmedia_image_kbiM3lVHdeskjBjRTlp0_1761657801951?alt=media&token=53eca3b7-6197-45e1-891f-d67860dd825d"
      ],
      "likes": {
        "title": "Rally in Hadapsar"
      },
      "videos": [],
      "youtubeLinks": null
    }
  ];

  print('Firebase media data structure:');
  print(jsonEncode(firebaseMediaData[0]));

  // Test MediaItem.fromJson directly
  print('\nTesting MediaItem.fromJson with Firebase data...');
  final jsonData = firebaseMediaData[0] as Map<String, dynamic>;
  print('Title in JSON: "${jsonData['title'] ?? 'NOT FOUND'}"');
  print('Likes in JSON: ${jsonData['likes']}');
  print('Likes type: ${jsonData['likes'].runtimeType}');

  try {
    final mediaItem = MediaItem.fromJson(jsonData);
    print('✅ MediaItem.fromJson SUCCESS!');
    print('Title extracted: "${mediaItem.title}"');
    print('Likes map: ${mediaItem.likes}');
    print('Images count: ${mediaItem.images.length}');
  } catch (e) {
    print('❌ MediaItem.fromJson FAILED: $e');
  }

  // Test updated Candidate._parseMediaData (modified to return raw data)
  print('\nTesting updated Candidate._parseMediaData...');
  final rawMediaData = _parseMediaDataUpdated(firebaseMediaData);
  print('Raw data: ${rawMediaData?.length} items');

  // Check how MediaTabView._getMediaItems would handle raw data
  print('\nTesting MediaTabView._getMediaItems with raw data...');
  final mediaItems = _simulateGetMediaItemsWithRawData(rawMediaData);
  print('Created ${mediaItems.length} MediaItem objects');

  if (mediaItems.isNotEmpty) {
    print('✅ SUCCESS: MediaItem objects created!');
    final item = mediaItems.first;
    print('Title: "${item.title}"');
    print('Date: "${item.date}"');
    print('Images: ${item.images.length}');
    print('Videos: ${item.videos.length}');
    print('YouTube links: ${item.youtubeLinks.length}');
  }
}

// Updated Candidate._parseMediaData (no conversion to Media objects)
List<dynamic>? _parseMediaDataUpdated(dynamic mediaData) {
  if (mediaData == null) return null;
  if (mediaData is! List) return null;
  final List<dynamic> mediaList = List<dynamic>.from(mediaData);
  return mediaList.isEmpty ? [] : mediaList;
}

// Simulate MediaTabView._getMediaItems with raw data
List<MediaItem> _simulateGetMediaItemsWithRawData(List<dynamic>? media) {
  List<MediaItem> mediaItems = [];

  if (media != null && media.isNotEmpty) {
    // Check the first item to determine format
    final firstItem = media.first;
    print('First item type: ${firstItem.runtimeType}');

    if (firstItem is Map<String, dynamic>) {
      print('✅ Detected grouped format (raw Firebase data)');
      final List<dynamic> mediaList = media;
      final validItems = mediaList.whereType<Map<String, dynamic>>();
      print('Found ${validItems.length} map items');

      // Create MediaItem objects from raw data
      mediaItems = validItems.map((item) => MediaItem.fromJson(item)).toList();
      print('Created ${mediaItems.length} MediaItem objects');
    } else {
      print('❌ Unexpected media item format: ${firstItem.runtimeType}');
    }
  }

  return mediaItems;
}

// Copied from candidate_model.dart
List<Media>? _parseMediaData(dynamic mediaData) {
  if (mediaData == null) return null;

  if (mediaData is! List) return null;

  final List<dynamic> mediaList = mediaData;
  if (mediaList.isEmpty) return [];

  final parsedMedia = <Media>[];

  for (final item in mediaList) {
    if (item is! Map<String, dynamic>) continue;

    final Map<String, dynamic> itemMap = item;

    // Check if this is grouped format (has title, date, images/videos arrays)
    if (_isGroupedFormat(itemMap)) {
      // Convert grouped format to individual Media objects
      final title = itemMap['title'] ?? 'Untitled';
      final date = itemMap['date'] ?? DateTime.now().toIso8601String().split('T')[0];

      final images = List<String>.from(itemMap['images'] ?? []);
      final videos = List<String>.from(itemMap['videos'] ?? []);
      final youtubeLinks = List<String>.from(itemMap['youtubeLinks'] ?? []);

      for (final imageUrl in images) {
        parsedMedia.add(Media(
          url: imageUrl,
          caption: '$title - $date',
          title: title,
          type: 'image',
          uploadedAt: date,
        ));
      }

      for (final videoUrl in videos) {
        parsedMedia.add(Media(
          url: videoUrl,
          caption: '$title - $date',
          title: title,
          type: 'video',
          uploadedAt: date,
        ));
      }

      for (final youtubeUrl in youtubeLinks) {
        parsedMedia.add(Media(
          url: youtubeUrl,
          caption: '$title - $date',
          title: title,
          type: 'youtube',
          uploadedAt: date,
        ));
      }
    } else {
      // This is individual format - try to parse as Media object
      try {
        // parsedMedia.add(Media.fromJson(itemMap));
        print('Would parse as individual Media object');
      } catch (e) {
        print('❌ Failed to parse individual media item: $e, skipping');
      }
    }
  }

  return parsedMedia;
}

// Check if media item is in grouped format (MediaItem JSON)
bool _isGroupedFormat(Map<String, dynamic> itemMap) {
  // Grouped format has these keys with array values
  return itemMap.containsKey('title') &&
         (itemMap.containsKey('images') || itemMap.containsKey('videos') || itemMap.containsKey('youtubeLinks'));
}

// Simulate MediaTabView._getMediaItems logic with individual Media objects
List<MediaItem> _simulateGetMediaItems(List<Media>? media) {
  List<MediaItem> mediaItems = [];

  if (media != null && media.isNotEmpty) {
    // Check the first item to determine format
    final firstItem = media.first;
    print('First item type: ${firstItem.runtimeType}');

    if (firstItem is Map<String, dynamic>) {
      print('Detected grouped format');
      // This would parse as grouped format
      final List<dynamic> mediaList = media;
      final validItems = mediaList.whereType<Map<String, dynamic>>();
      print('Found ${validItems.length} map items');

      // This would create MediaItem objects
      mediaItems = validItems.map((item) => MediaItem.fromJson(item)).toList();
    } else if (firstItem is Media) {
      print('Detected individual Media format - would convert to grouped');
      // Convert individual Media objects to grouped format
      final Map<String, List<Media>> groupedMedia = {};

      for (final item in media) {
        final mediaObj = item;
        final title = mediaObj.title ?? 'Untitled';
        final date = mediaObj.uploadedAt ?? DateTime.now().toIso8601String().split('T')[0];

        final groupKey = '$title|$date';

        if (!groupedMedia.containsKey(groupKey)) {
          groupedMedia[groupKey] = [];
        }
        groupedMedia[groupKey]!.add(mediaObj);
      }

      print('Grouped into ${groupedMedia.length} groups');

      // Convert grouped Media objects to MediaItem objects
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

        final likes = <String, int>{};
        mediaItems.add(MediaItem(
          title: title,
          date: date,
          images: images,
          videos: videos,
          youtubeLinks: youtubeLinks,
          likes: likes,
        ));
      }
    } else {
      print('❌ Unexpected media item format: ${firstItem.runtimeType}');
    }
  }

  return mediaItems;
}

// Copied Media and MediaItem classes for testing
class Media {
  final String url;
  final String? caption;
  final String? title;
  final String? description;
  final String? duration;
  final String? type;
  final String? uploadedAt;
  final String? addedDate;

  const Media({
    required this.url,
    this.caption,
    this.title,
    this.description,
    this.duration,
    this.type,
    this.uploadedAt,
    this.addedDate,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      url: json['url'],
      caption: json['caption'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      type: json['type'],
      uploadedAt: json['uploaded_at'],
      addedDate: json['added_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'caption': caption,
      'title': title,
      'description': description,
      'duration': duration,
      'type': type,
      'uploaded_at': uploadedAt,
      'added_date': addedDate,
    };
  }
}

class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  Map<String, int> likes;
  String? addedDate;

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    Map<String, int>? likes,
    this.addedDate,
  }) : date = date ?? DateTime.now().toIso8601String().split('T')[0],
       images = images ?? [],
       videos = videos ?? [],
       youtubeLinks = youtubeLinks ?? [],
       likes = likes ?? {};

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    // Handle Firebase format where title might be in likes map
    String title = json['title'] ?? '';
    if (title.isEmpty && json['likes'] is Map && json['likes']['title'] != null) {
      title = json['likes']['title'];
    }

    // Handle likes map - it might contain the title, so we need to extract only integer values
    final rawLikes = json['likes'] ?? {};
    final Map<String, int> likes = {};
    if (rawLikes is Map) {
      rawLikes.forEach((key, value) {
        if (value is int && key != 'title') { // Skip title key
          likes[key] = value;
        }
      });
    }

    return MediaItem(
      title: title,
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      likes: likes,
      addedDate: json['added_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'images': images,
      'videos': videos,
      'youtubeLinks': youtubeLinks,
      'likes': likes,
      'added_date': addedDate,
    };
  }
}
