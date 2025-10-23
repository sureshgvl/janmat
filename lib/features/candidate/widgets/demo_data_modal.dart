import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/demo_data_service.dart';
import '../models/achievements_model.dart';

class DemoDataModal extends StatefulWidget {
  final String category;
  final Function(dynamic) onDataSelected;

  const DemoDataModal({
    super.key,
    required this.category,
    required this.onDataSelected,
  });

  @override
  State<DemoDataModal> createState() => _DemoDataModalState();
}

class _DemoDataModalState extends State<DemoDataModal> {
  String selectedLanguage = 'en';
  String? selectedType;
  dynamic previewText;

  @override
  void initState() {
    super.initState();
    // Default to first available type
    final types = DemoDataService.getAvailableTypes(widget.category);
    if (types.isNotEmpty) {
      selectedType = types.first;
      _updatePreview();
    }
  }

  void _updatePreview() {
    if (selectedType != null) {
      setState(() {
        previewText = DemoDataService.getDemoData(
          widget.category,
          selectedType!,
          selectedLanguage,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = DemoDataService.getAvailableTypes(widget.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width - 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Demo ${widget.category.capitalizeFirst}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language Selection
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'en';
                                _updatePreview();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedLanguage == 'en'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                              foregroundColor: selectedLanguage == 'en'
                                  ? Colors.white
                                  : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'English',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'mr';
                                _updatePreview();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedLanguage == 'mr'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[200],
                              foregroundColor: selectedLanguage == 'mr'
                                  ? Colors.white
                                  : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'मराठी',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Template Selection
                    Row(
                      children: types.map((type) {
                        final isSelected = selectedType == type;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedType = type;
                                _updatePreview();
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1)
                                    : Colors.grey[100],
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  DemoDataService.getTypeDisplayName(type),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Preview
                    if (previewText != null) ...[
                      const Text(
                        'Preview:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child:
                              widget.category == 'achievements' &&
                                  previewText is List
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (previewText as List).map<Widget>((
                                    item,
                                  ) {
                                    if (item is Achievement) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SelectableText(
                                              item.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SelectableText(
                                              item.description,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            SelectableText(
                                              'Year: ${item.year}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }).toList(),
                                )
                              : widget.category == 'manifesto'
                              ? MarkdownBody(
                                  data: previewText?.toString() ?? '',
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                    strong: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      height: 1.5,
                                    ),
                                  ),
                                  selectable: true,
                                )
                              : SelectableText(
                                  previewText?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '* select text to copy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

