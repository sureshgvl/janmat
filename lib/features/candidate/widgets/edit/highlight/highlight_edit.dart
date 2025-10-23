import 'package:flutter/material.dart';
import 'package:janmat/features/candidate/controllers/highlights_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:get/get.dart';
import 'package:janmat/features/candidate/models/highlights_model.dart';
import 'package:janmat/utils/app_logger.dart';


// Enhanced Highlight Configuration Model
class HighlightConfig {
  bool enabled;
  String bannerStyle;
  String callToAction;
  String priorityLevel;
  List<String> targetLocations;
  bool showAnalytics;
  String customMessage;

  HighlightConfig({
    this.enabled = false,
    this.bannerStyle = 'premium',
    this.callToAction = 'View Profile',
    this.priorityLevel = 'normal',
    this.targetLocations = const [],
    this.showAnalytics = false,
    this.customMessage = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bannerStyle': bannerStyle,
      'callToAction': callToAction,
      'priorityLevel': priorityLevel,
      'targetLocations': targetLocations,
      'showAnalytics': showAnalytics,
      'customMessage': customMessage,
    };
  }

  factory HighlightConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HighlightConfig();
    return HighlightConfig(
      enabled: json['enabled'] ?? false,
      bannerStyle: json['bannerStyle'] ?? 'premium',
      callToAction: json['callToAction'] ?? 'View Profile',
      priorityLevel: json['priorityLevel'] ?? 'normal',
      targetLocations: List<String>.from(json['targetLocations'] ?? []),
      showAnalytics: json['showAnalytics'] ?? false,
      customMessage: json['customMessage'] ?? '',
    );
  }
}

// Main HighlightTabEdit Widget
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
  final HighlightsController _highlightsController = Get.find<HighlightsController>();
  late HighlightConfig _config;
  bool _isSaving = false;

  // Focus nodes for better keyboard management
  final FocusNode _customMessageFocusNode = FocusNode();

  // Text controller for custom message to prevent keyboard issues
  late TextEditingController _customMessageController;

  final List<String> _bannerStyles = [
    'premium', 'elegant', 'bold', 'minimal'
  ];

  final List<String> _callToActions = [
    'View Profile', 'Vote for Me', 'Learn More', 'Contact Me', 'Join Campaign'
  ];

  final List<String> _priorityLevels = [
    'normal', 'high', 'urgent'
  ];

  @override
  void initState() {
    super.initState();
    _customMessageController = TextEditingController(text: '');
    _loadHighlight();
  }

  @override
  void didUpdateWidget(HighlightTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      _loadHighlight();
    }
  }

  void _loadHighlight() {
    final data = widget.editedData ?? widget.candidateData;
    final highlights = data.highlights ?? [];
    final highlightData = highlights.isNotEmpty ? highlights.first : null;
    _config = HighlightConfig.fromJson(highlightData?.toJson());

    // Update controller text after loading config
    _customMessageController.text = _config.customMessage;
  }

  void _updateHighlight() {
    widget.onHighlightChange(_config.toJson());
  }

  Future<void> _saveHighlights() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.editedData ?? widget.candidateData;

      // Convert HighlightConfig to HighlightData
      final highlightData = _config.enabled ? HighlightData(
        enabled: _config.enabled,
        bannerStyle: _config.bannerStyle,
        callToAction: _config.callToAction,
        priorityLevel: _config.priorityLevel,
        targetLocations: _config.targetLocations,
        showAnalytics: _config.showAnalytics,
        customMessage: _config.customMessage,
      ) : null;

      // Save using the highlights controller
      final success = await _highlightsController.saveHighlightsTab(
        candidateId: data.userId ?? '',
        highlight: highlightData,
        candidateName: data.name,
        photoUrl: data.photo,
        onProgress: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Highlights saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save highlights'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving highlights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Method to upload pending files (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Highlights don't have file uploads, so this is a no-op
    AppLogger.candidate('📤 [Highlight] No pending files to upload');
  }

  @override
  void dispose() {
    _customMessageFocusNode.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = SingleChildScrollView(
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
          _buildEnableSection(),

          if (_config.enabled) ...[
            const SizedBox(height: 24),

            // Banner Style Customization
            _buildBannerStyleSection(),

            const SizedBox(height: 24),

            // Call to Action
            _buildCallToActionSection(),

            const SizedBox(height: 24),

            // Priority Level
            _buildPrioritySection(),

            const SizedBox(height: 24),

            // Custom Message
            _buildCustomMessageSection(),

            const SizedBox(height: 24),

            // Analytics Toggle
            _buildAnalyticsSection(),

            const SizedBox(height: 24),

            // Preview Section
            _buildPreviewSection(),

            // Add extra space to prevent overflow behind save button
            const SizedBox(height: 80),
          ],
        ],
      ),
    );

    // Add Save and Cancel buttons at the bottom
    return Stack(
      children: [
        card,
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveHighlights,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Highlights'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnableSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Enable Premium Highlight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Activate your premium banner on the home screen to increase visibility and attract more voter attention.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              SwitchListTile(
                title: const Text(
                  'Premium Highlight Active',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _config.enabled
                      ? 'Your banner is live on the home screen!'
                      : 'Enable to start attracting voters',
                  style: TextStyle(
                    fontSize: 12,
                    color: _config.enabled ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
                value: _config.enabled,
                onChanged: (value) {
                  setState(() => _config.enabled = value);
                  _updateHighlight();
                },
                activeColor: Colors.amber.shade600,
                activeTrackColor: Colors.amber.shade200,
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _config.enabled ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _config.enabled ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _config.enabled ? Icons.check_circle : Icons.cancel,
                      color: _config.enabled ? Colors.green.shade600 : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Status: ${_config.enabled ? 'Active' : 'Inactive'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _config.enabled ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerStyleSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.palette, color: Colors.purple, size: 24),
                SizedBox(width: 12),
                Text(
                  'Banner Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a visual style that represents your campaign personality',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bannerStyles.map((style) {
                  final isSelected = _config.bannerStyle == style;
                  return ChoiceChip(
                    key: ValueKey('banner_style_$style'),
                    label: Text(_getStyleDisplayName(style)),
                    selected: isSelected,
                    onSelected: (selected) {
                      AppLogger.candidate('Banner style selected: $style, selected: $selected');
                      setState(() => _config.bannerStyle = style);
                      _updateHighlight();
                    },
                    selectedColor: Colors.purple.shade100,
                    backgroundColor: Colors.grey.shade100,
                    checkmarkColor: Colors.purple.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.purple.shade700 : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Selected Style: ${_getStyleDisplayName(_config.bannerStyle)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallToActionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Call to Action',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'What action do you want voters to take?',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              DropdownButtonFormField<String>(
                value: _config.callToAction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _callToActions.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(action),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _config.callToAction = value);
                    _updateHighlight();
                  }
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Call to Action: ${_config.callToAction}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.priority_high, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'How urgently do you want to appear to voters?',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priorityLevels.map((level) {
                  final isSelected = _config.priorityLevel == level;
                  return ChoiceChip(
                    key: ValueKey('priority_level_$level'),
                    label: Text(_getPriorityDisplayName(level)),
                    selected: isSelected,
                    onSelected: (selected) {
                      AppLogger.candidate('Priority level selected: $level, selected: $selected');
                      setState(() => _config.priorityLevel = level);
                      _updateHighlight();
                    },
                    selectedColor: Colors.orange.shade100,
                    backgroundColor: Colors.grey.shade100,
                    checkmarkColor: Colors.orange.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Priority: ${_getPriorityDisplayName(_config.priorityLevel)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMessageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Custom Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.teal),
                  onPressed: _showCustomMessageExamples,
                  tooltip: 'View message examples',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Add a personal message to connect with voters (max 100 characters)',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              TextFormField(
                controller: _customMessageController,
                focusNode: _customMessageFocusNode,
                maxLength: 100,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g., "Committed to your development"',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  // Update config directly without causing rebuild
                  _config.customMessage = value;
                  // Update preview without full rebuild
                  setState(() {});
                },
                onEditingComplete: () {
                  // Update highlight when editing is complete
                  _updateHighlight();
                },
              )
            else if (_config.customMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${_config.customMessage}"',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo, size: 24),
                SizedBox(width: 12),
                Text(
                  'Performance Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Track how your banner performs with voters',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            if (widget.isEditing)
              SwitchListTile(
                title: const Text('Enable Analytics'),
                subtitle: const Text('View impressions, clicks, and engagement metrics'),
                value: _config.showAnalytics,
                onChanged: (value) {
                  AppLogger.candidate('Analytics toggle changed: $value');
                  setState(() => _config.showAnalytics = value);
                  _updateHighlight();
                },
                activeColor: Colors.indigo,
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _config.showAnalytics ? Colors.indigo.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _config.showAnalytics ? Icons.visibility : Icons.visibility_off,
                      color: _config.showAnalytics ? Colors.indigo : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analytics: ${_config.showAnalytics ? 'Enabled' : 'Disabled'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _config.showAnalytics ? Colors.indigo.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.preview, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Banner Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: _getBannerGradient(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '⭐ HIGHLIGHT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _getPriorityDisplayName(_config.priorityLevel),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Candidate info
                        Text(
                          widget.candidateData.name ?? 'Candidate Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          widget.candidateData.party ?? 'Party Name',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),

                        if (_config.customMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"${_config.customMessage}"',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const Spacer(),

                        // CTA Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _config.callToAction,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is how your banner will appear on the home screen',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getBannerGradient() {
    switch (_config.bannerStyle) {
      case 'premium':
        return [Colors.blue.shade600, Colors.blue.shade800];
      case 'elegant':
        return [Colors.purple.shade600, Colors.purple.shade800];
      case 'bold':
        return [Colors.red.shade600, Colors.red.shade800];
      case 'minimal':
        return [Colors.grey.shade600, Colors.grey.shade800];
      default:
        return [Colors.blue.shade600, Colors.blue.shade800];
    }
  }

  String _getStyleDisplayName(String style) {
    switch (style) {
      case 'premium':
        return 'Premium Blue';
      case 'elegant':
        return 'Elegant Purple';
      case 'bold':
        return 'Bold Red';
      case 'minimal':
        return 'Minimal Grey';
      default:
        return style;
    }
  }

  String _getPriorityDisplayName(String level) {
    switch (level) {
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      default:
        return level;
    }
  }

  void _showCustomMessageExamples() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Message Examples'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'English Examples:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                _buildExampleMessage('"Committed to your development"'),
                _buildExampleMessage('"Your voice matters to me"'),
                _buildExampleMessage('"Together for a better tomorrow"'),
                _buildExampleMessage('"Experience matters for results"'),
                _buildExampleMessage('"Working for real change"'),

                const SizedBox(height: 16),
                const Text(
                  'मराठी उदाहरणे (Marathi Examples):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                _buildExampleMessage('"तुमच्या विकासासाठी वचनबद्ध"'),
                _buildExampleMessage('"तुमचा आवाज मला महत्त्वाचा आहे"'),
                _buildExampleMessage('"एकत्रितपणे उज्ज्वल भविष्यासाठी"'),
                _buildExampleMessage('"परिणामांसाठी अनुभव महत्त्वाचा"'),
                _buildExampleMessage('"खऱ्या बदलासाठी काम करत आहे"'),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    '💡 Tip: Keep messages under 100 characters and focus on your key promises or values that resonate with voters.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExampleMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.lightbulb, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              benefit,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}

