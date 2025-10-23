import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';

class PrivateChatMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all existing private chats from root collection to user subcollections
  Future<void> migrateAllPrivateChats() async {
    try {
      AppLogger.chat('🚀 Starting private chat migration...');

      // Get all private chats from root collection
      final privateChatsQuery = _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private');

      final snapshot = await privateChatsQuery.get();

      AppLogger.chat('📊 Found ${snapshot.docs.length} private chats to migrate');

      int migratedCount = 0;
      int errorCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final chatData = doc.data();
          final roomId = doc.id;
          final members = List<String>.from(chatData['members'] ?? []);

          if (members.length == 2) {
            await _migrateSingleChat(roomId, chatData, members[0], members[1]);
            migratedCount++;
          } else {
            AppLogger.chat('⚠️ Skipping chat $roomId - invalid member count: ${members.length}');
            errorCount++;
          }
        } catch (e) {
          AppLogger.chat('❌ Error migrating chat ${doc.id}: $e');
          errorCount++;
        }
      }

      AppLogger.chat('✅ Migration completed: $migratedCount migrated, $errorCount errors');

    } catch (e) {
      AppLogger.chat('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate a single private chat
  Future<void> _migrateSingleChat(
    String roomId,
    Map<String, dynamic> chatData,
    String userId1,
    String userId2,
  ) async {
    try {
      // OPTIMIZED: Use UserController for user names
      // Get user names for the chat metadata
      final user1Doc = await _firestore.collection('users').doc(userId1).get();
      final user2Doc = await _firestore.collection('users').doc(userId2).get();

      final user1Name = user1Doc.exists ? (user1Doc.data()?['name'] ?? 'Unknown User') : 'Unknown User';
      final user2Name = user2Doc.exists ? (user2Doc.data()?['name'] ?? 'Unknown User') : 'Unknown User';

      // Create batch write for both users' subcollections
      final batch = _firestore.batch();

      // Add to user1's private chats
      batch.set(
        _firestore.collection('users').doc(userId1).collection('privateChats').doc(roomId),
        {
          ...chatData,
          'otherUserId': userId2,
          'otherUserName': user2Name,
          'lastMessageAt': chatData['lastMessageAt'] ?? FieldValue.serverTimestamp(),
          'unreadCount': 0, // Reset unread count during migration
        }
      );

      // Add to user2's private chats
      batch.set(
        _firestore.collection('users').doc(userId2).collection('privateChats').doc(roomId),
        {
          ...chatData,
          'otherUserId': userId1,
          'otherUserName': user1Name,
          'lastMessageAt': chatData['lastMessageAt'] ?? FieldValue.serverTimestamp(),
          'unreadCount': 0, // Reset unread count during migration
        }
      );

      await batch.commit();

      AppLogger.chat('✅ Migrated private chat: $roomId for users $userId1 and $userId2');

    } catch (e) {
      AppLogger.chat('❌ Error migrating chat $roomId: $e');
      rethrow;
    }
  }

  /// Clean up old private chats from root collection (run after migration is verified)
  Future<void> cleanupOldPrivateChats() async {
    try {
      AppLogger.chat('🧹 Starting cleanup of old private chats...');

      final privateChatsQuery = _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private');

      final snapshot = await privateChatsQuery.get();

      AppLogger.chat('📊 Found ${snapshot.docs.length} old private chats to clean up');

      final batch = _firestore.batch();
      int cleanupCount = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        cleanupCount++;

        // Firestore batch limit is 500 operations
        if (cleanupCount % 400 == 0) {
          await batch.commit();
          AppLogger.chat('🧹 Committed batch of 400 deletions');
          // Start new batch
          final newBatch = _firestore.batch();
          // Continue with new batch
        }
      }

      // Commit remaining operations
      if (cleanupCount % 400 != 0) {
        await batch.commit();
      }

      AppLogger.chat('✅ Cleanup completed: $cleanupCount chats removed from root collection');

    } catch (e) {
      AppLogger.chat('❌ Cleanup failed: $e');
      rethrow;
    }
  }

  /// Verify migration by checking counts
  Future<Map<String, dynamic>> verifyMigration() async {
    try {
      // Count old private chats
      final oldChatsQuery = _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private');
      final oldChatsCount = (await oldChatsQuery.count().get()).count;

      // Count new private chats in subcollections (approximate)
      // This is complex to count accurately across all users, so we'll just return old count
      final newChatsCount = 0; // Would need to query all users' subcollections

      return {
        'oldChatsCount': oldChatsCount ?? 0,
        'newChatsCount': newChatsCount,
        'migrationNeeded': (oldChatsCount ?? 0) > 0 ? 1 : 0,
      };

    } catch (e) {
      AppLogger.chat('❌ Error verifying migration: $e');
      return {'error': 1};
    }
  }
}
