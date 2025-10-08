# Chat Functionality Documentation

## Overview

The chat system in Janmat is a comprehensive real-time messaging platform designed to handle location-based community discussions, private conversations, and candidate interactions. It features advanced caching, offline support, and optimized performance for large-scale usage.

## 🏗️ Architecture

### Core Components

#### 1. Controllers
- **ChatController**: Main controller managing chat state, user data, and coordination
- **MessageController**: Handles message sending, receiving, and offline queuing
- **RoomController**: Manages chat rooms, unread counts, and room metadata

#### 2. Services
- **PrivateChatService**: Manages 1-on-1 conversations with optimized storage
- **ChatRepository**: Firebase operations with hierarchical data structure
- **LocalMessageService**: SQLite-based local message storage
- **OfflineMessageQueue**: Handles message delivery when offline

#### 3. Models
- **ChatRoom**: Room metadata and configuration
- **Message**: Individual message data with reactions and media
- **ChatMetadata**: Cached room information for performance
- **UserQuota**: Message limits and XP system

## 🚀 Key Features

### 1. Multi-Type Chat Rooms

#### Public Rooms
- **Ward Rooms**: City/district level discussions
- **Area Rooms**: Neighborhood-specific conversations
- **Candidate Rooms**: Official candidate communication channels

#### Private Rooms
- **1-on-1 Chats**: Direct messaging between users
- **Duplicate Storage**: Optimized for fast queries (54% cost reduction)

### 2. Advanced Caching System

#### WhatsApp-Style Metadata Caching
```dart
class ChatMetadata {
  final String roomId;
  final String title;
  final DateTime? lastMessageTime;
  final String? lastMessageText;
  final int unreadCount;
  final bool isPinned;
  // ... additional metadata
}
```

#### Multi-Level Cache Strategy
- **Memory Cache**: Fast access for active data
- **SQLite Cache**: Persistent local storage
- **Firebase Cache**: Server-side data with TTL

### 3. Offline Support

#### Message Queuing
```dart
class OfflineMessageQueue {
  Future<void> queueMessage(
    Message message,
    String roomId,
    Function(Message, String) onDeliver
  );
}
```

#### Local Storage
- Messages stored in SQLite when offline
- Automatic sync when connection restored
- Conflict resolution for concurrent edits

### 4. Performance Optimizations

#### Hierarchical Data Structure
```
Firebase Structure:
states/{stateId}/districts/{districtId}/bodies/{bodyId}/
  wards/{wardId}/chats/ward_discussion/
    └── room metadata

chats/{roomId}/messages/{messageId}/
  └── all messages regardless of room type
```

#### Query Optimization
- **Targeted Queries**: Fetch only relevant rooms for user
- **Subcollection Queries**: Private chats use user-specific subcollections
- **Index Optimization**: Strategic use of Firestore indexes

## 📱 User Experience Features

### Real-Time Messaging
- Instant message delivery with Firebase Realtime Database
- Typing indicators with automatic cleanup
- Message status (sent, delivered, read)
- Message reactions and replies

### Media Support
- Image sharing with compression
- Voice messages with waveform visualization
- File attachments with progress tracking
- Automatic media optimization

### Smart Notifications
- Push notifications for new messages
- Muted rooms and custom notification settings
- Background message processing
- Notification grouping by room

## 🔧 Technical Implementation

### SQLite Local Storage

#### Schema Design
```sql
-- Messages table
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

-- Chat metadata cache
CREATE TABLE chat_metadata (
  id INTEGER PRIMARY KEY,
  cacheKey TEXT UNIQUE,
  metadata TEXT, -- JSON
  timestamp TEXT
);
```

#### Sync Strategy
- **Write-Through**: Immediate local storage on send
- **Write-Behind**: Background sync to Firebase
- **Conflict Resolution**: Timestamp-based merging

### Caching Layers

#### 1. Memory Cache (L1)
- Fast access for active chat data
- Limited size with LRU eviction
- Automatic invalidation on data changes

#### 2. SQLite Cache (L2)
- Persistent storage for offline access
- Full message history when offline
- Metadata caching for room lists

#### 3. Firebase Cache (L3)
- Server-side data with TTL
- Automatic cache invalidation
- Background refresh mechanisms

### Loading Techniques

#### Progressive Loading
```dart
class ProgressiveLoader {
  Future<List<Message>> loadMessagesPaginated(
    String roomId, {
    int limit = 20,
    DateTime? startAfter
  });
}
```

#### Lazy Loading
- Rooms loaded on demand
- Messages loaded in chunks
- Media loaded when visible

#### Preloading Strategy
- Recent chats preloaded on app start
- Frequently accessed data cached
- Predictive loading based on user behavior

## 📊 Performance Metrics

### Current Performance
- **Chat Load Time**: < 500ms for room lists
- **Message Send**: < 200ms average
- **Offline Sync**: < 2 seconds for 100 messages
- **Memory Usage**: < 50MB for active chats

### Scalability Targets
- **Concurrent Users**: 10,000+ active users
- **Messages/Day**: 1M+ messages
- **Storage**: Efficient compression and cleanup
- **Cost**: Optimized Firebase usage

## 🔄 Data Flow

### Message Sending Flow
1. **User Input** → MessageController
2. **Local Storage** → SQLite (immediate)
3. **Queue Management** → OfflineMessageQueue
4. **Firebase Sync** → ChatRepository
5. **Real-time Update** → All room members
6. **Notification** → Push notification service

### Room Loading Flow
1. **Cache Check** → Memory/SQLite cache
2. **Firebase Query** → Targeted room fetch
3. **Metadata Update** → Cache refresh
4. **UI Update** → Progressive rendering

## 🚨 Error Handling

### Network Issues
- Automatic retry with exponential backoff
- Offline queue for failed messages
- Connection status monitoring

### Data Conflicts
- Timestamp-based conflict resolution
- User notification for conflicts
- Automatic merge strategies

### Storage Limits
- Automatic cleanup of old messages
- Media compression and optimization
- Quota management and warnings

## 🔮 Future Improvements

### Planned Enhancements

#### 1. Advanced Caching
- **Redis Integration**: Distributed caching for high traffic
- **CDN Integration**: Media delivery optimization
- **Edge Computing**: Regional data processing

#### 2. AI Features
- **Smart Replies**: AI-generated response suggestions
- **Content Moderation**: Automatic inappropriate content detection
- **Translation**: Real-time message translation

#### 3. Advanced Media
- **Video Calls**: Integrated video conferencing
- **Screen Sharing**: Collaborative features
- **File Previews**: Rich file type support

#### 4. Performance Optimizations
- **Message Compression**: Reduce storage costs
- **Batch Operations**: Bulk message processing
- **Predictive Loading**: ML-based content prefetching

### Technical Debt
- **Code Splitting**: Modular architecture for better maintainability
- **Testing Coverage**: Comprehensive unit and integration tests
- **Documentation**: API documentation and developer guides

## 📈 Monitoring & Analytics

### Key Metrics
- Message delivery success rate
- Average response time
- User engagement metrics
- Storage utilization
- Cost per active user

### Logging
- Structured logging with searchable tags
- Performance monitoring integration
- Error tracking and alerting
- User behavior analytics

## 🛠️ Development Guidelines

### Code Organization
```
lib/features/chat/
├── controllers/          # State management
├── services/            # Business logic
├── repositories/        # Data access
├── models/             # Data structures
├── screens/            # UI components
└── widgets/            # Reusable components
```

### Testing Strategy
- Unit tests for all services
- Integration tests for chat flows
- Performance tests for scalability
- UI tests for critical user journeys

### Deployment
- Blue-green deployment strategy
- Feature flags for gradual rollouts
- Automated rollback procedures
- Database migration scripts

## 📚 API Reference

### ChatController
```dart
class ChatController extends GetxController {
  // Core methods
  Future<void> initializeChatIfNeeded();
  Future<void> sendTextMessage(String text);
  Future<void> selectChatRoom(ChatRoom room);

  // Reactive properties
  Rx<ChatRoom?> get currentChatRoom;
  List<ChatRoom> get chatRooms;
  List<Message> get messages;
}
```

### MessageController
```dart
class MessageController {
  // Message operations
  Future<void> sendTextMessage(String roomId, String text, String userId);
  Future<void> sendImageMessage(String roomId, String imagePath, String userId);
  Future<void> markMessageAsRead(String roomId, String messageId, String userId);

  // Media handling
  Future<String> uploadMediaFile(String filePath, String roomId);
  String? getMediaUrl(String messageId, String? remoteUrl);
}
```

This comprehensive chat system provides a scalable, performant, and feature-rich messaging platform for community engagement and political discourse.