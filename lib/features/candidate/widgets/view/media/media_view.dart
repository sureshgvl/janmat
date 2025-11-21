import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/common/whatsapp_image_viewer.dart';
import 'package:janmat/features/common/video_player_screen.dart';
import 'package:janmat/features/common/reusable_video_widget.dart';
import 'package:janmat/features/common/image_gallery_components.dart';
import 'package:janmat/core/app_route_names.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import 'package:janmat/controllers/background_color_controller.dart';
import 'package:janmat/services/local_database_service.dart';
import 'package:janmat/features/auth/controllers/auth_controller.dart';
import 'package:janmat/features/candidate/services/firebase_engagement_service.dart';
import 'package:janmat/features/candidate/models/like_model.dart';
import 'package:janmat/features/candidate/models/comment_model.dart';

class MediaTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final Function(Candidate)? onLocalUpdate;

  const MediaTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
    this.onLocalUpdate,
  });

  @override
  State<MediaTabView> createState() => _MediaTabViewState();
}

class MediaTabViewReactive extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;

  const MediaTabViewReactive({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
  });

  @override
  State<MediaTabViewReactive> createState() => _MediaTabViewReactiveState();
}

class _MediaTabViewReactiveState extends State<MediaTabViewReactive> {
  // Local candidate copy for instant UI updates
  late Candidate localCandidate;

  @override
  void initState() {
    super.initState();
    // Initialize local copy
    localCandidate = widget.candidate.copyWith();
  }

  @override
  void didUpdateWidget(MediaTabViewReactive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local copy when widget candidate changes
    if (oldWidget.candidate.candidateId != widget.candidate.candidateId) {
      localCandidate = widget.candidate.copyWith();
    }
  }

  // Update local candidate for instant UI feedback
  void updateLocalCandidate(Candidate updatedCandidate) {
    setState(() {
      localCandidate = updatedCandidate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaTabView(
      candidate: localCandidate,
      isOwnProfile: widget.isOwnProfile,
      onLocalUpdate: updateLocalCandidate,
      key: ValueKey(
        'media_view_${localCandidate.candidateId}_${localCandidate.media?.length ?? 0}',
      ),
    );
  }
}

class _MediaTabViewState extends State<MediaTabView> {
  // Loading states for like buttons (per item)
  final Map<String, RxBool> _likeLoadingStates = {};

  // Get media items from candidate data
  List<MediaItem> _getMediaItems() {
    List<MediaItem> mediaItems = [];
    try {
      final media = widget.candidate.media;
      AppLogger.candidate(
        '📱 [MEDIA_VIEW] Building media view for candidate ${widget.candidate.candidateId}',
      );
      AppLogger.candidate('📱 [MEDIA_VIEW] Raw media data: $media');
      AppLogger.candidate('📱 [MEDIA_VIEW] Media type: ${media?.runtimeType}');
      AppLogger.candidate('📱 [MEDIA_VIEW] Media length: ${media?.length}');

      // Check if media is null or empty
      if (media == null) {
        AppLogger.candidate(
          '📱 [MEDIA_VIEW] Media is null - no media data available',
        );
        return [];
      }

      if (media.isEmpty) {
        AppLogger.candidate(
          '📱 [MEDIA_VIEW] Media is empty - no media items. Add some media posts to see them here!',
        );
        return [];
      }

      // DEBUG: Log each media item to see the structure
      for (int i = 0; i < media.length; i++) {
        final item = media[i];
        AppLogger.candidate(
          '📱 [MEDIA_VIEW] Media item $i: $item (type: ${item.runtimeType})',
        );
        if (item is Map<String, dynamic>) {
          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Media item $i keys: ${item.keys.toList()}',
          );
          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Media item $i title: ${item['title']}',
          );
          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Media item $i date: ${item['date']}',
          );
        }
      }

      if (media != null && media.isNotEmpty) {
        // Check the first item to determine format
        final firstItem = media.first;
        AppLogger.candidate(
          '📱 [MEDIA_VIEW] First item type: ${firstItem.runtimeType}',
        );
        AppLogger.candidate('📱 [MEDIA_VIEW] First item data: $firstItem');

        if (firstItem is Map<String, dynamic>) {
          // New grouped format - each item is already a MediaItem map
          final List<dynamic> mediaList = media;
          final validItems = mediaList.whereType<Map<String, dynamic>>();
          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Found ${validItems.length} valid map items out of ${mediaList.length} total items',
          );

          int itemIndex = 0;
          mediaItems = validItems
              .map((item) {
                try {
                  final itemMap = item;
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] Parsing item ${itemIndex++}: ${itemMap.keys.toList()}',
                  );

                  // Log the actual data for debugging
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - title: ${itemMap['title']}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - date: ${itemMap['date']}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - images count: ${(itemMap['images'] as List?)?.length ?? 0}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - videos count: ${(itemMap['videos'] as List?)?.length ?? 0}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - youtubeLinks count: ${(itemMap['youtubeLinks'] as List?)?.length ?? 0}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - likes count: ${(itemMap['likes'] as List?)?.length ?? 0}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - comments count: ${(itemMap['comments'] as List?)?.length ?? 0}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - raw likes data: ${itemMap['likes']}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - raw comments data: ${itemMap['comments']}',
                  );

                  final parsedItem = MediaItem.fromJson(itemMap);
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - parsed likes count: ${parsedItem.likes.length}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] - parsed comments count: ${parsedItem.comments.length}',
                  );
                  AppLogger.candidate(
                    '📱 [MEDIA_VIEW] Successfully parsed item: ${parsedItem.title}',
                  );
                  return parsedItem;
                } catch (e) {
                  AppLogger.candidateError(
                    '📱 [MEDIA_VIEW] Error parsing item ${itemIndex - 1}: $e',
                  );
                  return null;
                }
              })
              .whereType<MediaItem>()
              .toList(); // Remove null items from failed parsing

          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Successfully parsed ${mediaItems.length} MediaItems - failed to parse: ${validItems.length - mediaItems.length}',
          );
          for (var i = 0; i < mediaItems.length; i++) {
            final item = mediaItems[i];
            AppLogger.candidate(
              '📱 [MEDIA_VIEW] Item $i: "${item.title}" (${item.images.length} images, ${item.videos.length} videos, ${item.youtubeLinks.length} youtube)',
            );
          }
        } else if (firstItem is Media) {
          // Old format - individual Media objects need to be converted to grouped format
          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Processing legacy format with individual Media objects',
          );

          final Map<String, List<Media>> groupedMedia = {};

          for (final item in media) {
            final mediaObj = item as Media;
            final title = mediaObj.title ?? 'Untitled';
            final date =
                mediaObj.uploadedAt ??
                DateTime.now().toIso8601String().split('T')[0];

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

            mediaItems.add(
              MediaItem(
                title: title,
                date: date,
                images: images,
                videos: videos,
                youtubeLinks: youtubeLinks,
              ),
            );
          }

          AppLogger.candidate(
            '📱 [MEDIA_VIEW] Converted ${media.length} individual Media objects to ${mediaItems.length} grouped MediaItems',
          );
        } else {
          AppLogger.candidateError(
            '📱 [MEDIA_VIEW] Unexpected media item format: ${firstItem.runtimeType}',
          );
          mediaItems = [];
        }
      }
    } catch (e) {
      AppLogger.candidateError('📱 [MEDIA_VIEW] Error parsing media data: $e');
      mediaItems = [];
    }

    AppLogger.candidate(
      '📱 [MEDIA_VIEW] Returning ${mediaItems.length} media items',
    );
    return mediaItems;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColorController = Get.find<BackgroundColorController>();
    final mediaItems = _getMediaItems();

    // Sort by most recent first
    mediaItems.sort((a, b) {
      if (a.date.isEmpty) return 1;
      if (b.date.isEmpty) return -1;

      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        return 0;
      }
    });

    return Obx(
      () => Container(
        color: backgroundColorController.currentBackgroundColor.value,
        child: SingleChildScrollView(
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
                        widget.isOwnProfile
                            ? 'No posts yet'
                            : 'No media available',
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
        ),
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
                  child:
                      widget.candidate.basicInfo!.photo != null &&
                          widget.candidate.basicInfo!.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidate.basicInfo!.photo!,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                  child:
                      widget.candidate.basicInfo!.photo != null &&
                          widget.candidate.basicInfo!.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidate.basicInfo!.photo!,
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
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
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

          // Engagement actions (Like and Comment only - Facebook style)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildEngagementSection(item),
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
    Get.toNamed(
      AppRouteNames.candidateMediaEdit,
      arguments: {'item': item, 'candidate': widget.candidate},
    );
  }

  // Delete Confirmation
  void _showDeleteConfirmation(MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
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
    // Validate candidate location data before proceeding
    if (widget.candidate.location.stateId == null ||
        widget.candidate.location.districtId == null ||
        widget.candidate.location.bodyId == null ||
        widget.candidate.location.wardId == null ||
        widget.candidate.candidateId.isEmpty) {
      AppLogger.candidateError(
        '❌ [DELETE] Missing required location data for candidate',
      );
      SnackbarUtils.showScaffoldError(
        context,
        'Cannot delete post: missing candidate location data',
      );
      return;
    }

    // Show loading overlay immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteProgressDialog(
        title: 'Deleting Post',
        message: 'Scheduling cleanup...',
      ),
    );

    AppLogger.candidate(
      '🗑️ [DELETE] Starting deletion of post: "${item.title}" (${item.date})',
    );
    AppLogger.candidate(
      '🗑️ [DELETE] Candidate: ${widget.candidate.candidateId} at ${widget.candidate.location.stateId}/${widget.candidate.location.districtId}/${widget.candidate.location.bodyId}/${widget.candidate.location.wardId}',
    );

    try {
      final mediaController = Get.find<MediaController>();

      // STEP 1: Collect storage paths for deferred cleanup using deleteStorage pattern
      final storagePathsToDelete = <String>[];
      final allUrls = <String>[];

      // Collect all Firebase storage URLs (exclude local paths marked with 'local:')
      final firebaseImageUrls = item.images
          .where(
            (url) =>
                !FileUploadService().isLocalPath(url) &&
                url.contains('firebasestorage.googleapis.com'),
          )
          .toList();
      final firebaseVideoUrls = item.videos
          .where(
            (url) =>
                !FileUploadService().isLocalPath(url) &&
                url.contains('firebasestorage.googleapis.com'),
          )
          .toList();

      allUrls.addAll(firebaseImageUrls);
      allUrls.addAll(firebaseVideoUrls);

      AppLogger.candidate(
        '🗑️ [DELETE] Found ${firebaseImageUrls.length} images and ${firebaseVideoUrls.length} videos to clean up',
      );
      AppLogger.candidate('🗑️ [DELETE] URLs to process: $allUrls');

      // Convert Firebase URLs to storage paths for the deleteStorage array
      for (final url in allUrls) {
        try {
          final storagePath = _extractStoragePath(url);
          if (storagePath != url) {
            // Only add if extraction succeeded
            storagePathsToDelete.add(storagePath);
            AppLogger.candidate(
              '🗑️ [DELETE] Extracted storage path: $storagePath from $url',
            );
          } else {
            AppLogger.candidateError(
              '⚠️ [DELETE] Failed to extract storage path from: $url',
            );
          }
        } catch (e) {
          AppLogger.candidateError(
            '⚠️ [DELETE] Exception extracting storage path from: $url - $e',
          );
        }
      }

      AppLogger.candidate(
        '🗑️ [DELETE] Final storage paths to delete: $storagePathsToDelete',
      );

      // STEP 2: Add storage paths to candidate's deleteStorage array (deferred cleanup pattern)
      if (storagePathsToDelete.isNotEmpty) {
        try {
          // Get the hierarchical path for the candidate
          final candidateRef = FirebaseFirestore.instance
              .collection('states')
              .doc(widget.candidate.location.stateId!)
              .collection('districts')
              .doc(widget.candidate.location.districtId!)
              .collection('bodies')
              .doc(widget.candidate.location.bodyId!)
              .collection('wards')
              .doc(widget.candidate.location.wardId!)
              .collection('candidates')
              .doc(widget.candidate.candidateId);

          AppLogger.candidate(
            '🗑️ [DELETE] Updating deleteStorage at path: states/${widget.candidate.location.stateId}/districts/${widget.candidate.location.districtId}/bodies/${widget.candidate.location.bodyId}/wards/${widget.candidate.location.wardId}/candidates/${widget.candidate.candidateId}',
          );

          await candidateRef.update({
            'deleteStorage': FieldValue.arrayUnion(storagePathsToDelete),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          AppLogger.candidate(
            '📋 [DELETE] Successfully added ${storagePathsToDelete.length} files to deleteStorage: $storagePathsToDelete',
          );
        } catch (deleteStorageError) {
          AppLogger.candidateError(
            '❌ [DELETE] Failed to update deleteStorage: $deleteStorageError',
          );
          // Continue with deletion even if deleteStorage update fails
        }
      } else {
        AppLogger.candidate(
          '🗑️ [DELETE] No storage paths to add to deleteStorage array',
        );
      }

      // STEP 3: Remove the item from Firebase document
      if (mounted) {
        // Update loading dialog to show we're updating profile
        Navigator.of(context).pop(); // Dismiss current dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DeleteProgressDialog(
            title: 'Deleting Post',
            message: 'Updating profile...',
          ),
        );
      }

      final currentGroupedMedia = await mediaController.getMediaGrouped(
        widget.candidate,
      );
      if (currentGroupedMedia == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading dialog
        }
        return;
      }

      // Remove the item that matches title and date
      final updatedMedia = List<Map<String, dynamic>>.from(
        currentGroupedMedia.where((mediaData) {
          final parsedItem = MediaItem.fromJson(mediaData);
          return !(parsedItem.title == item.title &&
              parsedItem.date == item.date);
        }),
      );

      // Save the updated media array
      final success = await mediaController.saveMediaGrouped(
        widget.candidate,
        updatedMedia,
      );

      if (success) {
        // STEP 3: Force UI refresh and refresh candidate data
        setState(() {}); // Force the widget to rebuild with updated data
        try {
          final candidateController = Get.find<CandidateUserController>();
          await candidateController.refreshCandidateData();
        } catch (e) {
          AppLogger.candidateError(
            'Error refreshing candidate data after delete: $e',
          );
        }

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        SnackbarUtils.showScaffoldSuccess(context, 'Post deleted successfully');
      } else {
        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        SnackbarUtils.showScaffoldError(context, 'Failed to delete post');
      }
    } catch (e) {
      // Dismiss loading dialog on error
      if (mounted) {
        Navigator.of(context).pop();
      }

      AppLogger.candidateError('Error deleting post: $e');
      SnackbarUtils.showScaffoldError(context, 'Error deleting post: $e');
    }
  }

  // Video content builder
  Widget _buildVideoContent(MediaItem item) {
    if (item.videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.videos.map((videoUrl) {
        final videoIndex = item.videos.indexOf(videoUrl);
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

  // YouTube content builder
  Widget _buildYouTubeContent(MediaItem item) {
    if (item.youtubeLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: item.youtubeLinks.map((youtubeUrl) {
        final linkIndex = item.youtubeLinks.indexOf(youtubeUrl);

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
                    child: YoutubePlayer(
                      controller: YoutubePlayerController(
                        initialVideoId: YoutubePlayer.convertUrlToId(
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
                  ),
                ),
              ],
              // Link details
              InkWell(
                onTap: () async {
                  if (await canLaunchUrl(Uri.parse(youtubeUrl))) {
                    await launchUrl(Uri.parse(youtubeUrl));
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
        onTap: () => _openImageGallery(images, 0),
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
              onTap: () => _openImageGallery(images, 0),
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
              onTap: () => _openImageGallery(images, 1),
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
            onTap: () => _openImageGallery(images, 0),
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
                  onTap: () => _openImageGallery(images, 1),
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
                  onTap: () => _openImageGallery(images, 2),
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
              onTap: () => _openImageGallery(images, index),
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

  // Open image gallery with swipe functionality
  void _openImageGallery(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          images: images,
          initialIndex: initialIndex,
          isLocal: (index) => FileUploadService().isLocalPath(images[index]),
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

  // Build engagement section with embedded data from MediaItem
  Widget _buildEngagementSection(MediaItem item) {
    final engagementService = FirebaseEngagementService();
    final currentUserId = _getCurrentUserId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Engagement summary (like count and comment count) - ABOVE buttons like Facebook
        if (item.likeCount > 0 || item.commentCount > 0) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (item.likeCount > 0) ...[
                  Icon(Icons.thumb_up, color: Colors.blue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${item.likeCount}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (item.likeCount > 0 && item.commentCount > 0) ...[
                  const SizedBox(width: 16),
                ],
                if (item.commentCount > 0) ...[
                  Text(
                    '${item.commentCount} ${item.commentCount == 1 ? 'comment' : 'comments'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        // Like and Comment buttons row - BELOW counts like Facebook
        Row(
          children: [
            // Like button with loading state
            Expanded(
              child: Obx(
                () => _buildLikeButton(item, engagementService, currentUserId),
              ),
            ),
            // Comment button
            Expanded(
              child: TextButton.icon(
                onPressed: () =>
                    _showCommentsSheetEmbedded(item, engagementService),
                icon: Icon(
                  Icons.comment_outlined,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                label: Text(
                  'Comment',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                style: TextButton.styleFrom(alignment: Alignment.center),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build like button with reactive state
  Widget _buildLikeButton(
    MediaItem item,
    FirebaseEngagementService service,
    String currentUserId,
  ) {
    // Get reactive loading state for this specific item
    final isLoading = _getLikeLoadingState(item);

    return TextButton.icon(
      onPressed: isLoading.value
          ? null
          : () =>
                _toggleLikeOptimistic(item, service, currentUserId, isLoading),
      icon: isLoading.value
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.hasUserLiked(currentUserId)
                      ? Colors.blue
                      : Colors.grey.shade600,
                ),
              ),
            )
          : Icon(
              item.hasUserLiked(currentUserId)
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              color: item.hasUserLiked(currentUserId)
                  ? Colors.blue
                  : Colors.grey.shade600,
              size: 18,
            ),
      label: Text(
        isLoading.value
            ? '...'
            : (item.hasUserLiked(currentUserId) ? 'Liked' : 'Like'),
        style: TextStyle(
          color: item.hasUserLiked(currentUserId)
              ? Colors.blue
              : Colors.grey.shade600,
        ),
      ),
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
    );
  }

  // Get reactive loading state for a specific item
  RxBool _getLikeLoadingState(MediaItem item) {
    final key = '${item.title}_${item.date}';
    if (!_likeLoadingStates.containsKey(key)) {
      _likeLoadingStates[key] = false.obs;
    }
    return _likeLoadingStates[key]!;
  }

  // Optimistic like toggle with loading states and instant UI updates
  void _toggleLikeOptimistic(
    MediaItem item,
    FirebaseEngagementService service,
    String currentUserId,
    RxBool isLoading,
  ) async {
    if (currentUserId.isEmpty) {
      SnackbarUtils.showScaffoldError(context, 'Please login to like posts');
      return;
    }

    // Get current user's information
    final currentUserInfo = _getCurrentUserInfo();

    // Set loading state
    isLoading.value = true;

    // Store original state for rollback
    final wasLiked = item.hasUserLiked(currentUserId);

    // DEBUG: Log candidate location data
    AppLogger.candidate(
      '📍 [LIKE] Candidate location - stateId: ${widget.candidate.location.stateId}, districtId: ${widget.candidate.location.districtId}, bodyId: ${widget.candidate.location.bodyId}, wardId: ${widget.candidate.location.wardId}',
    );

    try {
      // Call Firebase service FIRST (no optimistic updates for now)
      if (wasLiked) {
        // Unlike
        await service.removeLikeFromMediaItem(
          candidateId: widget.candidate.candidateId,
          stateId: widget.candidate.location.stateId ?? '',
          districtId: widget.candidate.location.districtId ?? '',
          bodyId: widget.candidate.location.bodyId ?? '',
          wardId: widget.candidate.location.wardId ?? '',
          mediaItem: item,
        );
        SnackbarUtils.showScaffoldInfo(context, 'Unliked');
      } else {
        // Like
        await service.addLikeToMediaItem(
          candidateId: widget.candidate.candidateId,
          stateId: widget.candidate.location.stateId ?? '',
          districtId: widget.candidate.location.districtId ?? '',
          bodyId: widget.candidate.location.bodyId ?? '',
          wardId: widget.candidate.location.wardId ?? '',
          mediaItem: item,
          userName: currentUserInfo['name'],
          userPhoto: currentUserInfo['photo'],
        );
        SnackbarUtils.showScaffoldInfo(context, 'Liked!');
      }

      // Optimistic UI update - update local candidate data immediately
      try {
        final updatedMedia = widget.candidate.media?.map((mediaData) {
          final parsedItem = MediaItem.fromJson(
            mediaData as Map<String, dynamic>,
          );
          if (parsedItem.title == item.title && parsedItem.date == item.date) {
            // Create updated likes based on the operation
            final updatedLikes = wasLiked
                ? parsedItem.likes
                      .where((like) => like.userId != currentUserId)
                      .toList()
                : [
                    ...parsedItem.likes,
                    Like(
                      id: '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
                      userId: currentUserId,
                      postId:
                          '${widget.candidate.candidateId}_${item.title}_${item.date}',
                      mediaKey: 'post',
                      createdAt: DateTime.now(),
                      userName: currentUserInfo['name'],
                      userPhoto: currentUserInfo['photo'],
                    ),
                  ];
            return parsedItem.copyWith(likes: updatedLikes).toJson();
          }
          return mediaData;
        }).toList();

        // Update local candidate copy for immediate UI feedback
        final updatedCandidate = widget.candidate.copyWith(media: updatedMedia);
        widget.onLocalUpdate?.call(updatedCandidate);
      } catch (e) {
        AppLogger.candidateError(
          'Error updating local candidate data after like: $e',
        );
      }
    } catch (e) {
      AppLogger.candidateError('Error toggling like: $e');
      SnackbarUtils.showScaffoldError(
        context,
        'Failed to update like - please try again',
      );
    } finally {
      // Always clear loading state
      isLoading.value = false;
    }
  }

  // Get current user ID
  String _getCurrentUserId() {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;
    return currentUser?.uid ?? '';
  }

  // Get current user information (name and photo)
  Map<String, String> _getCurrentUserInfo() {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    // Try to get user info from CandidateUserController first
    final candidateController = Get.find<CandidateUserController>();
    if (candidateController.candidate.value != null) {
      final candidate = candidateController.candidate.value!;
      return {
        'name': candidate.basicInfo?.fullName ?? 'Anonymous User',
        'photo': candidate.basicInfo!.photo ?? '',
      };
    }

    // Fallback to auth user display name
    return {
      'name': currentUser?.displayName ?? 'Anonymous User',
      'photo': currentUser?.photoURL ?? '',
    };
  }

  // Toggle like using embedded data approach
  void _toggleLikeEmbedded(
    MediaItem item,
    FirebaseEngagementService service,
  ) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) {
      SnackbarUtils.showScaffoldError(context, 'Please login to like posts');
      return;
    }

    // Get current user's information
    final currentUserInfo = _getCurrentUserInfo();

    try {
      if (item.hasUserLiked(currentUserId)) {
        // Unlike
        await service.removeLikeFromMediaItem(
          candidateId: widget.candidate.candidateId,
          stateId: widget.candidate.location.stateId ?? '',
          districtId: widget.candidate.location.districtId ?? '',
          bodyId: widget.candidate.location.bodyId ?? '',
          wardId: widget.candidate.location.wardId ?? '',
          mediaItem: item,
        );
        SnackbarUtils.showScaffoldInfo(context, 'Unliked');
      } else {
        // Like
        await service.addLikeToMediaItem(
          candidateId: widget.candidate.candidateId,
          stateId: widget.candidate.location.stateId ?? '',
          districtId: widget.candidate.location.districtId ?? '',
          bodyId: widget.candidate.location.bodyId ?? '',
          wardId: widget.candidate.location.wardId ?? '',
          mediaItem: item,
          userName: currentUserInfo['name'],
          userPhoto: currentUserInfo['photo'],
        );
        SnackbarUtils.showScaffoldInfo(context, 'Liked!');
      }

      // Force immediate UI refresh by triggering GetBuilder rebuild
      final candidateController = Get.find<CandidateUserController>();
      candidateController.update(); // Force GetBuilder to rebuild

      // Also refresh candidate data in background to ensure consistency
      try {
        await candidateController.refreshCandidateData();
      } catch (e) {
        AppLogger.candidateError(
          'Error refreshing candidate data after like: $e',
        );
      }
    } catch (e) {
      AppLogger.candidateError('Error toggling like: $e');
      SnackbarUtils.showScaffoldError(context, 'Failed to update like');
    }
  }

  // Show comments sheet using embedded data
  void _showCommentsSheetEmbedded(
    MediaItem item,
    FirebaseEngagementService service,
  ) {
    final TextEditingController commentController = TextEditingController();
    final currentUserId = _getCurrentUserId();

    if (currentUserId.isEmpty) {
      SnackbarUtils.showScaffoldError(context, 'Please login to view comments');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Comments list
                Expanded(
                  child: item.comments.isEmpty
                      ? ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: item.comments.length,
                          itemBuilder: (context, index) {
                            final comment = item.comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User avatar
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue.shade100,
                                    child:
                                        comment.userPhoto != null &&
                                            comment.userPhoto!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              comment.userPhoto!,
                                              fit: BoxFit.cover,
                                              width: 32,
                                              height: 32,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    color: Colors.blue.shade600,
                                                    size: 16,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.blue.shade600,
                                            size: 16,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (comment.userName != null &&
                                                  comment
                                                      .userName!
                                                      .isNotEmpty) ...[
                                                Text(
                                                  comment.userName!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                              Text(
                                                comment.text,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCommentTime(
                                            comment.createdAt.toIso8601String(),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Comment input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.shade100,
                        child:
                            widget.candidate.basicInfo!.photo != null &&
                                widget.candidate.basicInfo!.photo!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  widget.candidate.basicInfo!.photo!,
                                  fit: BoxFit.cover,
                                  width: 32,
                                  height: 32,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: Colors.blue.shade600,
                                        size: 16,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.blue.shade600,
                                size: 16,
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Comment text field
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) => _addCommentEmbedded(
                            item,
                            text,
                            commentController,
                            setState,
                            service,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Send button
                      IconButton(
                        onPressed: () => _addCommentEmbedded(
                          item,
                          commentController.text,
                          commentController,
                          setState,
                          service,
                        ),
                        icon: Icon(
                          Icons.send,
                          color: commentController.text.isNotEmpty
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add comment using embedded data approach
  void _addCommentEmbedded(
    MediaItem item,
    String text,
    TextEditingController controller,
    StateSetter setState,
    FirebaseEngagementService service,
  ) async {
    if (text.trim().isEmpty) return;

    final currentUserId = _getCurrentUserId();
    if (currentUserId.isEmpty) {
      SnackbarUtils.showScaffoldError(context, 'Please login to comment');
      return;
    }

    // Get current user's information
    final currentUserInfo = _getCurrentUserInfo();

    try {
      await service.addCommentToMediaItem(
        candidateId: widget.candidate.candidateId,
        stateId: widget.candidate.location.stateId ?? '',
        districtId: widget.candidate.location.districtId ?? '',
        bodyId: widget.candidate.location.bodyId ?? '',
        wardId: widget.candidate.location.wardId ?? '',
        mediaItem: item,
        text: text.trim(),
        userName: currentUserInfo['name'],
        userPhoto: currentUserInfo['photo'],
      );

      controller.clear();

      // Optimistic UI update - update local candidate data immediately
      try {
        final updatedMedia = widget.candidate.media?.map((mediaData) {
          final parsedItem = MediaItem.fromJson(
            mediaData as Map<String, dynamic>,
          );
          if (parsedItem.title == item.title && parsedItem.date == item.date) {
            // Add the new comment to the local data
            final newComment = Comment(
              id: '${currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
              userId: currentUserId,
              postId:
                  '${widget.candidate.candidateId}_${item.title}_${item.date}',
              text: text.trim(),
              createdAt: DateTime.now(),
              userName: currentUserInfo['name'],
              userPhoto: currentUserInfo['photo'],
            );
            final updatedComments = [...parsedItem.comments, newComment];
            return parsedItem.copyWith(comments: updatedComments).toJson();
          }
          return mediaData;
        }).toList();

        // Update local candidate copy for immediate UI feedback
        final updatedCandidate = widget.candidate.copyWith(media: updatedMedia);
        widget.onLocalUpdate?.call(updatedCandidate);
      } catch (e) {
        AppLogger.candidateError(
          'Error updating local candidate data after comment: $e',
        );
      }

      setState(() {}); // Refresh the comments sheet

      SnackbarUtils.showScaffoldInfo(context, 'Comment added!');
    } catch (e) {
      AppLogger.candidateError('Error adding comment: $e');
      SnackbarUtils.showScaffoldError(context, 'Failed to add comment');
    }
  }

  // Extract storage path from Firebase URL
  String _extractStoragePath(String firebaseUrl) {
    try {
      // Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
      final uri = Uri.parse(firebaseUrl);
      final path = uri.pathSegments
          .skip(3)
          .join('/'); // Skip v0/b/bucket/o/ parts
      return Uri.decodeComponent(path); // Decode URL encoding
    } catch (e) {
      AppLogger.candidateError(
        'Failed to extract storage path from: $firebaseUrl',
      );
      return firebaseUrl; // Fallback to original URL if parsing fails
    }
  }

  // Firebase-based like toggle
  void _toggleLikeFirebase(
    MediaItem item,
    String mediaKey,
    FirebaseEngagementService service,
  ) async {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    if (currentUser == null) {
      SnackbarUtils.showScaffoldError(context, 'Please login to like posts');
      return;
    }

    final postId = '${widget.candidate.candidateId}_${item.title}_${item.date}';

    try {
      final hasLiked = await service.hasUserLiked(postId, mediaKey);

      if (hasLiked) {
        // Unlike
        await service.removeLike(postId, mediaKey);
        SnackbarUtils.showScaffoldInfo(context, 'Unliked');
      } else {
        // Like
        await service.addLike(
          postId,
          mediaKey,
          userName: widget.candidate.basicInfo?.fullName,
          userPhoto: widget.candidate.basicInfo!.photo,
        );
        SnackbarUtils.showScaffoldInfo(context, 'Liked!');
      }
    } catch (e) {
      AppLogger.candidateError('Error toggling like: $e');
      SnackbarUtils.showScaffoldError(context, 'Failed to update like');
    }
  }

  // Show comments in a bottom sheet (Firebase-based)
  void _showCommentsSheetFirebase(
    MediaItem item,
    FirebaseEngagementService service,
  ) {
    final TextEditingController commentController = TextEditingController();
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    if (currentUser == null) {
      SnackbarUtils.showScaffoldError(context, 'Please login to view comments');
      return;
    }

    final postId = '${widget.candidate.candidateId}_${item.title}_${item.date}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Comments list
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: service.getCommentsStream(postId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User avatar
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child:
                                    comment.userPhoto != null &&
                                        comment.userPhoto!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          comment.userPhoto!,
                                          fit: BoxFit.cover,
                                          width: 32,
                                          height: 32,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.person,
                                                    color: Colors.blue.shade600,
                                                    size: 16,
                                                  ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.blue.shade600,
                                        size: 16,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (comment.userName != null &&
                                              comment.userName!.isNotEmpty) ...[
                                            Text(
                                              comment.userName!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            comment.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCommentTime(
                                        comment.createdAt.toIso8601String(),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child:
                          widget.candidate.basicInfo!.photo != null &&
                              widget.candidate.basicInfo!.photo!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                widget.candidate.basicInfo!.photo!,
                                fit: BoxFit.cover,
                                width: 32,
                                height: 32,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.person,
                                      color: Colors.blue.shade600,
                                      size: 16,
                                    ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 16,
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Comment text field
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _addCommentFirebase(
                          item,
                          text,
                          commentController,
                          setState,
                          service,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button
                    IconButton(
                      onPressed: () => _addCommentFirebase(
                        item,
                        commentController.text,
                        commentController,
                        setState,
                        service,
                      ),
                      icon: Icon(
                        Icons.send,
                        color: commentController.text.isNotEmpty
                            ? Colors.blue.shade600
                            : Colors.grey.shade400,
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
  }

  void _addCommentFirebase(
    MediaItem item,
    String text,
    TextEditingController controller,
    StateSetter setState,
    FirebaseEngagementService service,
  ) async {
    if (text.trim().isEmpty) return;

    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    if (currentUser == null) {
      SnackbarUtils.showScaffoldError(context, 'Please login to comment');
      return;
    }

    try {
      final postId =
          '${widget.candidate.candidateId}_${item.title}_${item.date}';

      await service.addComment(
        postId,
        text.trim(),
        userName: widget.candidate.basicInfo?.fullName,
        userPhoto: widget.candidate.basicInfo!.photo,
      );

      controller.clear();
      setState(() {}); // Refresh the comments list

      SnackbarUtils.showScaffoldInfo(context, 'Comment added!');
    } catch (e) {
      AppLogger.candidateError('Error adding comment: $e');
      SnackbarUtils.showScaffoldError(context, 'Failed to add comment');
    }
  }

  // Get comment count for a post
  Future<int> _getCommentCount(MediaItem item) async {
    try {
      final postId =
          '${widget.candidate.candidateId}_${item.title}_${item.date}';
      final dbService = LocalDatabaseService();
      return await dbService.getCommentCountForPost(postId);
    } catch (e) {
      AppLogger.candidateError('Error getting comment count: $e');
      return 0;
    }
  }

  // Show comments in a bottom sheet (Facebook-style)
  void _showCommentsSheet(MediaItem item) {
    final TextEditingController commentController = TextEditingController();
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    if (currentUser == null) {
      SnackbarUtils.showScaffoldError(context, 'Please login to view comments');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Comments list
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getCommentsForPost(item),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User avatar
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue.shade600,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        comment['text'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatCommentTime(comment['createdAt']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.person,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Comment text field
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (text) => _addComment(
                          item,
                          text,
                          commentController,
                          setState,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button
                    IconButton(
                      onPressed: () => _addComment(
                        item,
                        commentController.text,
                        commentController,
                        setState,
                      ),
                      icon: Icon(
                        Icons.send,
                        color: commentController.text.isNotEmpty
                            ? Colors.blue.shade600
                            : Colors.grey.shade400,
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
  }

  Future<List<Map<String, dynamic>>> _getCommentsForPost(MediaItem item) async {
    try {
      final postId =
          '${widget.candidate.candidateId}_${item.title}_${item.date}';
      final dbService = LocalDatabaseService();
      return await dbService.getCommentsForPost(postId);
    } catch (e) {
      AppLogger.candidateError('Error getting comments: $e');
      return [];
    }
  }

  void _addComment(
    MediaItem item,
    String text,
    TextEditingController controller,
    StateSetter setState,
  ) async {
    if (text.trim().isEmpty) return;

    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser.value;

    if (currentUser == null) {
      SnackbarUtils.showScaffoldError(context, 'Please login to comment');
      return;
    }

    try {
      final postId =
          '${widget.candidate.candidateId}_${item.title}_${item.date}';
      final dbService = LocalDatabaseService();

      await dbService.addComment(currentUser.uid, postId, text.trim());

      controller.clear();
      setState(() {}); // Refresh the comments list

      // Force refresh of the parent widget to update comment count
      setState(() {});

      SnackbarUtils.showScaffoldInfo(context, 'Comment added!');
    } catch (e) {
      AppLogger.candidateError('Error adding comment: $e');
      SnackbarUtils.showScaffoldError(context, 'Failed to add comment');
    }
  }

  String _formatCommentTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}
