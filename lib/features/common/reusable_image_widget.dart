import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_logger.dart';
import '../../services/media_cache_service.dart';
import 'whatsapp_image_viewer.dart';

/// A reusable widget for displaying images with proper aspect ratio handling and WhatsApp-style full-screen viewer
class ReusableImageWidget extends StatefulWidget {
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
  final String? fullScreenTitle;

  const ReusableImageWidget({
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
    this.fullScreenTitle,
  });

  @override
  State<ReusableImageWidget> createState() => _ReusableImageWidgetState();
}

class _ReusableImageWidgetState extends State<ReusableImageWidget> {
  double _aspectRatio = 4 / 3; // Default aspect ratio
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void didUpdateWidget(ReusableImageWidget oldWidget) {
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
        // PHASE 4 INTEGRATION: Check cache first for network images
        final cacheService = Get.find<MediaCacheService>();
        final cachedFile = cacheService.getFile(widget.imageUrl);

        if (cachedFile != null) {
          // Use cached file for dimensions and loading
          AppLogger.ui('✅ [Image Cache] Using cached file for ${widget.imageUrl}', tag: 'CACHE');
          final bytes = await cachedFile.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          aspectRatio = decodedImage.width / decodedImage.height;
        } else {
          // For uncached images, use default aspect ratio and note for future background caching
          AppLogger.ui('⚠️ [Image Cache] Image not cached: ${widget.imageUrl} - will load from network', tag: 'CACHE');

          // Use default aspect ratio for uncached images
          aspectRatio = 4 / 3;
        }
      }

      if (mounted) {
        setState(() {
          _aspectRatio = aspectRatio;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.ui('Error loading image dimensions: $e', tag: 'IMAGE');
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
                      child: Icon(Icons.error, color: Colors.red, size: 48),
                    ))
              : (_isLoading
                    ? (widget.placeholder ??
                          const Center(child: CircularProgressIndicator()))
                    : null),
        ),
      ),
    );
  }

  void _showFullScreenView() {
    if (!widget.enableFullScreenView) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return WhatsAppImageViewer(
            imageUrl: widget.imageUrl,
            isLocal: widget.isLocal,
            title: widget.fullScreenTitle,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          widget.onTap ??
          (widget.enableFullScreenView ? _showFullScreenView : null),
      child: _buildImage(),
    );
  }
}
