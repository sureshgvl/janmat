import 'dart:async';
import 'dart:io';
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
import '../services/background_initializer.dart';

class ChatController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  // State variables
  List<ChatRoom> chatRooms = [];
  List<ChatRoomDisplayInfo> chatRoomDisplayInfos = []; // Rooms with unread info
  ChatRoom? currentChatRoom;
  List<Message> messages = [];
  UserQuota? userQuota;
  bool isLoading = false;
  bool isSendingMessage = false;
  String? errorMessage;
  String? currentRecordingPath;
  bool _isInitialLoadComplete = false; // Flag to prevent real-time override during initial load

  // Unread message tracking
  final Map<String, int> _unreadCounts = {}; // roomId -> unread count
  final Map<String, DateTime> _lastMessageTimes = {}; // roomId -> last message time
  final Map<String, String> _lastMessagePreviews = {}; // roomId -> last message preview
  final Map<String, String> _lastMessageSenders = {}; // roomId -> last message sender

  // Message caching for performance optimization
  final Map<String, List<Message>> _messageCache = {}; // roomId -> messages
  final Map<String, DateTime> _messageCacheTimestamps = {}; // roomId -> last cache time
  static const Duration _cacheValidityDuration = Duration(minutes: 5); // Cache valid for 5 minutes

  // Reactive variables for real-time updates
  var chatRoomsStream = Rx<List<ChatRoom>>([]);
  var chatRoomDisplayInfosStream = Rx<List<ChatRoomDisplayInfo>>([]); // Display info with unread counts
  var messagesStream = Rx<List<Message>>([]);
  var userQuotaStream = Rx<UserQuota?>(null);

  // Cached complete user data
  UserModel? _cachedUser;

  // Flag to prevent repeated debug logging
  bool _canSendMessageLogged = false;

  // Current user (returns cached complete data or fallback)
  UserModel? get currentUser {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    // ⚠️ WARNING: This fallback should rarely be used
    // If this is called frequently, it means user data is not being cached properly
    debugPrint('⚠️ FALLBACK: Using incomplete user data - this indicates caching issue');
    return _getCurrentUser();
  }

  // Unread count management methods
  void _incrementUnreadCount(String roomId, Message message) {
    final user = currentUser;
    if (user == null || currentChatRoom?.roomId == roomId) return; // Don't count if user is in the room

    _unreadCounts[roomId] = (_unreadCounts[roomId] ?? 0) + 1;
    _lastMessageTimes[roomId] = message.createdAt;
    _lastMessagePreviews[roomId] = _getMessagePreview(message);
    _lastMessageSenders[roomId] = message.senderId;

    _updateChatRoomDisplayInfos();
    debugPrint('📨 Unread count for room $roomId: ${_unreadCounts[roomId]}');
  }

  void _resetUnreadCount(String roomId) {
    _unreadCounts[roomId] = 0;
    _updateChatRoomDisplayInfos();
    debugPrint('✅ Reset unread count for room $roomId');
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case 'image':
        return '📷 Image';
      case 'audio':
        return '🎵 Voice message';
      case 'poll':
        return '📊 Poll';
      default:
        return message.text.length > 50
            ? '${message.text.substring(0, 50)}...'
            : message.text;
    }
  }

  void _updateChatRoomDisplayInfos() {
    chatRoomDisplayInfos = chatRooms.map((room) {
      return ChatRoomDisplayInfo(
        room: room,
        unreadCount: _unreadCounts[room.roomId] ?? 0,
        lastMessageTime: _lastMessageTimes[room.roomId],
        lastMessagePreview: _lastMessagePreviews[room.roomId],
        lastMessageSender: _lastMessageSenders[room.roomId],
      );
    }).toList();

    // Sort by last message time (newest first)
    chatRoomDisplayInfos.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.room.createdAt;
      final bTime = b.lastMessageTime ?? b.room.createdAt;
      return bTime.compareTo(aTime);
    });

    chatRoomDisplayInfosStream.value = chatRoomDisplayInfos;
  }

  @override
  void onInit() {
    super.onInit();
    // Clean up expired repository cache on app start (fast operation)
    clearExpiredRepositoryCache();

    // Firebase is now available synchronously, so we can initialize immediately
    // but we'll still defer heavy operations to when chat is actually accessed
    debugPrint('📱 ChatController initialized - Firebase ready');
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }

  // Lazy initialization - called when chat is actually accessed
  Future<void> initializeChatIfNeeded() async {
    // Only initialize if not already done
    if (_cachedUser != null || isLoading) return;

    debugPrint('🚀 Starting zero-frame chat initialization');

    // Use background initializer for zero-frame chat setup
    final backgroundInit = BackgroundInitializer();
    await backgroundInit.initializeServiceWithZeroFrames(
      'Chat Services',
      () => _initializeChat(),
    );

    debugPrint('✅ Chat initialized with zero frames');
  }

  // Initialize chat for current user
  Future<void> _initializeChat() async {
    // Clear any stale cached data first
    clearUserCache();

    // Clean up any expired message caches from previous sessions
    _clearExpiredCaches();

    try {
      debugPrint('📦 BATCH: Initializing chat with batch operations');

      // Get current user ID
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        debugPrint('❌ No Firebase Auth user - cannot initialize chat');
        return;
      }

      // Use batch operation to get all required data
      final userData = await _repository.getUserDataAndQuota(firebaseUser.uid);
      final user = userData['user'] as UserModel?;
      final quota = userData['quota'] as UserQuota?;

      if (user != null) {
        // Cache the user data immediately to prevent fallback usage
        _cachedUser = user;
        userQuota = quota;
        userQuotaStream.value = quota;

        debugPrint('🚀 Initializing chat for user: ${user.name} (${user.role}) - UID: ${user.uid}');
        debugPrint('💬 Chat initialized - User can send messages: $canSendMessage');

        // Use batch operation for remaining data
        final appData = await _repository.initializeAppData(
          user.uid,
          user.role,
          cityId: user.cityId,
          wardId: user.wardId
        );

        // Update local state with batch results
        chatRooms = appData['rooms'] as List<ChatRoom>;
        chatRoomsStream.value = chatRooms;

        debugPrint('✅ BATCH: Chat initialized with ${chatRooms.length} rooms');

        // Ensure ward room exists for users with complete profiles (both voters and candidates)
        if ((user.role == 'voter' || user.role == 'candidate') && user.wardId.isNotEmpty && user.cityId.isNotEmpty) {
          debugPrint('🏛️ BREAKPOINT FALLBACK-1: Ensuring ward room exists for ${user.role}: ward_${user.cityId}_${user.wardId}');
          debugPrint('🏛️ BREAKPOINT FALLBACK-1: User details - Name: ${user.name}, Role: ${user.role}, Ward: ${user.wardId}, City: ${user.cityId}');
          ensureWardRoomExists();
        } else if (user.role == 'voter' || user.role == 'candidate') {
          debugPrint('⚠️ BREAKPOINT FALLBACK-2: ${user.role} profile incomplete - missing ward or city info');
          debugPrint('⚠️ BREAKPOINT FALLBACK-2: User details - Name: ${user.name}, Ward: ${user.wardId}, City: ${user.cityId}');
        } else {
          debugPrint('🏛️ BREAKPOINT FALLBACK-3: User is not a voter or candidate - Role: ${user.role}');
        }
      } else {
        debugPrint('❌ CRITICAL: Failed to get complete user data from Firestore');
        debugPrint('   This will cause issues with user roles, XP, and premium status');
        debugPrint('   The app will fall back to incomplete Firebase Auth data');
        debugPrint('   ⚠️ WARNING: User data will be incomplete (no role, XP, premium status)');
      }
    } catch (e) {
      debugPrint('❌ BATCH: Failed to initialize chat with batch operations: $e');
      debugPrint('   Falling back to individual operations...');

      // Fallback to original initialization method
      await _initializeChatFallback();
    }
  }

  // Fallback initialization method (original logic)
  Future<void> _initializeChatFallback() async {
    final user = await getCompleteUserData();
    if (user != null) {
      // Cache the user data immediately to prevent fallback usage
      _cachedUser = user;

      debugPrint('🚀 Initializing chat (fallback) for user: ${user.name} (${user.role}) - UID: ${user.uid}');
      debugPrint('💬 Chat initialized - User can send messages: $canSendMessage');
      fetchUserQuota();
      fetchChatRooms();

      // Ensure ward room exists for users with complete profiles (both voters and candidates)
      if ((user.role == 'voter' || user.role == 'candidate') && user.wardId.isNotEmpty && user.cityId.isNotEmpty) {
        debugPrint('🏛️ BREAKPOINT INIT-1: Ensuring ward room exists for ${user.role}: ward_${user.cityId}_${user.wardId}');
        debugPrint('🏛️ BREAKPOINT INIT-1: User details - Name: ${user.name}, Role: ${user.role}, Ward: ${user.wardId}, City: ${user.cityId}');
        ensureWardRoomExists();
      } else if (user.role == 'voter' || user.role == 'candidate') {
        debugPrint('⚠️ BREAKPOINT INIT-2: ${user.role} profile incomplete - missing ward or city info');
        debugPrint('⚠️ BREAKPOINT INIT-2: User details - Name: ${user.name}, Ward: ${user.wardId}, City: ${user.cityId}');
      } else {
        debugPrint('🏛️ BREAKPOINT INIT-3: User is not a voter or candidate - Role: ${user.role}');
      }
    } else {
      debugPrint('❌ CRITICAL: Failed to get complete user data from Firestore');
      debugPrint('   This will cause issues with user roles, XP, and premium status');
      debugPrint('   The app will fall back to incomplete Firebase Auth data');

      // Try to get basic user info as fallback, but warn about the limitations
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        debugPrint('   Firebase Auth user available: ${firebaseUser.displayName ?? 'Unknown'}');
        debugPrint('   ⚠️ WARNING: User data will be incomplete (no role, XP, premium status)');
      } else {
        debugPrint('   ❌ No Firebase Auth user either - chat will not work properly');
      }
    }
  }

  // Get current user from Firebase Auth and Firestore
  UserModel? _getCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // ⚠️ WARNING: This method returns incomplete user data
    // It should only be used as a last resort when Firestore data is unavailable
    // The proper way is to use getCompleteUserData() which fetches from Firestore
    debugPrint('⚠️ WARNING: Using fallback user data - this should be avoided!');
    debugPrint('   Consider calling getCompleteUserData() instead for complete user info');

    return UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Unknown',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email,
      role: 'voter', // Default role - INCORRECT for actual users
      roleSelected: false,
      profileCompleted: false,
      wardId: '', // Will be updated after profile completion
      cityId: '', // Will be updated after profile completion
      xpPoints: 0, // INCORRECT - actual users have XP
      premium: false, // INCORRECT - actual users may be premium
      createdAt: DateTime.now(),
      photoURL: firebaseUser.photoURL,
    );
  }

  // Fetch complete user data from Firestore (with smart caching)
  Future<UserModel?> getCompleteUserData() async {
    // First check if we already have cached data
    if (_cachedUser != null) {
      debugPrint('⚡ CACHE HIT: Returning cached user data for ${_cachedUser!.name}');
      return _cachedUser;
    }

    debugPrint('🔄 CACHE MISS: Fetching fresh user data from Firestore');

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
          profileCompleted: data['profileCompleted'] ?? false,
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
        debugPrint('✅ Cached complete user data: XP=${completeUser.xpPoints}');

        return completeUser;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
    }

    debugPrint('⚠️ Falling back to basic Firebase Auth data');
    return _getCurrentUser(); // Fallback to basic data
  }

  // Fetch chat rooms for current user
  Future<void> fetchChatRooms() async {
    // Ensure chat is initialized before fetching rooms
    await initializeChatIfNeeded();

    final user = currentUser;

    // BREAKPOINT FETCH-1: Start of fetchChatRooms
    debugPrint('🔍 BREAKPOINT FETCH-1: Starting fetchChatRooms()');
    debugPrint('🔍 BREAKPOINT FETCH-1: Current user - Name: ${user?.name}, UID: ${user?.uid}, Role: ${user?.role}');

    if (user == null) {
      debugPrint('❌ BREAKPOINT FETCH-2: No user found, returning early');
      return;
    }

    isLoading = true;
    errorMessage = null;
    _isInitialLoadComplete = false; // Reset flag during fetch
    update();

    try {
      // BREAKPOINT FETCH-3: Before repository call
      debugPrint('🔍 BREAKPOINT FETCH-3: Calling repository.getChatRoomsForUser()');
      debugPrint('🔍 BREAKPOINT FETCH-3: Parameters - UID: ${user.uid}, Role: ${user.role}, City: ${user.cityId}, Ward: ${user.wardId}');

      chatRooms = await _repository.getChatRoomsForUser(
        user.uid,
        user.role,
        cityId: user.cityId,
        wardId: user.wardId
      );

      // BREAKPOINT FETCH-4: After repository call
      debugPrint('🔍 BREAKPOINT FETCH-4: Repository returned ${chatRooms.length} rooms');
      chatRooms.forEach((room) => debugPrint('   Room: ${room.roomId} - ${room.title} (${room.type})'));

      chatRoomsStream.value = chatRooms;

      // Initialize display info with current unread counts
      _updateChatRoomDisplayInfos();

      debugPrint('📋 Loaded ${chatRooms.length} chat rooms for ${user.role}');

      // Mark initial load as complete
      _isInitialLoadComplete = true;

      // Start listening for real-time room changes (deletions, updates)
      _listenForRoomChanges(user.uid, user.role);
    } catch (e) {
      errorMessage = e.toString();
      chatRooms = [];
      chatRoomsStream.value = [];
      chatRoomDisplayInfos = [];
      chatRoomDisplayInfosStream.value = [];
      _isInitialLoadComplete = true; // Even on error, mark as complete
    debugPrint('❌ BREAKPOINT FETCH-5: Failed to load chat rooms: $e');
    }

    isLoading = false;
    update();

    // BREAKPOINT FETCH-6: End of fetchChatRooms
    debugPrint('🔍 BREAKPOINT FETCH-6: fetchChatRooms() completed - Total rooms: ${chatRooms.length}');
  }

  // Listen for real-time room changes (deletions, updates)
  void _listenForRoomChanges(String userId, String userRole) {
    // Use a filtered query based on user role to avoid permission issues
    // This prevents trying to read rooms the user doesn't have access to

    Query query = FirebaseFirestore.instance.collection('chats');

    if (userRole != 'admin') {
      // Non-admin users can only see public rooms
      query = query.where('type', isEqualTo: 'public');
    }

    query.snapshots().listen((snapshot) async {
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
      debugPrint('🆕 New chat rooms available: ${addedRooms.length}');
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

  // Fetch user quota (with smart caching)
  Future<void> fetchUserQuota() async {
    final user = currentUser;
    if (user == null) return;

    // Check if we already have quota data and it's recent
    if (userQuota != null) {
      debugPrint('⚡ CACHE HIT: Using cached quota data');
      userQuotaStream.value = userQuota;
      _canSendMessageLogged = false;
      update();
      return;
    }

    debugPrint('🔄 CACHE MISS: Fetching fresh quota data from Firestore');

    try {
      userQuota = await _repository.getUserQuota(user.uid);

      // If no quota exists, create a default one
      if (userQuota == null) {
        debugPrint('📊 No quota found, creating default quota for user: ${user.uid}');
        final newQuota = UserQuota(
          userId: user.uid,
          lastReset: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await _repository.updateUserQuota(newQuota);
        userQuota = newQuota;
        debugPrint('✅ Default quota created: ${userQuota!.remainingMessages} messages remaining');
      }

      userQuotaStream.value = userQuota;
      // Reset the logging flag when quota is loaded
      _canSendMessageLogged = false;
      debugPrint('📊 User quota loaded: ${userQuota?.remainingMessages ?? 0} messages remaining');
      update();
    } catch (e) {
      debugPrint('❌ Failed to fetch user quota: $e');
    }
  }

  // Select a chat room
  void selectChatRoom(ChatRoom chatRoom) {
    currentChatRoom = chatRoom;

    // Reset unread count for this room
    _resetUnreadCount(chatRoom.roomId);

    // Check if we have cached messages for this room
    if (_hasValidCachedMessages(chatRoom.roomId)) {
      // Use cached messages
      messages = List.from(_messageCache[chatRoom.roomId]!);
      messagesStream.value = messages;
      final cacheAge = DateTime.now().difference(_messageCacheTimestamps[chatRoom.roomId]!);
      debugPrint('⚡ CACHE HIT: Using cached messages for room: ${chatRoom.title} (${messages.length} messages, ${cacheAge.inSeconds}s old)');

      // Start listening for real-time updates (only new messages)
      _listenToMessages(chatRoom.roomId, useCache: true);
    } else {
      // No valid cache, fetch from Firebase
      messages = [];
      messagesStream.value = [];
      debugPrint('🔄 CACHE MISS: Selected chat room: ${chatRoom.title} (${chatRoom.roomId}) - fetching from Firebase');

      // Start listening to messages
      _listenToMessages(chatRoom.roomId, useCache: false);
    }

    update();
  }

  // Check if we have valid cached messages for a room
  bool _hasValidCachedMessages(String roomId) {
    if (!_messageCache.containsKey(roomId) || !_messageCacheTimestamps.containsKey(roomId)) {
      return false;
    }

    final cacheTime = _messageCacheTimestamps[roomId]!;
    final now = DateTime.now();
    final isCacheValid = now.difference(cacheTime) < _cacheValidityDuration;

    if (!isCacheValid) {
      // Clean up expired cache
      _messageCache.remove(roomId);
      _messageCacheTimestamps.remove(roomId);
      debugPrint('🗑️ Cleaned up expired cache for room: $roomId');
    }

    return isCacheValid;
  }

  // Cache messages for a room
  void _cacheMessages(String roomId, List<Message> messages) {
    _messageCache[roomId] = List.from(messages);
    _messageCacheTimestamps[roomId] = DateTime.now();
    debugPrint('💾 Cached ${messages.length} messages for room: $roomId');
  }

  // Listen to messages in real-time
  void _listenToMessages(String roomId, {bool useCache = false}) {
    debugPrint('👂 Starting message listener for room: $roomId (useCache: $useCache)');

    _repository.getMessagesForRoom(roomId).listen((messagesList) {
    final cacheStatus = useCache ? ' (cache hit)' : ' (from Firebase)';
    debugPrint('📨 Received ${messagesList.length} messages for room $roomId$cacheStatus');

      // Filter out deleted messages
      final activeMessages = messagesList.where((msg) => !(msg.isDeleted ?? false)).toList();
      debugPrint('   Active messages: ${activeMessages.length} (filtered ${messagesList.length - activeMessages.length} deleted)');

      // Debug: Print message details (only first few for performance)
      for (var i = 0; i < activeMessages.length && i < 3; i++) {
        final msg = activeMessages[i];
        debugPrint('   Message ${i + 1}: "${msg.text.length > 50 ? msg.text.substring(0, 50) + '...' : msg.text}" by ${msg.senderId}');
      }

      // Check for new messages and increment unread counts
      final previousMessageCount = _messageCache[roomId]?.length ?? 0;
      final newMessages = activeMessages.length - previousMessageCount;

      if (newMessages > 0 && activeMessages.isNotEmpty) {
        // Increment unread count for new messages
        for (int i = previousMessageCount; i < activeMessages.length; i++) {
          _incrementUnreadCount(roomId, activeMessages[i]);
        }
      }

      // Cache the messages for future use
      _cacheMessages(roomId, activeMessages);

      messages = activeMessages;
      messagesStream.value = activeMessages;

      // Mark messages as read (only if user is currently in this room)
      if (currentChatRoom?.roomId == roomId) {
        _markUnreadMessagesAsRead();
      }

      update(); // Force UI update
    }, onError: (error) {
      debugPrint('❌ Error in message listener: $error');
    }, onDone: () {
      debugPrint('🔚 Message listener completed for room: $roomId');
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
    debugPrint('❌ Cannot send message: empty text or no chat room selected');
      return;
    }

    final user = currentUser;
    if (user == null) {
    debugPrint('❌ Cannot send message: user is null');
      return;
    }

    // Check if user can send message before proceeding
    if (!canSendMessage) {
    debugPrint('❌ Cannot send message: insufficient quota or XP');
      Get.snackbar(
        'Cannot Send Message',
        'You have no remaining messages or XP. Please watch an ad to earn XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Debug logging (only in debug mode)
    assert(() {
    debugPrint('📤 Attempting to send message: "${text.trim()}"');
    debugPrint('   User: ${user.name} (${user.uid})');
    debugPrint('   Room: ${currentChatRoom!.roomId}');
    debugPrint('   Can send: $canSendMessage');
    debugPrint('   XP balance: ${user.xpPoints}');
      return true;
    }());

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

      // Determine if we should use quota or XP
      final useQuota = userQuota != null && userQuota!.canSendMessage;
      final useXP = !useQuota && user.xpPoints > 0;

      // Use batch operation to send message and update quota/XP together
      debugPrint('📦 Using batch operation for message + quota/XP update');
      final result = await _repository.sendMessageWithQuotaUpdate(
        currentChatRoom!.roomId,
        message,
        user.uid,
        useQuota,
        useXP
      );

      // Update local quota if it was modified
      if (result['quota'] != null) {
        userQuota = result['quota'] as UserQuota?;
        userQuotaStream.value = userQuota;
      }

      // If XP was used, refresh user data
      if (useXP) {
        await getCompleteUserData();
        // Invalidate repository cache since user data changed
        _repository.invalidateUserCache(user.uid);
      }

      debugPrint('✅ Message sent with batch operation');

    } catch (e) {
    debugPrint('❌ Failed to send message: $e');
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

  // Send image message (with batch operations)
  Future<void> sendImageMessage() async {
    if (currentChatRoom == null) return;

    // Check if user can send message before proceeding
    if (!canSendMessage) {
    debugPrint('❌ Cannot send image: insufficient quota or XP');
      Get.snackbar(
        'Cannot Send Message',
        'You have no remaining messages or XP. Please watch an ad to earn XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      // Check image file size (5MB limit)
      final file = File(pickedFile.path);
      final fileSize = await file.length();
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSizeInBytes) {
        Get.snackbar(
          'Error',
          'Image size must be less than 5MB. Please select a smaller image.',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isSendingMessage = true;
      update();

      // Upload image to Firebase Storage
      final downloadUrl = await _repository.uploadMediaFile(
        currentChatRoom!.roomId,
        pickedFile.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
        'image/jpeg',
      );

      // Send message with image URL using batch operation
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

        // Determine if we should use quota or XP
        final useQuota = userQuota != null && userQuota!.canSendMessage;
        final useXP = !useQuota && user.xpPoints > 0;

        // Use batch operation to send message and update quota/XP together
        debugPrint('📦 Using batch operation for image message + quota/XP update');
        final result = await _repository.sendMessageWithQuotaUpdate(
          currentChatRoom!.roomId,
          message,
          user.uid,
          useQuota,
          useXP
        );

        // Update local quota if it was modified
        if (result['quota'] != null) {
          userQuota = result['quota'] as UserQuota?;
          userQuotaStream.value = userQuota;
          debugPrint('📊 Local quota updated: ${userQuota!.remainingMessages} messages remaining');
        } else if (useQuota) {
          // If quota was used but not returned, refresh from database
          debugPrint('🔄 Quota used but not returned, refreshing from database');
          await fetchUserQuota();
        }

        // If XP was used, refresh user data
        if (useXP) {
          await getCompleteUserData();
          // Invalidate repository cache since user data changed
          _repository.invalidateUserCache(user.uid);
        }

        debugPrint('✅ Image message sent with batch operation');
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

    // Check if user can send message before proceeding
    if (!canSendMessage) {
    debugPrint('❌ Cannot send voice message: insufficient quota or XP');
      Get.snackbar(
        'Cannot Send Message',
        'You have no remaining messages or XP. Please watch an ad to earn XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      );
      return;
    }

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

        // Determine if we should use quota or XP
        final useQuota = userQuota != null && userQuota!.canSendMessage;
        final useXP = !useQuota && user.xpPoints > 0;

        // Use batch operation to send message and update quota/XP together
        debugPrint('📦 Using batch operation for voice message + quota/XP update');
        final result = await _repository.sendMessageWithQuotaUpdate(
          currentChatRoom!.roomId,
          message,
          user.uid,
          useQuota,
          useXP
        );

        // Update local quota if it was modified
        if (result['quota'] != null) {
          userQuota = result['quota'] as UserQuota?;
          userQuotaStream.value = userQuota;
          debugPrint('📊 Local quota updated: ${userQuota!.remainingMessages} messages remaining');
        } else if (useQuota) {
          // If quota was used but not returned, refresh from database
          debugPrint('🔄 Quota used but not returned, refreshing from database');
          await fetchUserQuota();
        }

        // If XP was used, refresh user data
        if (useXP) {
          await getCompleteUserData();
          // Invalidate repository cache since user data changed
          _repository.invalidateUserCache(user.uid);
        }

        debugPrint('✅ Voice message sent with batch operation');
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
    debugPrint('📊 Creating poll: "$question" with ${options.length} options${expiresAt != null ? ', expires at: $expiresAt' : ', no expiration'}');

      final poll = Poll.create(
        pollId: _uuid.v4(),
        question: question,
        options: options,
        createdBy: user.uid,
        expiresAt: expiresAt,
      );

      // Create the poll in Firestore
      await _repository.createPoll(currentChatRoom!.roomId, poll);
    debugPrint('✅ Poll created successfully: ${poll.pollId}');

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

    debugPrint('💬 Creating poll announcement message...');
      await _repository.sendMessage(currentChatRoom!.roomId, pollMessage);
    debugPrint('✅ Poll announcement message sent');

    } catch (e) {
    debugPrint('❌ Error creating poll: $e');
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
    debugPrint('🗑️ Attempting to delete message: $messageId');

      // Check if user is admin or message sender
      final message = messages.firstWhereOrNull((msg) => msg.messageId == messageId);
      if (message == null) {
      debugPrint('❌ Message not found: $messageId');
        return;
      }

      // Allow deletion if user is admin or message sender
      if (user.role == 'admin' || message.senderId == user.uid) {
        await _repository.deleteMessage(currentChatRoom!.roomId, messageId);
      debugPrint('✅ Message marked as deleted: $messageId');

        Get.snackbar(
          'Message Deleted',
          'Message has been deleted',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      } else {
      debugPrint('❌ User not authorized to delete message');
        Get.snackbar(
          'Permission Denied',
          'You can only delete your own messages',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
        );
      }
    } catch (e) {
    debugPrint('❌ Error deleting message: $e');
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
      // No need to invalidate cache here since quota changes don't affect room visibility
      await fetchUserQuota();
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Get repository cache statistics
  Map<String, dynamic> getRepositoryCacheStats() {
    return _repository.getCacheStats();
  }

  // Manually clear expired repository cache
  void clearExpiredRepositoryCache() {
    _repository.clearExpiredCache();
  }

  // Force refresh all cached data (for debugging/admin purposes)
  Future<void> forceRefreshAllData() async {
    debugPrint('🔄 Force refreshing all cached data');

    // Clear all caches
    clearUserCache();
    clearExpiredRepositoryCache();
    clearAllMessageCaches();

    // Re-initialize everything
    await _initializeChat();

    Get.snackbar(
      'Data Refreshed',
      'All cached data has been refreshed from server',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 3),
    );
  }

  // Get comprehensive cache statistics
  Map<String, dynamic> getComprehensiveCacheStats() {
    final repoStats = getRepositoryCacheStats();

    return {
      'controller_cache': {
        'user_cached': _cachedUser != null,
        'quota_cached': userQuota != null,
        'message_cache_count': _messageCache.length,
        'chat_rooms_cached': chatRooms.length,
      },
      'repository_cache': repoStats,
      'total_cached_items': (_messageCache.length + chatRooms.length + (repoStats['total_entries'] as int? ?? 0)),
    };
  }

  // Deduct XP for sending message
  Future<void> _deductXPForMessage(String userId) async {
    try {
      // Deduct 1 XP point for each message
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'xpPoints': FieldValue.increment(-1),
      });

      // Invalidate repository cache since user data changed
      _repository.invalidateUserCache(userId);

      // Refresh cached user data to reflect XP changes
      await getCompleteUserData();

      // Force UI update for all listeners (including profile screen)
      update();

    debugPrint('💰 XP deducted for message. Updated cached XP: ${_cachedUser?.xpPoints ?? 0}');
    } catch (e) {
    debugPrint('Error deducting XP for message: $e');
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
    if (user == null) return;

    try {
      final chatRoom = ChatRoom(
        roomId: 'ward_${cityId}_$wardId',
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: 'Ward $wardId ($cityId) Discussion',
        description: 'Public discussion forum for Ward $wardId residents in $cityId',
      );

      await _repository.createChatRoom(chatRoom);
      print('✅ Ward chat room created: ${chatRoom.roomId}');
      await fetchChatRooms();
      print('📋 Refreshed chat rooms after ward room creation');
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


    print('🏗️ Creating candidate chat room for $candidateName');
      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms();
    print('✅ Candidate chat room created and chat rooms refreshed');
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
    // BREAKPOINT 1: Start of ward room creation
    debugPrint('🔍 BREAKPOINT 1: Starting ensureWardRoomExists()');

    try {
      // Use cached user data if available and complete, otherwise fetch from Firestore
      UserModel? user = currentUser;

      // BREAKPOINT 2: Check user data availability
      debugPrint('🔍 BREAKPOINT 2: Current user data - Name: ${user?.name}, UID: ${user?.uid}, Role: ${user?.role}');
      debugPrint('🔍 BREAKPOINT 2: Ward ID: ${user?.wardId}, City ID: ${user?.cityId}');

      // If cached user data is incomplete (missing ward/city), fetch fresh data
      if (user == null || user.wardId.isEmpty || user.cityId.isEmpty) {
        debugPrint('🔄 Cached user data incomplete, fetching fresh data...');
        user = await getCompleteUserData();

        // BREAKPOINT 3: After fetching fresh user data
        debugPrint('🔍 BREAKPOINT 3: Fresh user data - Name: ${user?.name}, Ward: ${user?.wardId}, City: ${user?.cityId}');
      }

      if (user == null) {
      debugPrint('❌ No user found for ward room creation');
        return;
      }

      if (user.wardId.isEmpty || user.cityId.isEmpty) {
      debugPrint('⚠️ User profile incomplete - wardId or cityId missing');
        return;
      }

    debugPrint('🔍 Checking ward room for user: ${user.name}, ward: ${user.wardId}, city: ${user.cityId}');

      // Check if ward room exists
      final wardRoomId = 'ward_${user.cityId}_${user.wardId}';

      // BREAKPOINT 4: Before checking existing rooms
      debugPrint('🔍 BREAKPOINT 4: Checking for existing ward room: $wardRoomId');

      final existingRooms = await _repository.getChatRoomsForUser(
        user.uid,
        user.role,
        cityId: user.cityId,
        wardId: user.wardId
      );

      // BREAKPOINT 5: After fetching existing rooms
      debugPrint('🔍 BREAKPOINT 5: Found ${existingRooms.length} existing rooms');
      existingRooms.forEach((room) => debugPrint('   Room: ${room.roomId} - ${room.title}'));

      final wardRoomExists = existingRooms.any((room) => room.roomId == wardRoomId);

      // BREAKPOINT 6: Ward room existence check result
      debugPrint('🔍 BREAKPOINT 6: Ward room exists: $wardRoomExists');

      if (wardRoomExists) {
      debugPrint('✅ Ward room already exists: $wardRoomId');
        return;
      }

    debugPrint('🏗️ Creating new ward room: $wardRoomId');

      // Get city and ward names for better display
      final cityName = await _getCityName(user.cityId);
      final wardName = await _getWardName(user.cityId, user.wardId);

      // BREAKPOINT 7: Before creating chat room
      debugPrint('🔍 BREAKPOINT 7: Creating ward room - City: $cityName, Ward: $wardName');

      // Create ward room if it doesn't exist
      final chatRoom = ChatRoom(
        roomId: wardRoomId,
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: cityName.isNotEmpty ? cityName : user.cityId.toUpperCase(),
        description: wardName.isNotEmpty ? wardName : 'Ward ${user.wardId}',
      );

      // BREAKPOINT 8: Before repository call
      debugPrint('🔍 BREAKPOINT 8: Calling repository.createChatRoom()');

      await _repository.createChatRoom(chatRoom);

      // BREAKPOINT 9: After successful creation
      debugPrint('✅ BREAKPOINT 9: Ward room created successfully: $wardRoomId');

      // Refresh chat rooms list
      await fetchChatRooms();

      // BREAKPOINT 10: After refresh
      debugPrint('✅ BREAKPOINT 10: Chat rooms refreshed after ward room creation');

    } catch (e) {
    debugPrint('❌ Failed to ensure ward room exists: $e');
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
    debugPrint('Error fetching city name: $e');
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
    debugPrint('Error fetching ward name: $e');
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

  // Clear message cache for a specific room
  void _clearMessageCache(String roomId) {
    _messageCache.remove(roomId);
    _messageCacheTimestamps.remove(roomId);
    debugPrint('🗑️ Cleared message cache for room: $roomId');
  }

  // Clear all expired message caches
  void _clearExpiredCaches() {
    final now = DateTime.now();
    final expiredRoomIds = <String>[];

    _messageCacheTimestamps.forEach((roomId, timestamp) {
      if (now.difference(timestamp) >= _cacheValidityDuration) {
        expiredRoomIds.add(roomId);
      }
    });

    for (final roomId in expiredRoomIds) {
      _clearMessageCache(roomId);
    }

    if (expiredRoomIds.isNotEmpty) {
      debugPrint('🧹 Cleared ${expiredRoomIds.length} expired message caches');
    }
  }

  // Clear error
  void clearError() {
    errorMessage = null;
    update();
  }

  // Clear cached user data (call when user logs out or switches)
  void clearUserCache() {
    debugPrint('🧹 Clearing cached user data');
    _cachedUser = null;
    userQuota = null;
    userQuotaStream.value = null;
    // Reset logging flag
    _canSendMessageLogged = false;
    // Clear chat data as well
    chatRooms = [];
    chatRoomsStream.value = [];
    chatRoomDisplayInfos = [];
    chatRoomDisplayInfosStream.value = [];
    currentChatRoom = null;
    messages = [];
    messagesStream.value = [];
    _isInitialLoadComplete = false;

    // Clear all message caches
    _messageCache.clear();
    _messageCacheTimestamps.clear();

    // Clear unread count tracking
    _unreadCounts.clear();
    _lastMessageTimes.clear();
    _lastMessagePreviews.clear();
    _lastMessageSenders.clear();

    debugPrint('🗑️ Cleared all message caches and unread counts');

    update();
  }

  // Handle user authentication state change (call from auth controller)
  Future<void> handleAuthStateChange() async {
  debugPrint('🔐 Handling authentication state change');
    clearUserCache();
    // Clear repository cache for the current user
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _repository.invalidateUserCache(currentUser.uid);
    }
    await _initializeChat();
  }

  // Force refresh user data (for debugging/manual refresh)
  Future<void> forceRefreshUserData() async {
  debugPrint('🔄 Force refreshing user data');
    _cachedUser = null;
    await getCompleteUserData();
    await fetchUserQuota();
    update();
  }

  // Refresh user data and reinitialize chat (call after profile completion)
  Future<void> refreshUserDataAndChat() async {
  debugPrint('🔄 Refreshing user data and chat after profile completion');
    _isInitialLoadComplete = false; // Reset flag for fresh load

    // Clear cached user data to force refresh
    _cachedUser = null;

    // Clear repository cache since user data changed
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _repository.invalidateUserCache(currentUser.uid);
    }

    await _initializeChat();
  }

  // Manual refresh of chat rooms (for debugging/admin purposes)
  Future<void> refreshChatRooms() async {
  debugPrint('🔄 Manual refresh of chat rooms requested');
    _isInitialLoadComplete = false; // Reset flag
    await fetchChatRooms();
  }

  // Check if user can send message
  bool get canSendMessage {
    final user = currentUser;

    //user is premium
    if (user != null && user.premium) {
      return true;
    }

    // First check user quota
    if (userQuota != null && userQuota!.canSendMessage) {
      return true;
    }

    // If no quota exists, assume user can send (quota will be created on first message)
    if (userQuota == null && user != null) {
      return true;
    }

    // If quota exhausted, check XP balance
    if (user != null && user.xpPoints > 0) {
      return true;
    }

    // If all checks fail, user cannot send messages
    return false;
  }

  // Check if user should see watch ads button
  bool get shouldShowWatchAdsButton {
    final user = currentUser;

    // Don't show if user is premium (they can always send)
    if (user != null && user.premium) {
      return false;
    }

    // Show if user cannot send messages (no quota and no XP)
    return !canSendMessage;
  }

  // Get remaining messages (integrate with XP system)
  int get remainingMessages {
    // First try to get from user quota
    if (userQuota != null) {
      return userQuota!.remainingMessages;
    }

    // If no quota data, try to create default quota immediately
    final user = currentUser;
    if (user != null) {
      // Create default quota synchronously if possible
      userQuota = UserQuota(
        userId: user.uid,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );
      // Update stream for UI
      userQuotaStream.value = userQuota;
      debugPrint('📊 Created default quota: ${userQuota!.remainingMessages} messages remaining');
      return userQuota!.remainingMessages;
    }

    // If no quota data, use XP balance as fallback
    // Each XP point = 1 message
    if (user != null && user.xpPoints > 0) {
      return user.xpPoints;
    }

    // Default fallback
    return 20; // Return default daily limit instead of 0
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
    debugPrint('🎬 Starting rewarded ad flow');

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
    debugPrint('🎬 Showing rewarded ad...');

      // Create a timeout future that will complete after 15 seconds
      final timeoutCompleter = Completer<int?>();
      final timeoutFuture = Future.delayed(const Duration(seconds: 15), () {
      debugPrint('⏰ Ad operation timeout reached');
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
      debugPrint('❌ Error in ad future: $error');
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

    debugPrint('🎯 Ad result: rewardXP = $rewardXP');

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
      debugPrint('⚠️ Ad was shown but no reward was earned - this might be normal for test ads');

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

  // Award XP from watching ad
  Future<bool> _awardXPFromAd(int xpAmount) async {
    final user = currentUser;
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

  debugPrint('🔍 User XP Debug Info:');
  debugPrint('   Firebase Auth User: ${firebaseUser?.displayName ?? 'null'} (${firebaseUser?.uid ?? 'null'})');
  debugPrint('   Current user: ${user?.name ?? 'null'} (${user?.uid ?? 'null'})');
  debugPrint('   Cached user: ${_cachedUser?.name ?? 'null'} (${_cachedUser?.uid ?? 'null'})');
  debugPrint('   User XP (cached): ${_cachedUser?.xpPoints ?? 'null'}');
  debugPrint('   User XP (current): ${user?.xpPoints ?? 'null'}');
  debugPrint('   Can send message: $canSendMessage');
  debugPrint('   Remaining messages: $remainingMessages');
  debugPrint('   User quota loaded: ${userQuota != null}');
  debugPrint('   Quota can send: ${userQuota?.canSendMessage ?? 'null'}');
  debugPrint('   User role: ${user?.role ?? 'null'}');

    // Check if there's a mismatch between Firebase Auth and cached user
    if (firebaseUser != null && _cachedUser != null && firebaseUser.uid != _cachedUser!.uid) {
    debugPrint('   ⚠️ MISMATCH DETECTED: Firebase UID (${firebaseUser.uid}) != Cached UID (${_cachedUser!.uid})');
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
    debugPrint('🔄 Force refreshing messages for room: ${currentChatRoom!.roomId}');
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
    debugPrint('🔄 Refreshing messages after poll vote for room: ${currentChatRoom!.roomId}');
      // Force a refresh of the message stream
      _listenToMessages(currentChatRoom!.roomId);
    }
  }

  // Debug all chat status
  void debugChatStatus() {
    debugPrint('🔍 Chat Debug Info:');
    debugPrint('   Current room: ${currentChatRoom?.roomId ?? 'null'}');
    debugPrint('   Messages count: ${messages.length}');
    debugPrint('   Is sending: $isSendingMessage');
    debugPrint('   Can send: $canSendMessage');
    debugPrint('   Remaining messages: $remainingMessages');

    // Debug cache info
    debugPrint('   📊 Cache Info:');
    debugPrint('     Cached rooms: ${_messageCache.length}');
    _messageCache.forEach((roomId, cachedMessages) {
      final timestamp = _messageCacheTimestamps[roomId];
      final age = timestamp != null ? DateTime.now().difference(timestamp) : null;
      debugPrint('     Room $roomId: ${cachedMessages.length} messages, age: ${age?.inSeconds ?? 'unknown'}s');
    });

    debugUserXPStatus();
  }

  // Manually clear all message caches (for debugging)
  void clearAllMessageCaches() {
    final cacheCount = _messageCache.length;
    _messageCache.clear();
    _messageCacheTimestamps.clear();
    debugPrint('🗑️ Manually cleared $cacheCount message caches');

    Get.snackbar(
      'Cache Cleared',
      'Cleared $cacheCount message caches',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 2),
    );
  }
}