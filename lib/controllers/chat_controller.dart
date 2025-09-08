import 'dart:async';
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

  // Cached complete user data
  UserModel? _cachedUser;

  // Current user (returns cached complete data or fallback)
  UserModel? get currentUser => _cachedUser ?? _getCurrentUser();

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
    // Clear any stale cached data first
    clearUserCache();

    final user = await getCompleteUserData();
    if (user != null) {
      print('🚀 Initializing chat for user: ${user.name} (${user.role}) - UID: ${user.uid}');
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
      roleSelected: false,
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
        final completeUser = UserModel(
          uid: data['uid'] ?? firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'Unknown',
          phone: data['phone'] ?? firebaseUser.phoneNumber ?? '',
          email: data['email'] ?? firebaseUser.email,
          role: data['role'] ?? 'voter',
          roleSelected: data['roleSelected'] ?? false,
          wardId: data['wardId'] ?? '',
          cityId: data['cityId'] ?? '',
          xpPoints: data['xpPoints'] ?? 0,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          photoURL: data['photoURL'] ?? firebaseUser.photoURL,
        );

        // Cache the complete user data
        _cachedUser = completeUser;
        print('✅ Cached complete user data: XP=${completeUser.xpPoints}');

        return completeUser;
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
    print('👂 Starting message listener for room: $roomId');

    _repository.getMessagesForRoom(roomId).listen((messagesList) {
      print('📨 Received ${messagesList.length} messages for room $roomId');

      // Filter out deleted messages
      final activeMessages = messagesList.where((msg) => !(msg.isDeleted ?? false)).toList();
      print('   Active messages: ${activeMessages.length} (filtered ${messagesList.length - activeMessages.length} deleted)');

      // Debug: Print message details
      for (var msg in activeMessages) {
        print('   Message: "${msg.text}" by ${msg.senderId} at ${msg.createdAt} (deleted: ${msg.isDeleted})');
      }

      messages = activeMessages;
      messagesStream.value = activeMessages;

      // Mark messages as read
      _markUnreadMessagesAsRead();

      update(); // Force UI update
    }, onError: (error) {
      print('❌ Error in message listener: $error');
    }, onDone: () {
      print('🔚 Message listener completed for room: $roomId');
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
    if (text.trim().isEmpty || currentChatRoom == null) {
      print('❌ Cannot send message: empty text or no chat room selected');
      return;
    }

    final user = currentUser;
    if (user == null) {
      print('❌ Cannot send message: user is null');
      return;
    }

    print('📤 Attempting to send message: "${text.trim()}"');
    print('   User: ${user.name} (${user.uid})');
    print('   Room: ${currentChatRoom!.roomId}');
    print('   Can send: $canSendMessage');
    print('   XP balance: ${user.xpPoints}');

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

      print('💾 Sending message to Firestore...');
      await _repository.sendMessage(currentChatRoom!.roomId, message);
      print('✅ Message sent successfully to Firestore');

      // Handle quota/XP deduction ONLY after successful message send
      if (userQuota != null && userQuota!.canSendMessage) {
        print('📊 Using regular quota for message');
        // Use regular quota
        await fetchUserQuota();
      } else if (user.xpPoints > 0) {
        print('💰 Using XP for message (XP before: ${user.xpPoints})');
        // Use XP points (1 XP = 1 message)
        await _deductXPForMessage(user.uid);
        await refreshUserDataAndChat(); // Refresh to get updated XP
        print('✅ XP deducted successfully');
      } else {
        print('❌ No quota or XP available for message');
        Get.snackbar(
          'Cannot Send Message',
          'You have no remaining messages or XP. Please watch an ad to earn XP.',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 4),
        );
      }

    } catch (e) {
      print('❌ Failed to send message: $e');
      errorMessage = e.toString();

      Get.snackbar(
        'Message Failed',
        'Failed to send message. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
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
  Future<void> createPoll(String question, List<String> options, {DateTime? expiresAt}) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      print('📊 Creating poll: "$question" with ${options.length} options${expiresAt != null ? ', expires at: $expiresAt' : ', no expiration'}');

      final poll = Poll.create(
        pollId: _uuid.v4(),
        question: question,
        options: options,
        createdBy: user.uid,
        expiresAt: expiresAt,
      );

      // Create the poll in Firestore
      await _repository.createPoll(currentChatRoom!.roomId, poll);
      print('✅ Poll created successfully: ${poll.pollId}');

      // Create a message to announce the poll in chat
      final pollMessage = Message(
        messageId: _uuid.v4(),
        text: '📊 ${question}',
        senderId: user.uid,
        type: 'poll',
        createdAt: DateTime.now(),
        readBy: [user.uid],
        metadata: {'pollId': poll.pollId}, // Store poll reference
      );

      print('💬 Creating poll announcement message...');
      await _repository.sendMessage(currentChatRoom!.roomId, pollMessage);
      print('✅ Poll announcement message sent');

    } catch (e) {
      print('❌ Error creating poll: $e');
      errorMessage = e.toString();
      update();

      Get.snackbar(
        'Poll Creation Failed',
        'Failed to create poll. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Vote on poll
  Future<void> voteOnPoll(String pollId, String option) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _repository.voteOnPoll(pollId, user.uid, option);
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

  // Delete message (mark as deleted)
  Future<void> deleteMessage(String messageId) async {
    final user = currentUser;
    if (user == null || currentChatRoom == null) return;

    try {
      print('🗑️ Attempting to delete message: $messageId');

      // Check if user is admin or message sender
      final message = messages.firstWhereOrNull((msg) => msg.messageId == messageId);
      if (message == null) {
        print('❌ Message not found: $messageId');
        return;
      }

      // Allow deletion if user is admin or message sender
      if (user.role == 'admin' || message.senderId == user.uid) {
        await _repository.deleteMessage(currentChatRoom!.roomId, messageId);
        print('✅ Message marked as deleted: $messageId');

        Get.snackbar(
          'Message Deleted',
          'Message has been deleted',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      } else {
        print('❌ User not authorized to delete message');
        Get.snackbar(
          'Permission Denied',
          'You can only delete your own messages',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
      print('❌ Error deleting message: $e');
      errorMessage = e.toString();
      update();

      Get.snackbar(
        'Delete Failed',
        'Failed to delete message. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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

      // Refresh cached user data to reflect XP changes
      await getCompleteUserData();

      // Force UI update for all listeners (including profile screen)
      update();

      print('💰 XP deducted for message. Updated cached XP: ${_cachedUser?.xpPoints ?? 0}');
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

  // Clear cached user data (call when user logs out or switches)
  void clearUserCache() {
    print('🧹 Clearing cached user data');
    _cachedUser = null;
    userQuota = null;
    userQuotaStream.value = null;
    // Clear chat data as well
    chatRooms = [];
    chatRoomsStream.value = [];
    currentChatRoom = null;
    messages = [];
    messagesStream.value = [];
    _isInitialLoadComplete = false;
    update();
  }

  // Handle user authentication state change (call from auth controller)
  Future<void> handleAuthStateChange() async {
    print('🔐 Handling authentication state change');
    clearUserCache();
    await _initializeChat();
  }

  // Force refresh user data (for debugging/manual refresh)
  Future<void> forceRefreshUserData() async {
    print('🔄 Force refreshing user data');
    _cachedUser = null;
    await getCompleteUserData();
    await fetchUserQuota();
    update();
  }

  // Refresh user data and reinitialize chat (call after profile completion)
  Future<void> refreshUserDataAndChat() async {
    print('🔄 Refreshing user data and chat after profile completion');
    _isInitialLoadComplete = false; // Reset flag for fresh load

    // Clear cached user data to force refresh
    _cachedUser = null;

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
    final user = currentUser;

    // Debug logging for troubleshooting
    print('🔍 Checking canSendMessage:');
    print('   Current user: ${user?.name ?? 'null'} (UID: ${user?.uid ?? 'null'})');
    print('   User XP: ${user?.xpPoints ?? 'null'}');
    print('   User quota loaded: ${userQuota != null}');
    print('   Quota can send: ${userQuota?.canSendMessage ?? 'null'}');
    print('   Quota remaining: ${userQuota?.remainingMessages ?? 'null'}');

    // First check user quota
    if (userQuota != null && userQuota!.canSendMessage) {
      print('   ✅ Can send: Using quota');
      return true;
    }

    // If quota exhausted, check XP balance
    if (user != null && user.xpPoints > 0) {
      print('   ✅ Can send: Using XP (${user.xpPoints} available)');
      return true;
    }

    // Allow if quota not loaded yet (fallback)
    if (userQuota == null) {
      print('   ⚠️ Can send: Quota not loaded yet (fallback)');
      return true;
    }

    print('   ❌ Cannot send: No quota or XP available');
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
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      print('🎬 Starting rewarded ad flow');

      // Show loading dialog with timeout
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
                'Please wait while we prepare your ad',
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

      // Show the rewarded ad and wait for reward with timeout
      print('🎬 Showing rewarded ad...');

      // Create a timeout future that will complete after 15 seconds
      final timeoutCompleter = Completer<int?>();
      final timeoutFuture = Future.delayed(const Duration(seconds: 15), () {
        print('⏰ Ad operation timeout reached');
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete(null); // Complete with null to indicate timeout
        }
        // Close loading dialog
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      });

      final adFuture = adMobService.showRewardedAd().then((result) {
        // If ad completes before timeout, cancel the timeout
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete(result);
        }
        return result;
      }).catchError((error) {
        print('❌ Error in ad future: $error');
        if (!timeoutCompleter.isCompleted) {
          timeoutCompleter.complete(null);
        }
        // Close loading dialog
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        return null;
      });

      // Wait for either the ad to complete or timeout
      final rewardXP = await timeoutCompleter.future;

      // Close loading dialog if still open (double check)
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      print('🎯 Ad result: rewardXP = $rewardXP');

      if (rewardXP != null && rewardXP > 0) {
        print('🎯 Ad completed, attempting to award $rewardXP XP');

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
          await refreshUserDataAndChat();
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
        print('⚠️ Ad was shown but no reward was earned - this might be normal for test ads');

        // For test ads, still award some XP as fallback
        if (adMobService.isTestAdUnit()) {
          print('🧪 Test ad detected, awarding fallback XP');
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
            await refreshUserDataAndChat();
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
      print('❌ Error in rewarded ad flow: $e');

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

  // Award XP from watching ad
  Future<bool> _awardXPFromAd(int xpAmount) async {
    final user = currentUser;
    if (user == null) {
      print('❌ Cannot award XP: user is null');
      return false;
    }

    try {
      print('🏆 Attempting to award $xpAmount XP to user: ${user.uid}');

      // Use MonetizationRepository to handle XP transaction
      final monetizationRepo = MonetizationRepository();

      // Create XP transaction and update balance
      await monetizationRepo.updateUserXPBalance(user.uid, xpAmount);

      // Immediately refresh cached user data to reflect XP changes
      await getCompleteUserData();

      // Force UI update for all listeners (including profile screen)
      update();

      print('✅ Successfully awarded $xpAmount XP to user: ${user.uid}');
      print('   Updated cached XP: ${_cachedUser?.xpPoints ?? 0}');
      return true;

    } catch (e) {
      print('❌ Error awarding XP from ad: $e');
      print('   Error details: ${e.toString()}');
      return false;
    }
  }

  // Get ad debug information
  Map<String, dynamic> getAdDebugInfo() {
    final adMobService = Get.find<AdMobService>();
    return adMobService.getAdDebugInfo();
  }

  // Force close any stuck dialogs (for emergency use)
  void forceCloseDialogs() {
    int closedCount = 0;
    while (Get.isDialogOpen ?? false) {
      Get.back();
      closedCount++;
    }
    if (closedCount > 0) {
      Get.snackbar(
        'Dialogs Closed',
        'Closed $closedCount stuck dialog(s)',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'No Dialogs',
        'No stuck dialogs found',
        backgroundColor: Colors.grey.shade100,
        colorText: Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Check dialog status
  bool get hasOpenDialog => Get.isDialogOpen ?? false;

  // Debug method to check user XP status
  void debugUserXPStatus() {
    final user = currentUser;
    final firebaseUser = _auth.currentUser;

    print('🔍 User XP Debug Info:');
    print('   Firebase Auth User: ${firebaseUser?.displayName ?? 'null'} (${firebaseUser?.uid ?? 'null'})');
    print('   Current user: ${user?.name ?? 'null'} (${user?.uid ?? 'null'})');
    print('   Cached user: ${_cachedUser?.name ?? 'null'} (${_cachedUser?.uid ?? 'null'})');
    print('   User XP (cached): ${_cachedUser?.xpPoints ?? 'null'}');
    print('   User XP (current): ${user?.xpPoints ?? 'null'}');
    print('   Can send message: $canSendMessage');
    print('   Remaining messages: $remainingMessages');
    print('   User quota loaded: ${userQuota != null}');
    print('   Quota can send: ${userQuota?.canSendMessage ?? 'null'}');
    print('   User role: ${user?.role ?? 'null'}');

    // Check if there's a mismatch between Firebase Auth and cached user
    if (firebaseUser != null && _cachedUser != null && firebaseUser.uid != _cachedUser!.uid) {
      print('   ⚠️ MISMATCH DETECTED: Firebase UID (${firebaseUser.uid}) != Cached UID (${_cachedUser!.uid})');
    }

    Get.snackbar(
      'XP Debug Info',
      'XP: ${user?.xpPoints ?? 0}, Can Send: $canSendMessage',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 5),
    );
  }

  // Force refresh messages (for debugging)
  void forceRefreshMessages() {
    if (currentChatRoom != null) {
      print('🔄 Force refreshing messages for room: ${currentChatRoom!.roomId}');
      // Re-initialize the message listener
      _listenToMessages(currentChatRoom!.roomId);
      update();

      Get.snackbar(
        'Messages Refreshed',
        'Message list has been refreshed',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'No Chat Room',
        'Please select a chat room first',
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Refresh current chat messages (called after poll voting)
  void refreshCurrentChatMessages() {
    if (currentChatRoom != null) {
      print('🔄 Refreshing messages after poll vote for room: ${currentChatRoom!.roomId}');
      // Force a refresh of the message stream
      _listenToMessages(currentChatRoom!.roomId);
    }
  }

  // Debug all chat status
  void debugChatStatus() {
    print('🔍 Chat Debug Info:');
    print('   Current room: ${currentChatRoom?.roomId ?? 'null'}');
    print('   Messages count: ${messages.length}');
    print('   Is sending: $isSendingMessage');
    print('   Can send: $canSendMessage');
    print('   Remaining messages: $remainingMessages');

    debugUserXPStatus();
  }
}