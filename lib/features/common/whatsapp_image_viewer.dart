import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// WhatsApp-style full-screen image viewer with interactive features
class WhatsAppImageViewer extends StatefulWidget {
  final String imageUrl;
  final bool isLocal;
  final String? title;

  const WhatsAppImageViewer({
    super.key,
    required this.imageUrl,
    this.isLocal = false,
    this.title,
  });

  @override
  State<WhatsAppImageViewer> createState() => _WhatsAppImageViewerState();
}

class _WhatsAppImageViewerState extends State<WhatsAppImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isImageLoaded = false;
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;
  bool _showControls = true; // Controls visibility for clean screenshots

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      if (_isZoomed) {
        // Zoom to 2x scale
        _transformationController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
      } else {
        // Reset to original scale
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  Future<void> _shareImage() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing image for sharing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Download the image to a temporary file
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'shared_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(tempDir.path, fileName);

      // Save image to file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Share the image file
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: widget.title != null ? 'Check out this ${widget.title}!' : 'Check out this image!',
      );

      // Clean up the temporary file
      if (await file.exists()) {
        await file.delete();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share image: ${e.toString()}'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image viewer
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            onDoubleTap: _toggleZoom,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: widget.isLocal
                      ? Image.file(
                          File(widget.imageUrl.replaceFirst('local:', '')),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isImageLoaded) {
                                  setState(() => _isImageLoaded = true);
                                }
                              });
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: child,
                              );
                            }
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white70,
                                      size: 48,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Visibility(
              visible: _showControls,
              child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // Title
                  Text(
                    widget.title ?? 'Image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),
              ),
            ),

          // Bottom bar with share button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Visibility(
              visible: _showControls,
              child: Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Share button
                  IconButton(
                    onPressed: _shareImage,
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Share Image',
                  ),
                ],
              ),
            ),
              ),
            ),
        ],
      ),
    );
  }
}

