// Compatibility layer for chat functionality
// This file provides backward compatibility while migrating to the new feature-based structure
// TODO: Remove this file after all screens are migrated to use the new controllers directly

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'message_controller.dart';
import 'room_controller.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/user_quota.dart';
import '../repositories/chat_repository.dart';
import '../../../models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../services/admob_service.dart';
import '../../monetization/repositories/monetization_repository.dart';

class ChatController extends GetxController {
  // New controllers
  final MessageController _messageController = Get.put(MessageController());
  final RoomController _roomController = Get.put(RoomController());
  final AuthRepository _authRepository = AuthRepository();
  final ChatRepository _repository = ChatRepository();

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
    debugPrint('🧹 Repository cache cleanup requested');
  }

  // User data - get from auth repository
  UserModel? get currentUser {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    // Try to get from auth repository
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser != null) {
      // Get complete user data asynchronously
      _loadCompleteUserData();
      return null; // Return null initially, will be updated when data loads
    }

    return null;
  }

  bool get canSendMessage {
    final user = _cachedUser;
    if (user == null) return false;

    // Premium users always can send
    if (user.premium) return true;

    // Check quota first
    if (userQuota.value != null && userQuota.value!.canSendMessage) {
      return true;
    }

    // Check XP as fallback (1 XP = 1 message)
    return user.xpPoints > 0;
  }

  bool get shouldShowWatchAdsButton {
    final user = _cachedUser;
    if (user == null || user.premium) return false;

    // Show if no quota and no XP
    return !canSendMessage;
  }

  int get remainingMessages {
    final user = _cachedUser;
    if (user == null) return 0;

    // Premium users have unlimited
    if (user.premium) return 999;

    // Return quota if available
    if (userQuota.value != null) {
      return userQuota.value!.remainingMessages;
    }

    // Fallback to XP count
    return user.xpPoints;
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
          _cachedUser = UserModel(
            uid: data['uid'] ?? firebaseUser.uid,
            name: data['name'] ?? firebaseUser.displayName ?? 'Unknown',
            phone: data['phone'] ?? firebaseUser.phoneNumber ?? '',
            email: data['email'] ?? firebaseUser.email,
            role: data['role'] ?? 'voter',
            roleSelected: data['roleSelected'] ?? false,
            profileCompleted: data['profileCompleted'] ?? false,
            wardId: data['wardId'] ?? '',
            districtId: data['districtId'] ?? '',
            bodyId: data['bodyId'] ?? '',
            area: data['area'],
            xpPoints: data['xpPoints'] ?? 0,
            premium: data['premium'] ?? false,
            createdAt: data['createdAt'] != null
                ? DateTime.parse(data['createdAt'])
                : DateTime.now(),
            photoURL: data['photoURL'] ?? firebaseUser.photoURL,
          );
          debugPrint(
            '✅ Loaded complete user data: ${_cachedUser!.name} (${_cachedUser!.role})',
          );
          update(); // Trigger UI update
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading complete user data: $e');
    }
  }

  // Delegate methods to appropriate controllers
  Future<void> initializeChatIfNeeded() async {
    // Load user data first
    await _loadCompleteUserData();

    final user = _cachedUser;
    if (user != null) {
      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        districtId: user.districtId,
        bodyId: user.bodyId,
        wardId: user.wardId,
        area: user.area,
      );

      // Load user quota
      try {
        final quota = await _repository.getUserQuota(user.uid);
        if (quota != null) {
          userQuota.value = quota;
          debugPrint(
            '📊 Loaded user quota: ${quota.remainingMessages} messages remaining',
          );
        } else {
          // Create default quota
          final defaultQuota = UserQuota(
            userId: user.uid,
            lastReset: DateTime.now(),
            createdAt: DateTime.now(),
          );
          userQuota.value = defaultQuota;
          await _repository.updateUserQuota(defaultQuota);
          debugPrint('📊 Created default quota');
        }
      } catch (e) {
        debugPrint('❌ Failed to load quota: $e');
      }
    } else {
      debugPrint('⚠️ No user data available for chat initialization');
    }
  }

  Future<void> fetchChatRooms() async {
    final user = _cachedUser;
    if (user != null) {
      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        districtId: user.districtId,
        bodyId: user.bodyId,
        wardId: user.wardId,
        area: user.area,
      );
    } else {
      debugPrint('⚠️ No user data available for fetching chat rooms');
    }
  }

  void selectChatRoom(ChatRoom chatRoom) {
    _roomController.selectChatRoom(chatRoom);
    _messageController.loadMessagesForRoom(chatRoom.roomId);
  }

  Future<void> sendMessage(String roomId, Message message) async {
    final userId = _cachedUser?.uid ?? message.senderId;
    if (message.type == 'text') {
      await _messageController.sendTextMessage(roomId, message.text, userId);
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

  Future<void> watchRewardedAdForXP() async {
    final adMobService = Get.find<AdMobService>();

    debugPrint('🎬 Checking ad availability...');
    debugPrint('🎬 Ad status: ${adMobService.getAdStatus()}');
    debugPrint('🎬 Ad debug info: ${adMobService.getAdDebugInfo()}');

    // Force initialize if not done yet
    await adMobService.initializeIfNeeded();

    // Wait a bit for ad to load if not ready
    if (!adMobService.isAdAvailable) {
      debugPrint('🎬 Ad not ready, waiting for load...');

      // Show loading dialog while waiting
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading rewarded ad...'),
              const SizedBox(height: 8),
              Text(
                'Preparing your ad. This may take a moment.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.snackbar(
                  'Cancelled',
                  'Ad loading cancelled',
                  backgroundColor: Colors.grey.shade100,
                  colorText: Colors.grey.shade800,
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // Wait up to 15 seconds for ad to load
      const maxWaitTime = Duration(seconds: 15);
      final startTime = DateTime.now();

      while (!adMobService.isAdAvailable &&
          DateTime.now().difference(startTime) < maxWaitTime) {
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint(
          '🎬 Still waiting for ad... (${DateTime.now().difference(startTime).inSeconds}s)',
        );
      }

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (!adMobService.isAdAvailable) {
        debugPrint('🎬 Ad still not ready after waiting');
        Get.snackbar(
          'Ad Not Ready',
          'Ad failed to load. Please check your internet connection and try again.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    try {
      debugPrint('🎬 Starting rewarded ad display...');

      // Show loading dialog while displaying ad
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Showing rewarded ad...'),
              const SizedBox(height: 8),
              Text(
                'Watch the ad completely to earn XP',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      debugPrint('🎬 Displaying rewarded ad...');
      int? rewardXP = await adMobService.showRewardedAd();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Close loading dialog if still open (double check)
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      debugPrint('🎯 Ad result: rewardXP = $rewardXP');

      // For testing: if ad fails, offer simulation
      if (rewardXP == null || rewardXP == 0) {
        debugPrint(
          '🎯 Ad failed or returned no reward, offering simulation for testing',
        );

        // Show dialog asking if user wants to simulate reward for testing
        final shouldSimulate = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Ad Not Available'),
            content: const Text(
              'The rewarded ad could not be shown. Would you like to simulate a reward for testing purposes?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Yes (Test)'),
              ),
            ],
          ),
        );

        if (shouldSimulate == true) {
          debugPrint('🧪 User chose to simulate reward');
          rewardXP = await adMobService.simulateRewardForTesting();
          debugPrint('🧪 Simulated reward: $rewardXP XP');
        }
      }

      if (rewardXP != null && rewardXP > 0) {
        debugPrint('🎯 Ad completed, attempting to award $rewardXP XP');

        // Award XP to user
        final awardSuccess = await _awardXPFromAd(rewardXP);

        if (awardSuccess) {
          Get.snackbar(
            '🎉 Reward Earned!',
            'You earned $rewardXP XP for watching the ad!',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            duration: const Duration(seconds: 4),
          );

          // Refresh user data to show updated XP
          await getCompleteUserData();
        } else {
          Get.snackbar(
            'Reward Error',
            'Ad was watched but failed to award XP. Please contact support.',
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            duration: const Duration(seconds: 4),
          );
        }
      } else {
        debugPrint(
          '⚠️ Ad was shown but no reward was earned - this might be normal for test ads',
        );

        // For test ads, still award some XP as fallback
        if (adMobService.isTestAdUnit()) {
          debugPrint('🧪 Test ad detected, awarding fallback XP');
          final fallbackXP = 2;
          final awardSuccess = await _awardXPFromAd(fallbackXP);

          if (awardSuccess) {
            Get.snackbar(
              '🎉 Test Reward Earned!',
              'You earned $fallbackXP XP (test mode)!',
              backgroundColor: Colors.blue.shade100,
              colorText: Colors.blue.shade800,
              duration: const Duration(seconds: 4),
            );
            await getCompleteUserData();
          }
        } else {
          Get.snackbar(
            'No Reward',
            'Ad was shown but no reward was earned. Please try again.',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in rewarded ad flow: $e');

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Ad Error',
        'Failed to show ad. Please try again later.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

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
      await _roomController.loadChatRooms(
        user.uid,
        user.role,
        districtId: user.districtId,
        bodyId: user.bodyId,
        wardId: user.wardId,
        area: user.area,
      );
    } else {
      debugPrint('⚠️ No user data available for refreshing chat rooms');
    }
  }

  Future<void> refreshUserDataAndChat() async {
    // This method needs to be implemented
  }

  Future<Map<String, dynamic>?> getSenderInfo(String senderId) async {
    // This method needs to be implemented
    return null;
  }

  Future<ChatRoom?> createChatRoom(ChatRoom chatRoom) async {
    return await _roomController.createChatRoom(chatRoom);
  }

  String? getMediaUrl(String messageId, String? remoteUrl) {
    return _messageController.getMediaUrl(messageId, remoteUrl);
  }

  // Reactive streams
  var messagesStream = Rx<List<Message>>([]);

  @override
  void onInit() {
    super.onInit();
    // Clean up expired repository cache on app start (fast operation)
    clearExpiredRepositoryCache();

    // Set up reactive listeners to bridge updates from new controllers
    _setupReactiveListeners();

    // Connect message streams
    _setupMessageStream();

    // Firebase is now available synchronously, so we can initialize immediately
    // but we'll still defer heavy operations to when chat is actually accessed
    debugPrint('📱 ChatController initialized - Firebase ready');
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
  RxBool get isSendingMessage => false.obs;
  @override
  RxBool get isLoading => _reactiveIsLoading;

  // Additional methods
  void clearError() {
    errorMessage = null;
    update();
  }

  void invalidateUserCache(String userId) {
    // This method needs to be implemented
  }

  Future<void> initializeSampleData() async {
    // This method needs to be implemented
  }

  // Send text message with quota/XP handling and immediate local storage
  Future<void> sendTextMessage(String text) async {
    final user = _cachedUser;
    if (user == null || currentChatRoom.value == null) {
      debugPrint('❌ Cannot send message: user or chat room is null');
      return;
    }

    // Check if user can send message (basic check - TODO: implement full quota/XP logic)
    if (!canSendMessage) {
      Get.snackbar(
        'Cannot Send Message',
        'You have no remaining messages or XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Create message
    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: user.uid,
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [user.uid],
    );

    try {
      // Determine resource usage
      final useQuota =
          userQuota.value != null && userQuota.value!.canSendMessage;
      final useXP = !useQuota && user.xpPoints > 0;

      // Use MessageController for immediate local storage and UI update
      await _messageController.addMessageToUI(
        message,
        currentChatRoom.value!.roomId,
      );

      // Deduct resources locally first
      if (useQuota && userQuota.value != null) {
        final updatedQuota = userQuota.value!.copyWith(
          messagesSent: userQuota.value!.messagesSent + 1,
        );
        userQuota.value = updatedQuota;
        debugPrint(
          '📊 Local quota updated: ${updatedQuota.remainingMessages} remaining',
        );
      } else if (useXP) {
        // XP deduction will be handled by the repository method
        debugPrint('⭐ Will deduct 1 XP for message');
      }

      // Send to server with quota/XP handling
      await sendMessage(currentChatRoom.value!.roomId, message);

      // Update server-side quota/XP
      if (useQuota && userQuota.value != null) {
        await _repository.updateUserQuota(userQuota.value!);
        debugPrint('📊 Server quota updated');
      } else if (useXP) {
        // Update XP via Firestore transaction
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          transaction.update(userRef, {'xpPoints': FieldValue.increment(-1)});
        });
        // Refresh user data to reflect XP change
        await getCompleteUserData();
        debugPrint('⭐ XP deducted from server');
      }

      // Update message status to sent
      await _messageController.updateMessageStatus(
        message.messageId,
        MessageStatus.sent,
      );

      debugPrint('✅ Text message sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send text message: $e');

      // Update message status to failed
      await _messageController.updateMessageStatus(
        message.messageId,
        MessageStatus.failed,
      );

      Get.snackbar(
        'Message Failed',
        'Failed to send message. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Award XP from watching ad
  Future<bool> _awardXPFromAd(int xpAmount) async {
    final user = _cachedUser;
    if (user == null) {
      debugPrint('❌ Cannot award XP: user is null');
      return false;
    }

    try {
      debugPrint('🏆 Attempting to award $xpAmount XP to user: ${user.uid}');

      // Use MonetizationRepository to handle XP transaction
      final monetizationRepo = MonetizationRepository();

      // Create XP transaction and update balance
      await monetizationRepo.updateUserXPBalance(user.uid, xpAmount);

      // Immediately refresh cached user data to reflect XP changes
      await getCompleteUserData();

      // Force UI update for all listeners (including profile screen)
      update();

      debugPrint('✅ Successfully awarded $xpAmount XP to user: ${user.uid}');
      debugPrint('   Updated cached XP: ${_cachedUser?.xpPoints ?? 0}');
      return true;
    } catch (e) {
      debugPrint('❌ Error awarding XP from ad: $e');
      debugPrint('   Error details: ${e.toString()}');
      return false;
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
    // Basic implementation - will be replaced when screens migrate
    debugPrint('createPoll called with question: $question');
  }

  void clearCurrentChat() {
    // Basic implementation - will be replaced when screens migrate
    debugPrint('clearCurrentChat called');
  }

  Future<void> createCandidateChatRoom(
    String candidateId, [
    String? name,
  ]) async {
    // Placeholder implementation
  }

  Future<void> retryMessage(String messageId) async {
    // This method needs to be implemented
  }

  Future<void> addReaction(String messageId, String emoji) async {
    // This method needs to be implemented
  }

  Future<void> refreshCurrentChatMessages() async {
    // This method needs to be implemented
  }

  Future<void> reportMessage(String messageId, String reason) async {
    // This method needs to be implemented
  }

  Future<void> deleteMessage(String messageId) async {
    // This method needs to be implemented
  }

  String? get currentRecordingPath => null; // Placeholder

  // Force reload rewarded ads for testing
  void forceReloadAds() {
    final adMobService = Get.find<AdMobService>();
    adMobService.reloadRewardedAd();
    Get.snackbar(
      'Ads Reloaded',
      'Rewarded ads have been reloaded. Try watching an ad again.',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 3),
    );
  }
}
