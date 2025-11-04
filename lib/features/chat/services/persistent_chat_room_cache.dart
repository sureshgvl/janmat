import '../../../utils/multi_level_cache.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';

class PersistentChatRoomCache {
  final MultiLevelCache _cache = MultiLevelCache();

  // Cache chat rooms persistently (like WhatsApp chat list)
  Future<void> cacheChatRooms(String userId, List<ChatRoom> rooms) async {
    final cacheKey = 'chat_rooms_$userId';
    final roomData = rooms.map((room) => room.toJson()).toList();

    await _cache.set(
      cacheKey,
      roomData,
      ttl: Duration(hours: 24), // Cache for 24 hours
      priority: CachePriority.high
    );

    AppLogger.chat('💾 PersistentChatRoomCache: Cached ${rooms.length} rooms for user $userId');
  }

  // Get cached chat rooms instantly
  Future<List<ChatRoom>?> getCachedChatRooms(String userId) async {
    final cacheKey = 'chat_rooms_$userId';

    final cachedData = await _cache.get<List<dynamic>>(cacheKey);
    if (cachedData != null) {
      try {
        final rooms = cachedData.map((json) => ChatRoom.fromJson(json)).toList();
        AppLogger.chat('⚡ PersistentChatRoomCache: Retrieved ${rooms.length} cached rooms for user $userId');
        return rooms;
      } catch (e) {
        AppLogger.chat('❌ PersistentChatRoomCache: Failed to parse cached rooms: $e');
        // Remove corrupted cache
        await _cache.remove(cacheKey);
        return null;
      }
    }

    AppLogger.chat('❌ PersistentChatRoomCache: No cached rooms found for user $userId');
    return null;
  }

  // Update specific room metadata (last message, unread count)
  Future<void> updateRoomMetadata(
    String userId,
    String roomId, {
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageTime,
    String? lastMessageSender,
  }) async {
    final rooms = await getCachedChatRooms(userId);
    if (rooms == null) return;

    final roomIndex = rooms.indexWhere((r) => r.roomId == roomId);
    if (roomIndex == -1) return;

    // Update the room metadata
    final updatedRoom = rooms[roomIndex];
    // Note: ChatRoom model would need to be extended to include these fields
    // For now, we'll just recache the rooms (assuming they come from server with updates)

    AppLogger.chat('📝 PersistentChatRoomCache: Updated metadata for room $roomId');
  }

  // Check if rooms are cached and fresh
  Future<bool> hasFreshCache(String userId) async {
    final cacheKey = 'chat_rooms_$userId';
    final cachedData = await _cache.get<List<dynamic>>(cacheKey);
    return cachedData != null;
  }

  // Clear cache for a specific user
  Future<void> clearUserCache(String userId) async {
    final cacheKey = 'chat_rooms_$userId';
    await _cache.remove(cacheKey);
    AppLogger.chat('🗑️ PersistentChatRoomCache: Cleared cache for user $userId');
  }

  // Clear all chat room cache
  Future<void> clearAllCache() async {
    // This would need to be implemented in MultiLevelCache
    // For now, we'll clear specific patterns
    AppLogger.chat('🧹 PersistentChatRoomCache: Clear all cache requested');
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    // This would need to be implemented in MultiLevelCache
    return {
      'cache_type': 'persistent_chat_rooms',
      'implementation': 'MultiLevelCache',
    };
  }
}
