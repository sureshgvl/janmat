import 'package:flutter/material.dart';
import '../../../models/candidate_model.dart';

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
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
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
    _isEnabled = data.extraInfo?.highlight?.enabled ?? false;
  }

  void _updateHighlight() {
    widget.onHighlightChange({'enabled': _isEnabled});
  }

  // Method to upload pending files (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Highlights don't have file uploads, so this is a no-op
    debugPrint('📤 [Highlight] No pending files to upload');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Highlight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Premium Highlight Feature',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enable premium highlight to make your profile stand out in search results and candidate listings. This feature helps voters find you more easily.',
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
                        'Enable Premium Highlight',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      subtitle: Text(
                        _isEnabled
                            ? 'Your profile will be highlighted in search results'
                            : 'Premium highlight is currently disabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isEnabled
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                        ),
                      ),
                      value: _isEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isEnabled = value;
                        });
                        _updateHighlight();
                      },
                      activeColor: Colors.amber.shade600,
                      activeTrackColor: Colors.amber.shade200,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isEnabled
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isEnabled
                              ? Colors.green.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isEnabled ? Icons.check_circle : Icons.cancel,
                            color: _isEnabled
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Premium Highlight: ${_isEnabled ? 'Enabled' : 'Disabled'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _isEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_isEnabled) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Highlight Benefits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem('Higher visibility in search results'),
                    _buildBenefitItem('Featured placement in candidate lists'),
                    _buildBenefitItem('Special highlight badge on profile'),
                    _buildBenefitItem('Priority in voter recommendations'),
                  ],
                ),
              ),
            ],
          ],
        ),
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
