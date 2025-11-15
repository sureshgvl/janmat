import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../../../features/user/models/user_model.dart';
import '../models/like_model.dart';
import '../models/comment_model.dart';
import '../models/media_model.dart';

class FirebaseEngagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Embedded engagement operations - works with MediaItem data stored in candidate document

  // Like operations - now work with embedded data in MediaItem
  Future<void> addLikeToMediaItem({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    String? userName,
    String? userPhoto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final like = Like(
      id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      postId: '${candidateId}_${mediaItem.title}_${mediaItem.date}',
      mediaKey: 'post',
      createdAt: DateTime.now(),
      userName: userName,
      userPhoto: userPhoto,
    );

    // Create a new MediaItem with the like added (don't modify the original)
    final updatedMediaItem = MediaItem(
      title: mediaItem.title,
      date: mediaItem.date,
      images: mediaItem.images,
      videos: mediaItem.videos,
      youtubeLinks: mediaItem.youtubeLinks,
      addedDate: mediaItem.addedDate,
      likes: [...mediaItem.likes.where((existingLike) => existingLike.userId != user.uid), like],
      comments: mediaItem.comments,
    );

    // Update the candidate document with the modified media item
    await _updateMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: updatedMediaItem,
    );

    AppLogger.database('✅ FirebaseEngagement: Like added to media item - ${like.id}');
  }

  Future<void> removeLikeFromMediaItem({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Create a new MediaItem with the like removed (don't modify the original)
    final updatedMediaItem = MediaItem(
      title: mediaItem.title,
      date: mediaItem.date,
      images: mediaItem.images,
      videos: mediaItem.videos,
      youtubeLinks: mediaItem.youtubeLinks,
      addedDate: mediaItem.addedDate,
      likes: mediaItem.likes.where((like) => like.userId != user.uid).toList(),
      comments: mediaItem.comments,
    );

    // Update the candidate document with the modified media item
    await _updateMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: updatedMediaItem,
    );

    AppLogger.database('✅ FirebaseEngagement: Like removed from media item');
  }

  Future<bool> hasUserLikedMediaItem(MediaItem mediaItem) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    return mediaItem.hasUserLiked(user.uid);
  }

  // Comment operations - now work with embedded data in MediaItem
  Future<void> addCommentToMediaItem({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    required String text,
    String? parentId,
    String? userName,
    String? userPhoto,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final comment = Comment(
      id: '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      postId: '${candidateId}_${mediaItem.title}_${mediaItem.date}',
      text: text,
      createdAt: DateTime.now(),
      parentId: parentId,
      userName: userName,
      userPhoto: userPhoto,
    );

    // Create a new MediaItem with the comment added (don't modify the original)
    final updatedMediaItem = MediaItem(
      title: mediaItem.title,
      date: mediaItem.date,
      images: mediaItem.images,
      videos: mediaItem.videos,
      youtubeLinks: mediaItem.youtubeLinks,
      addedDate: mediaItem.addedDate,
      likes: mediaItem.likes,
      comments: [...mediaItem.comments, comment],
    );

    // Update the candidate document with the modified media item
    await _updateMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: updatedMediaItem,
    );

    AppLogger.database('✅ FirebaseEngagement: Comment added to media item - ${comment.id}');
  }

  // Helper method to update media item in candidate document
  Future<void> _updateMediaItemInCandidate({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
  }) async {
    final candidateRef = _firestore
        .collection('states')
        .doc(stateId)
        .collection('districts')
        .doc(districtId)
        .collection('bodies')
        .doc(bodyId)
        .collection('wards')
        .doc(wardId)
        .collection('candidates')
        .doc(candidateId);

    // Get current candidate data from Firestore (always fresh)
    final candidateDoc = await candidateRef.get(const GetOptions(source: Source.server));
    if (!candidateDoc.exists) {
      throw Exception('Candidate document not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final mediaList = List<Map<String, dynamic>>.from(candidateData['media'] ?? []);

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      final existingItem = MediaItem.fromJson(mediaList[i]);
      if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
        // SIMPLIFIED FIX: The mediaItem parameter should already contain correctly merged data
        // Just use it directly - the calling methods (addLikeToMediaItem, addCommentToMediaItem)
        // are responsible for creating the correct merged MediaItem
        final finalUpdatedItem = mediaItem;

        mediaList[i] = finalUpdatedItem.toJson();
        itemFound = true;

        AppLogger.database('🔄 FirebaseEngagement: Updating media item with ${mediaItem.likes.length} likes and ${mediaItem.comments.length} comments');
        break;
      }
    }

    if (!itemFound) {
      throw Exception('Media item not found in candidate document');
    }

    // Update the candidate document with merged data
    await candidateRef.update({
      'media': mediaList,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.database('✅ FirebaseEngagement: Media item updated successfully with preserved data');
  }

  // Legacy methods for backward compatibility (deprecated)
  Future<void> addLike(String postId, String mediaKey, {String? userName, String? userPhoto}) async {
    AppLogger.database('⚠️ FirebaseEngagement: addLike is deprecated - use addLikeToMediaItem instead');
    throw Exception('Use addLikeToMediaItem instead');
  }

  Future<void> removeLike(String postId, String mediaKey) async {
    AppLogger.database('⚠️ FirebaseEngagement: removeLike is deprecated - use removeLikeFromMediaItem instead');
    throw Exception('Use removeLikeFromMediaItem instead');
  }

  Future<bool> hasUserLiked(String postId, String mediaKey) async {
    AppLogger.database('⚠️ FirebaseEngagement: hasUserLiked is deprecated - use hasUserLikedMediaItem instead');
    return false;
  }

  Future<int> getLikeCount(String postId, String mediaKey) async {
    AppLogger.database('⚠️ FirebaseEngagement: getLikeCount is deprecated - use MediaItem.likeCount instead');
    return 0;
  }

  Stream<int> getLikeCountStream(String postId, String mediaKey) {
    AppLogger.database('⚠️ FirebaseEngagement: getLikeCountStream is deprecated - listen to candidate document instead');
    return Stream.value(0);
  }

  Future<void> addComment(String postId, String text, {String? parentId, String? userName, String? userPhoto}) async {
    AppLogger.database('⚠️ FirebaseEngagement: addComment is deprecated - use addCommentToMediaItem instead');
    throw Exception('Use addCommentToMediaItem instead');
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    AppLogger.database('⚠️ FirebaseEngagement: getCommentsForPost is deprecated - use MediaItem.comments instead');
    return [];
  }

  Future<int> getCommentCount(String postId) async {
    AppLogger.database('⚠️ FirebaseEngagement: getCommentCount is deprecated - use MediaItem.commentCount instead');
    return 0;
  }

  Stream<List<Comment>> getCommentsStream(String postId) {
    AppLogger.database('⚠️ FirebaseEngagement: getCommentsStream is deprecated - listen to candidate document instead');
    return Stream.value([]);
  }

  Stream<int> getCommentCountStream(String postId) {
    AppLogger.database('⚠️ FirebaseEngagement: getCommentCountStream is deprecated - listen to candidate document instead');
    return Stream.value(0);
  }
}
