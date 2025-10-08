import 'package:flutter/material.dart';
import '../../../../../utils/app_logger.dart';
import '../highlight_config.dart';
import '../highlight_helpers.dart';

// Priority Level Section Widget
// Follows Single Responsibility Principle - handles only priority level selection

class PrioritySection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<String> onPriorityChanged;

  const PrioritySection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onPriorityChanged,
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
            if (isEditing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HighlightConstants.priorityLevels.map((level) {
                  final isSelected = config.priorityLevel == level;
                  return ChoiceChip(
                    key: ValueKey('priority_level_$level'),
                    label: Text(HighlightHelpers.getPriorityDisplayName(level)),
                    selected: isSelected,
                    onSelected: (selected) {
                      AppLogger.candidate('Priority level selected: $level, selected: $selected');
                      if (selected) {
                        onPriorityChanged(level);
                      }
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
                  'Priority: ${HighlightHelpers.getPriorityDisplayName(config.priorityLevel)}',
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

