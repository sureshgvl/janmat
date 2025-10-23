import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Repository responsible for user data persistence operations.
/// Handles all Firebase interactions related to user data.
/// Follows Repository pattern for clean separation of concerns.
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user document by UID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Create or update user document
  Future<void> setUserDocument(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Update specific fields in user document
  Future<void> updateUserDocument(String uid, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(uid).update({
      ...updates,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Listen to real-time user document changes
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Delete user document
  Future<void> deleteUserDocument(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  /// Check if user document exists
  Future<bool> userDocumentExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// Get current authenticated user's UID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Listen to authentication state changes
  Stream<User?> listenToAuthStateChanges() {
    return _auth.authStateChanges();
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
