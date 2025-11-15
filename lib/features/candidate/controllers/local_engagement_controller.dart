import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/candidate_model.dart';
import '../models/media_model.dart';
import '../models/engagement_operation.dart';
import '../models/like_model.dart';
import '../models/comment_model.dart';
import '../services/firebase_engagement_service.dart';
import 'candidate_user_controller.dart';

class LocalEngagementController extends GetxController {
  // Original candidate data from Firebase
  Candidate? originalCandidate;

  // Local working copy (modified during interactions)
  Rx<Candidate?> localCandidate = Rx(null);

  // Track pending operations for sync
  final RxList<EngagementOperation> pendingOperations = <EngagementOperation>[].obs;

  // Sync status
  final RxBool isSyncing = false.obs;
  final RxBool hasSyncErrors = false.obs;

  final FirebaseEngagementService _engagementService = FirebaseEngagementService();

  // Initialize local copy when entering profile
  void initializeLocalCopy(Candidate candidate) {
    AppLogger.candidate('🎯 [LOCAL_ENGAGEMENT] Initializing local copy for candidate: ${candidate.candidateId}');

    originalCandidate = candidate;
    localCandidate.value = candidate.copyWith(); // Deep copy
    pendingOperations.clear();
    hasSyncErrors.value = false;

    AppLogger.candidate('🎯 [LOCAL_ENGAGEMENT] Local copy initialized with ${candidate.media?.length ?? 0} media items');
  }

  // Update local like status immediately
  void updateLocalLike(MediaItem item, bool liked, String userId, Map<String, String> userInfo) {
    if (localCandidate.value == null) return;

    AppLogger.candidate('👍 [LOCAL_ENGAGEMENT] Updating local like - item: ${item.title}, liked: $liked');

    final updatedMedia = localCandidate.value!.media?.map((mediaData) {
      final parsedItem = MediaItem.fromJson(mediaData as Map<String, dynamic>);
      if (parsedItem.title == item.title && parsedItem.date == item.date) {
        // Create updated likes based on the operation
        final updatedLikes = liked
          ? [...parsedItem.likes, Like(
              id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
              userId: userId,
              postId: '${localCandidate.value!.candidateId}_${item.title}_${item.date}',
              mediaKey: 'post',
              createdAt: DateTime.now(),
              userName: userInfo['name'],
              userPhoto: userInfo['photo'],
            )]
          : parsedItem.likes.where((like) => like.userId != userId).toList();

        return parsedItem.copyWith(likes: updatedLikes).toJson();
      }
      return mediaData;
    }).toList();

    // Update local candidate
    localCandidate.value = localCandidate.value!.copyWith(media: updatedMedia);

    // Track operation for later sync
    final operation = LikeOperation(
      item: item,
      liked: liked,
      userId: userId,
      userInfo: userInfo,
    );
    pendingOperations.add(operation);

    AppLogger.candidate('👍 [LOCAL_ENGAGEMENT] Local like updated. Pending operations: ${pendingOperations.length}');
  }

  // Add local comment immediately
  void addLocalComment(MediaItem item, String text, String userId, Map<String, String> userInfo) {
    if (localCandidate.value == null) return;

    AppLogger.candidate('💬 [LOCAL_ENGAGEMENT] Adding local comment - item: ${item.title}, text: ${text.substring(0, min(50, text.length))}...');

    final updatedMedia = localCandidate.value!.media?.map((mediaData) {
      final parsedItem = MediaItem.fromJson(mediaData as Map<String, dynamic>);
      if (parsedItem.title == item.title && parsedItem.date == item.date) {
        // Add new comment
        final newComment = Comment(
          id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          postId: '${localCandidate.value!.candidateId}_${item.title}_${item.date}',
          text: text,
          createdAt: DateTime.now(),
          userName: userInfo['name'],
          userPhoto: userInfo['photo'],
        );
        final updatedComments = [...parsedItem.comments, newComment];
        return parsedItem.copyWith(comments: updatedComments).toJson();
      }
      return mediaData;
    }).toList();

    // Update local candidate
    localCandidate.value = localCandidate.value!.copyWith(media: updatedMedia);

    // Track operation for later sync
    final operation = CommentOperation(
      item: item,
      text: text,
      userId: userId,
      userInfo: userInfo,
    );
    pendingOperations.add(operation);

    AppLogger.candidate('💬 [LOCAL_ENGAGEMENT] Local comment added. Pending operations: ${pendingOperations.length}');
  }

  // Sync all pending operations to Firebase
  Future<void> syncPendingOperations() async {
    if (pendingOperations.isEmpty || localCandidate.value == null) {
      AppLogger.candidate('🔄 [LOCAL_ENGAGEMENT] No pending operations to sync');
      return;
    }

    AppLogger.candidate('🔄 [LOCAL_ENGAGEMENT] Starting sync of ${pendingOperations.length} operations');

    isSyncing.value = true;
    hasSyncErrors.value = false;

    try {
      final candidate = localCandidate.value!;

      // Group operations by type for batch processing
      final likeOperations = pendingOperations.whereType<LikeOperation>().toList();
      final commentOperations = pendingOperations.whereType<CommentOperation>().toList();

      // Process like operations
      for (final operation in likeOperations) {
        try {
          if (operation.liked) {
            await _engagementService.addLikeToMediaItem(
              candidateId: candidate.candidateId,
              stateId: candidate.location.stateId ?? '',
              districtId: candidate.location.districtId ?? '',
              bodyId: candidate.location.bodyId ?? '',
              wardId: candidate.location.wardId ?? '',
              mediaItem: operation.item,
              userName: operation.userInfo['name'],
              userPhoto: operation.userInfo['photo'],
            );
          } else {
            await _engagementService.removeLikeFromMediaItem(
              candidateId: candidate.candidateId,
              stateId: candidate.location.stateId ?? '',
              districtId: candidate.location.districtId ?? '',
              bodyId: candidate.location.bodyId ?? '',
              wardId: candidate.location.wardId ?? '',
              mediaItem: operation.item,
            );
          }
          AppLogger.candidate('✅ [LOCAL_ENGAGEMENT] Synced like operation: ${operation.operationId}');
        } catch (e) {
          AppLogger.candidateError('❌ [LOCAL_ENGAGEMENT] Failed to sync like operation: ${operation.operationId} - $e');
          hasSyncErrors.value = true;
          // Continue with other operations
        }
      }

      // Process comment operations
      for (final operation in commentOperations) {
        try {
          await _engagementService.addCommentToMediaItem(
            candidateId: candidate.candidateId,
            stateId: candidate.location.stateId ?? '',
            districtId: candidate.location.districtId ?? '',
            bodyId: candidate.location.bodyId ?? '',
            wardId: candidate.location.wardId ?? '',
            mediaItem: operation.item,
            text: operation.text,
            userName: operation.userInfo['name'],
            userPhoto: operation.userInfo['photo'],
          );
          AppLogger.candidate('✅ [LOCAL_ENGAGEMENT] Synced comment operation: ${operation.operationId}');
        } catch (e) {
          AppLogger.candidateError('❌ [LOCAL_ENGAGEMENT] Failed to sync comment operation: ${operation.operationId} - $e');
          hasSyncErrors.value = true;
          // Continue with other operations
        }
      }

      // Clear successful operations
      if (!hasSyncErrors.value) {
        pendingOperations.clear();
        AppLogger.candidate('🎉 [LOCAL_ENGAGEMENT] All operations synced successfully');
      } else {
        // Keep failed operations for retry
        AppLogger.candidate('⚠️ [LOCAL_ENGAGEMENT] Some operations failed, keeping for retry');
      }

    } catch (e) {
      AppLogger.candidateError('❌ [LOCAL_ENGAGEMENT] Sync failed: $e');
      hasSyncErrors.value = true;
    } finally {
      isSyncing.value = false;
    }
  }

  // Retry failed sync operations
  Future<void> retrySync() async {
    if (!hasSyncErrors.value) return;

    AppLogger.candidate('🔄 [LOCAL_ENGAGEMENT] Retrying sync...');
    await syncPendingOperations();
  }

  // Discard all local changes (when navigating away without proper exit)
  void discardLocalChanges() {
    AppLogger.candidate('🗑️ [LOCAL_ENGAGEMENT] Discarding local changes');

    localCandidate.value = originalCandidate?.copyWith();
    pendingOperations.clear();
    hasSyncErrors.value = false;
    isSyncing.value = false;
  }

  // Get pending operations count
  int get pendingOperationsCount => pendingOperations.length;

  // Check if there are unsynced changes
  bool get hasUnsyncedChanges => pendingOperations.isNotEmpty;

  int min(int a, int b) => a < b ? a : b;
}
