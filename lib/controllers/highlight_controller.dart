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

  // Cache for platinum banner
  Highlight? _platinumBanner;
  Highlight? get platinumBanner => _platinumBanner;

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

  // Load platinum banner for a specific location
  Future<void> loadPlatinumBanner({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      AppLogger.highlight('Loading platinum banner for $districtId/$bodyId/$wardId');

      _platinumBanner = await _repository.getPlatinumBanner(
        districtId,
        bodyId,
        wardId,
      );

      AppLogger.highlight('Platinum banner loaded: ${_platinumBanner?.id ?? 'None'}');
      update(); // Notify listeners

    } catch (e) {
      AppLogger.highlightError('Error loading platinum banner', error: e);
      _platinumBanner = null;
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
        active: startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now()),
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
  }) async {
    try {
      AppLogger.highlight('Creating Platinum highlight for $candidateName');

      final highlightId = 'platinum_hl_${DateTime.now().millisecondsSinceEpoch}';
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

      // Create highlight with enhanced data
      final result = await _repository.createHighlight(highlight);

      if (result != null) {
        AppLogger.highlight('Created Platinum highlight $highlightId for $candidateName');
        AppLogger.highlight('Location: $locationKey, Style: $bannerStyle, Priority: $priorityLevel ($priorityValue)');

        // Create welcome sponsored post
        await _createWelcomePushFeedItem(
          candidateId: candidateId,
          wardId: wardId,
          candidateName: candidateName,
          highlightId: highlightId,
        );
      }

      return result;
    } catch (e) {
      AppLogger.highlightError('Error creating Platinum highlight', error: e);
      errorMessage.value = 'Failed to create Platinum highlight: $e';
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
  Future<void> trackClick(String highlightId, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    try {
      await _repository.trackClick(highlightId,
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
  Future<void> updateHighlightStatus(String highlightId, bool active) async {
    try {
      await _repository.updateHighlightStatus(highlightId, active);
      AppLogger.highlight('Updated highlight $highlightId status to: $active');
    } catch (e) {
      AppLogger.highlightError('Error updating highlight status', error: e);
      errorMessage.value = 'Failed to update highlight status: $e';
    }
  }

  // Update highlight configuration
  Future<bool> updateHighlightConfig({
    required String highlightId,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    String? customMessage,
    bool? showAnalytics,
  }) async {
    try {
      final result = await _repository.updateHighlightConfig(
        highlightId: highlightId,
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
  Future<List<PushFeedItem>> getPushFeed(String wardId, {int limit = 20}) async {
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
      AppLogger.highlight('Creating push feed item for candidate: $candidateId');

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
        message: '$candidateName is now a Platinum member with maximum visibility!',
        highlightId: highlightId,
      );
      AppLogger.highlight('Created welcome push feed item');
    } catch (e) {
      AppLogger.highlightError('Error creating welcome push feed item', error: e);
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