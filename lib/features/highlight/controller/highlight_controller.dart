import 'package:get/get.dart';
import '../models/highlight_model.dart';
import '../../../models/push_feed_model.dart';
import '../../candidate/models/location_model.dart';
import '../../../repositories/highlight_repository.dart';
import '../services/highlight_service.dart';
import '../../../utils/app_logger.dart';

class HighlightController extends GetxController {
  final HighlightRepository _repository = HighlightRepository();

  // Reactive variables
  var highlights = <Highlight>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Cache for platinum banners (list for rotation)
  final List<Highlight> _platinumBanners = [];
  List<Highlight> get platinumBanners => _platinumBanners;
  Highlight? get currentPlatinumBanner => _platinumBanners.isNotEmpty ? _platinumBanners.first : null;

  @override
  void onInit() {
    super.onInit();
    AppLogger.highlight('HighlightController: Initialized');
  }

  // Create or update Platinum highlight for real candidate
  Future<String?> createOrUpdatePlatinumHighlight({
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
      AppLogger.highlight(
        '🏆 HighlightController: Creating/Updating Platinum highlight for $candidateName',
      );

      // Use the service method that handles checking for existing highlights
      return await HighlightService.createOrUpdatePlatinumHighlight(
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
    } catch (e) {
      AppLogger.highlightError(
        '❌ HighlightController: Error creating/updating Platinum highlight',
        error: e,
      );
      errorMessage.value = 'Failed to create/update Platinum highlight: $e';
      return null;
    }
  }

  // Create Platinum highlight for real candidate
  Future<String?> createPlatinumHighlight({
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
    Map<String, dynamic>?
    highlightConfig, // Add highlight config from dashboard
  }) async {
    try {
      AppLogger.highlight(
        '🔥 Creating/Updating Platinum highlight for $candidateName',
      );
      AppLogger.highlight('📍 Location: $districtId/$bodyId/$wardId');
      AppLogger.highlight('👤 Candidate ID: $candidateId');
      AppLogger.highlight(
        '⏰ Validity: $validityDays days, Placement: $placement',
      );

      // Check if candidate already has an active highlight
      final existingHighlights = await getHighlightsByCandidate(candidateId);
      final activeHighlight = existingHighlights
          .where(
            (h) =>
                h.active &&
                h.package == 'platinum' &&
                h.endDate.isAfter(DateTime.now()),
          )
          .firstOrNull;

      String highlightId;
      bool isUpdate = false;

      if (activeHighlight != null) {
        // Update existing highlight
        highlightId = activeHighlight.id;
        isUpdate = true;
        AppLogger.highlight(
          '🔄 Found existing active highlight $highlightId, updating instead of creating new',
        );
      } else {
        // Create new highlight
        highlightId = 'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
        AppLogger.highlight('🆕 Creating new highlight $highlightId');
      }

      final locationKey = '${districtId}_${bodyId}_$wardId';

      // Calculate priority based on level
      final priorityValue = _getPriorityValue(priorityLevel);

      final location = LocationModel(
        stateId: 'maharashtra',
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        location: location,
        locationKey: locationKey,
        package: 'platinum',
        placement: placement, // Use provided placement
        priority: priorityValue,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(
          Duration(days: validityDays),
        ), // Use provided validity
        active: true,
        exclusive: priorityLevel == 'urgent', // Urgent gets exclusive placement
        rotation: priorityLevel != 'urgent', // Don't rotate urgent items
        views: isUpdate ? activeHighlight?.views ?? 0 : 0,
        clicks: isUpdate ? activeHighlight?.clicks ?? 0 : 0,
        imageUrl: imageUrl,
        candidateName: candidateName,
        party: party,
        createdAt: isUpdate
            ? activeHighlight?.createdAt ?? DateTime.now()
            : DateTime.now(),
      );

      AppLogger.highlight(
        '📋 Highlight data (${isUpdate ? 'UPDATE' : 'CREATE'}):',
      );
      AppLogger.highlight('   ID: $highlightId');
      AppLogger.highlight('   Package: ${highlight.package}');
      AppLogger.highlight('   Placement: ${highlight.placement}');
      AppLogger.highlight('   Active: ${highlight.active}');
      AppLogger.highlight('   Priority: ${highlight.priority}');
      AppLogger.highlight('   Start: ${highlight.startDate}');
      AppLogger.highlight('   End: ${highlight.endDate}');

      // Add enhanced metadata for Platinum features
      final enhancedData = highlight.toJson();
      enhancedData['bannerStyle'] = bannerStyle;
      enhancedData['callToAction'] = callToAction;
      enhancedData['priorityLevel'] = priorityLevel;
      enhancedData['customMessage'] = customMessage;

      // Add highlight config data from candidate dashboard if provided
      if (highlightConfig != null) {
        enhancedData.addAll(highlightConfig);
      }

      AppLogger.highlight('💾 Saving to Firestore...');

      String? result;
      if (isUpdate) {
        // Update existing highlight
        final success = await _repository.updateHighlight(highlight);
        result = success ? highlightId : null;
        if (success) {
          AppLogger.highlight(
            '✅ Updated existing Platinum highlight $highlightId for $candidateName',
          );
        } else {
          AppLogger.highlight('❌ Failed to update existing highlight');
        }
      } else {
        // Create new highlight
        result = await _repository.createHighlight(highlight);
        if (result != null) {
          AppLogger.highlight(
            '✅ Created new Platinum highlight $highlightId for $candidateName',
          );
        } else {
          AppLogger.highlight(
            '❌ Failed to create highlight - repository returned null',
          );
        }
      }

      if (result != null) {
        AppLogger.highlight(
          '📍 Location: $locationKey, Style: $bannerStyle, Priority: $priorityLevel ($priorityValue)',
        );
        AppLogger.highlight(
          '🔗 Firestore path: states/maharashtra/districts/$districtId/bodies/$bodyId/wards/$wardId/highlights/$highlightId',
        );

        // Create welcome sponsored post only for new highlights
        if (!isUpdate) {
          await _createWelcomePushFeedItem(
            candidateId: candidateId,
            wardId: wardId,
            candidateName: candidateName,
            highlightId: highlightId,
          );
        }
      }

      return result;
    } catch (e) {
      AppLogger.highlightError(
        '❌ Error creating/updating Platinum highlight',
        error: e,
      );
      errorMessage.value = 'Failed to create/update Platinum highlight: $e';
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
      await _repository.updateHighlightStatus(
        highlightId,
        active,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
      AppLogger.highlight('Updated highlight $highlightId status to: $active');
    } catch (e) {
      AppLogger.highlightError('Error updating highlight status', error: e);
      errorMessage.value = 'Failed to update highlight status: $e';
    }
  }

  // Update highlight configuration
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
      final result = await _repository.updateHighlightConfig(
        highlightId: highlightId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
        bannerStyle: bannerStyle,
        callToAction: callToAction,
        priorityLevel: priorityLevel,
        customMessage: customMessage,
        showAnalytics: showAnalytics,
      );

      if (result) {
        AppLogger.highlight('Updated highlight config for: $highlightId');
      }

      return result;
    } catch (e) {
      AppLogger.highlightError('Error updating highlight config', error: e);
      errorMessage.value = 'Failed to update highlight configuration: $e';
      return false;
    }
  }

  // Get highlights by candidate
  Future<List<Highlight>> getHighlightsByCandidate(String candidateId) async {
    try {
      AppLogger.highlight('Getting highlights for candidate: $candidateId');
      return await _repository.getHighlightsByCandidate(candidateId);
    } catch (e) {
      AppLogger.highlightError('Error getting candidate highlights', error: e);
      return [];
    }
  }

  // Get push feed items for ward
  Future<List<PushFeedItem>> getPushFeed(
    String wardId, {
    int limit = 20,
  }) async {
    try {
      AppLogger.highlight('Getting push feed for ward: $wardId');
      return await _repository.getPushFeed(wardId, limit: limit);
    } catch (e) {
      AppLogger.highlightError('Error getting push feed', error: e);
      return [];
    }
  }

  // Create push feed item
  Future<String?> createPushFeedItem({
    required String candidateId,
    required String wardId,
    required String title,
    required String message,
    String? imageUrl,
    String? highlightId,
  }) async {
    try {
      AppLogger.highlight(
        'Creating push feed item for candidate: $candidateId',
      );

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

      return await _repository.createPushFeedItem(feedItem);
    } catch (e) {
      AppLogger.highlightError('Error creating push feed item', error: e);
      return null;
    }
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  // Helper method to create welcome push feed item
  Future<void> _createWelcomePushFeedItem({
    required String candidateId,
    required String wardId,
    required String candidateName,
    required String highlightId,
  }) async {
    try {
      await createPushFeedItem(
        candidateId: candidateId,
        wardId: wardId,
        title: '🎉 Platinum Plan Activated!',
        message:
            '$candidateName is now a Platinum member with maximum visibility!',
        highlightId: highlightId,
      );
      AppLogger.highlight('Created welcome push feed item');
    } catch (e) {
      AppLogger.highlightError(
        'Error creating welcome push feed item',
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
