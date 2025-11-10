import 'dart:async';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_message.dart';
import '../services/whatsapp_style_message_cache.dart';
import '../repositories/chat_repository.dart';

/// Manages message state, pagination, and loading for a specific room
class MessageStateManager extends GetxService {
  final ChatRepository _repository = ChatRepository();
  final WhatsAppStyleMessageCache _messageCache = WhatsAppStyleMessageCache();

  // Message state
  final messages = <Message>[].obs;
  final isLoadingMore = false.obs;
  final hasMoreMessages = true.obs;
  final oldestMessageTimestamp = Rx<DateTime?>(null);
  static const int messagesPerPage = 20;

  // Real-time listener management
  StreamSubscription<List<Message>>? _currentRoomMessagesSubscription;
  String? _currentRoomId;

  @override
  void onInit() {
    super.onInit();
    _messageCache.initialize();
  }

  /// Load messages for a specific room with caching
  Future<void> loadMessagesForRoom(String roomId) async {
    AppLogger.chat('🚀 MessageStateManager: Loading messages for room $roomId');

    // Cancel any existing room subscription
    _currentRoomMessagesSubscription?.cancel();
    _currentRoomMessagesSubscription = null;
    _currentRoomId = roomId;

    // Clear existing messages when switching rooms
    messages.clear();
    AppLogger.chat('🧹 MessageStateManager: Cleared existing messages for room switch');

    // Reset pagination state
    hasMoreMessages.value = true;
    oldestMessageTimestamp.value = null;

    // Load from cache first
    final cachedMessages = await _messageCache.getMessagesForRoom(roomId);
    if (cachedMessages.isNotEmpty) {
      messages.assignAll(cachedMessages);
      oldestMessageTimestamp.value = cachedMessages.first.createdAt;
      AppLogger.chat('⚡ MessageStateManager: Loaded ${cachedMessages.length} messages from cache');
    } else {
      AppLogger.chat('📭 MessageStateManager: No cached messages, will load from server');
    }

    // Listen to real-time updates
    _currentRoomMessagesSubscription = _repository.getMessagesForRoom(roomId).listen((serverMessages) {
      AppLogger.chat('🔄 MessageStateManager: Received ${serverMessages.length} messages from server for room $roomId');

      // Merge with current messages
      final mergedMessages = _mergeMessages(messages, serverMessages);
      messages.assignAll(mergedMessages);

      // Cache the latest messages
      if (mergedMessages.isNotEmpty) {
        _messageCache.saveMessage(mergedMessages.last, roomId);
      }

      AppLogger.chat('✅ MessageStateManager: Messages updated for room $roomId, total: ${messages.length}');
    });
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages(String roomId) async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;

    isLoadingMore.value = true;

    try {
      AppLogger.chat('📄 MessageStateManager: Loading more messages for room: $roomId');

      final olderMessages = await _repository.getMessagesForRoomPaginated(
        roomId,
        limit: messagesPerPage,
        startAfter: oldestMessageTimestamp.value,
      );

      if (olderMessages.isEmpty) {
        hasMoreMessages.value = false;
        AppLogger.chat('📄 MessageStateManager: No more messages to load');
      } else {
        messages.insertAll(0, olderMessages);
        oldestMessageTimestamp.value = olderMessages.last.createdAt;
        AppLogger.chat('📄 MessageStateManager: Loaded ${olderMessages.length} more messages, total: ${messages.length}');
      }
    } catch (e) {
      AppLogger.chat('❌ MessageStateManager: Error loading more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Add a message to the UI immediately
  void addMessageToUI(Message message) {
    AppLogger.chat('📝 MessageStateManager: addMessageToUI called - Message ID: ${message.messageId}');

    // Check if message already exists
    final existingIndex = messages.indexWhere((m) => m.messageId == message.messageId);
    if (existingIndex != -1) {
      AppLogger.chat('⚠️ MessageStateManager: Message ${message.messageId} already exists, skipping duplicate add');
      return;
    }

    messages.add(message);
    AppLogger.chat('✅ MessageStateManager: Added message ${message.messageId} to UI, total messages: ${messages.length}');
  }

  /// Update message status
  void updateMessageStatus(String messageId, MessageStatus status) {
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = messages[messageIndex].copyWith(status: status);
      AppLogger.chat('📝 MessageStateManager: Updated message $messageId status to $status');
    }
  }

  /// Update message media URL
  void updateMessageMediaUrl(String messageId, String remoteUrl) {
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = messages[messageIndex].copyWith(mediaUrl: remoteUrl);
    }
  }

  /// Get media URL (local or remote)
  String? getMediaUrl(String messageId, String? remoteUrl) {
    // This would delegate to a media manager, but for now return remote URL
    return remoteUrl;
  }

  /// Clear messages for room switch
  void clearMessages() {
    messages.clear();
    hasMoreMessages.value = true;
    oldestMessageTimestamp.value = null;
  }

  /// Merge server messages with local messages
  List<Message> _mergeMessages(List<Message> localMessages, List<Message> serverMessages) {
    AppLogger.chat('🔄 MessageStateManager: Starting merge process...');
    AppLogger.chat('   Local messages: ${localMessages.length}');
    AppLogger.chat('   Server messages: ${serverMessages.length}');

    final merged = <String, Message>{};
    final contentKeyMap = <String, String>{};

    // Helper function to create content key for duplicate detection
    String createContentKey(Message msg) {
      final timestampKey = (msg.createdAt.millisecondsSinceEpoch ~/ 5000).toString();
      return '${msg.senderId}_${msg.text}_$timestampKey';
    }

    // Add server messages first
    for (final message in serverMessages) {
      final contentKey = createContentKey(message);
      merged[message.messageId] = message;
      contentKeyMap[contentKey] = message.messageId;
    }

    // Add local messages only if they don't exist
    for (final message in localMessages) {
      final contentKey = createContentKey(message);

      if (!merged.containsKey(message.messageId) && !contentKeyMap.containsKey(contentKey)) {
        merged[message.messageId] = message;
        contentKeyMap[contentKey] = message.messageId;
      }
    }

    // Sort by creation time
    final sortedMessages = merged.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    AppLogger.chat('📝 MessageStateManager: Merged ${localMessages.length} local + ${serverMessages.length} server = ${sortedMessages.length} unique messages');

    return sortedMessages;
  }

  @override
  void onClose() {
    _currentRoomMessagesSubscription?.cancel();
    messages.clear();
    super.onClose();
  }
}
