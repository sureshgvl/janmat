import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/widgets/view/media/post_composer.dart';
import 'package:janmat/features/candidate/widgets/view/media/post_card.dart';
import 'package:janmat/features/candidate/widgets/view/media/empty_state.dart';
import 'package:janmat/features/candidate/widgets/view/media/media_data_processor.dart';
import 'package:janmat/features/candidate/widgets/view/media/media_navigation_handler.dart';
import 'package:janmat/features/candidate/widgets/view/media/media_storage_utils.dart';
import 'package:janmat/controllers/background_color_controller.dart';

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
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CandidateUserController>(
      id: 'media_view_${widget.candidate.candidateId}', // Unique ID for selective rebuilds
      builder: (candidateController) {
        // Get the latest candidate data from controller
        final currentCandidate = candidateController.candidate.value ?? widget.candidate;

        return MediaTabView(
          candidate: currentCandidate,
          isOwnProfile: widget.isOwnProfile,
          onLocalUpdate: (updatedCandidate) {
            // Update the controller with local changes
            candidateController.candidate.value = updatedCandidate;
            // Force a complete rebuild by updating without specific ID
            candidateController.update();
          },
        );
      },
    );
  }
}

class _MediaTabViewState extends State<MediaTabView> {
  late final MediaDataProcessor _mediaDataProcessor;
  late final MediaNavigationHandler _navigationHandler;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _mediaDataProcessor = MediaDataProcessor();
    _navigationHandler = MediaNavigationHandler(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColorController = Get.find<BackgroundColorController>();
    
    // Process media data using the extracted component
    final mediaItems = _mediaDataProcessor.processMediaData(widget.candidate);

    return Container(
      color: backgroundColorController.currentBackgroundColor.value,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facebook-style "What's on your mind?" Composer (only for own profile)
            if (widget.isOwnProfile) ...[
              const SizedBox(height: 16),
              _buildPostComposer(),
              const SizedBox(height: 8),
              _buildCleanupButton(),
            ],

            const SizedBox(height: 16),

            // Media Posts Timeline (all saved media posts)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mediaItems.length,
              itemBuilder: (context, index) => _buildPostCard(mediaItems[index]),
            ),

            // Empty State
            if (mediaItems.isEmpty) ...[
              const SizedBox(height: 40),
              MediaEmptyState(isOwnProfile: widget.isOwnProfile),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build Facebook-style "What's on your mind?" post composer
  Widget _buildPostComposer() {
    return FacebookStylePostComposer(
      candidate: widget.candidate,
      onTap: () => _navigationHandler.navigateToAddPost(widget.candidate),
    );
  }

  /// Build cleanup button for corrupted posts (only for own profile)
  Widget _buildCleanupButton() {
    // Check if there are corrupted posts by comparing raw vs filtered data
    final rawMediaCount = widget.candidate.media?.length ?? 0;
    final filteredMediaCount = _mediaDataProcessor.getMediaItemsCount(widget.candidate);
    final hasCorruptedPosts = rawMediaCount > filteredMediaCount;

    if (!hasCorruptedPosts) {
      return const SizedBox.shrink(); // Don't show button if no corrupted posts
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _cleanupCorruptedPosts,
        icon: const Icon(Icons.cleaning_services, size: 16),
        label: Text('Clean Up $rawMediaCount Corrupted Posts'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  /// Build Facebook-style media post card
  Widget _buildPostCard(MediaItem item) {
    return FacebookStylePostCard(
      item: item,
      candidate: widget.candidate,
      isOwnProfile: widget.isOwnProfile,
      onEdit: (item) => _navigationHandler.navigateToEditPost(widget.candidate, item),
      onDelete: (item) => _showDeleteConfirmation(item),
      onImageTap: _showImageGallery,
      onItemUpdated: _handleItemUpdated,
    );
  }

  /// Show image gallery when image is tapped
  void _showImageGallery(List<String> images, int initialIndex) {
    _navigationHandler.showImageGallery(images, initialIndex);
  }

  /// Handle item updates (like likes, comments) for optimistic UI updates
  void _handleItemUpdated(MediaItem updatedItem) {
    AppLogger.candidate('🔄 [MEDIA_VIEW] _handleItemUpdated called for post: ${updatedItem.title}');
    AppLogger.candidate('📊 [MEDIA_VIEW] Updated like count: ${updatedItem.likeCount}, comment count: ${updatedItem.commentCount}');

    // Update the local candidate data with the updated media item
    if (widget.onLocalUpdate != null) {
      AppLogger.candidate('✅ [MEDIA_VIEW] onLocalUpdate callback is available');

      final updatedMedia = widget.candidate.media?.map((mediaData) {
        final parsedItem = MediaItem.fromJson(mediaData as Map<String, dynamic>);
        if (parsedItem.title == updatedItem.title && parsedItem.date == updatedItem.date) {
          AppLogger.candidate('🔄 [MEDIA_VIEW] Found matching media item, updating it');
          return updatedItem.toJson();
        }
        return mediaData;
      }).toList();

      AppLogger.candidate('📦 [MEDIA_VIEW] Created updated media list with ${updatedMedia?.length ?? 0} items');

      final updatedCandidate = widget.candidate.copyWith(media: updatedMedia);
      AppLogger.candidate('👤 [MEDIA_VIEW] Created updated candidate object');

      widget.onLocalUpdate!(updatedCandidate);
      AppLogger.candidate('✅ [MEDIA_VIEW] Called onLocalUpdate callback - UI should update now');
    } else {
      AppLogger.candidate('❌ [MEDIA_VIEW] onLocalUpdate callback is NULL - UI will not update');
    }
  }



  /// Delete confirmation and processing
  void _showDeleteConfirmation(MediaItem item) {
    _navigationHandler.showDeleteConfirmation(
      item,
      () => _deletePost(item),
    );
  }

  void _deletePost(MediaItem item) async {
    // Validate candidate location data before proceeding
    if (widget.candidate.location.stateId == null ||
        widget.candidate.location.districtId == null ||
        widget.candidate.location.bodyId == null ||
        widget.candidate.location.wardId == null ||
        widget.candidate.candidateId.isEmpty) {
      _navigationHandler.showErrorMessage('Cannot delete post: missing candidate location data');
      return;
    }

    // Show loading overlay
    _navigationHandler.showLoadingDialog(
      title: 'Deleting Post',
      message: 'Scheduling cleanup...',
      barrierDismissible: false,
    );

    AppLogger.candidate(
      '🗑️ [DELETE] Starting deletion of post: "${item.title}" (${item.date})',
    );

    try {
      // Ensure MediaController is initialized
      if (!Get.isRegistered<MediaController>()) {
        Get.put<MediaController>(MediaController());
        AppLogger.candidate('✅ MediaController initialized for delete operation');
      }
      final mediaController = Get.find<MediaController>();

      // Use storage utilities to extract paths
      final allUrls = <String>[];
      allUrls.addAll(item.images);
      allUrls.addAll(item.videos);

      final storagePathsToDelete = MediaStorageUtils.extractValidStoragePaths(allUrls);

      // Update deleteStorage array if needed
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
      }

      // Update loading dialog message
      _navigationHandler.showLoadingDialog(
        title: 'Deleting Post',
        message: 'Updating profile...',
        barrierDismissible: false,
      );

      // Remove item from Firebase document
      final currentGroupedMedia = await mediaController.getMediaGrouped(widget.candidate);
      if (currentGroupedMedia == null) {
        _navigationHandler.dismissDialog();
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
        // Refresh candidate data and update UI
        await _refreshCandidateData();
        _navigationHandler.dismissDialog();
        _navigationHandler.showSuccessMessage('Post deleted successfully');
      } else {
        _navigationHandler.dismissDialog();
        _navigationHandler.showErrorMessage('Failed to delete post');
      }
    } catch (e) {
      _navigationHandler.dismissDialog();
      AppLogger.candidateError('Error deleting post: $e');
      _navigationHandler.showErrorMessage('Error deleting post: $e');
    }
  }

  /// Refresh candidate data after operations
  Future<void> _refreshCandidateData() async {
    try {
      final candidateController = Get.find<CandidateUserController>();
      await candidateController.refreshCandidateData();

      // Force UI refresh after data is updated
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      AppLogger.candidateError(
        'Error refreshing candidate data: $e',
      );
      // Still force UI refresh even if refresh fails
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Clean up corrupted posts with blob URLs from Firebase
  Future<void> _cleanupCorruptedPosts() async {
    try {
      AppLogger.candidate('🧹 [CLEANUP] Starting cleanup of corrupted posts with blob URLs');

      // Get raw media data directly from Firebase (bypass filtering)
      final mediaController = Get.find<MediaController>();
      final rawMediaData = await mediaController.getMediaGrouped(widget.candidate);

      if (rawMediaData == null || rawMediaData.isEmpty) {
        AppLogger.candidate('🧹 [CLEANUP] No media data found');
        return;
      }

      // Filter out corrupted posts (those with blob URLs)
      final cleanMediaData = rawMediaData.where((mediaItem) {
        final item = mediaItem as Map<String, dynamic>;
        final images = item['images'] as List<dynamic>? ?? [];

        final hasBlobUrls = images.any((url) => url.toString().startsWith('blob:'));
        if (hasBlobUrls) {
          AppLogger.candidate('🧹 [CLEANUP] Removing corrupted post: ${item['title']}');
          return false;
        }
        return true;
      }).toList();

      final removedCount = rawMediaData.length - cleanMediaData.length;
      AppLogger.candidate('🧹 [CLEANUP] Removed $removedCount corrupted posts');

      // Save the cleaned data back to Firebase
      final success = await mediaController.saveMediaGrouped(widget.candidate, cleanMediaData);

      if (success) {
        AppLogger.candidate('✅ [CLEANUP] Successfully cleaned corrupted posts');
        await _refreshCandidateData();
        _navigationHandler.showSuccessMessage('Corrupted posts cleaned up successfully');
      } else {
        AppLogger.candidateError('❌ [CLEANUP] Failed to save cleaned data');
        _navigationHandler.showErrorMessage('Failed to clean up corrupted posts');
      }

    } catch (e) {
      AppLogger.candidateError('❌ [CLEANUP] Error during cleanup: $e');
      _navigationHandler.showErrorMessage('Error cleaning up corrupted posts: $e');
    }
  }
}
