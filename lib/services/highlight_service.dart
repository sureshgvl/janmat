import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class Highlight {
  final String id;
  final String candidateId;
  final String wardId;
  final String districtId;
  final String bodyId; // Added for hierarchical targeting
  final String locationKey; // Composite key: district_body_ward
  final String package;
  final List<String> placement;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final bool exclusive;
  final bool rotation;
  final DateTime? lastShown;
  final int views;
  final int clicks;
  final String? imageUrl;
  final String? candidateName;
  final String? party;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.candidateId,
    required this.wardId,
    required this.districtId,
    required this.bodyId,
    required this.locationKey,
    required this.package,
    required this.placement,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.exclusive,
    required this.rotation,
    this.lastShown,
    required this.views,
    required this.clicks,
    this.imageUrl,
    this.candidateName,
    this.party,
    required this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['highlightId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      wardId: json['wardId'] ?? '',
      districtId: json['districtId'] ?? '',
      bodyId: json['bodyId'] ?? '',
      locationKey: json['locationKey'] ?? '',
      package: json['package'] ?? '',
      placement: List<String>.from(json['placement'] ?? []),
      priority: json['priority'] ?? 1,
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: json['active'] ?? false,
      exclusive: json['exclusive'] ?? false,
      rotation: json['rotation'] ?? true,
      lastShown: (json['lastShown'] as Timestamp?)?.toDate(),
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      imageUrl: json['imageUrl'],
      candidateName: json['candidateName'],
      party: json['party'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': id,
      'candidateId': candidateId,
      'wardId': wardId,
      'districtId': districtId,
      'bodyId': bodyId,
      'locationKey': locationKey,
      'package': package,
      'placement': placement,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'exclusive': exclusive,
      'rotation': rotation,
      'lastShown': lastShown != null ? Timestamp.fromDate(lastShown!) : null,
      'views': views,
      'clicks': clicks,
      'imageUrl': imageUrl,
      'candidateName': candidateName,
      'party': party,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class PushFeedItem {
  final String id;
  final String? highlightId;
  final String candidateId;
  final String wardId;
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isSponsored;

  PushFeedItem({
    required this.id,
    this.highlightId,
    required this.candidateId,
    required this.wardId,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.isSponsored,
  });

  factory PushFeedItem.fromJson(Map<String, dynamic> json) {
    return PushFeedItem(
      id: json['feedId'] ?? '',
      highlightId: json['highlightId'],
      candidateId: json['candidateId'] ?? '',
      wardId: json['wardId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSponsored: json['isSponsored'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedId': id,
      'highlightId': highlightId,
      'candidateId': candidateId,
      'wardId': wardId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSponsored': isSponsored,
    };
  }
}

class HighlightService {
  // Get active highlights for a specific district/body/ward combination
  static Future<List<Highlight>> getActiveHighlights(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Create composite location key for precise targeting
      final locationKey = '${districtId}_${bodyId}_$wardId';
      AppLogger.common('🎠 HighlightService: Fetching highlights for locationKey: $locationKey');

      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('locationKey', isEqualTo: locationKey)
          .where('active', isEqualTo: true)
          .orderBy('lastShown', descending: false)
          .orderBy('priority', descending: true)
          .limit(10)
          .get();

      AppLogger.common('🎠 HighlightService: Found ${snapshot.docs.length} highlights for $locationKey');
      final highlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      if (highlights.isNotEmpty) {
        AppLogger.common('🎠 HighlightService: First highlight - ID: ${highlights.first.id}, Candidate: ${highlights.first.candidateName}');
      }

      return highlights;
    } catch (e) {
      AppLogger.commonError('❌ HighlightService: Error fetching highlights', error: e);
      return [];
    }
  }

  // Get platinum banner for a specific district/body/ward combination
  static Future<Highlight?> getPlatinumBanner(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Create composite location key for precise targeting
      final locationKey = '${districtId}_${bodyId}_$wardId';
      AppLogger.common('🏷️ HighlightService: Fetching platinum banner for locationKey: $locationKey');

      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('locationKey', isEqualTo: locationKey)
          .where('active', isEqualTo: true)
          .where('placement', arrayContains: 'top_banner')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      AppLogger.common('🏷️ HighlightService: Found ${snapshot.docs.length} platinum banners for $locationKey');

      if (snapshot.docs.isNotEmpty) {
        final banner = Highlight.fromJson(snapshot.docs.first.data());
        AppLogger.common('🏷️ HighlightService: Platinum banner - ID: ${banner.id}, Candidate: ${banner.candidateName}');
        return banner;
      }

      AppLogger.common('🏷️ HighlightService: No platinum banner found for $locationKey');
      return null;
    } catch (e) {
      AppLogger.commonError('❌ HighlightService: Error fetching platinum banner', error: e);
      return null;
    }
  }

  // Track impression (view)
  static Future<void> trackImpression(String highlightId) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({
            'views': FieldValue.increment(1),
            'lastShown': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.commonError('Error tracking impression', error: e);
    }
  }

  // Track click
  static Future<void> trackClick(String highlightId) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({'clicks': FieldValue.increment(1)});
    } catch (e) {
      AppLogger.commonError('Error tracking click', error: e);
    }
  }

  // Create new highlight
  static Future<String?> createHighlight({
    required String candidateId,
    required String wardId,
    required String districtId,
    required String bodyId,
    required String package,
    required List<String> placement,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? candidateName,
    String? party,
    bool exclusive = false,
    int priority = 1,
  }) async {
    try {
      final highlightId = 'hl_${DateTime.now().millisecondsSinceEpoch}';
      final locationKey =
          '${districtId}_${bodyId}_$wardId'; // Composite key for precise targeting

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        wardId: wardId,
        districtId: districtId,
        bodyId: bodyId,
        locationKey: locationKey,
        package: package,
        placement: placement,
        priority: priority,
        startDate: startDate,
        endDate: endDate,
        active:
            startDate.isBefore(DateTime.now()) &&
            endDate.isAfter(DateTime.now()),
        exclusive: exclusive,
        rotation: !exclusive,
        views: 0,
        clicks: 0,
        imageUrl: imageUrl,
        candidateName: candidateName,
        party: party,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .set(highlight.toJson());

      return highlightId;
    } catch (e) {
      AppLogger.commonError('Error creating highlight', error: e);
      return null;
    }
  }

  // Get push feed items for ward
  static Future<List<PushFeedItem>> getPushFeed(
    String wardId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pushFeed')
          .where('wardId', isEqualTo: wardId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PushFeedItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.commonError('Error fetching push feed', error: e);
      return [];
    }
  }

  // Create push feed item
  static Future<String?> createPushFeedItem({
    required String candidateId,
    required String wardId,
    required String title,
    required String message,
    String? imageUrl,
    String? highlightId,
  }) async {
    try {
      final feedId = 'feed_${DateTime.now().millisecondsSinceEpoch}';
      final feedItem = PushFeedItem(
        id: feedId,
        highlightId: highlightId,
        candidateId: candidateId,
        wardId: wardId,
        title: title,
        message: message,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        isSponsored: highlightId != null,
      );

      await FirebaseFirestore.instance
          .collection('pushFeed')
          .doc(feedId)
          .set(feedItem.toJson());

      return feedId;
    } catch (e) {
      AppLogger.commonError('Error creating push feed item', error: e);
      return null;
    }
  }

  // Update highlight status
  static Future<void> updateHighlightStatus(
    String highlightId,
    bool active,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .update({'active': active});
    } catch (e) {
      AppLogger.commonError('Error updating highlight status', error: e);
    }
  }

  // Get highlights by candidate
  static Future<List<Highlight>> getHighlightsByCandidate(
    String candidateId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('highlights')
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.commonError('Error fetching candidate highlights', error: e);
      return [];
    }
  }


  // Create Platinum highlight for real candidate
  static Future<String?> createPlatinumHighlight({
    required String candidateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required String candidateName,
    required String party,
    String? imageUrl,
    String bannerStyle = 'premium',
    String callToAction = 'View Profile',
    String priorityLevel = 'normal',
    String? customMessage,
  }) async {
    try {
      AppLogger.common('🏆 HighlightService: Creating Platinum highlight for $candidateName');

      final highlightId = 'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
      final locationKey = '${districtId}_${bodyId}_$wardId';

      // Calculate priority based on level
      int priorityValue = _getPriorityValue(priorityLevel);

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        wardId: wardId,
        districtId: districtId,
        bodyId: bodyId,
        locationKey: locationKey,
        package: 'platinum', // Platinum package
        placement: ['carousel', 'top_banner'], // Show in both carousel and banner
        priority: priorityValue,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 365)), // 1 year validity
        active: true,
        exclusive: priorityLevel == 'urgent', // Urgent gets exclusive placement
        rotation: priorityLevel != 'urgent', // Don't rotate urgent items
        views: 0,
        clicks: 0,
        imageUrl: imageUrl,
        candidateName: candidateName,
        party: party,
        createdAt: DateTime.now(),
      );

      // Add enhanced metadata for Platinum features
      final enhancedData = highlight.toJson();
      enhancedData['bannerStyle'] = bannerStyle;
      enhancedData['callToAction'] = callToAction;
      enhancedData['priorityLevel'] = priorityLevel;
      enhancedData['customMessage'] = customMessage;

      await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .set(enhancedData);

      AppLogger.common('✅ HighlightService: Created Platinum highlight $highlightId for $candidateName');
      AppLogger.common('   Location: $locationKey, Style: $bannerStyle, Priority: $priorityLevel ($priorityValue)');
      return highlightId;
    } catch (e) {
      AppLogger.commonError('❌ HighlightService: Error creating Platinum highlight', error: e);
      return null;
    }
  }

  // Update existing highlight with enhanced configuration
  static Future<bool> updateHighlightConfig({
    required String highlightId,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    String? customMessage,
    bool? showAnalytics,
  }) async {
    try {
      AppLogger.common('🔄 HighlightService: Updating highlight config for $highlightId');

      final updates = <String, dynamic>{};
      if (bannerStyle != null) updates['bannerStyle'] = bannerStyle;
      if (callToAction != null) updates['callToAction'] = callToAction;
      if (priorityLevel != null) {
        updates['priorityLevel'] = priorityLevel;
        updates['priority'] = _getPriorityValue(priorityLevel);
        updates['exclusive'] = priorityLevel == 'urgent';
        updates['rotation'] = priorityLevel != 'urgent';
      }
      if (customMessage != null) updates['customMessage'] = customMessage;
      if (showAnalytics != null) updates['showAnalytics'] = showAnalytics;

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .update(updates);

        AppLogger.common('✅ HighlightService: Updated highlight $highlightId with ${updates.length} changes');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.commonError('❌ HighlightService: Error updating highlight config', error: e);
      return false;
    }
  }

  // Get highlight configuration for editing
  static Future<Map<String, dynamic>?> getHighlightConfig(String highlightId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('highlights')
          .doc(highlightId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      AppLogger.commonError('❌ HighlightService: Error getting highlight config', error: e);
      return null;
    }
  }

  // Helper method to convert priority level to numeric value
  static int _getPriorityValue(String priorityLevel) {
    switch (priorityLevel) {
      case 'normal':
        return 5;
      case 'high':
        return 8;
      case 'urgent':
        return 10;
      default:
        return 5;
    }
  }
}
