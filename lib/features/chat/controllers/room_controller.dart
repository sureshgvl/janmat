import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';

class RoomController extends GetxController {
  final ChatRepository _repository = ChatRepository();

  // Room state
  var chatRooms = <ChatRoom>[].obs;
  var chatRoomDisplayInfos = <ChatRoomDisplayInfo>[].obs;
  var currentChatRoom = Rx<ChatRoom?>(null);
  var isLoading = false.obs;

  // Unread counts
  final Map<String, int> _unreadCounts = {};
  final Map<String, DateTime> _lastMessageTimes = {};
  final Map<String, String> _lastMessagePreviews = {};
  final Map<String, String> _lastMessageSenders = {};

  // Load chat rooms for user
  Future<void> loadChatRooms(
    String userId,
    String userRole, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    isLoading.value = true;
    try {
      final rooms = await _repository.getChatRoomsForUser(
        userId,
        userRole,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
        area: area,
      );
      chatRooms.assignAll(rooms);

      // Calculate unread counts for each room
      await _calculateUnreadCounts(userId, rooms);

      _updateChatRoomDisplayInfos();
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  // Create new chat room
  Future<ChatRoom?> createChatRoom(ChatRoom chatRoom) async {
    try {
      final createdRoom = await _repository.createChatRoom(chatRoom);
      chatRooms.add(createdRoom);
      _updateChatRoomDisplayInfos();
      return createdRoom;
    } catch (e) {
      return null;
    }
  }

  // Select chat room
  void selectChatRoom(ChatRoom chatRoom) {
    currentChatRoom.value = chatRoom;
    _resetUnreadCount(chatRoom.roomId);
    _updateChatRoomDisplayInfos();
  }

  // Update unread count
  void updateUnreadCount(String roomId, int count) {
    _unreadCounts[roomId] = count;
    _updateChatRoomDisplayInfos();
  }

  // Update last message info
  void updateLastMessageInfo(
    String roomId, {
    DateTime? time,
    String? preview,
    String? sender,
  }) {
    if (time != null) _lastMessageTimes[roomId] = time;
    if (preview != null) _lastMessagePreviews[roomId] = preview;
    if (sender != null) _lastMessageSenders[roomId] = sender;
    _updateChatRoomDisplayInfos();
  }

  // Reset unread count for room
  void _resetUnreadCount(String roomId) {
    _unreadCounts[roomId] = 0;
  }

  // Calculate unread counts for all rooms
  Future<void> _calculateUnreadCounts(String userId, List<ChatRoom> rooms) async {
    final firestore = FirebaseFirestore.instance;

    for (final room in rooms) {
      try {
        final messages = await firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .where('readBy', arrayContains: userId)
            .get();

        final totalMessages = await firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .get();

        final unreadCount = totalMessages.docs.length - messages.docs.length;
        _unreadCounts[room.roomId] = unreadCount;

        // Also get last message info for sorting
        if (totalMessages.docs.isNotEmpty) {
          final lastMessage = totalMessages.docs.last;
          final messageData = lastMessage.data();
          _lastMessageTimes[room.roomId] = (messageData['createdAt'] as Timestamp).toDate();
          _lastMessagePreviews[room.roomId] = messageData['text'] ?? 'Media message';
          _lastMessageSenders[room.roomId] = messageData['senderId'] ?? '';
        }
      } catch (e) {
        debugPrint('Error calculating unread count for room ${room.roomId}: $e');
        _unreadCounts[room.roomId] = 0;
      }
    }
  }

  // Update display info
  void _updateChatRoomDisplayInfos() {
    chatRoomDisplayInfos.assignAll(
      chatRooms.map((room) {
        return ChatRoomDisplayInfo(
          room: room,
          unreadCount: _unreadCounts[room.roomId] ?? 0,
          lastMessageTime: _lastMessageTimes[room.roomId],
          lastMessagePreview: _lastMessagePreviews[room.roomId],
          lastMessageSender: _lastMessageSenders[room.roomId],
        );
      }).toList()..sort((a, b) {
        final aTime = a.lastMessageTime ?? a.room.createdAt;
        final bTime = b.lastMessageTime ?? b.room.createdAt;
        return bTime.compareTo(aTime);
      }),
    );
  }

  // Get total unread count
  int get totalUnreadCount {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  // Check if room exists
  Future<bool> roomExists(String roomId) async {
    return chatRooms.any((room) => room.roomId == roomId);
  }

  // Ensure ward room exists
  Future<void> ensureWardRoomExists() async {
    // Implementation would go here
  }

  // Ensure area room exists
  Future<void> ensureAreaRoomExists() async {
    // Implementation would go here
  }

  // Clear current room
  void clearCurrentRoom() {
    currentChatRoom.value = null;
  }

  // Clean up
  @override
  void onClose() {
    chatRooms.clear();
    chatRoomDisplayInfos.clear();
    currentChatRoom.value = null;
    _unreadCounts.clear();
    _lastMessageTimes.clear();
    _lastMessagePreviews.clear();
    _lastMessageSenders.clear();
    super.onClose();
  }
}

