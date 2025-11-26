import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Web-compatible YouTube player
class WebYouTubePlayer extends StatelessWidget {
  final String videoId;
  final double height;

  const WebYouTubePlayer({
    super.key,
    required this.videoId,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    // For web, show thumbnail with play button that opens in new tab
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    final videoUrl = 'https://www.youtube.com/watch?v=$videoId';

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail image
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // Fallback thumbnail
                return Container(
                  color: Colors.grey[800],
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 48,
                  ),
                );
              },
            ),
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(videoUrl))) {
                    // Use platformDefault to keep app active on web
                    await launchUrl(Uri.parse(videoUrl), mode: LaunchMode.platformDefault);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}