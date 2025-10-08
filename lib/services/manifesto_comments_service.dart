import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';
import '../models/like_model.dart';
import '../utils/performance_monitor.dart';
import '../utils/connection_optimizer.dart';
import '../utils/app_logger.dart';
import 'manifesto_cache_service.dart';

class ManifestoCommentsService {
  static final PerformanceMonitor _monitor = PerformanceMonitor();
  static final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  static final ManifestoCacheService _cacheService = ManifestoCacheService();

  /// Add a comment to a manifesto
  static Future<void> addComment(String userId, String manifestoId, String text, {String? parentId}) async {
    _monitor.startTimer('add_comment');

    try {
      final comment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate ID for cache
        userId: userId,
        postId: manifestoId,
        text: text,
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      // Always cache locally first
      await _cacheService.cacheComment(comment, synced: false);

      // If online, sync to Firestore
      if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
        try {
          final commentsRef = FirebaseFirestore.instance.collection('comments');
          final docRef = await commentsRef.add(comment.toJson());
          _monitor.trackFirebaseWrite('comments', 1);

          // Update cache with Firestore ID and mark as synced
          final syncedComment = comment.copyWith(id: docRef.id);
          await _cacheService.cacheComment(syncedComment, synced: true);
          await _cacheService.markCommentSynced(comment.id); // Mark old cache entry as synced
        } catch (e) {
          AppLogger.commonError('Failed to sync comment to Firestore, will retry later', error: e);
          // Comment remains in cache as unsynced
        }
      }

      _monitor.stopTimer('add_comment');
    } catch (e) {
      _monitor.stopTimer('add_comment');
      AppLogger.commonError('Error adding comment', error: e);
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Reply to a comment
  static Future<void> replyToComment(String userId, String manifestoId, String parentCommentId, String text) async {
    await addComment(userId, manifestoId, text, parentId: parentCommentId);
  }

  /// Get stream of comments for a manifesto (with offline support)
  static Stream<List<CommentModel>> getComments(String manifestoId) {
    // If offline, return cached comments
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.fromFuture(_cacheService.getCachedComments(manifestoId));
    }

    // Online: Get from Firestore and update cache
    final commentsRef = FirebaseFirestore.instance.collection('comments');

    return commentsRef
        .where('postId', isEqualTo: manifestoId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          _monitor.trackFirebaseRead('comments', snapshot.docs.length);
          final serverComments = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CommentModel.fromJson(data);
          }).toList();

          // Update cache with server data (only comments for now)
          // Note: This method is designed for full manifesto updates, but we can use it for comments
          await _cacheService.updateManifestoCache(manifestoId, serverComments, [], {});

          return serverComments;
        });
  }

  /// Toggle like for a comment
  /// Returns true if liked, false if unliked
  static Future<bool> toggleCommentLike(String userId, String commentId) async {
    _monitor.startTimer('toggle_comment_like');

    try {
      // Check cache first
      final hasLiked = await _cacheService.hasUserLiked(userId, commentId);
      bool isLiked;

      if (hasLiked) {
        // Unlike: remove from cache
        await _cacheService.removeCachedLike(commentId);
        isLiked = false;

        // If online, sync to Firestore
        if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
          try {
            final likesRef = FirebaseFirestore.instance.collection('comment_likes');
            final existingLike = await likesRef
                .where('userId', isEqualTo: userId)
                .where('postId', isEqualTo: commentId)
                .limit(1)
                .get();

            if (existingLike.docs.isNotEmpty) {
              await likesRef.doc(existingLike.docs.first.id).delete();
              _monitor.trackFirebaseWrite('comment_likes', 1);
            }
          } catch (e) {
            AppLogger.commonError('Failed to sync unlike to Firestore, will retry later', error: e);
          }
        }
      } else {
        // Like: add to cache
        final like = LikeModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          postId: commentId,
          createdAt: DateTime.now(),
        );

        await _cacheService.cacheLike(like, synced: false);
        isLiked = true;

        // If online, sync to Firestore
        if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
          try {
            final likesRef = FirebaseFirestore.instance.collection('comment_likes');
            await likesRef.add(like.toJson());
            _monitor.trackFirebaseWrite('comment_likes', 1);

            // Mark as synced
            await _cacheService.markLikeSynced(like.id);
          } catch (e) {
            AppLogger.commonError('Failed to sync like to Firestore, will retry later', error: e);
          }
        }
      }

      _monitor.stopTimer('toggle_comment_like');
      return isLiked;
    } catch (e) {
      _monitor.stopTimer('toggle_comment_like');
      AppLogger.commonError('Error toggling comment like', error: e);
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _monitor.getFirebaseSummary();
  }
}
