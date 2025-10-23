import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/highlights_model.dart';
import '../models/candidate_model.dart';

/// Service responsible for synchronizing banner configuration to highlights collection.
/// Follows Single Responsibility Principle - handles only banner synchronization.
class BannerSyncService {
  /// Sync banner configuration to highlights collection for home screen display
  Future<void> syncBannerToHighlightsCollection(
    HighlightData highlightData,
    Map<String, dynamic> config,
    Candidate candidate,
  ) async {
    try {
      AppLogger.database('Syncing banner to highlights collection for ${candidate.name}', tag: 'BANNER_SYNC_SERVICE');

      // Check if highlight already exists in hierarchical structure
      final existingHighlights = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(candidate.location.districtId ?? 'unknown')
          .collection('bodies')
          .doc(candidate.location.bodyId ?? 'unknown')
          .collection('wards')
          .doc(candidate.location.wardId ?? 'unknown')
          .collection('highlights')
          .where('candidateId', isEqualTo: candidate.candidateId)
          .where('placement', arrayContains: 'top_banner')
          .limit(1)
          .get();

      String? highlightId;

      if (existingHighlights.docs.isNotEmpty) {
        // Update existing highlight
        highlightId = existingHighlights.docs.first.id;
        AppLogger.database('Updating existing highlight: $highlightId', tag: 'BANNER_SYNC_SERVICE');

        await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc(candidate.location.districtId ?? 'unknown')
            .collection('bodies')
            .doc(candidate.location.bodyId ?? 'unknown')
            .collection('wards')
            .doc(candidate.location.wardId ?? 'unknown')
            .collection('highlights')
            .doc(highlightId)
            .update({
              'bannerStyle': config['bannerStyle'] ?? 'premium',
              'callToAction': config['callToAction'] ?? 'View Profile',
              'priorityLevel': config['priorityLevel'] ?? 'normal',
              'customMessage': config['customMessage'] ?? '',
              'showAnalytics': config['showAnalytics'] ?? false,
              'active': highlightData.enabled,
              'priority': _getPriorityValue(config['priorityLevel'] ?? 'normal'),
              'exclusive': (config['priorityLevel'] ?? 'normal') == 'urgent',
              'rotation': (config['priorityLevel'] ?? 'normal') != 'urgent',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } else if (highlightData.enabled) {
        // Create new highlight
        highlightId = 'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
        AppLogger.database('Creating new highlight: $highlightId', tag: 'BANNER_SYNC_SERVICE');

        final highlight = {
          'highlightId': highlightId,
          'candidateId': candidate.candidateId, // Use actual candidateId, not userId
          'wardId': candidate.location.wardId ?? 'unknown',
          'districtId': candidate.location.districtId ?? 'unknown',
          'bodyId': candidate.location.bodyId ?? 'unknown',
          'locationKey': '${candidate.location.districtId ?? 'unknown'}_${candidate.location.bodyId ?? 'unknown'}_${candidate.location.wardId ?? 'unknown'}',
          'package': 'platinum',
          'placement': ['carousel', 'top_banner'],
          'priority': _getPriorityValue(config['priorityLevel'] ?? 'normal'),
          'startDate': FieldValue.serverTimestamp(),
          'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          'active': true,
          'exclusive': (config['priorityLevel'] ?? 'normal') == 'urgent',
          'rotation': (config['priorityLevel'] ?? 'normal') != 'urgent',
          'views': 0,
          'clicks': 0,
          'imageUrl': highlightData.imageUrl ?? candidate.photo,
          'candidateName': candidate.name ?? 'Candidate',
          'party': candidate.party ?? 'Party',
          'createdAt': FieldValue.serverTimestamp(),
          // Banner configuration
          'bannerStyle': config['bannerStyle'] ?? 'premium',
          'callToAction': config['callToAction'] ?? 'View Profile',
          'priorityLevel': config['priorityLevel'] ?? 'normal',
          'customMessage': config['customMessage'] ?? '',
          'showAnalytics': config['showAnalytics'] ?? false,
        };

        await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc(candidate.location.districtId ?? 'unknown')
            .collection('bodies')
            .doc(candidate.location.bodyId ?? 'unknown')
            .collection('wards')
            .doc(candidate.location.wardId ?? 'unknown')
            .collection('highlights')
            .doc(highlightId)
            .set(highlight);
      }

      if (highlightId != null) {
        AppLogger.database('Banner synced to highlights collection: $highlightId', tag: 'BANNER_SYNC_SERVICE');
        AppLogger.database('  Style: ${config['bannerStyle']}, Priority: ${config['priorityLevel']}', tag: 'BANNER_SYNC_SERVICE');
      }
    } catch (e) {
      AppLogger.databaseError('Error syncing banner to highlights collection', tag: 'BANNER_SYNC_SERVICE', error: e);
    }
  }

  /// Helper method to convert priority level to numeric value
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

  /// Refresh highlight banner when candidate profile is updated
  void refreshHighlightBanner() {
    try {
      AppLogger.database('Triggering highlight banner refresh', tag: 'BANNER_SYNC_SERVICE');

      // Since we can't directly access the banner widget, we'll use a simple approach:
      // The banner will refresh itself on next location change or we can implement
      // a more sophisticated refresh mechanism later

      // For now, we'll just log that a refresh was requested
      // In a future implementation, we could use:
      // 1. A stream that the banner listens to
      // 2. A global key to call refresh directly
      // 3. Provider/Bloc pattern for state management

      AppLogger.database('Highlight banner refresh requested - banner will reload on next location change', tag: 'BANNER_SYNC_SERVICE');
    } catch (e) {
      AppLogger.databaseError('Error refreshing highlight banner', tag: 'BANNER_SYNC_SERVICE', error: e);
    }
  }
}