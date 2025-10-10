import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../models/highlight_model.dart';

class HighlightRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get active highlights for a specific district/body/ward combination
  Future<List<Highlight>> getActiveHighlights(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Create composite location key for precise targeting
      final locationKey = '${districtId}_${bodyId}_$wardId';
      AppLogger.common('🎠 HighlightRepository: Fetching highlights for locationKey: $locationKey');

      final snapshot = await _firestore
          .collection('highlights')
          .where('locationKey', isEqualTo: locationKey)
          .where('active', isEqualTo: true)
          .orderBy('lastShown', descending: false)
          .orderBy('priority', descending: true)
          .limit(10)
          .get();

      AppLogger.common('🎠 HighlightRepository: Found ${snapshot.docs.length} highlights for $locationKey');
      final highlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      if (highlights.isNotEmpty) {
        AppLogger.common('🎠 HighlightRepository: First highlight - ID: ${highlights.first.id}, Candidate: ${highlights.first.candidateName}');
      }

      return highlights;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error fetching highlights', error: e);
      return [];
    }
  }

  // Get platinum banner for a specific district/body/ward combination
  Future<Highlight?> getPlatinumBanner(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Create composite location key for precise targeting
      final locationKey = '${districtId}_${bodyId}_$wardId';
      AppLogger.common('🏷️ HighlightRepository: Fetching platinum banner for locationKey: $locationKey');

      final snapshot = await _firestore
          .collection('highlights')
          .where('locationKey', isEqualTo: locationKey)
          .where('active', isEqualTo: true)
          .where('placement', arrayContains: 'top_banner')
          .orderBy('priority', descending: true)
          .limit(1)
          .get();

      AppLogger.common('🏷️ HighlightRepository: Found ${snapshot.docs.length} platinum banners for $locationKey');

      if (snapshot.docs.isNotEmpty) {
        final banner = Highlight.fromJson(snapshot.docs.first.data());
        AppLogger.common('🏷️ HighlightRepository: Platinum banner - ID: ${banner.id}, Candidate: ${banner.candidateName}');
        return banner;
      }

      AppLogger.common('🏷️ HighlightRepository: No platinum banner found for $locationKey');
      return null;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error fetching platinum banner', error: e);
      return null;
    }
  }

  // Track impression (view)
  Future<void> trackImpression(String highlightId) async {
    try {
      await _firestore
          .collection('highlights')
          .doc(highlightId)
          .update({
            'views': FieldValue.increment(1),
            'lastShown': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error tracking impression', error: e);
    }
  }

  // Track click
  Future<void> trackClick(String highlightId) async {
    try {
      await _firestore
          .collection('highlights')
          .doc(highlightId)
          .update({'clicks': FieldValue.increment(1)});
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error tracking click', error: e);
    }
  }

  // Create new highlight
  Future<String?> createHighlight(Highlight highlight) async {
    try {
      await _firestore
          .collection('highlights')
          .doc(highlight.id)
          .set(highlight.toJson());

      return highlight.id;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error creating highlight', error: e);
      return null;
    }
  }

  // Get push feed items for ward
  Future<List<PushFeedItem>> getPushFeed(
    String wardId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('pushFeed')
          .where('wardId', isEqualTo: wardId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PushFeedItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error fetching push feed', error: e);
      return [];
    }
  }

  // Create push feed item
  Future<String?> createPushFeedItem(PushFeedItem feedItem) async {
    try {
      await _firestore
          .collection('pushFeed')
          .doc(feedItem.id)
          .set(feedItem.toJson());

      return feedItem.id;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error creating push feed item', error: e);
      return null;
    }
  }

  // Update highlight status
  Future<void> updateHighlightStatus(
    String highlightId,
    bool active,
  ) async {
    try {
      await _firestore
          .collection('highlights')
          .doc(highlightId)
          .update({'active': active});
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error updating highlight status', error: e);
    }
  }

  // Get highlights by candidate
  Future<List<Highlight>> getHighlightsByCandidate(
    String candidateId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('highlights')
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error fetching candidate highlights', error: e);
      return [];
    }
  }

  // Update existing highlight with enhanced configuration
  Future<bool> updateHighlightConfig({
    required String highlightId,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    String? customMessage,
    bool? showAnalytics,
  }) async {
    try {
      AppLogger.common('🔄 HighlightRepository: Updating highlight config for $highlightId');

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
        await _firestore
            .collection('highlights')
            .doc(highlightId)
            .update(updates);

        AppLogger.common('✅ HighlightRepository: Updated highlight $highlightId with ${updates.length} changes');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error updating highlight config', error: e);
      return false;
    }
  }

  // Get highlight configuration for editing
  Future<Map<String, dynamic>?> getHighlightConfig(String highlightId) async {
    try {
      final doc = await _firestore
          .collection('highlights')
          .doc(highlightId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error getting highlight config', error: e);
      return null;
    }
  }

  // Track carousel view for analytics
  Future<void> trackCarouselView({
    required String sectionType,
    required String contentId,
    required String userId,
    required String candidateId,
  }) async {
    try {
      await _firestore.collection('section_views').add({
        'sectionType': sectionType,
        'contentId': contentId,
        'userId': userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
      });
    } catch (e) {
      AppLogger.commonError('❌ HighlightRepository: Error tracking carousel view', error: e);
    }
  }

  // Helper method to convert priority level to numeric value
  int _getPriorityValue(String priorityLevel) {
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
