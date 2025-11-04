import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'persistent_chat_room_cache.dart';
import 'whatsapp_style_media_manager.dart';
import 'local_message_service.dart';

class ChatExperienceData {
  final List<ChatRoom> rooms;
  final Map<String, Message> recentMessages;
  final Map<String, int> unreadCounts;
  final bool isFromCache;

  ChatExperienceData({
    required this.rooms,
    required this.recentMessages,
    required this.unreadCounts,
    required this.isFromCache,
  });

  factory ChatExperienceData.loading() {
    return ChatExperienceData(
      rooms: [],
      recentMessages: {},
      unreadCounts: {},
      isFromCache: false,
    );
  }
}

class WhatsAppStyleChatCache {
  final PersistentChatRoomCache _roomCache = PersistentChatRoomCache();
  final WhatsAppStyleMediaManager _mediaManager = WhatsAppStyleMediaManager();
  final LocalMessageService _localMessageService = LocalMessageService();

  // Load chat experience instantly (like WhatsApp)
  Future<ChatExperienceData> loadChatExperience(String userId) async {
    AppLogger.chat('🚀 WhatsAppStyleChatCache: Loading chat experience for user $userId');

    // Parallel loading for instant experience
    final results = await Future.wait([
      _roomCache.getCachedChatRooms(userId),      // Instant room list
      _loadRecentMessages(userId),                 // Recent messages
      _loadUnreadCounts(userId),                   // Unread badges
    ]);

    final rooms = results[0] as List<ChatRoom>? ?? [];
    final recentMessages = results[1] as Map<String, Message>;
    final unreadCounts = results[2] as Map<String, int>;

    // If no cached data, show loading but fetch in background
    if (rooms.isEmpty) {
      AppLogger.chat('⚠️ WhatsAppStyleChatCache: No cached data, starting background fetch');
      _fetchFreshDataInBackground(userId);
      return ChatExperienceData.loading();
    }

    AppLogger.chat('✅ WhatsAppStyleChatCache: Loaded ${rooms.length} rooms from cache instantly');
    return ChatExperienceData(
      rooms: rooms,
      recentMessages: recentMessages,
      unreadCounts: unreadCounts,
      isFromCache: true
    );
  }

  Future<void> _fetchFreshDataInBackground(String userId) async {
    try {
      AppLogger.chat('🔄 WhatsAppStyleChatCache: Fetching fresh data in background...');

      // Import here to avoid circular dependencies
      final chatRepository = await _getChatRepository();
      final freshRooms = await chatRepository.getChatRoomsForUser(userId, 'voter');

      await _roomCache.cacheChatRooms(userId, freshRooms);

      // Update UI with fresh data (this would need to be handled by the controller)
      AppLogger.chat('✅ WhatsAppStyleChatCache: Fresh data cached and ready for next load');

      // TODO: Notify UI to refresh with new data
      // Get.find<ChatController>().updateRooms(freshRooms);

    } catch (e) {
      AppLogger.chat('❌ WhatsAppStyleChatCache: Failed to fetch fresh data: $e');
    }
  }

  // Cache new chat rooms
  Future<void> cacheChatRooms(String userId, List<ChatRoom> rooms) async {
    await _roomCache.cacheChatRooms(userId, rooms);
    AppLogger.chat('💾 WhatsAppStyleChatCache: Cached ${rooms.length} rooms for user $userId');
  }

  // Update room metadata (last message, unread count)
  Future<void> updateRoomMetadata(
    String userId,
    String roomId, {
    String? lastMessage,
    int? unreadCount,
    DateTime? lastMessageTime,
    String? lastMessageSender,
  }) async {
    await _roomCache.updateRoomMetadata(
      userId,
      roomId,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      lastMessageTime: lastMessageTime,
      lastMessageSender: lastMessageSender,
    );
  }

  // Media management
  Future<String?> downloadAndCacheMedia(
    String messageId,
    String remoteUrl,
    String originalFileName,
  ) async {
    return await _mediaManager.downloadAndCacheMedia(
      messageId,
      remoteUrl,
      originalFileName,
    );
  }

  Future<String?> getLocalMediaPath(String messageId, String originalFileName) async {
    return await _mediaManager.getLocalMediaPath(messageId, originalFileName);
  }

  // Message caching
  Future<List<Message>> getMessagesForRoom(String roomId) async {
    return _localMessageService.getMessagesForRoom(roomId);
  }

  Future<void> saveMessage(Message message, String roomId) async {
    await _localMessageService.saveMessage(message, roomId);
  }

  // Storage management
  Future<Map<String, dynamic>> getStorageStats() async {
    final mediaStats = await _mediaManager.getStorageStats();
    final messageStats = _localMessageService.getStorageStats();

    return {
      'media': mediaStats,
      'messages': messageStats,
      'total': {
        'files': (mediaStats['totalFiles'] ?? 0) + (messageStats['totalMessages'] ?? 0),
        'sizeMB': (mediaStats['totalSizeMB'] ?? 0.0) + (messageStats['totalSizeMB'] ?? 0.0),
      },
    };
  }

  // Cleanup old data
  Future<void> cleanupOldData({Duration maxAge = const Duration(days: 30)}) async {
    await _mediaManager.cleanupOldMedia(maxAge: maxAge);
    // Message cleanup would be handled by LocalMessageService
  }

  // Clear all cache
  Future<void> clearAllCache(String userId) async {
    await _roomCache.clearUserCache(userId);
    // Media and messages are kept for offline access
    AppLogger.chat('🧹 WhatsAppStyleChatCache: Cleared room cache for user $userId');
  }

  // Helper methods
  Future<Map<String, Message>> _loadRecentMessages(String userId) async {
    // This would load the most recent message for each room
    // For now, return empty map
    return {};
  }

  Future<Map<String, int>> _loadUnreadCounts(String userId) async {
    // This would load unread counts for each room
    // For now, return empty map
    return {};
  }

  Future<dynamic> _getChatRepository() async {
    // Dynamic import to avoid circular dependencies
    // This would need to be implemented properly
    return null;
  }

  // Initialize the cache system
  Future<void> initialize() async {
    await _localMessageService.initialize();
    AppLogger.chat('✅ WhatsAppStyleChatCache: Initialized');
  }
}
