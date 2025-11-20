import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String roomId;
  final DateTime createdAt;
  final String createdBy;
  final String type;
  final String title;
  final String description;
  final List<String>? members;
  // Location data for ward-specific rooms
  final String? stateId;
  final String? districtId;
  final String? bodyId;
  final String? wardId;
  final String? area;

  ChatRoom({
    required this.roomId,
    required this.createdAt,
    required this.createdBy,
    required this.type,
    required this.title,
    required this.description,
    this.members,
    this.stateId,
    this.districtId,
    this.bodyId,
    this.wardId,
    this.area,
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
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      members: json['members'] != null
          ? List<String>.from(json['members'])
          : null,
      stateId: json['stateId'],
      districtId: json['districtId'],
      bodyId: json['bodyId'],
      wardId: json['wardId'],
      area: json['area'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'type': type,
      'title': title,
      'description': description,
      'members': members,
      'stateId': stateId,
      'districtId': districtId,
      'bodyId': bodyId,
      'wardId': wardId,
      'area': area,
    };
  }
}

class ChatRoomDisplayInfo {
  final ChatRoom room;
  final int unreadCount;
  final DateTime? lastMessageTime;
  final String? lastMessagePreview;
  final String? lastMessageSender;
  final String? displayTitle;
  final int activeUsersCount;

  ChatRoomDisplayInfo({
    required this.room,
    required this.unreadCount,
    this.lastMessageTime,
    this.lastMessagePreview,
    this.lastMessageSender,
    this.displayTitle,
    this.activeUsersCount = 0,
  });

  bool get hasUnreadMessages => unreadCount > 0;
}
