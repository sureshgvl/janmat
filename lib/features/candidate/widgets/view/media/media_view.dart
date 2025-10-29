import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/common/whatsapp_image_viewer.dart';
import 'package:janmat/features/common/video_player_screen.dart';
import 'package:janmat/features/common/reusable_video_widget.dart';
import 'package:janmat/core/app_route_names.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/services/share_service.dart';
import 'package:janmat/services/file_upload_service.dart';

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

  // Force UI refresh method
  void _refreshView() {
    setState(() {});
  }

  // Get media items from candidate data
  List<MediaItem> _getMediaItems() {
    List<MediaItem> mediaItems = [];
    try {
      final media = widget.candidate.media;
      AppLogger.candidate('📱 [MEDIA_VIEW] Building media view for candidate ${widget.candidate.candidateId}');
      AppLogger.candidate('📱 [MEDIA_VIEW] Raw media data: $media');
      AppLogger.candidate('📱 [MEDIA_VIEW] Media type: ${media?.runtimeType}');
      AppLogger.candidate('📱 [MEDIA_VIEW] Media length: ${media?.length}');

      if (media != null && media.isNotEmpty) {
        // Check the first item to determine format
        final firstItem = media.first;
        AppLogger.candidate('📱 [MEDIA_VIEW] First item type: ${firstItem.runtimeType}');
        AppLogger.candidate('📱 [MEDIA_VIEW] First item data: $firstItem');

        if (firstItem is Map<String, dynamic>) {
          // New grouped format - each item is already a MediaItem map
          final List<dynamic> mediaList = media;
          final validItems = mediaList.whereType<Map<String, dynamic>>();
          AppLogger.candidate('📱 [MEDIA_VIEW] Found ${validItems.length} valid map items out of ${mediaList.length} total items');

          int itemIndex = 0;
          mediaItems = validItems.map((item) {
            try {
              final itemMap = item as Map<String, dynamic>;
              AppLogger.candidate('📱 [MEDIA_VIEW] Parsing item ${itemIndex++}: ${itemMap.keys.toList()}');

              // Log the actual data for debugging
              AppLogger.candidate('📱 [MEDIA_VIEW] - title: ${itemMap['title']}');
              AppLogger.candidate('📱 [MEDIA_VIEW] - date: ${itemMap['date']}');
              AppLogger.candidate('📱 [MEDIA_VIEW] - images count: ${(itemMap['images'] as List?)?.length ?? 0}');
              AppLogger.candidate('📱 [MEDIA_VIEW] - videos count: ${(itemMap['videos'] as List?)?.length ?? 0}');
              AppLogger.candidate('📱 [MEDIA_VIEW] - youtubeLinks count: ${(itemMap['youtubeLinks'] as List?)?.length ?? 0}');
              AppLogger.candidate('📱 [MEDIA_VIEW] - likes: ${itemMap['likes']}');

              final parsedItem = MediaItem.fromJson(itemMap);
              AppLogger.candidate('📱 [MEDIA_VIEW] Successfully parsed item: ${parsedItem.title}');
              return parsedItem;
            } catch (e) {
              AppLogger.candidateError('📱 [MEDIA_VIEW] Error parsing item ${itemIndex - 1}: $e');
              return null;
            }
          }).whereType<MediaItem>().toList(); // Remove null items from failed parsing

          AppLogger.candidate('📱 [MEDIA_VIEW] Successfully parsed ${mediaItems.length} MediaItems - failed to parse: ${validItems.length - mediaItems.length}');
          for (var i = 0; i < mediaItems.length; i++) {
            final item = mediaItems[i];
            AppLogger.candidate('📱 [MEDIA_VIEW] Item $i: "${item.title}" (${item.images.length} images, ${item.videos.length} videos, ${item.youtubeLinks.length} youtube)');
          }
        } else if (firstItem is Media) {
          // Old format - individual Media objects need to be converted to grouped format
          AppLogger.candidate('📱 [MEDIA_VIEW] Processing legacy format with individual Media objects');

          final Map<String, List<Media>> groupedMedia = {};

          for (final item in media) {
            final mediaObj = item as Media;
            final title = mediaObj.title ?? 'Untitled';
            final date = mediaObj.uploadedAt ?? DateTime.now().toIso8601String().split('T')[0];

            final groupKey = '$title|$date';

            if (!groupedMedia.containsKey(groupKey)) {
              groupedMedia[groupKey] = [];
            }
            groupedMedia[groupKey]!.add(mediaObj);
          }

          // Convert grouped Media objects to MediaItem objects
          for (final entry in groupedMedia.entries) {
            final keyParts = entry.key.split('|');
            final title = keyParts[0];
            final date = keyParts[1];

            final List<String> images = [];
            final List<String> videos = [];
            final List<String> youtubeLinks = [];

            for (final mediaObj in entry.value) {
              switch (mediaObj.type) {
                case 'image':
                  images.add(mediaObj.url);
                  break;
                case 'video':
                  videos.add(mediaObj.url);
                  break;
                case 'youtube':
                  youtubeLinks.add(mediaObj.url);
                  break;
              }
            }

            final likes = <String, int>{};
            mediaItems.add(MediaItem(
              title: title,
              date: date,
              images: images,
              videos: videos,
              youtubeLinks: youtubeLinks,
              likes: likes,
            ));
          }

          AppLogger.candidate('📱 [MEDIA_VIEW] Converted ${media.length} individual Media objects to ${mediaItems.length} grouped MediaItems');
        } else {
          AppLogger.candidateError('📱 [MEDIA_VIEW] Unexpected media item format: ${firstItem.runtimeType}');
          mediaItems = [];
        }
      }
    } catch (e) {
      AppLogger.candidateError('📱 [MEDIA_VIEW] Error parsing media data: $e');
      mediaItems = [];
    }

    AppLogger.candidate('📱 [MEDIA_VIEW] Returning ${mediaItems.length} media items');
    return mediaItems;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final mediaItems = _getMediaItems();

    // Sort by most recent first
    mediaItems.sort((a, b) {
      if (a.date == null || a.date!.isEmpty) return 1;
      if (b.date == null || b.date!.isEmpty) return -1;

      try {
        final dateA = DateTime.parse(a.date!);
        final dateB = DateTime.parse(b.date!);
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        return 0;
      }
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facebook-style "What's on your mind?" Composer (only for own profile)
          if (widget.isOwnProfile) ...[
            const SizedBox(height: 16),
            _buildFacebookStylePostComposer(),
          ],

          const SizedBox(height: 16),

          // Media Posts Timeline (all saved media posts)
          ...mediaItems.map((item) => _buildFacebookStylePostCard(item)),

          // Empty State
          if (mediaItems.isEmpty) ...[
            const SizedBox(height: 40),
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
                    widget.isOwnProfile ? 'No posts yet' : 'No media available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isOwnProfile
                        ? 'Tap above to create your first post!'
                        : 'Photos and videos will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
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

  // Facebook-style "What's on your mind?" post composer
  Widget _buildFacebookStylePostComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile avatar placeholder
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: widget.candidate.photo != null && widget.candidate.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidate.photo!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showAddPostDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Photo/Video button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showAddPostDialog(),
                    icon: Icon(Icons.photo_library, color: Colors.green),
                    label: Text(
                      'Photo/Video',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                // YouTube button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showAddPostDialog(),
                    icon: Icon(Icons.video_call, color: Colors.red),
                    label: Text(
                      'YouTube',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Facebook-style media post card
  Widget _buildFacebookStylePostCard(MediaItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: widget.candidate.photo != null && widget.candidate.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidate.photo!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.candidate.basicInfo!.fullName ?? 'Candidate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Text(
                        _formatDate(item.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3-dot menu for edit/delete (only for own profile)
                if (widget.isOwnProfile) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditPostDialog(item);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),

          // Post Title
          if (item.title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1f2937),
                ),
              ),
            ),
          ],

          // Media Content
          if (item.images.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: _buildFacebookStyleImageLayout(item.images),
            ),
          ],

          // Videos
          if (item.videos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildVideoContent(item),
            ),
          ],

          // YouTube Links
          if (item.youtubeLinks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildYouTubeContent(item),
            ),
          ],

          // Engagement actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Like button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _toggleLike(item, 'post'),
                    icon: Icon(
                      Icons.thumb_up_outlined,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                // Comment placeholder
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      // Show comment dialog
                      _showCommentDialog(item);
                    },
                    icon: Icon(
                      Icons.comment_outlined,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    label: Text(
                      'Comment',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                // Share functionality
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _sharePost(item);
                    },
                    icon: Icon(
                      Icons.share_outlined,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    label: Text(
                      'Share',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add Post Dialog
  void _showAddPostDialog() {
    // Navigate to add post screen with candidate
    Get.toNamed(AppRouteNames.candidateMediaAdd, arguments: widget.candidate);
  }

  // Edit Post Dialog
  void _showEditPostDialog(MediaItem item) {
    // Navigate to edit post screen with existing data
    Get.toNamed(AppRouteNames.candidateMediaEdit, arguments: {'item': item, 'candidate': widget.candidate});
  }

  // Delete Confirmation
  void _showDeleteConfirmation(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(item);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePost(MediaItem item) async {
    // Show loading overlay immediately
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing
      builder: (context) => const _DeleteProgressDialog(
        title: 'Deleting Post',
        message: 'Removing media files...',
      ),
    );

    try {
      final mediaController = Get.find<MediaController>();
      final fileUploadService = FileUploadService();

      // STEP 1: Delete files from Firebase Storage first
      AppLogger.candidate('🗑️ [DELETE] Starting deletion of post: "${item.title}" (${item.date})');

      // Update loading dialog message
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _DeleteProgressDialog(
            title: 'Deleting Post',
            message: 'Cleaning up storage files...',
          ),
        );
      }

      // Collect all Firebase storage URLs from the post
      final allUrls = <String>[];
      allUrls.addAll(item.images.where((url) => !FileUploadService().isLocalPath(url)));
      allUrls.addAll(item.videos.where((url) => !FileUploadService().isLocalPath(url)));

      AppLogger.candidate('🗑️ [DELETE] Found ${allUrls.length} Firebase files to delete');

      int deletedCount = 0;
      // Delete all files from Firebase Storage
      for (final url in allUrls) {
        try {
          await fileUploadService.deleteFile(url);
          deletedCount++;
          AppLogger.candidate('✅ [DELETE] Deleted storage file: $url');

          // Update loading dialog with progress
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => _DeleteProgressDialog(
                title: 'Deleting Post',
                message: 'Cleaning up storage files... (${deletedCount}/${allUrls.length})',
              ),
            );
          }
        } catch (e) {
          AppLogger.candidateError('⚠️ [DELETE] Failed to delete storage file: $url - $e');
          // Continue with other deletions don't stop the whole process
        }
      }

      // STEP 2: Remove the item from Firebase document
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _DeleteProgressDialog(
            title: 'Deleting Post',
            message: 'Updating profile...',
          ),
        );
      }

      final currentGroupedMedia = await mediaController.getMediaGrouped(widget.candidate);
      if (currentGroupedMedia == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
        }
        return;
      }

      // Remove the item that matches title and date
      final updatedMedia = List<Map<String, dynamic>>.from(currentGroupedMedia.where((mediaData) {
        final parsedItem = MediaItem.fromJson(mediaData);
        return !(parsedItem.title == item.title && parsedItem.date == item.date);
      }));

      // Save the updated media array
      final success = await mediaController.saveMediaGrouped(widget.candidate, updatedMedia);

      if (success) {
        // STEP 3: Force UI refresh and refresh candidate data
        setState(() {}); // Force the widget to rebuild with updated data
        try {
          final candidateController = Get.find<CandidateUserController>();
          await candidateController.refreshCandidateData();
        } catch (e) {
          AppLogger.candidateError('Error refreshing candidate data after delete: $e');
        }

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      } else {
        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post')),
        );
      }
    } catch (e) {
      // Dismiss loading dialog on error
      if (mounted) {
        Navigator.of(context).pop();
      }

      AppLogger.candidateError('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  void _showCommentDialog(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: const Text('Comments feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sharePost(MediaItem item) async {
    try {
      // Generate share text for media post
      final postTitle = item.title.isNotEmpty ? item.title : 'Campaign Update';
      final candidateName = widget.candidate.basicInfo!.fullName ?? 'Candidate';

      final StringBuffer buffer = StringBuffer();
      buffer.writeln('📱 Post by $candidateName');

      if (postTitle.isNotEmpty && postTitle != 'Campaign Update') {
        buffer.writeln('📝 "$postTitle"');
      }

      // Add media count
      final totalMedia = item.images.length + item.videos.length + item.youtubeLinks.length;
      if (totalMedia > 0) {
        buffer.writeln('🖼️ Contains $totalMedia media item(s)');
      }

      // Add date
      if (item.date != null && item.date!.isNotEmpty) {
        buffer.writeln('📅 Posted on ${_formatDate(item.date)}');
      }

      buffer.writeln();
      buffer.writeln('🌟 View this candidate\'s latest updates on Janmat!');
      buffer.writeln('Download the app now: https://play.google.com/store/apps/details?id=com.janmat');

      await ShareService.shareCandidateProfile(widget.candidate);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing post: $e')),
      );
    }
  }

  // Video content builder
  Widget _buildVideoContent(MediaItem item) {
    if (item.videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.videos.map((videoUrl) {
        final videoIndex = item.videos.indexOf(videoUrl);
        final videoLikes = item.likes['video_$videoIndex'] ?? 0;
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);

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
                Stack(
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
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
                    // Like button overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleLike(item, 'video_$videoIndex'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: videoLikes > 0 ? Colors.red : Colors.grey[600],
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
                        onPressed: () {
                          Get.to(
                            () => VideoPlayerScreen(
                              videoUrl: videoUrl,
                              title: '${item.title} - Video ${videoIndex + 1}',
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
            child: Stack(
              children: [
                VideoPreviewWidget(
                  videoUrl: videoUrl,
                  title: '${item.title} - Video ${videoIndex + 1}',
                  aspectRatio: 16 / 9,
                ),
                // Like button overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleLike(item, 'video_$videoIndex'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: videoLikes > 0 ? Colors.red : Colors.grey[600],
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
      }).toList(),
    );
  }

  // YouTube content builder
  Widget _buildYouTubeContent(MediaItem item) {
    if (item.youtubeLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.youtubeLinks.map((youtubeUrl) {
        final linkIndex = item.youtubeLinks.indexOf(youtubeUrl);
        final youtubeLikes = item.likes['youtube_$linkIndex'] ?? 0;

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
              if (YoutubePlayer.convertUrlToId(youtubeUrl) != null) ...[
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
                    child: Stack(
                      children: [
                        YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: YoutubePlayer.convertUrlToId(youtubeUrl)!,
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
                            onTap: () => _toggleLike(item, 'youtube_$linkIndex'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 14,
                                    color: youtubeLikes > 0 ? Colors.red : Colors.grey[600],
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

  Widget _buildFacebookStyleImageLayout(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final imageCount = images.length;

    if (imageCount == 1) {
      // Single image - full width
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black,
              pageBuilder: (context, animation, secondaryAnimation) {
                return WhatsAppImageViewer(
                  imageUrl: images[0],
                  title: 'Photo 1',
                );
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
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
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return WhatsAppImageViewer(
                        imageUrl: images[0],
                        title: 'Photo 1',
                      );
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
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
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return WhatsAppImageViewer(
                        imageUrl: images[1],
                        title: 'Photo 2',
                      );
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
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
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return WhatsAppImageViewer(
                      imageUrl: images[0],
                      title: 'Photo 1',
                    );
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                ),
              );
            },
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
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return WhatsAppImageViewer(
                            imageUrl: images[1],
                            title: 'Photo 2',
                          );
                        },
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
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
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return WhatsAppImageViewer(
                            imageUrl: images[2],
                            title: 'Photo 3',
                          );
                        },
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                      ),
                    );
                  },
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
      final int maxToShow = imageCount > 6 ? 6 : imageCount; // Limit to 6 images max for UI
      final int gridColumns = maxToShow <= 4 ? 2 : 3; // 2 columns for <=4 images, 3 for 5-6

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
              onTap: () => _showAllImages(images),
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
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return WhatsAppImageViewer(
                        imageUrl: imageUrl,
                        title: 'Photo ${index + 1}',
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
                          'Date: ${_formatDate(item.date)}',
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
                _buildFacebookStyleImageLayout(item.images),
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

              // Added date display at bottom
              if (item.addedDate != null && item.addedDate!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Added on ${_formatDate(item.addedDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      // Assuming the date is in YYYY-MM-DD format, convert to DD/MM/YYYY
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date ?? '';
    }
  }

  void _showAllImages(List<String> images) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              pageBuilder: (context, animation, secondaryAnimation) {
                                return WhatsAppImageViewer(
                                  imageUrl: images[index],
                                  title: 'Photo ${index + 1}',
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

// Loading dialog for delete progress
class _DeleteProgressDialog extends StatelessWidget {
  final String title;
  final String message;

  const _DeleteProgressDialog({
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
      actions: null, // No actions - user cannot dismiss
    );
  }
}
