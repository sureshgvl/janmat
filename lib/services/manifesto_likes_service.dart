import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/like_model.dart';
import '../utils/performance_monitor.dart';
import '../utils/connection_optimizer.dart';
import '../utils/app_logger.dart';
import 'manifesto_cache_service.dart';
import 'local_database_service.dart';

class ManifestoLikesService {
  static final PerformanceMonitor _monitor = PerformanceMonitor();
  static final ConnectionOptimizer _connectionOptimizer = ConnectionOptimizer();
  static final ManifestoCacheService _cacheService = ManifestoCacheService();
  static final LocalDatabaseService _dbService = LocalDatabaseService();

  /// Toggle like for a manifesto
  /// Returns true if liked, false if unliked
  static Future<bool> toggleLike(String userId, String manifestoId) async {
    _monitor.startTimer('toggle_like');

    try {
      // Check cache first
      final hasLiked = await _cacheService.hasUserLiked(userId, manifestoId);
      bool isLiked;

      if (hasLiked) {
        // Unlike: find the like record and remove it from cache
        final db = await _dbService.database;
        final existingLike = await db.query(
          LocalDatabaseService.likesTable,
          where: 'userId = ? AND postId = ? AND (syncAction != ? OR syncAction IS NULL)',
          whereArgs: [userId, manifestoId, 'delete'],
          limit: 1,
        );

        if (existingLike.isNotEmpty) {
          final likeId = existingLike.first['id'] as String;
          await _cacheService.removeCachedLike(likeId);
        }
        isLiked = false;

        // If online, sync to Firestore
        if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
          try {
            final likesRef = FirebaseFirestore.instance.collection('likes');
            final existingLike = await likesRef
                .where('userId', isEqualTo: userId)
                .where('postId', isEqualTo: manifestoId)
                .limit(1)
                .get();

            if (existingLike.docs.isNotEmpty) {
              await likesRef.doc(existingLike.docs.first.id).delete();
              _monitor.trackFirebaseWrite('likes', 1);
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
          postId: manifestoId,
          createdAt: DateTime.now(),
        );

        await _cacheService.cacheLike(like, synced: false);
        isLiked = true;

        // If online, sync to Firestore
        if (_connectionOptimizer.currentQuality != ConnectionQuality.offline) {
          try {
            final likesRef = FirebaseFirestore.instance.collection('likes');
            await likesRef.add(like.toJson());
            _monitor.trackFirebaseWrite('likes', 1);

            // Mark as synced
            await _cacheService.markLikeSynced(like.id);
          } catch (e) {
            AppLogger.commonError('Failed to sync like to Firestore, will retry later', error: e);
          }
        }
      }

      _monitor.stopTimer('toggle_like');
      return isLiked;
    } catch (e) {
      _monitor.stopTimer('toggle_like');
      AppLogger.commonError('Error toggling like', error: e);
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get stream of like count for a manifesto (with offline support)
  static Stream<int> getLikeCountStream(String manifestoId) {
    // If offline, return cached count
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.fromFuture(_cacheService.getCachedLikeCount(manifestoId));
    }

    // Online: Get from Firestore
    final likesRef = FirebaseFirestore.instance.collection('likes');

    return likesRef
        .where('postId', isEqualTo: manifestoId)
        .snapshots()
        .map((snapshot) {
          _monitor.trackFirebaseRead('likes', snapshot.docs.length);
          return snapshot.docs.length;
        });
  }

  /// Get stream of user's like status for a manifesto (with offline support)
  static Stream<bool> getUserLikeStatusStream(String userId, String manifestoId) {
    // If offline, return cached result as stream
    if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
      return Stream.fromFuture(_cacheService.hasUserLiked(userId, manifestoId));
    }

    // Online: Get from Firestore as stream
    final likesRef = FirebaseFirestore.instance.collection('likes');

    return likesRef
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: manifestoId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          _monitor.trackFirebaseRead('likes', 1);
          return snapshot.docs.isNotEmpty;
        });
  }

  /// Check if user has liked a manifesto (with offline support)
  static Future<bool> hasUserLiked(String userId, String manifestoId) async {
    _monitor.startTimer('check_user_like');

    try {
      // Check cache first
      final cachedResult = await _cacheService.hasUserLiked(userId, manifestoId);
      if (_connectionOptimizer.currentQuality == ConnectionQuality.offline) {
        _monitor.stopTimer('check_user_like');
        return cachedResult;
      }

      // Online: Check Firestore and update cache if needed
      final likesRef = FirebaseFirestore.instance.collection('likes');
      final existingLike = await likesRef
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: manifestoId)
          .limit(1)
          .get();

      _monitor.stopTimer('check_user_like');
      _monitor.trackFirebaseRead('likes', 1);

      return existingLike.docs.isNotEmpty;
    } catch (e) {
      _monitor.stopTimer('check_user_like');
      AppLogger.commonError('Error checking user like', error: e);
      // Fall back to cache
      return await _cacheService.hasUserLiked(userId, manifestoId);
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _monitor.getFirebaseSummary();
  }
}
