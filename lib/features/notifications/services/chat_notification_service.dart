import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/models/chat_message.dart';
import '../../chat/models/chat_room.dart';
import '../../chat/repositories/chat_repository.dart';
import '../models/notification_type.dart';
import '../../../utils/app_logger.dart';
import 'notification_manager.dart';

class ChatNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatRepository _chatRepository = ChatRepository();
  final NotificationManager _notificationManager = NotificationManager();

  // Stream subscriptions for real-time message monitoring
  final Map<String, StreamSubscription> _messageSubscriptions = {};
  final Map<String, StreamSubscription> _roomSubscriptions = {};

  // Track last processed message timestamps to avoid duplicates
  final Map<String, DateTime> _lastProcessedTimestamps = {};

  // User information
  String? _currentUserId;
  String? _currentUserRole;
  Map<String, dynamic>? _userLocation;

  /// Initialize the chat notification service
  Future<void> initialize({
    required String userId,
    required String userRole,
    Map<String, dynamic>? userLocation,
  }) async {
    _currentUserId = userId;
    _currentUserRole = userRole;
    _userLocation = userLocation;

    AppLogger.common('🔔 Initializing Chat Notification Service for user: $userId');

    // Start monitoring accessible chat rooms
    await _startMonitoringChatRooms();

    AppLogger.common('✅ Chat Notification Service initialized');
  }

  /// Start monitoring chat rooms for new messages
  Future<void> _startMonitoringChatRooms() async {
    if (_currentUserId == null || _currentUserRole == null) return;

    try {
      // Get all accessible chat rooms for this user
      final rooms = await _chatRepository.getChatRoomsForUser(
        _currentUserId!,
        _currentUserRole!,
        stateId: _userLocation?['stateId'],
        districtId: _userLocation?['districtId'],
        bodyId: _userLocation?['bodyId'],
        wardId: _userLocation?['wardId'],
        area: _userLocation?['area'],
      );

      AppLogger.common('👀 Monitoring ${rooms.length} chat rooms for notifications');

      // Start monitoring each room for new messages
      for (final room in rooms) {
        await _startMonitoringRoom(room);
      }

      // Also monitor for new rooms being created
      _startMonitoringNewRooms();

    } catch (e) {
      AppLogger.common('❌ Error starting chat room monitoring: $e');
    }
  }

  /// Start monitoring a specific chat room for new messages
  Future<void> _startMonitoringRoom(ChatRoom room) async {
    final roomId = room.roomId;

    // Cancel existing subscription if any
    _messageSubscriptions[roomId]?.cancel();

    // Get the last processed timestamp for this room
    final lastTimestamp = _lastProcessedTimestamps[roomId] ?? DateTime.now().subtract(const Duration(hours: 1));

    // Listen to new messages in this room
    final subscription = _chatRepository.getMessagesForRoom(roomId).listen(
      (messages) {
        _processNewMessages(room, messages);
      },
      onError: (error) {
        AppLogger.common('❌ Error monitoring messages in room $roomId: $error');
      },
    );

    _messageSubscriptions[roomId] = subscription;
    AppLogger.common('👂 Started monitoring messages in room: $roomId');
  }

  /// Monitor for newly created rooms
  void _startMonitoringNewRooms() {
    // Cancel existing subscription
    _roomSubscriptions['new_rooms']?.cancel();

    final subscription = _firestore
        .collection('chats')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final roomData = change.doc.data();
            if (roomData != null) {
              roomData['roomId'] = change.doc.id;
              final newRoom = ChatRoom.fromJson(roomData);

              // Check if this user should have access to this room
              final hasAccess = await _userHasAccessToRoom(newRoom);
              if (hasAccess) {
                AppLogger.common('🆕 New room detected, starting monitoring: ${newRoom.roomId}');
                await _startMonitoringRoom(newRoom);
              }
            }
          }
        }
      },
      onError: (error) {
        AppLogger.common('❌ Error monitoring new rooms: $error');
      },
    );

    _roomSubscriptions['new_rooms'] = subscription;
  }

  /// Process new messages and trigger notifications
  void _processNewMessages(ChatRoom room, List<Message> messages) {
    if (_currentUserId == null) return;

    final roomId = room.roomId;
    final lastTimestamp = _lastProcessedTimestamps[roomId];

    // Filter messages that are newer than our last processed timestamp
    final newMessages = messages.where((message) {
      // Skip messages from current user
      if (message.senderId == _currentUserId) return false;

      // Skip messages that are already read by current user
      if (message.readBy.contains(_currentUserId)) return false;

      // Skip messages older than our last processed timestamp
      if (lastTimestamp != null && message.createdAt.isBefore(lastTimestamp)) return false;

      return true;
    }).toList();

    if (newMessages.isEmpty) return;

    // Update last processed timestamp
    final latestMessage = newMessages.reduce((a, b) =>
        a.createdAt.isAfter(b.createdAt) ? a : b);
    _lastProcessedTimestamps[roomId] = latestMessage.createdAt;

    // Process each new message
    for (final message in newMessages) {
      _processMessageNotification(room, message);
    }
  }

  /// Process a single message and create appropriate notifications
  Future<void> _processMessageNotification(ChatRoom room, Message message) async {
    if (_currentUserId == null) return;

    try {
      // Check if user has chat notifications enabled
      final preferences = await _notificationManager.getUserPreferences();
      if (!preferences.categoryPreferences['Chat']!) {
        return; // User disabled chat notifications
      }

      // Check for mentions first (higher priority)
      final hasMention = _messageContainsMention(message, _currentUserId!);
      if (hasMention) {
        await _createMentionNotification(room, message);
        return; // Don't create regular message notification for mentions
      }

      // Check if this is a group chat or private chat
      final isGroupChat = _isGroupChat(room);
      if (isGroupChat) {
        await _createGroupMessageNotification(room, message);
      } else {
        await _createPrivateMessageNotification(room, message);
      }

    } catch (e) {
      AppLogger.commonError('❌ Error processing message notification', error: e);
    }
  }

  /// Create notification for @mentions
  Future<void> _createMentionNotification(ChatRoom room, Message message) async {
    if (_currentUserId == null) return;

    await _notificationManager.createNotification(
      type: NotificationType.mention,
      title: 'You were mentioned',
      body: '${_getSenderName(message.senderId)} mentioned you in ${room.title}',
      data: {
        'roomId': room.roomId,
        'roomTitle': room.title,
        'messageId': message.messageId,
        'senderId': message.senderId,
        'messageText': message.text,
        'mentionType': 'direct',
      },
    );
    AppLogger.common('🔔 Mention notification created for user $_currentUserId in room ${room.roomId}');
  }

  /// Create notification for group chat messages
  Future<void> _createGroupMessageNotification(ChatRoom room, Message message) async {
    if (_currentUserId == null) return;

    await _notificationManager.createNotification(
      type: NotificationType.newMessage,
      title: room.title,
      body: '${_getSenderName(message.senderId)}: ${_getMessagePreview(message)}',
      data: {
        'roomId': room.roomId,
        'roomTitle': room.title,
        'messageId': message.messageId,
        'senderId': message.senderId,
        'messageText': message.text,
        'roomType': 'group',
      },
    );
    AppLogger.common('🔔 Group message notification created for user $_currentUserId in room ${room.roomId}');
  }

  /// Create notification for private chat messages
  Future<void> _createPrivateMessageNotification(ChatRoom room, Message message) async {
    if (_currentUserId == null) return;

    await _notificationManager.createNotification(
      type: NotificationType.newMessage,
      title: _getSenderName(message.senderId),
      body: _getMessagePreview(message),
      data: {
        'roomId': room.roomId,
        'roomTitle': room.title,
        'messageId': message.messageId,
        'senderId': message.senderId,
        'messageText': message.text,
        'roomType': 'private',
      },
    );
    AppLogger.common('🔔 Private message notification created for user $_currentUserId from ${message.senderId}');
  }

  /// Check if a message contains a mention of the current user
  bool _messageContainsMention(Message message, String userId) {
    // Simple mention detection - look for @ followed by user identifier
    // In a real app, you'd want more sophisticated mention detection
    final mentionPatterns = [
      '@$userId',
      '@${userId.substring(0, min(8, userId.length))}',
      // Add more patterns as needed
    ];

    final messageText = message.text.toLowerCase();
    return mentionPatterns.any((pattern) => messageText.contains(pattern.toLowerCase()));
  }

  /// Check if a chat room is a group chat
  bool _isGroupChat(ChatRoom room) {
    // Consider it a group chat if it has multiple members or is public
    return room.type == 'public' ||
           (room.members != null && room.members!.length > 2);
  }

  /// Get a preview of the message text for notifications
  String _getMessagePreview(Message message) {
    if (message.type == 'image') return '📷 Image';
    if (message.type == 'audio') return '🎵 Voice message';
    if (message.type == 'video') return '🎥 Video';

    // Truncate long messages
    final text = message.text;
    return text.length > 50 ? '${text.substring(0, 47)}...' : text;
  }

  /// Get sender name (would typically fetch from user data)
  String _getSenderName(String senderId) {
    // In a real implementation, you'd fetch the user name from a user service
    // For now, return a generic name
    return 'User'; // Replace with actual user name lookup
  }

  /// Check if current user has access to a room
  Future<bool> _userHasAccessToRoom(ChatRoom room) async {
    if (_currentUserId == null || _currentUserRole == null) return false;

    try {
      // Get rooms user has access to and check if this room is included
      final userRooms = await _chatRepository.getChatRoomsForUser(
        _currentUserId!,
        _currentUserRole!,
        stateId: _userLocation?['stateId'],
        districtId: _userLocation?['districtId'],
        bodyId: _userLocation?['bodyId'],
        wardId: _userLocation?['wardId'],
        area: _userLocation?['area'],
      );

      return userRooms.any((userRoom) => userRoom.roomId == room.roomId);
    } catch (e) {
      AppLogger.commonError('❌ Error checking room access', error: e);
      return false;
    }
  }

  /// Update user information (call when user data changes)
  Future<void> updateUserInfo({
    String? userId,
    String? userRole,
    Map<String, dynamic>? userLocation,
  }) async {
    final userChanged = userId != null && userId != _currentUserId;
    final roleChanged = userRole != null && userRole != _currentUserRole;
    final locationChanged = userLocation != null && userLocation != _userLocation;

    if (userChanged || roleChanged || locationChanged) {
      AppLogger.common('🔄 Updating chat notification service user info');

      // Stop all current monitoring
      await _stopMonitoring();

      // Update user info
      _currentUserId = userId ?? _currentUserId;
      _currentUserRole = userRole ?? _currentUserRole;
      _userLocation = userLocation ?? _userLocation;

      // Restart monitoring with new info
      if (_currentUserId != null && _currentUserRole != null) {
        await _startMonitoringChatRooms();
      }
    }
  }

  /// Stop all monitoring and clean up resources
  Future<void> _stopMonitoring() async {
    AppLogger.common('🛑 Stopping chat notification monitoring');

    // Cancel all message subscriptions
    for (final subscription in _messageSubscriptions.values) {
      await subscription.cancel();
    }
    _messageSubscriptions.clear();

    // Cancel room subscriptions
    for (final subscription in _roomSubscriptions.values) {
      await subscription.cancel();
    }
    _roomSubscriptions.clear();

    // Clear timestamps
    _lastProcessedTimestamps.clear();
  }

  /// Dispose of the service
  Future<void> dispose() async {
    AppLogger.common('🗑️ Disposing Chat Notification Service');
    await _stopMonitoring();
  }

  /// Get current monitoring status for debugging
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'userId': _currentUserId,
      'userRole': _currentUserRole,
      'monitoredRooms': _messageSubscriptions.keys.toList(),
      'activeSubscriptions': _messageSubscriptions.length,
      'lastProcessedTimestamps': _lastProcessedTimestamps.length,
    };
  }
}

/// Utility function for min operation
int min(int a, int b) => a < b ? a : b;
