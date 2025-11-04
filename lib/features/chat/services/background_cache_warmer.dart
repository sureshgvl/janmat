import 'dart:async';
import 'dart:collection';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'persistent_chat_room_cache.dart';
import 'whatsapp_style_message_cache.dart';
import 'whatsapp_style_chat_cache.dart';

class CacheWarmupMetrics {
  final int roomsWarmed;
  final int messagesWarmed;
  final Duration warmupTime;
  final DateTime timestamp;

  CacheWarmupMetrics({
    required this.roomsWarmed,
    required this.messagesWarmed,
    required this.warmupTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'roomsWarmed': roomsWarmed,
    'messagesWarmed': messagesWarmed,
    'warmupTimeMs': warmupTime.inMilliseconds,
    'timestamp': timestamp.toIso8601String(),
  };
}

class BackgroundCacheWarmer {
  final PersistentChatRoomCache _roomCache = PersistentChatRoomCache();
  final WhatsAppStyleMessageCache _messageCache = WhatsAppStyleMessageCache();
  final WhatsAppStyleChatCache _chatCache = WhatsAppStyleChatCache();

  // Configuration
  static const Duration _warmupInterval = Duration(minutes: 30);
  static const int _maxConcurrentWarmups = 3;
  static const int _maxRoomsToWarm = 10;
  static const Duration _maxWarmupTime = Duration(seconds: 30);

  // State
  Timer? _warmupTimer;
  bool _isWarmingUp = false;
  final Queue<String> _warmupQueue = Queue<String>();
  final Set<String> _recentlyWarmedRooms = {};

  // Metrics
  final List<CacheWarmupMetrics> _warmupHistory = [];
  int _totalWarmups = 0;

  // Initialize background warming
  Future<void> initialize() async {
    AppLogger.chat('🔥 BackgroundCacheWarmer: Initializing background cache warming');

    await _chatCache.initialize();
    await _messageCache.initialize();

    // Start periodic warming
    _startPeriodicWarming();

    // Warm up on app start (after a short delay)
    Future.delayed(const Duration(seconds: 5), () => _performInitialWarmup());

    AppLogger.chat('✅ BackgroundCacheWarmer: Initialized successfully');
  }

  // Start periodic cache warming
  void _startPeriodicWarming() {
    _warmupTimer = Timer.periodic(_warmupInterval, (timer) {
      if (!_isWarmingUp) {
        _performPeriodicWarmup();
      }
    });
    AppLogger.chat('⏰ BackgroundCacheWarmer: Started periodic warming every ${_warmupInterval.inMinutes} minutes');
  }

  // Perform initial warmup on app start
  Future<void> _performInitialWarmup() async {
    try {
      AppLogger.chat('🚀 BackgroundCacheWarmer: Performing initial cache warmup');

      final startTime = DateTime.now();
      final userId = await _getCurrentUserId();

      if (userId == null) {
        AppLogger.chat('⚠️ BackgroundCacheWarmer: No user ID available for initial warmup');
        return;
      }

      // Get cached rooms first
      final rooms = await _roomCache.getCachedChatRooms(userId);
      if (rooms == null || rooms.isEmpty) {
        AppLogger.chat('📭 BackgroundCacheWarmer: No cached rooms for initial warmup');
        return;
      }

      // Sort by last activity and take top rooms
      final sortedRooms = _sortRoomsByActivity(rooms);
      final roomsToWarm = sortedRooms.take(5).toList(); // Warm top 5 rooms initially

      final metrics = await _warmupRooms(roomsToWarm, userId);
      _recordWarmupMetrics(metrics);

      final totalTime = DateTime.now().difference(startTime);
      AppLogger.chat('✅ BackgroundCacheWarmer: Initial warmup completed in ${totalTime.inSeconds}s');

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Initial warmup failed: $e');
    }
  }

  // Perform periodic warmup
  Future<void> _performPeriodicWarmup() async {
    if (_isWarmingUp) return;

    try {
      _isWarmingUp = true;
      AppLogger.chat('🔄 BackgroundCacheWarmer: Starting periodic cache warmup');

      final userId = await _getCurrentUserId();
      if (userId == null) return;

      // Get rooms that need warming (not recently warmed)
      final roomsToWarm = await _identifyRoomsNeedingWarmup(userId);
      if (roomsToWarm.isEmpty) {
        AppLogger.chat('📭 BackgroundCacheWarmer: No rooms need warmup');
        return;
      }

      final metrics = await _warmupRooms(roomsToWarm, userId);
      _recordWarmupMetrics(metrics);

      AppLogger.chat('✅ BackgroundCacheWarmer: Periodic warmup completed');

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Periodic warmup failed: $e');
    } finally {
      _isWarmingUp = false;
    }
  }

  // Identify rooms that need cache warming
  Future<List<ChatRoom>> _identifyRoomsNeedingWarmup(String userId) async {
    final rooms = await _roomCache.getCachedChatRooms(userId);
    if (rooms == null) return [];

    // Filter out recently warmed rooms and sort by priority
    final eligibleRooms = rooms.where((room) =>
      !_recentlyWarmedRooms.contains(room.roomId)
    ).toList();

    final sortedRooms = _sortRoomsByActivity(eligibleRooms);
    return sortedRooms.take(_maxRoomsToWarm).toList();
  }

  // Sort rooms by activity priority
  List<ChatRoom> _sortRoomsByActivity(List<ChatRoom> rooms) {
    return rooms..sort((a, b) {
      // Priority based on:
      // 1. Has recent messages (last 24h)
      // 2. Room type (private > ward > area > candidate)
      // 3. Creation date (newer first)

      final aRecent = _isRoomRecentlyActive(a);
      final bRecent = _isRoomRecentlyActive(b);

      if (aRecent && !bRecent) return -1;
      if (!aRecent && bRecent) return 1;

      // Room type priority
      final aPriority = _getRoomTypePriority(a.type);
      final bPriority = _getRoomTypePriority(b.type);

      if (aPriority != bPriority) return bPriority.compareTo(aPriority);

      // Creation date (newer first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Check if room has recent activity
  bool _isRoomRecentlyActive(ChatRoom room) {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    // This would need to be enhanced with actual last message time
    return room.createdAt.isAfter(oneDayAgo);
  }

  // Get room type priority for sorting
  int _getRoomTypePriority(String type) {
    switch (type) {
      case 'private': return 10;
      case 'ward': return 8;
      case 'area': return 6;
      case 'candidate': return 4;
      default: return 1;
    }
  }

  // Warm up multiple rooms concurrently
  Future<CacheWarmupMetrics> _warmupRooms(List<ChatRoom> rooms, String userId) async {
    final startTime = DateTime.now();
    int totalMessagesWarmed = 0;

    // Process rooms in batches to avoid overwhelming the system
    final batches = _chunkList(rooms, _maxConcurrentWarmups);

    for (final batch in batches) {
      final futures = batch.map((room) => _warmupSingleRoom(room, userId));
      final results = await Future.wait(futures);

      for (final messagesCount in results) {
        totalMessagesWarmed += messagesCount;
      }

      // Mark rooms as recently warmed
      for (final room in batch) {
        _recentlyWarmedRooms.add(room.roomId);
      }

      // Small delay between batches
      if (batches.length > 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    final warmupTime = DateTime.now().difference(startTime);

    // Clean up old recently warmed rooms (keep only last 20)
    if (_recentlyWarmedRooms.length > 20) {
      final toRemove = _recentlyWarmedRooms.take(_recentlyWarmedRooms.length - 20).toList();
      _recentlyWarmedRooms.removeAll(toRemove);
    }

    return CacheWarmupMetrics(
      roomsWarmed: rooms.length,
      messagesWarmed: totalMessagesWarmed,
      warmupTime: warmupTime,
      timestamp: DateTime.now(),
    );
  }

  // Warm up a single room
  Future<int> _warmupSingleRoom(ChatRoom room, String userId) async {
    try {
      AppLogger.chat('🔥 BackgroundCacheWarmer: Warming up room ${room.roomId}');

      // Warm up message cache
      final messages = await _messageCache.getMessagesForRoom(room.roomId);
      final messageCount = messages.length;

      // Warm up message metadata
      await _messageCache.getMessageMetadata(room.roomId);

      AppLogger.chat('✅ BackgroundCacheWarmer: Warmed up room ${room.roomId} with $messageCount messages');
      return messageCount;

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Failed to warm up room ${room.roomId}: $e');
      return 0;
    }
  }

  // Manual warmup for specific rooms (called when user opens app)
  Future<void> warmupSpecificRooms(List<String> roomIds, String userId) async {
    if (_isWarmingUp) {
      AppLogger.chat('⚠️ BackgroundCacheWarmer: Already warming up, queuing request');
      _warmupQueue.addAll(roomIds);
      return;
    }

    try {
      _isWarmingUp = true;
      AppLogger.chat('🎯 BackgroundCacheWarmer: Manual warmup for ${roomIds.length} rooms');

      // Get room objects
      final allRooms = await _roomCache.getCachedChatRooms(userId);
      if (allRooms == null) return;

      final roomsToWarm = allRooms.where((room) => roomIds.contains(room.roomId)).toList();

      if (roomsToWarm.isNotEmpty) {
        final metrics = await _warmupRooms(roomsToWarm, userId);
        _recordWarmupMetrics(metrics);
        AppLogger.chat('✅ BackgroundCacheWarmer: Manual warmup completed');
      }

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Manual warmup failed: $e');
    } finally {
      _isWarmingUp = false;

      // Process queued requests
      if (_warmupQueue.isNotEmpty) {
        final queuedRoomIds = _warmupQueue.toList();
        _warmupQueue.clear();
        Future.delayed(const Duration(seconds: 1), () =>
          warmupSpecificRooms(queuedRoomIds, userId));
      }
    }
  }

  // Predictive warmup based on user behavior patterns
  Future<void> predictiveWarmup(String userId) async {
    try {
      AppLogger.chat('🔮 BackgroundCacheWarmer: Starting predictive warmup');

      // Analyze user patterns (this would be enhanced with ML in production)
      final predictedRooms = await _predictRoomsToWarm(userId);

      if (predictedRooms.isNotEmpty) {
        await warmupSpecificRooms(predictedRooms, userId);
        AppLogger.chat('✅ BackgroundCacheWarmer: Predictive warmup completed');
      }

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Predictive warmup failed: $e');
    }
  }

  // Predict which rooms to warm based on patterns
  Future<List<String>> _predictRoomsToWarm(String userId) async {
    final rooms = await _roomCache.getCachedChatRooms(userId);
    if (rooms == null) return [];

    // Simple prediction: recently active rooms + high-priority rooms
    final predictedRooms = <String>[];

    // Add recently active rooms
    final recentRooms = rooms.where((room) => _isRoomRecentlyActive(room)).toList();
    predictedRooms.addAll(recentRooms.map((r) => r.roomId));

    // Add private chats (high priority)
    final privateChats = rooms.where((room) => room.type == 'private').toList();
    predictedRooms.addAll(privateChats.map((r) => r.roomId));

    // Remove duplicates and limit
    return predictedRooms.toSet().take(5).toList();
  }

  // Get warmup statistics
  Map<String, dynamic> getWarmupStats() {
    final recentMetrics = _warmupHistory.where((m) =>
      m.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 24)))
    ).toList();

    final totalRoomsWarmed = recentMetrics.fold(0, (sum, m) => sum + m.roomsWarmed);
    final totalMessagesWarmed = recentMetrics.fold(0, (sum, m) => sum + m.messagesWarmed);
    final avgWarmupTime = recentMetrics.isNotEmpty
        ? recentMetrics.map((m) => m.warmupTime).reduce((a, b) => a + b) ~/ recentMetrics.length
        : Duration.zero;

    return {
      'totalWarmups': _totalWarmups,
      'recentWarmups24h': recentMetrics.length,
      'totalRoomsWarmed24h': totalRoomsWarmed,
      'totalMessagesWarmed24h': totalMessagesWarmed,
      'averageWarmupTime': avgWarmupTime.inMilliseconds,
      'currentlyWarming': _isWarmingUp,
      'recentlyWarmedRooms': _recentlyWarmedRooms.length,
      'warmupQueueLength': _warmupQueue.length,
    };
  }

  // Record warmup metrics
  void _recordWarmupMetrics(CacheWarmupMetrics metrics) {
    _warmupHistory.add(metrics);
    _totalWarmups++;

    // Keep only last 100 metrics
    if (_warmupHistory.length > 100) {
      _warmupHistory.removeRange(0, _warmupHistory.length - 100);
    }

    AppLogger.chat('📊 BackgroundCacheWarmer: Recorded metrics - ${metrics.roomsWarmed} rooms, ${metrics.messagesWarmed} messages in ${metrics.warmupTime.inSeconds}s');
  }

  // Utility: Chunk list into smaller batches
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  // Get current user ID from Firebase Auth
  Future<String?> _getCurrentUserId() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
      AppLogger.chat('⚠️ BackgroundCacheWarmer: No authenticated user found');
      return null;
    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Error getting current user ID: $e');
      return null;
    }
  }

  // Force cleanup of old cache data
  Future<void> cleanupOldCache() async {
    try {
      AppLogger.chat('🧹 BackgroundCacheWarmer: Starting cache cleanup');

      // Clear old warmup history (keep last 24 hours)
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      _warmupHistory.removeWhere((m) => m.timestamp.isBefore(cutoffTime));

      // Clear recently warmed rooms older than 1 hour
      // Note: This is simplified - you'd want more sophisticated cleanup

      AppLogger.chat('✅ BackgroundCacheWarmer: Cache cleanup completed');

    } catch (e) {
      AppLogger.chat('❌ BackgroundCacheWarmer: Cache cleanup failed: $e');
    }
  }

  // Stop background warming
  void stop() {
    _warmupTimer?.cancel();
    _warmupTimer = null;
    _isWarmingUp = false;
    _warmupQueue.clear();

    AppLogger.chat('🛑 BackgroundCacheWarmer: Stopped background warming');
  }

  // Dispose resources
  void dispose() {
    stop();
    _warmupHistory.clear();
    _recentlyWarmedRooms.clear();
    _warmupQueue.clear();

    AppLogger.chat('✅ BackgroundCacheWarmer: Disposed');
  }
}
