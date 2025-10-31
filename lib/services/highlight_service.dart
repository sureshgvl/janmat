import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../features/highlight/models/highlight_model.dart';
import '../models/push_feed_model.dart';
import '../features/candidate/models/location_model.dart';
import 'highlight_session_service.dart';

class HighlightService {
  static bool isShow = false;

  // Get active highlights for a specific district/body/ward combination
  static Future<List<Highlight>> getActiveHighlights(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Use hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights
      AppLogger.common(
        '🎠 HighlightService: Fetching highlights for ward: $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId) // Use the stateId parameter
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .where('active', isEqualTo: true)
          .limit(20) // Get more to allow sorting in memory
          .get();

      AppLogger.common(
        '🎠 HighlightService: Found ${snapshot.docs.length} potential highlights from query',
        isShow: isShow,
      );

      // Convert to highlight objects and filter expired highlights manually
      final activeHighlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .where((highlight) => highlight.endDate.isAfter(now))
          .toList();

      AppLogger.common(
        '🎠 HighlightService: Found ${activeHighlights.length} active non-expired highlights',
        isShow: isShow,
      );

      // Sort by priority in memory (can't use composite index with orderBy+where)
      activeHighlights.sort((a, b) => b.priority.compareTo(a.priority));

      // Take top 10
      final topHighlights = activeHighlights.take(10).toList();

      AppLogger.common(
        '🎠 HighlightService: Returning top ${topHighlights.length} highlights after priority sorting',
        isShow: isShow,
      );

      if (topHighlights.isNotEmpty) {
        AppLogger.common(
          '🎠 HighlightService: Top highlight - ID: ${topHighlights.first.id}, Candidate: ${topHighlights.first.candidateName}, Priority: ${topHighlights.first.priority}',
          isShow: isShow,
        );
      }

      return topHighlights;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error fetching highlights',
        error: e,
        isShow: isShow,
      );
      return [];
    }
  }

  // Get platinum banner for a specific district/body/ward combination
  static Future<Highlight?> getPlatinumBanner(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Use hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights
      AppLogger.common(
        '🏷️ HighlightService: Fetching platinum banner for ward: $districtId/$bodyId/$wardId',
        isShow: isShow,
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
          .limit(20) // Get more for priority sorting
          .get();

      AppLogger.common(
        '🏷️ HighlightService: Found ${snapshot.docs.length} potential banners from query',
        isShow: isShow,
      );

      // Convert and sort by priority in memory (can't use composite index with arrayContains)
      final activeBanners = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .where((highlight) => highlight.endDate.isAfter(now))
          .toList();

      AppLogger.common(
        '🏷️ HighlightService: Found ${activeBanners.length} active non-expired banners',
        isShow: isShow,
      );

      // Sort by priority (highest first)
      activeBanners.sort((a, b) => b.priority.compareTo(a.priority));

      // Return top banner
      if (activeBanners.isNotEmpty) {
        final highlight = activeBanners.first;
        AppLogger.common(
          '🏷️ HighlightService: Returning top banner - ID: ${highlight.id}, Candidate: ${highlight.candidateName}, Priority: ${highlight.priority}',
          isShow: isShow,
        );
        return highlight;
      }

      AppLogger.common(
        '🏷️ HighlightService: No premium platinum banner found for $districtId/$bodyId/$wardId',
        isShow: isShow,
      );
      return null;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error fetching platinum banner',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Track impression (view) - SESSION-BASED: Only track once per user session per highlight
  static Future<void> trackImpression(
    String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      final sessionService = HighlightSessionService();

      // Use session-based tracking: only increment if not viewed in current session
      final impressionTracked = await sessionService.trackImpressionIfNotViewed(
        highlightId: highlightId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      if (impressionTracked) {
        AppLogger.common(
          '📊 HighlightService: Impression tracked for $highlightId (session-based)',
          isShow: isShow,
        );
      } else {
        AppLogger.common(
          '⏭️ HighlightService: Impression skipped for $highlightId (already viewed in session)',
          isShow: isShow,
        );
      }
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error in session-based impression tracking',
        error: e,
        isShow: isShow,
      );
    }
  }

  // Track click
  static Future<void> trackClick(
    String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        await FirebaseFirestore.instance
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
        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .update({'clicks': FieldValue.increment(1)});
      }
    } catch (e) {
      AppLogger.commonError('Error tracking click', error: e, isShow: isShow);
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
          '${districtId}_${bodyId}_$wardId'; // Keep for backward compatibility

      final location = LocationModel(
        stateId: 'maharashtra', // Default state
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        location: location,
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

      // Save to hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights/{highlightId}
      await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra') // TODO: Make dynamic based on user location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .set(highlight.toJson());

      return highlightId;
    } catch (e) {
      AppLogger.commonError(
        'Error creating highlight',
        error: e,
        isShow: isShow,
      );
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
      AppLogger.commonError(
        'Error fetching push feed',
        error: e,
        isShow: isShow,
      );
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
      AppLogger.commonError(
        'Error creating push feed item',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Update highlight status
  static Future<void> updateHighlightStatus(
    String highlightId,
    bool active, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        await FirebaseFirestore.instance
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
        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .update({'active': active});
      }
    } catch (e) {
      AppLogger.commonError(
        'Error updating highlight status',
        error: e,
        isShow: isShow,
      );
    }
  }

  // Update highlight status with lifecycle management
  static Future<void> updateHighlightStatusWithLifecycle(
    String highlightId,
    String status, {
    String? districtId,
    String? bodyId,
    String? wardId,
    DateTime? expiredAt,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'active': status == 'active',
      };

      if (expiredAt != null && status == 'expired') {
        updates['expiredAt'] = Timestamp.fromDate(expiredAt);
      }

      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        await FirebaseFirestore.instance
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
        await FirebaseFirestore.instance
            .collection('highlights')
            .doc(highlightId)
            .update(updates);
      }

      AppLogger.common(
        '✅ HighlightService: Updated highlight $highlightId status to $status',
        isShow: isShow,
      );
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error updating highlight status with lifecycle',
        error: e,
        isShow: isShow,
      );
    }
  }

  // Get all highlights in a ward (for lifecycle management)
  static Future<List<Highlight>> getAllHighlightsInWard(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      AppLogger.common(
        '📋 HighlightService: Fetching ALL highlights for ward: $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

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
          .orderBy('createdAt', descending: true)
          .get();

      final highlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      AppLogger.common(
        '📋 HighlightService: Found ${highlights.length} total highlights in ward',
        isShow: isShow,
      );

      return highlights;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error fetching all highlights in ward',
        error: e,
        isShow: isShow,
      );
      return [];
    }
  }

  // Process expired highlights (call this periodically or via Cloud Function)
  static Future<void> processExpiredHighlights(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      AppLogger.common(
        '⏰ HighlightService: Processing expired highlights for ward: $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

      final now = DateTime.now();
      final allHighlights = await getAllHighlightsInWard(stateId, districtId, bodyId, wardId);

      // Find highlights that should be expired
      final expiredHighlights = allHighlights.where((highlight) =>
        highlight.status == 'active' &&
        highlight.endDate.isBefore(now)
      ).toList();

      if (expiredHighlights.isNotEmpty) {
        AppLogger.common(
          '⏰ HighlightService: Found ${expiredHighlights.length} highlights to expire',
          isShow: isShow,
        );

        // Update each expired highlight
        for (final highlight in expiredHighlights) {
          await updateHighlightStatusWithLifecycle(
            highlight.id,
            'expired',
            districtId: districtId,
            bodyId: bodyId,
            wardId: wardId,
            expiredAt: now,
          );
        }

        AppLogger.common(
          '✅ HighlightService: Successfully expired ${expiredHighlights.length} highlights',
          isShow: isShow,
        );
      } else {
        AppLogger.common(
          '⏰ HighlightService: No highlights to expire',
          isShow: isShow,
        );
      }
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error processing expired highlights',
        error: e,
        isShow: isShow,
      );
    }
  }

  // Get highlights by candidate
  static Future<List<Highlight>> getHighlightsByCandidate(
    String candidateId,
  ) async {
    try {
      // Use collection group query to find highlights across all wards
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('highlights')
          .where('candidateId', isEqualTo: candidateId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.commonError(
        'Error fetching candidate highlights',
        error: e,
        isShow: isShow,
      );
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
    int validityDays = 7, // Default to 7 days for highlight plans
    List<String> placement = const [
      'top_banner',
    ], // Default to banner only for highlight plans
  }) async {
    try {
      AppLogger.common(
        '🏆 HighlightService: Creating Platinum highlight for $candidateName',
        isShow: isShow,
      );

      final highlightId =
          'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
      final locationKey = '${districtId}_${bodyId}_$wardId';

      // Calculate priority based on level
      int priorityValue = _getPriorityValue(priorityLevel);

      final location = LocationModel(
        stateId: 'maharashtra', // Default state
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        location: location,
        locationKey: locationKey,
        package: 'platinum', // Platinum package
        placement: placement, // Use provided placement
        priority: priorityValue,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(
          Duration(days: validityDays),
        ), // Use provided validity
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

      // Save to hierarchical structure: /states/maharashtra/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/highlights/{highlightId}
      await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra') // TODO: Make dynamic based on user location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .set(enhancedData);

      AppLogger.common(
        '✅ HighlightService: Created Platinum highlight $highlightId for $candidateName',
        isShow: isShow,
      );
      AppLogger.common(
        '   Location: $locationKey, Style: $bannerStyle, Priority: $priorityLevel ($priorityValue)',
        isShow: isShow,
      );
      AppLogger.common(
        '   Validity: $validityDays days, Placement: $placement',
        isShow: isShow,
      );
      return highlightId;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error creating Platinum highlight',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Update existing highlight with enhanced configuration
  static Future<bool> updateHighlightConfig({
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
        '🔄 HighlightService: Updating highlight config for $highlightId',
        isShow: isShow,
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
          await FirebaseFirestore.instance
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
          await FirebaseFirestore.instance
              .collection('highlights')
              .doc(highlightId)
              .update(updates);
        }

        AppLogger.common(
          '✅ HighlightService: Updated highlight $highlightId with ${updates.length} changes',
          isShow: isShow,
        );
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error updating highlight config',
        error: e,
        isShow: isShow,
      );
      return false;
    }
  }

  // Get highlight configuration for editing
  static Future<Map<String, dynamic>?> getHighlightConfig(
    String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      // If location info is provided, use hierarchical path
      if (districtId != null && bodyId != null && wardId != null) {
        final doc = await FirebaseFirestore.instance
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
        final doc = await FirebaseFirestore.instance
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
        '❌ HighlightService: Error getting highlight config',
        error: e,
        isShow: isShow,
      );
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
