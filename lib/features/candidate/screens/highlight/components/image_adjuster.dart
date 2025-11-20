import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageAdjuster extends StatefulWidget {
  final String imagePath;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ImageAdjuster({
    super.key,
    required this.imagePath,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ImageAdjuster> createState() => _ImageAdjusterState();
}

class _ImageAdjusterState extends State<ImageAdjuster> {
  final TransformationController _transformationController = TransformationController();

  // Banner preview dimensions - exact same as actual banner
  static const double bannerHeight = 180.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.crop, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Crop Banner Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Move and zoom the image. The transparent frame shows exactly what will be displayed in your banner.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Image cropping area
          Container(
            height: bannerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Full background image - larger than frame for adjustment
                  InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: _buildBackgroundImage(),
                  ),

                  // Transparent frame overlay - shows exact banner dimensions
                  Container(
                    width: double.infinity,
                    height: bannerHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(0), // Square corners for frame
                    ),
                    child: Stack(
                      children: [
                        // Semi-transparent overlay outside the frame
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),

                        // Clear frame area (punch-through)
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: bannerHeight,
                            color: Colors.transparent,
                            child: Stack(
                              children: [
                                // Party symbol placeholder (top-left)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.amber.withValues(alpha: 0.8),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 25,
                                    ),
                                  ),
                                ),

                                // Text area placeholder (bottom)
                                Positioned(
                                  bottom: 12,
                                  left: 70, // Leave space for party symbol
                                  right: 70, // Leave space for arrow button
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.blue.withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Candidate Name',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Arrow button placeholder (top-right)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.withValues(alpha: 0.8),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Control hint
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  kIsWeb ? Icons.mouse : Icons.touch_app,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  kIsWeb
                      ? 'Use mouse to drag and scroll to zoom'
                      : 'Use finger to drag and pinch to zoom',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons - full width, no overlap issues
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirm Crop'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final Widget imageWidget;

    // On web, use Image.network for blob URLs
    if (kIsWeb && widget.imagePath.startsWith('blob:')) {
      imageWidget = Image.network(
        widget.imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
      );
    }
    // On mobile/desktop, use Image.file for local file paths
    else if (!kIsWeb) {
      imageWidget = Image.file(
        File(widget.imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
      );
    }
    // Fallback
    else {
      imageWidget = Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }

    // Make image much larger than the frame so user can adjust position/zoom
    return SizedBox(
      width: MediaQuery.of(context).size.width * 2, // Much larger than frame
      height: MediaQuery.of(context).size.width * 2, // Square aspect ratio
      child: imageWidget,
    );
  }
}
