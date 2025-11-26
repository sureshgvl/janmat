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
    AppLogger.database('🚀 FirebaseEngagement: addLikeToMediaItem called for post "${mediaItem.title}" by user', tag: 'ENGAGEMENT');

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

    // Update the candidate document with the like
    // The _updateMediaItemInCandidate method will get fresh data and merge correctly
    await _addLikeToMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: mediaItem,
      like: like,
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

    // Update the candidate document to remove the like
    await _removeLikeFromMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: mediaItem,
      userId: user.uid,
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
    AppLogger.database('🚀 FirebaseEngagement: addCommentToMediaItem called for post "${mediaItem.title}" with text: "$text"', tag: 'ENGAGEMENT');

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

    // Update the candidate document with the comment
    await _addCommentToMediaItemInCandidate(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      mediaItem: mediaItem,
      comment: comment,
    );

    AppLogger.database('✅ FirebaseEngagement: Comment added to media item - ${comment.id}');
  }

  // Helper method to add like to media item in candidate document
  Future<void> _addLikeToMediaItemInCandidate({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    required Like like,
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

    AppLogger.database('📍 FirebaseEngagement: Document path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'ENGAGEMENT');

    // Get current candidate data from Firestore (always fresh)
    final candidateDoc = await candidateRef.get(const GetOptions(source: Source.server));
    if (!candidateDoc.exists) {
      throw Exception('Candidate document not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final mediaList = List<Map<String, dynamic>>.from(candidateData['media'] ?? []);

    AppLogger.database('🔍 FirebaseEngagement: Adding like to media item "${mediaItem.title}" from ${mediaItem.date}');

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      try {
        final existingItem = MediaItem.fromJson(mediaList[i]);
        if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
          AppLogger.database('✅ FirebaseEngagement: Found matching item at index $i');

          // Remove existing like from same user if exists, then add new like
          final updatedLikes = [...existingItem.likes.where((existingLike) => existingLike.userId != like.userId), like];

          // Create updated media item with new likes (preserve all other data)
          final updatedMediaItem = MediaItem(
            title: existingItem.title,
            date: existingItem.date,
            images: existingItem.images,
            videos: existingItem.videos,
            youtubeLinks: existingItem.youtubeLinks,
            addedDate: existingItem.addedDate,
            likes: updatedLikes,
            comments: existingItem.comments, // Preserve existing comments
          );

          mediaList[i] = updatedMediaItem.toJson();
          itemFound = true;

          AppLogger.database('🔄 FirebaseEngagement: Added like, now has ${updatedLikes.length} likes and ${existingItem.comments.length} comments');
          break;
        }
      } catch (e) {
        AppLogger.database('❌ FirebaseEngagement: Error parsing media item at index $i: $e');
        continue;
      }
    }

    if (!itemFound) {
      throw Exception('Media item not found in candidate document');
    }

    // Update the candidate document
    AppLogger.database('🔄 FirebaseEngagement: Updating document with ${mediaList.length} media items', tag: 'ENGAGEMENT');
    if (mediaList.isNotEmpty) {
      final firstItem = mediaList.first;
      AppLogger.database('🔄 FirebaseEngagement: Updated first item likes: ${firstItem['likes']?.length ?? 0}', tag: 'ENGAGEMENT');
      AppLogger.database('🔄 FirebaseEngagement: Updated first item comments: ${firstItem['comments']?.length ?? 0}', tag: 'ENGAGEMENT');
    }

    try {
      await candidateRef.update({
        'media': mediaList,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Verify the update actually took effect
      final verifyDoc = await candidateRef.get(const GetOptions(source: Source.server));
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data() as Map<String, dynamic>;
        final verifyMediaList = List<Map<String, dynamic>>.from(verifyData['media'] ?? []);
        if (verifyMediaList.isNotEmpty) {
          final firstItem = verifyMediaList.first;
          final likesCount = (firstItem['likes'] as List?)?.length ?? 0;
          AppLogger.database('✅ FirebaseEngagement: Like added successfully - verified ${likesCount} likes in database', tag: 'ENGAGEMENT');
        } else {
          AppLogger.database('❌ FirebaseEngagement: Update completed but media list is empty in database!', tag: 'ENGAGEMENT');
        }
      } else {
        AppLogger.database('❌ FirebaseEngagement: Update completed but document no longer exists!', tag: 'ENGAGEMENT');
      }
    } catch (updateError) {
      AppLogger.database('❌ FirebaseEngagement: Failed to update document: $updateError', tag: 'ENGAGEMENT');
      rethrow;
    }
  }

  // Helper method to remove like from media item in candidate document
  Future<void> _removeLikeFromMediaItemInCandidate({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    required String userId,
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

    AppLogger.database('📍 FirebaseEngagement: Document path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'ENGAGEMENT');

    // Get current candidate data from Firestore (always fresh)
    final candidateDoc = await candidateRef.get(const GetOptions(source: Source.server));
    if (!candidateDoc.exists) {
      throw Exception('Candidate document not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final mediaList = List<Map<String, dynamic>>.from(candidateData['media'] ?? []);

    AppLogger.database('🔍 FirebaseEngagement: Removing like from media item "${mediaItem.title}" from ${mediaItem.date}');

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      try {
        final existingItem = MediaItem.fromJson(mediaList[i]);
        if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
          AppLogger.database('✅ FirebaseEngagement: Found matching item at index $i');

          // Remove like from this user
          final updatedLikes = existingItem.likes.where((like) => like.userId != userId).toList();

          // Create updated media item with removed like (preserve all other data)
          final updatedMediaItem = MediaItem(
            title: existingItem.title,
            date: existingItem.date,
            images: existingItem.images,
            videos: existingItem.videos,
            youtubeLinks: existingItem.youtubeLinks,
            addedDate: existingItem.addedDate,
            likes: updatedLikes,
            comments: existingItem.comments, // Preserve existing comments
          );

          mediaList[i] = updatedMediaItem.toJson();
          itemFound = true;

          AppLogger.database('🔄 FirebaseEngagement: Removed like, now has ${updatedLikes.length} likes and ${existingItem.comments.length} comments');
          break;
        }
      } catch (e) {
        AppLogger.database('❌ FirebaseEngagement: Error parsing media item at index $i: $e');
        continue;
      }
    }

    if (!itemFound) {
      throw Exception('Media item not found in candidate document');
    }

    // Update the candidate document
    try {
      await candidateRef.update({
        'media': mediaList,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.database('✅ FirebaseEngagement: Like removed successfully');
    } catch (updateError) {
      AppLogger.database('❌ FirebaseEngagement: Failed to update document: $updateError', tag: 'ENGAGEMENT');
      rethrow;
    }
  }

  // Helper method to add comment to media item in candidate document
  Future<void> _addCommentToMediaItemInCandidate({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    required Comment comment,
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

    AppLogger.database('📍 FirebaseEngagement: Document path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'ENGAGEMENT');

    // Get current candidate data from Firestore (always fresh)
    final candidateDoc = await candidateRef.get(const GetOptions(source: Source.server));
    if (!candidateDoc.exists) {
      throw Exception('Candidate document not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final mediaList = List<Map<String, dynamic>>.from(candidateData['media'] ?? []);

    AppLogger.database('🔍 FirebaseEngagement: Current media list has ${mediaList.length} items', tag: 'ENGAGEMENT');
    if (mediaList.isNotEmpty) {
      final firstItem = mediaList.first;
      AppLogger.database('🔍 FirebaseEngagement: First item keys: ${firstItem.keys.toList()}', tag: 'ENGAGEMENT');
      AppLogger.database('🔍 FirebaseEngagement: First item likes: ${firstItem['likes']}', tag: 'ENGAGEMENT');
      AppLogger.database('🔍 FirebaseEngagement: First item comments: ${firstItem['comments']}', tag: 'ENGAGEMENT');
    }

    AppLogger.database('🔍 FirebaseEngagement: Adding comment to media item "${mediaItem.title}" from ${mediaItem.date}');

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      try {
        final existingItem = MediaItem.fromJson(mediaList[i]);
        if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
          AppLogger.database('✅ FirebaseEngagement: Found matching item at index $i');

          // Add new comment to existing comments
          final updatedComments = [...existingItem.comments, comment];

          // Create updated media item with new comment (preserve all other data)
          final updatedMediaItem = MediaItem(
            title: existingItem.title,
            date: existingItem.date,
            images: existingItem.images,
            videos: existingItem.videos,
            youtubeLinks: existingItem.youtubeLinks,
            addedDate: existingItem.addedDate,
            likes: existingItem.likes, // Preserve existing likes
            comments: updatedComments,
          );

          mediaList[i] = updatedMediaItem.toJson();
          itemFound = true;

          AppLogger.database('🔄 FirebaseEngagement: Added comment, now has ${existingItem.likes.length} likes and ${updatedComments.length} comments');
          break;
        }
      } catch (e) {
        AppLogger.database('❌ FirebaseEngagement: Error parsing media item at index $i: $e');
        continue;
      }
    }

    if (!itemFound) {
      throw Exception('Media item not found in candidate document');
    }

    // Update the candidate document
    try {
      await candidateRef.update({
        'media': mediaList,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Verify the update actually took effect
      final verifyDoc = await candidateRef.get(const GetOptions(source: Source.server));
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data() as Map<String, dynamic>;
        final verifyMediaList = List<Map<String, dynamic>>.from(verifyData['media'] ?? []);
        if (verifyMediaList.isNotEmpty) {
          final firstItem = verifyMediaList.first;
          final commentsCount = (firstItem['comments'] as List?)?.length ?? 0;
          AppLogger.database('✅ FirebaseEngagement: Comment added successfully - verified ${commentsCount} comments in database', tag: 'ENGAGEMENT');
        } else {
          AppLogger.database('❌ FirebaseEngagement: Update completed but media list is empty in database!', tag: 'ENGAGEMENT');
        }
      } else {
        AppLogger.database('❌ FirebaseEngagement: Update completed but document no longer exists!', tag: 'ENGAGEMENT');
      }
    } catch (updateError) {
      AppLogger.database('❌ FirebaseEngagement: Failed to update document: $updateError', tag: 'ENGAGEMENT');
      rethrow;
    }
  }

  // Delete comment from media item
  Future<void> deleteCommentFromMediaItem({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    required MediaItem mediaItem,
    required String commentId,
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

    AppLogger.database('📍 FirebaseEngagement: Document path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'ENGAGEMENT');

    // Get current candidate data from Firestore (always fresh)
    final candidateDoc = await candidateRef.get(const GetOptions(source: Source.server));
    if (!candidateDoc.exists) {
      throw Exception('Candidate document not found');
    }

    final candidateData = candidateDoc.data() as Map<String, dynamic>;
    final mediaList = List<Map<String, dynamic>>.from(candidateData['media'] ?? []);

    AppLogger.database('🔍 FirebaseEngagement: Deleting comment $commentId from media item "${mediaItem.title}" from ${mediaItem.date}');

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      try {
        final existingItem = MediaItem.fromJson(mediaList[i]);
        if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
          AppLogger.database('✅ FirebaseEngagement: Found matching item at index $i');

          // Remove the specific comment
          final updatedComments = existingItem.comments.where((comment) => comment.id != commentId).toList();

          // Create updated media item with removed comment (preserve all other data)
          final updatedMediaItem = MediaItem(
            title: existingItem.title,
            date: existingItem.date,
            images: existingItem.images,
            videos: existingItem.videos,
            youtubeLinks: existingItem.youtubeLinks,
            addedDate: existingItem.addedDate,
            likes: existingItem.likes, // Preserve existing likes
            comments: updatedComments,
          );

          mediaList[i] = updatedMediaItem.toJson();
          itemFound = true;

          AppLogger.database('🔄 FirebaseEngagement: Removed comment, now has ${existingItem.likes.length} likes and ${updatedComments.length} comments');
          break;
        }
      } catch (e) {
        AppLogger.database('❌ FirebaseEngagement: Error parsing media item at index $i: $e');
        continue;
      }
    }

    if (!itemFound) {
      throw Exception('Media item not found in candidate document');
    }

    // Update the candidate document
    try {
      await candidateRef.update({
        'media': mediaList,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.database('✅ FirebaseEngagement: Comment deleted successfully');
    } catch (updateError) {
      AppLogger.database('❌ FirebaseEngagement: Failed to update document: $updateError', tag: 'ENGAGEMENT');
      rethrow;
    }
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

    AppLogger.database('🔍 FirebaseEngagement: Looking for media item "${mediaItem.title}" from ${mediaItem.date}');
    AppLogger.database('📊 FirebaseEngagement: Found ${mediaList.length} media items in document');

    // Find and update the specific media item
    bool itemFound = false;
    for (int i = 0; i < mediaList.length; i++) {
      try {
        final existingItem = MediaItem.fromJson(mediaList[i]);
        AppLogger.database('🔍 FirebaseEngagement: Checking item ${i}: "${existingItem.title}" from ${existingItem.date}');

        if (existingItem.title == mediaItem.title && existingItem.date == mediaItem.date) {
          AppLogger.database('✅ FirebaseEngagement: Found matching item at index $i');
          AppLogger.database('📊 FirebaseEngagement: Existing item has ${existingItem.likes.length} likes and ${existingItem.comments.length} comments');
          AppLogger.database('📊 FirebaseEngagement: New item has ${mediaItem.likes.length} likes and ${mediaItem.comments.length} comments');

          // Use the mediaItem parameter which should already contain correctly merged data
          mediaList[i] = mediaItem.toJson();
          itemFound = true;

          AppLogger.database('🔄 FirebaseEngagement: Updated media item with ${mediaItem.likes.length} likes and ${mediaItem.comments.length} comments');
          break;
        }
      } catch (e) {
        AppLogger.database('❌ FirebaseEngagement: Error parsing media item at index $i: $e');
        continue; // Skip this item and continue searching
      }
    }

    if (!itemFound) {
      AppLogger.database('❌ FirebaseEngagement: Media item not found in candidate document');
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
