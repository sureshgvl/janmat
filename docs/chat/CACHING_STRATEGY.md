# Chat Caching Strategy

## Overview

The chat system implements a sophisticated multi-level caching strategy to ensure fast loading times, offline support, and optimal performance across different network conditions.

## 🏗️ Cache Architecture

### Three-Tier Caching System

#### L1: Memory Cache (Fastest)
```dart
class MemoryCache {
  static final Map<String, List<ChatMetadata>> _metadataCache = {};
  static final Map<String, DateTime> _metadataTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 15);
}
```

**Purpose**: Instant access for active data
**Size**: Limited, LRU eviction
**TTL**: 15 minutes
**Use Case**: Currently viewed chats, recent messages

#### L2: SQLite Cache (Persistent)
```sql
CREATE TABLE chat_metadata (
  id INTEGER PRIMARY KEY,
  cacheKey TEXT UNIQUE,
  metadata TEXT, -- JSON serialized ChatMetadata
  timestamp TEXT
);

CREATE TABLE messages (
  id INTEGER PRIMARY KEY,
  messageId TEXT UNIQUE,
  roomId TEXT,
  text TEXT,
  senderId TEXT,
  type TEXT,
  mediaUrl TEXT,
  createdAt TEXT,
  status INTEGER,
  readBy TEXT -- JSON array
);
```

**Purpose**: Offline persistence and larger data storage
**Size**: Unlimited (with cleanup policies)
**TTL**: 24 hours default
**Use Case**: Full message history, offline access

#### L3: Firebase Cache (Server)
```dart
// Automatic caching via Firestore SDK
// TTL managed by Firebase
// Background refresh mechanisms
```

**Purpose**: Server-side data with global consistency
**Size**: Firebase limits apply
**TTL**: Configurable per collection
**Use Case**: Authoritative data source

## 🔄 Cache Synchronization

### Write-Through Strategy
```dart
Future<void> sendMessage(Message message) async {
  // 1. Immediate local storage (L2)
  await _sqliteCache.storeMessage(message);

  // 2. UI update (L1)
  _memoryCache.addMessage(message);

  // 3. Firebase sync (L3)
  await _firebaseRepository.sendMessage(message);

  // 4. Cache invalidation if needed
  _invalidateRelatedCaches(message.roomId);
}
```

### Read Strategy
```dart
Future<List<ChatRoom>> getChatRooms() async {
  // 1. Check L1 cache first
  var rooms = _memoryCache.getRooms();
  if (rooms != null) return rooms;

  // 2. Check L2 cache
  rooms = await _sqliteCache.getRooms();
  if (rooms != null) {
    _memoryCache.storeRooms(rooms); // Promote to L1
    return rooms;
  }

  // 3. Fetch from Firebase (L3)
  rooms = await _firebaseRepository.getRooms();

  // 4. Store in all cache levels
  await _sqliteCache.storeRooms(rooms);
  _memoryCache.storeRooms(rooms);

  return rooms;
}
```

## 📊 Cache Key Strategy

### Hierarchical Cache Keys
```
Format: {userId}_{userRole}_{stateId}_{districtId}_{bodyId}_{wardId}_{area}
Example: user123_voter_maharashtra_pune_pune_m_cop_ward_17_माळवाडी
```

**Benefits**:
- Precise cache invalidation
- Location-based cache management
- Role-specific data isolation

### Cache Invalidation Patterns

#### User-Specific Invalidation
```dart
void invalidateUserCache(String userId) {
  final keysToRemove = _metadataCache.keys
      .where((key) => key.contains(userId))
      .toList();

  for (final key in keysToRemove) {
    _metadataCache.remove(key);
    _metadataTimestamps.remove(key);
  }
}
```

#### Location-Based Invalidation
```dart
void invalidateLocationCache(String districtId, String wardId) {
  final locationPattern = '${districtId}_$wardId';
  final keysToRemove = _metadataCache.keys
      .where((key) => key.contains(locationPattern))
      .toList();

  // Remove from all cache levels
}
```

## 🚀 Performance Optimizations

### Cache Warming
```dart
Future<void> warmCacheOnAppStart() async {
  // Preload user's recent chats
  final recentRooms = await _sqliteCache.getRecentRooms();

  // Background fetch for stale data
  if (_isCacheStale()) {
    _backgroundRefreshCache();
  }
}
```

### Lazy Loading with Cache
```dart
Future<List<Message>> loadMessagesPaginated(
  String roomId, {
  int limit = 20,
  DateTime? startAfter
}) async {
  // Check cache first
  final cachedMessages = await _sqliteCache.getMessages(
    roomId,
    limit: limit,
    startAfter: startAfter
  );

  if (cachedMessages.isNotEmpty) {
    return cachedMessages;
  }

  // Fetch from Firebase
  final messages = await _firebaseRepository.getMessagesPaginated(
    roomId,
    limit: limit,
    startAfter: startAfter
  );

  // Cache for future use
  await _sqliteCache.storeMessages(messages);

  return messages;
}
```

## 🔧 Cache Management

### Automatic Cleanup
```dart
class CacheManager {
  static const Duration _maxAge = Duration(hours: 24);

  Future<void> cleanupExpiredCache() async {
    final cutoffTime = DateTime.now().subtract(_maxAge);

    // Clean SQLite cache
    await _sqliteCache.deleteExpiredEntries(cutoffTime);

    // Clean memory cache
    _memoryCache.removeExpiredEntries(cutoffTime);
  }
}
```

### Storage Quotas
```dart
class CacheQuotaManager {
  static const int _maxMessagesPerRoom = 1000;
  static const int _maxTotalCacheSize = 100 * 1024 * 1024; // 100MB

  Future<void> enforceQuotas() async {
    // Limit messages per room
    await _trimOldMessages();

    // Limit total cache size
    await _trimOldestEntries();
  }
}
```

## 📈 Monitoring & Metrics

### Cache Hit Rates
```dart
class CacheMetrics {
  int memoryHits = 0;
  int sqliteHits = 0;
  int firebaseHits = 0;
  int totalRequests = 0;

  double getMemoryHitRate() => memoryHits / totalRequests;
  double getSqliteHitRate() => sqliteHits / totalRequests;
  double getCacheHitRate() => (memoryHits + sqliteHits) / totalRequests;
}
```

### Performance Tracking
- Cache load times
- Hit/miss ratios
- Storage utilization
- Memory usage patterns

## 🔮 Advanced Features

### Predictive Caching
```dart
class PredictiveCache {
  Future<void> preloadLikelyNeededData(String userId) async {
    // Analyze user behavior patterns
    final userPatterns = await _analyzeUserBehavior(userId);

    // Preload frequently accessed rooms
    for (final roomId in userPatterns.frequentRooms) {
      await _preloadRoomData(roomId);
    }

    // Preload recent contacts
    for (final contactId in userPatterns.recentContacts) {
      await _preloadPrivateChatData(userId, contactId);
    }
  }
}
```

### Distributed Caching (Future)
- Redis integration for high-traffic scenarios
- CDN caching for media content
- Edge caching for regional users

## 🐛 Troubleshooting

### Common Cache Issues

#### Stale Data
```dart
// Force cache refresh
await _cacheManager.forceRefreshCache(userId);

// Clear specific cache entries
await _cacheManager.invalidateRoomCache(roomId);
```

#### Cache Corruption
```dart
// Rebuild cache from Firebase
await _cacheManager.rebuildCacheFromSource(userId);

// Validate cache integrity
final isValid = await _cacheManager.validateCacheIntegrity();
```

#### Memory Leaks
```dart
// Monitor memory usage
final memoryStats = await _cacheManager.getMemoryStats();

// Force garbage collection
await _cacheManager.forceGarbageCollection();
```

This caching strategy ensures optimal performance, offline support, and seamless user experience across all network conditions.