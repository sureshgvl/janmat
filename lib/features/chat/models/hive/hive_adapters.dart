import 'package:hive/hive.dart';
import '../chat_message.dart';

part 'hive_adapters.g.dart';

// Hive adapter for MessageReaction
@HiveType(typeId: 0)
class HiveMessageReaction {
  @HiveField(0)
  final String emoji;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime createdAt;

  HiveMessageReaction({
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  // Convert from MessageReaction to HiveMessageReaction
  factory HiveMessageReaction.fromMessageReaction(MessageReaction reaction) {
    return HiveMessageReaction(
      emoji: reaction.emoji,
      userId: reaction.userId,
      createdAt: reaction.createdAt,
    );
  }

  // Convert to MessageReaction
  MessageReaction toMessageReaction() {
    return MessageReaction(emoji: emoji, userId: userId, createdAt: createdAt);
  }
}

// Hive adapter for Message
@HiveType(typeId: 1)
class HiveMessage {
  @HiveField(0)
  final String messageId;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String type;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final List<String> readBy;

  @HiveField(6)
  final String? mediaUrl;

  @HiveField(7)
  final String? mediaLocalPath;

  @HiveField(8)
  final List<HiveMessageReaction>? reactions;

  @HiveField(9)
  final int status; // MessageStatus as int

  @HiveField(10)
  final int retryCount;

  @HiveField(11)
  final bool isDeleted;

  @HiveField(12)
  final Map<String, dynamic>? metadata;

  HiveMessage({
    required this.messageId,
    required this.text,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.readBy = const [],
    this.mediaUrl,
    this.mediaLocalPath,
    this.reactions,
    this.status = 1, // MessageStatus.sent
    this.retryCount = 0,
    this.isDeleted = false,
    this.metadata,
  });

  // Convert from Message to HiveMessage
  factory HiveMessage.fromMessage(Message message) {
    return HiveMessage(
      messageId: message.messageId,
      text: message.text,
      senderId: message.senderId,
      type: message.type,
      createdAt: message.createdAt,
      readBy: message.readBy,
      mediaUrl: message.mediaUrl,
      mediaLocalPath: message.mediaLocalPath,
      reactions: message.reactions
          ?.map((r) => HiveMessageReaction.fromMessageReaction(r))
          .toList(),
      status: message.status.index,
      retryCount: message.retryCount,
      isDeleted: message.isDeleted,
      metadata: message.metadata,
    );
  }

  // Convert to Message
  Message toMessage() {
    return Message(
      messageId: messageId,
      text: text,
      senderId: senderId,
      type: type,
      createdAt: createdAt,
      readBy: readBy,
      mediaUrl: mediaUrl,
      mediaLocalPath: mediaLocalPath,
      reactions: reactions?.map((r) => r.toMessageReaction()).toList(),
      status: MessageStatus.values[status],
      retryCount: retryCount,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }
}
