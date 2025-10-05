import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../candidate/repositories/candidate_repository.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();
  final CandidateRepository _candidateRepository = CandidateRepository();

  // Repository-level caching
  static final Map<String, List<ChatRoom>> _roomCache = {};
  static final Map<String, DateTime> _roomTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(
    minutes: 15,
  ); // Longer than controller cache

  // Check if cache is valid
  bool _isCacheValid(String cacheKey) {
    if (!_roomTimestamps.containsKey(cacheKey)) return false;
    final cacheTime = _roomTimestamps[cacheKey]!;
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  // Cache rooms for a user
  void _cacheRooms(String cacheKey, List<ChatRoom> rooms) {
    _roomCache[cacheKey] = List.from(rooms);
    _roomTimestamps[cacheKey] = DateTime.now();
  }

  // Get cached rooms
  List<ChatRoom>? _getCachedRooms(String cacheKey) {
    return _isCacheValid(cacheKey) ? _roomCache[cacheKey] : null;
  }

  // Public method to get cached rooms (for controller use)
  List<ChatRoom>? getCachedRooms(String cacheKey) {
    return _getCachedRooms(cacheKey);
  }

  // Invalidate cache for a user
  void invalidateUserCache(String userId) {
    final keysToRemove = _roomCache.keys
        .where((key) => key.contains(userId))
        .toList();
    for (final key in keysToRemove) {
      _roomCache.remove(key);
      _roomTimestamps.remove(key);
    }
    debugPrint(
      '🗑️ Invalidated ${keysToRemove.length} cache entries for user: $userId',
    );
  }

  // Invalidate cache for a specific role
  void invalidateRoleCache(String userRole) {
    final keysToRemove = _roomCache.keys
        .where((key) => key.contains('_${userRole}_'))
        .toList();
    for (final key in keysToRemove) {
      _roomCache.remove(key);
      _roomTimestamps.remove(key);
    }
    debugPrint(
      '🗑️ Invalidated ${keysToRemove.length} cache entries for role: $userRole',
    );
  }

  // Invalidate cache for a specific location
  void invalidateLocationCache(String cityId, String wardId) {
    final locationPattern = '${cityId}_$wardId';
    final keysToRemove = _roomCache.keys
        .where((key) => key.contains(locationPattern))
        .toList();
    for (final key in keysToRemove) {
      _roomCache.remove(key);
      _roomTimestamps.remove(key);
    }
    debugPrint(
      '🗑️ Invalidated ${keysToRemove.length} cache entries for location: $locationPattern',
    );
  }

  // Invalidate cache when user follows/unfollows a candidate
  void invalidateUserFollowCache(String userId) {
    final keysToRemove = _roomCache.keys
        .where((key) => key.startsWith('${userId}_voter_'))
        .toList();
    for (final key in keysToRemove) {
      _roomCache.remove(key);
      _roomTimestamps.remove(key);
    }
    debugPrint(
      '🗑️ Invalidated ${keysToRemove.length} cache entries for user follow changes: $userId',
    );
  }

  // Clear all expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _roomTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheValidityDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _roomCache.remove(key);
      _roomTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('🧹 Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'total_entries': _roomCache.length,
      'cache_size_mb':
          (_roomCache.values
              .map(
                (rooms) => rooms.length * 1024,
              ) // Rough estimate: 1KB per room
              .fold(0, (a, b) => a + b) /
          (1024 * 1024)),
      'oldest_entry': _roomTimestamps.values.isNotEmpty
          ? _roomTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest_entry': _roomTimestamps.values.isNotEmpty
          ? _roomTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // Get chat rooms for a user
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
    debugPrint('🔍 BREAKPOINT REPO-1: getChatRoomsForUser called');
    debugPrint(
      '🔍 BREAKPOINT REPO-1: User ID: $userId, Role: $userRole, State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId',
    );

    // Create cache key based on user and parameters
    final cacheKey = userRole == 'voter'
        ? '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}'
        : '${userId}_${userRole}_${stateId ?? 'no_state'}_${districtId ?? 'no_district'}_${bodyId ?? 'no_body'}_${wardId ?? 'no_ward'}_${area ?? 'no_area'}';

    // BREAKPOINT REPO-2: Cache check
    debugPrint('🔍 BREAKPOINT REPO-2: Cache key: $cacheKey');

    // Check cache first
    final cachedRooms = _getCachedRooms(cacheKey);
    if (cachedRooms != null) {
      debugPrint(
        '⚡ REPOSITORY CACHE HIT: Returning ${cachedRooms.length} cached rooms for $userRole',
      );
      return cachedRooms;
    }

    debugPrint(
      '🔄 REPOSITORY CACHE MISS: Fetching rooms from Firebase for $userRole',
    );

    try {
      // BREAKPOINT REPO-3: Location data check
      debugPrint(
        '🔍 BREAKPOINT REPO-3: Initial location data - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
      );

      // If location data is not provided, try to get it from user profile
      if (stateId == null || districtId == null || bodyId == null || wardId == null) {
        debugPrint(
          '🔍 BREAKPOINT REPO-4: Fetching location data from user profile',
        );
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          stateId = userData['stateId'];
          districtId =
              userData['districtId'] ??
              userData['cityId']; // Backward compatibility
          bodyId = userData['bodyId'];
          wardId = userData['wardId'];
          area = userData['area'];
          debugPrint(
            '🔍 BREAKPOINT REPO-4: Updated location data - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
          );
        } else {
          debugPrint('🔍 BREAKPOINT REPO-4: User document not found');
        }
      }

      // BREAKPOINT REPO-5: Before Firebase query
      debugPrint(
        '🔍 BREAKPOINT REPO-5: Querying Firebase for rooms - Role: $userRole',
      );

      List<ChatRoom> allRooms = [];
      Query query = _firestore.collection('chats');

      if (userRole == 'admin') {
        // BREAKPOINT REPO-6: Admin query
        debugPrint('🔍 BREAKPOINT REPO-6: Admin user - fetching all rooms');
        query = query.orderBy('createdAt', descending: true);
        final snapshot = await query.get();
        allRooms = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['roomId'] = doc.id;
          return ChatRoom.fromJson(data);
        }).toList();
        debugPrint(
          '🔍 BREAKPOINT REPO-6: Admin fetched ${allRooms.length} rooms',
        );
      } else {
        // BREAKPOINT REPO-7: Non-admin query
        debugPrint(
          '🔍 BREAKPOINT REPO-7: Non-admin user - fetching public rooms',
        );

        // Get public rooms
        final publicQuery = query.where('type', isEqualTo: 'public');
        final publicSnapshot = await publicQuery.get();
        final publicRooms = publicSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['roomId'] = doc.id;
          return ChatRoom.fromJson(data);
        }).toList();

        // Get private rooms where user is a member
        final privateQuery = _firestore
            .collection('chats')
            .where('type', isEqualTo: 'private')
            .where('members', arrayContains: userId);
        final privateSnapshot = await privateQuery.get();
        final privateRooms = privateSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['roomId'] = doc.id;
          return ChatRoom.fromJson(data);
        }).toList();

        // Combine public and private rooms
        allRooms = [...publicRooms, ...privateRooms];
        debugPrint(
          '🔍 BREAKPOINT REPO-7: Fetched ${publicRooms.length} public + ${privateRooms.length} private = ${allRooms.length} total rooms',
        );

        // Filter based on user role and location
        if (userRole == 'candidate') {
          // BREAKPOINT REPO-8: Candidate filtering
          debugPrint('🔍 BREAKPOINT REPO-8: Filtering rooms for candidate');
          debugPrint(
            '🔍 BREAKPOINT REPO-8: User location - State: $stateId, District: $districtId, Body: $bodyId, Ward: $wardId, Area: $area',
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
                room.roomId.startsWith(
                  'area_${stateId}_${districtId}_${bodyId}_${wardId}_',
                );
            final isCandidateRoom =
                room.roomId.startsWith('candidate_') &&
                room.createdBy == userId;

            // Include private chats where user is a member
            final isPrivateChat = room.type == 'private' && room.members != null && room.members!.contains(userId);

            // Include rooms that are relevant to this candidate's location or their own candidate room
            final shouldInclude =
                isOwnRoom || isWardRoom || isAreaRoom || isCandidateRoom || isPrivateChat;

            if (shouldInclude) {
              debugPrint(
                '🔍 BREAKPOINT REPO-8: Including room: ${room.roomId} (own: $isOwnRoom, ward: $isWardRoom, area: $isAreaRoom, candidate: $isCandidateRoom, private: $isPrivateChat)',
              );
            }

            return shouldInclude;
          }).toList();
          debugPrint(
            '🔍 BREAKPOINT REPO-8: Candidate filtered to ${allRooms.length} rooms',
          );
        } else {
          // BREAKPOINT REPO-9: Voter filtering
          debugPrint('🔍 BREAKPOINT REPO-9: Filtering rooms for voter');
          if (stateId != null && districtId != null && bodyId != null && wardId != null) {
            final wardRoomId = 'ward_${stateId}_${districtId}_${bodyId}_$wardId';
            final areaRoomId = area != null
                ? 'area_${stateId}_${districtId}_${bodyId}_${wardId}_$area'
                : null;
            debugPrint(
              '🔍 BREAKPOINT REPO-9: Looking for ward room: $wardRoomId',
            );
            if (areaRoomId != null) {
              debugPrint(
                '🔍 BREAKPOINT REPO-9: Looking for area room: $areaRoomId',
              );
            }

            // Get list of candidates the voter is following
            final followedCandidateIds = await _candidateRepository
                .getUserFollowing(userId);
            debugPrint(
              '🔍 BREAKPOINT REPO-9: Voter follows ${followedCandidateIds.length} candidates',
            );

            // Get list of candidate user IDs in the same ward (for filtering followed candidates)
            final wardCandidateIds = await _getCandidateIdsInWard(
              districtId,
              bodyId,
              wardId,
            );
            debugPrint(
              '🔍 BREAKPOINT REPO-9: Found ${wardCandidateIds.length} candidates in ward',
            );

            // Only include candidates that are both followed AND in the same ward
            final relevantCandidateIds = followedCandidateIds
                .where((candidateId) => wardCandidateIds.contains(candidateId))
                .toList();
            debugPrint(
              '🔍 BREAKPOINT REPO-9: Found ${relevantCandidateIds.length} followed candidates in ward',
            );

            allRooms = allRooms.where((room) {
              // Include ward room
              if (room.roomId == wardRoomId) {
                debugPrint(
                  '🔍 BREAKPOINT REPO-9: Including ward room: ${room.roomId}',
                );
                return true;
              }

              // Include area room if user has area
              if (areaRoomId != null && room.roomId == areaRoomId) {
                debugPrint(
                  '🔍 BREAKPOINT REPO-9: Including area room: ${room.roomId}',
                );
                return true;
              }

              // Include rooms created by followed candidates in the same ward
              if (relevantCandidateIds.contains(room.createdBy)) {
                debugPrint(
                  '🔍 BREAKPOINT REPO-9: Including followed candidate room: ${room.roomId} by ${room.createdBy}',
                );
                return true;
              }

              // Include private chats where user is a member
              if (room.type == 'private' && room.members != null && room.members!.contains(userId)) {
                debugPrint(
                  '🔍 BREAKPOINT REPO-9: Including private chat: ${room.roomId}',
                );
                return true;
              }

              return false;
            }).toList();
            debugPrint(
              '🔍 BREAKPOINT REPO-9: Voter filtered to ${allRooms.length} rooms',
            );
          } else {
            // BREAKPOINT REPO-10: No location data
            debugPrint(
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
      debugPrint(
        '🔍 BREAKPOINT REPO-11: Final rooms list - ${allRooms.length} unique rooms',
      );
      for (var room in allRooms) {
        debugPrint(
          '   Final room: ${room.roomId} - ${room.title} (${room.type})',
        );
      }

      // Cache the results
      _cacheRooms(cacheKey, allRooms);
      debugPrint('💾 Cached ${allRooms.length} rooms for cache key: $cacheKey');

      // BREAKPOINT REPO-12: Returning result
      debugPrint(
        '🔍 BREAKPOINT REPO-12: Returning ${allRooms.length} rooms to controller',
      );
      return allRooms;
    } catch (e) {
      throw Exception('Failed to fetch chat rooms: $e');
    }
  }

  // Create a new chat room
  Future<ChatRoom> createChatRoom(ChatRoom chatRoom) async {
    // BREAKPOINT CREATE-1: Start of createChatRoom
    debugPrint('🔍 BREAKPOINT CREATE-1: createChatRoom called');
    debugPrint(
      '🔍 BREAKPOINT CREATE-1: Room ID: ${chatRoom.roomId}, Title: ${chatRoom.title}, Type: ${chatRoom.type}',
    );
    debugPrint('🔍 BREAKPOINT CREATE-1: Created by: ${chatRoom.createdBy}');

    try {
      // BREAKPOINT CREATE-2: Before Firestore operation
      debugPrint('🔍 BREAKPOINT CREATE-2: Setting room data in Firestore');
      final docRef = _firestore.collection('chats').doc(chatRoom.roomId);
      await docRef.set(chatRoom.toJson());

      // BREAKPOINT CREATE-3: After successful creation
      debugPrint(
        '🔍 BREAKPOINT CREATE-3: Room successfully created in Firestore',
      );

      // Invalidate cache for the creator (they might see new rooms)
      invalidateUserCache(chatRoom.createdBy);
      debugPrint(
        '🗑️ Invalidated cache for user ${chatRoom.createdBy} after room creation',
      );

      // BREAKPOINT CREATE-4: Returning result
      debugPrint(
        '🔍 BREAKPOINT CREATE-4: Returning created room: ${chatRoom.roomId}',
      );
      return chatRoom;
    } catch (e) {
      // BREAKPOINT CREATE-5: Error occurred
      debugPrint('❌ BREAKPOINT CREATE-5: Failed to create chat room: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Batch: Create room and add initial members
  Future<ChatRoom> createRoomWithMembers(
    ChatRoom chatRoom,
    List<String> memberIds,
  ) async {
    try {
      debugPrint(
        '📦 BATCH: Creating room with ${memberIds.length} initial members',
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
            debugPrint('🗑️ Invalidated cache for member: $memberId');
          }
        }
      }

      debugPrint('✅ BATCH: Room created with initial members');
      return chatRoom;
    } catch (e) {
      debugPrint('❌ BATCH: Failed to create room with members: $e');
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
      debugPrint('📦 BATCH: Initializing app data for user');

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

      debugPrint(
        '✅ BATCH: App data initialized - ${rooms.length} rooms, $unreadCount unread messages',
      );

      return {
        'user': userData['user'],
        'quota': userData['quota'],
        'rooms': rooms,
        'unreadCount': unreadCount,
      };
    } catch (e) {
      debugPrint('❌ BATCH: Failed to initialize app data: $e');
      throw Exception('Failed to initialize app data: $e');
    }
  }

  // Get messages for a chat room
  Stream<List<Message>> getMessagesForRoom(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
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
              debugPrint('⚠️ Message ${doc.id} missing status field, defaulting to sent');
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
          debugPrint('⚠️ Message ${doc.id} missing status field, defaulting to sent');
        }

        return Message.fromJson(data);
      }).where((message) => message != null).cast<Message>().toList();
    } catch (e) {
      debugPrint('❌ Error loading paginated messages: $e');
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
      debugPrint('❌ Error getting oldest message timestamp: $e');
      return null;
    }
  }

  // Send a message
  Future<Message> sendMessage(String roomId, Message message) async {
    try {
      // Only log in debug mode
      assert(() {
        debugPrint(
          '💾 Repository: Sending message "${message.text}" to room $roomId',
        );
        return true;
      }());

      final docRef = _firestore
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .doc(message.messageId);

      await docRef.set(message.toJson());

      // Only log in debug mode
      assert(() {
        debugPrint('✅ Repository: Message saved to Firestore successfully');
        return true;
      }());

      // Quota/XP handling is now done in the controller

      return message;
    } catch (e) {
      // Only log in debug mode
      assert(() {
        debugPrint('❌ Repository: Failed to send message: $e');
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
      debugPrint('📦 BATCH: Sending message with quota/XP update');

      // Perform the transaction with all reads first, then all writes
      final result = await _firestore.runTransaction((transaction) async {
        // READ PHASE: Get all data we need first
        UserQuota? currentQuota;
        if (useQuota) {
          final quotaRef = _firestore.collection('user_quotas').doc(userId);
          final quotaSnapshot = await transaction.get(quotaRef);
          if (quotaSnapshot.exists) {
            currentQuota = UserQuota.fromJson(quotaSnapshot.data()!);
            debugPrint(
              '📊 Current quota before update: ${currentQuota.remainingMessages} messages',
            );
          } else {
            debugPrint('📊 No quota found, will create default quota');
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
            debugPrint(
              '📊 Updated quota: ${updatedQuota.remainingMessages} messages remaining',
            );
          } else {
            // No quota exists - create default with 1 message already sent
            debugPrint('📊 Creating default quota with 1 message sent');
            updatedQuota = UserQuota(
              userId: userId,
              dailyLimit: 20,
              messagesSent: 1, // Start with 1 since we're sending a message
              extraQuota: 0,
              lastReset: DateTime.now(),
              createdAt: DateTime.now(),
            );
            transaction.set(quotaRef, updatedQuota.toJson());
            debugPrint(
              '📊 Created new quota: ${updatedQuota.remainingMessages} messages remaining',
            );
          }
        }

        // 3. Update XP if needed
        if (useXP) {
          final userRef = _firestore.collection('users').doc(userId);
          transaction.update(userRef, {'xpPoints': FieldValue.increment(-1)});
          debugPrint('⭐ XP decremented by 1');
        }

        return {'message': message, 'quota': updatedQuota};
      });

      debugPrint(
        '✅ BATCH: Message sent with quota/XP update in single transaction',
      );
      return result;
    } catch (e) {
      debugPrint('❌ BATCH: Failed to send message with quota update: $e');
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
      debugPrint('📦 BATCH: Fetching user data and quota together');

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

      debugPrint('✅ BATCH: Retrieved user data and quota in single operation');
      return {'user': user, 'quota': quota};
    } catch (e) {
      debugPrint('❌ BATCH: Failed to get user data and quota: $e');
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

      debugPrint('✅ Poll created and indexed: ${poll.pollId} in room $roomId');
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

        debugPrint('🎯 Found poll in indexed room: $roomId');

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
      debugPrint('🔄 Poll index not found, using optimized search');
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
      debugPrint('⚠️ Failed to update poll index: $e');
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
        debugPrint('🎯 Found poll room from index: $roomId');
      } else {
        // Fallback: Optimized search
        debugPrint('🔄 Poll index not found, using optimized search');
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

      debugPrint('✅ Vote recorded for poll $pollId by user $userId');
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

  // Get candidate user IDs in a specific ward
  Future<List<String>> _getCandidateIdsInWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    // BREAKPOINT CANDIDATE-1: Start of _getCandidateIdsInWard
    debugPrint(
      '🔍 BREAKPOINT CANDIDATE-1: Getting candidates for ward $wardId in body $bodyId, district $districtId',
    );

    try {
      // BREAKPOINT CANDIDATE-2: Before Firestore query
      debugPrint(
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
      debugPrint(
        '🔍 BREAKPOINT CANDIDATE-3: Found ${snapshot.docs.length} candidate documents',
      );
      final candidateIds = snapshot.docs.map((doc) => doc.id).toList();
      debugPrint('🔍 BREAKPOINT CANDIDATE-3: Candidate IDs: $candidateIds');

      // BREAKPOINT CANDIDATE-4: Returning result
      debugPrint(
        '🔍 BREAKPOINT CANDIDATE-4: Returning ${candidateIds.length} candidate IDs',
      );
      return candidateIds;
    } catch (e) {
      debugPrint(
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
      debugPrint('Error checking ward room existence: $e');
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
      debugPrint('Error checking area room existence: $e');
      return false;
    }
  }

  // Create area room if it doesn't exist
  Future<bool> createAreaRoomIfNeeded(
    String districtId,
    String bodyId,
    String wardId,
    String areaId,
    String creatorId,
  ) async {
    try {
      final areaRoomId = 'area_${districtId}_${bodyId}_${wardId}_$areaId';

      // Check if room already exists
      if (await areaRoomExists(districtId, bodyId, wardId, areaId)) {
        debugPrint('Area room already exists: $areaRoomId');
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
      debugPrint('✅ Area room created: $areaRoomId');

      // Invalidate cache
      invalidateLocationCache(districtId, wardId);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to create area room: $e');
      return false;
    }
  }

  // Create ward room if it doesn't exist
  Future<bool> createWardRoomIfNeeded(
    String districtId,
    String bodyId,
    String wardId,
    String creatorId,
  ) async {
    try {
      final wardRoomId = 'ward_${districtId}_${bodyId}_$wardId';

      // Check if room already exists
      if (await wardRoomExists(districtId, bodyId, wardId)) {
        debugPrint('Ward room already exists: $wardRoomId');
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
      debugPrint('✅ Ward room created: $wardRoomId');

      // Invalidate cache
      invalidateLocationCache(districtId, wardId);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to create ward room: $e');
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
      debugPrint('Error fetching district name: $e');
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
      debugPrint('Error fetching body name: $e');
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
      debugPrint('Error fetching ward name: $e');
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
      debugPrint('Error fetching area name: $e');
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
      debugPrint('Error updating typing status: $e');
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
        debugPrint('Cleaned up ${expiredDocs.docs.length} expired typing statuses');
      }
    } catch (e) {
      debugPrint('Error cleaning up typing statuses: $e');
    }
  }

  // Clear typing status for a specific user in a room
  Future<void> clearTypingStatus(String roomId, String userId) async {
    try {
      final typingRef = _firestore.collection('typing_status').doc('${roomId}_$userId');
      await typingRef.delete();
      debugPrint('🧹 Cleared typing status for user $userId in room $roomId');
    } catch (e) {
      debugPrint('Error clearing typing status: $e');
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
}

