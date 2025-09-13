import 'dart:io';
import 'package:flutter/material.dart';

/// A reusable widget for displaying images with proper aspect ratio handling
class AspectRatioImage extends StatefulWidget {
  final String imageUrl;
  final bool isLocal;
  final BoxFit fit;
  final double? minHeight;
  final double? maxHeight;
  final double? minWidth;
  final double? maxWidth;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Widget? placeholder;
  final Widget? errorWidget;
  final VoidCallback? onTap;
  final bool enableFullScreenView;

  const AspectRatioImage({
    super.key,
    required this.imageUrl,
    this.isLocal = false,
    this.fit = BoxFit.contain,
    this.minHeight = 120,
    this.maxHeight = 250,
    this.minWidth,
    this.maxWidth,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1,
    this.placeholder,
    this.errorWidget,
    this.onTap,
    this.enableFullScreenView = true,
  });

  @override
  State<AspectRatioImage> createState() => _AspectRatioImageState();
}

class _AspectRatioImageState extends State<AspectRatioImage> {
  double _aspectRatio = 4 / 3; // Default aspect ratio
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void didUpdateWidget(AspectRatioImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImageDimensions();
    }
  }

  Future<void> _loadImageDimensions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      double aspectRatio = 4 / 3; // Default

      if (widget.isLocal) {
        // For local images, try to get actual dimensions
        final file = File(widget.imageUrl.replaceFirst('local:', ''));
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          aspectRatio = decodedImage.width / decodedImage.height;
        }
      } else {
        // For network images, we could implement caching here
        // For now, use default aspect ratio
        aspectRatio = 4 / 3;
      }

      if (mounted) {
        setState(() {
          _aspectRatio = aspectRatio;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading image dimensions: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImage() {
    final imageProvider = widget.isLocal
        ? FileImage(File(widget.imageUrl.replaceFirst('local:', '')))
        : NetworkImage(widget.imageUrl);

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.minHeight ?? 120,
        maxHeight: widget.maxHeight ?? 250,
        minWidth: widget.minWidth ?? 0,
        maxWidth: widget.maxWidth ?? double.infinity,
      ),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
            image: _hasError
                ? null
                : DecorationImage(
                    image: imageProvider as ImageProvider,
                    fit: widget.fit,
                  ),
          ),
          child: _hasError
              ? (widget.errorWidget ??
                  const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 48,
                    ),
                  ))
              : (_isLoading
                  ? (widget.placeholder ??
                      const Center(
                        child: CircularProgressIndicator(),
                      ))
                  : null),
        ),
      ),
    );
  }

  void _showFullScreenView() {
    if (!widget.enableFullScreenView) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: widget.isLocal
                ? Image.file(
                    File(widget.imageUrl.replaceFirst('local:', '')),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 48,
                        ),
                      );
                    },
                  )
                : Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 48,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? (widget.enableFullScreenView ? _showFullScreenView : null),
      child: _buildImage(),
    );
  }
}

/// Utility class for aspect ratio calculations
class AspectRatioUtils {
  /// Get default aspect ratio for different content types
  static double getDefaultAspectRatio(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'portrait':
      case 'profile':
        return 3 / 4; // Portrait
      case 'landscape':
      case 'banner':
        return 16 / 9; // Landscape
      case 'square':
        return 1 / 1; // Square
      case 'video':
        return 16 / 9; // Standard video
      default:
        return 4 / 3; // Default
    }
  }

  /// Calculate aspect ratio from width and height
  static double calculateAspectRatio(double width, double height) {
    if (height == 0) return 4 / 3; // Prevent division by zero
    return width / height;
  }

  /// Get responsive constraints based on screen size
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return BoxConstraints(
      minHeight: isSmallScreen ? 100 : 120,
      maxHeight: isSmallScreen ? 200 : 300,
      minWidth: 0,
      maxWidth: double.infinity,
    );
  }
}
