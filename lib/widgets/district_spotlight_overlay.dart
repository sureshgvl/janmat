import 'package:flutter/material.dart';
import '../models/district_spotlight_model.dart';

class DistrictSpotlightOverlay extends StatefulWidget {
  final DistrictSpotlight spotlight;
  final VoidCallback onClose;

  const DistrictSpotlightOverlay({
    super.key,
    required this.spotlight,
    required this.onClose,
  });

  @override
  State<DistrictSpotlightOverlay> createState() => _DistrictSpotlightOverlayState();
}

class _DistrictSpotlightOverlayState extends State<DistrictSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Increased for smoother animation
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0, // Start from 0 as requested
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack, // Smooth bounce effect
    ));

    // Start the animation with a delay to ensure smooth rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7), // Dark overlay like Google ads
      child: Stack(
        children: [
          // Animated spotlight content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.95,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Full screen image
                      Builder(
                        builder: (context) {
                          debugPrint('🎯 District Spotlight - Loading image: ${widget.spotlight.fullImage}');
                          debugPrint('🎯 District Spotlight - Party ID: ${widget.spotlight.partyId}');
                          debugPrint('🎯 District Spotlight - Is Active: ${widget.spotlight.isActive}');

                          return Image.network(
                            widget.spotlight.fullImage,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ District Spotlight - Image load error: $error');
                              debugPrint('❌ District Spotlight - Stack trace: $stackTrace');
                              return Container(
                                color: Colors.grey[300],
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Image failed to load\nURL: ${widget.spotlight.fullImage}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Close button at top right (small like Google ads)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () async {
                            // Animate out
                            await _animationController.reverse();
                            widget.onClose();
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
