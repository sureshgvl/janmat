import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/candidate_model.dart';
import '../../../common/video_player_screen.dart';
import '../../../common/reusable_image_widget.dart';
import '../../../common/reusable_video_widget.dart';
import '../../../common/whatsapp_image_viewer.dart';
import '../../../../utils/app_logger.dart';

// Media Item Model (same as in edit widget)
class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  Map<String, int> likes; // Track likes for each media item

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    Map<String, int>? likes,
  }) : date = date ?? DateTime.now().toIso8601String().split('T')[0],
       images = images ?? [],
       videos = videos ?? [],
       youtubeLinks = youtubeLinks ?? [],
       likes = likes ?? {};

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] ?? '',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      likes: Map<String, int>.from(json['likes'] ?? {}),
    );
  }
}

class MediaTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;

  const MediaTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
  });

  @override
  State<MediaTabView> createState() => _MediaTabViewState();
}

class _MediaTabViewState extends State<MediaTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Get media items from candidate data
    List<MediaItem> mediaItems = [];
    try {
      final media = widget.candidate.extraInfo?.media;
      if (media != null && media.isNotEmpty) {
        // Handle current format - List of media items (from edit component)
        final List<dynamic> mediaList = media;
        mediaItems = mediaList.whereType<Map<String, dynamic>>().map((item) {
          return MediaItem.fromJson(item);
        }).toList();
      }
    } catch (e) {
      AppLogger.candidateError('Error parsing media data: $e');
      mediaItems = [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Items
          if (mediaItems.isNotEmpty) ...[
            ...mediaItems.map((item) => _buildMediaItemCard(item)),
          ] else ...[
            // No media message
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No media available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photos and videos will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],

          // Social YouTube Channel Section (if exists)
          if (widget.candidate.contact.socialLinks != null &&
              widget.candidate.contact.socialLinks!.containsKey('YouTube')) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YouTube Channel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final youtubeUrl =
                          widget.candidate.contact.socialLinks!['YouTube']!;
                      if (await canLaunch(youtubeUrl)) {
                        await launch(youtubeUrl);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: Colors.red.shade600,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Official YouTube Channel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Watch videos and updates',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.red.shade600,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMediaItemCard(MediaItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isNotEmpty ? item.title : 'Untitled Media',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${item.date}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.event, color: Colors.blue.shade600, size: 24),
                ],
              ),
              const SizedBox(height: 20),

              // Images Section
              if (item.images.isNotEmpty) ...[
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        3, // Changed from 2 to 3 to show more photos
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: item.images.length,
                  itemBuilder: (context, index) {
                    final photoUrl = item.images[index];
                    final photoLikes = item.likes['image_$index'] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        // Show full screen image viewer
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            barrierColor: Colors.black,
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return WhatsAppImageViewer(
                                imageUrl: photoUrl,
                                title: '${item.title} - Photo ${index + 1}',
                              );
                            },
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
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
                                imageUrl: photoUrl,
                                fit: BoxFit.cover,
                                minHeight: 100,
                                maxHeight: 100,
                                borderColor: Colors.transparent,
                                enableFullScreenView: false, // Disable built-in full screen
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Like button
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _toggleLike(item, 'image_$index'),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                size: 14,
                                                color: photoLikes > 0
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                photoLikes.toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Photo number
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Photo ${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
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
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Videos Section
              if (item.videos.isNotEmpty) ...[
                const Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 12),
                ...item.videos.map((videoUrl) {
                  final videoIndex = item.videos.indexOf(videoUrl);
                  final videoLikes = item.likes['video_$videoIndex'] ?? 0;
                  final videoId = YoutubePlayer.convertUrlToId(videoUrl);
                  if (videoId != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: YoutubePlayer(
                                    controller: YoutubePlayerController(
                                      initialVideoId: videoId,
                                      flags: const YoutubePlayerFlags(
                                        autoPlay: false,
                                        mute: false,
                                        enableCaption: true,
                                        captionLanguage: 'en',
                                        forceHD: false,
                                        loop: false,
                                        controlsVisibleAtStart: true,
                                      ),
                                    ),
                                    showVideoProgressIndicator: true,
                                    progressIndicatorColor: Colors.red,
                                    progressColors: const ProgressBarColors(
                                      playedColor: Colors.red,
                                      handleColor: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                              // Like button for video
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      _toggleLike(item, 'video_$videoIndex'),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          size: 16,
                                          color: videoLikes > 0
                                              ? Colors.red
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          videoLikes.toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
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
                                onPressed: () {
                                  Get.to(
                                    () => VideoPlayerScreen(
                                      videoUrl: videoUrl,
                                      title:
                                          '${item.title} - Video ${videoIndex + 1}',
                                    ),
                                  );
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
                        ],
                      ),
                    );
                  } else {
                    // Handle non-YouTube videos
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          VideoPreviewWidget(
                            videoUrl: videoUrl,
                            title: '${item.title} - Video ${videoIndex + 1}',
                            aspectRatio: 16 / 9,
                          ),
                          // Like button for non-YouTube video
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  _toggleLike(item, 'video_$videoIndex'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: videoLikes > 0
                                          ? Colors.red
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      videoLikes.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
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
                }),
                const SizedBox(height: 20),
              ],

              // YouTube Links Section
              if (item.youtubeLinks.isNotEmpty) ...[
                const Text(
                  'YouTube Links',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 12),
                ...item.youtubeLinks.map((youtubeUrl) {
                  final linkIndex = item.youtubeLinks.indexOf(youtubeUrl);
                  final youtubeLikes = item.likes['youtube_$linkIndex'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          // YouTube video preview (if it's a valid YouTube URL)
                          if (YoutubePlayer.convertUrlToId(youtubeUrl) !=
                              null) ...[
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.red.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                                child: Stack(
                                  children: [
                                    YoutubePlayer(
                                      controller: YoutubePlayerController(
                                        initialVideoId:
                                            YoutubePlayer.convertUrlToId(
                                              youtubeUrl,
                                            )!,
                                        flags: const YoutubePlayerFlags(
                                          autoPlay: false,
                                          mute: false,
                                          enableCaption: true,
                                          captionLanguage: 'en',
                                          forceHD: false,
                                          loop: false,
                                          controlsVisibleAtStart: true,
                                          showLiveFullscreenButton: true,
                                        ),
                                      ),
                                      showVideoProgressIndicator: true,
                                      progressIndicatorColor: Colors.red,
                                      progressColors: const ProgressBarColors(
                                        playedColor: Colors.red,
                                        handleColor: Colors.redAccent,
                                      ),
                                    ),
                                    // Like button overlay
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => _toggleLike(
                                          item,
                                          'youtube_$linkIndex',
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                size: 14,
                                                color: youtubeLikes > 0
                                                    ? Colors.red
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                youtubeLikes.toString(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // Link details
                          InkWell(
                            onTap: () async {
                              if (await canLaunch(youtubeUrl)) {
                                await launch(youtubeUrl);
                              }
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLike(MediaItem item, String mediaKey) {
    // In a real app, this would update the server
    // For now, we'll just show a local update
    setState(() {
      final currentLikes = item.likes[mediaKey] ?? 0;
      item.likes[mediaKey] = currentLikes > 0 ? 0 : 1; // Toggle between 0 and 1
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.likes[mediaKey]! > 0 ? 'Liked!' : 'Unliked'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

}

