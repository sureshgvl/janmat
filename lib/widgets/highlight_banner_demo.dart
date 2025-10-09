import 'package:flutter/material.dart';
import 'highlight_banner.dart';

/// Demo widget to showcase both HighlightBanner designs
class HighlightBannerDemo extends StatefulWidget {
  const HighlightBannerDemo({super.key});

  @override
  State<HighlightBannerDemo> createState() => _HighlightBannerDemoState();
}

class _HighlightBannerDemoState extends State<HighlightBannerDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlight Banner Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Design info
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highlight Banner Design',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Image at top with overlapping party symbol\n• Candidate name and symbol info\n• Full-width "अधिक पहा" button\n• Clean, modern design',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            // Banner widget
            const HighlightBanner(
              districtId: 'pune',
              bodyId: 'pune_m_cop',
              wardId: 'ward_17',
            ),

            const SizedBox(height: 24),

            // Usage examples
            const Text(
              'Usage Example:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '''
// Highlight Banner
HighlightBanner(
  districtId: 'pune',
  bodyId: 'pune_m_cop',
  wardId: 'ward_17',
)
                ''',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}