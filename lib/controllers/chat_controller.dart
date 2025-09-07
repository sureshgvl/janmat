import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../repositories/chat_repository.dart';
import '../repositories/monetization_repository.dart';
import '../services/chat_initializer.dart';
import '../services/admob_service.dart';

class ChatController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  // State variables
  List<ChatRoom> chatRooms = [];
  ChatRoom? currentChatRoom;
  List<Message> messages = [];
  UserQuota? userQuota;
  bool isLoading = false;
  bool isSendingMessage = false;
  String? errorMessage;
  String? currentRecordingPath;
  bool _isInitialLoadComplete = false; // Flag to prevent real-time override during initial load

  // Reactive variables for real-time updates
  var chatRoomsStream = Rx<List<ChatRoom>>([]);
  var messagesStream = Rx<List<Message>>([]);
  var userQuotaStream = Rx<UserQuota?>(null);

  // Current user
  UserModel? get currentUser => _getCurrentUser();

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }

  // Initialize chat for current user
  Future<void> _initializeChat() async {
    final user = await getCompleteUserData();
    if (user != null) {
      print('🚀 Initializing chat for user: ${user.name} (${user.role})');
      fetchUserQuota();
      fetchChatRooms();

      // Ensure ward room exists for voters with complete profiles
      if (user.role == 'voter' && user.wardId.isNotEmpty && user.cityId.isNotEmpty) {
        print('🏛️ Ensuring ward room exists for voter: ward_${user.cityId}_${user.wardId}');
        ensureWardRoomExists();
      } else if (user.role == 'voter') {
        print('⚠️ Voter profile incomplete - missing ward or city info');
      }
    } else {
      print('❌ No user found for chat initialization');
    }
  }

  // Get current user from Firebase Auth and Firestore
  UserModel? _getCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // For now, return basic user info
    // In a real implementation, you'd cache this or fetch from Firestore
    return UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Unknown',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      role: 'voter', // Default role
      wardId: '', // Will be updated after profile completion
      cityId: '', // Will be updated after profile completion
      xpPoints: 0,
      premium: false,
      createdAt: DateTime.now(),
      photoURL: firebaseUser.photoURL,
    );
  }

  // Fetch complete user data from Firestore
  Future<UserModel?> getCompleteUserData() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return UserModel(
          uid: data['uid'] ?? firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'Unknown',
          phone: data['phone'] ?? firebaseUser.phoneNumber ?? '',
          email: data['email'] ?? firebaseUser.email,
          role: data['role'] ?? 'voter',
          wardId: data['wardId'] ?? '',
          cityId: data['cityId'] ?? '',
          xpPoints: data['xpPoints'] ?? 0,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          photoURL: data['photoURL'] ?? firebaseUser.photoURL,
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }

    return _getCurrentUser(); // Fallback to basic data
  }

  // Fetch chat rooms for current user
  Future<void> fetchChatRooms() async {
    final user = currentUser;
    if (user == null) return;

    isLoading = true;
    errorMessage = null;
    _isInitialLoadComplete = false; // Reset flag during fetch
    update();

    try {
      chatRooms = await _repository.getChatRoomsForUser(user.uid, user.role);
      chatRoomsStream.value = chatRooms;

      // Mark initial load as complete
      _isInitialLoadComplete = true;

      // Start listening for real-time room changes (deletions, updates)
      _listenForRoomChanges(user.uid, user.role);
    } catch (e) {
      errorMessage = e.toString();
      chatRooms = [];
      chatRoomsStream.value = [];
      _isInitialLoadComplete = true; // Even on error, mark as complete
    }

    isLoading = false;
    update();
  }

  // Listen for real-time room changes (deletions, updates)
  void _listenForRoomChanges(String userId, String userRole) {
    // Use a single comprehensive query instead of multiple listeners
    // This prevents the issue where different listeners overwrite each other

    FirebaseFirestore.instance
        .collection('chats')
        .snapshots()
        .listen((snapshot) async {
          await _handleAllRoomChanges(snapshot, userId, userRole);
        });
  }

  // Handle all room changes with proper filtering
  Future<void> _handleAllRoomChanges(QuerySnapshot snapshot, String userId, String userRole) async {
    // Don't process real-time updates until initial load is complete
    if (!_isInitialLoadComplete) {
      return;
    }

    final allRooms = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['roomId'] = doc.id;
      return ChatRoom.fromJson(data);
    }).toList();

    // Filter rooms based on user permissions
    final accessibleRooms = allRooms.where((room) {
      // Public rooms are accessible to all authenticated users
      if (room.type == 'public') {
        return true;
      }

      // Private rooms are only accessible to members
      if (room.type == 'private') {
        return room.members?.contains(userId) ?? false;
      }

      // For candidates and admins, they can also access rooms they created
      if (userRole == 'candidate' || userRole == 'admin') {
        return room.createdBy == userId;
      }

      return false;
    }).toList();

    // Sort rooms by creation date (newest first)
    accessibleRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Only update if there are actual changes to prevent unnecessary UI updates
    final currentRoomIds = chatRooms.map((r) => r.roomId).toSet();
    final newRoomIds = accessibleRooms.map((r) => r.roomId).toSet();

    if (currentRoomIds != newRoomIds) {
      // Update local chat rooms list
      chatRooms = accessibleRooms;
      chatRoomsStream.value = accessibleRooms;
      update();

      // Show notification for new rooms
      final addedRooms = newRoomIds.difference(currentRoomIds);
      if (addedRooms.isNotEmpty) {
        print('🆕 New chat rooms available: ${addedRooms.length}');
      }

      // Show notification for deleted rooms
      final deletedRooms = currentRoomIds.difference(newRoomIds);
      if (deletedRooms.isNotEmpty) {
        Get.snackbar(
          'Chat Room Updated',
          'Some chat rooms have been updated or removed',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  // Fetch user quota
  Future<void> fetchUserQuota() async {
    final user = currentUser;
    if (user == null) return;

    try {
      userQuota = await _repository.getUserQuota(user.uid);
      userQuotaStream.value = userQuota;
      update();
    } catch (e) {
      print('Failed to fetch user quota: $e');
    }
  }

  // Select a chat room
  void selectChatRoom(ChatRoom chatRoom) {
    currentChatRoom = chatRoom;
    messages = [];
    messagesStream.value = [];

    // Start listening to messages
    _listenToMessages(chatRoom.roomId);
    update();
  }

  // Listen to messages in real-time
  void _listenToMessages(String roomId) {
    _repository.getMessagesForRoom(roomId).listen((messagesList) {
      messages = messagesList;
      messagesStream.value = messagesList;

      // Mark messages as read
      _markUnreadMessagesAsRead();
    });
  }

  // Mark unread messages as read
  void _markUnreadMessagesAsRead() {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    final unreadMessages = messages.where((msg) =>
      !msg.readBy.contains(user.uid) && msg.senderId != user.uid
    ).toList();

    for (final message in unreadMessages) {
      _repository.markMessageAsRead(currentChatRoom!.roomId, message.messageId, user.uid);
    }
  }

  // Send text message
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || currentChatRoom == null) return;

    final user = currentUser;
    if (user == null) return;

    isSendingMessage = true;
    update();

    try {
      final message = Message(
        messageId: _uuid.v4(),
        text: text.trim(),
        senderId: user.uid,
        type: 'text',
        createdAt: DateTime.now(),
        readBy: [user.uid],
      );

      await _repository.sendMessage(currentChatRoom!.roomId, message);

      // Handle quota/XP deduction
      if (userQuota != null && userQuota!.canSendMessage) {
        // Use regular quota
        await fetchUserQuota();
      } else if (user.xpPoints > 0) {
        // Use XP points (1 XP = 1 message)
        await _deductXPForMessage(user.uid);
        await refreshUserDataAndChat(); // Refresh to get updated XP
      }

    } catch (e) {
      errorMessage = e.toString();
    }

    isSendingMessage = false;
    update();
  }

  // Send image message
  Future<void> sendImageMessage() async {
    if (currentChatRoom == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      isSendingMessage = true;
      update();

      // Upload image to Firebase Storage
      final downloadUrl = await _repository.uploadMediaFile(
        currentChatRoom!.roomId,
        pickedFile.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
        'image/jpeg',
      );

      // Send message with image URL
      final user = currentUser;
      if (user != null) {
        final message = Message(
          messageId: _uuid.v4(),
          text: 'Image',
          senderId: user.uid,
          type: 'image',
          createdAt: DateTime.now(),
          readBy: [user.uid],
          mediaUrl: downloadUrl,
        );

        await _repository.sendMessage(currentChatRoom!.roomId, message);

        // Handle quota/XP deduction
        if (userQuota != null && userQuota!.canSendMessage) {
          await fetchUserQuota();
        } else if (user.xpPoints > 0) {
          await _deductXPForMessage(user.uid);
          await refreshUserDataAndChat();
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isSendingMessage = false;
    update();
  }

  // Start voice recording
  Future<void> startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        currentRecordingPath = fileName;

        await _audioRecorder.start(
          const RecordConfig(),
          path: fileName,
        );
      }
    } catch (e) {
      errorMessage = 'Failed to start recording: $e';
      update();
    }
  }

  // Stop voice recording and send
  Future<void> stopVoiceRecording() async {
    if (currentChatRoom == null || currentRecordingPath == null) return;

    try {
      final path = await _audioRecorder.stop();
      if (path == null) return;

      isSendingMessage = true;
      update();

      // Upload audio to Firebase Storage
      final downloadUrl = await _repository.uploadMediaFile(
        currentChatRoom!.roomId,
        path,
        currentRecordingPath!,
        'audio/m4a',
      );

      // Send message with audio URL
      final user = currentUser;
      if (user != null) {
        final message = Message(
          messageId: _uuid.v4(),
          text: 'Voice message',
          senderId: user.uid,
          type: 'audio',
          createdAt: DateTime.now(),
          readBy: [user.uid],
          mediaUrl: downloadUrl,
        );

        await _repository.sendMessage(currentChatRoom!.roomId, message);

        // Handle quota/XP deduction
        if (userQuota != null && userQuota!.canSendMessage) {
          await fetchUserQuota();
        } else if (user.xpPoints > 0) {
          await _deductXPForMessage(user.uid);
          await refreshUserDataAndChat();
        }
      }

      currentRecordingPath = null;
    } catch (e) {
      errorMessage = e.toString();
    }

    isSendingMessage = false;
    update();
  }

  // Add reaction to message
  Future<void> addReaction(String messageId, String emoji) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      await _repository.addReactionToMessage(
        currentChatRoom!.roomId,
        messageId,
        user.uid,
        emoji,
      );
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create a poll
  Future<void> createPoll(String question, List<String> options) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      final poll = Poll(
        pollId: _uuid.v4(),
        question: question,
        options: options,
        createdBy: user.uid,
        createdAt: DateTime.now(),
        votes: {},
        userVotes: {},
      );

      await _repository.createPoll(currentChatRoom!.roomId, poll);
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Vote on poll
  Future<void> voteOnPoll(String pollId, String option) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      await _repository.voteOnPoll(currentChatRoom!.roomId, pollId, user.uid, option);
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Report message
  Future<void> reportMessage(String messageId, String reason) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      await _repository.reportMessage(currentChatRoom!.roomId, messageId, user.uid, reason);
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Add extra quota (after watching ad)
  Future<void> addExtraQuota(int quota) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _repository.addExtraQuota(user.uid, quota);
      await fetchUserQuota();
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Deduct XP for sending message
  Future<void> _deductXPForMessage(String userId) async {
    try {
      // Deduct 1 XP point for each message
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'xpPoints': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Error deducting XP for message: $e');
    }
  }

  // Create new chat room (admin/candidate only)
  Future<void> createChatRoom(ChatRoom chatRoom) async {
    try {
      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms(); // Refresh list
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create ward-based chat room (automatic)
  Future<void> createWardChatRoom(String wardId, String cityId) async {
    final user = currentUser;
    if (user == null || (user.role != 'admin' && user.role != 'candidate')) return;

    try {
      final chatRoom = ChatRoom(
        roomId: 'ward_${cityId}_${wardId}',
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: 'Ward $wardId ($cityId) Discussion',
        description: 'Public discussion forum for Ward $wardId residents in $cityId',
      );

      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms();
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create candidate-specific chat room
  Future<void> createCandidateChatRoom(String candidateId, String candidateName) async {
    final user = currentUser;
    if (user == null || user.uid != candidateId) return;

    try {
      final chatRoom = ChatRoom(
        roomId: 'candidate_$candidateId',
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: '$candidateName Updates',
        description: 'Official updates and discussions with $candidateName',
      );

      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms();
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create private conversation
  Future<void> createPrivateChatRoom(String otherUserId, String roomName) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final roomId = 'private_${user.uid}_$otherUserId';
      final chatRoom = ChatRoom(
        roomId: roomId,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'private',
        members: [user.uid, otherUserId],
        title: roomName,
        description: 'Private conversation',
      );

      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms();
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Get or create ward room for current user
  Future<void> ensureWardRoomExists() async {
    try {
      // Fetch complete user data from Firestore
      final user = await getCompleteUserData();
      if (user == null) {
        print('❌ No user found for ward room creation');
        return;
      }

      if (user.wardId.isEmpty || user.cityId.isEmpty) {
        print('⚠️ User profile incomplete - wardId or cityId missing');
        return;
      }

      print('🔍 Checking ward room for user: ${user.name}, ward: ${user.wardId}, city: ${user.cityId}');

      // Check if ward room exists
      final wardRoomId = 'ward_${user.cityId}_${user.wardId}';
      final existingRooms = await _repository.getChatRoomsForUser(user.uid, user.role);
      final wardRoomExists = existingRooms.any((room) => room.roomId == wardRoomId);

      if (wardRoomExists) {
        print('✅ Ward room already exists: $wardRoomId');
        return;
      }

      print('🏗️ Creating new ward room: $wardRoomId');

      // Get city and ward names for better display
      final cityName = await _getCityName(user.cityId);
      final wardName = await _getWardName(user.cityId, user.wardId);

      // Create ward room if it doesn't exist
      final chatRoom = ChatRoom(
        roomId: wardRoomId,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: cityName.isNotEmpty ? cityName : user.cityId.toUpperCase(),
        description: wardName.isNotEmpty ? wardName : 'Ward ${user.wardId}',
      );

      await _repository.createChatRoom(chatRoom);
      print('✅ Ward room created successfully: $wardRoomId');

      // Refresh chat rooms list
      await fetchChatRooms();

    } catch (e) {
      print('❌ Failed to ensure ward room exists: $e');
    }
  }

  // Get city name from city ID
  Future<String> _getCityName(String cityId) async {
    try {
      final cityDoc = await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityId)
          .get();

      if (cityDoc.exists) {
        final data = cityDoc.data();
        return data?['name'] ?? cityId.toUpperCase();
      }
    } catch (e) {
      print('Error fetching city name: $e');
    }
    return cityId.toUpperCase();
  }

  // Get ward name from city ID and ward ID
  Future<String> _getWardName(String cityId, String wardId) async {
    try {
      final wardDoc = await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityId)
          .collection('wards')
          .doc(wardId)
          .get();

      if (wardDoc.exists) {
        final data = wardDoc.data();
        return data?['name'] ?? 'Ward $wardId';
      }
    } catch (e) {
      print('Error fetching ward name: $e');
    }
    return 'Ward $wardId';
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    final user = currentUser;
    if (user == null) return 0;

    return await _repository.getUnreadMessageCount(user.uid);
  }

  // Initialize sample data (for testing/admin purposes)
  Future<void> initializeSampleData() async {
    try {
      isLoading = true;
      update();

      final initializer = ChatInitializer();
      await initializer.initializeAll();

      // Refresh chat rooms after initialization
      await fetchChatRooms();

      Get.snackbar(
        'Success',
        'Sample chat rooms and messages created successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      errorMessage = e.toString();
      Get.snackbar(
        'Error',
        'Failed to initialize sample data: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }

    isLoading = false;
    update();
  }

  // Clear current chat
  void clearCurrentChat() {
    currentChatRoom = null;
    messages = [];
    messagesStream.value = [];
    update();
  }

  // Clear error
  void clearError() {
    errorMessage = null;
    update();
  }

  // Refresh user data and reinitialize chat (call after profile completion)
  Future<void> refreshUserDataAndChat() async {
    print('🔄 Refreshing user data and chat after profile completion');
    _isInitialLoadComplete = false; // Reset flag for fresh load
    await _initializeChat();
  }

  // Manual refresh of chat rooms (for debugging/admin purposes)
  Future<void> refreshChatRooms() async {
    print('🔄 Manual refresh of chat rooms requested');
    _isInitialLoadComplete = false; // Reset flag
    await fetchChatRooms();
  }

  // Check if user can send message
  bool get canSendMessage {
    // First check user quota
    if (userQuota != null && userQuota!.canSendMessage) {
      return true;
    }

    // If quota exhausted, check XP balance
    final user = currentUser;
    if (user != null && user.xpPoints > 0) {
      return true;
    }

    // Allow if quota not loaded yet (fallback)
    if (userQuota == null) return true;

    return false;
  }

  // Get remaining messages (integrate with XP system)
  int get remainingMessages {
    // First try to get from user quota
    if (userQuota != null) {
      return userQuota!.remainingMessages;
    }

    // If no quota data, use XP balance as fallback
    // Each XP point = 1 message
    final user = currentUser;
    if (user != null && user.xpPoints > 0) {
      return user.xpPoints;
    }

    // Default fallback
    return 20;
  }

  // Watch rewarded ad for XP
  Future<void> watchRewardedAdForXP() async {
    final adMobService = Get.find<AdMobService>();

    if (!adMobService.isAdAvailable) {
      Get.snackbar(
        'Ad Not Ready',
        'Please wait for the ad to load or try again later.',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      return;
    }

    try {
      // Show loading dialog
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading rewarded ad...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Show the rewarded ad and wait for reward
      final rewardXP = await adMobService.showRewardedAd();

      // Close loading dialog
      Get.back();

      if (rewardXP != null && rewardXP > 0) {
        // Award XP to user
        await _awardXPFromAd(rewardXP);

        Get.snackbar(
          '🎉 Reward Earned!',
          'You earned $rewardXP XP for watching the ad!',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 4),
        );

        // Refresh user data to show updated XP
        await refreshUserDataAndChat();
      } else {
        Get.snackbar(
          'No Reward',
          'Ad was shown but no reward was earned.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
        );
      }

    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to show ad: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Award XP from watching ad
  Future<void> _awardXPFromAd(int xpAmount) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Use MonetizationRepository to handle XP transaction
      final monetizationRepo = MonetizationRepository();

      // Create XP transaction and update balance
      await monetizationRepo.updateUserXPBalance(user.uid, xpAmount);

    } catch (e) {
      print('Error awarding XP from ad: $e');
    }
  }
}