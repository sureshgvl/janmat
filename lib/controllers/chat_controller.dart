import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
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
  bool isRecording = false; // Track recording state
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

  // Cache for sender information to avoid repeated database calls
  final Map<String, Map<String, dynamic>> _senderInfoCache = {};

  // Flag to prevent repeated debug logging
  bool _canSendMessageLogged = false;

  // Real-time listener management
  StreamSubscription<QuerySnapshot>? _roomChangesSubscription;

  // Current user (returns cached complete data or fetches from Firestore)
  UserModel? get currentUser {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    // ⚠️ WARNING: This fallback should rarely be used
    // If this is called frequently, it means user data is not being cached properly
    debugPrint('⚠️ FALLBACK: Using incomplete user data - this indicates caching issue');

    // Instead of using incomplete Firebase Auth data, try to fetch complete data
    // This will prevent role detection issues
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      // Try to get complete user data from Firestore asynchronously
      // Don't block the UI - let it return basic data first
      getCompleteUserData().then((user) {
        if (user != null) {
          final previousRole = _cachedUser?.role ?? 'unknown';
          _cachedUser = user;
          debugPrint('✅ Fetched complete user data in fallback: ${user.name} (${user.role})');

          // Check if role changed and restart real-time listener if needed
          if (previousRole != user.role && _isInitialLoadComplete) {
            debugPrint('🔄 User role changed from $previousRole to ${user.role}, restarting real-time listener');
            _restartRealTimeListener();
          }

          update(); // Trigger UI update with complete data
        }
      }).catchError((e) {
        debugPrint('❌ Failed to fetch complete user data in fallback: $e');
      });
    }

    // Return basic Firebase Auth data as temporary fallback
    return _getCurrentUser();
  }

  // Unread count management methods
  void _incrementUnreadCount(String roomId, Message message) {
    final user = currentUser;
    if (user == null) {
      debugPrint('⚠️ Cannot increment unread count: user is null');
      return;
    }

    // Don't count if user is currently in this room
    if (currentChatRoom?.roomId == roomId) {
      debugPrint('📨 Skipping unread count increment - user is in room: $roomId');
      return;
    }

    // Don't count user's own messages
    if (message.senderId == user.uid) {
      debugPrint('📨 Skipping unread count increment - own message in room: $roomId');
      return;
    }

    // Increment unread count
    final currentCount = _unreadCounts[roomId] ?? 0;
    _unreadCounts[roomId] = currentCount + 1;

    // Update last message info
    _lastMessageTimes[roomId] = message.createdAt;
    _lastMessagePreviews[roomId] = _getMessagePreview(message);
    _lastMessageSenders[roomId] = message.senderId;

    // Update display info (UI update will be handled by debounced timer)
    _updateChatRoomDisplayInfos();

    debugPrint('📨 Unread count incremented for room $roomId: ${currentCount + 1}');
  }

  void _resetUnreadCount(String roomId) {
    final previousCount = _unreadCounts[roomId] ?? 0;
    _unreadCounts[roomId] = 0;
    _updateChatRoomDisplayInfos();
    update(); // Force UI update
    debugPrint('✅ Reset unread count for room $roomId: $previousCount → 0');
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
    _roomChangesSubscription?.cancel();
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
          districtId: user.districtId,
          bodyId: user.bodyId,
          wardId: user.wardId,
          area: user.area
        );

        // Update local state with batch results
        chatRooms = appData['rooms'] as List<ChatRoom>;
        chatRoomsStream.value = chatRooms;

        debugPrint('✅ BATCH: Chat initialized with ${chatRooms.length} rooms');

        // Ensure ward room exists for candidates with complete profiles (removed voter room creation)
        final districtId = user.districtId; // Use districtId
        if (user.role == 'candidate' &&
            user.wardId.isNotEmpty &&
            (user.bodyId?.isNotEmpty ?? false) &&
            (districtId?.isNotEmpty ?? false)) {
          debugPrint('🏛️ BREAKPOINT FALLBACK-1: Ensuring ward room exists for ${user.role}: ward_${districtId}_${user.wardId}');
          debugPrint('🏛️ BREAKPOINT FALLBACK-1: User details - Name: ${user.name}, Role: ${user.role}, Ward: ${user.wardId}, District: $districtId');
          ensureWardRoomExists();
        } else if (user.role == 'candidate') {
          debugPrint('⚠️ BREAKPOINT FALLBACK-2: ${user.role} profile incomplete - missing ward or district info');
          debugPrint('⚠️ BREAKPOINT FALLBACK-2: User details - Name: ${user.name}, Ward: ${user.wardId}, District: $districtId');
        } else {
          debugPrint('🏛️ BREAKPOINT FALLBACK-3: User is not a candidate - Role: ${user.role}');
        }

        // Ensure area room exists for users with area field
        if (user.area != null && user.area!.isNotEmpty) {
          debugPrint('🏠 BREAKPOINT AREA-1: Ensuring area room exists for user with area: ${user.area}');
          ensureAreaRoomExists();
        } else {
          debugPrint('🏠 BREAKPOINT AREA-2: User has no area field or area is empty');
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

      // Ensure ward room exists for candidates with complete profiles (removed voter room creation)
      final districtId = user.districtId; // Use districtId
      if (user.role == 'candidate' &&
          user.wardId.isNotEmpty &&
          (user.bodyId?.isNotEmpty ?? false) &&
          (districtId?.isNotEmpty ?? false)) {
        debugPrint('🏛️ BREAKPOINT INIT-1: Ensuring ward room exists for ${user.role}: ward_${districtId}_${user.wardId}');
        debugPrint('🏛️ BREAKPOINT INIT-1: User details - Name: ${user.name}, Role: ${user.role}, Ward: ${user.wardId}, District: $districtId');
        ensureWardRoomExists();
      } else if (user.role == 'candidate') {
        debugPrint('⚠️ BREAKPOINT INIT-2: ${user.role} profile incomplete - missing ward or district info');
        debugPrint('⚠️ BREAKPOINT INIT-2: User details - Name: ${user.name}, Ward: ${user.wardId}, District: $districtId');
      } else {
        debugPrint('🏛️ BREAKPOINT INIT-3: User is not a candidate - Role: ${user.role}');
      }

      // Ensure area room exists for users with area field
      if (user.area != null && user.area!.isNotEmpty) {
        debugPrint('🏠 BREAKPOINT AREA-INIT-1: Ensuring area room exists for user with area: ${user.area}');
        ensureAreaRoomExists();
      } else {
        debugPrint('🏠 BREAKPOINT AREA-INIT-2: User has no area field or area is empty');
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
      districtId: '', // Will be updated after profile completion
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
          districtId: data['districtId'] ?? '',
          bodyId: data['bodyId'] ?? '',
          area: data['area'], // Keep area as nullable
          xpPoints: data['xpPoints'] ?? 0,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          photoURL: data['photoURL'] ?? firebaseUser.photoURL,
        );

        // Cache the complete user data
        _cachedUser = completeUser;
        debugPrint('✅ Cached complete user data: Role=${completeUser.role}, Area=${completeUser.area}, XP=${completeUser.xpPoints}');

        return completeUser;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user data: $e');
    }

    debugPrint('⚠️ Falling back to basic Firebase Auth data');
    return _getCurrentUser(); // Fallback to basic data
  }

  // Get user data synchronously from cache (no Firebase call)
  UserModel? getUserDataFromCache() {
    return _cachedUser;
  }

  // Fetch sender information for displaying in message bubbles
  Future<Map<String, dynamic>?> getSenderInfo(String senderId) async {
    // Check cache first
    if (_senderInfoCache.containsKey(senderId)) {
      return _senderInfoCache[senderId];
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        final senderInfo = {
          'name': data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'voter',
          'districtId': data['districtId'],
          'bodyId': data['bodyId'],
          'wardId': data['wardId'],
        };

        // Cache the sender info
        _senderInfoCache[senderId] = senderInfo;
        return senderInfo;
      }
    } catch (e) {
      debugPrint('Error fetching sender info for $senderId: $e');
    }

    return null;
  }

  // Clear sender info cache when user data changes
  void clearSenderInfoCache() {
    _senderInfoCache.clear();
    debugPrint('🧹 Cleared sender info cache');
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
      final districtId = user.districtId; // Use districtId
      debugPrint('🔍 BREAKPOINT FETCH-3: Parameters - UID: ${user.uid}, Role: ${user.role}, District: $districtId, Body: ${user.bodyId}, Ward: ${user.wardId}');

      chatRooms = await _repository.getChatRoomsForUser(
        user.uid,
        user.role,
        districtId: user.districtId, // Use districtId
        bodyId: user.bodyId,
        wardId: user.wardId,
        area: user.area
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
    // Cancel existing subscription if any
    _roomChangesSubscription?.cancel();

    // Use a filtered query based on user role to avoid permission issues
    // This prevents trying to read rooms the user doesn't have access to

    Query query = FirebaseFirestore.instance.collection('chats');

    if (userRole != 'admin') {
      // Non-admin users can only see public rooms
      query = query.where('type', isEqualTo: 'public');
    }

    _roomChangesSubscription = query.snapshots().listen((snapshot) async {
      await _handleAllRoomChanges(snapshot, userId, userRole);
    });

    debugPrint('👂 Started real-time listener for user role: $userRole');
  }

  // Restart real-time listener when user role changes
  void _restartRealTimeListener() {
    final user = currentUser;
    if (user == null) return;

    debugPrint('🔄 Restarting real-time listener for user: ${user.name} (${user.role})');

    // Clear existing unread counts to prevent stale data
    _unreadCounts.clear();
    _lastMessageTimes.clear();
    _lastMessagePreviews.clear();
    _lastMessageSenders.clear();

    // Restart the listener with correct role
    _listenForRoomChanges(user.uid, user.role);

    // Refresh chat rooms to ensure consistency
    fetchChatRooms();
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

    // Get current user data for location-based filtering
    final user = currentUser;
    if (user == null) {
      debugPrint('⚠️ No user data available for real-time room filtering');
      return;
    }

    // Always use the current user role, not the role passed to this method
    // This ensures real-time updates use the most current role information
    final currentUserRole = user.role;
    if (currentUserRole != userRole) {
      debugPrint('🔄 User role changed during real-time update ($userRole -> $currentUserRole), using current role');
    }

    // Apply the same filtering logic as getChatRoomsForUser
    final accessibleRooms = allRooms.where((room) {
      // Public rooms are accessible to all authenticated users
      if (room.type == 'public') {
        // For candidates, apply strict location-based filtering
        if (currentUserRole == 'candidate') {
          final isOwnRoom = room.createdBy == userId;
          final isWardRoom = user.districtId != null && user.bodyId != null && user.wardId != null &&
                            room.roomId == 'ward_${user.districtId}_${user.bodyId}_${user.wardId}';
          final isAreaRoom = user.districtId != null && user.bodyId != null && user.wardId != null && user.area != null &&
                            room.roomId == 'area_${user.districtId}_${user.bodyId}_${user.wardId}_${user.area}';

          // For candidates, include all area rooms in their district/body, not just their specific location
          final isAnyAreaRoom = user.districtId != null && user.bodyId != null && user.wardId != null &&
                               room.roomId.startsWith('area_${user.districtId}_${user.bodyId}_${user.wardId}_');

          // Only include rooms that are relevant to this candidate's location
          return isOwnRoom || isWardRoom || isAreaRoom || isAnyAreaRoom;
        }
        // For voters, apply location-based filtering
        else if (currentUserRole == 'voter') {
          if (user.districtId != null && user.bodyId != null && user.wardId != null) {
            final wardRoomId = 'ward_${user.districtId}_${user.bodyId}_${user.wardId}';
            final areaRoomId = user.area != null ? 'area_${user.districtId}_${user.bodyId}_${user.wardId}_${user.area}' : null;

            // Include ward room
            if (room.roomId == wardRoomId) {
              return true;
            }

            // Include area room if user has area
            if (areaRoomId != null && room.roomId == areaRoomId) {
              return true;
            }

            // Include rooms created by followed candidates in the same ward
            // For real-time updates, we'll include candidate rooms that match the pattern
            if (room.roomId.startsWith('candidate_')) {
              return true; // Include all candidate rooms for now (could be optimized)
            }
          } else {
            // No location data - only show general public rooms
            return !room.roomId.startsWith('ward_') &&
                   !room.roomId.startsWith('area_') &&
                   !room.roomId.startsWith('candidate_');
          }
        }
        // For admins, include all public rooms
        else if (currentUserRole == 'admin') {
          return true;
        }
        return false;
      }

      // Private rooms are only accessible to members
      if (room.type == 'private') {
        return room.members?.contains(userId) ?? false;
      }

      // For candidates and admins, they can also access rooms they created
      if (currentUserRole == 'candidate' || currentUserRole == 'admin') {
        return room.createdBy == userId;
      }

      return false;
    }).toList();

    // Sort rooms by creation date (newest first)
    accessibleRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Remove duplicates from accessibleRooms to prevent showing the same room multiple times
    final uniqueRooms = <String, ChatRoom>{};
    for (final room in accessibleRooms) {
      uniqueRooms[room.roomId] = room;
    }
    final deduplicatedRooms = uniqueRooms.values.toList();

    // Sort rooms by creation date (newest first)
    deduplicatedRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Only update if there are actual changes to prevent unnecessary UI updates
    final currentRoomIds = chatRooms.map((r) => r.roomId).toSet();
    final newRoomIds = deduplicatedRooms.map((r) => r.roomId).toSet();

    if (currentRoomIds != newRoomIds || chatRooms.length != deduplicatedRooms.length) {
      // Update local chat rooms list
      chatRooms = deduplicatedRooms;
      chatRoomsStream.value = deduplicatedRooms;

      // Update display info to maintain consistency
      _updateChatRoomDisplayInfos();

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

      debugPrint('📋 Real-time update: ${deduplicatedRooms.length} unique rooms (was ${chatRooms.length})');
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
    debugPrint('🏠 Selecting chat room: ${chatRoom.roomId}');

    // Set current chat room first
    currentChatRoom = chatRoom;

    // Reset unread count for this room immediately
    _resetUnreadCount(chatRoom.roomId);
    debugPrint('✅ Reset unread count for room: ${chatRoom.roomId}');

    // Update display info (UI update will be handled by debounced timer in message listener)
    _updateChatRoomDisplayInfos();

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

    // Mark all messages in this room as read immediately
    _markMessagesAsReadForRoom(chatRoom.roomId);

    // Single UI update at the end
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

    // Debounce UI updates to prevent excessive rebuilds
    Timer? _updateDebounceTimer;

    _repository.getMessagesForRoom(roomId).listen((messagesList) {
      final cacheStatus = useCache ? ' (cache hit)' : ' (from Firebase)';
      debugPrint('📨 Received ${messagesList.length} messages for room $roomId$cacheStatus');

      // Filter out deleted messages efficiently
      final activeMessages = messagesList.where((msg) => !(msg.isDeleted ?? false)).toList();

      // Early exit if no changes
      final previousMessageCount = _messageCache[roomId]?.length ?? 0;
      if (activeMessages.length == previousMessageCount && useCache) {
        debugPrint('⚡ No message changes detected, skipping update');
        return;
      }

      debugPrint('   Active messages: ${activeMessages.length} (filtered ${messagesList.length - activeMessages.length} deleted)');

      // Batch process new messages for better performance
      final newMessages = activeMessages.length - previousMessageCount;
      if (newMessages > 0 && activeMessages.isNotEmpty) {
        _processNewMessagesBatch(roomId, activeMessages, previousMessageCount);
      }

      // Cache the messages for future use
      _cacheMessages(roomId, activeMessages);

      // Update local state
      messages = activeMessages;
      messagesStream.value = activeMessages;

      // Mark messages as read (only if user is currently in this room)
      if (currentChatRoom?.roomId == roomId) {
        _markUnreadMessagesAsRead();
      }

      // Debounced UI update to prevent excessive rebuilds
      _updateDebounceTimer?.cancel();
      _updateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        update(); // Force UI update
        debugPrint('✅ UI updated for room: $roomId');
      });

    }, onError: (error) {
      debugPrint('❌ Error in message listener: $error');
    }, onDone: () {
      debugPrint('🔚 Message listener completed for room: $roomId');
      _updateDebounceTimer?.cancel();
    });
  }

  // Batch process new messages for better performance
  void _processNewMessagesBatch(String roomId, List<Message> activeMessages, int previousMessageCount) {
    final user = currentUser;
    if (user == null) return;

    // Pre-calculate if user is in current room to avoid repeated checks
    final isUserInRoom = currentChatRoom?.roomId == roomId;

    // Batch unread count updates
    int unreadIncrement = 0;
    DateTime? latestMessageTime;
    String? latestMessagePreview;
    String? latestMessageSender;

    for (int i = previousMessageCount; i < activeMessages.length; i++) {
      final message = activeMessages[i];

      // Skip own messages
      if (message.senderId == user.uid) continue;

      // Skip if user is currently in this room
      if (isUserInRoom) continue;

      // Count as unread
      unreadIncrement++;

      // Track latest message info
      if (latestMessageTime == null || message.createdAt.isAfter(latestMessageTime)) {
        latestMessageTime = message.createdAt;
        latestMessagePreview = _getMessagePreview(message);
        latestMessageSender = message.senderId;
      }
    }

    // Apply batch updates
    if (unreadIncrement > 0) {
      final currentCount = _unreadCounts[roomId] ?? 0;
      _unreadCounts[roomId] = currentCount + unreadIncrement;

      // Update last message info if we have new messages
      if (latestMessageTime != null) {
        _lastMessageTimes[roomId] = latestMessageTime;
        if (latestMessagePreview != null) {
          _lastMessagePreviews[roomId] = latestMessagePreview!;
        }
        if (latestMessageSender != null) {
          _lastMessageSenders[roomId] = latestMessageSender!;
        }
      }

      // Update display info once for the batch
      _updateChatRoomDisplayInfos();

      debugPrint('📨 Batch updated unread count for room $roomId: +$unreadIncrement (total: ${currentCount + unreadIncrement})');
    }
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

  // Mark all messages in a specific room as read
  void _markMessagesAsReadForRoom(String roomId) {
    final user = currentUser;
    if (user == null) return;

    // Get cached messages for this room
    final cachedMessages = _messageCache[roomId];
    if (cachedMessages == null) return;

    final unreadMessages = cachedMessages.where((msg) =>
      !msg.readBy.contains(user.uid) && msg.senderId != user.uid
    ).toList();

    debugPrint('📖 Marking ${unreadMessages.length} messages as read in room: $roomId');

    for (final message in unreadMessages) {
      _repository.markMessageAsRead(roomId, message.messageId, user.uid);
    }
  }

  // Send text message
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty || currentChatRoom == null) {
    debugPrint('❌ Cannot send message: empty text or no chat room selected');
      return;
    }

    // Check character limit (WhatsApp-like limit)
    if (text.length > 4096) {
      Get.snackbar(
        'Message Too Long',
        'Messages cannot exceed 4096 characters',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
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

    final messageId = _uuid.v4();

    try {
      final message = Message(
        messageId: messageId,
        text: text.trim(),
        senderId: user.uid,
        type: 'text',
        createdAt: DateTime.now(),
        readBy: [user.uid],
        status: MessageStatus.sending,
        retryCount: 0,
      );

      // OPTIMIZATION: Immediately add message to local state for instant UI feedback
      final optimisticMessages = List<Message>.from(messages)..add(message);
      messages = optimisticMessages;
      messagesStream.value = optimisticMessages;
      debugPrint('⚡ OPTIMISTIC: Added message to local state immediately');

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

      // Update message status to sent
      _updateMessageStatus(messageId, MessageStatus.sent);

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

      // Update message status to failed and show retry option
      _updateMessageStatus(messageId, MessageStatus.failed);

      errorMessage = e.toString();

      Get.snackbar(
        'Message Failed',
        'Failed to send message. Tap to retry.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
        onTap: (_) => retryMessage(messageId),
      );
    } finally {
      // Always reset the sending flag and update UI
      isSendingMessage = false;
      update();
    }
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
    } finally {
      // Always reset the sending flag and update UI
      isSendingMessage = false;
      update();
    }
  }

  // Start voice recording
  Future<void> startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Get the temporary directory for storing the recording
        final tempDir = await getTemporaryDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
        final fullPath = path.join(tempDir.path, fileName);
        currentRecordingPath = fullPath;

        debugPrint('🎤 Starting voice recording to: $fullPath');

        await _audioRecorder.start(
          const RecordConfig(),
          path: fullPath,
        );

        isRecording = true;
        update();

        debugPrint('✅ Voice recording started successfully');

        // Show recording started feedback
        Get.snackbar(
          'Recording Started',
          'Tap the mic button again to stop recording',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        );
      } else {
        debugPrint('❌ Microphone permission denied');
        Get.snackbar(
          'Permission Denied',
          'Microphone permission is required for voice recording',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to start recording: $e');
      errorMessage = 'Failed to start recording: $e';
      update();

      Get.snackbar(
        'Recording Error',
        'Failed to start voice recording. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Stop voice recording and send
  Future<void> stopVoiceRecording() async {
    if (currentChatRoom == null || currentRecordingPath == null) {
      debugPrint('❌ Cannot stop recording: missing chat room or recording path');
      return;
    }

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
      debugPrint('🛑 Stopping voice recording...');
      final recordingPath = await _audioRecorder.stop();
      if (recordingPath == null) {
        debugPrint('❌ No recording path returned from recorder');
        return;
      }

      debugPrint('✅ Recording stopped, file saved to: $recordingPath');

      // Verify the file exists and is readable
      final audioFile = File(recordingPath);
      if (!await audioFile.exists()) {
        debugPrint('❌ Recorded file does not exist: $recordingPath');
        Get.snackbar(
          'Recording Error',
          'Failed to save voice recording. Please try again.',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade800,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      final fileSize = await audioFile.length();
      debugPrint('📊 Recording file size: $fileSize bytes');

      if (fileSize == 0) {
        debugPrint('❌ Recording file is empty');
        Get.snackbar(
          'Recording Error',
          'Voice recording is empty. Please try recording again.',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isRecording = false; // Stop recording state
      isSendingMessage = true;
      update();

      // Show recording stopped feedback
      Get.snackbar(
        'Recording Stopped',
        'Sending voice message...',
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );

      // Get filename from the full path for upload
      final fileName = path.basename(recordingPath);
      debugPrint('📤 Uploading voice recording: $fileName');

      // Upload audio to Firebase Storage
      final downloadUrl = await _repository.uploadMediaFile(
        currentChatRoom!.roomId,
        recordingPath,
        fileName,
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
    } finally {
      // Always reset the sending flag and update UI
      isSendingMessage = false;
      update();
    }
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

  // Create new chat room (candidate only - removed admin support)
  Future<void> createChatRoom(ChatRoom chatRoom) async {
    final user = currentUser;
    if (user == null || user.role != 'candidate') {
      debugPrint('⚠️ Chat room creation only allowed for candidates');
      return;
    }

    try {
      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms(); // Refresh list
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create ward-based chat room (for candidates only)
  Future<void> createWardChatRoom(String wardId, String districtId) async {
    final user = currentUser;
    if (user == null || user.role != 'candidate') {
      debugPrint('⚠️ Ward room creation only allowed for candidates');
      return;
    }

    try {
      final chatRoom = ChatRoom(
        roomId: 'ward_${districtId}_$wardId',
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: 'Ward $wardId ($districtId) Discussion',
        description: 'Public discussion forum for Ward $wardId residents in $districtId',
      );

      await _repository.createChatRoom(chatRoom);
      debugPrint('✅ Ward chat room created: ${chatRoom.roomId}');
      await fetchChatRooms();
      debugPrint('📋 Refreshed chat rooms after ward room creation');
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create candidate-specific chat room (only for the candidate themselves)
  Future<void> createCandidateChatRoom(String candidateId, String candidateName) async {
    final user = currentUser;
    if (user == null || user.role != 'candidate' || user.uid != candidateId) {
      debugPrint('⚠️ Candidate room creation only allowed for the candidate themselves');
      return;
    }

    try {
      final chatRoom = ChatRoom(
        roomId: 'candidate_$candidateId',
        createdAt: DateTime.now(),
        createdBy: user.uid,
        type: 'public',
        title: '$candidateName Updates',
        description: 'Official updates and discussions with $candidateName',
      );

      debugPrint('🏗️ Creating candidate chat room for $candidateName');
      await _repository.createChatRoom(chatRoom);
      await fetchChatRooms();
      debugPrint('✅ Candidate chat room created and chat rooms refreshed');
    } catch (e) {
      errorMessage = e.toString();
      update();
    }
  }

  // Create private conversation (for candidates only)
  Future<void> createPrivateChatRoom(String otherUserId, String roomName) async {
    final user = currentUser;
    if (user == null || user.role != 'candidate') {
      debugPrint('⚠️ Private room creation only allowed for candidates');
      return;
    }

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

  // Get or create area room for users with area field
  Future<void> ensureAreaRoomExists() async {
    debugPrint('🏠 Starting area room creation process');

    try {
      // Get current user data from cache first (no Firebase fetch needed)
      UserModel? user = _cachedUser;

      // If no cached user data, try to get from currentUser property
      if (user == null) {
        user = currentUser;
      }

      if (user == null) {
        debugPrint('❌ No user found for area room creation');
        return;
      }

      final districtId = user.districtId;
      final area = user.area;
      if (user.wardId.isEmpty || (user.bodyId?.isEmpty ?? true) || (districtId?.isEmpty ?? true) || (area?.isEmpty ?? true)) {
        debugPrint('⚠️ User profile incomplete - wardId, bodyId, districtId, or area missing');
        debugPrint('   Ward: ${user.wardId}, Body: ${user.bodyId}, District: $districtId, Area: $area');

        // Try to update area field if missing
        if (area?.isEmpty ?? true) {
          debugPrint('🔄 Attempting to update missing area field');
          await _updateUserAreaField(user.uid);
          // Refresh cached user data after update
          user = await getCompleteUserData();
        }

        if (user == null || (user.area?.isEmpty ?? true)) {
          debugPrint('⚠️ Still no area field available, skipping area room creation');
          return;
        }
      }

      debugPrint('🔍 Ensuring area room exists for user ${user.name} in area ${user.area}, ward ${user.wardId}, district $districtId');

      // Use repository method for efficient area room creation
      final success = await _repository.createAreaRoomIfNeeded(districtId!, user.bodyId!, user.wardId, area!, user.uid);

      if (success) {
        debugPrint('✅ Area room creation process completed successfully');
        // Refresh chat rooms list to show the new area room
        await fetchChatRooms();
      } else {
        debugPrint('❌ Area room creation failed');
      }

    } catch (e) {
      debugPrint('❌ Failed to ensure area room exists: $e');
      // Don't rethrow - area room creation failure shouldn't break the app
    }
  }

  // Update user's area field if missing (for backward compatibility)
  Future<void> _updateUserAreaField(String userId) async {
    try {
      debugPrint('🔄 Checking if user has area field in profile');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final currentArea = data['area'];

        if (currentArea == null || (currentArea is String && currentArea.isEmpty)) {
          debugPrint('📝 User missing area field, attempting to set default area');

          // Try to get area from user's location or set a default
          // For now, we'll set a default area - this should be updated based on user location
          const defaultArea = 'area_1'; // Default area

          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'area': defaultArea,
          });

          debugPrint('✅ Updated user area field to: $defaultArea');

          // Invalidate cached user data
          _cachedUser = null;
        } else {
          debugPrint('✅ User already has area field: $currentArea');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to update user area field: $e');
    }
  }

  // Get or create ward room for candidates only (removed voter room creation)
  Future<void> ensureWardRoomExists() async {
    debugPrint('🏛️ Starting ward room creation process for candidates');

    try {
      // Get current user data
      UserModel? user = currentUser;

      // If cached user data is incomplete, fetch fresh data
      if (user == null || user.wardId.isEmpty || (user.districtId?.isEmpty ?? true) || (user.bodyId?.isEmpty ?? true)) {
        debugPrint('🔄 Fetching fresh user data for ward room creation');
        user = await getCompleteUserData();
      }

      if (user == null) {
        debugPrint('❌ No user found for ward room creation');
        return;
      }

      // Only allow candidates to create ward rooms
      if (user.role != 'candidate') {
        debugPrint('⚠️ Ward room creation only allowed for candidates, current role: ${user.role}');
        return;
      }

      final districtId = user.districtId; // Use districtId
      if (user.wardId.isEmpty || (user.bodyId?.isEmpty ?? true) || (districtId?.isEmpty ?? true)) {
        debugPrint('⚠️ User profile incomplete - wardId, bodyId, or districtId missing');
        debugPrint('   Ward: ${user.wardId}, Body: ${user.bodyId}, District: $districtId');
        return;
      }

      debugPrint('🔍 Ensuring ward room exists for candidate ${user.name} in ward ${user.wardId}, district $districtId');

      // Use repository method for efficient ward room creation
      final success = await _repository.createWardRoomIfNeeded(districtId!, user.bodyId!, user.wardId, user.uid);

      if (success) {
        debugPrint('✅ Ward room creation process completed successfully');
        // Refresh chat rooms list to show the new ward room
        await fetchChatRooms();
      } else {
        debugPrint('❌ Ward room creation failed');
      }

    } catch (e) {
      debugPrint('❌ Failed to ensure ward room exists: $e');
      // Don't rethrow - ward room creation failure shouldn't break the app
    }
  }

  // Get district name from district ID
  Future<String> _getDistrictName(String districtId) async {
    try {
      final districtDoc = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .get();

      if (districtDoc.exists) {
        final data = districtDoc.data();
        return data?['name'] ?? districtId.toUpperCase();
      }
    } catch (e) {
      debugPrint('Error fetching district name: $e');
    }
    return districtId.toUpperCase();
  }

  // Get body name from district ID and body ID
  Future<String> _getBodyName(String districtId, String bodyId) async {
    try {
      final bodyDoc = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .get();

      if (bodyDoc.exists) {
        final data = bodyDoc.data();
        return data?['name'] ?? bodyId;
      }
    } catch (e) {
      debugPrint('Error fetching body name: $e');
    }
    return bodyId;
  }

  // Get ward name from district ID, body ID and ward ID
  Future<String> _getWardName(String districtId, String bodyId, String wardId) async {
    try {
      final wardDoc = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
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

    final districtId = user.districtId; // Use districtId
    return await _repository.getUnreadMessageCount(user.uid, districtId: districtId, bodyId: user.bodyId, wardId: user.wardId, area: user.area);
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

  // Ensure navigation consistency - called when returning to chat screen
  void ensureNavigationConsistency() {
    final user = currentUser;
    if (user == null) return;

    // Ensure we have the latest room data
    if (chatRooms.isEmpty && _isInitialLoadComplete) {
      debugPrint('🔄 Navigation: Refreshing chat rooms for consistency');
      fetchChatRooms();
    }

    // Ensure real-time listener is active
    if (_roomChangesSubscription == null || _roomChangesSubscription!.isPaused) {
      debugPrint('🔄 Navigation: Restarting real-time listener for consistency');
      _listenForRoomChanges(user.uid, user.role);
    }

    // Update display info to ensure consistency
    _updateChatRoomDisplayInfos();
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

    // Clear sender info cache
    clearSenderInfoCache();

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

    // Force refresh user data from Firestore
    await getCompleteUserData();

    await _initializeChat();
  }

  // Manual trigger for ward room creation (for candidates only - testing/debugging)
  Future<void> manuallyCreateWardRoom() async {
    final user = currentUser;
    if (user == null || user.role != 'candidate') {
      Get.snackbar(
        'Permission Denied',
        'Ward room creation is only available for candidates.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    debugPrint('🔧 Manual ward room creation triggered for candidate');
    await ensureWardRoomExists();
    Get.snackbar(
      'Ward Room Creation',
      'Attempted to create ward room. Check logs for details.',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 3),
    );
  }

  // Manual refresh of chat rooms (for debugging/admin purposes)
  Future<void> refreshChatRooms() async {
    debugPrint('🔄 Manual refresh of chat rooms requested');
    _isInitialLoadComplete = false; // Reset flag

    // Clear repository cache to force fresh fetch
    _repository.invalidateUserCache(currentUser?.uid ?? '');

    // Clear local unread counts to prevent stale data
    _unreadCounts.clear();
    _lastMessageTimes.clear();
    _lastMessagePreviews.clear();
    _lastMessageSenders.clear();

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

  // Invalidate user cache (called when follow relationships change)
  void invalidateUserCache(String userId) {
    debugPrint('🗑️ Invalidating chat cache for user: $userId');
    _repository.invalidateUserCache(userId);

    // Refresh chat rooms if current user matches
    final currentUser = this.currentUser;
    if (currentUser != null && currentUser.uid == userId) {
      debugPrint('🔄 Refreshing chat rooms due to cache invalidation');
      fetchChatRooms();
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

  // Update message status in local state
  void _updateMessageStatus(String messageId, MessageStatus status) {
    final updatedMessages = messages.map((msg) {
      if (msg.messageId == messageId) {
        return msg.copyWith(status: status);
      }
      return msg;
    }).toList();

    messages = updatedMessages;
    messagesStream.value = updatedMessages;
    debugPrint('📝 Updated message $messageId status to: $status');
  }

  // Retry sending a failed message
  Future<void> retryMessage(String messageId) async {
    final messageIndex = messages.indexWhere((msg) => msg.messageId == messageId);
    if (messageIndex == -1) {
      debugPrint('❌ Message not found for retry: $messageId');
      return;
    }

    final message = messages[messageIndex];
    if (message.status != MessageStatus.failed) {
      debugPrint('⚠️ Message is not in failed state: ${message.status}');
      return;
    }

    final user = currentUser;
    if (user == null || currentChatRoom == null) {
      debugPrint('❌ Cannot retry message: user or chat room is null');
      return;
    }

    // Check if user can send message
    if (!canSendMessage) {
      Get.snackbar(
        'Cannot Retry',
        'You have no remaining messages or XP.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      // Update message status to sending
      _updateMessageStatus(messageId, MessageStatus.sending);

      // Increment retry count
      final updatedMessage = message.copyWith(retryCount: message.retryCount + 1);

      // Update the message in local state
      final updatedMessages = List<Message>.from(messages);
      updatedMessages[messageIndex] = updatedMessage;
      messages = updatedMessages;
      messagesStream.value = updatedMessages;

      // Determine if we should use quota or XP
      final useQuota = userQuota != null && userQuota!.canSendMessage;
      final useXP = !useQuota && user.xpPoints > 0;

      // Retry sending the message
      debugPrint('🔄 Retrying message: ${message.text} (attempt ${updatedMessage.retryCount})');
      final result = await _repository.sendMessageWithQuotaUpdate(
        currentChatRoom!.roomId,
        updatedMessage,
        user.uid,
        useQuota,
        useXP
      );

      // Update message status to sent
      _updateMessageStatus(messageId, MessageStatus.sent);

      // Update local quota if it was modified
      if (result['quota'] != null) {
        userQuota = result['quota'] as UserQuota?;
        userQuotaStream.value = userQuota;
      }

      // If XP was used, refresh user data
      if (useXP) {
        await getCompleteUserData();
        _repository.invalidateUserCache(user.uid);
      }

      debugPrint('✅ Message retry successful');

      Get.snackbar(
        'Message Sent',
        'Message sent successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      debugPrint('❌ Message retry failed: $e');

      // Update message status back to failed
      _updateMessageStatus(messageId, MessageStatus.failed);

      // Show retry snackbar again
      Get.snackbar(
        'Retry Failed',
        'Failed to send message. Tap to retry again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        duration: const Duration(seconds: 3),
        onTap: (_) => retryMessage(messageId),
      );
    }
  }

  // Debug user profile completion status
  void debugUserProfileStatus() {
    final user = currentUser;
    final firebaseUser = _auth.currentUser;

    debugPrint('🔍 User Profile Debug Info:');
    debugPrint('   Firebase Auth User: ${firebaseUser?.displayName ?? 'null'} (${firebaseUser?.uid ?? 'null'})');
    debugPrint('   Current user: ${user?.name ?? 'null'} (${user?.uid ?? 'null'})');
    debugPrint('   Cached user: ${_cachedUser?.name ?? 'null'} (${_cachedUser?.uid ?? 'null'})');
    debugPrint('   Profile completed: ${user?.profileCompleted ?? 'null'}');
    debugPrint('   Role: ${user?.role ?? 'null'}');
    debugPrint('   Ward ID: ${user?.wardId ?? 'null'}');
    debugPrint('   District ID: ${user?.districtId ?? 'null'}');
    debugPrint('   Body ID: ${user?.bodyId ?? 'null'}');

    final districtId = user?.districtId; // Use districtId
    final hasCompleteLocation = (user?.wardId.isNotEmpty ?? false) &&
                               (user?.bodyId?.isNotEmpty ?? false) &&
                               (districtId?.isNotEmpty ?? false);
    debugPrint('   Has complete location data: $hasCompleteLocation');

    Get.snackbar(
      'Profile Debug',
      'Profile: ${user?.profileCompleted ?? false}, Location: $hasCompleteLocation, District: $districtId',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 5),
    );
  }

  // Debug unread message counts
  void debugUnreadCounts() {
    debugPrint('🔍 Unread Counts Debug Info:');
    debugPrint('   Current room: ${currentChatRoom?.roomId ?? 'null'}');
    debugPrint('   Total unread counts: ${_unreadCounts.length}');
    _unreadCounts.forEach((roomId, count) {
      debugPrint('     Room $roomId: $count unread messages');
    });
    debugPrint('   Chat room display infos: ${chatRoomDisplayInfos.length}');
    chatRoomDisplayInfos.forEach((info) {
      debugPrint('     Room ${info.room.roomId}: unread=${info.unreadCount}, hasUnread=${info.hasUnreadMessages}');
    });

    Get.snackbar(
      'Unread Debug',
      'Total unread: ${_unreadCounts.values.fold(0, (sum, count) => sum + count)}',
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 5),
    );
  }

  // Test method to manually increment unread count for debugging
  void testIncrementUnreadCount(String roomId) {
    final testMessage = Message(
      messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Test message',
      senderId: 'test_sender',
      type: 'text',
      createdAt: DateTime.now(),
      readBy: [],
    );

    _incrementUnreadCount(roomId, testMessage);
    debugPrint('🧪 Manually incremented unread count for room: $roomId');
  }
}