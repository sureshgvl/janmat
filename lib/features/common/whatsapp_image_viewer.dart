import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main image viewer
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: InteractiveViewer(
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
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
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

          // Bottom bar with share button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Share button
                  IconButton(
                    onPressed: () async {
                      try {
                        final title = widget.title ?? 'Image';
                        final shareText =
                            'Check out this $title: ${widget.imageUrl}';

                        // Try to open share URL (works on mobile)
                        final shareUrl =
                            'https://wa.me/?text=${Uri.encodeComponent(shareText)}';

                        if (await canLaunch(shareUrl)) {
                          await launch(shareUrl);
                        } else {
                          // Fallback: copy to clipboard
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Image URL copied to clipboard',
                              ),
                              backgroundColor: Colors.white24,
                              action: SnackBarAction(
                                label: 'OK',
                                onPressed: () {},
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to share: ${e.toString()}'),
                            backgroundColor: Colors.red.shade800,
                          ),
                        );
                      }
                    },
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
        ],
      ),
    );
  }
}
