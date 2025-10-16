import 'package:get/get.dart';
import '../models/highlight_model.dart';
import '../repositories/highlight_repository.dart';
import '../utils/app_logger.dart';

class HighlightController extends GetxController {
  final HighlightRepository _repository = HighlightRepository();

  // Reactive variables
  var highlights = <Highlight>[].obs;
  var isLoading = false.obs;
  var errorMessage = ''.obs;

  // Cache for platinum banners (list for rotation)
  List<Highlight> _platinumBanners = [];
  List<Highlight> get platinumBanners => _platinumBanners;
  Highlight? get currentPlatinumBanner => _platinumBanners.isNotEmpty ? _platinumBanners.first : null;

  @override
  void onInit() {
    super.onInit();
    AppLogger.highlight('HighlightController: Initialized');
  }

  // Load active highlights for a specific location
  Future<void> loadHighlights({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      AppLogger.highlight('Loading highlights for $districtId/$bodyId/$wardId');

      final loadedHighlights = await _repository.getActiveHighlights(
        districtId,
        bodyId,
        wardId,
      );

      highlights.value = loadedHighlights;
      AppLogger.highlight('Loaded ${loadedHighlights.length} highlights');
    } catch (e) {
      AppLogger.highlightError('Error loading highlights', error: e);
      errorMessage.value = 'Failed to load highlights: $e';
      highlights.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // Load platinum banners for a specific location (returns list for rotation)
  Future<void> loadPlatinumBanners({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.highlight(
        'Loading platinum banners for $districtId/$bodyId/$wardId',
      );

      _platinumBanners = await HighlightRepository.getHighlightBanners(
        stateId: 'maharashtra', // TODO: Make dynamic based on user location
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      AppLogger.highlight(
        'Platinum banners loaded: ${_platinumBanners.length} banners',
      );
      update(); // Notify listeners
    } catch (e) {
      AppLogger.highlightError('Error loading platinum banners', error: e);
      _platinumBanners = [];
      update();
    }
  }

  // Create new highlight
  Future<String?> createHighlight({
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
      AppLogger.highlight('Creating highlight for candidate: $candidateId');

      final highlightId = 'hl_${DateTime.now().millisecondsSinceEpoch}';
      final locationKey = '${districtId}_${bodyId}_$wardId';

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

      final result = await _repository.createHighlight(highlight);

      if (result != null) {
        AppLogger.highlight('Highlight created successfully: $highlightId');
        // Optionally refresh highlights if we're in the same location
        // await loadHighlights(districtId: districtId, bodyId: bodyId, wardId: wardId);
      }

      return result;
    } catch (e) {
      AppLogger.highlightError('Error creating highlight', error: e);
      errorMessage.value = 'Failed to create highlight: $e';
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

      final highlight = Highlight(
        id: highlightId,
        candidateId: candidateId,
        wardId: wardId,
        districtId: districtId,
        bodyId: bodyId,
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

  // Track impression (view)
  Future<void> trackImpression(String highlightId) async {
    try {
      await _repository.trackImpression(highlightId);
      AppLogger.highlight('Tracked impression for highlight: $highlightId');
    } catch (e) {
      AppLogger.highlightError('Error tracking impression', error: e);
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
      await _repository.trackClick(
        highlightId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
      AppLogger.highlight('Tracked click for highlight: $highlightId');
    } catch (e) {
      AppLogger.highlightError('Error tracking click', error: e);
    }
  }

  // Track carousel view for analytics
  Future<void> trackCarouselView({
    required String contentId,
    required String userId,
    required String candidateId,
  }) async {
    try {
      await _repository.trackCarouselView(
        sectionType: 'carousel',
        contentId: contentId,
        userId: userId,
        candidateId: candidateId,
      );
      AppLogger.highlight('Tracked carousel view for: $contentId');
    } catch (e) {
      AppLogger.highlightError('Error tracking carousel view', error: e);
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
