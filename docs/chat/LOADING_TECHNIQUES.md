# Chat Loading Techniques & Performance

## Overview

The chat system employs advanced loading techniques to ensure fast, efficient, and scalable performance. This document covers the various strategies used to load chats quickly and handle large volumes of data.

## 🚀 Loading Strategies

### 1. Progressive Loading

#### Message Pagination
```dart
class MessagePagination {
  static const int _pageSize = 20;
  static const int _maxPages = 50; // Prevent infinite scroll

  Future<List<Message>> loadMessagesPaginated(
    String roomId, {
    DateTime? startAfter,
    bool loadOlder = true
  }) async {
    // Load from cache first
    final cachedMessages = await _sqliteCache.getMessages(
      roomId,
      limit: _pageSize,
      startAfter: startAfter,
      loadOlder: loadOlder
    );

    if (cachedMessages.isNotEmpty) {
      return cachedMessages;
    }

    // Fetch from Firebase with pagination
    final query = _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: !loadOlder)
        .limit(_pageSize);

    if (startAfter != null) {
      query.startAfter([Timestamp.fromDate(startAfter)]);
    }

    final snapshot = await query.get();
    final messages = snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();

    // Cache for future use
    await _sqliteCache.storeMessages(messages);

    return messages;
  }
}
```

#### Room List Loading
```dart
class RoomListLoader {
  Future<List<ChatRoom>> loadRoomsWithPagination({
    int limit = 10,
    String? lastRoomId
  }) async {
    // Use metadata cache for fast loading
    final cachedMetadata = await _metadataCache.getRoomsMetadata(
      limit: limit,
      startAfter: lastRoomId
    );

    if (cachedMetadata.isNotEmpty) {
      return cachedMetadata.map((meta) => meta.toChatRoom()).toList();
    }

    // Fetch from Firebase with pagination
    Query query = _firestore.collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .limit(limit);

    if (lastRoomId != null) {
      final lastDoc = await _firestore.collection('chats').doc(lastRoomId).get();
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    final rooms = snapshot.docs.map((doc) => ChatRoom.fromJson(doc.data())).toList();

    // Update cache
    await _metadataCache.storeRoomsMetadata(rooms);

    return rooms;
  }
}
```

### 2. Lazy Loading

#### On-Demand Media Loading
```dart
class MediaLazyLoader {
  final Map<String, bool> _loadingStates = {};
  final Map<String, Uint8List?> _mediaCache = {};

  Future<Uint8List?> loadMediaLazy(String mediaUrl, String messageId) async {
    // Check memory cache first
    if (_mediaCache.containsKey(messageId)) {
      return _mediaCache[messageId];
    }

    // Prevent duplicate loading
    if (_loadingStates[messageId] == true) {
      return null; // Already loading
    }

    _loadingStates[messageId] = true;

    try {
      // Download with progress tracking
      final bytes = await _downloadMediaWithProgress(mediaUrl, messageId);

      // Cache in memory
      _mediaCache[messageId] = bytes;

      // Also cache to disk for future use
      await _diskCache.storeMedia(messageId, bytes);

      return bytes;
    } finally {
      _loadingStates[messageId] = false;
    }
  }

  Future<Uint8List> _downloadMediaWithProgress(String url, String messageId) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    final contentLength = response.contentLength ?? 0;
    int downloaded = 0;

    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      downloaded += chunk.length;

      // Update progress (0.0 to 1.0)
      final progress = downloaded / contentLength;
      _updateDownloadProgress(messageId, progress);
    }

    return Uint8List.fromList(bytes);
  }
}
```

#### User Profile Lazy Loading
```dart
class UserProfileLazyLoader {
  final Map<String, Future<UserModel?>> _loadingFutures = {};

  Future<UserModel?> getUserProfile(String userId) async {
    // Check cache first
    final cached = await _userCache.getUserProfile(userId);
    if (cached != null) return cached;

    // Prevent duplicate requests
    if (_loadingFutures.containsKey(userId)) {
      return _loadingFutures[userId];
    }

    // Start loading
    final future = _loadUserProfileFromFirebase(userId);
    _loadingFutures[userId] = future;

    try {
      final user = await future;
      if (user != null) {
        await _userCache.storeUserProfile(user);
      }
      return user;
    } finally {
      _loadingFutures.remove(userId);
    }
  }
}
```

### 3. Preloading Strategies

#### App Start Preloading
```dart
class AppStartPreloader {
  Future<void> preloadEssentialData() async {
    final futures = await Future.wait([
      _preloadUserProfile(),
      _preloadRecentChats(),
      _preloadFrequentlyUsedData(),
    ]);

    debugPrint('✅ Essential data preloaded in ${DateTime.now().difference(_startTime).inMilliseconds}ms');
  }

  Future<void> _preloadUserProfile() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      await _userCache.storeUserProfile(user);
    }
  }

  Future<void> _preloadRecentChats() async {
    final recentRooms = await _chatRepository.getRecentRooms(limit: 5);
    for (final room in recentRooms) {
      // Preload last 10 messages for each recent room
      await _messageCache.preloadMessages(room.roomId, limit: 10);
    }
  }
}
```

#### Predictive Preloading
```dart
class PredictivePreloader {
  final Map<String, UserBehaviorPattern> _behaviorPatterns = {};

  Future<void> analyzeAndPreload(String userId) async {
    final pattern = await _analyzeUserBehavior(userId);

    // Preload based on time of day
    final hour = DateTime.now().hour;
    if (hour >= 9 && hour <= 17) { // Work hours
      await _preloadWorkRelatedChats(pattern);
    } else { // Evening hours
      await _preloadPersonalChats(pattern);
    }

    // Preload based on day of week
    final weekday = DateTime.now().weekday;
    if (weekday >= 1 && weekday <= 5) { // Weekdays
      await _preloadWeekdayChats(pattern);
    }
  }

  Future<UserBehaviorPattern> _analyzeUserBehavior(String userId) async {
    // Analyze chat patterns, message times, frequently contacted users
    final messages = await _messageRepository.getUserMessagesLast30Days(userId);
    final chatPatterns = await _chatRepository.getUserChatPatterns(userId);

    return UserBehaviorPattern.fromData(messages, chatPatterns);
  }
}
```

## ⚡ Performance Optimizations

### 1. Query Optimization

#### Targeted Queries Instead of Collection Scans
```dart
// ❌ Inefficient: Scan all chats
final allChats = await _firestore.collection('chats').get();

// ✅ Efficient: Query specific user's private chats
final userPrivateChats = await _firestore
    .collection('users')
    .doc(userId)
    .collection('privateChats')
    .orderBy('lastMessageAt', descending: true)
    .limit(20)
    .get();
```

#### Index Optimization
```javascript
// Firestore indexes for optimal queries
{
  collectionGroup: 'chats',
  queryScope: 'COLLECTION_GROUP',
  fields: [
    { fieldPath: 'type', order: 'ASCENDING' },
    { fieldPath: 'members', arrayConfig: 'CONTAINS' },
    { fieldPath: 'lastMessageAt', order: 'DESCENDING' }
  ]
}
```

### 2. Data Compression

#### Message Compression
```dart
class MessageCompressor {
  static const int _maxTextLength = 1000; // Compress longer messages

  String compressMessage(String text) {
    if (text.length <= _maxTextLength) return text;

    // Use compression for long messages
    final compressed = gzip.encode(utf8.encode(text));
    return 'compressed:${base64Encode(compressed)}';
  }

  String decompressMessage(String compressedText) {
    if (!compressedText.startsWith('compressed:')) return compressedText;

    final compressed = base64Decode(compressedText.substring(11));
    return utf8.decode(gzip.decode(compressed));
  }
}
```

#### Media Optimization
```dart
class MediaOptimizer {
  Future<String> optimizeImage(File imageFile) async {
    // Resize large images
    final optimizedFile = await _resizeImageIfNeeded(imageFile);

    // Compress with appropriate quality
    final compressedFile = await _compressImage(optimizedFile, quality: 0.8);

    // Convert to WebP for better compression
    return await _convertToWebP(compressedFile);
  }

  Future<String> optimizeVideo(File videoFile) async {
    // Compress video with appropriate bitrate
    return await _compressVideo(videoFile, targetBitrate: 1000000); // 1Mbps
  }
}
```

### 3. Connection Optimization

#### Request Batching
```dart
class RequestBatcher {
  final List<Future> _pendingRequests = [];
  Timer? _batchTimer;

  Future<T> addToBatch<T>(Future<T> Function() request) {
    final completer = Completer<T>();

    _pendingRequests.add(
      request().then((result) {
        completer.complete(result);
        return result;
      }).catchError((error) {
        completer.completeError(error);
        throw error;
      })
    );

    // Process batch after delay or when full
    _scheduleBatchProcessing();

    return completer.future;
  }

  void _scheduleBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 50), _processBatch);
  }

  Future<void> _processBatch() async {
    if (_pendingRequests.isEmpty) return;

    debugPrint('📦 Processing batch of ${_pendingRequests.length} requests');

    // Wait for all requests in batch to complete
    await Future.wait(_pendingRequests);
    _pendingRequests.clear();

    debugPrint('✅ Batch processing completed');
  }
}
```

#### Connection Pooling
```dart
class ConnectionPool {
  static const int _maxConnections = 5;
  final List<HttpClient> _availableConnections = [];
  final List<Completer<HttpClient>> _waitingRequests = [];

  Future<HttpClient> getConnection() async {
    if (_availableConnections.isNotEmpty) {
      return _availableConnections.removeLast();
    }

    if (_availableConnections.length < _maxConnections) {
      return HttpClient();
    }

    // Wait for connection to become available
    final completer = Completer<HttpClient>();
    _waitingRequests.add(completer);
    return completer.future;
  }

  void releaseConnection(HttpClient connection) {
    if (_waitingRequests.isNotEmpty) {
      final completer = _waitingRequests.removeAt(0);
      completer.complete(connection);
    } else {
      _availableConnections.add(connection);
    }
  }
}
```

## 📊 Performance Monitoring

### Loading Time Tracking
```dart
class PerformanceMonitor {
  final Map<String, DateTime> _operationStartTimes = {};

  void startOperation(String operationId) {
    _operationStartTimes[operationId] = DateTime.now();
  }

  Duration endOperation(String operationId) {
    final startTime = _operationStartTimes.remove(operationId);
    if (startTime == null) return Duration.zero;

    final duration = DateTime.now().difference(startTime);

    // Log performance metrics
    _logPerformanceMetric(operationId, duration);

    // Alert on slow operations
    if (duration > const Duration(seconds: 5)) {
      _alertSlowOperation(operationId, duration);
    }

    return duration;
  }

  void _logPerformanceMetric(String operation, Duration duration) {
    // Send to analytics service
    analytics.logEvent('performance', {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### Memory Usage Monitoring
```dart
class MemoryMonitor {
  static const Duration _checkInterval = Duration(seconds: 30);

  void startMonitoring() {
    Timer.periodic(_checkInterval, (timer) {
      final memoryInfo = ProcessInfo.currentRss;
      final memoryUsage = memoryInfo / 1024 / 1024; // MB

      if (memoryUsage > 100) { // Alert threshold
        _alertHighMemoryUsage(memoryUsage);
      }

      // Trigger garbage collection if needed
      if (memoryUsage > 150) {
        _forceGarbageCollection();
      }
    });
  }
}
```

## 🔮 Advanced Techniques

### 1. Edge Computing (Future)
```dart
class EdgeLoader {
  Future<List<Message>> loadFromNearestEdge(String roomId, String region) async {
    // Route requests to nearest edge server
    final edgeUrl = _getNearestEdgeUrl(region);

    final response = await http.get(
      Uri.parse('$edgeUrl/api/chat/rooms/$roomId/messages')
    );

    if (response.statusCode == 200) {
      return _parseMessagesFromResponse(response.body);
    }

    // Fallback to Firebase
    return _firebaseRepository.getMessages(roomId);
  }
}
```

### 2. Predictive Prefetching
```dart
class PredictivePrefetcher {
  Future<void> prefetchBasedOnBehavior(String userId) async {
    final behavior = await _analyzeUserBehavior(userId);

    // Prefetch rooms user typically opens
    for (final roomId in behavior.frequentRooms) {
      await _prefetchRoomData(roomId);
    }

    // Prefetch media for upcoming messages
    for (final mediaUrl in behavior.upcomingMedia) {
      await _prefetchMedia(mediaUrl);
    }
  }
}
```

### 3. Adaptive Loading
```dart
class AdaptiveLoader {
  Future<List<Message>> loadAdaptively(String roomId) async {
    final connectionQuality = await _measureConnectionQuality();

    switch (connectionQuality) {
      case ConnectionQuality.excellent:
        return _loadHighQuality(roomId, limit: 50);
      case ConnectionQuality.good:
        return _loadMediumQuality(roomId, limit: 30);
      case ConnectionQuality.poor:
        return _loadLowQuality(roomId, limit: 10);
    }
  }

  Future<ConnectionQuality> _measureConnectionQuality() async {
    final stopwatch = Stopwatch()..start();
    try {
      await http.head(Uri.parse('https://www.google.com'));
      final ping = stopwatch.elapsedMilliseconds;

      if (ping < 100) return ConnectionQuality.excellent;
      if (ping < 500) return ConnectionQuality.good;
      return ConnectionQuality.poor;
    } catch (e) {
      return ConnectionQuality.poor;
    }
  }
}
```

These loading techniques ensure the chat system remains fast and responsive even with large amounts of data and varying network conditions.