import 'package:flutter/material.dart';
import '../../../../../utils/app_logger.dart';
import '../highlight_config.dart';

// Analytics Section Widget
// Follows Single Responsibility Principle - handles only analytics toggle

class AnalyticsSection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<bool> onAnalyticsChanged;

  const AnalyticsSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onAnalyticsChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            if (isEditing)
              SwitchListTile(
                title: const Text('Enable Analytics'),
                subtitle: const Text('View impressions, clicks, and engagement metrics'),
                value: config.showAnalytics,
                onChanged: (value) {
                  AppLogger.candidate('Analytics toggle changed: $value');
                  onAnalyticsChanged(value);
                },
                activeColor: Colors.indigo,
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: config.showAnalytics ? Colors.indigo.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      config.showAnalytics ? Icons.visibility : Icons.visibility_off,
                      color: config.showAnalytics ? Colors.indigo : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analytics: ${config.showAnalytics ? 'Enabled' : 'Disabled'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: config.showAnalytics ? Colors.indigo.shade700 : Colors.grey.shade700,
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

