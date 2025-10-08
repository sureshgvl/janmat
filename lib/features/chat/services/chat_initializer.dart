import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../../../models/chat_model.dart';

class ChatInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize sample chat rooms for testing
  Future<void> initializeSampleChatRooms() async {
    try {
      await _createSampleWardRooms();
      await _createSampleCandidateRooms();
      AppLogger.chat('✅ Sample chat rooms initialized successfully');
    } catch (e) {
      AppLogger.chat('❌ Failed to initialize sample chat rooms: $e');
    }
  }

  Future<void> _createSampleWardRooms() async {
    final wardRooms = [
      {
        'roomId': 'ward_mumbai_1',
        'title': 'Ward 1 (Mumbai) Community Chat',
        'description': 'Public discussion forum for Ward 1 residents in Mumbai',
        'cityId': 'mumbai',
      },
      {
        'roomId': 'ward_mumbai_2',
        'title': 'Ward 2 (Mumbai) Community Chat',
        'description': 'Public discussion forum for Ward 2 residents in Mumbai',
        'cityId': 'mumbai',
      },
      {
        'roomId': 'ward_pune_1',
        'title': 'Ward 1 (Pune) Community Chat',
        'description': 'Public discussion forum for Ward 1 residents in Pune',
        'cityId': 'pune',
      },
      {
        'roomId': 'ward_pune_2',
        'title': 'Ward 2 (Pune) Community Chat',
        'description': 'Public discussion forum for Ward 2 residents in Pune',
        'cityId': 'pune',
      },
      {
        'roomId': 'ward_nashik_1',
        'title': 'Ward 1 (Nashik) Community Chat',
        'description': 'Public discussion forum for Ward 1 residents in Nashik',
        'cityId': 'nashik',
      },
    ];

    for (final roomData in wardRooms) {
      final chatRoom = ChatRoom(
        roomId: roomData['roomId'] as String,
        createdAt: DateTime.now(),
        createdBy: 'admin_system', // System-generated
        type: 'public',
        title: roomData['title'] as String,
        description: roomData['description'] as String,
      );

      await _createRoomIfNotExists(chatRoom);
    }
  }

  Future<void> _createSampleCandidateRooms() async {
    final candidateRooms = [
      {
        'roomId': 'candidate_sample1',
        'title': 'Rahul Sharma - Ward 1 Candidate',
        'description': 'Official updates and discussions with Rahul Sharma',
        'candidateId': 'sample_candidate_1',
      },
      {
        'roomId': 'candidate_sample2',
        'title': 'Priya Patel - Ward 2 Candidate',
        'description': 'Official updates and discussions with Priya Patel',
        'candidateId': 'sample_candidate_2',
      },
      {
        'roomId': 'candidate_sample3',
        'title': 'Amit Kumar - Ward 3 Candidate',
        'description': 'Official updates and discussions with Amit Kumar',
        'candidateId': 'sample_candidate_3',
      },
    ];

    for (final roomData in candidateRooms) {
      final chatRoom = ChatRoom(
        roomId: roomData['roomId'] as String,
        createdAt: DateTime.now(),
        createdBy: roomData['candidateId'] as String,
        type: 'public',
        title: roomData['title'] as String,
        description: roomData['description'] as String,
      );

      await _createRoomIfNotExists(chatRoom);
    }
  }

  Future<void> _createRoomIfNotExists(ChatRoom chatRoom) async {
    try {
      final docRef = _firestore.collection('chats').doc(chatRoom.roomId);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set(chatRoom.toJson());
        AppLogger.chat('✅ Created chat room: ${chatRoom.roomId}');
      } else {
        AppLogger.chat('ℹ️ Chat room already exists: ${chatRoom.roomId}');
      }
    } catch (e) {
      AppLogger.chat('❌ Failed to create room ${chatRoom.roomId}: $e');
    }
  }

  // Create sample messages for testing
  Future<void> createSampleMessages() async {
    try {
      final sampleMessages = [
        {
          'roomId': 'ward_mumbai_1',
          'text':
              'Welcome to Ward 1 (Mumbai) Community Chat! This is a public forum for all residents.',
          'senderId': 'admin_system',
          'type': 'text',
        },
        {
          'roomId': 'ward_mumbai_1',
          'text':
              'Hello everyone! I\'m Rahul Sharma, your candidate for Ward 1. Feel free to ask questions!',
          'senderId': 'sample_candidate_1',
          'type': 'text',
        },
        {
          'roomId': 'candidate_sample1',
          'text':
              'Thank you for your support! I\'m committed to improving our ward\'s infrastructure.',
          'senderId': 'sample_candidate_1',
          'type': 'text',
        },
        {
          'roomId': 'ward_pune_1',
          'text':
              'Welcome to Ward 1 (Pune) Community Chat! Let\'s discuss local issues together.',
          'senderId': 'admin_system',
          'type': 'text',
        },
      ];

      for (final messageData in sampleMessages) {
        final message = Message(
          messageId:
              'sample_${DateTime.now().millisecondsSinceEpoch}_${messageData['roomId']}',
          text: messageData['text'] as String,
          senderId: messageData['senderId'] as String,
          type: messageData['type'] as String,
          createdAt: DateTime.now(),
          readBy: [messageData['senderId'] as String],
        );

        await _createMessageIfNotExists(
          messageData['roomId'] as String,
          message,
        );
      }

      AppLogger.chat('✅ Sample messages created successfully');
    } catch (e) {
      AppLogger.chat('❌ Failed to create sample messages: $e');
    }
  }

  Future<void> _createMessageIfNotExists(String roomId, Message message) async {
    try {
      final messagesRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages');

      // Check if any messages exist in this room
      final existingMessages = await messagesRef.limit(1).get();

      if (existingMessages.docs.isEmpty) {
        await messagesRef.doc(message.messageId).set(message.toJson());
        AppLogger.chat('✅ Created sample message in room: $roomId');
      }
    } catch (e) {
      AppLogger.chat('❌ Failed to create message in room $roomId: $e');
    }
  }

  // Initialize everything
  Future<void> initializeAll() async {
    await initializeSampleChatRooms();
    await createSampleMessages();
    AppLogger.chat('🎉 Chat system initialization complete!');
  }
}

