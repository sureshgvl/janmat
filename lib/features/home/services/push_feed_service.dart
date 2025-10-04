import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PushFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get sponsored updates for a specific ward
  Future<List<SponsoredUpdate>> getPushFeedForWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    // Check if user is authenticated before fetching data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('ℹ️ User not authenticated, skipping push feed fetch');
      return [];
    }

    try {
      final querySnapshot = await _firestore
          .collection('sponsored_updates')
          .where('districtId', isEqualTo: districtId)
          .where('bodyId', isEqualTo: bodyId)
          .where('wardId', isEqualTo: wardId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs
          .map((doc) => SponsoredUpdate.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching push feed: $e');
      return [];
    }
  }

  /// Create a new sponsored update (typically for candidates/admin)
  Future<String?> createSponsoredUpdate({
    required String title,
    required String message,
    String? imageUrl,
    required String authorId,
    required String authorName,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    try {
      final updateData = {
        'title': title,
        'message': message,
        'imageUrl': imageUrl,
        'authorId': authorId,
        'authorName': authorName,
        'timestamp': FieldValue.serverTimestamp(),
        'districtId': districtId,
        'bodyId': bodyId,
        'wardId': wardId,
        'isActive': true,
      };

      final docRef = await _firestore
          .collection('sponsored_updates')
          .add(updateData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating sponsored update: $e');
      return null;
    }
  }

  /// Deactivate a sponsored update
  Future<bool> deactivateUpdate(String updateId) async {
    try {
      await _firestore.collection('sponsored_updates').doc(updateId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error deactivating update: $e');
      return false;
    }
  }

  /// Get sponsored updates by author
  Future<List<SponsoredUpdate>> getUpdatesByAuthor(String authorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sponsored_updates')
          .where('authorId', isEqualTo: authorId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SponsoredUpdate.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching author updates: $e');
      return [];
    }
  }

  /// Get all active sponsored updates for a district (for admin purposes)
  Future<List<SponsoredUpdate>> getAllActiveUpdatesForDistrict(
    String districtId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('sponsored_updates')
          .where('districtId', isEqualTo: districtId)
          .where('isActive', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SponsoredUpdate.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error fetching district updates: $e');
      return [];
    }
  }
}

