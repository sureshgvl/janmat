import 'package:flutter/material.dart';
import '../../../../utils/app_logger.dart';
import '../../models/candidate_model.dart';
import 'highlight_config.dart';
import 'highlight_sections/banner_image_section.dart';

// Main HighlightTabEdit Widget - Refactored for SOLID principles
// Follows Single Responsibility Principle - orchestrates highlight editing UI

class HighlightTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(Map<String, dynamic>) onHighlightChange;

  const HighlightTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onHighlightChange,
  });

  @override
  State<HighlightTabEdit> createState() => HighlightTabEditState();
}

class HighlightTabEditState extends State<HighlightTabEdit> {
  HighlightConfig? _config;
  bool _isUpdatingConfig = false; // Flag to prevent config reset during updates

  @override
  void initState() {
    super.initState();
    _loadHighlight();
  }

  @override
  void didUpdateWidget(HighlightTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.candidate('didUpdateWidget called - old editedData: ${oldWidget.editedData}, new editedData: ${widget.editedData}, _isUpdatingConfig: $_isUpdatingConfig');
    if (!_isUpdatingConfig && (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData)) {
      AppLogger.candidate('didUpdateWidget - data changed, calling _loadHighlight');
      _loadHighlight();
    } else {
      AppLogger.candidate('didUpdateWidget - skipping _loadHighlight (config update in progress)');
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
    // Sync local config changes to controller
    AppLogger.candidate('📤 [Highlight] Syncing config changes to controller');
    _isUpdatingConfig = true;
    _updateHighlight();
    _isUpdatingConfig = false;
    AppLogger.candidate('📤 [Highlight] Config sync completed');
  }

  // Test methods for adding/removing highlights
  Future<void> _addHighlightForSameCandidate(BuildContext context) async {
    try {
      AppLogger.candidate('🧪 [TEST] Adding highlight for same candidate: ${widget.candidateData.candidateId}');

      // Show snackbar to confirm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adding highlight for same candidate (Test Mode)'),
          duration: Duration(seconds: 2),
        ),
      );

      // Note: Actual implementation would call highlight service to create highlight
      // This is just for testing the UI

    } catch (e) {
      AppLogger.candidate('❌ [TEST] Error adding highlight for same candidate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addHighlightForDummyCandidate(BuildContext context) async {
    try {
      AppLogger.candidate('🧪 [TEST] Adding highlight for dummy candidate');

      // Show snackbar to confirm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adding highlight for dummy candidate (Test Mode)'),
          duration: Duration(seconds: 2),
        ),
      );

      // Note: Actual implementation would create a dummy candidate highlight
      // This is just for testing the UI

    } catch (e) {
      AppLogger.candidate('❌ [TEST] Error adding highlight for dummy candidate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeTestHighlight(BuildContext context) async {
    try {
      AppLogger.candidate('🧪 [TEST] Removing test highlight');

      // Show snackbar to confirm
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removing test highlight (Test Mode)'),
          duration: Duration(seconds: 2),
        ),
      );

      // Note: Actual implementation would remove the test highlight
      // This is just for testing the UI

    } catch (e) {
      AppLogger.candidate('❌ [TEST] Error removing test highlight: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure config is initialized
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    AppLogger.candidate('HighlightTabEdit - Build called with _config.bannerStyle: ${_config!.bannerStyle}');
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.view_carousel),
                  text: 'Highlight Banner',
                ),
                Tab(
                  icon: Icon(Icons.grid_view),
                  text: 'Carousel Cards',
                ),
              ],
              labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 14),
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              children: [
                // Highlight Banner Tab
                _buildHighlightBannerTab(),

                // Carousel Cards Tab
                _buildCarouselCardsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightBannerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Highlight Banner Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your home screen banner appearance and settings',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Status Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _config!.enabled ? Icons.visibility : Icons.visibility_off,
                      color: _config!.enabled ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Banner Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _config!.enabled,
                      onChanged: (enabled) {
                        setState(() => _config = _config!.copyWith(enabled: enabled));
                        _isUpdatingConfig = true;
                        _updateHighlight();
                        _isUpdatingConfig = false;
                      },
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _config!.enabled ? 'Banner is active and visible on home screen' : 'Banner is inactive and hidden from home screen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          if (_config!.enabled) ...[
            const SizedBox(height: 24),

            // End Date Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        Text(
                          _config!.endDate != null
                              ? '${_config!.endDate!.day}/${_config!.endDate!.month}/${_config!.endDate!.year}'
                              : 'No end date set',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Banner Image Section
            BannerImageSection(
              key: ValueKey('banner_image_section_${_config!.bannerImageUrl}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              isEditing: widget.isEditing,
              onImageUrlChanged: (imageUrl) {
                setState(() => _config = _config!.copyWith(bannerImageUrl: imageUrl));
                // Local state only - sync on save
              },
            ),

            const SizedBox(height: 24),

            // Banner Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.preview, color: Colors.grey.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Banner Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _config!.bannerImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _config!.bannerImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],

          // Add extra space to prevent overflow behind save button
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCarouselCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎠 Carousel Cards Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure carousel card appearance and behavior',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Placeholder content for carousel cards
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.grid_view,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Carousel Cards Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Carousel card management features will be implemented here.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Add extra space to prevent overflow behind save button
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
