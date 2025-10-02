import 'package:flutter/material.dart';
import '../highlight_config.dart';
import '../highlight_helpers.dart';

// Call to Action Section Widget
// Follows Single Responsibility Principle - handles only call-to-action selection

class CallToActionSection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<String> onCallToActionChanged;

  const CallToActionSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onCallToActionChanged,
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
            if (isEditing)
              DropdownButtonFormField<String>(
                value: config.callToAction,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: HighlightConstants.callToActions.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(action),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onCallToActionChanged(value);
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
                  'Call to Action: ${config.callToAction}',
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
}