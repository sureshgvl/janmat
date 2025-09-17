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
  Future<void> sendTextMessage(String roomId, String text, String senderId) async {
    if (text.trim().isEmpty) return;

    final message = Message(
      messageId: _generateMessageId(),
      text: text,
      senderId: senderId,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [senderId],
    );

    // Save locally immediately and add to UI
    await _localMessageService.saveMessage(message, roomId);
    messages.add(message);

    // Send to server asynchronously (don't block UI)
    _sendMessageToServer(message, roomId);
  }

  Future<void> _sendMessageToServer(Message message, String roomId) async {
    try {
      // Send to server with quota handling
      await _repository.sendMessage(roomId, message);

      // Update local quota if needed
      await _updateUserQuotaAfterMessage();

      // Update status to sent
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.sent);
    } catch (e) {
      // Update status to failed
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.failed);
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

        debugPrint('MessageController: Updated quota - sent: ${updatedQuota.messagesSent}, remaining: ${updatedQuota.remainingMessages}');
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
        final recordingsDir = Directory(path.join(appDir.path, 'voice_recordings'));

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

        debugPrint('MessageController: Started voice recording: $currentRecordingPath');
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      debugPrint('MessageController: Failed to start voice recording: $e');
      isRecording.value = false;
      throw e;
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
        debugPrint('MessageController: Voice recording failed - no path returned');
        return null;
      }
    } catch (e) {
      debugPrint('MessageController: Failed to stop voice recording: $e');
      isRecording.value = false;
      return null;
    }
  }


  Future<void> sendImageMessage(String roomId, String imagePath, String senderId) async {
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
    debugPrint('📝 MessageController: Added voice message to UI, total messages: ${messages.length}');
    update(); // Force UI update
    debugPrint('📝 MessageController: Added image message to UI, total messages: ${messages.length}');
    update(); // Force UI update
    debugPrint('📝 MessageController: Added message to UI, total messages: ${messages.length}');
    update(); // Force UI update

    // Send to server asynchronously (don't block UI)
    _sendImageMessageToServer(message, roomId, imagePath);
  }

  Future<void> _sendImageMessageToServer(Message message, String roomId, String imagePath) async {
    try {
      // Upload to Firebase Storage
      final fileName = path.basename(imagePath);
      final remoteUrl = await _mediaService.uploadMediaFile(roomId, imagePath, fileName, 'image/jpeg');

      // Update message with remote URL
      await _localMessageService.updateMessageMediaUrl(message.messageId, remoteUrl);

      // Send to server
      await _repository.sendMessage(roomId, message.copyWith(mediaUrl: remoteUrl));

      // Update local quota
      await _updateUserQuotaAfterMessage();

      // Update status to sent
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.sent);

      debugPrint('MessageController: Image message sent successfully');
    } catch (e) {
      // Update status to failed
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.failed);
      debugPrint('MessageController: Failed to send image message: $e');
    }
  }

  Future<void> sendVoiceMessage(String roomId, String audioPath, String senderId) async {
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

  Future<void> _sendVoiceMessageToServer(Message message, String roomId, String audioPath) async {
    try {
      // Upload to Firebase Storage
      final fileName = path.basename(audioPath);
      final remoteUrl = await _mediaService.uploadMediaFile(roomId, audioPath, fileName, 'audio/m4a');

      // Update message with remote URL
      await _localMessageService.updateMessageMediaUrl(message.messageId, remoteUrl);

      // Send to server
      await _repository.sendMessage(roomId, message.copyWith(mediaUrl: remoteUrl));

      // Update local quota
      await _updateUserQuotaAfterMessage();

      // Update status to sent
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.sent);

      debugPrint('MessageController: Voice message sent successfully');
    } catch (e) {
      // Update status to failed
      await _localMessageService.updateMessageStatus(message.messageId, MessageStatus.failed);
      debugPrint('MessageController: Failed to send voice message: $e');
    }
  }

  // Message reactions
  Future<void> addReaction(String roomId, String messageId, String userId, String emoji) async {
    await _repository.addReactionToMessage(roomId, messageId, userId, emoji);
    // Update local message
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final reactions = List<MessageReaction>.from(message.reactions ?? []);
      reactions.add(MessageReaction(
        emoji: emoji,
        userId: userId,
        createdAt: DateTime.now(),
      ));
      messages[messageIndex] = message.copyWith(reactions: reactions);
    }
  }

  // Message status updates
  Future<void> markMessageAsRead(String roomId, String messageId, String userId) async {
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
      await _localMessageService.updateMessageStatus(messageId, MessageStatus.sent);
    } catch (e) {
      messages[messageIndex] = message.copyWith(status: MessageStatus.failed);
      await _localMessageService.updateMessageStatus(messageId, MessageStatus.failed);
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
  Future<void> reportMessage(String roomId, String messageId, String reporterId, String reason) async {
    await _repository.reportMessage(roomId, messageId, reporterId, reason);
  }

  // Get media URL (local or remote)
  String? getMediaUrl(String messageId, String? remoteUrl) {
    return _localMessageService.getLocalMediaPath(messageId) ?? remoteUrl;
  }

  // Add message to UI immediately (for local storage)
  Future<void> addMessageToUI(Message message, String roomId) async {
    await _localMessageService.saveMessage(message, roomId);
    messages.add(message);
    debugPrint('📝 MessageController: Added message to UI, total messages: ${messages.length}');
    update(); // Force UI update
  }

  // Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    await _localMessageService.updateMessageStatus(messageId, status);
    final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
    if (messageIndex != -1) {
      messages[messageIndex] = messages[messageIndex].copyWith(status: status);
      debugPrint('📝 MessageController: Updated message $messageId status to $status');
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
      // Merge with local messages
      final mergedMessages = _mergeMessages(localMessages, serverMessages);
      messages.assignAll(mergedMessages);
    });
  }

  List<Message> _mergeMessages(List<Message> localMessages, List<Message> serverMessages) {
    final merged = <String, Message>{};

    // Add local messages
    for (final message in localMessages) {
      merged[message.messageId] = message;
    }

    // Override with server messages
    for (final message in serverMessages) {
      merged[message.messageId] = message;
    }

    return merged.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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