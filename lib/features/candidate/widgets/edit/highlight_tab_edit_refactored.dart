import 'package:flutter/material.dart';
import '../../../../utils/app_logger.dart';
import '../../models/candidate_model.dart';
import 'highlight_config.dart';
import 'highlight_sections/enable_section.dart';
import 'highlight_sections/banner_style_section.dart';
import 'highlight_sections/call_to_action_section.dart';
import 'highlight_sections/priority_section.dart';
import 'highlight_sections/custom_message_section.dart';
import 'highlight_sections/analytics_section.dart';
import 'highlight_sections/preview_section.dart';

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
    final highlightData = data.extraInfo?.highlight;
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
      } else {
        AppLogger.candidate('_loadHighlight - no external changes, keeping current config');
      }
    } else {
      // First time loading or during our own updates
      _config = HighlightConfig.fromJson(highlightData?.toJson());
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

  @override
  Widget build(BuildContext context) {
    // Ensure config is initialized
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    AppLogger.candidate('HighlightTabEdit - Build called with _config.bannerStyle: ${_config!.bannerStyle}');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            '🏆 Premium Highlight Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customize your home screen banner to attract more voters',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Enable/Disable Toggle
          EnableSection(
            key: const ValueKey('enable_section'),
            config: _config!,
            isEditing: widget.isEditing,
            onEnabledChanged: (enabled) {
              setState(() => _config = _config!.copyWith(enabled: enabled));
              _isUpdatingConfig = true;
              _updateHighlight();
              _isUpdatingConfig = false;
            },
          ),

          if (_config!.enabled) ...[
            const SizedBox(height: 24),

            // Banner Style Customization
            Builder(
              builder: (context) {
                AppLogger.candidate('Main widget - Building BannerStyleSection with config.bannerStyle: ${_config!.bannerStyle}');
                return BannerStyleSection(
                  key: ValueKey('banner_style_section_${_config!.bannerStyle}_${DateTime.now().millisecondsSinceEpoch}'),
                  config: _config!,
                  isEditing: widget.isEditing,
                  onStyleChanged: (style) {
                    AppLogger.candidate('Main widget - Banner style callback: $style, current config: ${_config!.bannerStyle}');
                    setState(() {
                      _config = _config!.copyWith(bannerStyle: style);
                      AppLogger.candidate('Main widget - Inside setState, _config.bannerStyle: ${_config!.bannerStyle}');
                    });
                    AppLogger.candidate('Main widget - After setState, _config.bannerStyle: ${_config!.bannerStyle}');
                    // Don't update controller for individual changes - only on save
                    // This prevents the broken controller update from interfering with UI
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Call to Action
            CallToActionSection(
              key: ValueKey('call_to_action_section_${_config!.callToAction}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              isEditing: widget.isEditing,
              onCallToActionChanged: (action) {
                setState(() => _config = _config!.copyWith(callToAction: action));
                // Local state only - sync on save
              },
            ),

            const SizedBox(height: 24),

            // Priority Level
            PrioritySection(
              key: ValueKey('priority_section_${_config!.priorityLevel}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              isEditing: widget.isEditing,
              onPriorityChanged: (priority) {
                AppLogger.candidate('Priority level selected: $priority');
                setState(() => _config = _config!.copyWith(priorityLevel: priority));
                // Local state only - sync on save
              },
            ),

            const SizedBox(height: 24),

            // Custom Message
            CustomMessageSection(
              key: ValueKey('custom_message_section_${_config!.customMessage.hashCode}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              isEditing: widget.isEditing,
              onMessageChanged: (message) {
                setState(() => _config = _config!.copyWith(customMessage: message));
                // Local state only - sync on save
              },
            ),

            const SizedBox(height: 24),

            // Analytics Toggle
            AnalyticsSection(
              key: ValueKey('analytics_section_${_config!.showAnalytics}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              isEditing: widget.isEditing,
              onAnalyticsChanged: (enabled) {
                AppLogger.candidate('Analytics toggle changed: $enabled');
                setState(() => _config = _config!.copyWith(showAnalytics: enabled));
                // Local state only - sync on save
              },
            ),

            const SizedBox(height: 24),

            // Preview Section
            PreviewSection(
              key: ValueKey('preview_section_${_config!.bannerStyle}_${_config!.callToAction}_${_config!.priorityLevel}_${DateTime.now().millisecondsSinceEpoch}'),
              config: _config!,
              candidate: widget.candidateData,
            ),
          ],

          // Add extra space to prevent overflow behind save button
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

