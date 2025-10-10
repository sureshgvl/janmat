import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';

class PrivateChatService {
  final ChatRepository _repository = ChatRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a consistent private chat room ID for two users
  String _generatePrivateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'private_${ids[0]}_${ids[1]}';
  }

  /// Check if a private chat room exists between two users
  Future<ChatRoom?> getExistingPrivateChat(String userId1, String userId2) async {
    try {
      final roomId = _generatePrivateChatId(userId1, userId2);

      // Check if chat exists in user1's subcollection
      final doc = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('privateChats')
          .doc(roomId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['roomId'] = doc.id;
        return ChatRoom.fromJson(data);
      }
      return null;
    } catch (e) {
      AppLogger.chat('Error checking existing private chat: $e');
      return null;
    }
  }

  /// Create a new private chat room between two users
  Future<ChatRoom?> createPrivateChat(
    String currentUserId,
    String otherUserId,
    String currentUserName,
    String otherUserName,
  ) async {
    try {
      AppLogger.chat('🔐 Creating private chat between $currentUserId ($currentUserName) and $otherUserId ($otherUserName)');

      // Check if private chat already exists
      final existingChat = await getExistingPrivateChat(currentUserId, otherUserId);
      if (existingChat != null) {
        AppLogger.chat('✅ Private chat already exists: ${existingChat.roomId} with title: ${existingChat.title}');
        return existingChat;
      }

      // Create new private chat room
      final roomId = _generatePrivateChatId(currentUserId, otherUserId);
      final chatRoom = ChatRoom(
        roomId: roomId,
        createdAt: DateTime.now(),
        createdBy: currentUserId,
        type: 'private',
        title: otherUserName.trim().isNotEmpty ? otherUserName : 'Private Chat', // Display name of the other user
        description: 'Private conversation',
        members: [currentUserId, otherUserId],
      );

      AppLogger.chat('📝 Created private chat room: $roomId with title: "${chatRoom.title}"');

      // Create chat in both users' subcollections using batch write
      final batch = _firestore.batch();
      final chatData = chatRoom.toJson();

      // Add to current user's private chats
      batch.set(
        _firestore.collection('users').doc(currentUserId).collection('privateChats').doc(roomId),
        {
          ...chatData,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        }
      );

      // Add to other user's private chats
      batch.set(
        _firestore.collection('users').doc(otherUserId).collection('privateChats').doc(roomId),
        {
          ...chatData,
          'otherUserId': currentUserId,
          'otherUserName': currentUserName,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        }
      );

      await batch.commit();

      // Also create the main chat room for messages (keep existing structure for messages)
      await _repository.createRoomWithMembers(chatRoom, [currentUserId, otherUserId]);

      AppLogger.chat('✅ Private chat created in both users\' subcollections');
      return chatRoom;
    } catch (e) {
      AppLogger.chat('❌ Error creating private chat: $e');
      return null;
    }
  }

  /// Get all private chat rooms for a user
  Future<List<ChatRoom>> getUserPrivateChats(String userId) async {
    try {
      final query = _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .orderBy('lastMessageAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['roomId'] = doc.id;
        return ChatRoom.fromJson(data);
      }).toList();
    } catch (e) {
      AppLogger.chat('Error getting private chats: $e');
      return [];
    }
  }

  /// Get user info for private chat display
  Future<Map<String, dynamic>?> getPrivateChatUserInfo(String roomId, String currentUserId) async {
    try {
      // Get chat info from user's private chats subcollection
      final chatDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('privateChats')
          .doc(roomId)
          .get();

      if (!chatDoc.exists) return null;

      final chatData = chatDoc.data() as Map<String, dynamic>;

      // Return the cached user info from the subcollection
      return {
        'userId': chatData['otherUserId'] ?? '',
        'name': chatData['otherUserName'] ?? 'Unknown User',
        'phone': '', // Not stored in subcollection for privacy
        'photoURL': null, // Not stored in subcollection for privacy
        'role': 'user', // Generic role for privacy
      };
    } catch (e) {
      AppLogger.chat('Error getting private chat user info: $e');
      return null;
    }
  }

  /// Update last message info in both users' private chat documents
  Future<void> updateChatLastMessage(String roomId, String messagePreview, String senderId, DateTime messageTime) async {
    try {
      // Extract user IDs from room ID
      final roomIdParts = roomId.replaceFirst('private_', '').split('_');
      if (roomIdParts.length != 2) return;

      final userId1 = roomIdParts[0];
      final userId2 = roomIdParts[1];

      final batch = _firestore.batch();

      // Update for user 1
      batch.update(
        _firestore.collection('users').doc(userId1).collection('privateChats').doc(roomId),
        {
          'lastMessagePreview': messagePreview,
          'lastMessageSender': senderId,
          'lastMessageAt': Timestamp.fromDate(messageTime),
          // Increment unread count for the recipient (not sender)
          'unreadCount': senderId == userId1 ? 0 : FieldValue.increment(1),
        }
      );

      // Update for user 2
      batch.update(
        _firestore.collection('users').doc(userId2).collection('privateChats').doc(roomId),
        {
          'lastMessagePreview': messagePreview,
          'lastMessageSender': senderId,
          'lastMessageAt': Timestamp.fromDate(messageTime),
          // Increment unread count for the recipient (not sender)
          'unreadCount': senderId == userId2 ? 0 : FieldValue.increment(1),
        }
      );

      await batch.commit();
      AppLogger.chat('✅ Updated last message info for private chat: $roomId');
    } catch (e) {
      AppLogger.chat('❌ Error updating chat last message: $e');
    }
  }

  /// Mark messages as read for a user in a private chat
  Future<void> markChatAsRead(String roomId, String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .doc(roomId)
          .update({'unreadCount': 0});

      AppLogger.chat('✅ Marked chat as read: $roomId for user: $userId');
    } catch (e) {
      AppLogger.chat('❌ Error marking chat as read: $e');
    }
  }

  /// Get unread count for a specific private chat
  Future<int> getChatUnreadCount(String roomId, String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('privateChats')
          .doc(roomId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      AppLogger.chat('❌ Error getting chat unread count: $e');
      return 0;
    }
  }
}

