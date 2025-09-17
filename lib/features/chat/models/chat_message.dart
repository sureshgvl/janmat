import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, failed }

class MessageReaction {
  final String emoji;
  final String userId;
  final DateTime createdAt;

  MessageReaction({
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final String messageId;
  final String text;
  final String senderId;
  final String type; // 'text', 'image', 'audio'
  final DateTime createdAt;
  final List<String> readBy;
  final String? mediaUrl;
  final String? mediaLocalPath;
  final List<MessageReaction>? reactions;
  final MessageStatus status;
  final int retryCount;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;

  Message({
    required this.messageId,
    required this.text,
    required this.senderId,
    required this.type,
    required this.createdAt,
    this.readBy = const [],
    this.mediaUrl,
    this.mediaLocalPath,
    this.reactions,
    this.status = MessageStatus.sent,
    this.retryCount = 0,
    this.isDeleted = false,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return Message(
      messageId: json['messageId'] ?? '',
      text: json['text'] ?? '',
      senderId: json['senderId'] ?? '',
      type: json['type'] ?? 'text',
      createdAt: createdAt,
      readBy: List<String>.from(json['readBy'] ?? []),
      mediaUrl: json['mediaUrl'],
      mediaLocalPath: json['mediaLocalPath'],
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
                .map((r) => MessageReaction.fromJson(r))
                .toList()
          : null,
      status: _parseMessageStatus(json['status']),
      retryCount: json['retryCount'] ?? 0,
      isDeleted: json['isDeleted'] ?? false,
      metadata: json['metadata'],
    );
  }

  // Helper method to parse message status from JSON
  static MessageStatus _parseMessageStatus(dynamic statusValue) {
    if (statusValue is int) {
      // Handle int index
      if (statusValue >= 0 && statusValue < MessageStatus.values.length) {
        return MessageStatus.values[statusValue];
      }
    } else if (statusValue is String) {
      // Handle string name
      switch (statusValue.toLowerCase()) {
        case 'sending':
          return MessageStatus.sending;
        case 'sent':
          return MessageStatus.sent;
        case 'failed':
          return MessageStatus.failed;
      }
    }

    // Default to sent for unknown values
    return MessageStatus.sent;
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'text': text,
      'senderId': senderId,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'mediaUrl': mediaUrl,
      'mediaLocalPath': mediaLocalPath,
      'reactions': reactions?.map((r) => r.toJson()).toList(),
      'status': status.index,
      'retryCount': retryCount,
      'isDeleted': isDeleted,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? messageId,
    String? text,
    String? senderId,
    String? type,
    DateTime? createdAt,
    List<String>? readBy,
    String? mediaUrl,
    String? mediaLocalPath,
    List<MessageReaction>? reactions,
    MessageStatus? status,
    int? retryCount,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }
}
