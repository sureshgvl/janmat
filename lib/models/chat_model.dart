import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final DateTime createdAt;
  final String createdBy;
  final String type; // 'public' or 'private'
  final List<String>? members; // for private rooms
  final String? title;
  final String? description;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  ChatRoom({
    required this.roomId,
    required this.createdAt,
    required this.createdBy,
    required this.type,
    this.members,
    this.title,
    this.description,
    this.isActive = true,
    this.metadata,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return ChatRoom(
      roomId: json['roomId'] ?? '',
      createdAt: createdAt,
      createdBy: json['createdBy'] ?? '',
      type: json['type'] ?? 'public',
      members: json['members'] != null
          ? List<String>.from(json['members'])
          : null,
      title: json['title'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'type': type,
      'members': members,
      'title': title,
      'description': description,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  ChatRoom copyWith({
    String? roomId,
    DateTime? createdAt,
    String? createdBy,
    String? type,
    List<String>? members,
    String? title,
    String? description,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      roomId: roomId ?? this.roomId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      type: type ?? this.type,
      members: members ?? this.members,
      title: title ?? this.title,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }
}

class Message {
  final String messageId;
  final String text;
  final String senderId;
  final String type; // 'text', 'image', 'audio', 'video', 'emoji'
  final DateTime createdAt;
  final List<String> readBy;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool? isDeleted;
  final List<MessageReaction>? reactions;

  Message({
    required this.messageId,
    required this.text,
    required this.senderId,
    required this.type,
    required this.createdAt,
    required this.readBy,
    this.mediaUrl,
    this.metadata,
    this.isDeleted = false,
    this.reactions,
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
      readBy: json['readBy'] != null
          ? List<String>.from(json['readBy'])
          : [],
      mediaUrl: json['mediaUrl'],
      metadata: json['metadata'],
      isDeleted: json['isDeleted'] ?? false,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'text': text,
      'senderId': senderId,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'readBy': readBy,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
      'isDeleted': isDeleted,
      'reactions': reactions?.map((r) => r.toJson()).toList(),
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
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
    );
  }
}

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
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return MessageReaction(
      emoji: json['emoji'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: createdAt,
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

class Poll {
  final String pollId;
  final String question;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, int> votes; // option -> count
  final Map<String, String> userVotes; // userId -> option

  Poll({
    required this.pollId,
    required this.question,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    required this.votes,
    required this.userVotes,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    DateTime? expiresAt;
    if (json['expiresAt'] is Timestamp) {
      expiresAt = (json['expiresAt'] as Timestamp).toDate();
    } else if (json['expiresAt'] is String) {
      expiresAt = DateTime.parse(json['expiresAt']);
    }

    return Poll(
      pollId: json['pollId'] ?? '',
      question: json['question'] ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
      createdBy: json['createdBy'] ?? '',
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: json['isActive'] ?? true,
      votes: json['votes'] != null
          ? Map<String, int>.from(json['votes'])
          : {},
      userVotes: json['userVotes'] != null
          ? Map<String, String>.from(json['userVotes'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      'question': question,
      'options': options,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'votes': votes,
      'userVotes': userVotes,
    };
  }

  Poll copyWith({
    String? pollId,
    String? question,
    List<String>? options,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
  }) {
    return Poll(
      pollId: pollId ?? this.pollId,
      question: question ?? this.question,
      options: options ?? this.options,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
    );
  }

  // Helper methods for expiration
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get canVote {
    return isActive && !isExpired;
  }

  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  String get expirationStatus {
    if (expiresAt == null) return 'No expiration';
    if (isExpired) return 'Expired';
    final remaining = timeRemaining!;
    if (remaining.inDays > 0) {
      return 'Expires in ${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
    } else if (remaining.inHours > 0) {
      return 'Expires in ${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'}';
    } else if (remaining.inMinutes > 0) {
      return 'Expires in ${remaining.inMinutes} minute${remaining.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Expires soon';
    }
  }

  // Create poll with default expiration (24 hours from now)
  factory Poll.create({
    required String pollId,
    required String question,
    required List<String> options,
    required String createdBy,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return Poll(
      pollId: pollId,
      question: question,
      options: options,
      createdBy: createdBy,
      createdAt: now,
      expiresAt: expiresAt ?? now.add(const Duration(hours: 24)), // Default 24 hours
      isActive: true,
      votes: {},
      userVotes: {},
    );
  }
}

class UserQuota {
  final String userId;
  final int dailyLimit;
  final int messagesSent;
  final int extraQuota;
  final DateTime lastReset;
  final DateTime createdAt;

  UserQuota({
    required this.userId,
    this.dailyLimit = 20,
    this.messagesSent = 0,
    this.extraQuota = 0,
    required this.lastReset,
    required this.createdAt,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    DateTime lastReset;
    if (json['lastReset'] is Timestamp) {
      lastReset = (json['lastReset'] as Timestamp).toDate();
    } else if (json['lastReset'] is String) {
      lastReset = DateTime.parse(json['lastReset']);
    } else {
      lastReset = DateTime.now();
    }

    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return UserQuota(
      userId: json['userId'] ?? '',
      dailyLimit: json['dailyLimit'] ?? 20,
      messagesSent: json['messagesSent'] ?? 0,
      extraQuota: json['extraQuota'] ?? 0,
      lastReset: lastReset,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dailyLimit': dailyLimit,
      'messagesSent': messagesSent,
      'extraQuota': extraQuota,
      'lastReset': lastReset.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get canSendMessage {
    return messagesSent < (dailyLimit + extraQuota);
  }

  int get remainingMessages {
    return (dailyLimit + extraQuota) - messagesSent;
  }

  UserQuota copyWith({
    String? userId,
    int? dailyLimit,
    int? messagesSent,
    int? extraQuota,
    DateTime? lastReset,
    DateTime? createdAt,
  }) {
    return UserQuota(
      userId: userId ?? this.userId,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      messagesSent: messagesSent ?? this.messagesSent,
      extraQuota: extraQuota ?? this.extraQuota,
      lastReset: lastReset ?? this.lastReset,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}