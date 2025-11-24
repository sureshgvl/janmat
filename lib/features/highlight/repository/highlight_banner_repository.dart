import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlight_model.dart';
import '../../../models/push_feed_model.dart';

class HighlightBannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get active highlights for a specific district/body/ward combination
  Future<List<Highlight>> getActiveHighlights(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Use hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights
      AppLogger.common(
        '🎠 HighlightRepository: Fetching highlights for ward: $districtId/$bodyId/$wardId',
      );
      AppLogger.common(
        '🔍 Query: active=true, ordered by lastShown ASC, priority DESC, limit=10',
      );

      final snapshot = await _firestore
          .collection('states')
          .doc('maharashtra') // TODO: Make dynamic based on user location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .where('active', isEqualTo: true)
          .orderBy('lastShown', descending: false)
          .orderBy('priority', descending: true)
          .limit(10)
          .get();

      AppLogger.common(
        '🎠 HighlightRepository: Found ${snapshot.docs.length} highlights for $districtId/$bodyId/$wardId',
      );
      final highlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      if (highlights.isNotEmpty) {
        AppLogger.common(
          '🎠 HighlightRepository: First highlight - ID: ${highlights.first.id}, Candidate: ${highlights.first.candidateName}',
        );
        AppLogger.common('📊 Highlights summary:');
        for (var i = 0; i < highlights.length; i++) {
          final h = highlights[i];
          AppLogger.common(
            '   ${i + 1}. ${h.candidateName} (${h.id}) - Priority: ${h.priority}, Placement: ${h.placement}',
          );
        }
      } else {
        AppLogger.common(
          '🎠 HighlightRepository: No active highlights found for $districtId/$bodyId/$wardId',
        );
      }

      return highlights;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error fetching highlights',
        error: e,
      );
      return [];
    }
  }

  // Get highlight banners for a specific state/district/body/ward combination (returns list for rotation)
  static Future<List<Highlight>> getHighlightBanners({
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Use hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights
        AppLogger.common(
          '🏷️ HighlightRepository: Fetching platinum banner for ward: $districtId/$bodyId/$wardId',
        );
        AppLogger.common(
          '🔍 Query: active=true AND placement contains "top_banner"',
        );

        final now = DateTime.now();
        final snapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc(stateId)
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('highlights')
            .where('active', isEqualTo: true)
            .where('placement', arrayContains: 'top_banner')
            .orderBy('priority', descending: true)
            .limit(4) // Max 4 banners, rotate every 3 seconds
            .get();

        AppLogger.common(
          '🏷️ HighlightRepository: Found ${snapshot.docs.length} potential banners, filtering by expiry...',
        );

        // Filter expired highlights manually (simpler than complex query)
        final validBanners = snapshot.docs
            .map((doc) => Highlight.fromJson(doc.data()))
            .where((highlight) => highlight.endDate.isAfter(now))
            .toList();

        AppLogger.common(
          '🏷️ HighlightRepository: Found ${validBanners.length} active premium banners after expiry filter',
        );

        if (validBanners.isNotEmpty) {
          AppLogger.common(
            '🏷️ HighlightRepository: Returning ${validBanners.length} banners for rotation',
          );
          for (var i = 0; i < validBanners.length; i++) {
            final banner = validBanners[i];
            AppLogger.common(
              '   Banner ${i + 1}: ID: ${banner.id}, Candidate: ${banner.candidateName}',
            );
          }
          return validBanners;
        }

        AppLogger.common(
          '🏷️ HighlightRepository: No premium platinum banners found for $districtId/$bodyId/$wardId',
        );
        return [];
      } catch (e) {
        AppLogger.commonError(
          'Platinum banner fetch attempt $attempt failed',
          tag: 'CANDIDATE',
          error: e,
        );

        if (attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final delay = baseDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
        AppLogger.common(
          'Retrying platinum banner fetch in ${delay.inSeconds}s...',
          tag: 'CANDIDATE',
        );
        await Future.delayed(delay);
      }
    }

    throw Exception(
      'Failed to fetch platinum banner after $maxRetries attempts',
    );
  }

  // Track impression (view)
  Future<void> trackImpression(String highlightId) async {
    try {
      await _firestore.collection('highlights').doc(highlightId).update({
        'views': FieldValue.increment(1),
        'lastShown': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error tracking impression',
        error: e,
      );
    }
  }

  // Track click
  Future<void> trackClick(
    String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        await _firestore
            .collection('states')
            .doc('maharashtra') // TODO: Make dynamic
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('highlights')
            .doc(highlightId)
            .update({'clicks': FieldValue.increment(1)});
      } else {
        // Fallback: try to find in old structure (for backward compatibility)
        await _firestore.collection('highlights').doc(highlightId).update({
          'clicks': FieldValue.increment(1),
        });
      }
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error tracking click',
        error: e,
      );
    }
  }

  // Create new highlight
  Future<String?> createHighlight(Highlight highlight) async {
    try {
      AppLogger.common(
        '💾 HighlightRepository: Creating highlight ${highlight.id}',
      );
      AppLogger.common(
        '📍 Location: ${highlight.districtId}/${highlight.bodyId}/${highlight.wardId}',
      );
      AppLogger.common(
        '👤 Candidate: ${highlight.candidateName} (${highlight.candidateId})',
      );
      AppLogger.common(
        '📦 Package: ${highlight.package}, Placement: ${highlight.placement}',
      );
      AppLogger.common(
        '🔥 Active: ${highlight.active}, Priority: ${highlight.priority}',
      );

      // Save to hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights/{highlightId}
      final path =
          'states/maharashtra/districts/${highlight.districtId}/bodies/${highlight.bodyId}/wards/${highlight.wardId}/highlights/${highlight.id}';
      AppLogger.common('🔗 Firestore path: $path');

      await _firestore
          .collection('states')
          .doc('maharashtra') // TODO: Make dynamic based on user location
          .collection('districts')
          .doc(highlight.districtId)
          .collection('bodies')
          .doc(highlight.bodyId)
          .collection('wards')
          .doc(highlight.wardId)
          .collection('highlights')
          .doc(highlight.id)
          .set(highlight.toJson());

      AppLogger.common(
        '✅ HighlightRepository: Successfully created highlight ${highlight.id}',
      );
      return highlight.id;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error creating highlight',
        error: e,
      );
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
      AppLogger.commonError(
        '❌ HighlightRepository: Error fetching push feed',
        error: e,
      );
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
      AppLogger.commonError(
        '❌ HighlightRepository: Error creating push feed item',
        error: e,
      );
      return null;
    }
  }

  // Update highlight status
  Future<void> updateHighlightStatus(
    String highlightId,
    bool active, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        await _firestore
            .collection('states')
            .doc('maharashtra') // TODO: Make dynamic
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('highlights')
            .doc(highlightId)
            .update({'active': active});
      } else {
        // Fallback: try to find in old structure (for backward compatibility)
        await _firestore.collection('highlights').doc(highlightId).update({
          'active': active,
        });
      }
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error updating highlight status',
        error: e,
      );
    }
  }

  // Get highlights by candidate
  Future<List<Highlight>> getHighlightsByCandidate(String candidateId) async {
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
      AppLogger.commonError(
        '❌ HighlightRepository: Error fetching candidate highlights',
        error: e,
      );
      return [];
    }
  }

  // Update existing highlight with enhanced configuration
  Future<bool> updateHighlightConfig({
    required String highlightId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    String? customMessage,
    bool? showAnalytics,
  }) async {
    try {
      AppLogger.common(
        '🔄 HighlightRepository: Updating highlight config for $highlightId',
      );

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
        // If location info is provided, use hierarchical path
        if (districtId != null && bodyId != null && wardId != null) {
          await _firestore
              .collection('states')
              .doc('maharashtra') // TODO: Make dynamic
              .collection('districts')
              .doc(districtId)
              .collection('bodies')
              .doc(bodyId)
              .collection('wards')
              .doc(wardId)
              .collection('highlights')
              .doc(highlightId)
              .update(updates);
        } else {
          // Fallback: try to find in old structure (for backward compatibility)
          await _firestore
              .collection('highlights')
              .doc(highlightId)
              .update(updates);
        }

        AppLogger.common(
          '✅ HighlightRepository: Updated highlight $highlightId with ${updates.length} changes',
        );
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error updating highlight config',
        error: e,
      );
      return false;
    }
  }

  // Update entire highlight document
  Future<bool> updateHighlight(Highlight highlight) async {
    try {
      AppLogger.common(
        '🔄 HighlightRepository: Updating entire highlight ${highlight.id}',
      );
      AppLogger.common(
        '📍 Location: ${highlight.districtId}/${highlight.bodyId}/${highlight.wardId}',
      );
      AppLogger.common(
        '👤 Candidate: ${highlight.candidateName} (${highlight.candidateId})',
      );

      // Add enhanced metadata for Platinum features
      final enhancedData = highlight.toJson();
      // These would be passed in the highlight object if needed
      // enhancedData['bannerStyle'] = bannerStyle;
      // enhancedData['callToAction'] = callToAction;
      // enhancedData['priorityLevel'] = priorityLevel;
      // enhancedData['customMessage'] = customMessage;

      // Update in hierarchical structure
      await _firestore
          .collection('states')
          .doc('maharashtra') // TODO: Make dynamic based on user location
          .collection('districts')
          .doc(highlight.districtId)
          .collection('bodies')
          .doc(highlight.bodyId)
          .collection('wards')
          .doc(highlight.wardId)
          .collection('highlights')
          .doc(highlight.id)
          .set(
            enhancedData,
            SetOptions(merge: true),
          ); // Use merge to update existing

      AppLogger.common(
        '✅ HighlightRepository: Successfully updated highlight ${highlight.id}',
      );
      return true;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error updating highlight',
        error: e,
      );
      return false;
    }
  }

  // Get highlight configuration for editing
  Future<Map<String, dynamic>?> getHighlightConfig(
    String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        final doc = await _firestore
            .collection('states')
            .doc('maharashtra') // TODO: Make dynamic
            .collection('districts')
            .doc(districtId)
            .collection('bodies')
            .doc(bodyId)
            .collection('wards')
            .doc(wardId)
            .collection('highlights')
            .doc(highlightId)
            .get();

        if (doc.exists) {
          return doc.data();
        }
      } else {
        // Fallback: try to find in old structure (for backward compatibility)
        final doc = await _firestore
            .collection('highlights')
            .doc(highlightId)
            .get();

        if (doc.exists) {
          return doc.data();
        }
      }
      return null;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightRepository: Error getting highlight config',
        error: e,
      );
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
      AppLogger.commonError(
        '❌ HighlightRepository: Error tracking carousel view',
        error: e,
      );
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
