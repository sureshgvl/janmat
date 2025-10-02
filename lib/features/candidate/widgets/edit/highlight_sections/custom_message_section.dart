import 'package:flutter/material.dart';
import '../highlight_config.dart';
import '../highlight_helpers.dart';

// Custom Message Section Widget
// Follows Single Responsibility Principle - handles only custom message input

class CustomMessageSection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<String> onMessageChanged;

  const CustomMessageSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onMessageChanged,
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
                  onPressed: () => HighlightHelpers.showCustomMessageExamples(context),
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
            if (isEditing)
              TextFormField(
                initialValue: config.customMessage,
                maxLength: 100,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g., "Committed to your development"',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: onMessageChanged,
              )
            else if (config.customMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${config.customMessage}"',
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
}