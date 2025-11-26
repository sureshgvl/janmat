import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/common/whatsapp_image_viewer.dart';
import 'package:janmat/features/common/reusable_video_widget.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'youtube_player.dart';

// Video content builder
class VideoContentWidget extends StatelessWidget {
  final MediaItem item;

  const VideoContentWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.videos.map((videoUrl) {
        final videoIndex = item.videos.indexOf(videoUrl);
        final videoId = _extractYouTubeVideoId(videoUrl);

        if (videoId != null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? WebYouTubePlayer(videoId: videoId, height: 180)
                        : const SizedBox.shrink(), // Mobile would use youtube_player_flutter
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Video ${videoIndex + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          // Handle fullscreen video
                        },
                        icon: const Icon(Icons.fullscreen, size: 12),
                        label: const Text('Fullscreen'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Handle non-YouTube videos
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: VideoPreviewWidget(
              videoUrl: videoUrl,
              title: '${item.title} - Video ${videoIndex + 1}',
              aspectRatio: 16 / 9,
            ),
          );
        }
      }).toList(),
    );
  }

  // Helper function to extract YouTube video ID from URL
  String? _extractYouTubeVideoId(String url) {
    final RegExp youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = youtubeRegex.firstMatch(url);
    return match?.group(1);
  }
}

// YouTube content builder
class YouTubeContentWidget extends StatelessWidget {
  final MediaItem item;

  const YouTubeContentWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.youtubeLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.youtubeLinks.map((youtubeUrl) {
        final linkIndex = item.youtubeLinks.indexOf(youtubeUrl);
        final videoId = _extractYouTubeVideoId(youtubeUrl);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // YouTube video preview
              if (videoId != null) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: WebYouTubePlayer(videoId: videoId, height: 120),
                  ),
                ),
              ],
              // Link details
              InkWell(
                onTap: () async {
                  // Handle YouTube link tap
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        color: Colors.red.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YouTube Video ${linkIndex + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              youtubeUrl,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.red.shade600,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper function to extract YouTube video ID from URL
  String? _extractYouTubeVideoId(String url) {
    final RegExp youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = youtubeRegex.firstMatch(url);
    return match?.group(1);
  }
}

// Facebook-style image layout
class FacebookStyleImageLayout extends StatelessWidget {
  final List<String> images;
  final Function(List<String>, int) onImageTap;

  const FacebookStyleImageLayout({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;

    if (imageCount == 1) {
      // Single image - full width
      return GestureDetector(
        onTap: () => onImageTap(images, 0),
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ReusableImageWidget(
              imageUrl: images[0],
              fit: BoxFit.cover,
              borderColor: Colors.transparent,
              enableFullScreenView: false,
            ),
          ),
        ),
      );
    } else if (imageCount == 2) {
      // Two images - side by side
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onImageTap(images, 0),
              child: Container(
                height: 200,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ReusableImageWidget(
                    imageUrl: images[0],
                    fit: BoxFit.cover,
                    borderColor: Colors.transparent,
                    enableFullScreenView: false,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onImageTap(images, 1),
              child: Container(
                height: 200,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ReusableImageWidget(
                    imageUrl: images[1],
                    fit: BoxFit.cover,
                    borderColor: Colors.transparent,
                    enableFullScreenView: false,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (imageCount == 3) {
      // Three images - first large, other two side by side below
      return Column(
        children: [
          // First image (large)
          GestureDetector(
            onTap: () => onImageTap(images, 0),
            child: Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ReusableImageWidget(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  borderColor: Colors.transparent,
                  enableFullScreenView: false,
                ),
              ),
            ),
          ),
          // Second and third images (side by side)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(images, 1),
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ReusableImageWidget(
                        imageUrl: images[1],
                        fit: BoxFit.cover,
                        borderColor: Colors.transparent,
                        enableFullScreenView: false,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onImageTap(images, 2),
                  child: Container(
                    height: 150,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ReusableImageWidget(
                        imageUrl: images[2],
                        fit: BoxFit.cover,
                        borderColor: Colors.transparent,
                        enableFullScreenView: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 4+ images - show all images in responsive grid (up to 6 images for now)
      final int maxToShow = imageCount > 6
          ? 6
          : imageCount; // Limit to 6 images max for UI
      final int gridColumns = maxToShow <= 4
          ? 2
          : 3; // 2 columns for <=4 images, 3 for 5-6

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.0,
        ),
        itemCount: maxToShow,
        itemBuilder: (context, index) {
          if (imageCount > 6 && index == 5) {
            // Last item when >6 images - show count overlay
            final remainingCount = imageCount - 5;
            return GestureDetector(
              onTap: () => _showAllImages(context, images),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ReusableImageWidget(
                        imageUrl: images[5],
                        fit: BoxFit.cover,
                        borderColor: Colors.transparent,
                        enableFullScreenView: false,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // Regular image
            final imageUrl = images[index];
            return GestureDetector(
              onTap: () => onImageTap(images, index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ReusableImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    borderColor: Colors.transparent,
                    enableFullScreenView: false,
                  ),
                ),
              ),
            );
          }
        },
      );
    }
  }

  void _showAllImages(BuildContext context, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${images.length} Photos',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Grid View
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              barrierColor: Colors.black,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return WhatsAppImageViewer(
                                  imageUrl: images[index],
                                  title: 'Photo ${index + 1}',
                                );
                              },
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ReusableImageWidget(
                              imageUrl: images[index],
                              fit: BoxFit.cover,
                              borderColor: Colors.transparent,
                              enableFullScreenView: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}