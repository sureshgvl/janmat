// Compatibility layer for chat functionality
// This file provides backward compatibility while migrating to the new feature-based structure
// TODO: Remove this file after all screens are migrated to use the new controllers directly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/snackbar_utils.dart';
import 'message_controller.dart';
import 'room_controller.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/poll.dart';
import '../models/user_quota.dart';
import '../repositories/chat_repository.dart';
import '../services/private_chat_service.dart';
import '../services/user_manager.dart';
import '../services/poll_manager.dart';
import '../services/typing_status_manager.dart';
import '../services/private_chat_manager.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../notifications/services/poll_notification_service.dart';
import '../../../utils/app_logger.dart';

class ChatController extends GetxController {
  // New controllers - now lazy loaded in bindings
  late final RoomController _roomController;
  late final MessageController _messageController;
  final AuthRepository _authRepository = AuthRepository();
  final ChatRepository _repository = ChatRepository();
  final PrivateChatService _privateChatService = PrivateChatService();

  // New focused services for SOLID principles
  final UserManager _userManager = UserManager();
  final PollManager _pollManager = PollManager();
  final TypingStatusManager _typingStatusManager = TypingStatusManager();
  final PrivateChatManager _privateChatManager = PrivateChatManager();

  // Delegate properties to new controllers with reactive bridging
  List<ChatRoom> get chatRooms => _roomController.chatRooms;
  List<ChatRoomDisplayInfo> get chatRoomDisplayInfos =>
      _reactiveChatRoomDisplayInfos;
  Rx<ChatRoom?> get currentChatRoom => _roomController.currentChatRoom;
  List<Message> get messages => _messageController.messages;
  Rx<UserQuota?> get userQuota => _messageController.userQuota;

  // Reactive variables to bridge updates
  final _reactiveChatRoomDisplayInfos = <ChatRoomDisplayInfo>[].obs;
  final _reactiveIsLoading = false.obs;
  final _reactiveIsSendingMessage = false.obs;

  // Cached user data
  UserModel? _cachedUser;

  // Set up listeners for reactive streams from new controllers
  void _setupReactiveListeners() {
    // Listen to room controller updates
    _roomController.chatRoomDisplayInfos.listen((displayInfos) {
      _reactiveChatRoomDisplayInfos.assignAll(displayInfos);
      update(); // Trigger GetBuilder update
    });

    _roomController.isLoading.listen((loading) {
      _reactiveIsLoading.value = loading;
      update(); // Trigger GetBuilder update
    });
  }

  // Clean up expired repository cache on app start
  void clearExpiredRepositoryCache() {
    // This method is called from the old ChatRepository
    // For now, we'll just log that it's called
    AppLogger.database('Repository cache cleanup requested', tag: 'CHAT');
  }

  // User data - now using UserManager service
  UserModel? get currentUser {
    // First try to get from reactive state
    if (_userManager.currentUser.value != null) {
      return _userManager.currentUser.value;
    }
    // Fallback to cached user from legacy method
    return _cachedUser;
  }

  // Synchronous check if user is authenticated (for UI checks)
  bool get isUserAuthenticated => _userManager.isAuthenticated;

  bool get canSendMessage {
    final user = _cachedUser;
    if (user == null) return false;

    // Premium users always can send
    if (user.premium) return true;

    // // // COMMENTED OUT: XP balance checks removed - no limits on messaging for users
    // // // Check quota only
    // // return userQuota.value != null && userQuota.value!.canSendMessage;

    return true; // Always allow messaging
  }

  // COMMENTED OUT: XP balance feature removed
  // bool get shouldShowWatchAdsButton {
  //   final user = _cachedUser;
  //   if (user == null || user.premium) return false;
  //   // Show if no remaining messages
  //   return !canSendMessage;
  // }

  bool get shouldShowWatchAdsButton => false; // Always false since XP/ads removed

  int get remainingMessages {
    final user = _cachedUser;
    if (user == null) return 0;

    // Premium users have unlimited
    if (user.premium) return 999;

    // // // COMMENTED OUT: Quota limits removed - no limits on messaging
    // // return userQuota.value?.remainingMessages ?? 0;

    return 999; // Unlimited messages for non-premium users as well
  }

  // Load complete user data from Firestore
  Future<void> _loadCompleteUserData() async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser != null) {
        // Get complete user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          // Use UserModel.fromJson() to properly handle Timestamp conversions
          _cachedUser = UserModel.fromJson(data);
          AppLogger.database(
            'Loaded complete user data: ${_cachedUser!.name} (${_cachedUser!.role})',
            tag: 'CHAT',
          );
          update(); // Trigger UI update
        }
      }
    } catch (e) {
      AppLogger.database('Error loading complete user data: $e', tag: 'CHAT');
    }
  }

  // Delegate methods to appropriate controllers
  Future<void> initializeChatIfNeeded() async {
    // Load user data first
    await _loadCompleteUserData();

    final user = _cachedUser;
    if (user != null) {
      // Get the regular election area (assuming user has one)
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

      // // // COMMENTED OUT: Quota limits removed - no longer load or manage quotas
      // // // Load user quota
      // // try {
      // //   final quota = await _repository.getUserQuota(user.uid);
      // //   if (quota != null) {
      // //     userQuota.value = quota;
      // //     AppLogger.database(
      // //       'Loaded user quota: ${quota.remainingMessages} messages remaining',
      // //       tag: 'CHAT',
      // //     );
      // //   } else {
      // //     // Create default quota
      // //     final defaultQuota = UserQuota(
      // //       userId: user.uid,
      // //       lastReset: DateTime.now(),
      // //       createdAt: DateTime.now(),
      // //     );
      // //     userQuota.value = defaultQuota;
      // //     await _repository.updateUserQuota(defaultQuota);
      // //     AppLogger.database('Created default quota', tag: 'CHAT');
      // //   }
      // // } catch (e) {
      // //   AppLogger.database('Failed to load quota: $e', tag: 'CHAT');
      // // }
    } else {
      AppLogger.database('No user data available for chat initialization', tag: 'CHAT');
    }
  }

  Future<void> fetchChatRooms() async {
    final user = _cachedUser;
    if (user != null) {
      // Get the regular election area (assuming user has one)
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
    _setupTypingSubscription(chatRoom.roomId);
  }

  void _setupTypingSubscription(String roomId) {
    // Cancel previous subscription
    _typingSubscription?.cancel();

    // Set up new subscription
    _typingSubscription = _repository.getTypingStatusForRoom(roomId).listen(
      (statuses) {
        _typingStatuses.assignAll(statuses);
        update(); // Trigger UI update
      },
      onError: (error) {
        AppLogger.database('Error listening to typing status: $error', tag: 'CHAT');
      },
    );
  }

  void updateTypingStatus(bool isTyping) {
    final user = _cachedUser;
    final room = currentChatRoom.value;

    if (user != null && room != null) {
      _repository.updateTypingStatus(
        room.roomId,
        user.uid,
        user.name,
        isTyping,
      );
    }
  }

  Future<void> markMessageAsRead(String roomId, String messageId, String userId) async {
    try {
      await _repository.markMessageAsRead(roomId, messageId, userId);
    } catch (e) {
      AppLogger.database('Error marking message as read: $e', tag: 'CHAT');
    }
  }

  Future<void> sendMessage(String roomId, Message message) async {
    final userId = _cachedUser?.uid ?? message.senderId;
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
      // Handle poll messages - send directly to server
      await _messageController.sendPollMessage(roomId, message);
    }
  }

  Future<void> sendRecordedVoiceMessage(String filePath) async {
    if (currentChatRoom.value != null && _cachedUser != null) {
      await _messageController.sendVoiceMessage(
        currentChatRoom.value!.roomId,
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

  bool get isRecording => _messageController.isRecording.value;

  // Delegate other methods as needed
  Future<void> getCompleteUserData() async {
    await _loadCompleteUserData();
  }

  Future<void> fetchUserQuota() async {
    // This method needs to be implemented
  }

  Future<void> clearUserCache() async {
    _roomController.clearCurrentRoom();
    _messageController.onClose();
  }

  // Add other compatibility methods as needed

  // Missing methods that screens expect
  Future<void> manuallyCreateWardRoom() async {
    await _roomController.ensureWardRoomExists();
  }

  Future<void> refreshChatRooms() async {
    final user = _cachedUser;
    if (user != null) {
      // Get the regular election area (assuming user has one)
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

  Future<void> refreshUserDataAndChat() async {
    // This method needs to be implemented
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

  /// Start a private chat with another user
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
        // Force cache invalidation for both users
        _repository.invalidateUserCache(currentUser.uid);
        _repository.invalidateUserCache(otherUserId);

        // Small delay to ensure cache invalidation propagates
        await Future.delayed(const Duration(milliseconds: 100));

        // Refresh chat rooms to include the new private chat
        await fetchChatRooms();
        AppLogger.ui('Private chat created: ${chatRoom.roomId}', tag: 'CHAT');
      }

      return chatRoom;
    } catch (e) {
      AppLogger.ui('Error starting private chat: $e', tag: 'CHAT');
      return null;
    }
  }

  /// Get user info for private chat display
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

  // Typing status
  final RxList<TypingStatus> _typingStatuses = <TypingStatus>[].obs;
  List<TypingStatus> get typingStatuses => _typingStatuses;
  StreamSubscription<List<TypingStatus>>? _typingSubscription;

  // Reactive streams
  var messagesStream = Rx<List<Message>>([]);

  @override
  void onInit() {
    super.onInit();

    // Initialize controllers from bindings
    _roomController = Get.find<RoomController>();
    _messageController = Get.find<MessageController>();

    // Initialize UserManager and load user data
    _initializeUserManager();

    // Clean up expired repository cache on app start (fast operation)
    clearExpiredRepositoryCache();

    // Set up reactive listeners to bridge updates from new controllers
    _setupReactiveListeners();

    // Connect message streams
    _setupMessageStream();

    // Firebase is now available synchronously, so we can initialize immediately
    // but we'll still defer heavy operations to when chat is actually accessed
    AppLogger.ui('ChatController initialized - Firebase ready', tag: 'CHAT');
  }

  // Initialize UserManager and load user data
  Future<void> _initializeUserManager() async {
    try {
      // Load user data into UserManager
      await _userManager.getCurrentUser();
      AppLogger.chat('UserManager initialized successfully');
    } catch (e) {
      AppLogger.chat('Failed to initialize UserManager: $e');
    }
  }

  // Set up message stream connection
  void _setupMessageStream() {
    _messageController.messages.listen((messages) {
      messagesStream.value = messages;
      update(); // Trigger GetBuilder update
    });
  }

  // Additional properties that screens expect
  String? errorMessage;

  // Fix the reactive properties (remove duplicates)
  @override
  RxBool get isSendingMessage => _reactiveIsSendingMessage;
  @override
  RxBool get isLoading => _reactiveIsLoading;

  // Additional methods
  void clearError() {
    errorMessage = null;
    update();
  }

  void invalidateUserCache(String userId) {
    // Refresh cached user data if it matches the invalidated user
    if (_cachedUser?.uid == userId) {
      AppLogger.ui('Invalidating user cache for user: $userId', tag: 'CHAT');
      _cachedUser = null; // Clear cache to force reload
      getCompleteUserData(); // Reload user data
    }
  }

  Future<void> initializeSampleData() async {
    // This method needs to be implemented
  }

  // Send text message with quota/XP handling and immediate local storage
  Future<void> sendTextMessage(String text) async {
    final user = _cachedUser;
    if (user == null || currentChatRoom.value == null) {
      AppLogger.ui('Cannot send message: user or chat room is null', tag: 'CHAT');
      return;
    }

    AppLogger.ui(
      'sendTextMessage called - Text: "$text", Room: ${currentChatRoom.value!.roomId}',
      tag: 'CHAT',
    );

    // // // COMMENTED OUT: Messaging limits removed - users can always send messages
    // // // Check if user can send message
    // // if (!canSendMessage) {
    // //   SnackbarUtils.showError('You have no remaining messages. Watch a rewarded ad to get 10 extra messages.');
    // //   return;
    // // }

    // Set sending state to true
    _reactiveIsSendingMessage.value = true;
    AppLogger.ui('Set isSendingMessage to true (current value: ${_reactiveIsSendingMessage.value})', tag: 'CHAT');

    // Create message
    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: user.uid,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [user.uid],
    );

    AppLogger.ui(
      'Created message - ID: ${message.messageId}, Text: "${message.text}", Sender: ${message.senderId}',
      tag: 'CHAT',
    );

    try {
      // Add message to UI immediately (will be updated by stream)
      AppLogger.ui('Calling addMessageToUI...', tag: 'CHAT');
      await _messageController.addMessageToUI(
        message,
        currentChatRoom.value!.roomId,
      );

      // // // COMMENTED OUT: Quota deduction removed - unlimited messaging
      // // Deduct quota locally first
      // // if (userQuota.value != null) {
      // //   final updatedQuota = userQuota.value!.copyWith(
      // //     messagesSent: userQuota.value!.messagesSent + 1,
      // //   );
      // //   userQuota.value = updatedQuota;
      // //   AppLogger.ui(
      // //     'Local quota updated: ${updatedQuota.remainingMessages} remaining',
      // //     tag: 'CHAT',
      // //   );
      // // }

      // Send to server with quota handling
      AppLogger.ui('Sending message to server...', tag: 'CHAT');
      await sendMessage(currentChatRoom.value!.roomId, message);

      // // // COMMENTED OUT: Server quota updates removed
      // // Update server-side quota
      // // if (userQuota.value != null) {
      // //   await _repository.updateUserQuota(userQuota.value!);
      // //   AppLogger.ui('Server quota updated', tag: 'CHAT');
      // // }

      // Update message status to sent
      AppLogger.ui('Updating message status to sent...', tag: 'CHAT');
      await _messageController.updateMessageStatus(
        message.messageId,
        MessageStatus.sent,
      );

      // Set sending state to false
      _reactiveIsSendingMessage.value = false;
      AppLogger.ui('Set isSendingMessage to false - message sent successfully (current value: ${_reactiveIsSendingMessage.value})', tag: 'CHAT');
      AppLogger.ui('Text message sent successfully', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to send text message: $e', tag: 'CHAT');

      // Set sending state to false on error
      _reactiveIsSendingMessage.value = false;
      AppLogger.ui('Set isSendingMessage to false - message failed (current value: ${_reactiveIsSendingMessage.value})', tag: 'CHAT');

      // Update message status to failed
      await _messageController.updateMessageStatus(
        message.messageId,
        MessageStatus.failed,
      );

      SnackbarUtils.showError('Failed to send message. Please try again.');
    }
  }

  Future<void> sendImageMessage() async {
    // Pick image from gallery
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null &&
        currentChatRoom.value != null &&
        _cachedUser != null) {
      await _messageController.sendImageMessage(
        currentChatRoom.value!.roomId,
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
    final room = currentChatRoom.value;

    if (user == null || room == null) {
      AppLogger.ui('Cannot create poll: user or room is null', tag: 'CHAT');
      SnackbarUtils.showError('Please select a chat room first.');
      return;
    }

    if (question.trim().isEmpty || options.length < 2) {
      AppLogger.ui('Cannot create poll: invalid question or options', tag: 'CHAT');
      SnackbarUtils.showError('Please provide a question and at least 2 options.');
      return;
    }

    try {
      AppLogger.ui('Creating poll: "$question" with ${options.length} options, expires at: $expiresAt', tag: 'CHAT');

      // Create poll object
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

      // Save poll to repository
      await _repository.createPoll(room.roomId, poll);
      AppLogger.ui('Poll created in repository: $pollId', tag: 'CHAT');

      // Create poll message
      final message = Message(
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '📊 $question',
        senderId: user.uid,
        type: 'poll',
        createdAt: DateTime.now(),
        readBy: [user.uid],
        metadata: {'pollId': pollId},
      );

      // Add message to UI immediately
      await _messageController.addMessageToUI(message, room.roomId);

      // Send message to server
      await sendMessage(room.roomId, message);

      AppLogger.ui('Poll message sent successfully', tag: 'CHAT');

      // Send notifications to room members about the new poll
      try {
        final pollNotificationService = PollNotificationService();
        await pollNotificationService.notifyNewPollCreated(
          roomId: room.roomId,
          pollId: pollId,
          creatorId: user.uid,
          pollQuestion: question,
        );
        AppLogger.ui('Poll creation notifications sent', tag: 'CHAT');
      } catch (e) {
        AppLogger.ui('Failed to send poll creation notifications: $e', tag: 'CHAT');
        // Don't fail the poll creation if notifications fail
      }

      SnackbarUtils.showSuccess('Your poll has been created successfully!');
    } catch (e) {
      AppLogger.ui('Failed to create poll: $e', tag: 'CHAT');
      SnackbarUtils.showError('Failed to create poll. Please try again.');
    }
  }

  void clearCurrentChat() {
    // Clear typing status from Firestore before leaving
    final user = _cachedUser;
    final room = currentChatRoom.value;
    if (user != null && room != null) {
      _repository.clearTypingStatus(room.roomId, user.uid);
    }

    // Cancel typing subscription
    _typingSubscription?.cancel();
    _typingStatuses.clear();
    update();

    // Clear current room
    _roomController.clearCurrentRoom();

    AppLogger.ui('clearCurrentChat called - typing status cleared from Firestore', tag: 'CHAT');
  }

  @override
  void onClose() {
    _typingSubscription?.cancel();
    super.onClose();
  }

  Future<void> createCandidateChatRoom(
    String candidateId, [
    String? name,
  ]) async {
    // Placeholder implementation
  }

  Future<void> retryMessage(String messageId) async {
    final room = currentChatRoom.value;
    if (room == null) {
      AppLogger.ui('Cannot retry message: no current room', tag: 'CHAT');
      return;
    }

    await _messageController.retryMessage(room.roomId, messageId);
  }

  Future<void> addReaction(String messageId, String emoji) async {
    final user = _cachedUser;
    final room = currentChatRoom.value;

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
      AppLogger.ui('Reaction added: $emoji to message $messageId in room ${room.roomId}', tag: 'CHAT');
    } catch (e) {
      AppLogger.ui('Failed to add reaction: $e', tag: 'CHAT');
      SnackbarUtils.showError('Failed to add reaction. Please try again.');
    }
  }

  Future<void> refreshCurrentChatMessages() async {
    final room = currentChatRoom.value;
    if (room == null) {
      AppLogger.ui('Cannot refresh messages: no current room', tag: 'CHAT');
      return;
    }

    // Reload messages for the current room
    _messageController.loadMessagesForRoom(room.roomId);
    AppLogger.ui('Refreshed messages for room: ${room.roomId}', tag: 'CHAT');
  }

  Future<void> reportMessage(String messageId, String reason) async {
    final room = currentChatRoom.value;
    if (room == null) {
      AppLogger.ui('Cannot report message: no current room', tag: 'CHAT');
      return;
    }

    try {
      await _repository.reportMessage(room.roomId, messageId, _cachedUser?.uid ?? '', reason);
      SnackbarUtils.showInfo('Thank you for your report. We will review it.');
    } catch (e) {
      AppLogger.ui('Failed to report message: $e', tag: 'CHAT');
      SnackbarUtils.showError('Failed to report message. Please try again.');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final room = currentChatRoom.value;
    if (room == null) {
      AppLogger.ui('Cannot delete message: no current room', tag: 'CHAT');
      return;
    }

    try {
      await _repository.deleteMessage(room.roomId, messageId);
      SnackbarUtils.showSuccess('Message has been deleted successfully.');
    } catch (e) {
      AppLogger.ui('Failed to delete message: $e', tag: 'CHAT');
      SnackbarUtils.showError('Failed to delete message. Please try again.');
    }
  }

  String? get currentRecordingPath => null; // Placeholder

  // Force reload rewarded ads for testing (stub since ads removed)
  void forceReloadAds() {
    SnackbarUtils.showInfo('Ad functionality has been removed.');
  }
}
