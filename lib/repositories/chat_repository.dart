import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  // Get chat rooms for a user
  Future<List<ChatRoom>> getChatRoomsForUser(String userId, String userRole) async {
    try {
      Query query = _firestore.collection('chats');

      if (userRole == 'admin') {
        // Admins can see all rooms
        query = query.orderBy('createdAt', descending: true);
      } else if (userRole == 'candidate') {
        // Candidates can see rooms they created or public rooms
        query = query.where(Filter.or(
          Filter('createdBy', isEqualTo: userId),
          Filter('type', isEqualTo: 'public')
        ));
      } else {
        // Voters can only see public rooms
        query = query.where('type', isEqualTo: 'public');
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['roomId'] = doc.id;
        return ChatRoom.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch chat rooms: $e');
    }
  }

  // Create a new chat room
  Future<ChatRoom> createChatRoom(ChatRoom chatRoom) async {
    try {
      final docRef = _firestore.collection('chats').doc(chatRoom.roomId);
      await docRef.set(chatRoom.toJson());
      return chatRoom;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Get messages for a chat room
  Stream<List<Message>> getMessagesForRoom(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['messageId'] = doc.id;
            return Message.fromJson(data);
          }).toList();
        });
  }

  // Send a message
  Future<Message> sendMessage(String roomId, Message message) async {
    try {
      print('💾 Repository: Sending message "${message.text}" to room $roomId');

      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(message.messageId);

      await docRef.set(message.toJson());
      print('✅ Repository: Message saved to Firestore successfully');

      // Update user's message count (only if they have quota, not XP)
      // XP deduction is handled in the controller
      final canUseQuota = await _canUserSendMessage(message.senderId);
      if (canUseQuota) {
        await _incrementUserMessageCount(message.senderId);
        print('📊 Repository: User quota decremented');
      } else {
        print('💰 Repository: User using XP (quota not decremented)');
      }

      return message;
    } catch (e) {
      print('❌ Repository: Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String roomId, String messageId, String userId) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final message = Message.fromJson(snapshot.data()!);
        final readBy = List<String>.from(message.readBy);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          transaction.update(docRef, {'readBy': readBy});
        }
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Upload media file
  Future<String> uploadMediaFile(String roomId, String filePath, String fileName, String contentType) async {
    try {
      final storageRef = _storage.ref().child('chat_media/$roomId/$fileName');
      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media file: $e');
    }
  }

  // Get user quota
  Future<UserQuota?> getUserQuota(String userId) async {
    try {
      final doc = await _firestore.collection('user_quotas').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['userId'] = doc.id;
        return UserQuota.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user quota: $e');
    }
  }

  // Create or update user quota
  Future<void> updateUserQuota(UserQuota quota) async {
    try {
      await _firestore.collection('user_quotas').doc(quota.userId).set(quota.toJson());
    } catch (e) {
      throw Exception('Failed to update user quota: $e');
    }
  }

  // Add extra quota (after watching ad)
  Future<void> addExtraQuota(String userId, int extraQuota) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(quotaRef);
        if (snapshot.exists) {
          final currentQuota = UserQuota.fromJson(snapshot.data()!);
          final updatedQuota = currentQuota.copyWith(
            extraQuota: currentQuota.extraQuota + extraQuota,
          );
          transaction.set(quotaRef, updatedQuota.toJson());
        } else {
          // Create new quota
          final newQuota = UserQuota(
            userId: userId,
            extraQuota: extraQuota,
            lastReset: DateTime.now(),
            createdAt: DateTime.now(),
          );
          transaction.set(quotaRef, newQuota.toJson());
        }
      });
    } catch (e) {
      throw Exception('Failed to add extra quota: $e');
    }
  }

  // Create a poll
  Future<Poll> createPoll(String roomId, Poll poll) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('polls')
          .doc(poll.pollId);

      await docRef.set(poll.toJson());
      return poll;
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get polls for a room
  Stream<List<Poll>> getPollsForRoom(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['pollId'] = doc.id;
            return Poll.fromJson(data);
          }).toList();
        });
  }

  // Get a specific poll by ID from any room
  Future<Poll?> getPollById(String pollId) async {
    try {
      // Since polls are stored per room, we need to find which room contains this poll
      // This is a simplified approach - in production, you'd want to index polls differently
      final roomsSnapshot = await _firestore.collection('chats').get();

      for (final roomDoc in roomsSnapshot.docs) {
        final pollDoc = await roomDoc.reference.collection('polls').doc(pollId).get();
        if (pollDoc.exists) {
          final data = pollDoc.data() as Map<String, dynamic>;
          data['pollId'] = pollDoc.id;
          return Poll.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get poll by ID: $e');
    }
  }

  // Vote on a poll (finds the poll in any room)
  Future<void> voteOnPoll(String pollId, String userId, String option) async {
    try {
      // Find which room contains this poll
      final roomsSnapshot = await _firestore.collection('chats').get();
      String? roomId;

      for (final roomDoc in roomsSnapshot.docs) {
        final pollDoc = await roomDoc.reference.collection('polls').doc(pollId).get();
        if (pollDoc.exists) {
          roomId = roomDoc.id;
          break;
        }
      }

      if (roomId == null) {
        throw Exception('Poll not found');
      }

      final pollRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('polls')
          .doc(pollId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(pollRef);
        if (!snapshot.exists) return;

        final poll = Poll.fromJson(snapshot.data()!);

        // Check if user already voted
        if (poll.userVotes.containsKey(userId)) {
          // Remove previous vote
          final previousOption = poll.userVotes[userId]!;
          if (poll.votes.containsKey(previousOption)) {
            poll.votes[previousOption] = (poll.votes[previousOption] ?? 0) - 1;
          }
        }

        // Add new vote
        poll.userVotes[userId] = option;
        poll.votes[option] = (poll.votes[option] ?? 0) + 1;

        transaction.update(pollRef, {
          'votes': poll.votes,
          'userVotes': poll.userVotes,
        });
      });
    } catch (e) {
      throw Exception('Failed to vote on poll: $e');
    }
  }

  // Add reaction to message
  Future<void> addReactionToMessage(String roomId, String messageId, String userId, String emoji) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      final reaction = MessageReaction(
        emoji: emoji,
        userId: userId,
        createdAt: DateTime.now(),
      );

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);
        if (!snapshot.exists) return;

        final message = Message.fromJson(snapshot.data()!);
        final reactions = List<MessageReaction>.from(message.reactions ?? []);

        // Remove existing reaction from same user with same emoji
        reactions.removeWhere((r) => r.userId == userId && r.emoji == emoji);

        // Add new reaction
        reactions.add(reaction);

        transaction.update(messageRef, {
          'reactions': reactions.map((r) => r.toJson()).toList(),
        });
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Report a message
  Future<void> reportMessage(String roomId, String messageId, String reporterId, String reason) async {
    try {
      final reportId = _uuid.v4();
      await _firestore.collection('reported_messages').doc(reportId).set({
        'reportId': reportId,
        'roomId': roomId,
        'messageId': messageId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  // Delete message (admin only)
  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Helper methods
  Future<bool> _canUserSendMessage(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromJson(userDoc.data()!);

      // Premium users and candidates have unlimited messages
      if (user.role == 'candidate' || user.role == 'admin' || user.premium) {
        return true;
      }

      // Check quota for voters
      final quota = await getUserQuota(userId);
      if (quota == null) {
        // Create default quota
        final newQuota = UserQuota(
          userId: userId,
          lastReset: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await updateUserQuota(newQuota);
        return true;
      }

      // Reset quota if it's a new day
      final now = DateTime.now();
      if (now.difference(quota.lastReset).inDays >= 1) {
        final resetQuota = quota.copyWith(
          messagesSent: 0,
          extraQuota: 0,
          lastReset: now,
        );
        await updateUserQuota(resetQuota);
        return true;
      }

      return quota.canSendMessage;
    } catch (e) {
      return false;
    }
  }

  Future<void> _incrementUserMessageCount(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(quotaRef);
        if (snapshot.exists) {
          final quota = UserQuota.fromJson(snapshot.data()!);
          final updatedQuota = quota.copyWith(
            messagesSent: quota.messagesSent + 1,
          );
          transaction.set(quotaRef, updatedQuota.toJson());
        }
      });
    } catch (e) {
      // Silently fail - quota tracking is not critical
    }
  }

  // Get unread message count for user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd need to track read status more efficiently
      final rooms = await getChatRoomsForUser(userId, 'voter'); // Assuming voter role for simplicity
      int totalUnread = 0;

      for (final room in rooms) {
        final messages = await _firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .where('readBy', arrayContains: userId)
            .get();

        // Count messages not read by user
        final totalMessages = await _firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .get();

        totalUnread += totalMessages.docs.length - messages.docs.length;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}