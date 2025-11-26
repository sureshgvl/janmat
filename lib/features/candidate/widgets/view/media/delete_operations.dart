import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';

class DeleteOperations {
  // Extract storage path from Firebase URL
  static String extractStoragePath(String firebaseUrl) {
    try {
      // Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
      final uri = Uri.parse(firebaseUrl);

      // Ensure this is a valid Firebase Storage URL
      if (!uri.host.contains('firebasestorage.googleapis.com') ||
          !uri.path.startsWith('/v0/b/')) {
        AppLogger.candidateError(
          'Invalid Firebase Storage URL format: $firebaseUrl',
        );
        return '';
      }

      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4) {
        AppLogger.candidateError(
          'Firebase URL does not have enough path segments: $firebaseUrl',
        );
        return '';
      }

      // Skip v0/b/bucket/o/ parts to get the actual storage path
      final storagePath = pathSegments.skip(3).join('/');
      final decodedPath = Uri.decodeComponent(storagePath);

      // Validate the extracted path
      if (decodedPath.isEmpty) {
        AppLogger.candidateError(
          'Extracted storage path is empty from: $firebaseUrl',
        );
        return '';
      }

      return decodedPath;
    } catch (e) {
      AppLogger.candidateError(
        'Failed to extract storage path from: $firebaseUrl - Error: $e',
      );
      return '';
    }
  }

  static Future<void> deletePost(
    BuildContext context,
    MediaItem item,
    Function(Candidate)? onLocalUpdate,
  ) async {
    final mediaController = Get.find<MediaController>();
    final candidateController = Get.find<CandidateUserController>();
    final candidate = candidateController.candidate.value;

    if (candidate == null) {
      SnackbarUtils.showScaffoldError(context, 'Candidate data not available');
      return;
    }

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Collect all Firebase storage URLs (exclude local paths and blob URLs)
      final firebaseImageUrls = item.images
          .where(
            (url) =>
                !FileUploadService().isLocalPath(url) &&
                !url.startsWith('blob:') &&
                url.contains('firebasestorage.googleapis.com'),
          )
          .toList();
      final firebaseVideoUrls = item.videos
          .where(
            (url) =>
                !FileUploadService().isLocalPath(url) &&
                !url.startsWith('blob:') &&
                url.contains('firebasestorage.googleapis.com'),
          )
          .toList();

      final allUrls = <String>[];
      allUrls.addAll(firebaseImageUrls);
      allUrls.addAll(firebaseVideoUrls);

      AppLogger.candidate(
        '🗑️ [DELETE] Found ${firebaseImageUrls.length} images and ${firebaseVideoUrls.length} videos to clean up',
      );
      AppLogger.candidate('🗑️ [DELETE] URLs to process: $allUrls');

      // Convert Firebase URLs to storage paths for the deleteStorage array
      final storagePathsToDelete = <String>[];
      for (final url in allUrls) {
        AppLogger.candidate('🗑️ [DELETE] Processing URL: $url');
        if (url.contains('firebasestorage.googleapis.com')) {
          try {
            final storagePath = extractStoragePath(url);
            AppLogger.candidate('🗑️ [DELETE] Extracted storage path: "$storagePath" from URL: $url');
            if (storagePath.isNotEmpty && storagePath != url) {
              // Only add if extraction succeeded and path is valid
              storagePathsToDelete.add(storagePath);
              AppLogger.candidate(
                '✅ [DELETE] Added to deleteStorage: $storagePath',
              );
            } else {
              AppLogger.candidateError(
                '⚠️ [DELETE] Failed to extract valid storage path from: $url (got: "$storagePath")',
              );
            }
          } catch (e) {
            AppLogger.candidateError(
              '⚠️ [DELETE] Exception extracting storage path from: $url - $e',
            );
          }
        } else {
          AppLogger.candidate(
            '🗑️ [DELETE] Skipping non-Firebase URL: $url',
          );
        }
      }

      // STEP 2: Add storage paths to candidate's deleteStorage array (deferred cleanup pattern)
      if (storagePathsToDelete.isNotEmpty) {
        try {
          // Get the hierarchical path for the candidate
          final candidateRef = FirebaseFirestore.instance
              .collection('states')
              .doc(candidate.location.stateId!)
              .collection('districts')
              .doc(candidate.location.districtId!)
              .collection('bodies')
              .doc(candidate.location.bodyId!)
              .collection('wards')
              .doc(candidate.location.wardId!)
              .collection('candidates')
              .doc(candidate.candidateId);

          AppLogger.candidate(
            '🗑️ [DELETE] Updating deleteStorage at path: states/${candidate.location.stateId}/districts/${candidate.location.districtId}/bodies/${candidate.location.bodyId}/wards/${candidate.location.wardId}/candidates/${candidate.candidateId}',
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
      final currentGroupedMedia = await mediaController.getMediaGrouped(
        candidate,
      );
      if (currentGroupedMedia == null) {
        throw Exception('Failed to get current media data');
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
        candidate,
        updatedMedia,
      );

      if (!success) {
        throw Exception('Failed to save updated media');
      }

      // Update local candidate data
      final updatedMediaLocal = candidate.media?.where((mediaItem) {
        if (mediaItem is Map<String, dynamic>) {
          final mediaItemObj = MediaItem.fromJson(mediaItem);
          return !(mediaItemObj.title == item.title && mediaItemObj.date == item.date);
        }
        return true;
      }).toList();

      final updatedCandidate = candidate.copyWith(media: updatedMediaLocal);
      candidateController.candidate.value = updatedCandidate;
      onLocalUpdate?.call(updatedCandidate);

      if (context.mounted) {
        SnackbarUtils.showScaffoldInfo(context, 'Post deleted successfully');
      }
    } catch (e) {
      AppLogger.candidateError('Error deleting post: $e');
      if (context.mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to delete post');
      }
    }
  }
}