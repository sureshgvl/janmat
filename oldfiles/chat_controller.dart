// Compatibility layer for chat functionality
// This file provides backward compatibility while migrating to Riverpod
// TODO: Remove this file after all screens are migrated to use Riverpod providers directly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
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
import '../../../core/providers/chat_providers.dart';

class ChatController extends GetxController {
  // New controllers - now lazy loaded in bindings
  late final RoomController _roomController;
  late final MessageController _messageController;

  final AuthRepository _authRepository = AuthRepository();
  final ChatRepository _repository = ChatRepository();
  final PrivateChatService _privateChatService = PrivateChatService();

  // Reactive variables to bridge updates
  final _reactiveChatRoomDisplayInfos = <ChatRoomDisplayInfo>[].obs;
  final _reactiveIsLoading = false.obs;
  final _reactiveIsSendingMessage = false.obs;

  // Cached user data
  UserModel? _cachedUser;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _setupReactiveBridges();
  }

  void _initializeControllers() {
    _roomController = RoomController();
    _messageController = MessageController(roomController: _roomController);
  }

  void _setupReactiveBridges() {
    // Bridge updates from Riverpod to GetX reactive variables
    // This will be removed once all screens use Riverpod directly
    ever(_reactiveChatRoomDisplayInfos, (_) => update());
    ever(_reactiveIsLoading, (_) => update());
    ever(_reactiveIsSendingMessage, (_) => update());
  }

  // Delegate properties to new controllers with reactive bridging
  List<ChatRoom> get chatRooms => _roomController.chatRooms;
  List<ChatRoomDisplayInfo> get chatRoomDisplayInfos => _reactiveChatRoomDisplayInfos;
  ChatRoom? get currentChatRoom => _roomController.currentChatRoom;
  List<Message> get messages => _messageController.messages;
  UserQuota? get userQuota => _messageController.userQuota;

  // Computed properties
  bool get canSendMessage {
    final user = _cachedUser;
    if (user == null) return false;
    if (user.premium) return true;
    return userQuota?.canSendMessage ?? false;
  }

  bool get shouldShowWatchAdsButton {
    final user = _cachedUser;
    if (user == null || user.premium) return false;
    return !canSendMessage;
  }

  int get remainingMessages {
    final user = _cachedUser;
    if (user == null) return 0;
    if (user.premium) return 999;
    return userQuota?.remainingMessages ?? 0;
  }

  // Reactive getters for backward compatibility
  RxBool get isLoading => _reactiveIsLoading;
  RxBool get isSendingMessage => _reactiveIsSendingMessage;

  // Missing getters
  UserModel? get currentUser => _cachedUser;
  String get errorMessage => ''; // TODO: Implement error state management
  List<TypingStatus> get typingStatuses => []; // TODO: Implement typing status tracking
  bool get isRecording => _messageController.isRecording;
  String? get currentRecordingPath => _messageController.currentRecordingPath;

  // Delegate methods to new controllers
  Future<void> initializeChatIfNeeded() async {
    await _loadCompleteUserData();

    final user = _cachedUser;
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
          // Note: userQuota is now a plain property, need to update via message controller
          _messageController.userQuota = quota;
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
          _messageController.userQuota = defaultQuota;
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
          _cachedUser = UserModel.fromJson(data);
          AppLogger.database(
            'Loaded complete user data: ${_cachedUser!.name} (${_cachedUser!.role})',
            tag: 'CHAT',
          );
        }
      }
    } catch (e) {
      AppLogger.database('Error loading complete user data: $e', tag: 'CHAT');
    }
  }

  Future<void> fetchChatRooms() async {
    final user = _cachedUser;
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

  void selectChatRoom(ChatRoom chatRoom) {
    _roomController.selectChatRoom(chatRoom);
    _messageController.loadMessagesForRoom(chatRoom.roomId);
  }

  Future<void> sendTextMessage(String text) async {
    final user = _cachedUser;
    if (user == null || currentChatRoom == null) {
      AppLogger.ui('Cannot send message: user or chat room is null', tag: 'CHAT');
      return;
    }

    AppLogger.ui(
      'sendTextMessage called - Text: "$text", Room: ${currentChatRoom!.roomId}',
      tag: 'CHAT',
    );

    if (!canSendMessage) {
      // Handle quota exceeded - this would need to be handled by the UI
      AppLogger.ui('Cannot send message: quota exceeded', tag: 'CHAT');
      return;
    }

    _reactiveIsSendingMessage.value = true;

    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: user.uid,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [user.uid],
    );

    try {
      await _messageController.addMessageToUI(message, currentChatRoom!.roomId);

      if (userQuota != null) {
        final updatedQuota = userQuota!.copyWith(
          messagesSent: userQuota!.messagesSent + 1,
        );
        // Note: userQuota is now a plain property, need to update via message controller
        _messageController.userQuota = updatedQuota;
      }

      await _messageController.sendTextMessage(currentChatRoom!.roomId, message.text, user.uid, existingMessage: message);

      if (userQuota != null) {
        await _repository.updateUserQuota(userQuota!);
      }

      await _messageController.updateMessageStatus(message.messageId, MessageStatus.sent);
      _reactiveIsSendingMessage.value = false;
      AppLogger.ui('Text message sent successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to send text message: $e', tag: 'CHAT');
      _reactiveIsSendingMessage.value = false;
      await _messageController.updateMessageStatus(message.messageId, MessageStatus.failed);
    }
  }

  Future<void> watchRewardedAdForXP([AdMobService? adMobService]) async {
    // If no AdMobService provided, create one (for backward compatibility)
    final service = adMobService ?? AdMobService();
    AppLogger.ui('Checking ad availability...', tag: 'CHAT');

    await service.initializeIfNeeded();

    if (!service.isAdAvailable) {
      AppLogger.ui('Ad not ready, waiting for load...', tag: 'CHAT');

      // Show loading dialog logic would be handled in UI
      const maxWaitTime = Duration(seconds: 15);
      final startTime = DateTime.now();

      while (!service.isAdAvailable &&
          DateTime.now().difference(startTime) < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!service.isAdAvailable) {
        AppLogger.ui('Ad still not ready after waiting', tag: 'CHAT');
        return;
      }
    }

    try {
      AppLogger.ui('Starting rewarded ad display...', tag: 'CHAT');
      int? rewardXP = await service.showRewardedAd();

      if (rewardXP != null && rewardXP > 0) {
        await _awardExtraMessagesFromAd(10);
      }
    } catch (e) {
      AppLogger.ui('Error in rewarded ad flow: $e', tag: 'CHAT');
    }
  }

  Future<bool> _awardExtraMessagesFromAd(int extraMessages) async {
    final user = _cachedUser;
    if (user == null) {
      AppLogger.ui('Cannot award extra messages: user is null', tag: 'CHAT');
      return false;
    }

    try {
      await _repository.addExtraQuota(user.uid, extraMessages);

      if (userQuota != null) {
        final updatedQuota = userQuota!.copyWith(
          extraQuota: userQuota!.extraQuota + extraMessages,
        );
        _messageController.userQuota = updatedQuota;
      }

      AppLogger.ui('Successfully awarded $extraMessages extra messages', tag: 'CHAT');
      return true;
    } catch (e) {
      AppLogger.ui('Error awarding extra messages from ad: $e', tag: 'CHAT');
      return false;
    }
  }

  Future<void> sendImageMessage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null &&
        currentChatRoom != null &&
        _cachedUser != null) {
      await _messageController.sendImageMessage(
        currentChatRoom!.roomId,
        pickedFile.path,
        _cachedUser!.uid,
      );
    }
  }

  Future<void> createPoll(
    String question,
    List<String> options, {
    DateTime? expiresAt,
  }) async {
    final user = _cachedUser;
    final room = currentChatRoom;

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
      await _messageController.sendPollMessage(room.roomId, message);

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

  void clearCurrentChat() {
    final user = _cachedUser;
    final room = currentChatRoom;
    if (user != null && room != null) {
      _repository.clearTypingStatus(room.roomId, user.uid);
    }

    _roomController.clearCurrentRoom();
    AppLogger.ui('clearCurrentChat called - typing status cleared', tag: 'CHAT');
  }

  Future<ChatRoom?> startPrivateChat(String otherUserId, String otherUserName) async {
    final currentUser = _cachedUser;
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

  Future<Map<String, dynamic>?> getPrivateChatUserInfo(String roomId) async {
    final currentUser = _cachedUser;
    if (currentUser == null) return null;

    return await _privateChatService.getPrivateChatUserInfo(roomId, currentUser.uid);
  }

  Future<ChatRoom?> createChatRoom(ChatRoom chatRoom) async {
    return await _roomController.createChatRoom(chatRoom);
  }

  String? getMediaUrl(String messageId, String? remoteUrl) {
    return _messageController.getMediaUrl(messageId, remoteUrl);
  }

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

  Future<void> addReaction(String messageId, String emoji) async {
    final user = _cachedUser;
    final room = currentChatRoom;

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

  Future<void> refreshCurrentChatMessages() async {
    final room = currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot refresh messages: no current room', tag: 'CHAT');
      return;
    }

    _messageController.loadMessagesForRoom(room.roomId);
    AppLogger.ui('Refreshed messages for room: ${room.roomId}', tag: 'CHAT');
  }

  Future<void> reportMessage(String messageId, String reason) async {
    final room = currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot report message: no current room', tag: 'CHAT');
      return;
    }

    try {
      await _repository.reportMessage(room.roomId, messageId, _cachedUser?.uid ?? '', reason);
      AppLogger.ui('Message reported successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to report message: $e', tag: 'CHAT');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final room = currentChatRoom;
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

  Future<void> retryMessage(String messageId) async {
    final room = currentChatRoom;
    if (room == null) {
      AppLogger.ui('Cannot retry message: no current room', tag: 'CHAT');
      return;
    }

    await _messageController.retryMessage(room.roomId, messageId);
  }

  Future<void> refreshChatRooms() async {
    final user = _cachedUser;
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

  Future<void> getCompleteUserData() async {
    await _loadCompleteUserData();
  }

  Future<void> fetchUserQuota() async {
    // Implementation would go here if needed
  }

  Future<void> clearUserCache() async {
    _roomController.clearCurrentRoom();
    _messageController.dispose();
  }

  void invalidateUserCache(String userId) {
    if (_cachedUser?.uid == userId) {
      AppLogger.ui('Invalidating user cache for user: $userId', tag: 'CHAT');
      _cachedUser = null;
      getCompleteUserData();
    }
  }

  Future<void> initializeSampleData() async {
    // Implementation would go here if needed
  }

  Future<void> manuallyCreateWardRoom() async {
    await _roomController.ensureWardRoomExists();
  }

  Future<void> refreshUserDataAndChat() async {
    await getCompleteUserData();
    await refreshChatRooms();
  }

  void forceReloadAds(AdMobService adMobService) {
    adMobService.reloadRewardedAd();
  }

  // Missing methods
  Future<void> initialize(RoomController roomController, MessageController messageController) async {
    // Store the controllers for backward compatibility
    _roomController = roomController;
    _messageController = messageController;
    await initializeChatIfNeeded();
  }

  Future<void> markMessageAsRead(String roomId, String messageId, String userId) async {
    await _messageController.markMessageAsRead(roomId, messageId, userId);
  }

  Future<void> updateTypingStatus(bool isTyping) async {
    final room = currentChatRoom;
    final user = _cachedUser;
    if (room != null && user != null) {
      await _repository.updateTypingStatus(room.roomId, user.uid, user.name, isTyping);
    }
  }

  Future<void> sendRecordedVoiceMessage(String filePath) async {
    if (currentChatRoom != null && _cachedUser != null) {
      await _messageController.sendVoiceMessage(
        currentChatRoom!.roomId,
        filePath,
        _cachedUser!.uid,
      );
    }
  }

  Future<String?> stopVoiceRecordingOnly() async {
    return await _messageController.stopVoiceRecording();
  }

  Future<void> startVoiceRecording() async {
    await _messageController.startVoiceRecording();
  }

  void clearError() {
    // Implementation for clearing error state
  }

  @override
  void onClose() {
    _messageController.dispose();
    super.onClose();
  }
}
