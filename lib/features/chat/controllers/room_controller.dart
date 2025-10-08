import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';
import '../../../models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';

class RoomController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final AuthRepository _authRepository = AuthRepository();

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
    // Check if we have cached data first
    final cacheKey = userRole == 'voter'
        ? '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}'
        : '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}_${area ?? 'no_area'}';

    final cachedRooms = await _repository.getCachedRooms(cacheKey);

    if (cachedRooms != null && cachedRooms.isNotEmpty) {
      // Show cached data immediately
      AppLogger.chat('⚡ ROOM CONTROLLER: Showing ${cachedRooms.length} cached rooms immediately');
      chatRooms.assignAll(cachedRooms);
      await _calculateUnreadCounts(userId, cachedRooms);
      _updateChatRoomDisplayInfos();

      // Then fetch fresh data in background
      isLoading.value = false; // Don't show loading since we have cached data
      _loadFreshDataInBackground(userId, userRole, cacheKey, stateId: stateId, districtId: districtId, bodyId: bodyId, wardId: wardId, area: area);
    } else {
      // No cached data, show loading
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
        AppLogger.chat('Error loading chat rooms: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Load fresh data in background when cached data is already displayed
  Future<void> _loadFreshDataInBackground(
    String userId,
    String userRole,
    String cacheKey, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    try {
      AppLogger.chat('🔄 ROOM CONTROLLER: Loading fresh data in background...');
      final freshRooms = await _repository.getChatRoomsForUser(
        userId,
        userRole,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
        area: area,
      );

      // Only update if we got different data
      if (freshRooms.length != chatRooms.length ||
          !freshRooms.every((room) => chatRooms.any((cached) => cached.roomId == room.roomId))) {
        AppLogger.chat('🔄 ROOM CONTROLLER: Fresh data differs from cache, updating UI');
        chatRooms.assignAll(freshRooms);
        await _calculateUnreadCounts(userId, freshRooms);
        _updateChatRoomDisplayInfos();
      } else {
        AppLogger.chat('🔄 ROOM CONTROLLER: Fresh data matches cache, no UI update needed');
      }
    } catch (e) {
      AppLogger.chat('Error loading fresh chat rooms in background: $e');
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
        AppLogger.chat('Error calculating unread count for room ${room.roomId}: $e');
        _unreadCounts[room.roomId] = 0;
      }
    }
  }

  // Update display info
  void _updateChatRoomDisplayInfos() async {
    final displayInfos = <ChatRoomDisplayInfo>[];

    for (final room in chatRooms) {
      String? displayTitle;

      // For private chats, get the other user's name
      if (room.type == 'private') {
        try {
          final userInfo = await _getPrivateChatDisplayTitle(room.roomId);
          displayTitle = userInfo;
        } catch (e) {
          AppLogger.chat('Error getting private chat display title: $e');
          displayTitle = 'Private Chat';
        }
      }

      displayInfos.add(ChatRoomDisplayInfo(
        room: room,
        unreadCount: _unreadCounts[room.roomId] ?? 0,
        lastMessageTime: _lastMessageTimes[room.roomId],
        lastMessagePreview: _lastMessagePreviews[room.roomId],
        lastMessageSender: _lastMessageSenders[room.roomId],
        displayTitle: displayTitle,
      ));
    }

    // Sort by last message time
    displayInfos.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.room.createdAt;
      final bTime = b.lastMessageTime ?? b.room.createdAt;
      return bTime.compareTo(aTime);
    });

    chatRoomDisplayInfos.assignAll(displayInfos);
  }

  // Get display title for private chat (other user's name)
  Future<String?> _getPrivateChatDisplayTitle(String roomId) async {
    try {
      final roomDoc = await FirebaseFirestore.instance.collection('chats').doc(roomId).get();
      if (!roomDoc.exists) return 'Private Chat';

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(roomData['members'] ?? []);

      // Get current user ID from auth repository
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) return 'Private Chat';
      final currentUserId = currentUser.uid;

      // Find the other user
      final otherUserId = members.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return 'Private Chat';

      // Get other user's info
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) return 'Private Chat';

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['name'] ?? 'Private Chat';
    } catch (e) {
      AppLogger.chat('Error getting private chat display title: $e');
      return 'Private Chat';
    }
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

