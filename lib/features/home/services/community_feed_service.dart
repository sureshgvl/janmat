import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../models/post_model.dart';

class CommunityFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get community posts for a specific ward
  Future<List<CommunityPost>> getCommunityFeedForWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    // Check if user is authenticated before fetching data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppLogger.common('User not authenticated, skipping community feed fetch', tag: 'FEED');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('community_posts')
          .where('districtId', isEqualTo: districtId)
          .where('bodyId', isEqualTo: bodyId)
          .where('wardId', isEqualTo: wardId)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => CommunityPost.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.common('Error fetching community feed: $e', tag: 'FEED');
      return [];
    }
  }

  /// Create a new community post
  Future<String?> createCommunityPost({
    required String authorId,
    required String authorName,
    required String content,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      final postData = {
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      };

      final docRef = await _firestore
          .collection('community_posts')
          .add(postData);
      return docRef.id;
    } catch (e) {
      AppLogger.common('Error creating community post: $e', tag: 'FEED');
      return null;
    }
  }

  /// Like/unlike a community post
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('community_posts').doc(postId);
      final postDoc = await postRef.get();

      if (!postDoc.exists) return false;

      final data = postDoc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        // Unlike
        await postRef.update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Like
        await postRef.update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }

      return !isLiked;
    } catch (e) {
      AppLogger.common('Error toggling like: $e', tag: 'FEED');
      return false;
    }
  }

  /// Get posts by a specific user
  Future<List<CommunityPost>> getPostsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommunityPost.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      AppLogger.common('Error fetching user posts: $e', tag: 'FEED');
      return [];
    }
  }
}
