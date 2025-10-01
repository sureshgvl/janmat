import 'package:flutter/material.dart';
import 'manifesto_resources_improved.dart';

/// Demo screen to showcase the improved manifesto resources UI
class ManifestoResourcesDemo extends StatelessWidget {
  const ManifestoResourcesDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifesto Resources - Improved UI'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo with all resources available
            const Text(
              '📋 With All Resources Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ManifestoResourcesImproved(
              pdfUrl: 'https://example.com/manifesto.pdf',
              imageUrl: 'https://picsum.photos/400/300?random=1',
              videoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
            ),

            const SizedBox(height: 32),

            // Demo with missing resources
            const Text(
              '📋 With Missing Resources',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ManifestoResourcesImproved(
              pdfUrl: null, // No PDF
              imageUrl: 'https://picsum.photos/400/300?random=2',
              videoUrl: null, // No video
            ),

            const SizedBox(height: 32),

            // Demo with no resources
            const Text(
              '📋 No Resources Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ManifestoResourcesImproved(
              pdfUrl: null,
              imageUrl: null,
              videoUrl: null,
            ),

            const SizedBox(height: 32),

            // Feature highlights
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ Key Improvements',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('Modern card-based design with gradients and shadows'),
                  _buildFeatureItem('Consistent 3-column horizontal layout'),
                  _buildFeatureItem('Interactive hover effects and animations'),
                  _buildFeatureItem('File size indicators and metadata'),
                  _buildFeatureItem('Video duration badges (≤2 min limit)'),
                  _buildFeatureItem('Image thumbnails with full-screen viewer'),
                  _buildFeatureItem('PDF download with progress indication'),
                  _buildFeatureItem('Offline/sync status indicators'),
                  _buildFeatureItem('Responsive design for mobile devices'),
                  _buildFeatureItem('Accessibility improvements'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}