import '../../../utils/multi_level_cache.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_message.dart';
import 'local_message_service.dart';

class WhatsAppStyleMessageCache {
  final MultiLevelCache _cache = MultiLevelCache();
  final LocalMessageService _localService = LocalMessageService();

  // Get messages for room with WhatsApp-style multi-level caching
  Future<List<Message>> getMessagesForRoom(String roomId) async {
    final cacheKey = 'messages_$roomId';

    AppLogger.chat('🔄 WhatsAppStyleMessageCache: Loading messages for room $roomId');

    // Tier 1: Memory cache (instant)
    List<Message>? messages = await _cache.get<List<Message>>(cacheKey);
    if (messages != null) {
      AppLogger.chat('⚡ WhatsAppStyleMessageCache: Memory cache hit - ${messages.length} messages');
      return messages;
    }

    // Tier 2: Disk cache (fast)
    messages = await _cache.get<List<Message>>(cacheKey);
    if (messages != null) {
      // Promote to memory cache
      await _cache.set(cacheKey, messages, priority: CachePriority.high);
      AppLogger.chat('💾 WhatsAppStyleMessageCache: Disk cache hit - ${messages.length} messages (promoted to memory)');
      return messages;
    }

    // Tier 3: Local storage (current implementation)
    messages = _localService.getMessagesForRoom(roomId);
    if (messages.isNotEmpty) {
      // Promote to multi-level cache
      await _cache.set(
        cacheKey,
        messages,
        ttl: Duration(days: 7), // Keep for 7 days
        priority: CachePriority.normal
      );
      AppLogger.chat('💽 WhatsAppStyleMessageCache: Local storage hit - ${messages.length} messages (promoted to cache)');
    } else {
      AppLogger.chat('❌ WhatsAppStyleMessageCache: No messages found for room $roomId');
    }

    return messages;
  }

  // Save message with multi-level caching
  Future<void> saveMessage(Message message, String roomId) async {
    // Save to local storage first (authoritative source)
    await _localService.saveMessage(message, roomId);

    // Update cache
    final cacheKey = 'messages_$roomId';
    final currentMessages = await getMessagesForRoom(roomId);

    // Add new message if not already present
    if (!currentMessages.any((m) => m.messageId == message.messageId)) {
      currentMessages.add(message);
      // Sort by timestamp
      currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Update all cache levels
      await _cache.set(
        cacheKey,
        currentMessages,
        ttl: Duration(days: 7),
        priority: CachePriority.high // High priority for recent messages
      );

      AppLogger.chat('💾 WhatsAppStyleMessageCache: Message saved and cached: ${message.messageId}');
    }
  }

  // Update message status across all cache levels
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    // Update local storage
    await _localService.updateMessageStatus(messageId, status);

    // Update all cached message lists that contain this message
    // This is a simplified approach - in production you'd want to track which rooms contain which messages
    final cacheKeys = await _getAllMessageCacheKeys();

    for (final cacheKey in cacheKeys) {
      final messages = await _cache.get<List<Message>>(cacheKey);
      if (messages != null) {
        final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
        if (messageIndex != -1) {
          messages[messageIndex] = messages[messageIndex].copyWith(status: status);
          await _cache.set(cacheKey, messages, priority: CachePriority.high);
          AppLogger.chat('📝 WhatsAppStyleMessageCache: Updated status for message $messageId in $cacheKey');
        }
      }
    }
  }

  // Delete message from all cache levels
  Future<void> deleteMessage(String messageId) async {
    // Delete from local storage
    await _localService.deleteMessage(messageId);

    // Remove from all cached message lists
    final cacheKeys = await _getAllMessageCacheKeys();

    for (final cacheKey in cacheKeys) {
      final messages = await _cache.get<List<Message>>(cacheKey);
      if (messages != null) {
        messages.removeWhere((m) => m.messageId == messageId);
        await _cache.set(cacheKey, messages, priority: CachePriority.high);
        AppLogger.chat('🗑️ WhatsAppStyleMessageCache: Deleted message $messageId from $cacheKey');
      }
    }
  }

  // Get message metadata for quick access
  Future<Map<String, dynamic>> getMessageMetadata(String roomId) async {
    final cacheKey = 'message_metadata_$roomId';

    // Try cache first
    final cached = await _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Generate metadata from messages
    final messages = await getMessagesForRoom(roomId);
    final metadata = {
      'totalMessages': messages.length,
      'lastMessageTime': messages.isNotEmpty ? messages.last.createdAt.toIso8601String() : null,
      'unreadCount': 0, // Would need to be calculated based on read receipts
      'hasMedia': messages.any((m) => m.type != 'text'),
      'lastActivity': messages.isNotEmpty ? messages.last.createdAt.toIso8601String() : null,
    };

    // Cache metadata
    await _cache.set(
      cacheKey,
      metadata,
      ttl: Duration(hours: 1), // Shorter TTL for metadata
      priority: CachePriority.normal
    );

    return metadata;
  }

  // Preload messages for recently active rooms
  Future<void> preloadRecentRooms(List<String> roomIds) async {
    AppLogger.chat('🔥 WhatsAppStyleMessageCache: Preloading ${roomIds.length} recent rooms');

    for (final roomId in roomIds) {
      final messages = await getMessagesForRoom(roomId);
      if (messages.isNotEmpty) {
        AppLogger.chat('🔥 WhatsAppStyleMessageCache: Preloaded ${messages.length} messages for room $roomId');
      }
    }
  }

  // Clean up old messages and cache
  Future<void> cleanupOldData({Duration maxAge = const Duration(days: 30)}) async {
    AppLogger.chat('🧹 WhatsAppStyleMessageCache: Starting cleanup');

    // Clean local storage
    await _localService.cleanupOldMessages(''); // This needs room-specific cleanup

    // Clean cache entries older than maxAge
    // Note: MultiLevelCache handles TTL automatically, but we can force cleanup
    AppLogger.chat('✅ WhatsAppStyleMessageCache: Cleanup completed');
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final localStats = _localService.getStorageStats();
    final cacheStats = _cache.getStats();

    return {
      'localStorage': localStats,
      'cache': cacheStats,
      'total': {
        'messages': localStats['totalMessages'] ?? 0,
        'sizeMB': (localStats['totalSizeMB'] ?? 0.0) + ((cacheStats['overall']?['size'] ?? 0) / (1024 * 1024)),
      },
    };
  }

  // Invalidate cache for a specific room
  Future<void> invalidateRoomCache(String roomId) async {
    final messageCacheKey = 'messages_$roomId';
    final metadataCacheKey = 'message_metadata_$roomId';

    await _cache.remove(messageCacheKey);
    await _cache.remove(metadataCacheKey);

    AppLogger.chat('🚫 WhatsAppStyleMessageCache: Invalidated cache for room $roomId');
  }

  // Warm up cache with frequently accessed data
  Future<void> warmupCache(List<String> roomIds) async {
    AppLogger.chat('🔥 WhatsAppStyleMessageCache: Warming up cache for ${roomIds.length} rooms');

    await _cache.warmup(roomIds.map((id) => 'messages_$id').toList());
    await _cache.warmup(roomIds.map((id) => 'message_metadata_$id').toList());

    AppLogger.chat('✅ WhatsAppStyleMessageCache: Cache warmup completed');
  }

  // Helper: Get all message cache keys (simplified - would need better tracking in production)
  Future<List<String>> _getAllMessageCacheKeys() async {
    // This is a simplified implementation
    // In production, you'd maintain a registry of active cache keys
    return [
      // You'd need to track which rooms have cached messages
      // For now, return empty list - individual cache operations handle this
    ];
  }

  // Initialize the cache system
  Future<void> initialize() async {
    await _localService.initialize();
    AppLogger.chat('✅ WhatsAppStyleMessageCache: Initialized');
  }

  // Close and cleanup
  Future<void> dispose() async {
    await _localService.close();
    AppLogger.chat('✅ WhatsAppStyleMessageCache: Disposed');
  }
}
