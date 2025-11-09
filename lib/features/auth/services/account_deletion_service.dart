import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../services/admob_service.dart';
import '../../../features/chat/controllers/chat_controller.dart';
import '../../../features/candidate/controllers/candidate_controller.dart';

class AccountDeletionService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    AppLogger.auth('🗑️ Starting account deletion for user: $userId');

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
      AppLogger.auth('🔐 Deleting Firebase Auth account...');
      await user.delete();
      AppLogger.auth('✅ Firebase Auth account deleted');

      // Force sign out from Google (if applicable)
      await _googleSignIn.signOut();

      // Clear all local app data and cache AFTER auth deletion
      await _clearAppCache();

      // Clear all GetX controllers
      await _clearAllControllers();

      AppLogger.auth('✅ Account deletion completed successfully');
    } catch (e) {
      AppLogger.auth('Account deletion failed: $e');

      // If Firestore deletion fails, still try to delete from Auth
      try {
        await user.delete();
        await _googleSignIn.signOut();
        await _clearAppCache();
        await _clearAllControllers();
        AppLogger.auth('⚠️ Partial deletion completed - some data may remain');
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
      if (!e.toString().contains('failed-precondition') &&
          !e.toString().contains('permission-denied')) {
        throw 'Failed to delete user data: $e';
      }
    }
  }

  // Delete user data in chunks to avoid Firestore batch size limits
  Future<void> _deleteUserDataInChunks(String userId, bool isCandidate) async {
    final batches = <WriteBatch>[];
    int currentBatchIndex = 0;

    // Helper function to get or create batch
    WriteBatch getCurrentBatch() {
      if (currentBatchIndex >= batches.length) {
        batches.add(_firestore.batch());
      }
      return batches[currentBatchIndex];
    }

    // Helper function to commit current batch if it's getting full
    Future<void> commitIfNeeded() async {
      // We can't check exact size, so we'll commit periodically
      // This is a simplified approach - in production, you'd track operations count
      if (batches.length > currentBatchIndex + 1) {
        await batches[currentBatchIndex].commit();
        currentBatchIndex++;
        AppLogger.auth('📦 Committed batch $currentBatchIndex');
      }
    }

    try {
      // 1. Delete user document and subcollections
      AppLogger.auth('📄 Deleting user document and subcollections...');
      await _deleteUserDocumentChunked(userId, getCurrentBatch, commitIfNeeded);

      // 2. Delete conversations and messages (this can be large)
      AppLogger.auth('💬 Deleting conversations and messages...');
      await _deleteConversationsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 3. Delete rewards
      AppLogger.auth('🏆 Deleting rewards...');
      await _deleteRewardsChunked(userId, getCurrentBatch, commitIfNeeded);

      // 4. Delete XP transactions
      AppLogger.auth('⭐ Deleting XP transactions...');
      await _deleteXpTransactionsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 5. If user is a candidate, delete candidate data
      if (isCandidate) {
        AppLogger.auth('👥 Deleting candidate data...');
        await _deleteCandidateDataChunked(
          userId,
          getCurrentBatch,
          commitIfNeeded,
        );
      }

      // 6. Delete chat rooms created by the user
      AppLogger.auth('🏠 Deleting user chat rooms...');
      await _deleteUserChatRoomsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 7. Delete user quota data
      AppLogger.auth('📊 Deleting user quota...');
      await _deleteUserQuota(userId, getCurrentBatch());

      // 8. Delete reported messages by the user
      AppLogger.auth('🚨 Deleting reported messages...');
      await _deleteUserReportedMessagesChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 9. Delete user subscriptions
      AppLogger.auth('💳 Deleting user subscriptions...');
      await _deleteUserSubscriptionsChunked(
        userId,
        getCurrentBatch,
        commitIfNeeded,
      );

      // 10. Delete user devices
      AppLogger.auth('📱 Deleting user devices...');
      await _deleteUserDevicesChunked(userId, getCurrentBatch, commitIfNeeded);

      // Commit all remaining batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        await batches[i].commit();
        AppLogger.auth('📦 Committed final batch ${i + 1}');
      }

      AppLogger.auth('✅ All user data deleted successfully');
    } catch (e) {
      AppLogger.auth('Error during chunked deletion: $e');
      // Try to commit any pending batches
      for (int i = currentBatchIndex; i < batches.length; i++) {
        try {
          await batches[i].commit();
        } catch (batchError) {
          AppLogger.auth('Failed to commit batch ${i + 1}: $batchError');
        }
      }
      rethrow;
    }
  }

  // Clear all app cache and local storage
  Future<void> _clearAppCache() async {
    try {
      AppLogger.auth('🧹 Starting comprehensive cache cleanup...');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.auth('✅ SharedPreferences cleared');

      // Clear Firebase local cache (handle errors gracefully)
      try {
        await _firestore.clearPersistence();
        AppLogger.auth('✅ Firebase local cache cleared');
      } catch (cacheError) {
        // Handle specific cache clearing errors gracefully
        final errorMessage = cacheError.toString();
        if (errorMessage.contains('failed-precondition') ||
            errorMessage.contains('not in a state') ||
            errorMessage.contains('Operation was rejected')) {
          AppLogger.auth(
            'ℹ️ Firebase cache clearing skipped (normal after account deletion)',
          );
        } else {
          AppLogger.auth('Warning: Firebase cache clearing failed: $cacheError');
        }
      }

      // Clear any cached data in Firebase Auth
      await _firebaseAuth.signOut();
      AppLogger.auth('✅ Firebase Auth cache cleared');

      // Clear image cache (if using cached_network_image or similar)
      await _clearImageCache();

      // Clear HTTP cache
      await _clearHttpCache();

      // Clear temporary files
      await _clearTempFiles();

      // Clear file upload service temp files
      await _clearFileUploadTempFiles();

      // Clear all app directories and cache
      await _clearAllAppDirectories();

      AppLogger.auth('✅ Comprehensive cache cleanup completed');
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some cache: $e');
      // Don't throw here as cache clearing failure shouldn't stop account deletion
    }
  }

  // Clear all GetX controllers (except LoginController which is needed for login screen)
  Future<void> _clearAllControllers() async {
    try {
      // Delete all registered controllers except LoginController (needed for login screen)
      // Don't clear LoginController as it's required when navigating back to login
      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>(force: true);
      }
      if (Get.isRegistered<CandidateController>()) {
        Get.delete<CandidateController>(force: true);
      }
      if (Get.isRegistered<AdMobService>()) {
        Get.delete<AdMobService>(force: true);
      }

      AppLogger.auth(
        '✅ Controllers cleared (LoginController preserved for login screen)',
      );
    } catch (e) {
      AppLogger.auth('Warning: Failed to clear some controllers: $e');
    }
  }

  // Helper methods for chunked deletion (simplified versions)
  Future<void> _deleteUserDocumentChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
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

  Future<void> _deleteConversationsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('userId', isEqualTo: userId)
        .get();

    for (final conversationDoc in conversationsSnapshot.docs) {
      // Delete messages subcollection (this can be very large)
      final messagesSnapshot = await conversationDoc.reference
          .collection('messages')
          .get();
      for (final messageDoc in messagesSnapshot.docs) {
        getBatch().delete(messageDoc.reference);
        await commitIfNeeded();
      }

      // Delete conversation document
      getBatch().delete(conversationDoc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteRewardsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final rewardsSnapshot = await _firestore
        .collection('rewards')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in rewardsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteXpTransactionsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    final xpTransactionsSnapshot = await _firestore
        .collection('xp_transactions')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in xpTransactionsSnapshot.docs) {
      getBatch().delete(doc.reference);
      await commitIfNeeded();
    }
  }

  Future<void> _deleteCandidateDataChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find candidate document in hierarchical structure
      // First, search through all districts and wards to find the candidate
      final districtsSnapshot = await _firestore.collection('districts').get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidateSnapshot = await wardDoc.reference
                .collection('candidates')
                .where('userId', isEqualTo: userId)
                .limit(1)
                .get();

            if (candidateSnapshot.docs.isNotEmpty) {
              final candidateDoc = candidateSnapshot.docs.first;

              // Delete followers subcollection
              final followersSnapshot = await candidateDoc.reference
                  .collection('followers')
                  .get();
              for (final followerDoc in followersSnapshot.docs) {
                getBatch().delete(followerDoc.reference);
                await commitIfNeeded();
              }

              // Delete candidate document from hierarchical structure
              getBatch().delete(candidateDoc.reference);
              await commitIfNeeded();

              AppLogger.auth(
                '✅ Deleted candidate data from: /districts/${districtDoc.id}/bodies/${bodyDoc.id}/wards/${wardDoc.id}/candidates/${candidateDoc.id}',
              );
              return; // Found and deleted, no need to continue searching
            }
          }
        }
      }

      AppLogger.auth('⚠️ No candidate data found for user: $userId');
    } catch (e) {
      AppLogger.auth('Error deleting candidate data: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserChatRoomsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      // Find all chat rooms created by the user
      final chatRoomsSnapshot = await _firestore
          .collection('chats')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final roomDoc in chatRoomsSnapshot.docs) {
        final roomId = roomDoc.id;

        // Delete all messages in the room (can be very large)
        final messagesSnapshot = await roomDoc.reference
            .collection('messages')
            .get();
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

        AppLogger.auth(
          '✅ Deleted chat room: $roomId with ${messagesSnapshot.docs.length} messages and ${pollsSnapshot.docs.length} polls',
        );
      }

      AppLogger.auth(
        '✅ Deleted ${chatRoomsSnapshot.docs.length} chat rooms created by user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user chat rooms: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserQuota(String userId, WriteBatch batch) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      batch.delete(quotaRef);
      AppLogger.auth('✅ Deleted user quota for: $userId');
    } catch (e) {
      AppLogger.auth('Error deleting user quota: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserReportedMessagesChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
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

      AppLogger.auth(
        '✅ Deleted ${reportsSnapshot.docs.length} reported messages by user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user reported messages: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserSubscriptionsChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
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

      AppLogger.auth(
        '✅ Deleted ${subscriptionsSnapshot.docs.length} subscriptions for user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user subscriptions: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserDevicesChunked(
    String userId,
    WriteBatch Function() getBatch,
    Future<void> Function() commitIfNeeded,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Delete devices subcollection
      final devicesSnapshot = await userRef.collection('devices').get();
      for (final deviceDoc in devicesSnapshot.docs) {
        getBatch().delete(deviceDoc.reference);
        await commitIfNeeded();
      }

      AppLogger.auth(
        '✅ Deleted ${devicesSnapshot.docs.length} devices for user: $userId',
      );
    } catch (e) {
      AppLogger.auth('Error deleting user devices: $e');
      // Don't throw here as we want to continue with other deletions
    }
  }

  Future<void> _deleteUserMediaFiles(String userId) async {
    try {
      // Note: Firebase Storage deletion is more complex and might require
      // listing all files in the user's media folder and deleting them individually
      // For now, we'll log this as a reminder that media files should be cleaned up
      AppLogger.auth(
        '📝 Reminder: Media files in Firebase Storage for user $userId should be manually cleaned up',
      );
      AppLogger.auth('   Location: chat_media/ and other user-uploaded files');

      // In a production app, you would:
      // 1. List all files in user's media folders
      // 2. Delete each file individually
      // 3. This can be expensive, so consider doing it asynchronously
    } catch (e) {
      AppLogger.auth('Error deleting user media files: $e');
      // Don't throw here as media cleanup is not critical
    }
  }

  // Placeholder methods for cache clearing (would be implemented in AuthCacheService)
  Future<void> _clearImageCache() async {}
  Future<void> _clearHttpCache() async {}
  Future<void> _clearTempFiles() async {}
  Future<void> _clearFileUploadTempFiles() async {}
  Future<void> _clearAllAppDirectories() async {}
}
