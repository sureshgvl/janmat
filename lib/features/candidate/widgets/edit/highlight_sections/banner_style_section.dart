import 'package:flutter/material.dart';
import '../highlight_config.dart';
import '../highlight_helpers.dart';

// Banner Style Section Widget
// Follows Single Responsibility Principle - handles only banner style selection

class BannerStyleSection extends StatelessWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<String> onStyleChanged;

  const BannerStyleSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onStyleChanged,
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
            if (isEditing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HighlightConstants.bannerStyles.map((style) {
                  final isSelected = config.bannerStyle == style;
                  return ChoiceChip(
                    key: ValueKey('banner_style_$style'),
                    label: Text(HighlightHelpers.getStyleDisplayName(style)),
                    selected: isSelected,
                    onSelected: (selected) {
                      debugPrint('Banner style selected: $style, selected: $selected');
                      if (selected) {
                        onStyleChanged(style);
                      }
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
                  'Selected Style: ${HighlightHelpers.getStyleDisplayName(config.bannerStyle)}',
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