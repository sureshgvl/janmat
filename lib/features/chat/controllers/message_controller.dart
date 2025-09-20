import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/chat_message.dart';
import '../models/user_quota.dart';
import '../services/local_message_service.dart';
import '../services/media_service.dart';
import '../repositories/chat_repository.dart';

class MessageController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final LocalMessageService _localMessageService = LocalMessageService();
  final MediaService _mediaService = MediaService();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Voice recording state
  var isRecording = false.obs;
  String? currentRecordingPath;

  @override
  void onInit() {
    super.onInit();
    _localMessageService.initialize();
    _loadUserQuota();
  }

  // Message state
  var messages = <Message>[].obs;
  var userQuota = Rx<UserQuota?>(null);

  // Message sending
  Future<void> sendTextMessage(
    String roomId,
    String text,
    String senderId,
  ) async {
    if (text.trim().isEmpty) return;

    final message = Message(
      messageId: _generateMessageId(),
      text: text,
      senderId: senderId,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [senderId],
      status: MessageStatus.sending, // Mark as sending initially
    );

    debugPrint(
      '📤 MessageController: sendTextMessage called - Message ID: ${message.messageId}, Text: "${message.text}", Room: $roomId',
    );

    // Note: Message is added to UI by ChatController.addMessageToUI
    // Don't add here to prevent duplicates

    // Send to server asynchronously (don't block UI)
    _sendMessageToServer(message, roomId);
  }

  Future<void> _sendMessageToServer(Message message, String roomId) async {
    try {
      // Send to server with quota handling
      await _repository.sendMessage(roomId, message);

      // Update local quota if needed
      await _updateUserQuotaAfterMessage();

      // Update status to sent in UI
      updateMessageStatus(message.messageId, MessageStatus.sent);

      debugPrint('MessageController: Message sent successfully');
    } catch (e) {
      // Update status to failed in UI
      updateMessageStatus(message.messageId, MessageStatus.failed);
      debugPrint('MessageController: Failed to send message: $e');
    }
  }

  // Load user quota
  Future<void> _loadUserQuota() async {
    // For now, just set a default quota since we don't have user auth in this controller
    // The quota will be managed by the main ChatController
    debugPrint('MessageController: Quota loading deferred to ChatController');
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

        debugPrint(
          'MessageController: Updated quota - sent: ${updatedQuota.messagesSent}, remaining: ${updatedQuota.remainingMessages}',
        );
      }
    } catch (e) {
      debugPrint('MessageController: Failed to update quota: $e');
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

        debugPrint(
          'MessageController: Started voice recording: $currentRecordingPath',
        );
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      debugPrint('MessageController: Failed to start voice recording: $e');
      isRecording.value = false;
      rethrow;
    }
  }

  Future<String?> stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;

      if (path != null) {
        debugPrint('MessageController: Stopped voice recording: $path');
        return path;
      } else {
        debugPrint(
          'MessageController: Voice recording failed - no path returned',
        );
        return null;
      }
    } catch (e) {
      debugPrint('MessageController: Failed to stop voice recording: $e');
      isRecording.value = false;
      return null;
    }
  }

  Future<void> sendImageMessage(
    String roomId,
    String imagePath,
    String senderId,
  ) async {
    final message = Message(
      messageId: _generateMessageId(),
      text: 'Image',
      senderId: senderId,
      type: 'image',
      createdAt: DateTime.now(),
      readBy: [senderId],
      mediaUrl: imagePath, // Local path initially
      mediaLocalPath: imagePath,
    );

    // Save locally immediately and add to UI
    await _localMessageService.saveMessage(message, roomId);
    messages.add(message);
    debugPrint(
      '📝 MessageController: Added voice message to UI, total messages: ${messages.length}',
    );
    update(); // Force UI update
    debugPrint(
      '📝 MessageController: Added image message to UI, total messages: ${messages.length}',
    );
    update(); // Force UI update
    debugPrint(
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
    try {
      // Upload to Firebase Storage
      final fileName = path.basename(imagePath);
      final remoteUrl = await _mediaService.uploadMediaFile(
        roomId,
        imagePath,
        fileName,
        'image/jpeg',
      );

      // Update message with remote URL
      await _localMessageService.updateMessageMediaUrl(
        message.messageId,
        remoteUrl,
      );

      // Send to server
      await _repository.sendMessage(
        roomId,
        message.copyWith(mediaUrl: remoteUrl),
      );

      // Update local quota
      await _updateUserQuotaAfterMessage();

      // Update status to sent
      await _localMessageService.updateMessageStatus(
        message.messageId,
        MessageStatus.sent,
      );

      debugPrint('MessageController: Image message sent successfully');
    } catch (e) {
      // Update status to failed
      await _localMessageService.updateMessageStatus(
        message.messageId,
        MessageStatus.failed,
      );
      debugPrint('MessageController: Failed to send image message: $e');
    }
  }

  Future<void> sendVoiceMessage(
    String roomId,
    String audioPath,
    String senderId,
  ) async {
    final message = Message(
      messageId: _generateMessageId(),
      text: 'Voice message',
      senderId: senderId,
      type: 'audio',
      createdAt: DateTime.now(),
      readBy: [senderId],
      mediaUrl: audioPath, // Local path initially
      mediaLocalPath: audioPath,
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
    try {
      // Upload to Firebase Storage
      final fileName = path.basename(audioPath);
      final remoteUrl = await _mediaService.uploadMediaFile(
        roomId,
        audioPath,
        fileName,
        'audio/m4a',
      );

      // Update message with remote URL
      await _localMessageService.updateMessageMediaUrl(
        message.messageId,
        remoteUrl,
      );

      // Send to server
      await _repository.sendMessage(
        roomId,
        message.copyWith(mediaUrl: remoteUrl),
      );

      // Update local quota
      await _updateUserQuotaAfterMessage();

      // Update status to sent
      await _localMessageService.updateMessageStatus(
        message.messageId,
        MessageStatus.sent,
      );

      debugPrint('MessageController: Voice message sent successfully');
    } catch (e) {
      // Update status to failed
      await _localMessageService.updateMessageStatus(
        message.messageId,
        MessageStatus.failed,
      );
      debugPrint('MessageController: Failed to send voice message: $e');
    }
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
    debugPrint(
      '📝 MessageController: addMessageToUI called - Message ID: ${message.messageId}, Text: "${message.text}", Sender: ${message.senderId}',
    );

    await _localMessageService.saveMessage(message, roomId);

    // Check if message already exists before adding
    final existingIndex = messages.indexWhere((m) => m.messageId == message.messageId);
    if (existingIndex != -1) {
      debugPrint(
        '⚠️ MessageController: Message ${message.messageId} already exists at index $existingIndex, skipping duplicate add',
      );
      return;
    }

    messages.add(message);
    debugPrint(
      '✅ MessageController: Added message ${message.messageId} to UI, total messages: ${messages.length}',
    );

    // Log all current messages for debugging
    for (int i = 0; i < messages.length; i++) {
      debugPrint('   Message $i: ID=${messages[i].messageId}, Text="${messages[i].text}"');
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
      debugPrint(
        '📝 MessageController: Updated message $messageId status to $status',
      );
      update(); // Force UI update
    }
  }

  // Load messages for room
  Future<void> loadMessagesForRoom(String roomId) async {
    // First load from local storage
    final localMessages = _localMessageService.getMessagesForRoom(roomId);
    if (localMessages.isNotEmpty) {
      messages.assignAll(localMessages);
    }

    // Then listen to real-time updates
    _repository.getMessagesForRoom(roomId).listen((serverMessages) {
      // Merge with current messages (not just local messages)
      final mergedMessages = _mergeMessages(messages, serverMessages);
      messages.assignAll(mergedMessages);
      update(); // Force UI update
    });
  }

  List<Message> _mergeMessages(
    List<Message> localMessages,
    List<Message> serverMessages,
  ) {
    debugPrint('🔄 MessageController: Starting merge process...');
    debugPrint('   Local messages: ${localMessages.length}');
    debugPrint('   Server messages: ${serverMessages.length}');

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
      debugPrint('   Added server message: ${message.messageId} - "${message.text}" (status: ${serverMessage.status}, key: $contentKey)');
    }

    // Add local messages only if they don't exist in server messages
    // Check both by ID and by content to prevent duplicates
    for (final message in localMessages) {
      final contentKey = _createContentKey(message);

      if (!merged.containsKey(message.messageId) && !contentKeyMap.containsKey(contentKey)) {
        merged[message.messageId] = message;
        contentKeyMap[contentKey] = message.messageId;
        debugPrint('   Added local message: ${message.messageId} - "${message.text}" (key: $contentKey)');
      } else {
        // If server message exists (either by ID or content), check if we need to update status
        final existingId = merged.containsKey(message.messageId)
            ? message.messageId
            : contentKeyMap[contentKey];

        if (existingId != null) {
          final serverMessage = merged[existingId]!;
          debugPrint('   Local message ${message.messageId} matches server message $existingId, checking status...');
          debugPrint('   Local status: ${message.status}, Server status: ${serverMessage.status}');

          // Status resolution logic:
          // 1. If server is sent/failed, always use server (most authoritative)
          // 2. If server is sending but local is sent/failed, use local (local update happened)
          // 3. If both are sending, use server (to avoid conflicts)
          if (serverMessage.status == MessageStatus.sent || serverMessage.status == MessageStatus.failed) {
            // Server has final status, use it
            merged[existingId] = serverMessage;
            debugPrint('   Using server status (final) for message ${existingId}');
          } else if ((message.status == MessageStatus.sent || message.status == MessageStatus.failed) &&
                     serverMessage.status == MessageStatus.sending) {
            // Local has final status but server doesn't, use local
            merged[existingId] = message;
            debugPrint('   Using local status (final) for message ${existingId}');
          } else {
            // Both are sending or other cases, prefer server for consistency
            merged[existingId] = serverMessage;
            debugPrint('   Using server status (default) for message ${existingId}');
          }
        }
      }
    }

    // Sort by creation time
    final sortedMessages = merged.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    debugPrint('📝 MessageController: Merged ${localMessages.length} local + ${serverMessages.length} server = ${sortedMessages.length} unique messages');

    // Log final merged messages
    for (int i = 0; i < sortedMessages.length; i++) {
      debugPrint('   Final message $i: ${sortedMessages[i].messageId} - "${sortedMessages[i].text}" (status: ${sortedMessages[i].status})');
    }

    return sortedMessages;
  }

  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Clean up
  @override
  void onClose() {
    messages.clear();
    super.onClose();
  }
}
