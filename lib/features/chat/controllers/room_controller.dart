import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/persistent_chat_room_cache.dart';

class RoomController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final AuthRepository _authRepository = AuthRepository();
  final PersistentChatRoomCache _persistentCache = PersistentChatRoomCache();

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
  // Member counts
  final Map<String, int> _memberCounts = {};

  // Load chat rooms for user with WhatsApp-style instant loading
  Future<void> loadChatRooms(
    String userId,
    String userRole, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    AppLogger.chat('🚀 ROOM CONTROLLER: Loading chat rooms for user $userId');

    // First, try persistent cache (WhatsApp-style instant loading)
    final persistentRooms = await _persistentCache.getCachedChatRooms(userId);

    if (persistentRooms != null && persistentRooms.isNotEmpty) {
      // Show persistent cached data immediately (like WhatsApp)
      AppLogger.chat('⚡ ROOM CONTROLLER: Instant loading ${persistentRooms.length} rooms from persistent cache');
      chatRooms.assignAll(persistentRooms);
      await _calculateUnreadCounts(userId, persistentRooms);
      await _calculateMemberCounts(persistentRooms);
      _updateChatRoomDisplayInfos();

      // Don't show loading since we have cached data
      isLoading.value = false;
    } else {
      // No cache available, fetch from server
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

        // Cache persistently for future instant loading
        await _persistentCache.cacheChatRooms(userId, rooms);

        // Calculate unread counts and member counts
        await _calculateUnreadCounts(userId, rooms);
        await _calculateMemberCounts(rooms);
        _updateChatRoomDisplayInfos();

        AppLogger.chat('✅ ROOM CONTROLLER: Loaded ${rooms.length} rooms');
      } catch (e) {
        AppLogger.chat('❌ ROOM CONTROLLER: Error loading chat rooms: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Calculate member counts for all rooms
  Future<void> _calculateMemberCounts(List<ChatRoom> rooms) async {
    final futures = <Future>[];

    for (final room in rooms) {
      if (room.type == 'private') {
        // For private chats, member count is just members.length
        _memberCounts[room.roomId] = room.members?.length ?? 0;
      } else if (room.roomId.startsWith('ward_')) {
        futures.add(_calculateWardMemberCount(room));
      } else if (room.roomId.startsWith('area_')) {
        futures.add(_calculateAreaMemberCount(room));
      }
    }

    // Wait for all async calculations to complete
    await Future.wait(futures);
  }

  // Calculate member count for a ward room
  Future<void> _calculateWardMemberCount(ChatRoom room) async {
    // try {
    //   final count = await _repository.getWardActiveUserCount(room.roomId);
    //   _memberCounts[room.roomId] = count;
    //   AppLogger.chat('🐛 Ward ${room.roomId}: counted $count members');
    // } catch (e) {
    //   AppLogger.chat('Error calculating member count for ward ${room.roomId}: $e');
    //   _memberCounts[room.roomId] = 0;
    // }
  }

  // Calculate member count for an area room
  Future<void> _calculateAreaMemberCount(ChatRoom room) async {
    // try {
    //   final count = await _repository.getAreaActiveUserCount(room.roomId);
    //   _memberCounts[room.roomId] = count;
    //   AppLogger.chat('🏠 Area ${room.roomId}: counted $count members');
    // } catch (e) {
    //   AppLogger.chat('Error calculating member count for area ${room.roomId}: $e');
    //   _memberCounts[room.roomId] = 0;
    // }
  }

  // Update display info - synchronous version that uses pre-calculated counts
  void _updateChatRoomDisplayInfos() {
    final displayInfos = <ChatRoomDisplayInfo>[];

    for (final room in chatRooms) {
      displayInfos.add(ChatRoomDisplayInfo(
        room: room,
        unreadCount: _unreadCounts[room.roomId] ?? 0,
        lastMessageTime: _lastMessageTimes[room.roomId],
        lastMessagePreview: _lastMessagePreviews[room.roomId],
        lastMessageSender: _lastMessageSenders[room.roomId],
        displayTitle: null,
        activeUsersCount: _memberCounts[room.roomId] ?? 0,
      ));
    }

    // Sort by last message time
    displayInfos.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.room.createdAt;
      final bTime = b.lastMessageTime ?? b.room.createdAt;
      return bTime.compareTo(aTime);
    });

    chatRoomDisplayInfos.assignAll(displayInfos);

    // Log member counts
    final wardDisplayInfos = chatRoomDisplayInfos.where((info) => info.room.roomId.startsWith('ward_')).toList();
    final areaDisplayInfos = chatRoomDisplayInfos.where((info) => info.room.roomId.startsWith('area_')).toList();

    AppLogger.chat('📋 ROOM CONTROLLER: Display infos updated - ${chatRoomDisplayInfos.length} rooms');
    AppLogger.chat('🏛️ WARD ROOMS: ${wardDisplayInfos.map((info) => '${info.room.roomId}(${info.activeUsersCount} users)').join(", ")}');
    AppLogger.chat('🏘️ AREA ROOMS: ${areaDisplayInfos.map((info) => '${info.room.roomId}(${info.activeUsersCount} users)').join(", ")}');
  }

  // Get total unread count
  int get totalUnreadCount {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
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

  // Reset unread count for room
  void _resetUnreadCount(String roomId) {
    _unreadCounts[roomId] = 0;
  }

  // Calculate unread counts for all rooms
  Future<void> _calculateUnreadCounts(String userId, List<ChatRoom> rooms) async {
    final firestore = FirebaseFirestore.instance;

    for (final room in rooms) {
      try {
        final totalMessagesSnapshot = await firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .get();

        final allMessages = totalMessagesSnapshot.docs;
        var unreadCount = 0;

        for (final messageDoc in allMessages) {
          final messageData = messageDoc.data();
          final readBy = List<String>.from(messageData['readBy'] ?? []);
          if (!readBy.contains(userId)) {
            unreadCount++;
          }
        }

        _unreadCounts[room.roomId] = unreadCount;

        if (allMessages.isNotEmpty) {
          final lastMessage = allMessages.first;
          final messageData = lastMessage.data();
          _lastMessageTimes[room.roomId] = (messageData['createdAt'] as Timestamp).toDate();
          _lastMessagePreviews[room.roomId] = _getMessagePreview(messageData);
          _lastMessageSenders[room.roomId] = messageData['senderId'] ?? '';
        }
      } catch (e) {
        AppLogger.chat('Error calculating unread count for room ${room.roomId}: $e');
        _unreadCounts[room.roomId] = 0;
      }
    }
  }

  // Helper method to get message preview
  String _getMessagePreview(Map<String, dynamic> messageData) {
    final text = messageData['text'] as String?;
    final type = messageData['type'] as String? ?? 'text';

    if (text != null && text.isNotEmpty) {
      return text;
    }

    switch (type) {
      case 'image':
        return '📷 Image';
      case 'audio':
        return '🎵 Voice message';
      case 'poll':
        return '📊 Poll';
      default:
        return 'Media message';
    }
  }

  // Check if room exists
  Future<bool> roomExists(String roomId) async {
    return chatRooms.any((room) => room.roomId == roomId);
  }

  // Create new chat room
  Future<ChatRoom?> createChatRoom(ChatRoom chatRoom) async {
    try {
      final createdRoom = await _repository.createChatRoom(chatRoom);
      chatRooms.add(createdRoom);
      await _calculateMemberCounts([createdRoom]);
      _updateChatRoomDisplayInfos();
      return createdRoom;
    } catch (e) {
      return null;
    }
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

  // Clear current room
  void clearCurrentRoom() {
    currentChatRoom.value = null;
  }

  // Ensure ward room exists
  Future<void> ensureWardRoomExists() async {
    AppLogger.chat('🏛️ Ward room existence check requested - method stub for compatibility');
    // Implementation would go here - currently not needed for chat list functionality
  }

  // Ensure area room exists
  Future<void> ensureAreaRoomExists() async {
    AppLogger.chat('🏘️ Area room existence check requested - method stub for compatibility');
    // Implementation would go here - currently not needed for chat list functionality
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
    _memberCounts.clear();
    super.onClose();
  }
}
