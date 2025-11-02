import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlight_model.dart';
import '../../candidate/models/location_model.dart';
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

  // Create or update Platinum highlight for real candidate
  static Future<String?> createOrUpdatePlatinumHighlight({
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
        '🏆 HighlightService: Creating/Updating Platinum highlight for $candidateName',
        isShow: isShow,
      );

      // Check if candidate already has an existing highlight in their specific ward
      final existingHighlights = await getHighlightsByCandidateInWard(
        candidateId: candidateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
      final existingHighlight = existingHighlights.isNotEmpty ? existingHighlights.first : null;

      if (existingHighlight != null) {
        AppLogger.common(
          '🔄 HighlightService: Found existing highlight ${existingHighlight.id} for candidate $candidateId, updating instead of creating new',
          isShow: isShow,
        );

        // Update existing highlight
        return await updateExistingHighlight(
          existingHighlight: existingHighlight,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
          candidateName: candidateName,
          party: party,
          imageUrl: imageUrl,
          bannerStyle: bannerStyle,
          callToAction: callToAction,
          priorityLevel: priorityLevel,
          customMessage: customMessage,
          validityDays: validityDays,
          placement: placement,
        );
      } else {
        AppLogger.common(
          '🆕 HighlightService: No existing highlight found for candidate $candidateId, creating new one',
          isShow: isShow,
        );

        // Create new highlight
        return await _createNewPlatinumHighlight(
          candidateId: candidateId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
          candidateName: candidateName,
          party: party,
          imageUrl: imageUrl,
          bannerStyle: bannerStyle,
          callToAction: callToAction,
          priorityLevel: priorityLevel,
          customMessage: customMessage,
          validityDays: validityDays,
          placement: placement,
        );
      }
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error creating/updating Platinum highlight',
        error: e,
        isShow: isShow,
      );
      return null;
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
    // For backward compatibility, delegate to the new method
    return await createOrUpdatePlatinumHighlight(
      candidateId: candidateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      candidateName: candidateName,
      party: party,
      imageUrl: imageUrl,
      bannerStyle: bannerStyle,
      callToAction: callToAction,
      priorityLevel: priorityLevel,
      customMessage: customMessage,
      validityDays: validityDays,
      placement: placement,
    );
  }

  // Helper method to create new Platinum highlight
  static Future<String?> _createNewPlatinumHighlight({
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
    int validityDays = 7,
    List<String> placement = const ['top_banner'],
  }) async {
    try {
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
        '✅ HighlightService: Created new Platinum highlight $highlightId for $candidateName',
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
        '❌ HighlightService: Error creating new Platinum highlight',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Helper method to update existing highlight
  static Future<String?> updateExistingHighlight({
    required Highlight existingHighlight,
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
    int validityDays = 7,
    List<String> placement = const ['top_banner'],
  }) async {
    try {
      final now = DateTime.now();
      final highlightId = existingHighlight.id;

      // Calculate priority based on level
      int priorityValue = _getPriorityValue(priorityLevel);

      // Calculate new end date - extend from current end date if it's in the future, otherwise from now
      final currentEndDate = existingHighlight.endDate;
      final baseDate = currentEndDate.isAfter(now) ? currentEndDate : now;
      final newEndDate = baseDate.add(Duration(days: validityDays));

      final updates = <String, dynamic>{
        'candidateName': candidateName,
        'party': party,
        'placement': placement,
        'priority': priorityValue,
        'endDate': Timestamp.fromDate(newEndDate),
        'active': true,
        'exclusive': priorityLevel == 'urgent',
        'rotation': priorityLevel != 'urgent',
        'status': 'active',
        'updatedAt': Timestamp.fromDate(now),
        // Enhanced metadata
        'bannerStyle': bannerStyle,
        'callToAction': callToAction,
        'priorityLevel': priorityLevel,
        'customMessage': customMessage,
      };

      // Update image URL if provided
      if (imageUrl != null && imageUrl.isNotEmpty) {
        updates['imageUrl'] = imageUrl;
      }

      // Update in hierarchical structure
      await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .doc(highlightId)
          .update(updates);

      AppLogger.common(
        '✅ HighlightService: Updated existing highlight $highlightId for $candidateName',
        isShow: isShow,
      );
      AppLogger.common(
        '   Extended end date from ${existingHighlight.endDate} to $newEndDate',
        isShow: isShow,
      );
      AppLogger.common(
        '   Priority: $priorityLevel ($priorityValue), Validity extension: $validityDays days',
        isShow: isShow,
      );
      return highlightId;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error updating existing highlight',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Helper method to get highlights by candidate in a specific ward
  static Future<List<Highlight>> getHighlightsByCandidateInWard({
    required String candidateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.common(
        '� HighlightService: Getting highlights for candidate $candidateId in ward $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('highlights')
          .where('candidateId', isEqualTo: candidateId)
          .get();

      final highlights = snapshot.docs
          .map((doc) => Highlight.fromJson(doc.data()))
          .toList();

      // Sort by createdAt descending in memory since we can't use orderBy with where clause
      highlights.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.common(
        '✅ HighlightService: Found ${highlights.length} highlights for candidate $candidateId in ward',
        isShow: isShow,
      );

      return highlights;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error getting highlights by candidate in ward',
        error: e,
        isShow: isShow,
      );
      return [];
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

  // Get candidate symbol URL for independent candidates
  static Future<String?> getCandidateSymbolUrl({
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required String candidateId,
  }) async {
    try {
      AppLogger.common(
        '🎨 HighlightService: Fetching candidate symbol for $candidateId in $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

      final candidateDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (candidateDoc.exists && candidateDoc.data() != null) {
        final candidateData = candidateDoc.data()!;
        final symbolUrl = candidateData['symbol'] as String?;

        if (symbolUrl != null && symbolUrl.isNotEmpty && symbolUrl.startsWith('http')) {
          AppLogger.common(
            '✅ HighlightService: Found custom symbol URL: $symbolUrl',
            isShow: isShow,
          );
          return symbolUrl;
        }
      }

      AppLogger.common(
        '❌ HighlightService: No custom symbol found for candidate $candidateId',
        isShow: isShow,
      );
      return null;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error fetching candidate symbol',
        error: e,
        isShow: isShow,
      );
      return null;
    }
  }

  // Cleanup expired highlights in a specific ward (on-demand cleanup)
  static Future<int> cleanupExpiredHighlights({
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.common(
        '🧹 HighlightService: Starting cleanup of expired highlights for ward: $districtId/$bodyId/$wardId',
        isShow: isShow,
      );

      final now = DateTime.now();
      int cleanedCount = 0;

      // Get all highlights in the ward (both active and inactive)
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
          .get();

      AppLogger.common(
        '🧹 HighlightService: Found ${snapshot.docs.length} total highlights to check for expiration',
        isShow: isShow,
      );

      // Process each highlight document
      for (final doc in snapshot.docs) {
        try {
          final highlight = Highlight.fromJson(doc.data());

          // Check if highlight has expired
          if (highlight.endDate.isBefore(now) && highlight.active) {
            AppLogger.common(
              '🧹 HighlightService: Found expired highlight ${highlight.id} for candidate ${highlight.candidateName} (expired: ${highlight.endDate})',
              isShow: isShow,
            );

            // Mark as expired and inactive
            await FirebaseFirestore.instance
                .collection('states')
                .doc(stateId)
                .collection('districts')
                .doc(districtId)
                .collection('bodies')
                .doc(bodyId)
                .collection('wards')
                .doc(wardId)
                .collection('highlights')
                .doc(highlight.id)
                .update({
                  'active': false,
                  'status': 'expired',
                  'expiredAt': Timestamp.fromDate(now),
                  'updatedAt': Timestamp.fromDate(now),
                });

            cleanedCount++;
            AppLogger.common(
              '✅ HighlightService: Successfully cleaned up expired highlight ${highlight.id}',
              isShow: isShow,
            );
          }
        } catch (e) {
          AppLogger.commonError(
            '❌ HighlightService: Error processing highlight ${doc.id} during cleanup',
            error: e,
            isShow: isShow,
          );
        }
      }

      AppLogger.common(
        '✅ HighlightService: Cleanup completed. Cleaned up $cleanedCount expired highlights',
        isShow: isShow,
      );

      return cleanedCount;
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightService: Error during highlight cleanup',
        error: e,
        isShow: isShow,
      );
      return 0;
    }
  }
}
