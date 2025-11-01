import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/features/highlight/models/highlight_model.dart';
import 'package:janmat/features/highlight/services/highlight_service.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/symbol_utils.dart';
import '../../controllers/highlights_controller.dart';
import '../../models/candidate_model.dart';
import '../../widgets/edit/highlight_config.dart';
import 'components/image_handler.dart';
import 'components/highlight_banner_section.dart';
import 'components/carousel_card_section.dart';

class HighlightTab extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final Function(Map<String, dynamic>) onHighlightChange;
  final Function(bool) onChangesStateChanged;

  const HighlightTab({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.onHighlightChange,
    required this.onChangesStateChanged,
  });

  @override
  State<HighlightTab> createState() => HighlightTabState();
}

class HighlightTabState extends State<HighlightTab> {
  HighlightConfig? _config;
  bool _isUpdatingConfig = false;
  List<Highlight> _candidateHighlights = [];
  int _availableSeats = 4; // Max 4 highlights per ward
  Widget _currentSymbol = const Icon(Icons.star, color: Colors.amber, size: 25);

  // Local image storage for banner image
  String? _localBannerImagePath;
  bool _isUploadingImage = false;

  // Force rebuild counter for image updates
  int _imageUpdateCounter = 0;

  // Track original image URL for cleanup
  String? _originalImageUrl;
  List<String> _imagesToDelete = [];

  @override
  void initState() {
    super.initState();
    _loadHighlight();
    _loadCandidateHighlights();
  }

  @override
  void didUpdateWidget(HighlightTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.candidate('didUpdateWidget called - old editedData: ${oldWidget.editedData}, new editedData: ${widget.editedData}, _isUpdatingConfig: $_isUpdatingConfig');
    if (!_isUpdatingConfig && (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData)) {
      AppLogger.candidate('didUpdateWidget - data changed, calling _loadHighlight');
      _loadHighlight();
      _loadCandidateHighlights();
    } else {
      AppLogger.candidate('didUpdateWidget - skipping _loadHighlight (config update in progress)');
    }
  }

  Future<void> _loadCandidateHighlights() async {
    try {
      AppLogger.candidate('🔄 [HighlightDashboard] Starting to load candidate highlights...');

      // Fetch ALL highlights in the ward (active, expired, inactive)
      AppLogger.candidate('📡 [HighlightDashboard] Fetching all highlights in ward: ${widget.candidateData.location.districtId}/${widget.candidateData.location.bodyId}/${widget.candidateData.location.wardId}');
      final allWardHighlights = await HighlightService.getAllHighlightsInWard(
        widget.candidateData.location.stateId ?? 'maharashtra',
        widget.candidateData.location.districtId!,
        widget.candidateData.location.bodyId!,
        widget.candidateData.location.wardId!
      );

      AppLogger.candidate('📊 [HighlightDashboard] Found ${allWardHighlights.length} total highlights in ward');

      // Debug: Log all highlights status
      for (final highlight in allWardHighlights) {
        AppLogger.candidate('🔍 [HighlightDashboard] Highlight ${highlight.id}: status=${highlight.status}, active=${highlight.active}, endDate=${highlight.endDate}');
      }

      // Filter for active highlights only (for available seats calculation)
      final activeHighlights = allWardHighlights
        .where((h) => h.status == 'active' && h.active)
        .toList();

      AppLogger.candidate('✅ [HighlightDashboard] Found ${activeHighlights.length} active highlights (available seats: ${4 - activeHighlights.length})');

      // Find current candidate's highlight (any status)
      final candidateHighlights = allWardHighlights
        .where((highlight) => highlight.candidateId == widget.candidateData.candidateId)
        .toList();

      final currentCandidateHighlight = candidateHighlights.isNotEmpty ? candidateHighlights.first : null;

      AppLogger.candidate('👤 [HighlightDashboard] Current candidate (${widget.candidateData.candidateId}) has ${candidateHighlights.length} highlights');
      if (currentCandidateHighlight != null) {
        AppLogger.candidate('🎯 [HighlightDashboard] Candidate highlight: ID=${currentCandidateHighlight.id}, Status=${currentCandidateHighlight.status}, Active=${currentCandidateHighlight.active}, EndDate=${currentCandidateHighlight.endDate}');
        AppLogger.candidate('🖼️ [HighlightDashboard] Candidate imageUrl: "${currentCandidateHighlight.imageUrl}"');
      } else {
        AppLogger.candidate('❌ [HighlightDashboard] Candidate has no highlights in this ward');
      }

      if (mounted) {
        setState(() {
          _candidateHighlights = currentCandidateHighlight != null ? [currentCandidateHighlight] : [];
          _availableSeats = 4 - activeHighlights.length; // Correct: only count truly active highlights

          // Track original image URL for cleanup logic
          _originalImageUrl = currentCandidateHighlight?.imageUrl;
          _imagesToDelete = []; // Reset delete list
        });

        AppLogger.candidate('💾 [HighlightDashboard] Updated state: availableSeats=${_availableSeats}, candidateHighlights=${_candidateHighlights.length}');
        AppLogger.candidate('🖼️ [HighlightDashboard] Original image URL: "${_originalImageUrl}"');

        // Load party symbol for the candidate's highlight if available
        if (currentCandidateHighlight != null) {
          _loadPartySymbolForHighlight(currentCandidateHighlight);
        }
      }

      AppLogger.candidate('✅ [HighlightDashboard] Successfully loaded candidate highlights');
    } catch (e) {
      AppLogger.candidateError('❌ [HighlightDashboard] Error loading candidate highlights: $e');
    }
  }

  Future<void> _loadPartySymbolForHighlight(Highlight highlight) async {
    final party = highlight.party ?? 'independent';

    // For independent candidates, check Firebase for custom symbol
    if (party.toLowerCase().contains('independent')) {
      try {
        final highlightsController = Get.find<HighlightsController>();
        final symbolUrl = await highlightsController.getCandidateSymbol(widget.candidateData);

        if (symbolUrl != null && symbolUrl.isNotEmpty && symbolUrl.startsWith('http') && mounted) {
          setState(() {
            _currentSymbol = ClipOval(
              child: Image.network(
                symbolUrl,
                width: 35,
                height: 35,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/symbols/independent.png',
                    width: 35, height: 35, fit: BoxFit.cover);
                },
              ),
            );
          });
          return;
        }
      } catch (e) {
        AppLogger.commonError('❌ HighlightBanner: Error fetching custom symbol', error: e);
      }
    }

    // For regular parties or fallback, use SymbolUtils
    final symbolPath = SymbolUtils.getPartySymbolPath(party);
    if (mounted) {
      setState(() {
        _currentSymbol = ClipOval(
          child: Image(
            image: SymbolUtils.getSymbolImageProvider(symbolPath),
            width: 35,
            height: 35,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.star, color: Colors.amber, size: 25);
            },
          ),
        );
      });
    }
  }

  void _loadHighlight() {
    AppLogger.candidate('_loadHighlight called');
    final data = widget.editedData ?? widget.candidateData;
    final highlights = data.highlights ?? [];
    final highlightData = highlights.isNotEmpty ? highlights.first : null;
    final oldConfig = _config?.bannerStyle ?? 'uninitialized';

    AppLogger.candidate('_loadHighlight - oldConfig: $oldConfig, highlightData: $highlightData');

    // If we have local config changes, preserve them instead of resetting
    if (_config != null && !_isUpdatingConfig) {
      AppLogger.candidate('_loadHighlight - preserving local config changes');
      // Only update config if it's truly different data (not our own updates)
      final newConfig = HighlightConfig.fromJson(highlightData?.toJson());
      AppLogger.candidate('_loadHighlight - newConfig.bannerStyle: ${newConfig.bannerStyle}, oldConfig: $oldConfig');
      if (newConfig.bannerStyle != oldConfig) {
        AppLogger.candidate('_loadHighlight - external data change detected, updating config');
        _config = newConfig;
        // Load endDate from highlight data
        if (highlightData?.expiresAt != null) {
          _config = _config!.copyWith(endDate: DateTime.parse(highlightData!.expiresAt!));
        }
      } else {
        AppLogger.candidate('_loadHighlight - no external changes, keeping current config');
      }
    } else {
      // First time loading or during our own updates
      _config = HighlightConfig.fromJson(highlightData?.toJson());
      // Load endDate from highlight data
      if (highlightData?.expiresAt != null) {
        _config = _config!.copyWith(endDate: DateTime.parse(highlightData!.expiresAt!));
      }
      AppLogger.candidate('_loadHighlight - initial load or during update, config: ${_config!.bannerStyle}');
    }
  }

  void _updateHighlight() {
    assert(_config != null, 'Config should be initialized before updating');
    AppLogger.candidate('_updateHighlight called with bannerStyle: ${_config!.bannerStyle}');
    widget.onHighlightChange(_config!.toJson());
    AppLogger.candidate('_updateHighlight completed');
  }

  // Method to upload pending files and sync config (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Upload local banner image to Firebase Storage if one was selected
    if (_localBannerImagePath != null) {
      AppLogger.candidate('📤 [Highlight] Uploading local banner image to Firebase Storage');
      try {
        setState(() => _isUploadingImage = true);

        // Import the file upload service
        final fileUploadService = Get.find<FileUploadService>();

        // Upload the image file
        final uploadedUrl = await fileUploadService.uploadFile(
          _localBannerImagePath!,
          'highlight_banners/${widget.candidateData.candidateId}/banner_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'image/jpeg',
        );

        if (uploadedUrl != null) {
          AppLogger.candidate('📤 [Highlight] Image uploaded successfully: $uploadedUrl');

          // Update the highlight document with the new image URL using controller
          final currentHighlight = _currentHighlight;
          if (currentHighlight != null) {
            final highlightsController = Get.find<HighlightsController>();
            await highlightsController.updateHighlightImageUrl(widget.candidateData, currentHighlight.id, uploadedUrl);

            // If we have images to delete, update the candidate document's deleteStorage array
            if (_imagesToDelete.isNotEmpty) {
              await highlightsController.addImagesToDeleteStorage(widget.candidateData, _imagesToDelete);

              AppLogger.candidate('🗑️ [Highlight] Added ${_imagesToDelete.length} images to deleteStorage: $_imagesToDelete');

              // Clear the delete list after processing
              _imagesToDelete.clear();
            }

            AppLogger.candidate('📤 [Highlight] Highlight document updated with new image URL');
          }
        } else {
          AppLogger.candidate('⚠️ [Highlight] Upload returned null (likely due to Firebase Storage permissions during testing) - continuing with local cleanup');
        }

        // Clear the local image path since upload attempt is complete (successful or failed due to permissions)
        setState(() {
          _localBannerImagePath = null;
        });

        // Notify parent that changes have been processed (even if upload failed due to permissions)
        widget.onChangesStateChanged(false);
      } catch (e) {
        AppLogger.candidateError('❌ [Highlight] Error uploading banner image: $e');
        rethrow;
      } finally {
        if (mounted) {
          setState(() => _isUploadingImage = false);
        }
      }
    }

    // Sync local config changes to controller
    AppLogger.candidate('📤 [Highlight] Syncing config changes to controller');
    _isUpdatingConfig = true;
    _updateHighlight();
    _isUpdatingConfig = false;
    AppLogger.candidate('📤 [Highlight] Config sync completed');
  }

  // Image picker functionality
  Future<void> _pickBannerImage() async {
    final imagePath = await ImageHandler.pickBannerImage();

    if (imagePath != null && mounted) {
      // Check if we need to mark the current image for deletion
      _checkImageForDeletion();

      AppLogger.candidate('📸 [HighlightDashboard] Setting local image path: $imagePath');
      AppLogger.candidate('📸 [HighlightDashboard] Previous local path: $_localBannerImagePath');

      // Update state with new image path and force rebuild counter
      final oldPath = _localBannerImagePath;
      setState(() {
        _localBannerImagePath = imagePath;
        _imageUpdateCounter++; // Force rebuild by changing counter
      });

      AppLogger.candidate('📸 [HighlightDashboard] State updated - new local path: $_localBannerImagePath, counter: $_imageUpdateCounter');

      // Additional force rebuild for immediate UI update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppLogger.candidate('🔄 [HighlightDashboard] Post-frame callback - forcing additional rebuild');
          setState(() {
            _imageUpdateCounter++; // Another counter increment to ensure rebuild
          });
        }
      });

      // Notify parent that changes have been made
      widget.onChangesStateChanged(true);

      AppLogger.candidate('✅ [HighlightDashboard] Image selection complete - path changed from $oldPath to $_localBannerImagePath');

      // Show immediate feedback to user
      Get.snackbar(
        'Image Selected',
        'New banner image ready for preview',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Check if current highlight image should be deleted when replaced
  void _checkImageForDeletion() {
    final currentHighlight = _currentHighlight;
    if (currentHighlight?.imageUrl != null &&
        currentHighlight!.imageUrl!.isNotEmpty &&
        _originalImageUrl != null &&
        _originalImageUrl!.isNotEmpty) {

      // Get candidate's profile photo URL
      final candidateProfilePhotoUrl = widget.candidateData.photo;

      // If current highlight image is different from candidate's profile photo,
      // it means it's a custom uploaded image that should be deleted
      if (_originalImageUrl != candidateProfilePhotoUrl) {
        _imagesToDelete.add(_originalImageUrl!);
        AppLogger.candidate('🗑️ [HighlightDashboard] Marked image for deletion: $_originalImageUrl');
      }
    }
  }



  // Get the current highlight document (first active one)
  Highlight? get _currentHighlight {
    return _candidateHighlights.isNotEmpty ? _candidateHighlights.first : null;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure config is initialized
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🏆 Highlight Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your home screen banner and carousel card appearance',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),

          // Section 1: Highlight Banner Section
          HighlightBannerSection(
            currentHighlight: _currentHighlight,
            isBannerActive: _currentHighlight?.active ?? false,
            availableSeats: _availableSeats,
            localBannerImagePath: _localBannerImagePath,
            isUploadingImage: _isUploadingImage,
            onPickImage: _pickBannerImage,
            currentSymbol: _currentSymbol,
          ),

          const SizedBox(height: 32),

          // Section 2: Carousel Card Section
          const CarouselCardSection(),

          // Add extra space to prevent overflow behind save button
          const SizedBox(height: 80),
        ],
      ),
    );
  }


}
