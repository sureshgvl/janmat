import 'package:flutter/material.dart';

// Constants and utility functions for highlight editing
// Follows Single Responsibility Principle - handles only utility functions

class HighlightConstants {
  static const List<String> bannerStyles = [
    'premium', 'elegant', 'bold', 'minimal'
  ];

  static const List<String> callToActions = [
    'View Profile', 'Vote for Me', 'Learn More', 'Contact Me', 'Join Campaign'
  ];

  static const List<String> priorityLevels = [
    'normal', 'high', 'urgent'
  ];

  static const List<String> englishExamples = [
    'Committed to your development',
    'Your voice matters to me',
    'Together for a better tomorrow',
    'Experience matters for results',
    'Working for real change',
  ];

  static const List<String> marathiExamples = [
    'तुमच्या विकासासाठी वचनबद्ध',
    'तुमचा आवाज मला महत्त्वाचा आहे',
    'एकत्रितपणे उज्ज्वल भविष्यासाठी',
    'परिणामांसाठी अनुभव महत्त्वाचा',
    'खऱ्या बदलासाठी काम करत आहे',
  ];
}

class HighlightHelpers {
  static String getStyleDisplayName(String style) {
    switch (style) {
      case 'premium':
        return 'Premium Blue';
      case 'elegant':
        return 'Elegant Purple';
      case 'bold':
        return 'Bold Red';
      case 'minimal':
        return 'Minimal Grey';
      default:
        return style;
    }
  }

  static String getPriorityDisplayName(String level) {
    switch (level) {
      case 'normal':
        return 'Normal';
      case 'high':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      default:
        return level;
    }
  }

  static List<Color> getBannerGradient(String bannerStyle) {
    switch (bannerStyle) {
      case 'premium':
        return [Colors.blue.shade600, Colors.blue.shade800];
      case 'elegant':
        return [Colors.purple.shade600, Colors.purple.shade800];
      case 'bold':
        return [Colors.red.shade600, Colors.red.shade800];
      case 'minimal':
        return [Colors.grey.shade600, Colors.grey.shade800];
      default:
        return [Colors.blue.shade600, Colors.blue.shade800];
    }
  }

  static String getCallToAction(String? callToAction) {
    return callToAction ?? 'View Profile';
  }

  static void showCustomMessageExamples(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Message Examples'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'English Examples:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                ...HighlightConstants.englishExamples.map(_buildExampleMessage),

                const SizedBox(height: 16),
                const Text(
                  'मराठी उदाहरणे (Marathi Examples):',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 8),
                ...HighlightConstants.marathiExamples.map(_buildExampleMessage),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    '💡 Tip: Keep messages under 100 characters and focus on your key promises or values that resonate with voters.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildExampleMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.lightbulb, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$message"',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}