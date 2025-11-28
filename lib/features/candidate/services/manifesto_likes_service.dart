import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/like_model.dart';
import '../../../utils/performance_monitor.dart';
import '../../../utils/app_logger.dart';

class ManifestoLikesService {
  static final PerformanceMonitor _monitor = PerformanceMonitor();

  /// Toggle like for a manifesto
  /// Returns true if liked, false if unliked
  static Future<bool> toggleLike(String userId, String manifestoId) async {
    _monitor.startTimer('toggle_like');

    try {
      final likesRef = FirebaseFirestore.instance.collection('likes');

      // Check if user already liked
      final existingLike = await likesRef
          .where('userId', isEqualTo: userId)
          .where('postId', isEqualTo: manifestoId)
          .limit(1)
          .get();

      bool isLiked;

      if (existingLike.docs.isNotEmpty) {
        // Unlike: remove from Firestore
        await likesRef.doc(existingLike.docs.first.id).delete();
        _monitor.trackFirebaseWrite('likes', 1);
        isLiked = false;
        AppLogger.common('Unliked manifesto $manifestoId by user $userId');
      } else {
        // Like: add to Firestore
        final like = LikeModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          postId: manifestoId,
          createdAt: DateTime.now(),
        );

        await likesRef.add(like.toJson());
        _monitor.trackFirebaseWrite('likes', 1);
        isLiked = true;
        AppLogger.common('Liked manifesto $manifestoId by user $userId');
      }

      _monitor.stopTimer('toggle_like');
      return isLiked;
    } catch (e) {
      _monitor.stopTimer('toggle_like');
      AppLogger.commonError('Error toggling like', error: e);
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get stream of like count for a manifesto
  static Stream<int> getLikeCountStream(String manifestoId) {
    final likesRef = FirebaseFirestore.instance.collection('likes');

    return likesRef
        .where('postId', isEqualTo: manifestoId)
        .snapshots()
        .map((snapshot) {
          _monitor.trackFirebaseRead('likes', snapshot.docs.length);
          return snapshot.docs.length;
        });
  }

  /// Get stream of user's like status for a manifesto
  static Stream<bool> getUserLikeStatusStream(String userId, String manifestoId) {
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

  /// Check if user has liked a manifesto
  static Future<bool> hasUserLiked(String userId, String manifestoId) async {
    _monitor.startTimer('check_user_like');

    try {
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
      return false;
    }
  }

  /// Get performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    return _monitor.getFirebaseSummary();
  }
}
