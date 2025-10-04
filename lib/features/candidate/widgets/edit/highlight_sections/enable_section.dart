import 'package:flutter/material.dart';
import '../highlight_config.dart';

// Enable/Disable Section Widget
// Follows Single Responsibility Principle - handles only enable/disable functionality

class EnableSection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<bool> onEnabledChanged;

  const EnableSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onEnabledChanged,
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
            if (isEditing)
              SwitchListTile(
                title: const Text(
                  'Premium Highlight Active',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  config.enabled
                      ? 'Your banner is live on the home screen!'
                      : 'Enable to start attracting voters',
                  style: TextStyle(
                    fontSize: 12,
                    color: config.enabled ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
                value: config.enabled,
                onChanged: onEnabledChanged,
                activeColor: Colors.amber.shade600,
                activeTrackColor: Colors.amber.shade200,
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: config.enabled ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: config.enabled ? Colors.green.shade200 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      config.enabled ? Icons.check_circle : Icons.cancel,
                      color: config.enabled ? Colors.green.shade600 : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Status: ${config.enabled ? 'Active' : 'Inactive'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: config.enabled ? Colors.green.shade700 : Colors.grey.shade700,
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

