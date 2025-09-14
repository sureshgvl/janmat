import 'package:flutter/material.dart';

class DemoDataModal extends StatelessWidget {
  final String category;
  final Function(Map<String, dynamic>) onDataSelected;

  const DemoDataModal({
    super.key,
    required this.category,
    required this.onDataSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Use Demo ${category.capitalize()}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category == 'media') ...[
              _buildMediaDemoOptions(context),
            ] else ...[
              const Text('Demo data not available for this category.'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildMediaDemoOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose demo media content:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        _buildDemoOption(
          context,
          'Cleanliness Drive at Ward 23',
          'Demo content with 3 photos, campaign poster, and short video',
          {
            'images': [
              'https://example.com/demo_cleanliness_1.jpg',
              'https://example.com/demo_cleanliness_2.jpg',
              'https://example.com/demo_cleanliness_3.jpg',
            ],
            'videos': [
              'https://example.com/demo_campaign_video.mp4',
            ],
            'youtubeLinks': [
              'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              'https://www.youtube.com/watch?v=oHg5SJYRHA0',
            ],
          },
        ),
        const SizedBox(height: 12),
        _buildDemoOption(
          context,
          'Infrastructure Development',
          'Demo content with construction photos and progress videos',
          {
            'images': [
              'https://example.com/demo_infrastructure_1.jpg',
              'https://example.com/demo_infrastructure_2.jpg',
            ],
            'videos': [
              'https://example.com/demo_progress_video.mp4',
            ],
            'youtubeLinks': [
              'https://www.youtube.com/watch?v=9bZkp7q19f0',
            ],
          },
        ),
        const SizedBox(height: 12),
        _buildDemoOption(
          context,
          'Community Event',
          'Demo content with event photos and social media links',
          {
            'images': [
              'https://example.com/demo_event_1.jpg',
              'https://example.com/demo_event_2.jpg',
              'https://example.com/demo_event_3.jpg',
              'https://example.com/demo_event_4.jpg',
            ],
            'videos': [],
            'youtubeLinks': [
              'https://www.youtube.com/watch?v=jNQXAC9IVRw',
              'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
            ],
          },
        ),
      ],
    );
  }

  Widget _buildDemoOption(
    BuildContext context,
    String title,
    String description,
    Map<String, dynamic> demoData,
  ) {
    return InkWell(
      onTap: () {
        onDataSelected(demoData);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo $title data loaded')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
