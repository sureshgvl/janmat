import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../repositories/chat_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/persistent_chat_room_cache.dart';

class RoomController {
  final ChatRepository _repository = ChatRepository();
  final AuthRepository _authRepository = AuthRepository();
  final PersistentChatRoomCache _persistentCache = PersistentChatRoomCache();

  // Room state - now managed by Riverpod providers
  List<ChatRoom> _chatRooms = [];
  List<ChatRoomDisplayInfo> _chatRoomDisplayInfos = [];
  ChatRoom? _currentChatRoom;
  bool _isLoading = false;

  // Getters for state (will be accessed through Riverpod providers)
  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatRoomDisplayInfo> get chatRoomDisplayInfos => _chatRoomDisplayInfos;
  ChatRoom? get currentChatRoom => _currentChatRoom;
  bool get isLoading => _isLoading;

  // Unread counts
  final Map<String, int> _unreadCounts = {};
  final Map<String, DateTime> _lastMessageTimes = {};
  final Map<String, String> _lastMessagePreviews = {};
  final Map<String, String> _lastMessageSenders = {};

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
      _chatRooms = persistentRooms;
      await _calculateUnreadCounts(userId, persistentRooms);
      _updateChatRoomDisplayInfos();

      // Then fetch fresh data in background
      _isLoading = false; // Don't show loading since we have cached data
      _loadFreshDataInBackground(userId, userRole, '', stateId: stateId, districtId: districtId, bodyId: bodyId, wardId: wardId, area: area);
    } else {
      // Check repository cache as fallback
      final cacheKey = userRole == 'voter'
          ? '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}'
          : '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}_${area ?? 'no_area'}';

      final cachedRooms = await _repository.getCachedRooms(cacheKey);

      if (cachedRooms != null && cachedRooms.isNotEmpty) {
        // Show repository cached data immediately
        AppLogger.chat('💾 ROOM CONTROLLER: Showing ${cachedRooms.length} repository cached rooms');
        _chatRooms = cachedRooms;
        await _calculateUnreadCounts(userId, cachedRooms);
        _updateChatRoomDisplayInfos();

        // Cache persistently for next time and fetch fresh data
        await _persistentCache.cacheChatRooms(userId, cachedRooms);
        _isLoading = false;
        _loadFreshDataInBackground(userId, userRole, cacheKey, stateId: stateId, districtId: districtId, bodyId: bodyId, wardId: wardId, area: area);
      } else {
        // No cached data at all, show loading and fetch from server
        AppLogger.chat('🔄 ROOM CONTROLLER: No cache available, fetching from server');
        _isLoading = true;
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
          _chatRooms = rooms;

          // Cache persistently for future instant loading
          await _persistentCache.cacheChatRooms(userId, rooms);

          // Calculate unread counts for each room
          await _calculateUnreadCounts(userId, rooms);
          _updateChatRoomDisplayInfos();

          AppLogger.chat('✅ ROOM CONTROLLER: Loaded and cached ${rooms.length} rooms');
        } catch (e) {
          AppLogger.chat('❌ ROOM CONTROLLER: Error loading chat rooms: $e');
        } finally {
          _isLoading = false;
        }
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
      if (freshRooms.length != _chatRooms.length ||
          !freshRooms.every((room) => _chatRooms.any((cached) => cached.roomId == room.roomId))) {
        AppLogger.chat('🔄 ROOM CONTROLLER: Fresh data differs from cache, updating UI');
        _chatRooms = freshRooms;
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
      _chatRooms.add(createdRoom);
      _updateChatRoomDisplayInfos();
      return createdRoom;
    } catch (e) {
      return null;
    }
  }

  // Select chat room
  void selectChatRoom(ChatRoom chatRoom) {
    _currentChatRoom = chatRoom;
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

    // Process rooms in batches to avoid overwhelming Firestore
    const batchSize = 5;
    for (var i = 0; i < rooms.length; i += batchSize) {
      final batch = rooms.sublist(i, i + batchSize > rooms.length ? rooms.length : i + batchSize);
      final futures = batch.map((room) => _calculateUnreadCountForRoom(userId, room));
      await Future.wait(futures);
    }
  }

  // Calculate unread count for a single room
  Future<void> _calculateUnreadCountForRoom(String userId, ChatRoom room) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Get all messages for this room (we need them anyway for last message info)
      final totalMessagesSnapshot = await firestore
          .collection('chats')
          .doc(room.roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to recent messages for performance
          .get();

      final allMessages = totalMessagesSnapshot.docs;

      // Calculate unread count by checking which messages don't contain userId in readBy
      var unreadCount = 0;
      for (final messageDoc in allMessages) {
        final messageData = messageDoc.data();
        final readBy = List<String>.from(messageData['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          unreadCount++;
        }
      }

      _unreadCounts[room.roomId] = unreadCount;

      // Get last message info for sorting (from the first message since we ordered descending)
      if (allMessages.isNotEmpty) {
        final lastMessage = allMessages.first; // First because we ordered descending
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

    _chatRoomDisplayInfos = displayInfos;
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
    _currentChatRoom = null;
  }

  // Clean up
  void dispose() {
    _chatRooms.clear();
    _chatRoomDisplayInfos.clear();
    _currentChatRoom = null;
    _unreadCounts.clear();
    _lastMessageTimes.clear();
    _lastMessagePreviews.clear();
    _lastMessageSenders.clear();
  }
}
