import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class AnalyticsTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String, dynamic) onAnalyticsChange;

  const AnalyticsTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onAnalyticsChange,
  });

  @override
  State<AnalyticsTabEdit> createState() => _AnalyticsTabEditState();
}

class _AnalyticsTabEditState extends State<AnalyticsTabEdit> {
  late TextEditingController _profileViewsController;
  late TextEditingController _manifestoViewsController;
  late TextEditingController _engagementRateController;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    final analytics = data.extraInfo?.analytics;

    _profileViewsController = TextEditingController(
      text: analytics?.profileViews?.toString() ?? '0',
    );
    _manifestoViewsController = TextEditingController(
      text: analytics?.manifestoViews?.toString() ?? '0',
    );
    _engagementRateController = TextEditingController(
      text: analytics?.engagementRate?.toStringAsFixed(1) ?? '0.0',
    );
  }

  @override
  void didUpdateWidget(AnalyticsTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final analytics = data.extraInfo?.analytics;

      _profileViewsController.text = analytics?.profileViews?.toString() ?? '0';
      _manifestoViewsController.text =
          analytics?.manifestoViews?.toString() ?? '0';
      _engagementRateController.text =
          analytics?.engagementRate?.toStringAsFixed(1) ?? '0.0';
    }
  }

  @override
  void dispose() {
    _profileViewsController.dispose();
    _manifestoViewsController.dispose();
    _engagementRateController.dispose();
    super.dispose();
  }

  void _updateProfileViews(String value) {
    final views = int.tryParse(value) ?? 0;
    widget.onAnalyticsChange('profileViews', views);
  }

  void _updateManifestoViews(String value) {
    final views = int.tryParse(value) ?? 0;
    widget.onAnalyticsChange('manifestoViews', views);
  }

  void _updateEngagementRate(String value) {
    final rate = double.tryParse(value) ?? 0.0;
    widget.onAnalyticsChange('engagementRate', rate);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;
    final analytics = data.extraInfo?.analytics;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure analytics tracking for your candidate profile',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // Profile Views
            TextFormField(
              controller: _profileViewsController,
              decoration: const InputDecoration(
                labelText: 'Profile Views',
                border: OutlineInputBorder(),
                hintText: 'Number of profile views',
                prefixIcon: Icon(Icons.visibility),
              ),
              keyboardType: TextInputType.number,
              onChanged: _updateProfileViews,
            ),
            const SizedBox(height: 16),

            // Manifesto Views
            TextFormField(
              controller: _manifestoViewsController,
              decoration: const InputDecoration(
                labelText: 'Manifesto Views',
                border: OutlineInputBorder(),
                hintText: 'Number of manifesto views',
                prefixIcon: Icon(Icons.description),
              ),
              keyboardType: TextInputType.number,
              onChanged: _updateManifestoViews,
            ),
            const SizedBox(height: 16),

            // Engagement Rate
            TextFormField(
              controller: _engagementRateController,
              decoration: const InputDecoration(
                labelText: 'Engagement Rate (%)',
                border: OutlineInputBorder(),
                hintText: 'Engagement rate as percentage',
                prefixIcon: Icon(Icons.trending_up),
                suffixText: '%',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: _updateEngagementRate,
            ),
            const SizedBox(height: 16),

            // Current Analytics Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Analytics Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Views',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${analytics?.profileViews ?? 0}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manifesto Views',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${analytics?.manifestoViews ?? 0}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Engagement',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${analytics?.engagementRate?.toStringAsFixed(1) ?? '0.0'}%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Analytics Features Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analytics Features',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Track profile and manifesto views\n• Monitor voter engagement\n• Analyze follower growth trends\n• View demographic insights',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.5,
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
}

