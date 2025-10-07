import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      final doc = await _firestore.collection('chats').doc(roomId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['roomId'] = doc.id;
        return ChatRoom.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking existing private chat: $e');
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
      debugPrint('🔐 Creating private chat between $currentUserId ($currentUserName) and $otherUserId ($otherUserName)');

      // Check if private chat already exists
      final existingChat = await getExistingPrivateChat(currentUserId, otherUserId);
      if (existingChat != null) {
        debugPrint('✅ Private chat already exists: ${existingChat.roomId} with title: ${existingChat.title}');
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

      debugPrint('📝 Created private chat room: $roomId with title: "${chatRoom.title}"');

      return await _repository.createRoomWithMembers(chatRoom, [currentUserId, otherUserId]);
    } catch (e) {
      debugPrint('❌ Error creating private chat: $e');
      return null;
    }
  }

  /// Get all private chat rooms for a user
  Future<List<ChatRoom>> getUserPrivateChats(String userId) async {
    try {
      final query = _firestore
          .collection('chats')
          .where('type', isEqualTo: 'private')
          .where('members', arrayContains: userId);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['roomId'] = doc.id;
        return ChatRoom.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting private chats: $e');
      return [];
    }
  }

  /// Get user info for private chat display
  Future<Map<String, dynamic>?> getPrivateChatUserInfo(String roomId, String currentUserId) async {
    try {
      final roomDoc = await _firestore.collection('chats').doc(roomId).get();
      if (!roomDoc.exists) return null;

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(roomData['members'] ?? []);

      // Find the other user
      final otherUserId = members.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return null;

      // Get other user's info
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      return {
        'userId': otherUserId,
        'name': userData['name'] ?? 'Unknown User',
        'phone': userData['phone'] ?? '',
        'photoURL': userData['photoURL'],
        'role': userData['role'] ?? 'voter',
      };
    } catch (e) {
      debugPrint('Error getting private chat user info: $e');
      return null;
    }
  }
}

