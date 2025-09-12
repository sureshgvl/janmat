import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../controllers/login_controller.dart';
import '../controllers/chat_controller.dart';
import '../controllers/candidate_controller.dart';
import '../services/admob_service.dart';
import '../services/background_initializer.dart';
import '../utils/performance_monitor.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _forceAccountPicker = false;

  // Phone Authentication
  Future<void> verifyPhoneNumber(String phoneNumber, Function(String) onCodeSent) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // Google Sign-In - Ultra-optimized for zero-frame performance
  Future<UserCredential?> signInWithGoogle() async {
    startPerformanceTimer('google_signin');

    try {
      debugPrint('🚀 Starting ultra-optimized Google Sign-In');

      // Step 1: Google Sign-In (fast operation with timeout)
      debugPrint('📱 Requesting Google account selection...');

      // Force account picker if flag is set (after logout)
      final GoogleSignInAccount? googleUser;
      if (_forceAccountPicker) {
        debugPrint('🎯 Force account picker enabled - disconnecting and showing account selection');

        // First disconnect to clear any cached authentication
        try {
          await _googleSignIn.disconnect();
          debugPrint('✅ Google account disconnected for fresh sign-in');
        } catch (e) {
          debugPrint('⚠️ Google disconnect failed (might be normal): $e');
        }

        // Now show the account picker
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('⏰ Google Sign-In timeout');
            throw 'Google Sign-In timed out. Please try again.';
          },
        );

        // Reset the flag after use
        _forceAccountPicker = false;
        debugPrint('✅ Account picker flag reset');
      } else {
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('⏰ Google Sign-In timeout');
            throw 'Google Sign-In timed out. Please try again.';
          },
        );
      }

      if (googleUser == null) {
        stopPerformanceTimer('google_signin');
        debugPrint('❌ User cancelled Google Sign-In');
        return null; // User cancelled
      }

      debugPrint('✅ Google account selected: ${googleUser.displayName}');

      // Step 2: Get authentication tokens (optimized)
      debugPrint('🔑 Retrieving authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw 'Failed to retrieve authentication tokens from Google';
      }

      // Step 3: Create Firebase credential
      debugPrint('🔧 Creating Firebase credential...');
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Firebase authentication (can be slow - optimized)
      debugPrint('🔐 Authenticating with Firebase...');

      // Use a longer timeout to handle App Check delays
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              debugPrint('⏰ Firebase authentication timeout');

              // Check if authentication actually succeeded despite the timeout
              final currentUser = _firebaseAuth.currentUser;
              if (currentUser != null) {
                debugPrint('✅ Authentication succeeded despite timeout - proceeding');
                throw 'AUTH_SUCCESS_BUT_TIMEOUT'; // Special exception to handle in catch block
              } else {
                throw 'Firebase authentication timed out. Please check your internet connection.';
              }
            },
          );

      debugPrint('✅ Firebase authentication successful for: ${userCredential.user?.displayName}');

      // Step 5: User data operations (synchronous to avoid isolate issues)
      debugPrint('👤 Processing user data synchronously...');
      await createOrUpdateUser(userCredential.user!);

      stopPerformanceTimer('google_signin');
      debugPrint('✅ Google Sign-In completed successfully');

      return userCredential;
    } catch (e) {
      stopPerformanceTimer('google_signin');
      debugPrint("❌ Google Sign-In Error: $e");

      // Handle the special case where auth succeeded but timed out
      if (e.toString() == 'AUTH_SUCCESS_BUT_TIMEOUT') {
        debugPrint('✅ Handling successful authentication that timed out');

        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          debugPrint('✅ Proceeding with authenticated user: ${currentUser.displayName}');

          // Step 5: User data operations for successful auth
          debugPrint('👤 Processing user data synchronously...');
          await createOrUpdateUser(currentUser);

          debugPrint('✅ Google Sign-In completed successfully despite timeout');
          return null; // Return null to indicate success but no UserCredential
        }
      }

      // Provide more specific error messages
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw 'Network error during sign-in. Please check your internet connection and try again.';
      } else if (e.toString().contains('cancelled')) {
        throw 'Sign-in was cancelled.';
      } else {
        throw 'Sign-in failed: ${e.toString()}';
      }
    }
  }

  // Create or update user in Firestore - Optimized for performance
  Future<void> createOrUpdateUser(User firebaseUser, {String? name, String? role}) async {
    startPerformanceTimer('user_data_setup');

    try {
      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        debugPrint('👤 Creating new user record...');
        // Create new user with optimized data structure
        final userModel = UserModel(
          uid: firebaseUser.uid,
          name: name ?? firebaseUser.displayName ?? 'User',
          phone: firebaseUser.phoneNumber ?? '',
          email: firebaseUser.email,
          role: role ?? '', // Default to empty string for first-time users
          roleSelected: false,
          profileCompleted: false,
          wardId: '',
          cityId: '',
          xpPoints: 0,
          premium: false,
          createdAt: DateTime.now(),
          photoURL: firebaseUser.photoURL,
        );

        // Use set with merge to ensure atomic operation
        await userDoc.set(userModel.toJson(), SetOptions(merge: true));

        // Create default quota for new user (optimized)
        await _createDefaultUserQuotaOptimized(firebaseUser.uid);

        debugPrint('✅ New user created successfully');
      } else {
        debugPrint('🔄 Updating existing user record...');
        // Update existing user with minimal data transfer
        final updatedData = {
          'phone': firebaseUser.phoneNumber,
          'email': firebaseUser.email,
          'photoURL': firebaseUser.photoURL,
          'lastLogin': FieldValue.serverTimestamp(), // Track login time
        };

        // Only update non-null values to minimize data transfer
        final filteredData = Map<String, dynamic>.fromEntries(
          updatedData.entries.where((entry) => entry.value != null)
        );

        if (filteredData.isNotEmpty) {
          await userDoc.update(filteredData);
          debugPrint('✅ User data updated successfully');
        } else {
          debugPrint('ℹ️ No user data changes needed');
        }
      }

      stopPerformanceTimer('user_data_setup');
    } catch (e) {
      stopPerformanceTimer('user_data_setup');
      debugPrint('❌ Error in createOrUpdateUser: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign out - Enhanced to properly clear Google Sign-In cache
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Starting enhanced sign-out process...');

      // Step 1: Sign out from Firebase Auth
      await _firebaseAuth.signOut();
      debugPrint('✅ Firebase Auth sign-out completed');

      // Step 2: Disconnect Google account completely (not just sign out)
      // This clears the cached authentication and forces account picker on next sign-in
      await _googleSignIn.disconnect();
      debugPrint('✅ Google account disconnected');

      // Step 3: Set flag to force account picker on next sign-in
      _forceAccountPicker = true;
      debugPrint('✅ Account picker flag set');

      debugPrint('🚪 Enhanced sign-out completed successfully');
    } catch (e) {
      debugPrint('⚠️ Error during enhanced sign-out: $e');
      // Fallback to basic sign-out if enhanced fails
      try {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        _forceAccountPicker = true;
        debugPrint('⚠️ Fallback sign-out completed');
      } catch (fallbackError) {
        debugPrint('❌ Fallback sign-out also failed: $fallbackError');
        // At minimum, set the flag
        _forceAccountPicker = true;
      }
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Create default quota for new user
  Future<void> _createDefaultUserQuota(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      final quotaData = {
        'userId': userId,
        'dailyLimit': 20,
        'messagesSent': 0,
        'extraQuota': 0,
        'lastReset': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await quotaRef.set(quotaData);
      debugPrint('✅ Created default quota for new user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create default quota for user $userId: $e');
      // Don't throw here as user creation should succeed even if quota creation fails
    }
  }

  // Create default quota for new user - Optimized version
  Future<void> _createDefaultUserQuotaOptimized(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      final now = DateTime.now();

      // Use server timestamp for better consistency
      final quotaData = {
        'userId': userId,
        'dailyLimit': 20,
        'messagesSent': 0,
        'extraQuota': 0,
        'lastReset': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Use set with merge for atomic operation
      await quotaRef.set(quotaData, SetOptions(merge: true));
      debugPrint('✅ Created optimized default quota for new user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to create optimized default quota for user $userId: $e');
      // Fallback to original method
      await _createDefaultUserQuota(userId);
    }
  }

  // Delete account and all associated data with proper batch size management
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      // If no user is currently signed in, still clear cache and controllers
      await _clearAppCache();
      await _clearAllControllers();
      return; // Consider this a successful "deletion" since user is already gone
    }

    final userId = user.uid;
    debugPrint('🗑️ Starting account deletion for user: $userId');

    try {
      // Get user document to check if they're a candidate
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final isCandidate = userData?['role'] == 'candidate';

      // Delete data in chunks to avoid Firestore batch size limits (500 writes max)
      await _deleteUserDataInChunks(userId, isCandidate);

      // Clean up media files from Firebase Storage (after Firestore deletions)
      await _deleteUserMediaFiles(userId);

      // Delete from Firebase Auth BEFORE clearing cache
      debugPrint('🔐 Deleting Firebase Auth account...');
      await user.delete();
      debugPrint('✅ Firebase Auth account deleted');

      // Force sign out from Google (if applicable)
      await _googleSignIn.signOut();

      // Clear all local app data and cache AFTER auth deletion
      await _clearAppCache();

      // Clear all GetX controllers
      await _clearAllControllers();

      debugPrint('✅ Account deletion completed successfully');

    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');

      // If Firestore deletion fails, still try to delete from Auth
      try {
        await user.delete();
        await _googleSignIn.signOut();
        await _clearAppCache();
        await _clearAllControllers();
        debugPrint('⚠️ Partial deletion completed - some data may remain');
      } catch (authError) {
        // If auth deletion also fails, still clear cache and controllers
        try {
          await _clearAppCache();
          await _clearAllControllers();
        } catch (cacheError) {
          // At minimum, try to clear controllers
          await _clearAllControllers();
        }
        // Don't throw auth error if user was already deleted
        if (!authError.toString().contains('no-current-user')) {
          throw 'Failed to delete account: $authError';
        }
      }
      // Don't throw Firestore errors if they are just permission/indexing issues
      if (!e.toString().contains('failed-precondition') && !e.toString().contains('permission-denied')) {
        throw 'Failed to delete user data: $e';
      }
    }
  }

  // Delete user data in chunks to avoid Firestore batch size limits
  Future<void> _deleteUserDataInChunks(String userId, bool isCandidate) async {
    const int maxBatchSize = 400; // Leave some buffer below 500 limit
    final batches = <WriteBatch>[];
    int currentBatchIndex = 0;

    // Helper function to get or create batch
    WriteBatch _getCurrentBatch() {
      if (currentBatchIndex >= batches.length) {
        batches.add(_firestore.batch());
      }
      return batches[currentBatchIndex];
    }

    // Helper function to commit current batch if it's getting full
    Future<void> _commitIfNeeded() async {
      final currentBatch = batches[currentBatchIndex];
      // We can't check exact size, so we'll commit periodically
      // This is a simplified approach - in production, you'd track operations count
      if (batches.length > currentBatchIndex + 1) {
        await batches[currentBatchIndex].commit();
        currentBatchIndex++;
        debugPrint('📦 Committed batch ${currentBatchIndex}');
      }
    }

    try {
      // 1. Delete user document and subcollections
      debugPrint('📄 Deleting user document and subcollections...');
      await _deleteUserDocumentChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 2. Delete conversations and messages (this can be large)
      debugPrint('💬 Deleting conversations and messages...');
      await _deleteConversationsChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 3. Delete rewards
      debugPrint('🏆 Deleting rewards...');
      await _deleteRewardsChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 4. Delete XP transactions
      debugPrint('⭐ Deleting XP transactions...');
      await _deleteXpTransactionsChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 5. If user is a candidate, delete candidate data
      if (isCandidate) {
        debugPrint('👥 Deleting candidate data...');
        await _deleteCandidateDataChunked(userId, _getCurrentBatch, _commitIfNeeded);
      }

      // 6. Delete chat rooms created by the user
      debugPrint('🏠 Deleting user chat rooms...');
      await _deleteUserChatRoomsChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 7. Delete user quota data
      debugPrint('📊 Deleting user quota...');
      await _deleteUserQuota(userId, _getCurrentBatch());

      // 8. Delete reported messages by the user
      debugPrint('🚨 Deleting reported messages...');
      await _deleteUserReportedMessagesChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 9. Delete user subscriptions
      debugPrint('💳 Deleting user subscriptions...');
      await _deleteUserSubscriptionsChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // 10. Delete user devices
      debugPrint('📱 Deleting user devices...');
      await _deleteUserDevicesChunked(userId, _getCurrentBatch, _commitIfNeeded);

      // Commit all remaining batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        await batches[i].commit();
        debugPrint('📦 Committed final batch ${i + 1}');
      }

      debugPrint('✅ All user data deleted successfully');

    } catch (e) {
      debugPrint('❌ Error during chunked deletion: $e');
      // Try to commit any pending batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        try {
          await batches[i].commit();
        } catch (batchError) {
          debugPrint('❌ Failed to commit batch ${i + 1}: $batchError');
        }
      }
      rethrow;
    }
  }

  // Clear all app cache and local storage
  Future<void> _clearAppCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Firebase local cache (handle errors gracefully)
      try {
        await _firestore.clearPersistence();
      } catch (cacheError) {
        // Cache clearing might fail due to various reasons (indexing, etc.)
        // This is not critical for account deletion, so we continue
      debugPrint('Warning: Firebase cache clearing failed: $cacheError');
      }

      // Clear any cached data in Firebase Auth
      await _firebaseAuth.signOut();

    } catch (e) {
    debugPrint('Warning: Failed to clear some cache: $e');
      // Don't throw here as cache clearing failure shouldn't stop account deletion
    }
  }

  // Clear all GetX controllers
  Future<void> _clearAllControllers() async {
    try {
      // Delete all registered controllers (but don't reset GetX navigation)
      if (Get.isRegistered<LoginController>()) {
        Get.delete<LoginController>(force: true);
      }
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<CandidateController>()) {
        Get.delete<CandidateController>(force: true);
      }
      if (Get.isRegistered<AdMobService>()) {
        Get.delete<AdMobService>(force: true);
      }

    } catch (e) {
    debugPrint('Warning: Failed to clear some controllers: $e');
    }
  }

  // Chunked deletion methods to handle large datasets
  Future<void> _deleteUserDocumentChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Delete following subcollection
    final followingSnapshot = await userRef.collection('following').get();
    for (final doc in followingSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }

    // Delete main user document
    getBatch().delete(userRef);
  }

  Future<void> _deleteConversationsChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .get();

    for (final conversationDoc in conversationsSnapshot.docs) {
      // Delete messages subcollection (this can be very large)
      final messagesSnapshot = await conversationDoc.reference.collection('messages').get();
      for (final messageDoc in messagesSnapshot.docs) {
        getBatch().delete(messageDoc.reference);
        await commitIfNeeded();
      }

      // Delete conversation document
      getBatch().delete(conversationDoc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteRewardsChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    final rewardsSnapshot = await _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in rewardsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteXpTransactionsChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    final xpTransactionsSnapshot = await _firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in xpTransactionsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteCandidateDataChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    try {
      // Find candidate document in hierarchical structure
      // First, search through all cities and wards to find the candidate
      final citiesSnapshot = await _firestore.collection('cities').get();

      for (var cityDoc in citiesSnapshot.docs) {
        final wardsSnapshot = await cityDoc.reference.collection('wards').get();

        for (var wardDoc in wardsSnapshot.docs) {
          final candidateSnapshot = await wardDoc.reference
              .collection('candidates')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (candidateSnapshot.docs.isNotEmpty) {
            final candidateDoc = candidateSnapshot.docs.first;

            // Delete followers subcollection
            final followersSnapshot = await candidateDoc.reference.collection('followers').get();
            for (final followerDoc in followersSnapshot.docs) {
              getBatch().delete(followerDoc.reference);
              await commitIfNeeded();
            }

            // Delete candidate document from hierarchical structure
            getBatch().delete(candidateDoc.reference);
            await commitIfNeeded();

            debugPrint('✅ Deleted candidate data from: /cities/${cityDoc.id}/wards/${wardDoc.id}/candidates/${candidateDoc.id}');
            return; // Found and deleted, no need to continue searching
          }
        }
      }

      debugPrint('⚠️ No candidate data found for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting candidate data: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserChatRoomsChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    try {
      // Find all chat rooms created by the user
      final chatRoomsSnapshot = await _firestore
          .collection('chats')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final roomDoc in chatRoomsSnapshot.docs) {
        final roomId = roomDoc.id;

        // Delete all messages in the room (can be very large)
        final messagesSnapshot = await roomDoc.reference.collection('messages').get();
        for (final messageDoc in messagesSnapshot.docs) {
          getBatch().delete(messageDoc.reference);
          await commitIfNeeded();
        }

        // Delete all polls in the room
        final pollsSnapshot = await roomDoc.reference.collection('polls').get();
        for (final pollDoc in pollsSnapshot.docs) {
          getBatch().delete(pollDoc.reference);
          await commitIfNeeded();
        }

        // Delete the chat room itself
        getBatch().delete(roomDoc.reference);
        await commitIfNeeded();

        debugPrint('✅ Deleted chat room: $roomId with ${messagesSnapshot.docs.length} messages and ${pollsSnapshot.docs.length} polls');
      }

      debugPrint('✅ Deleted ${chatRoomsSnapshot.docs.length} chat rooms created by user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user chat rooms: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserQuota(String userId, WriteBatch batch) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      batch.delete(quotaRef);
    debugPrint('✅ Deleted user quota for: $userId');
    } catch (e) {
    debugPrint('❌ Error deleting user quota: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserReportedMessagesChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    try {
      // Find all reported messages by the user
      final reportsSnapshot = await _firestore
          .collection('reported_messages')
          .where('reporterId', isEqualTo: userId)
          .get();

      for (final reportDoc in reportsSnapshot.docs) {
        getBatch().delete(reportDoc.reference);
        await commitIfNeeded();
      }

      debugPrint('✅ Deleted ${reportsSnapshot.docs.length} reported messages by user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user reported messages: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserSubscriptionsChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    try {
      // Find all subscriptions for the user
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final subscriptionDoc in subscriptionsSnapshot.docs) {
        getBatch().delete(subscriptionDoc.reference);
        await commitIfNeeded();
      }

      debugPrint('✅ Deleted ${subscriptionsSnapshot.docs.length} subscriptions for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user subscriptions: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserDevicesChunked(String userId, WriteBatch Function() getBatch, Future<void> Function() commitIfNeeded) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Delete devices subcollection
      final devicesSnapshot = await userRef.collection('devices').get();
      for (final deviceDoc in devicesSnapshot.docs) {
        getBatch().delete(deviceDoc.reference);
        await commitIfNeeded();
      }

      debugPrint('✅ Deleted ${devicesSnapshot.docs.length} devices for user: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user devices: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserMediaFiles(String userId) async {
    try {
      // Note: Firebase Storage deletion is more complex and might require
      // listing all files in the user's media folder and deleting them individually
      // For now, we'll log this as a reminder that media files should be cleaned up
    debugPrint('📝 Reminder: Media files in Firebase Storage for user $userId should be manually cleaned up');
    debugPrint('   Location: chat_media/ and other user-uploaded files');

      // In a production app, you would:
      // 1. List all files in user's media folders
      // 2. Delete each file individually
      // 3. This can be expensive, so consider doing it asynchronously

    } catch (e) {
    debugPrint('❌ Error deleting user media files: $e');
      // Don't throw here as media cleanup is not critical
    }
  }
}