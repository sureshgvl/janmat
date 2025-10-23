import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../candidate/repositories/candidate_repository.dart';
import '../../notifications/services/poll_notification_service.dart';
import '../../notifications/services/notification_manager.dart';
import '../../notifications/models/notification_type.dart';
import '../../../utils/app_logger.dart';
import '../../../controllers/user_data_controller.dart';

// WhatsApp-style Chat Metadata for efficient caching
class ChatMetadata {
  final String roomId;
  final String title;
  final String? description;
  final String type;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageTime;
  final String? lastMessageText;
  final String? lastMessageSender;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final String? lastMessageType; // text, image, etc.

  ChatMetadata({
    required this.roomId,
    required this.title,
    this.description,
    required this.type,
    required this.createdBy,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessageText,
    this.lastMessageSender,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.lastMessageType,
  });

  factory ChatMetadata.fromChatRoom(ChatRoom room, {int unreadCount = 0}) {
    return ChatMetadata(
      roomId: room.roomId,
      title: room.title,
      description: room.description,
      type: room.type,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      unreadCount: unreadCount,
    );
  }

  ChatMetadata copyWith({
    String? title,
    String? description,
    DateTime? lastMessageTime,
    String? lastMessageText,
    String? lastMessageSender,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    String? lastMessageType,
  }) {
    return ChatMetadata(
      roomId: roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      createdBy: createdBy,
      createdAt: createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      lastMessageType: lastMessageType ?? this.lastMessageType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'title': title,
      'description': description,
      'type': type,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageText': lastMessageText,
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'lastMessageType': lastMessageType,
    };
  }

  factory ChatMetadata.fromJson(Map<String, dynamic> json) {
    return ChatMetadata(
      roomId: json['roomId'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageTime: json['lastMessageTime'] != null ? DateTime.parse(json['lastMessageTime']) : null,
      lastMessageText: json['lastMessageText'],
      lastMessageSender: json['lastMessageSender'],
      unreadCount: json['unreadCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      lastMessageType: json['lastMessageType'],
    );
  }
}

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final CandidateRepository _candidateRepository = CandidateRepository();

  // WhatsApp-style caching: Cache metadata, not full room data
  static final Map<String, List<ChatMetadata>> _metadataCache = {};
  static final Map<String, DateTime> _metadataTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  // Local storage for offline access (simulated with memory for now)
  static final Map<String, List<ChatMetadata>> _localStorage = {};

  // Check if cache is valid
  bool _isCacheValid(String cacheKey) {
    if (!_metadataTimestamps.containsKey(cacheKey)) return false;
    final cacheTime = _metadataTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  // Cache metadata for a user
  void _cacheMetadata(String cacheKey, List<ChatMetadata> metadata) {
    _metadataCache[cacheKey] = List.from(metadata);
    _metadataTimestamps[cacheKey] = DateTime.now();
    // Also save to local storage for offline access
    _localStorage[cacheKey] = List.from(metadata);
  }

  // Get cached metadata
  List<ChatMetadata>? _getCachedMetadata(String cacheKey) {
    return _isCacheValid(cacheKey) ? _metadataCache[cacheKey] : null;
  }

  // Get from local storage (for offline access)
  List<ChatMetadata>? _getLocalMetadata(String cacheKey) {
    return _localStorage[cacheKey];
  }

  // Invalidate specific chat metadata
  void invalidateChatMetadata(String cacheKey, String roomId) {
    final cached = _metadataCache[cacheKey];
    if (cached != null) {
      cached.removeWhere((meta) => meta.roomId == roomId);
      _metadataTimestamps[cacheKey] = DateTime.now(); // Update timestamp
    }
  }

  // Update chat metadata (for new messages, etc.)
  void updateChatMetadata(String cacheKey, String roomId, ChatMetadata updatedMetadata) {
    final cached = _metadataCache[cacheKey];
    if (cached != null) {
      final index = cached.indexWhere((meta) => meta.roomId == roomId);
      if (index != -1) {
        cached[index] = updatedMetadata;
      } else {
        cached.add(updatedMetadata);
      }
      _metadataTimestamps[cacheKey] = DateTime.now();
    }
  }

  // Convert metadata list to ChatRoom objects (for compatibility)
  Future<List<ChatRoom>> _convertMetadataToRooms(
    List<ChatMetadata> metadata,
    String userId,
    String userRole,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  ) async {
    final rooms = <ChatRoom>[];

    for (final meta in metadata) {
      try {
        // Try to get the full room data from Firestore
        ChatRoom? room;
        final roomPath = _getRoomPathFromId(meta.roomId);
        final doc = await _firestore.doc(roomPath).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          room = ChatRoom.fromJson(data);
        } else {
          // Fallback: create a basic room from metadata
          room = ChatRoom(
            roomId: meta.roomId,
            title: meta.title,
            description: meta.description ?? '',
            type: meta.type,
            createdBy: meta.createdBy,
            createdAt: meta.createdAt,
          );
        }

        if (room != null) {
          rooms.add(room);
        }
      } catch (e) {
        AppLogger.database('Failed to convert metadata to room for ${meta.roomId}: $e', tag: 'CHAT');
      }
    }

    return rooms;
  }

  // Public method to get cached rooms (for controller compatibility)
  Future<List<ChatRoom>?> getCachedRooms(String cacheKey) async {
    final metadata = _getCachedMetadata(cacheKey);
    if (metadata != null) {
      // Extract user info from cache key for conversion
      // Format: {userId}_{userRole}_{stateId}_{districtId}_{bodyId}_{wardId}_{area}
      final parts = cacheKey.split('_');
      if (parts.length >= 2) {
        final userId = parts[0];
        final userRole = parts[1];
        // Extract location data (this is a simplified approach)
        String? stateId, districtId, bodyId, wardId, area;

        if (parts.length >= 6) {
          stateId = parts[2] != 'no_state' ? parts[2] : null;
          districtId = parts[3] != 'no_district' ? parts[3] : null;
          bodyId = parts[4] != 'no_body' ? parts[4] : null;
          wardId = parts[5] != 'no_ward' ? parts[5] : null;
          if (parts.length >= 7 && parts[6] != 'no_area') {
            area = parts[6];
          }
        }

        return await _convertMetadataToRooms(metadata, userId, userRole, stateId, districtId, bodyId, wardId, area);
      }
    }
    return null;
  }

  // Invalidate cache for a user
  void invalidateUserCache(String userId) {
    final keysToRemove = _metadataCache.keys
        .where((key) => key.contains(userId))
        .toList();
    for (final key in keysToRemove) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }
    AppLogger.database(
      'Invalidated ${keysToRemove.length} metadata cache entries for user: $userId',
      tag: 'CHAT',
    );
  }

  // Invalidate cache for a specific role
  void invalidateRoleCache(String userRole) {
    final keysToRemove = _metadataCache.keys
        .where((key) => key.contains('_${userRole}_'))
        .toList();
    for (final key in keysToRemove) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }
    AppLogger.database(
      'Invalidated ${keysToRemove.length} metadata cache entries for role: $userRole',
      tag: 'CHAT',
    );
  }

  // Invalidate cache for a specific location
  void invalidateLocationCache(String cityId, String wardId) {
    final locationPattern = '${cityId}_$wardId';
    final keysToRemove = _metadataCache.keys
        .where((key) => key.contains(locationPattern))
        .toList();
    for (final key in keysToRemove) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }
    AppLogger.database(
      'Invalidated ${keysToRemove.length} metadata cache entries for location: $locationPattern',
      tag: 'CHAT',
    );
  }

  // Invalidate cache when user follows/unfollows a candidate
  void invalidateUserFollowCache(String userId) {
    final keysToRemove = _metadataCache.keys
        .where((key) => key.startsWith('${userId}_voter_'))
        .toList();
    for (final key in keysToRemove) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }
    AppLogger.database(
      'Invalidated ${keysToRemove.length} metadata cache entries for user follow changes: $userId',
      tag: 'CHAT',
    );
  }

  // Force refresh cache for a user (used when new rooms are discovered)
  void forceRefreshUserCache(String userId, String userRole) {
    final keysToRemove = _metadataCache.keys
        .where((key) => key.startsWith('${userId}_${userRole}_'))
        .toList();
    for (final key in keysToRemove) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }
    AppLogger.database(
      'Force refreshed ${keysToRemove.length} metadata cache entries for user: $userId ($userRole)',
      tag: 'CHAT',
    );
  }

  // Clear old cache keys (for migration when cache key format changes)
  void _clearOldCacheKeys(
    String userId,
    String userRole,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  ) {
    final oldKeysToRemove = <String>[];

    // Old format for voters (without area)
    if (userRole == 'voter') {
      final oldVoterKey = '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}';
      oldKeysToRemove.add(oldVoterKey);
    }

    // Old format for candidates (might have been different)
    if (userRole == 'candidate') {
      final oldCandidateKey = '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}';
      oldKeysToRemove.add(oldCandidateKey);
    }

    for (final key in oldKeysToRemove) {
      if (_metadataCache.containsKey(key)) {
        _metadataCache.remove(key);
        _metadataTimestamps.remove(key);
        AppLogger.database('Cleared old metadata cache key: $key', tag: 'CHAT');
      }
    }
  }

  // Clear all expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _metadataTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheValidityDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _metadataCache.remove(key);
      _metadataTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      AppLogger.database('Cleared ${expiredKeys.length} expired metadata cache entries', tag: 'CHAT');
    }
  }

  // Force clear all cache (for testing/debugging)
  void clearAllCache() {
    final count = _metadataCache.length;
    _metadataCache.clear();
    _metadataTimestamps.clear();
    _localStorage.clear();
    AppLogger.database('Force cleared all $count metadata cache entries', tag: 'CHAT');
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'total_entries': _metadataCache.length,
      'cache_size_mb':
          (_metadataCache.values
              .map(
                (metadata) => metadata.length * 512, // Rough estimate: 512B per metadata
              )
              .fold(0, (a, b) => a + b) /
          (1024 * 1024)),
      'oldest_entry': _metadataTimestamps.values.isNotEmpty
          ? _metadataTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest_entry': _metadataTimestamps.values.isNotEmpty
          ? _metadataTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // Get chat rooms for a user from hierarchical structure
  Future<List<ChatRoom>> getChatRoomsForUser(
    String userId,
    String userRole, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    // BREAKPOINT REPO-1: Start of getChatRoomsForUser
    AppLogger.database('getChatRoomsForUser called', tag: 'CHAT');
    AppLogger.database(
      'User ID: $userId, Role: $userRole, State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId',
      tag: 'CHAT',
    );

    // Create cache key based on user and parameters
    final cacheKey = '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}_${area ?? 'no_area'}';

    // BREAKPOINT REPO-2: Cache check
    AppLogger.database('Cache key: $cacheKey', tag: 'CHAT');

    // WhatsApp-style caching: Check metadata cache first
    final cachedMetadata = _getCachedMetadata(cacheKey);
    if (cachedMetadata != null) {
      AppLogger.database(
        'REPOSITORY CACHE HIT: Returning ${cachedMetadata.length} cached metadata for $userRole',
        tag: 'CHAT',
      );
      // Convert metadata back to ChatRoom objects for compatibility
      final rooms = await _convertMetadataToRooms(cachedMetadata, userId, userRole, stateId, districtId, bodyId, wardId, area);
      return rooms;
    }

    // Check local storage for offline access
    final localMetadata = _getLocalMetadata(cacheKey);
    if (localMetadata != null && cachedMetadata == null) {
      AppLogger.database(
        'LOCAL STORAGE HIT: Returning ${localMetadata.length} local metadata for $userRole',
        tag: 'CHAT',
      );
      final rooms = await _convertMetadataToRooms(localMetadata, userId, userRole, stateId, districtId, bodyId, wardId, area);
      return rooms;
    }

    // Clear old cache entries with different keys (for migration)
    _clearOldCacheKeys(userId, userRole, stateId, districtId, bodyId, wardId, area);

    AppLogger.database(
      'REPOSITORY CACHE MISS: Fetching rooms from Firebase for $userRole',
      tag: 'CHAT',
    );

    try {
      // BREAKPOINT REPO-3: Location data check
      AppLogger.database(
        'Initial location data - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
        tag: 'CHAT',
      );

      // If location data is not provided, try to get it from user profile
      if (stateId == null || districtId == null || bodyId == null || wardId == null) {
        AppLogger.database(
          'Fetching location data from user profile',
          tag: 'CHAT',
        );

        // OPTIMIZED: Use UserDataController for cached user data
        final userDataController = Get.find<UserDataController>();
        if (userDataController.isInitialized.value && userDataController.currentUser.value != null) {
          final userModel = userDataController.currentUser.value!;
          stateId = userModel.stateId;
          districtId = userModel.districtId;
          bodyId = userModel.bodyId;
          wardId = userModel.wardId;
          area = userModel.area;

          AppLogger.database(
            'Updated location data from cache - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
            tag: 'CHAT',
          );
        } else {
          // Fallback to fresh fetch if cache not available
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userModel = UserModel.fromJson(userData);
            stateId = userModel.stateId;
            districtId = userModel.districtId;
            bodyId = userModel.bodyId;
            wardId = userModel.wardId;
            area = userModel.area;

            AppLogger.database(
              'Updated location data from fresh fetch - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
              tag: 'CHAT',
            );
          } else {
            AppLogger.database('User document not found', tag: 'CHAT');
          }
        }
      }

      // BREAKPOINT REPO-5: Before Firebase query
      AppLogger.database(
        'Querying Firebase for rooms - Role: $userRole',
        tag: 'CHAT',
      );

      List<ChatRoom> allRooms = [];

      if (userRole == 'admin') {
        // BREAKPOINT REPO-6: Admin query - use collection group to get all rooms
        AppLogger.database('Admin user - fetching all rooms from hierarchical structure', tag: 'CHAT');
        final snapshot = await _firestore.collectionGroup('chats').get();
        allRooms = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ChatRoom.fromJson(data);
        }).toList();
        AppLogger.database(
          'Admin fetched ${allRooms.length} rooms',
          tag: 'CHAT',
        );
      } else {
        // BREAKPOINT REPO-7: Non-admin query - use targeted queries for better performance
        AppLogger.database(
          'Non-admin user - using targeted queries for better performance',
          tag: 'CHAT',
        );

        // For non-admin users, query specific rooms directly instead of fetching everything
        final targetedRooms = await _getTargetedRoomsForUser(userId, userRole, stateId, districtId, bodyId, wardId, area);
        allRooms = targetedRooms;
        AppLogger.database(
          'Fetched ${allRooms.length} targeted rooms for $userRole',
          tag: 'CHAT',
        );

        // Filter based on user role and location
        if (userRole == 'candidate') {
          // BREAKPOINT REPO-8: Candidate filtering
          AppLogger.database('Filtering rooms for candidate', tag: 'CHAT');
          AppLogger.database(
            'User location - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
            tag: 'CHAT',
          );

          allRooms = allRooms.where((room) {
            final isOwnRoom = room.createdBy == userId;
            final isWardRoom =
                stateId != null &&
                districtId != null &&
                bodyId != null &&
                wardId != null &&
                room.roomId == 'ward_${stateId}_${districtId}_${bodyId}_$wardId';
            final isAreaRoom =
                stateId != null &&
                districtId != null &&
                bodyId != null &&
                wardId != null &&
                room.roomId.startsWith('area_${stateId}_${districtId}_${bodyId}_${wardId}_');
            final isCandidateRoom =
                room.roomId.startsWith('candidate_') &&
                room.createdBy == userId;

            // Include private chats where user is a member
            final isPrivateChat = room.type == 'private' && room.members != null && room.members!.contains(userId);

            // Include rooms that are relevant to this candidate's location or their own candidate room
            final shouldInclude =
                isOwnRoom || isWardRoom || isAreaRoom || isCandidateRoom || isPrivateChat;

            if (shouldInclude) {
              AppLogger.database(
                'Including room: ${room.roomId} (own: $isOwnRoom, ward: $isWardRoom, area: $isAreaRoom, candidate: $isCandidateRoom, private: $isPrivateChat)',
                tag: 'CHAT',
              );
            }

            return shouldInclude;
          }).toList();
          AppLogger.database(
            'Candidate filtered to ${allRooms.length} rooms',
            tag: 'CHAT',
          );
        } else {
          // BREAKPOINT REPO-9: Voter filtering
          AppLogger.chat('🔍 BREAKPOINT REPO-9: Filtering rooms for voter');
          if (stateId != null && districtId != null && bodyId != null && wardId != null) {
            final wardRoomId = 'ward_${stateId}_${districtId}_${bodyId}_$wardId';
            final areaRoomId = area != null
                ? 'area_${stateId}_${districtId}_${bodyId}_${wardId}_$area'
                : null;
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-9: Looking for ward room: $wardRoomId',
            );
            if (areaRoomId != null) {
              AppLogger.chat(
                '🔍 BREAKPOINT REPO-9: Looking for area room: $areaRoomId',
              );
            }

            // Get list of candidates the voter is following
            final followedCandidateIds = await _candidateRepository
                .getUserFollowing(userId);
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-9: Voter follows ${followedCandidateIds.length} candidates',
            );

            // Get list of candidate user IDs in the same ward (for filtering followed candidates)
            final wardCandidateIds = await _getCandidateIdsInWard(
              districtId,
              bodyId,
              wardId,
            );
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-9: Found ${wardCandidateIds.length} candidates in ward',
            );

            // Only include candidates that are both followed AND in the same ward
            final relevantCandidateIds = followedCandidateIds
                .where((candidateId) => wardCandidateIds.contains(candidateId))
                .toList();
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-9: Found ${relevantCandidateIds.length} followed candidates in ward',
            );

            allRooms = allRooms.where((room) {
              // Include ward room
              if (room.roomId == wardRoomId) {
                AppLogger.chat(
                  '🔍 BREAKPOINT REPO-9: Including ward room: ${room.roomId}',
                );
                return true;
              }

              // Include area room if user has area
              if (areaRoomId != null && room.roomId == areaRoomId) {
                AppLogger.chat(
                  '🔍 BREAKPOINT REPO-9: Including area room: ${room.roomId}',
                );
                return true;
              }

              // Include rooms created by followed candidates in the same ward
              if (relevantCandidateIds.contains(room.createdBy)) {
                AppLogger.chat(
                  '🔍 BREAKPOINT REPO-9: Including followed candidate room: ${room.roomId} by ${room.createdBy}',
                );
                return true;
              }

              // Include private chats where user is a member
              if (room.type == 'private' && room.members != null && room.members!.contains(userId)) {
                AppLogger.chat(
                  '🔍 BREAKPOINT REPO-9: Including private chat: ${room.roomId}',
                );
                return true;
              }

              return false;
            }).toList();
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-9: Voter filtered to ${allRooms.length} rooms',
            );
          } else {
            // BREAKPOINT REPO-10: No location data
            AppLogger.chat(
              '🔍 BREAKPOINT REPO-10: No location data - showing only general public rooms',
            );
            // Only show general public rooms, not location-specific ones
            allRooms = allRooms
                .where(
                  (room) =>
                      room.type == 'public' &&
                      !room.roomId.startsWith('ward_') &&
                      !room.roomId.startsWith('area_') &&
                      !room.roomId.startsWith('candidate_'),
                )
                .toList();
          }
        }
      }

      // Remove duplicates to ensure clean room list
      final uniqueRooms = <String, ChatRoom>{};
      for (final room in allRooms) {
        uniqueRooms[room.roomId] = room;
      }
      allRooms = uniqueRooms.values.toList();

      // Sort by creation date (newest first)
      allRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // BREAKPOINT REPO-11: Final result before caching
      AppLogger.database(
        'Final rooms list - ${allRooms.length} unique rooms',
        tag: 'CHAT',
      );
      for (var room in allRooms) {
        AppLogger.database(
          'Final room: ${room.roomId} - ${room.title} (${room.type})',
          tag: 'CHAT',
        );
      }

      // Cache the metadata results (WhatsApp style)
      final metadata = allRooms.map((room) => ChatMetadata.fromChatRoom(room)).toList();
      _cacheMetadata(cacheKey, metadata);
      AppLogger.database('Cached ${metadata.length} metadata entries for cache key: $cacheKey', tag: 'CHAT');

      // BREAKPOINT REPO-12: Returning result
      AppLogger.database(
        'Returning ${allRooms.length} rooms to controller',
        tag: 'CHAT',
      );
      return allRooms;
    } catch (e) {
      throw Exception('Failed to fetch chat rooms: $e');
    }
  }

  // Create a new chat room in hierarchical structure
  Future<ChatRoom> createChatRoom(ChatRoom chatRoom) async {
    // BREAKPOINT CREATE-1: Start of createChatRoom
    AppLogger.database('createChatRoom called', tag: 'CHAT');
    AppLogger.database(
      'Room ID: ${chatRoom.roomId}, Title: ${chatRoom.title}, Type: ${chatRoom.type}',
      tag: 'CHAT',
    );
    AppLogger.database('Created by: ${chatRoom.createdBy}', tag: 'CHAT');

    try {
      // BREAKPOINT CREATE-2: Before Firestore operation
      AppLogger.database('Setting room data in hierarchical structure', tag: 'CHAT');
      final roomPath = _getRoomPathFromId(chatRoom.roomId);
      final docRef = _firestore.doc(roomPath);
      await docRef.set(chatRoom.toJson());

      // BREAKPOINT CREATE-3: After successful creation
      AppLogger.database(
        'Room successfully created in hierarchical structure',
        tag: 'CHAT',
      );

      // Invalidate cache for the creator and related users
      invalidateUserCache(chatRoom.createdBy);
      // Force refresh cache for the creator to see the new room immediately
      forceRefreshUserCache(chatRoom.createdBy, 'candidate'); // Assume candidate for now
      AppLogger.database(
        'Invalidated and force refreshed cache for user ${chatRoom.createdBy} after room creation',
        tag: 'CHAT',
      );

      // BREAKPOINT CREATE-4: Returning result
      AppLogger.database(
        'Returning created room: ${chatRoom.roomId}',
        tag: 'CHAT',
      );
      return chatRoom;
    } catch (e) {
      // BREAKPOINT CREATE-5: Error occurred
      AppLogger.database('Failed to create chat room: $e', tag: 'CHAT');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Batch: Create room and add initial members
  Future<ChatRoom> createRoomWithMembers(
    ChatRoom chatRoom,
    List<String> memberIds,
  ) async {
    try {
      AppLogger.database(
        'Creating room with ${memberIds.length} initial members',
        tag: 'CHAT',
      );

      await _firestore.runTransaction((transaction) async {
        // Create the room
        final roomRef = _firestore.collection('chats').doc(chatRoom.roomId);
        transaction.set(roomRef, chatRoom.toJson());

        // Add initial members (for private rooms)
        if (chatRoom.type == 'private' && memberIds.isNotEmpty) {
          // You could add member management logic here
          // For now, just create the room
        }
      });

      // Invalidate cache for all members (important for private chats)
      invalidateUserCache(chatRoom.createdBy);
      if (memberIds.isNotEmpty) {
        for (final memberId in memberIds) {
          if (memberId != chatRoom.createdBy) {
            invalidateUserCache(memberId);
            AppLogger.database('Invalidated cache for member: $memberId', tag: 'CHAT');
          }
        }
      }

      AppLogger.database('Room created with initial members', tag: 'CHAT');
      return chatRoom;
    } catch (e) {
      AppLogger.database('Failed to create room with members: $e', tag: 'CHAT');
      throw Exception('Failed to create room with members: $e');
    }
  }

  // Batch: Initialize app data (user + quota + rooms)
  Future<Map<String, dynamic>> initializeAppData(
    String userId,
    String userRole, {
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    try {
      AppLogger.database('Initializing app data for user', tag: 'CHAT');

      // Parallel fetch of all required data
      final results = await Future.wait([
        getUserDataAndQuota(userId),
        getChatRoomsForUser(
          userId,
          userRole,
          stateId: stateId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
          area: area,
        ),
        getUnreadMessageCount(
          userId,
          userRole: userRole,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
          area: area,
        ),
      ]);

      final userData = results[0] as Map<String, dynamic>;
      final rooms = results[1] as List<ChatRoom>;
      final unreadCount = results[2] as int;

      AppLogger.database(
        'App data initialized - ${rooms.length} rooms, $unreadCount unread messages',
        tag: 'CHAT',
      );

      return {
        'user': userData['user'],
        'quota': userData['quota'],
        'rooms': rooms,
        'unreadCount': unreadCount,
      };
    } catch (e) {
      AppLogger.database('Failed to initialize app data: $e', tag: 'CHAT');
      throw Exception('Failed to initialize app data: $e');
    }
  }

  // Get messages for a chat room from hierarchical structure
  Stream<List<Message>> getMessagesForRoom(String roomId) {
    // Parse roomId to determine the hierarchical path
    final roomPath = _getRoomPathFromId(roomId);
    return _firestore
        .doc(roomPath)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['messageId'] = doc.id;

            // Ensure status field exists, default to sent if missing
            if (!data.containsKey('status') || data['status'] == null) {
              data['status'] = 1; // MessageStatus.sent.index
              AppLogger.chat('⚠️ Message ${doc.id} missing status field, defaulting to sent');
            }

            return Message.fromJson(data);
          }).toList();
        });
  }

  // Get paginated messages for a chat room (for loading older messages)
  Future<List<Message>> getMessagesForRoomPaginated(
    String roomId, {
    int limit = 20,
    DateTime? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: true) // Newest first for pagination
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return null;

        data['messageId'] = doc.id;

        // Ensure status field exists, default to sent if missing
        if (!data.containsKey('status') || data['status'] == null) {
          data['status'] = 1; // MessageStatus.sent.index
          AppLogger.database('Message ${doc.id} missing status field, defaulting to sent', tag: 'CHAT');
        }

        return Message.fromJson(data);
      }).where((message) => message != null).cast<Message>().toList();
    } catch (e) {
      AppLogger.chat('❌ Error loading paginated messages: $e');
      return [];
    }
  }

  // Get the oldest message timestamp for pagination
  Future<DateTime?> getOldestMessageTimestamp(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final timestamp = data['createdAt'];
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        }
      }
      return null;
    } catch (e) {
      AppLogger.chat('❌ Error getting oldest message timestamp: $e');
      return null;
    }
  }

  // Send a message to hierarchical chat room
  Future<Message> sendMessage(String roomId, Message message) async {
    try {
      // Only log in debug mode
      assert(() {
        AppLogger.database(
          'Sending message "${message.text}" to room $roomId',
          tag: 'CHAT',
        );
        return true;
      }());

      final roomPath = _getRoomPathFromId(roomId);
      final docRef = _firestore
          .doc(roomPath)
          .collection('messages')
          .doc(message.messageId);

      await docRef.set(message.toJson());

      // Only log in debug mode
      assert(() {
        AppLogger.chat('✅ Repository: Message saved to Firestore successfully');
        return true;
      }());

      // Send notification to other room members (except sender)
      try {
        await _sendMessageNotification(roomId, message);
      } catch (e) {
        AppLogger.chat('⚠️ Failed to send message notification: $e');
        // Don't fail the message send if notification fails
      }

      // Quota/XP handling is now done in the controller

      return message;
    } catch (e) {
      // Only log in debug mode
      assert(() {
        AppLogger.chat('❌ Repository: Failed to send message: $e');
        return true;
      }());
      throw Exception('Failed to send message: $e');
    }
  }

  // Batch: Send message and update quota/XP in single transaction
  Future<Map<String, dynamic>> sendMessageWithQuotaUpdate(
    String roomId,
    Message message,
    String userId,
    bool useQuota,
    bool useXP,
  ) async {
    try {
      AppLogger.chat('📦 BATCH: Sending message with quota/XP update');

      // Perform the transaction with all reads first, then all writes
      final result = await _firestore.runTransaction((transaction) async {
        // READ PHASE: Get all data we need first
        UserQuota? currentQuota;
        if (useQuota) {
          final quotaRef = _firestore.collection('user_quotas').doc(userId);
          final quotaSnapshot = await transaction.get(quotaRef);
          if (quotaSnapshot.exists) {
            currentQuota = UserQuota.fromJson(quotaSnapshot.data()!);
            AppLogger.chat(
              '📊 Current quota before update: ${currentQuota.remainingMessages} messages',
            );
          } else {
            AppLogger.chat('📊 No quota found, will create default quota');
          }
        }

        // WRITE PHASE: Now perform all writes
        // 1. Send message
        final messageRef = _firestore
            .collection('chats')
            .doc(roomId)
            .collection('messages')
            .doc(message.messageId);

        transaction.set(messageRef, message.toJson());

        // 2. Update quota if needed
        UserQuota? updatedQuota;
        if (useQuota) {
          final quotaRef = _firestore.collection('user_quotas').doc(userId);

          if (currentQuota != null) {
            // Existing quota - increment messagesSent
            updatedQuota = currentQuota.copyWith(
              messagesSent: currentQuota.messagesSent + 1,
            );
            transaction.set(quotaRef, updatedQuota.toJson());
            AppLogger.chat(
              '📊 Updated quota: ${updatedQuota.remainingMessages} messages remaining',
            );
          } else {
            // No quota exists - create default with 1 message already sent
            AppLogger.chat('📊 Creating default quota with 1 message sent');
            updatedQuota = UserQuota(
              userId: userId,
              dailyLimit: 100,
              messagesSent: 1, // Start with 1 since we're sending a message
              extraQuota: 0,
              lastReset: DateTime.now(),
              createdAt: DateTime.now(),
            );
            transaction.set(quotaRef, updatedQuota.toJson());
            AppLogger.chat(
              '📊 Created new quota: ${updatedQuota.remainingMessages} messages remaining',
            );
          }
        }

        // 3. Update XP if needed
        if (useXP) {
          final userRef = _firestore.collection('users').doc(userId);
          transaction.update(userRef, {'xpPoints': FieldValue.increment(-1)});
          AppLogger.chat('⭐ XP decremented by 1');
        }

        return {'message': message, 'quota': updatedQuota};
      });

      AppLogger.chat(
        '✅ BATCH: Message sent with quota/XP update in single transaction',
      );
      return result;
    } catch (e) {
      AppLogger.chat('❌ BATCH: Failed to send message with quota update: $e');
      throw Exception('Failed to send message with quota update: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(
    String roomId,
    String messageId,
    String userId,
  ) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final message = Message.fromJson(snapshot.data()!);
        final readBy = List<String>.from(message.readBy);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          transaction.update(docRef, {'readBy': readBy});
        }
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Upload media file
  Future<String> uploadMediaFile(
    String roomId,
    String filePath,
    String fileName,
    String contentType,
  ) async {
    try {
      final storageRef = _storage.ref().child('chat_media/$roomId/$fileName');
      final uploadTask = storageRef.putFile(
        File(filePath),
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media file: $e');
    }
  }

  // Get user quota
  Future<UserQuota?> getUserQuota(String userId) async {
    try {
      final doc = await _firestore.collection('user_quotas').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['userId'] = doc.id;
        return UserQuota.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user quota: $e');
    }
  }

  // Batch: Get user data and quota together
  Future<Map<String, dynamic>> getUserDataAndQuota(String userId) async {
    try {
      AppLogger.chat('📦 BATCH: Fetching user data and quota together');

      final results = await Future.wait([
        _firestore.collection('users').doc(userId).get(),
        _firestore.collection('user_quotas').doc(userId).get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final quotaDoc = results[1] as DocumentSnapshot;

      UserModel? user;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        user = UserModel(
          uid: data['uid'] ?? userId,
          name: data['name'] ?? 'Unknown',
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'voter',
          roleSelected: data['roleSelected'] ?? false,
          profileCompleted: data['profileCompleted'] ?? false,
          electionAreas: [],
          districtId: data['districtId'] ?? '',
          xpPoints: data['xpPoints'] ?? 0,
          premium: data['premium'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
          photoURL: data['photoURL'],
        );
      }

      UserQuota? quota;
      if (quotaDoc.exists) {
        final data = quotaDoc.data() as Map<String, dynamic>;
        data['userId'] = quotaDoc.id;
        quota = UserQuota.fromJson(data);
      }

      AppLogger.chat('✅ BATCH: Retrieved user data and quota in single operation');
      return {'user': user, 'quota': quota};
    } catch (e) {
      AppLogger.chat('❌ BATCH: Failed to get user data and quota: $e');
      throw Exception('Failed to get user data and quota: $e');
    }
  }

  // Create or update user quota
  Future<void> updateUserQuota(UserQuota quota) async {
    try {
      await _firestore
          .collection('user_quotas')
          .doc(quota.userId)
          .set(quota.toJson());
    } catch (e) {
      throw Exception('Failed to update user quota: $e');
    }
  }

  // Add extra quota (after watching ad)
  Future<void> addExtraQuota(String userId, int extraQuota) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(quotaRef);
        if (snapshot.exists) {
          final currentQuota = UserQuota.fromJson(snapshot.data()!);
          final updatedQuota = currentQuota.copyWith(
            extraQuota: currentQuota.extraQuota + extraQuota,
          );
          transaction.set(quotaRef, updatedQuota.toJson());
        } else {
          // Create new quota
          final newQuota = UserQuota(
            userId: userId,
            extraQuota: extraQuota,
            lastReset: DateTime.now(),
            createdAt: DateTime.now(),
          );
          transaction.set(quotaRef, newQuota.toJson());
        }
      });
    } catch (e) {
      throw Exception('Failed to add extra quota: $e');
    }
  }

  // Create a poll - Optimized with indexing
  Future<Poll> createPoll(String roomId, Poll poll) async {
    try {
      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('polls')
          .doc(poll.pollId);

      await docRef.set(poll.toJson());

      // Update poll index for faster lookups
      await _updatePollIndex(poll.pollId, roomId);

      AppLogger.chat('✅ Poll created and indexed: ${poll.pollId} in room $roomId');
      return poll;
    } catch (e) {
      throw Exception('Failed to create poll: $e');
    }
  }

  // Get polls for a room
  Stream<List<Poll>> getPollsForRoom(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['pollId'] = doc.id;
            return Poll.fromJson(data);
          }).toList();
        });
  }

  // Get a specific poll by ID from any room - Optimized with indexing
  Future<Poll?> getPollById(String pollId) async {
    try {
      // First, try to get location from poll index
      final indexDoc = await _firestore
          .collection('poll_index')
          .doc(pollId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final roomId = indexData['roomId'];

        AppLogger.chat('🎯 Found poll in indexed room: $roomId');

        // Direct query using room ID from index
        final pollDoc = await _firestore
            .collection('chats')
            .doc(roomId)
            .collection('polls')
            .doc(pollId)
            .get();

        if (pollDoc.exists) {
          final data = pollDoc.data() as Map<String, dynamic>;
          data['pollId'] = pollDoc.id;
          return Poll.fromJson(data);
        }
      }

      // Fallback: Optimized search with early termination
      AppLogger.chat('🔄 Poll index not found, using optimized search');
      final roomsSnapshot = await _firestore.collection('chats').get();

      for (final roomDoc in roomsSnapshot.docs) {
        final pollDoc = await roomDoc.reference
            .collection('polls')
            .doc(pollId)
            .get();
        if (pollDoc.exists) {
          final data = pollDoc.data() as Map<String, dynamic>;
          data['pollId'] = pollDoc.id;

          // Update index for future queries
          await _updatePollIndex(pollId, roomDoc.id);

          return Poll.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get poll by ID: $e');
    }
  }

  // Update poll index for faster lookups
  Future<void> _updatePollIndex(String pollId, String roomId) async {
    try {
      await _firestore.collection('poll_index').doc(pollId).set({
        'roomId': roomId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.chat('⚠️ Failed to update poll index: $e');
      // Don't throw - this is not critical
    }
  }

  // Vote on a poll (finds the poll in any room) - Optimized with indexing
  Future<void> voteOnPoll(String pollId, String userId, String option) async {
    try {
      // First try to get room ID from poll index
      final indexDoc = await _firestore
          .collection('poll_index')
          .doc(pollId)
          .get();
      String? roomId;

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        roomId = indexData['roomId'];
        AppLogger.chat('🎯 Found poll room from index: $roomId');
      } else {
        // Fallback: Optimized search
        AppLogger.chat('🔄 Poll index not found, using optimized search');
        final roomsSnapshot = await _firestore.collection('chats').get();

        for (final roomDoc in roomsSnapshot.docs) {
          final pollDoc = await roomDoc.reference
              .collection('polls')
              .doc(pollId)
              .get();
          if (pollDoc.exists) {
            roomId = roomDoc.id;

            // Update index for future queries
            await _updatePollIndex(pollId, roomId);
            break;
          }
        }
      }

      if (roomId == null) {
        throw Exception('Poll not found');
      }

      final pollRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('polls')
          .doc(pollId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(pollRef);
        if (!snapshot.exists) return;

        final poll = Poll.fromJson(snapshot.data()!);

        // Check if user already voted
        if (poll.userVotes.containsKey(userId)) {
          // Remove previous vote
          final previousOption = poll.userVotes[userId]!;
          if (poll.votes.containsKey(previousOption)) {
            poll.votes[previousOption] = (poll.votes[previousOption] ?? 0) - 1;
          }
        }

        // Add new vote
        poll.userVotes[userId] = option;
        poll.votes[option] = (poll.votes[option] ?? 0) + 1;

        transaction.update(pollRef, {
          'votes': poll.votes,
          'userVotes': poll.userVotes,
        });
      });

      AppLogger.chat('✅ Vote recorded for poll $pollId by user $userId');

      // Send voting reminder notifications to non-voters (if poll is still active)
      try {
        final pollNotificationService = PollNotificationService();
        // Get poll data to check if it's still active and get question
        final poll = await getPollById(pollId);
        if (poll != null && !poll.isExpired) {
          await pollNotificationService.sendVotingReminders(
            roomId: roomId,
            pollId: pollId,
            pollQuestion: poll.question,
          );
          AppLogger.chat('🔔 Voting reminders sent for poll $pollId');
        }
      } catch (e) {
        AppLogger.chat('⚠️ Failed to send voting reminders: $e');
        // Don't fail the vote if notifications fail
      }
    } catch (e) {
      throw Exception('Failed to vote on poll: $e');
    }
  }

  // Add reaction to message
  Future<void> addReactionToMessage(
    String roomId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      final reaction = MessageReaction(
        emoji: emoji,
        userId: userId,
        createdAt: DateTime.now(),
      );

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(messageRef);
        if (!snapshot.exists) return;

        final message = Message.fromJson(snapshot.data()!);
        final reactions = List<MessageReaction>.from(message.reactions ?? []);

        // Remove existing reaction from same user with same emoji
        reactions.removeWhere((r) => r.userId == userId && r.emoji == emoji);

        // Add new reaction
        reactions.add(reaction);

        transaction.update(messageRef, {
          'reactions': reactions.map((r) => r.toJson()).toList(),
        });
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  // Report a message
  Future<void> reportMessage(
    String roomId,
    String messageId,
    String reporterId,
    String reason,
  ) async {
    try {
      final reportId = _uuid.v4();
      await _firestore.collection('reported_messages').doc(reportId).set({
        'reportId': reportId,
        'roomId': roomId,
        'messageId': messageId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  // Delete message (admin only)
  Future<void> deleteMessage(String roomId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Helper method to get hierarchical path from roomId
  String _getRoomPathFromId(String roomId) {
    AppLogger.database('Parsing roomId: $roomId', tag: 'CHAT');
    // Parse roomId like "ward_maharashtra_pune_pune_m_cop_ward_17" or "area_maharashtra_pune_pune_m_cop_ward_17_माळवाडी"

    if (roomId.startsWith('ward_')) {
      // Format: ward_{stateId}_{districtId}_{bodyId}_{wardId}
      // We need to parse from the end since bodyId can contain underscores
      final withoutPrefix = roomId.substring(5); // Remove 'ward_'
      final parts = withoutPrefix.split('_');

      if (parts.length < 4) return 'chats/$roomId'; // Fallback

      // Last part is wardId, second to last is districtId, first is stateId
      // Everything in between is bodyId
      final wardId = parts.last;
      final districtId = parts[parts.length - 2];
      final stateId = parts[0];
      final bodyId = parts.sublist(1, parts.length - 2).join('_'); // Everything between state and district

      AppLogger.database('Ward parsed - state: $stateId, district: $districtId, body: $bodyId, ward: $wardId', tag: 'CHAT');
      // Path: states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/chats/ward_discussion
      return 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/chats/ward_discussion';

    } else if (roomId.startsWith('area_')) {
      // Format: area_{stateId}_{districtId}_{bodyId}_{wardId}_{areaId}
      // Use a more robust parsing approach that doesn't rely on underscore counting
      final parts = roomId.split('_');

      if (parts.length < 6) return 'chats/$roomId'; // Fallback - need at least area + 4 components + area name

      // Known positions: area(0), stateId(1), districtId(2), wardId is the one before last
      // Everything between districtId and wardId is bodyId (may contain underscores)
      // Everything after wardId is areaId (may contain underscores)

      final stateId = parts[1];
      final districtId = parts[2];

      // Find the wardId by looking for the pattern "ward_" followed by digits
      int wardIndex = -1;
      for (int i = 3; i < parts.length; i++) {
        if (parts[i].startsWith('ward') && RegExp(r'^\d+$').hasMatch(parts[i].substring(4))) {
          wardIndex = i;
          break;
        }
      }

      if (wardIndex == -1) return 'chats/$roomId'; // Fallback if ward not found

      // Everything between districtId and wardId is bodyId
      final bodyId = parts.sublist(3, wardIndex).join('_');
      final wardId = parts[wardIndex];

      // Everything after wardId is areaId
      final areaId = parts.sublist(wardIndex + 1).join('_');

      AppLogger.database('Area parsed - state: $stateId, district: $districtId, body: $bodyId, ward: $wardId, area: $areaId', tag: 'CHAT');
      // Path: states/{stateId}/districts/{districtId}/bodies/{bodyId}/wards/{wardId}/areas/{areaId}/chats/area_discussion
      return 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/areas/$areaId/chats/area_discussion';
    }

    AppLogger.database('Unknown room type, using fallback', tag: 'CHAT');
    return 'chats/$roomId'; // Fallback
  }

  // Helper methods
  Future<bool> _canUserSendMessage(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromJson(userDoc.data()!);

      // Premium users and candidates have unlimited messages
      if (user.role == 'candidate' || user.role == 'admin' || user.premium) {
        return true;
      }

      // Check quota for voters
      final quota = await getUserQuota(userId);
      if (quota == null) {
        // Create default quota
        final newQuota = UserQuota(
          userId: userId,
          lastReset: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await updateUserQuota(newQuota);
        return true;
      }

      // Reset quota if it's a new day
      final now = DateTime.now();
      if (now.difference(quota.lastReset).inDays >= 1) {
        final resetQuota = quota.copyWith(
          messagesSent: 0,
          extraQuota: 0,
          lastReset: now,
        );
        await updateUserQuota(resetQuota);
        return true;
      }

      return quota.canSendMessage;
    } catch (e) {
      return false;
    }
  }

  Future<void> _incrementUserMessageCount(String userId) async {
    try {
      final quotaRef = _firestore.collection('user_quotas').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(quotaRef);
        if (snapshot.exists) {
          final quota = UserQuota.fromJson(snapshot.data()!);
          final updatedQuota = quota.copyWith(
            messagesSent: quota.messagesSent + 1,
          );
          transaction.set(quotaRef, updatedQuota.toJson());
        }
      });
    } catch (e) {
      // Silently fail - quota tracking is not critical
    }
  }

  // Get targeted rooms for a user (optimized queries)
  Future<List<ChatRoom>> _getTargetedRoomsForUser(
    String userId,
    String userRole,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  ) async {
    AppLogger.chat('🎯 _getTargetedRoomsForUser called for $userRole: $userId');
    final rooms = <ChatRoom>[];

    try {
      if (userRole == 'candidate') {
        AppLogger.chat('👤 Processing candidate rooms for user: $userId');

        // For candidates: query hierarchical structure for ward and area rooms
        if (stateId != null && districtId != null && bodyId != null && wardId != null) {
          try {
            // Get ward room from hierarchical structure
            final wardPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/chats/ward_discussion';
            AppLogger.chat('🔍 Looking for ward room at: $wardPath');

            final wardDoc = await _firestore.doc(wardPath).get();
            if (wardDoc.exists) {
              final data = wardDoc.data() as Map<String, dynamic>;
              final room = ChatRoom.fromJson(data);
              rooms.add(room);
              AppLogger.chat('✅ Added ward room: ${room.title} (ID: ${room.roomId})');
            } else {
              AppLogger.chat('⚠️ Ward room not found at: $wardPath');
            }

            // Get area rooms from hierarchical structure
            // First, get areas from ward document to know which area rooms to look for
            try {
              AppLogger.chat('👤 Getting areas from ward document: $wardId');
              final wardDoc = await _firestore
                  .collection('states')
                  .doc(stateId)
                  .collection('districts')
                  .doc(districtId)
                  .collection('bodies')
                  .doc(bodyId)
                  .collection('wards')
                  .doc(wardId)
                  .get();

              if (wardDoc.exists) {
                final wardData = wardDoc.data() as Map<String, dynamic>;
                final areas = wardData['areas'] as List<dynamic>? ?? [];

                AppLogger.chat('👤 Found ${areas.length} areas in ward document: $areas');

                // Query for area rooms in hierarchical structure
                for (final area in areas) {
                  if (area is String && area.isNotEmpty) {
                    final areaPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/areas/$area/chats/area_discussion';
                    AppLogger.chat('🔍 Looking for area room at: $areaPath');

                    final areaDoc = await _firestore.doc(areaPath).get();
                    if (areaDoc.exists) {
                      final data = areaDoc.data() as Map<String, dynamic>;
                      final room = ChatRoom.fromJson(data);
                      rooms.add(room);
                      AppLogger.chat('✅ Added area room: ${room.title} (ID: ${room.roomId})');
                    } else {
                      AppLogger.chat('ℹ️ Area room not created yet: $areaPath');
                    }
                  }
                }
              } else {
                AppLogger.chat('⚠️ Ward document not found');
              }
            } catch (e) {
              AppLogger.chat('⚠️ Failed to get areas from ward document: $e');
            }
          } catch (e) {
            AppLogger.chat('⚠️ Failed to query hierarchical structure: $e');
          }
        }

        // Add private chats for candidates
        try {
          AppLogger.chat('👤 Getting private chats for candidate: $userId');
          final privateRooms = await _firestore
              .collection('chats')
              .where('type', isEqualTo: 'private')
              .where('members', arrayContains: userId)
              .get();

          for (final doc in privateRooms.docs) {
            final data = doc.data();
            final room = ChatRoom.fromJson(data);
            rooms.add(room);
            AppLogger.chat('✅ Added private room for candidate: ${room.title} (ID: ${room.roomId})');
          }
          AppLogger.chat('👤 Found ${privateRooms.docs.length} private rooms for candidate');
        } catch (e) {
          AppLogger.chat('⚠️ Failed to get private rooms for candidate: $e');
        }

      } else if (userRole == 'voter') {
        AppLogger.chat('🗳️ Processing voter rooms for user: $userId');
        // For voters: get ward room + area room + followed candidate rooms
        final roomIds = <String>[];

        // Add ward and area rooms if location data is available
        if (stateId != null && districtId != null && bodyId != null && wardId != null) {
          roomIds.add('ward_${districtId}_${bodyId}_$wardId');

          if (area != null && area.isNotEmpty) {
            roomIds.add('area_${districtId}_${bodyId}_${wardId}_$area');
          }

          // Get followed candidate rooms in the same ward
          final followedCandidateIds = await _candidateRepository.getUserFollowing(userId);
          if (followedCandidateIds.isNotEmpty) {
            final wardCandidateIds = await _getCandidateIdsInWard(districtId, bodyId, wardId);
            final relevantCandidateIds = followedCandidateIds.where((id) => wardCandidateIds.contains(id)).toList();

            for (final candidateId in relevantCandidateIds) {
              final candidateRooms = await _getCandidateRoomIds(candidateId);
              roomIds.addAll(candidateRooms);
            }
          }
        }

        AppLogger.chat('🗳️ Voter roomIds to query: $roomIds');

        // Query specific rooms from hierarchical structure
        for (final roomId in roomIds.toSet()) { // Remove duplicates
          try {
            AppLogger.chat('🔍 Checking room: $roomId');
            ChatRoom? room;

            // Use location data to construct the correct hierarchical path
            String roomPath;
            if (roomId.startsWith('ward_') && stateId != null && districtId != null && bodyId != null && wardId != null) {
              roomPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/chats/ward_discussion';
              AppLogger.chat('🔍 Constructed ward path: $roomPath');
            } else if (roomId.startsWith('area_') && stateId != null && districtId != null && bodyId != null && wardId != null && area != null) {
              roomPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/areas/$area/chats/area_discussion';
              AppLogger.chat('🔍 Constructed area path: $roomPath');
            } else {
              AppLogger.chat('⚠️ Cannot construct path for roomId: $roomId');
              continue;
            }

            final hierarchicalDoc = await _firestore.doc(roomPath).get();
            if (hierarchicalDoc.exists) {
              final data = hierarchicalDoc.data() as Map<String, dynamic>;
              room = ChatRoom.fromJson(data);
              AppLogger.chat('✅ Found room at hierarchical path: ${room?.title}');
            } else {
              AppLogger.chat('⚠️ Room not found at hierarchical path: $roomPath');
            }

            if (room != null) {
              rooms.add(room);
              AppLogger.chat('✅ Added room: ${room.title}');
            }
          } catch (e) {
            AppLogger.chat('⚠️ Failed to fetch room $roomId: $e');
          }
        }

        // Add private chats for voters
        try {
          AppLogger.chat('🗳️ Getting private chats for voter: $userId');
          final privateRooms = await _firestore
              .collection('chats')
              .where('type', isEqualTo: 'private')
              .where('members', arrayContains: userId)
              .get();

          for (final doc in privateRooms.docs) {
            final data = doc.data();
            final room = ChatRoom.fromJson(data);
            rooms.add(room);
            AppLogger.chat('✅ Added private room for voter: ${room.title} (ID: ${room.roomId})');
          }
          AppLogger.chat('🗳️ Found ${privateRooms.docs.length} private rooms for voter');
        } catch (e) {
          AppLogger.chat('⚠️ Failed to get private rooms for voter: $e');
        }
      }

      // If no rooms found through targeted query, fall back to collection group query
      if (rooms.isEmpty) {
        AppLogger.chat('⚠️ No rooms found through targeted query, falling back to collection group query');
        final fallbackRooms = await _fallbackCollectionGroupQuery(userId, userRole);
        rooms.addAll(fallbackRooms);
        AppLogger.chat('✅ Added ${fallbackRooms.length} rooms from fallback query');
      }

      AppLogger.chat('✅ Targeted query returned ${rooms.length} rooms');
      return rooms;

    } catch (e) {
      AppLogger.chat('❌ Error in targeted room query: $e');
      // Fallback to old method if targeted query fails
      AppLogger.chat('🔄 Falling back to collection group query');
      return await _fallbackCollectionGroupQuery(userId, userRole);
    }
  }

  // Get candidate room IDs for a specific candidate
  Future<List<String>> _getCandidateRoomIds(String candidateId) async {
    try {
      // Query for rooms created by this candidate
      final snapshot = await _firestore
          .collection('chats')
          .where('createdBy', isEqualTo: candidateId)
          .where('type', isEqualTo: 'public') // Only public candidate rooms
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      AppLogger.chat('⚠️ Failed to get candidate rooms for $candidateId: $e');
      return [];
    }
  }

  // Fallback method using collection group (for error recovery)
  Future<List<ChatRoom>> _fallbackCollectionGroupQuery(String userId, String userRole) async {
    try {
      final allRoomsSnapshot = await _firestore.collectionGroup('chats').get();
      final roomsFromSnapshot = allRoomsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ChatRoom.fromJson(data);
      }).toList();

      // Filter rooms client-side (no index required)
      final publicRooms = roomsFromSnapshot.where((room) => room.type == 'public').toList();
      final privateRooms = roomsFromSnapshot.where((room) =>
        room.type == 'private' && (room.members?.contains(userId) ?? false)
      ).toList();

      return [...publicRooms, ...privateRooms];
    } catch (e) {
      AppLogger.chat('❌ Fallback query also failed: $e');
      return [];
    }
  }

  // Get candidate user IDs in a specific ward
  Future<List<String>> _getCandidateIdsInWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    // BREAKPOINT CANDIDATE-1: Start of _getCandidateIdsInWard
    AppLogger.chat(
      '🔍 BREAKPOINT CANDIDATE-1: Getting candidates for ward $wardId in body $bodyId, district $districtId',
    );

    try {
      // BREAKPOINT CANDIDATE-2: Before Firestore query
      AppLogger.chat(
        '🔍 BREAKPOINT CANDIDATE-2: Querying Firestore for candidates',
      );
      final query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'candidate')
          .where('districtId', isEqualTo: districtId)
          .where('bodyId', isEqualTo: bodyId)
          .where('wardId', isEqualTo: wardId);

      final snapshot = await query.get();

      // BREAKPOINT CANDIDATE-3: After query results
      AppLogger.chat(
        '🔍 BREAKPOINT CANDIDATE-3: Found ${snapshot.docs.length} candidate documents',
      );
      final candidateIds = snapshot.docs.map((doc) => doc.id).toList();
      AppLogger.chat('🔍 BREAKPOINT CANDIDATE-3: Candidate IDs: $candidateIds');

      // BREAKPOINT CANDIDATE-4: Returning result
      AppLogger.chat(
        '🔍 BREAKPOINT CANDIDATE-4: Returning ${candidateIds.length} candidate IDs',
      );
      return candidateIds;
    } catch (e) {
      AppLogger.chat(
        '❌ BREAKPOINT CANDIDATE-5: Error getting candidate IDs in ward: $e',
      );
      return [];
    }
  }

  // Check if ward room exists
  Future<bool> wardRoomExists(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      final wardRoomId = 'ward_${districtId}_${bodyId}_$wardId';
      final doc = await _firestore.collection('chats').doc(wardRoomId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.chat('Error checking ward room existence: $e');
      return false;
    }
  }

  // Check if area room exists
  Future<bool> areaRoomExists(
    String districtId,
    String bodyId,
    String wardId,
    String areaId,
  ) async {
    try {
      final areaRoomId = 'area_${districtId}_${bodyId}_${wardId}_$areaId';
      final doc = await _firestore.collection('chats').doc(areaRoomId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.chat('Error checking area room existence: $e');
      return false;
    }
  }

  // Create area room if it doesn't exist
  Future<bool> createAreaRoomIfNeeded(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
    String areaId,
    String creatorId,
  ) async {
    try {
      final areaRoomId = 'area_${stateId}_${districtId}_${bodyId}_${wardId}_$areaId';

      // Check if room already exists
      if (await areaRoomExists(districtId, bodyId, wardId, areaId)) {
        AppLogger.chat('Area room already exists: $areaRoomId');
        return true;
      }

      // Get district, body, ward and area names
      final districtName = await _getDistrictName(districtId);
      final bodyName = await _getBodyName(districtId, bodyId);
      final wardName = await _getWardName(districtId, bodyId, wardId);
      final areaName = await _getAreaName(districtId, bodyId, wardId, areaId);

      // Create area room
      final chatRoom = ChatRoom(
        roomId: areaRoomId,
        createdAt: DateTime.now(),
        createdBy: creatorId,
        type: 'public',
        title: (areaName.isNotEmpty) ? '$areaName Discussion' : 'Area $areaId',
        description: areaName.isNotEmpty
            ? 'Public discussion for $areaName in $wardName'
            : 'Public discussion forum for Area $areaId residents',
      );

      await createChatRoom(chatRoom);
      AppLogger.chat('✅ Area room created: $areaRoomId');

      // Invalidate cache
      invalidateLocationCache(districtId, wardId);

      return true;
    } catch (e) {
      AppLogger.chat('❌ Failed to create area room: $e');
      return false;
    }
  }

  // Create ward room if it doesn't exist
  Future<bool> createWardRoomIfNeeded(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
    String creatorId,
  ) async {
    try {
      final wardRoomId = 'ward_${stateId}_${districtId}_${bodyId}_$wardId';

      // Check if room already exists
      if (await wardRoomExists(districtId, bodyId, wardId)) {
        AppLogger.chat('Ward room already exists: $wardRoomId');
        return true;
      }

      // Get district, body and ward names
      final districtName = await _getDistrictName(districtId);
      final bodyName = await _getBodyName(districtId, bodyId);
      final wardName = await _getWardName(districtId, bodyId, wardId);

      // Create ward room
      final chatRoom = ChatRoom(
        roomId: wardRoomId,
        createdAt: DateTime.now(),
        createdBy: creatorId,
        type: 'public',
        title: (districtName.isNotEmpty && wardName.isNotEmpty)
            ? '$districtName - $wardName'
            : 'Ward $wardId',
        description: wardName.isNotEmpty
            ? 'Public discussion for $wardName in $bodyName'
            : 'Public discussion forum for Ward $wardId residents in $bodyName',
      );

      await createChatRoom(chatRoom);
      AppLogger.chat('✅ Ward room created: $wardRoomId');

      // Invalidate cache
      invalidateLocationCache(districtId, wardId);

      return true;
    } catch (e) {
      AppLogger.chat('❌ Failed to create ward room: $e');
      return false;
    }
  }

  // Helper methods for district, body and ward names
  Future<String> _getDistrictName(String districtId) async {
    try {
      final districtDoc = await _firestore
          .collection('districts')
          .doc(districtId)
          .get();
      if (districtDoc.exists) {
        final data = districtDoc.data();
        return data?['name'] ?? districtId.toUpperCase();
      }
    } catch (e) {
      AppLogger.chat('Error fetching district name: $e');
    }
    return districtId.toUpperCase();
  }

  Future<String> _getBodyName(String districtId, String bodyId) async {
    try {
      final bodyDoc = await _firestore
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
      AppLogger.chat('Error fetching body name: $e');
    }
    return bodyId;
  }

  Future<String> _getWardName(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      // Get from districts -> bodies -> wards structure
      final wardDoc = await _firestore
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

      // Fallback to old cities structure for backward compatibility
      final fallbackWardDoc = await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc('default') // Default body for backward compatibility
          .collection('wards')
          .doc(wardId)
          .get();
      if (fallbackWardDoc.exists) {
        final data = fallbackWardDoc.data();
        return data?['name'] ?? 'Ward $wardId';
      }
    } catch (e) {
      AppLogger.chat('Error fetching ward name: $e');
    }
    return 'Ward $wardId';
  }

  // Get area name from district ID, body ID, ward ID and area ID
  Future<String> _getAreaName(
    String districtId,
    String bodyId,
    String wardId,
    String areaId,
  ) async {
    try {
      // Get from districts -> bodies -> wards -> areas structure
      final areaDoc = await _firestore
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('areas')
          .doc(areaId)
          .get();

      if (areaDoc.exists) {
        final data = areaDoc.data();
        return data?['name'] ?? 'Area $areaId';
      }
    } catch (e) {
      AppLogger.chat('Error fetching area name: $e');
    }
    return 'Area $areaId';
  }

  // Typing status management
  Future<void> updateTypingStatus(String roomId, String userId, String userName, bool isTyping) async {
    try {
      final typingRef = _firestore.collection('typing_status').doc('${roomId}_$userId');

      if (isTyping) {
        await typingRef.set({
          'userId': userId,
          'roomId': roomId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      AppLogger.chat('Error updating typing status: $e');
    }
  }

  // Get typing status stream for a room
  Stream<List<TypingStatus>> getTypingStatusForRoom(String roomId) {
    return _firestore
        .collection('typing_status')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                data['timestamp'] = data['timestamp']?.toDate()?.toIso8601String() ?? now.toIso8601String();
                return TypingStatus.fromJson(data);
              })
              .where((status) => !status.isExpired)
              .toList();
        });
  }

  // Clean up expired typing statuses (call periodically)
  Future<void> cleanupExpiredTypingStatuses() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(seconds: 5));
      final expiredDocs = await _firestore
          .collection('typing_status')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredDocs.docs) {
        batch.delete(doc.reference);
      }

      if (expiredDocs.docs.isNotEmpty) {
        await batch.commit();
        AppLogger.chat('Cleaned up ${expiredDocs.docs.length} expired typing statuses');
      }
    } catch (e) {
      AppLogger.chat('Error cleaning up typing statuses: $e');
    }
  }

  // Clear typing status for a specific user in a room
  Future<void> clearTypingStatus(String roomId, String userId) async {
    try {
      final typingRef = _firestore.collection('typing_status').doc('${roomId}_$userId');
      await typingRef.delete();
      AppLogger.chat('🧹 Cleared typing status for user $userId in room $roomId');
    } catch (e) {
      AppLogger.chat('Error clearing typing status: $e');
    }
  }

  // Get unread message count for user
  Future<int> getUnreadMessageCount(
    String userId, {
    String? userRole,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
    String? area,
  }) async {
    try {
      // Get user's role and location if not provided
      if (userRole == null ||
          stateId == null ||
          districtId == null ||
          wardId == null ||
          area == null) {
        // OPTIMIZED: Use UserDataController for cached user data
        final userDataController = Get.find<UserDataController>();
        if (userDataController.isInitialized.value && userDataController.currentUser.value != null) {
          final userModel = userDataController.currentUser.value!;
          userRole ??= userModel.role ?? 'voter';
          stateId ??= userModel.stateId;
          districtId ??= userModel.districtId;
          bodyId ??= userModel.bodyId;
          wardId ??= userModel.wardId;
          area ??= userModel.area;
        } else {
          // Fallback to fresh fetch if cache not available
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userRole ??= userData['role'] ?? 'voter';
            stateId ??= userData['stateId'];
            districtId ??=
                userData['districtId'] ??
                userData['cityId']; // Backward compatibility
            bodyId ??= userData['bodyId'];
            wardId ??= userData['wardId'];
            area ??= userData['area'];
          }
        }
      }

      // Get accessible rooms for this user (this will now use selective candidate filtering)
      final rooms = await getChatRoomsForUser(
        userId,
        userRole ?? 'voter',
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
        area: area,
      );
      int totalUnread = 0;

      for (final room in rooms) {
        final messages = await _firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .where('readBy', arrayContains: userId)
            .get();

        // Count messages not read by user
        final totalMessages = await _firestore
            .collection('chats')
            .doc(room.roomId)
            .collection('messages')
            .get();

        totalUnread += totalMessages.docs.length - messages.docs.length;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }

  // Send notification to room members when a new message is sent
  Future<void> _sendMessageNotification(String roomId, Message message) async {
    try {
      // Get room data from hierarchical structure to find members
      final roomPath = _getRoomPathFromId(roomId);
      final roomDoc = await _firestore.doc(roomPath).get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(roomData['members'] ?? []);

      // OPTIMIZED: Use UserDataController for sender info
      // Get sender info
      final userDataController = Get.find<UserDataController>();
      String senderName = 'Someone';
      if (userDataController.isInitialized.value && userDataController.currentUser.value != null) {
        final userModel = userDataController.currentUser.value!;
        if (userModel.uid == message.senderId) {
          senderName = userModel.name;
        } else {
          // Fallback to direct fetch for other users
          final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
          senderName = senderDoc.exists
              ? (senderDoc.data()?['name'] ?? 'Someone')
              : 'Someone';
        }
      } else {
        // Fallback to direct fetch if cache not available
        final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
        senderName = senderDoc.exists
            ? (senderDoc.data()?['name'] ?? 'Someone')
            : 'Someone';
      }

      // Send notification to each member except the sender
      final notificationManager = NotificationManager();
      for (final memberId in members) {
        if (memberId != message.senderId) {
          try {
            await notificationManager.sendNotification(
              type: NotificationType.newMessage,
              title: 'New Message',
              body: '$senderName: ${message.text.length > 50 ? message.text.substring(0, 50) + '...' : message.text}',
              data: {
                'senderId': message.senderId,
                'senderName': senderName,
                'roomId': roomId,
                'messageId': message.messageId,
                'type': 'new_message',
              },
            );
          } catch (e) {
            AppLogger.chat('⚠️ Failed to send message notification to user $memberId: $e');
          }
        }
      }

      AppLogger.chat('✅ Sent message notifications to ${members.length - 1} room members');
    } catch (e) {
      AppLogger.chat('⚠️ Failed to send message notifications: $e');
      // Don't throw - this shouldn't break message sending
    }
  }
}

