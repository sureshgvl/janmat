import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:vector_math/vector_math_64.dart' as vector_math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../../utils/snackbar_utils.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isImageLoaded = false;
  final TransformationController _transformationController = TransformationController();
  bool _isZoomed = false;
  bool _showControls = true; // Controls visibility for clean screenshots

  // Zoom animation variables
  late AnimationController _zoomAnimationController;
  late Animation<Matrix4> _zoomAnimation;
  Matrix4 _originalMatrix = Matrix4.identity();
  Matrix4 _zoomedMatrix = Matrix4.identity();

  // Swipe to close variables
  double _dragOffset = 0.0;
  bool _isDragging = false;
  static const double _dismissThreshold = 100.0; // Minimum drag distance to dismiss

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isZoomed) return; // Don't allow swipe to close when zoomed
    setState(() {
      _isDragging = true;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isZoomed) return;
    setState(() {
      _dragOffset += details.delta.dy;
      // Prevent dragging upwards beyond the starting point
      if (_dragOffset < 0) {
        _dragOffset = 0;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging || _isZoomed) return;

    if (_dragOffset > _dismissThreshold) {
      // Dismiss the viewer
      Navigator.of(context).pop();
    } else {
      // Reset to original position
      setState(() {
        _dragOffset = 0.0;
        _isDragging = false;
      });
    }
  }

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

    // Initialize zoom animation controller
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Set up zoom animation listener
    _zoomAnimationController.addListener(() {
      if (mounted) {
        _transformationController.value = _zoomAnimation.value;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    // Prevent zoom toggle during swipe gestures
    if (_isDragging) return;

    setState(() {
      _isZoomed = !_isZoomed;

      // Get the screen size to calculate center
      final size = MediaQuery.of(context).size;
      final centerX = size.width / 2;
      final centerY = size.height / 2;

      // Create transformation matrices
      _originalMatrix = Matrix4.identity();
      _zoomedMatrix = Matrix4.identity()
        ..translateByVector3(vector_math.Vector3(centerX, centerY, 0))
        ..scaleByVector3(vector_math.Vector3(2.0, 2.0, 1.0))
        ..translateByVector3(vector_math.Vector3(-centerX, -centerY, 0));

      // Create the animation
      _zoomAnimation = Matrix4Tween(
        begin: _isZoomed ? _originalMatrix : _zoomedMatrix,
        end: _isZoomed ? _zoomedMatrix : _originalMatrix,
      ).animate(CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ));

      // Start the animation
      _zoomAnimationController.forward(from: 0.0);
    });
  }

  Future<void> _shareImage() async {
    try {
      // Show loading indicator
      SnackbarUtils.showScaffoldInfo(context, 'Preparing image for sharing...');

      // Download the image
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      if (kIsWeb) {
        // On web: Download the image directly to user's downloads folder
        final blob = html.Blob([response.bodyBytes], 'image/jpeg');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'shared_image.jpg')
          ..click();

        html.Url.revokeObjectUrl(url);

        SnackbarUtils.showScaffoldInfo(context, 'Image downloaded successfully!');
      } else {
        // On Android/iOS: Use existing mobile sharing logic
        // Get temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = 'shared_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(tempDir.path, fileName);

        // Save image to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Share the image file
        await Share.shareXFiles(
          [XFile(filePath)],
          text: widget.title != null ? 'Check out this ${widget.title}!' : 'Check out this image!',
        );

        // Clean up the temporary file
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      SnackbarUtils.showScaffoldError(context, 'Failed to share image: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate opacity based on drag offset
    final opacity = (1.0 - (_dragOffset / _dismissThreshold)).clamp(0.0, 1.0);
    // Make background transparent when dragging significantly
    final backgroundColor = _isDragging && _dragOffset > 20.0
        ? Colors.transparent
        : Colors.black.withValues(alpha: opacity);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main image viewer with swipe-to-dismiss
          GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
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
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: _dragOffset,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
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
                    Flexible(
                      child: Text(
                        widget.title ?? 'Image',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Placeholder for symmetry
                    const SizedBox(width: 48),
                  ],
                ),
              ),
                ),
              ),
            ),

          // Bottom bar with share button
          Positioned(
            bottom: _dragOffset,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
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
            ),
        ],
      ),
    );
  }
}
