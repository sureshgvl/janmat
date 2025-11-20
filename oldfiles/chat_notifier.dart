import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'message_controller.dart';
import 'room_controller.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/poll.dart';
import '../models/user_quota.dart';
import '../repositories/chat_repository.dart';
import '../services/private_chat_service.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../services/admob_service.dart';
import '../../notifications/services/poll_notification_service.dart';
import '../../../utils/app_logger.dart';

// Chat state class to hold all chat-related state
class ChatState {
  final List<ChatRoom> chatRooms;
  final List<ChatRoomDisplayInfo> chatRoomDisplayInfos;
  final ChatRoom? currentChatRoom;
  final List<Message> messages;
  final UserQuota? userQuota;
  final bool isLoading;
  final bool isSendingMessage;
  final List<TypingStatus> typingStatuses;
  final UserModel? currentUser;
  final String? errorMessage;

  const ChatState({
    this.chatRooms = const [],
    this.chatRoomDisplayInfos = const [],
    this.currentChatRoom,
    this.messages = const [],
    this.userQuota,
    this.isLoading = false,
    this.isSendingMessage = false,
    this.typingStatuses = const [],
    this.currentUser,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatRoom>? chatRooms,
    List<ChatRoomDisplayInfo>? chatRoomDisplayInfos,
    ChatRoom? currentChatRoom,
    List<Message>? messages,
    UserQuota? userQuota,
    bool? isLoading,
    bool? isSendingMessage,
    List<TypingStatus>? typingStatuses,
    UserModel? currentUser,
    String? errorMessage,
  }) {
    return ChatState(
      chatRooms: chatRooms ?? this.chatRooms,
      chatRoomDisplayInfos: chatRoomDisplayInfos ?? this.chatRoomDisplayInfos,
      currentChatRoom: currentChatRoom ?? this.currentChatRoom,
      messages: messages ?? this.messages,
      userQuota: userQuota ?? this.userQuota,
      isLoading: isLoading ?? this.isLoading,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      typingStatuses: typingStatuses ?? this.typingStatuses,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Computed properties
  bool get canSendMessage {
    final user = currentUser;
    if (user == null) return false;
    if (user.premium) return true;
    return userQuota != null && userQuota!.canSendMessage;
  }

  bool get shouldShowWatchAdsButton {
    final user = currentUser;
    if (user == null || user.premium) return false;
    return !canSendMessage;
  }

  int get remainingMessages {
    final user = currentUser;
    if (user == null) return 0;
    if (user.premium) return 999;
    return userQuota?.remainingMessages ?? 0;
  }

  bool get isRecording => false; // Will be managed by MessageController
}

// ChatNotifier that manages all chat state and actions
class ChatNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final ChatRepository _repository = ChatRepository();
  final PrivateChatService _privateChatService = PrivateChatService();
  late final RoomController _roomController;
  late final MessageController _messageController;

  StreamSubscription<List<TypingStatus>>? _typingSubscription;

  // Current state
  ChatState _state = const ChatState();

  ChatState get state => _state;
  set state(ChatState newState) => _state = newState;

  ChatNotifier() {
    _roomController = RoomController();
    _messageController = MessageController(roomController: _roomController);

    // Clean up expired repository cache on app start
    clearExpiredRepositoryCache();

    AppLogger.ui('ChatNotifier initialized', tag: 'CHAT');
  }

  // Clean up expired repository cache on app start
  void clearExpiredRepositoryCache() {
    AppLogger.database('Repository cache cleanup requested', tag: 'CHAT');
  }

  // Load complete user data from Firestore
  Future<void> _loadCompleteUserData() async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final user = UserModel.fromJson(data);
          state = state.copyWith(currentUser: user);
          AppLogger.database(
            'Loaded complete user data: ${user.name} (${user.role})',
            tag: 'CHAT',
          );
        }
      }
    } catch (e) {
      AppLogger.database('Error loading complete user data: $e', tag: 'CHAT');
    }
  }

  // Initialize chat if needed
  Future<void> initializeChatIfNeeded() async {
    await _loadCompleteUserData();

    final user = state.currentUser;
    if (user != null) {
      final regularArea = user.electionAreas.isNotEmpty
          ? user.electionAreas.firstWhere(
              (area) => area.type == ElectionType.regular,
              orElse: () => user.electionAreas.first,
            )
          : null;

      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        stateId: user.location?.stateId,
        districtId: user.location?.districtId,
        bodyId: regularArea?.bodyId,
        wardId: regularArea?.wardId,
        area: regularArea?.area,
      );

      // Load user quota
      try {
        final quota = await _repository.getUserQuota(user.uid);
        if (quota != null) {
          state = state.copyWith(userQuota: quota);
          AppLogger.database(
            'Loaded user quota: ${quota.remainingMessages} messages remaining',
            tag: 'CHAT',
          );
        } else {
          final defaultQuota = UserQuota(
            userId: user.uid,
            lastReset: DateTime.now(),
            createdAt: DateTime.now(),
          );
          state = state.copyWith(userQuota: defaultQuota);
          await _repository.updateUserQuota(defaultQuota);
          AppLogger.database('Created default quota', tag: 'CHAT');
        }
      } catch (e) {
        AppLogger.database('Failed to load quota: $e', tag: 'CHAT');
      }
    } else {
      AppLogger.database('No user data available for chat initialization', tag: 'CHAT');
    }
  }

  // Fetch chat rooms
  Future<void> fetchChatRooms() async {
    final user = state.currentUser;
    if (user != null) {
      final regularArea = user.electionAreas.isNotEmpty
          ? user.electionAreas.firstWhere(
              (area) => area.type == ElectionType.regular,
              orElse: () => user.electionAreas.first,
            )
          : null;

      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        stateId: user.location?.stateId,
        districtId: user.location?.districtId,
        bodyId: regularArea?.bodyId,
        wardId: regularArea?.wardId,
        area: regularArea?.area,
      );
    } else {
      AppLogger.database('No user data available for fetching chat rooms', tag: 'CHAT');
    }
  }

  // Select chat room
  void selectChatRoom(ChatRoom chatRoom) {
    _roomController.selectChatRoom(chatRoom);
    _messageController.loadMessagesForRoom(chatRoom.roomId);
    _setupTypingSubscription(chatRoom.roomId);
    state = state.copyWith(currentChatRoom: chatRoom);
  }

  // Set up typing subscription
  void _setupTypingSubscription(String roomId) {
    _typingSubscription?.cancel();
    _typingSubscription = _repository.getTypingStatusForRoom(roomId).listen(
      (statuses) {
        state = state.copyWith(typingStatuses: statuses);
      },
      onError: (error) {
        AppLogger.database('Error listening to typing status: $error', tag: 'CHAT');
      },
    );
  }

  // Update typing status
  void updateTypingStatus(bool isTyping) {
    final user = state.currentUser;
    final room = state.currentChatRoom;

    if (user != null && room != null) {
      _repository.updateTypingStatus(
        room.roomId,
        user.uid,
        user.name,
        isTyping,
      );
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String roomId, String messageId, String userId) async {
    try {
      await _repository.markMessageAsRead(roomId, messageId, userId);
    } catch (e) {
      AppLogger.database('Error marking message as read: $e', tag: 'CHAT');
    }
  }

  // Send message
  Future<void> sendMessage(String roomId, Message message) async {
    final userId = state.currentUser?.uid ?? message.senderId;
    if (message.type == 'text') {
      await _messageController.sendTextMessage(roomId, message.text, userId, existingMessage: message);
    } else if (message.type == 'image') {
      await _messageController.sendImageMessage(
        roomId,
        message.mediaUrl!,
        userId,
      );
    } else if (message.type == 'audio') {
      await _messageController.sendVoiceMessage(
        roomId,
        message.mediaUrl!,
        userId,
      );
    } else if (message.type == 'poll') {
      await _messageController.sendPollMessage(roomId, message);
    }
  }

  // Send recorded voice message
  Future<void> sendRecordedVoiceMessage(String filePath) async {
    if (state.currentChatRoom != null && state.currentUser != null) {
      await _messageController.sendVoiceMessage(
        state.currentChatRoom!.roomId,
        filePath,
        state.currentUser!.uid,
      );
    }
  }

  // Voice recording methods
  Future<String?> stopVoiceRecordingOnly() async {
    return await _messageController.stopVoiceRecording();
  }

  Future<void> startVoiceRecording() async {
    await _messageController.startVoiceRecording();
  }

  // Send text message with quota/XP handling
  Future<void> sendTextMessage(String text) async {
    final user = state.currentUser;
    if (user == null || state.currentChatRoom == null) {
      AppLogger.ui('Cannot send message: user or chat room is null', tag: 'CHAT');
      return;
    }

    AppLogger.ui(
      'sendTextMessage called - Text: "$text", Room: ${state.currentChatRoom!.roomId}',
      tag: 'CHAT',
    );

    if (!state.canSendMessage) {
      // Handle quota exceeded - this would need to be handled by the UI
      AppLogger.ui('Cannot send message: quota exceeded', tag: 'CHAT');
      return;
    }

    state = state.copyWith(isSendingMessage: true);

    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: user.uid,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [user.uid],
    );

    try {
      await _messageController.addMessageToUI(message, state.currentChatRoom!.roomId);

      if (state.userQuota != null) {
        final updatedQuota = state.userQuota!.copyWith(
          messagesSent: state.userQuota!.messagesSent + 1,
        );
        state = state.copyWith(userQuota: updatedQuota);
      }

      await sendMessage(state.currentChatRoom!.roomId, message);

      if (state.userQuota != null) {
        await _repository.updateUserQuota(state.userQuota!);
      }

      await _messageController.updateMessageStatus(message.messageId, MessageStatus.sent);
      state = state.copyWith(isSendingMessage: false);
      AppLogger.ui('Text message sent successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to send text message: $e', tag: 'CHAT');
      state = state.copyWith(isSendingMessage: false);
      await _messageController.updateMessageStatus(message.messageId, MessageStatus.failed);
    }
  }

  // Watch rewarded ad for XP
  Future<void> watchRewardedAdForXP(AdMobService adMobService) async {
    AppLogger.ui('Checking ad availability...', tag: 'CHAT');

    await adMobService.initializeIfNeeded();

    if (!adMobService.isAdAvailable) {
      AppLogger.ui('Ad not ready, waiting for load...', tag: 'CHAT');

      // Show loading dialog logic would be handled in UI
      const maxWaitTime = Duration(seconds: 15);
      final startTime = DateTime.now();

      while (!adMobService.isAdAvailable &&
          DateTime.now().difference(startTime) < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!adMobService.isAdAvailable) {
        AppLogger.ui('Ad still not ready after waiting', tag: 'CHAT');
        return;
      }
    }

    try {
      AppLogger.ui('Starting rewarded ad display...', tag: 'CHAT');
      int? rewardXP = await adMobService.showRewardedAd();

      if (rewardXP != null && rewardXP > 0) {
        await _awardExtraMessagesFromAd(10);
      }
    } catch (e) {
      AppLogger.ui('Error in rewarded ad flow: $e', tag: 'CHAT');
    }
  }

  // Award extra messages from ad
  Future<bool> _awardExtraMessagesFromAd(int extraMessages) async {
    final user = state.currentUser;
    if (user == null) {
      AppLogger.ui('Cannot award extra messages: user is null', tag: 'CHAT');
      return false;
    }

    try {
      await _repository.addExtraQuota(user.uid, extraMessages);

      if (state.userQuota != null) {
        final updatedQuota = state.userQuota!.copyWith(
          extraQuota: state.userQuota!.extraQuota + extraMessages,
        );
        state = state.copyWith(userQuota: updatedQuota);
      }

      AppLogger.ui('Successfully awarded $extraMessages extra messages', tag: 'CHAT');
      return true;
    } catch (e) {
      AppLogger.ui('Error awarding extra messages from ad: $e', tag: 'CHAT');
      return false;
    }
  }

  // Send image message
  Future<void> sendImageMessage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null &&
        state.currentChatRoom != null &&
        state.currentUser != null) {
      await _messageController.sendImageMessage(
        state.currentChatRoom!.roomId,
        pickedFile.path,
        state.currentUser!.uid,
      );
    }
  }

  // Create poll
  Future<void> createPoll(
    String question,
    List<String> options, {
    DateTime? expiresAt,
  }) async {
    final user = state.currentUser;
    final room = state.currentChatRoom;

    if (user == null || room == null) {
      AppLogger.ui('Cannot create poll: user or room is null', tag: 'CHAT');
      return;
    }

    if (question.trim().isEmpty || options.length < 2) {
      AppLogger.ui('Cannot create poll: invalid question or options', tag: 'CHAT');
      return;
    }

    try {
      final pollId = DateTime.now().millisecondsSinceEpoch.toString();
      final poll = Poll(
        pollId: pollId,
        question: question,
        options: options,
        votes: {},
        userVotes: {},
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        isActive: true,
      );

      await _repository.createPoll(room.roomId, poll);

      final message = Message(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '≡ƒôè $question',
        senderId: user.uid,
        type: 'poll',
        createdAt: DateTime.now(),
        readBy: [user.uid],
        metadata: {'pollId': pollId},
      );

      await _messageController.addMessageToUI(message, room.roomId);
      await sendMessage(room.roomId, message);

      try {
        final pollNotificationService = PollNotificationService();
        await pollNotificationService.notifyNewPollCreated(
          roomId: room.roomId,
          pollId: pollId,
          creatorId: user.uid,
          pollQuestion: question,
        );
      } catch (e) {
        AppLogger.ui('Failed to send poll creation notifications: $e', tag: 'CHAT');
      }

      AppLogger.ui('Poll created successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to create poll: $e', tag: 'CHAT');
    }
  }

  // Clear current chat
  void clearCurrentChat() {
    final user = state.currentUser;
    final room = state.currentChatRoom;
    if (user != null && room != null) {
      _repository.clearTypingStatus(room.roomId, user.uid);
    }

    _typingSubscription?.cancel();
    state = state.copyWith(
      currentChatRoom: null,
      typingStatuses: [],
    );

    _roomController.clearCurrentRoom();
    AppLogger.ui('clearCurrentChat called - typing status cleared', tag: 'CHAT');
  }

  // Start private chat
  Future<ChatRoom?> startPrivateChat(String otherUserId, String otherUserName) async {
    final currentUser = state.currentUser;
    if (currentUser == null) {
      AppLogger.ui('Cannot start private chat: current user is null', tag: 'CHAT');
      return null;
    }

    try {
      final chatRoom = await _privateChatService.createPrivateChat(
        currentUser.uid,
        otherUserId,
        currentUser.name,
        otherUserName,
      );

      if (chatRoom != null) {
        _repository.invalidateUserCache(currentUser.uid);
        _repository.invalidateUserCache(otherUserId);
        await Future.delayed(const Duration(milliseconds: 100));
        await fetchChatRooms();
        AppLogger.ui('Private chat created: ${chatRoom.roomId}', tag: 'CHAT');
      }

      return chatRoom;
    } catch (e) {
      AppLogger.ui('Error starting private chat: $e', tag: 'CHAT');
      return null;
    }
  }

  // Get private chat user info
  Future<Map<String, dynamic>?> getPrivateChatUserInfo(String roomId) async {
    final currentUser = state.currentUser;
    if (currentUser == null) return null;

    return await _privateChatService.getPrivateChatUserInfo(roomId, currentUser.uid);
  }

  // Create chat room
  Future<ChatRoom?> createChatRoom(ChatRoom chatRoom) async {
    return await _roomController.createChatRoom(chatRoom);
  }

  // Get media URL
  String? getMediaUrl(String messageId, String? remoteUrl) {
    return _messageController.getMediaUrl(messageId, remoteUrl);
  }

  // Get sender info
  Future<Map<String, dynamic>?> getSenderInfo(String senderId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'photoURL': data['photoURL'],
          'role': data['role'] ?? 'voter',
        };
      }
      return null;
    } catch (e) {
      AppLogger.database('Error getting sender info: $e', tag: 'CHAT');
      return null;
    }
  }

  // Add reaction
  Future<void> addReaction(String messageId, String emoji) async {
    final user = state.currentUser;
    final room = state.currentChatRoom;

    if (user == null || room == null) {
      AppLogger.ui('Cannot add reaction: user or room is null', tag: 'CHAT');
      return;
    }

    try {
      await _repository.addReactionToMessage(
        room.roomId,
        messageId,
        user.uid,
        emoji,
      );
      AppLogger.ui('Reaction added: $emoji to message $messageId', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to add reaction: $e', tag: 'CHAT');
    }
  }

  // Refresh current chat messages
  Future<void> refreshCurrentChatMessages() async {
    final room = state.currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot refresh messages: no current room', tag: 'CHAT');
      return;
    }

    _messageController.loadMessagesForRoom(room.roomId);
    AppLogger.ui('Refreshed messages for room: ${room.roomId}', tag: 'CHAT');
  }

  // Report message
  Future<void> reportMessage(String messageId, String reason) async {
    final room = state.currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot report message: no current room', tag: 'CHAT');
      return;
    }

    try {
      await _repository.reportMessage(room.roomId, messageId, state.currentUser?.uid ?? '', reason);
      AppLogger.ui('Message reported successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to report message: $e', tag: 'CHAT');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    final room = state.currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot delete message: no current room', tag: 'CHAT');
      return;
    }

    try {
      await _repository.deleteMessage(room.roomId, messageId);
      AppLogger.ui('Message deleted successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to delete message: $e', tag: 'CHAT');
    }
  }

  // Retry message
  Future<void> retryMessage(String messageId) async {
    final room = state.currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot retry message: no current room', tag: 'CHAT');
      return;
    }

    await _messageController.retryMessage(room.roomId, messageId);
  }

  // Refresh chat rooms
  Future<void> refreshChatRooms() async {
    final user = state.currentUser;
    if (user != null) {
      final regularArea = user.electionAreas.isNotEmpty
          ? user.electionAreas.firstWhere(
              (area) => area.type == ElectionType.regular,
              orElse: () => user.electionAreas.first,
            )
          : null;

      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        stateId: user.location?.stateId,
        districtId: user.location?.districtId,
        bodyId: regularArea?.bodyId,
        wardId: regularArea?.wardId,
        area: regularArea?.area,
      );
    } else {
      AppLogger.ui('No user data available for refreshing chat rooms', tag: 'CHAT');
    }
  }

  // Get complete user data
  Future<void> getCompleteUserData() async {
    await _loadCompleteUserData();
  }

  // Fetch user quota
  Future<void> fetchUserQuota() async {
    // Implementation would go here if needed
  }

  // Clear user cache
  Future<void> clearUserCache() async {
    _roomController.clearCurrentRoom();
    _messageController.dispose();
  }

  // Invalidate user cache
  void invalidateUserCache(String userId) {
    if (state.currentUser?.uid == userId) {
      AppLogger.ui('Invalidating user cache for user: $userId', tag: 'CHAT');
      state = state.copyWith(currentUser: null);
      getCompleteUserData();
    }
  }

  // Initialize sample data
  Future<void> initializeSampleData() async {
    // Implementation would go here if needed
  }

  // Manually create ward room
  Future<void> manuallyCreateWardRoom() async {
    await _roomController.ensureWardRoomExists();
  }

  // Refresh user data and chat
  Future<void> refreshUserDataAndChat() async {
    await getCompleteUserData();
    await refreshChatRooms();
  }

  // Force reload ads
  void forceReloadAds(AdMobService adMobService) {
    adMobService.reloadRewardedAd();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
