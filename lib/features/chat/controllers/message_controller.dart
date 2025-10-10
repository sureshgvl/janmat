import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../utils/app_logger.dart';
import '../models/chat_message.dart';
import '../models/user_quota.dart';
import '../services/local_message_service.dart';
import '../services/media_service.dart';
import '../services/offline_message_queue.dart';
import '../services/private_chat_service.dart';
import '../repositories/chat_repository.dart';
import 'room_controller.dart';

class MessageController extends GetxController {
   final ChatRepository _repository = ChatRepository();
   final LocalMessageService _localMessageService = LocalMessageService();
   final MediaService _mediaService = MediaService();
   final OfflineMessageQueue _offlineQueue = OfflineMessageQueue();
   final PrivateChatService _privateChatService = PrivateChatService();
   final AudioRecorder _audioRecorder = AudioRecorder();
   final RoomController _roomController = Get.find<RoomController>();

  // Voice recording state
  var isRecording = false.obs;
  String? currentRecordingPath;

  @override
  void onInit() {
    super.onInit();
    _localMessageService.initialize();
    _offlineQueue.initialize();
    _loadUserQuota();

    // Set up offline queue callbacks
    _setupOfflineQueueCallbacks();
  }

  // Message state
  var messages = <Message>[].obs;
  var userQuota = Rx<UserQuota?>(null);

  // Pagination state
  var isLoadingMore = false.obs;
  var hasMoreMessages = true.obs;
  var oldestMessageTimestamp = Rx<DateTime?>(null);
  static const int messagesPerPage = 20;

  // Message sending
  Future<void> sendTextMessage(
    String roomId,
    String text,
    String senderId, {
    Message? existingMessage,
  }) async {
    if (text.trim().isEmpty) return;

    // Check if this is a ward room and add broadcast control metadata
    final isWardRoom = roomId.startsWith('ward_');
    final metadata = isWardRoom ? {'broadcast': false} : null;

    final message = existingMessage ?? Message(
      messageId: _generateMessageId(),
      text: text,
      senderId: senderId,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [senderId],
      status: MessageStatus.sending, // Mark as sending initially
      metadata: metadata,
    );

    AppLogger.chat(
      '📤 MessageController: sendTextMessage called - Message ID: ${message.messageId}, Text: "${message.text}", Room: $roomId',
    );

    // Note: Message is added to UI by ChatController.addMessageToUI
    // Don't add here to prevent duplicates

    // Send to server asynchronously (don't block UI)
    _sendMessageToServer(message, roomId);
  }

  Future<void> _sendMessageToServer(Message message, String roomId) async {
    // Use offline queue for reliable message delivery
    await _offlineQueue.queueMessage(
      message,
      roomId,
      (msg, rId) async {
        // This function will be called by the offline queue
        await _repository.sendMessage(rId, msg);
        await _updateUserQuotaAfterMessage();

        // Update private chat metadata if this is a private chat
        if (rId.startsWith('private_')) {
          await _updatePrivateChatMetadata(msg, rId);
        }
      },
    );

    AppLogger.chat('MessageController: Message queued for sending: ${message.messageId}');
  }

  // Set up offline queue callbacks
  void _setupOfflineQueueCallbacks() {
    _offlineQueue.onMessageQueued = (queuedMessage) {
      AppLogger.chat('📋 MessageController: Message queued for offline sending: ${queuedMessage.message.messageId}');
      // Update UI to show queued status
      updateMessageStatus(queuedMessage.message.messageId, MessageStatus.sending);
    };

    _offlineQueue.onMessageSent = (queuedMessage) {
      AppLogger.chat('✅ MessageController: Queued message sent successfully: ${queuedMessage.message.messageId}');
      // Update UI to show sent status
      updateMessageStatus(queuedMessage.message.messageId, MessageStatus.sent);
    };

    _offlineQueue.onMessageFailed = (queuedMessage, error) {
      AppLogger.chat('❌ MessageController: Queued message failed: ${queuedMessage.message.messageId} - $error');
      // Update UI to show failed status
      updateMessageStatus(queuedMessage.message.messageId, MessageStatus.failed);
    };
  }

  // Load user quota
  Future<void> _loadUserQuota() async {
    // For now, just set a default quota since we don't have user auth in this controller
    // The quota will be managed by the main ChatController
    AppLogger.chat('MessageController: Quota loading deferred to ChatController');
  }

  // Update user quota after sending a message
  Future<void> _updateUserQuotaAfterMessage() async {
    try {
      // Get current quota
      final currentQuota = userQuota.value;
      if (currentQuota != null) {
        // Increment messages sent
        final updatedQuota = currentQuota.copyWith(
          messagesSent: currentQuota.messagesSent + 1,
        );

        // Update local state
        userQuota.value = updatedQuota;

        // Update in repository
        await _repository.updateUserQuota(updatedQuota);

        AppLogger.chat(
          'MessageController: Updated quota - sent: ${updatedQuota.messagesSent}, remaining: ${updatedQuota.remainingMessages}',
        );
      }
    } catch (e) {
      AppLogger.chat('MessageController: Failed to update quota: $e');
    }
  }

  // Update private chat metadata when messages are sent
  Future<void> _updatePrivateChatMetadata(Message message, String roomId) async {
    try {
      // Create message preview for chat list
      String messagePreview = message.text;
      if (message.type == 'image') {
        messagePreview = '📷 Image';
      } else if (message.type == 'audio') {
        messagePreview = '🎵 Voice message';
      } else if (message.type == 'poll') {
        messagePreview = '📊 Poll';
      }

      // Update last message info in both users' private chat documents
      await _privateChatService.updateChatLastMessage(
        roomId,
        messagePreview,
        message.senderId,
        message.createdAt,
      );

      AppLogger.chat('✅ Updated private chat metadata for room: $roomId');
    } catch (e) {
      AppLogger.chat('❌ Error updating private chat metadata: $e');
    }
  }

  // Voice recording methods
  Future<void> startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory(
          path.join(appDir.path, 'voice_recordings'),
        );

        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        currentRecordingPath = path.join(recordingsDir.path, fileName);

        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: currentRecordingPath!);
        isRecording.value = true;

        AppLogger.chat(
          'MessageController: Started voice recording: $currentRecordingPath',
        );
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      AppLogger.chat('MessageController: Failed to start voice recording: $e');
      isRecording.value = false;
      rethrow;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;

      if (path != null) {
        AppLogger.chat('MessageController: Stopped voice recording: $path');
        return path;
      } else {
        AppLogger.chat(
          'MessageController: Voice recording failed - no path returned',
        );
        return null;
      }
    } catch (e) {
      AppLogger.chat('MessageController: Failed to stop voice recording: $e');
      isRecording.value = false;
      return null;
    }
  }

  Future<void> sendImageMessage(
    String roomId,
    String imagePath,
    String senderId,
  ) async {
    // Check if this is a ward room and add broadcast control metadata
    final isWardRoom = roomId.startsWith('ward_');
    final metadata = isWardRoom ? {'broadcast': false} : null;

    final message = Message(
      messageId: _generateMessageId(),
      text: 'Image',
      senderId: senderId,
      type: 'image',
      createdAt: DateTime.now(),
      readBy: [senderId],
      mediaUrl: imagePath, // Local path initially
      mediaLocalPath: imagePath,
      metadata: metadata,
    );

    // Save locally immediately and add to UI
    await _localMessageService.saveMessage(message, roomId);
    messages.add(message);
    AppLogger.chat(
      '📝 MessageController: Added voice message to UI, total messages: ${messages.length}',
    );
    update(); // Force UI update
    AppLogger.chat(
      '📝 MessageController: Added image message to UI, total messages: ${messages.length}',
    );
    update(); // Force UI update
    AppLogger.chat(
      '📝 MessageController: Added message to UI, total messages: ${messages.length}',
    );
    update(); // Force UI update

    // Send to server asynchronously (don't block UI)
    _sendImageMessageToServer(message, roomId, imagePath);
  }

  Future<void> _sendImageMessageToServer(
    Message message,
    String roomId,
    String imagePath,
  ) async {
    // Use offline queue for reliable image message delivery
    await _offlineQueue.queueMessage(
      message,
      roomId,
      (msg, rId) async {
        // Upload to Firebase Storage
        final fileName = path.basename(imagePath);
        final remoteUrl = await _mediaService.uploadMediaFile(
          rId,
          imagePath,
          fileName,
          'image/jpeg',
        );

        // Update message with remote URL
        await _localMessageService.updateMessageMediaUrl(
          msg.messageId,
          remoteUrl,
        );

        // Send to server
        await _repository.sendMessage(
          rId,
          msg.copyWith(mediaUrl: remoteUrl),
        );

        // Update local quota
        await _updateUserQuotaAfterMessage();

        // Update status to sent
        await _localMessageService.updateMessageStatus(
          msg.messageId,
          MessageStatus.sent,
        );
      },
    );

    AppLogger.chat('MessageController: Image message queued for sending: ${message.messageId}');
  }

  Future<void> sendPollMessage(String roomId, Message message) async {
    // Check if this is a ward room and add broadcast control metadata
    final isWardRoom = roomId.startsWith('ward_');
    final metadata = isWardRoom ? {'broadcast': false} : null;
    final pollMessage = message.copyWith(metadata: metadata);

    AppLogger.chat('📊 MessageController: Sending poll message: ${message.messageId} to room: $roomId');

    // Send to server asynchronously (don't block UI)
    _sendMessageToServer(pollMessage, roomId);
  }

  Future<void> sendVoiceMessage(
    String roomId,
    String audioPath,
    String senderId,
  ) async {
    // Check if this is a ward room and add broadcast control metadata
    final isWardRoom = roomId.startsWith('ward_');
    final metadata = isWardRoom ? {'broadcast': false} : null;

    final message = Message(
      messageId: _generateMessageId(),
      text: 'Voice message',
      senderId: senderId,
      type: 'audio',
      createdAt: DateTime.now(),
      readBy: [senderId],
      mediaUrl: audioPath, // Local path initially
      mediaLocalPath: audioPath,
      metadata: metadata,
    );

    // Save locally immediately and add to UI
    await _localMessageService.saveMessage(message, roomId);
    messages.add(message);

    // Send to server asynchronously (don't block UI)
    _sendVoiceMessageToServer(message, roomId, audioPath);
  }

  Future<void> _sendVoiceMessageToServer(
    Message message,
    String roomId,
    String audioPath,
  ) async {
    // Use offline queue for reliable voice message delivery
    await _offlineQueue.queueMessage(
      message,
      roomId,
      (msg, rId) async {
        // Upload to Firebase Storage
        final fileName = path.basename(audioPath);
        final remoteUrl = await _mediaService.uploadMediaFile(
          rId,
          audioPath,
          fileName,
          'audio/m4a',
        );

        // Update message with remote URL
        await _localMessageService.updateMessageMediaUrl(
          msg.messageId,
          remoteUrl,
        );

        // Send to server
        await _repository.sendMessage(
          rId,
          msg.copyWith(mediaUrl: remoteUrl),
        );

        // Update local quota
        await _updateUserQuotaAfterMessage();

        // Update status to sent
        await _localMessageService.updateMessageStatus(
          msg.messageId,
          MessageStatus.sent,
        );
      },
    );

    AppLogger.chat('MessageController: Voice message queued for sending: ${message.messageId}');
  }

  // Message reactions
  Future<void> addReaction(
    String roomId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    await _repository.addReactionToMessage(roomId, messageId, userId, emoji);
    // Update local message
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final reactions = List<MessageReaction>.from(message.reactions ?? []);
      reactions.add(
        MessageReaction(
          emoji: emoji,
          userId: userId,
          createdAt: DateTime.now(),
        ),
      );
      messages[messageIndex] = message.copyWith(reactions: reactions);
    }
  }

  // Message status updates
  Future<void> markMessageAsRead(
    String roomId,
    String messageId,
    String userId,
  ) async {
    await _repository.markMessageAsRead(roomId, messageId, userId);

    // Mark private chat as read if this is a private chat
    if (roomId.startsWith('private_')) {
      await _privateChatService.markChatAsRead(roomId, userId);
    }

    // Update local message
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final readBy = List<String>.from(message.readBy)..add(userId);
      messages[messageIndex] = message.copyWith(readBy: readBy);
    }
  }

  // Retry failed message
  Future<void> retryMessage(String roomId, String messageId) async {
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex == -1) return;

    final message = messages[messageIndex];
    if (message.status != MessageStatus.failed) return;

    // Update status to sending
    messages[messageIndex] = message.copyWith(status: MessageStatus.sending);

    try {
      await _repository.sendMessage(roomId, message);
      messages[messageIndex] = message.copyWith(status: MessageStatus.sent);
      await _localMessageService.updateMessageStatus(
        messageId,
        MessageStatus.sent,
      );
    } catch (e) {
      messages[messageIndex] = message.copyWith(status: MessageStatus.failed);
      await _localMessageService.updateMessageStatus(
        messageId,
        MessageStatus.failed,
      );
    }
  }

  // Delete message
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _repository.deleteMessage(roomId, messageId);
    // Update local message
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = messages[messageIndex].copyWith(isDeleted: true);
    }
  }

  // Report message
  Future<void> reportMessage(
    String roomId,
    String messageId,
    String reporterId,
    String reason,
  ) async {
    await _repository.reportMessage(roomId, messageId, reporterId, reason);
  }

  // Get media URL (local or remote)
  String? getMediaUrl(String messageId, String? remoteUrl) {
    return _localMessageService.getLocalMediaPath(messageId) ?? remoteUrl;
  }

  // Add message to UI immediately (for local storage)
  Future<void> addMessageToUI(Message message, String roomId) async {
    AppLogger.chat(
      '📝 MessageController: addMessageToUI called - Message ID: ${message.messageId}, Text: "${message.text}", Sender: ${message.senderId}',
    );

    await _localMessageService.saveMessage(message, roomId);

    // Check if message already exists before adding
    final existingIndex = messages.indexWhere((m) => m.messageId == message.messageId);
    if (existingIndex != -1) {
      AppLogger.chat(
        '⚠️ MessageController: Message ${message.messageId} already exists at index $existingIndex, skipping duplicate add',
      );
      return;
    }

    messages.add(message);
    AppLogger.chat(
      '✅ MessageController: Added message ${message.messageId} to UI, total messages: ${messages.length}',
    );

    // Update room's last message info for sorting
    _updateRoomLastMessageInfo(message, roomId);

    // Log all current messages for debugging
    for (int i = 0; i < messages.length; i++) {
      AppLogger.chat('   Message $i: ID=${messages[i].messageId}, Text="${messages[i].text}"');
    }

    update(); // Force UI update
  }

  // Update message status
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    await _localMessageService.updateMessageStatus(messageId, status);
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = messages[messageIndex].copyWith(status: status);
      AppLogger.chat(
        '📝 MessageController: Updated message $messageId status to $status',
      );
      update(); // Force UI update
    }
  }

  // Load messages for room (initial load with pagination)
  Future<void> loadMessagesForRoom(String roomId) async {
    // Reset pagination state
    hasMoreMessages.value = true;
    oldestMessageTimestamp.value = null;

    // First load from local storage
    final localMessages = _localMessageService.getMessagesForRoom(roomId);
    if (localMessages.isNotEmpty) {
      messages.assignAll(localMessages);
      // Set oldest timestamp for pagination
      if (localMessages.isNotEmpty) {
        oldestMessageTimestamp.value = localMessages.first.createdAt;
      }
    }

    // Then listen to real-time updates (only recent messages)
    _repository.getMessagesForRoom(roomId).listen((serverMessages) {
      // Merge with current messages (not just local messages)
      final mergedMessages = _mergeMessages(messages, serverMessages);
      messages.assignAll(mergedMessages);

      // Update room's last message info if we received new messages
      if (serverMessages.isNotEmpty) {
        final latestMessage = serverMessages.last;
        _updateRoomLastMessageInfo(latestMessage, roomId);
      }

      update(); // Force UI update
    });
  }

  // Load more messages (pagination)
  Future<void> loadMoreMessages(String roomId) async {
    if (isLoadingMore.value || !hasMoreMessages.value) return;

    isLoadingMore.value = true;

    try {
      AppLogger.chat('📄 Loading more messages for room: $roomId');

      // Load older messages using pagination
      final olderMessages = await _repository.getMessagesForRoomPaginated(
        roomId,
        limit: messagesPerPage,
        startAfter: oldestMessageTimestamp.value,
      );

      if (olderMessages.isEmpty) {
        // No more messages to load
        hasMoreMessages.value = false;
        AppLogger.chat('📄 No more messages to load');
      } else {
        // Add older messages to the beginning
        messages.insertAll(0, olderMessages);

        // Update oldest timestamp for next pagination
        oldestMessageTimestamp.value = olderMessages.last.createdAt;

        AppLogger.chat('📄 Loaded ${olderMessages.length} more messages, total: ${messages.length}');
      }
    } catch (e) {
      AppLogger.chat('❌ Error loading more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  List<Message> _mergeMessages(
    List<Message> localMessages,
    List<Message> serverMessages,
  ) {
    AppLogger.chat('🔄 MessageController: Starting merge process...');
    AppLogger.chat('   Local messages: ${localMessages.length}');
    AppLogger.chat('   Server messages: ${serverMessages.length}');

    final merged = <String, Message>{};
    final contentKeyMap = <String, String>{}; // Map content key to message ID

    // Helper function to create content key for duplicate detection
    String _createContentKey(Message msg) {
      // Use sender + text + timestamp (within 5 seconds) as duplicate key
      final timestampKey = (msg.createdAt.millisecondsSinceEpoch ~/ 5000).toString();
      return '${msg.senderId}_${msg.text}_$timestampKey';
    }

    // Add server messages first (they have the most up-to-date data)
    for (final message in serverMessages) {
      final contentKey = _createContentKey(message);

      // Ensure server message has a valid status (default to sent if missing)
      final serverMessage = message.status != null ? message : message.copyWith(status: MessageStatus.sent);

      merged[message.messageId] = serverMessage;
      contentKeyMap[contentKey] = message.messageId;
      AppLogger.chat('   Added server message: ${message.messageId} - "${message.text}" (status: ${serverMessage.status}, key: $contentKey)');
    }

    // Add local messages only if they don't exist in server messages
    // Check both by ID and by content to prevent duplicates
    for (final message in localMessages) {
      final contentKey = _createContentKey(message);

      if (!merged.containsKey(message.messageId) && !contentKeyMap.containsKey(contentKey)) {
        merged[message.messageId] = message;
        contentKeyMap[contentKey] = message.messageId;
        AppLogger.chat('   Added local message: ${message.messageId} - "${message.text}" (key: $contentKey)');
      } else {
        // If server message exists (either by ID or content), check if we need to update status
        final existingId = merged.containsKey(message.messageId)
            ? message.messageId
            : contentKeyMap[contentKey];

        if (existingId != null) {
          final serverMessage = merged[existingId]!;
          AppLogger.chat('   Local message ${message.messageId} matches server message $existingId, checking status...');
          AppLogger.chat('   Local status: ${message.status}, Server status: ${serverMessage.status}');

          // Status resolution logic:
          // 1. If server is sent/failed, always use server (most authoritative)
          // 2. If server is sending but local is sent/failed, use local (local update happened)
          // 3. If both are sending, use server (to avoid conflicts)
          if (serverMessage.status == MessageStatus.sent || serverMessage.status == MessageStatus.failed) {
            // Server has final status, use it
            merged[existingId] = serverMessage;
            AppLogger.chat('   Using server status (final) for message ${existingId}');
          } else if ((message.status == MessageStatus.sent || message.status == MessageStatus.failed) &&
                     serverMessage.status == MessageStatus.sending) {
            // Local has final status but server doesn't, use local
            merged[existingId] = message;
            AppLogger.chat('   Using local status (final) for message ${existingId}');
          } else {
            // Both are sending or other cases, prefer server for consistency
            merged[existingId] = serverMessage;
            AppLogger.chat('   Using server status (default) for message ${existingId}');
          }
        }
      }
    }

    // Sort by creation time
    final sortedMessages = merged.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    AppLogger.chat('📝 MessageController: Merged ${localMessages.length} local + ${serverMessages.length} server = ${sortedMessages.length} unique messages');

    // Log final merged messages
    for (int i = 0; i < sortedMessages.length; i++) {
      AppLogger.chat('   Final message $i: ${sortedMessages[i].messageId} - "${sortedMessages[i].text}" (status: ${sortedMessages[i].status})');
    }

    return sortedMessages;
  }

  // Update room's last message info for sorting
  void _updateRoomLastMessageInfo(Message message, String roomId) {
    try {
      // Create message preview for chat list
      String messagePreview = message.text;
      if (message.type == 'image') {
        messagePreview = '📷 Image';
      } else if (message.type == 'audio') {
        messagePreview = '🎵 Voice message';
      } else if (message.type == 'poll') {
        messagePreview = '📊 Poll';
      }

      // Update room controller with last message info
      _roomController.updateLastMessageInfo(
        roomId,
        time: message.createdAt,
        preview: messagePreview,
        sender: message.senderId,
      );

      AppLogger.chat('✅ Updated room last message info for room: $roomId');
    } catch (e) {
      AppLogger.chat('❌ Error updating room last message info: $e');
    }
  }

  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Offline queue management methods
  Map<String, dynamic> getOfflineQueueStats() {
    return _offlineQueue.getQueueStats();
  }

  Future<void> retryAllFailedMessages() async {
    await _offlineQueue.retryAllFailed();
  }

  Future<void> clearOldQueuedMessages({int daysOld = 7}) async {
    await _offlineQueue.clearOldMessages(daysOld: daysOld);
  }

  // Clean up
  @override
  void onClose() {
    _offlineQueue.dispose();
    messages.clear();
    super.onClose();
  }
}

