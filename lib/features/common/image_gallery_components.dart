import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// Image Gallery Viewer Widget for swipeable image viewing
class ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool Function(int) isLocal;

  const ImageGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.isLocal,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {

    super.dispose();
  }
  late int _currentIndex = widget.initialIndex;
  bool _showControls = true;
  double _verticalDrag = 0.0;

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _shareCurrentImage() async {
    final currentImageUrl = widget.images[_currentIndex];
    final isLocalImage = widget.isLocal(_currentIndex);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing image for sharing...')),
      );

      late XFile xFile;

      if (isLocalImage) {
        final localPath = currentImageUrl.replaceFirst('local:', '');
        xFile = XFile(localPath);
      } else {
        final response = await http.get(Uri.parse(currentImageUrl));
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
          tempDir.path,
          'shared_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        xFile = XFile(filePath);
      }

      await Share.shareXFiles([xFile], text: 'Check out this image!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDrag += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_verticalDrag.abs() > 120) {
      Navigator.pop(context);
    } else {
      setState(() {
        _verticalDrag = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double opacity =
        1.0 - (_verticalDrag.abs() / 300).clamp(0.0, 0.8);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _verticalDrag),
              child: PhotoViewGallery.builder(
                itemCount: widget.images.length,
                pageController: PageController(initialPage: widget.initialIndex),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                onPageChanged: (index) =>
                    setState(() => _currentIndex = index),
                builder: (context, index) {
                  final imageUrl = widget.images[index];
                  final isLocal = widget.isLocal(index);

                  return PhotoViewGalleryPageOptions(
                    imageProvider: isLocal
                        ? FileImage(File(imageUrl.replaceFirst('local:', '')))
                        : NetworkImage(imageUrl) as ImageProvider,
                    heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                  );
                },
              ),
            ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          '${_currentIndex + 1}/${widget.images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _shareCurrentImage,
                          icon: const Icon(Icons.share,
                              color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ImageGrid Widget for Hero animations
class ImageGrid extends StatelessWidget {
  final List<String> images;
  final bool Function(int) isLocal;

  const ImageGrid({super.key, required this.images, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final imageUrl = images[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (_, __, ___) => ImageGalleryViewer(
                  images: images,
                  initialIndex: index,
                  isLocal: isLocal,
                ),
              ),
            );
          },
          child: Hero(
            tag: imageUrl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isLocal(index)
                  ? Image.file(
                      File(imageUrl.replaceFirst('local:', '')),
                      fit: BoxFit.cover,
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }
}

// Loading dialog for delete progress
class DeleteProgressDialog extends StatelessWidget {
  final String title;
  final String message;

  const DeleteProgressDialog({
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Row(
        children: [
          const Icon(Icons.delete_forever, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
      actions: null, // No actions - user cannot dismiss
    );
  }
}
