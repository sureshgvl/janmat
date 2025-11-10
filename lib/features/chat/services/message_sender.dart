import 'dart:io';
import 'package:path/path.dart' as path;
import '../../../utils/app_logger.dart';
import '../models/chat_message.dart';
import '../models/user_quota.dart';
import '../services/media_service.dart';
import '../services/offline_message_queue.dart';
import '../services/private_chat_service.dart';
import '../services/local_message_service.dart';
import '../repositories/chat_repository.dart';

/// Handles sending different types of messages
class MessageSender {
  final ChatRepository _repository = ChatRepository();
  final LocalMessageService _localMessageService = LocalMessageService();
  final MediaService _mediaService = MediaService();
  final OfflineMessageQueue _offlineQueue = OfflineMessageQueue();
  final PrivateChatService _privateChatService = PrivateChatService();

  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Send text message
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
      status: MessageStatus.sending,
      metadata: metadata,
    );

    AppLogger.chat(
      '📤 MessageSender: sendTextMessage called - Message ID: ${message.messageId}, Text: "${message.text}", Room: $roomId',
    );

    await _sendMessageToServer(message, roomId);
  }

  /// Send image message
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

    // Save locally immediately
    await _localMessageService.saveMessage(message, roomId);

    AppLogger.chat(
      '📝 MessageSender: Added image message to local storage, total messages: saved',
    );

    // Send to server asynchronously
    await _sendImageMessageToServer(message, roomId, imagePath);
  }

  /// Send voice message
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

    // Save locally immediately
    await _localMessageService.saveMessage(message, roomId);

    AppLogger.chat(
      '📝 MessageSender: Added voice message to local storage',
    );

    // Send to server asynchronously
    await _sendVoiceMessageToServer(message, roomId, audioPath);
  }

  /// Send poll message
  Future<void> sendPollMessage(String roomId, Message message) async {
    // Check if this is a ward room and add broadcast control metadata
    final isWardRoom = roomId.startsWith('ward_');
    final metadata = isWardRoom ? {'broadcast': false} : null;
    final pollMessage = message.copyWith(metadata: metadata);

    AppLogger.chat('📊 MessageSender: Sending poll message: ${message.messageId} to room: $roomId');

    await _sendMessageToServer(pollMessage, roomId);
  }

  /// Send message to server via offline queue
  Future<void> _sendMessageToServer(Message message, String roomId) async {
    await _offlineQueue.queueMessage(
      message,
      roomId,
      (msg, rId) async {
        await _repository.sendMessage(rId, msg);

        // Update private chat metadata if this is a private chat
        if (rId.startsWith('private_')) {
          await _updatePrivateChatMetadata(msg, rId);
        }
      },
    );

    AppLogger.chat('MessageSender: Message queued for sending: ${message.messageId}');
  }

  /// Send image message to server with upload
  Future<void> _sendImageMessageToServer(
    Message message,
    String roomId,
    String imagePath,
  ) async {
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

        // Update status to sent
        await _localMessageService.updateMessageStatus(
          msg.messageId,
          MessageStatus.sent,
        );
      },
    );

    AppLogger.chat('MessageSender: Image message queued for sending: ${message.messageId}');
  }

  /// Send voice message to server with upload
  Future<void> _sendVoiceMessageToServer(
    Message message,
    String roomId,
    String audioPath,
  ) async {
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

        // Update status to sent
        await _localMessageService.updateMessageStatus(
          msg.messageId,
          MessageStatus.sent,
        );
      },
    );

    AppLogger.chat('MessageSender: Voice message queued for sending: ${message.messageId}');
  }

  /// Update private chat metadata when messages are sent
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

      AppLogger.chat('✅ MessageSender: Updated private chat metadata for room: $roomId');
    } catch (e) {
      AppLogger.chat('❌ MessageSender: Error updating private chat metadata: $e');
    }
  }
}
