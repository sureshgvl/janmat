# Chat Logging Guide

## Overview

This guide shows how to use the new `AppLogger` utility to filter and control app logs, making it easier to debug chat functionality after app reinstallation.

## 🚀 Quick Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Logger in main.dart
```dart
import 'utils/app_logger.dart';

void main() async {
  // ... existing code ...

  // Configure which logs to show
  AppLogger.configure(
    chat: true,        // Show chat-related logs
    auth: true,        // Show authentication logs
    network: true,     // Show network request logs
    cache: true,       // Show cache operation logs
    database: true,    // Show database operation logs
    ui: false,         // Hide UI interaction logs (can be noisy)
    performance: true, // Show performance monitoring logs
  );

  // Quick setup options:
  // AppLogger.enableAllLogs();      // Show all logs
  // AppLogger.enableChatOnly();     // Show only chat logs
  // AppLogger.enableCoreOnly();     // Show core functionality logs
  // AppLogger.disableAllLogs();     // Disable all app logs

  runApp(const MyApp());
}
```

## 📱 Usage Examples

### Replace debugPrint with AppLogger

#### Before (old way):
```dart
debugPrint('💬 [ChatController] Loading messages for room: $roomId');
debugPrint('❌ [ChatController] Failed to send message: $error');
```

#### After (new way):
```dart
AppLogger.chat('Loading messages for room: $roomId', tag: 'ChatController');
AppLogger.chatError('Failed to send message', tag: 'ChatController', error: error);
```

### Chat-Related Logging

```dart
import 'package:janmat/utils/app_logger.dart';

// Message operations
AppLogger.chat('Sending message to room: $roomId');
AppLogger.chat('Message sent successfully', tag: 'MessageController');
AppLogger.chatError('Failed to send message', error: e, stackTrace: s);

// Room operations
AppLogger.chat('Loading chat rooms for user: $userId');
AppLogger.chat('Found ${rooms.length} chat rooms');
AppLogger.chatWarning('Room not found: $roomId');

// Typing indicators
AppLogger.chat('User started typing in room: $roomId', tag: 'Typing');
AppLogger.chat('User stopped typing in room: $roomId', tag: 'Typing');
```

### Network Operations

```dart
// Firebase operations
AppLogger.network('Fetching messages from Firebase');
AppLogger.network('Messages fetched successfully: ${messages.length}');
AppLogger.networkError('Firebase query failed', error: e);

// API calls
AppLogger.network('Calling chat API endpoint');
AppLogger.network('API response received', tag: 'API');
```

### Cache Operations

```dart
// Cache hits/misses
AppLogger.cache('Cache hit for room: $roomId');
AppLogger.cache('Cache miss for room: $roomId, fetching from server');

// Cache updates
AppLogger.cache('Updating cache for room: $roomId');
AppLogger.cache('Cache cleared for user: $userId');
```

### Database Operations

```dart
// SQLite operations
AppLogger.database('Storing message locally: ${message.id}');
AppLogger.database('Message stored successfully');
AppLogger.databaseError('Failed to store message', error: e);

// Sync operations
AppLogger.database('Syncing offline messages');
AppLogger.database('Sync completed: $syncedCount messages');
```

### Performance Monitoring

```dart
// Performance logs
AppLogger.performance('Chat load time: ${duration}ms');
AppLogger.performance('Message send time: ${duration}ms');
AppLogger.performanceWarning('Slow operation detected: ${operation}');

// Memory usage
AppLogger.performance('Memory usage: ${memoryUsage}MB');
AppLogger.performance('Cache size: ${cacheSize} items');
```

## 🎯 Testing Chat Functionality

### Recommended Configuration for Testing

```dart
// In main.dart - for testing chat functionality
AppLogger.configure(
  chat: true,        // ✅ Show all chat logs
  auth: true,        // ✅ Show login/auth logs
  network: true,     // ✅ Show Firebase/API calls
  cache: true,       // ✅ Show cache operations
  database: true,    // ✅ Show SQLite operations
  ui: false,         // ❌ Hide UI logs (too noisy)
  performance: true, // ✅ Show performance metrics
);
```

### Quick Test Commands

```dart
// Enable only chat logs
AppLogger.enableChatOnly();

// Enable all logs for debugging
AppLogger.enableAllLogs();

// Disable all logs for production
AppLogger.disableAllLogs();
```

## 🔍 Log Categories & Emojis

| Category | Emoji | Description | Use Case |
|----------|-------|-------------|----------|
| Chat | 💬 | Chat operations | Messages, rooms, typing |
| Auth | 🔐 | Authentication | Login, logout, user management |
| Network | 🌐 | Network requests | Firebase, API calls, HTTP |
| Cache | 🏗️ | Cache operations | Hits, misses, updates |
| Database | 💾 | Local storage | SQLite operations, sync |
| UI | 🎨 | User interface | Button clicks, navigation |
| Performance | ⚡ | Performance metrics | Load times, memory usage |
| Error | ❌ | Error conditions | Exceptions, failures |
| Warning | ⚠️ | Warning conditions | Non-critical issues |
| Info | ℹ️ | General information | Status updates, milestones |

## 📊 Log Levels

The logger supports different levels (automatically managed):

- **Verbose**: All logs (development only)
- **Debug**: Debug information
- **Info**: General information
- **Warning**: Warnings and non-critical issues
- **Error**: Errors and exceptions
- **Nothing**: No logs (production)

## 🔧 Advanced Configuration

### Custom Log Filtering

```dart
// Create custom filter function
bool customFilter(String message, String category) {
  // Only show logs containing "candidate" or "chat"
  return message.toLowerCase().contains('candidate') ||
         message.toLowerCase().contains('chat');
}

// Apply custom filter (requires code modification)
AppLogger.setCustomFilter(customFilter);
```

### Log to File (Future Enhancement)

```dart
// Save logs to file for detailed analysis
AppLogger.enableFileLogging('chat_debug_logs.txt');

// Limit file size
AppLogger.setMaxLogFileSize(10 * 1024 * 1024); // 10MB
```

### Remote Logging (Future Enhancement)

```dart
// Send logs to remote server for production monitoring
AppLogger.enableRemoteLogging(
  serverUrl: 'https://logs.janmat.com/api/logs',
  apiKey: 'your-api-key'
);
```

## 🚨 Troubleshooting

### Common Issues

#### 1. No Logs Appearing
```dart
// Check if logs are enabled
final config = AppLogger.getConfiguration();
print('Logger config: $config');

// Enable all logs
AppLogger.enableAllLogs();
```

#### 2. Too Many Logs
```dart
// Reduce log noise
AppLogger.configure(
  chat: true,
  auth: false,
  network: false,
  cache: false,
  database: false,
  ui: false,
  performance: false,
);
```

#### 3. Missing Chat Logs
```dart
// Ensure chat logs are enabled
AppLogger.configure(chat: true);

// Check if code is using AppLogger instead of debugPrint
// Replace: debugPrint('message');
// With:    AppLogger.chat('message');
```

### Performance Impact

- **Memory**: Minimal (~1-2MB additional memory usage)
- **CPU**: Negligible performance impact
- **Storage**: Logs are not persisted by default
- **Network**: No network usage unless remote logging enabled

## 📝 Migration Guide

### Converting Existing debugPrint Calls

#### Step 1: Identify Files
```bash
# Find all debugPrint calls in chat-related files
grep -r "debugPrint" lib/features/chat/ --include="*.dart"
```

#### Step 2: Replace with AppLogger
```dart
// Old code
debugPrint('Loading messages for room: $roomId');

// New code
AppLogger.chat('Loading messages for room: $roomId', tag: 'ChatController');
```

#### Step 3: Choose Appropriate Category
- `AppLogger.chat()` - for chat operations
- `AppLogger.network()` - for Firebase/API calls
- `AppLogger.cache()` - for cache operations
- `AppLogger.database()` - for SQLite operations
- `AppLogger.performance()` - for timing/metrics

## 🎯 Best Practices

### 1. Use Descriptive Tags
```dart
// Good
AppLogger.chat('Loading messages', tag: 'MessageController');

// Bad
AppLogger.chat('Loading messages');
```

### 2. Include Context
```dart
// Good
AppLogger.chat('Loading messages for room: $roomId, user: $userId');

// Bad
AppLogger.chat('Loading messages');
```

### 3. Use Appropriate Log Levels
```dart
// Info for normal operations
AppLogger.chat('Message sent successfully');

// Warning for potential issues
AppLogger.chatWarning('Slow network detected');

// Error for failures
AppLogger.chatError('Failed to send message', error: e);
```

### 4. Avoid Sensitive Data
```dart
// Good
AppLogger.auth('User login successful', tag: 'AuthController');

// Bad (exposes sensitive data)
AppLogger.auth('User $email logged in with password $password');
```

This logging system will help you effectively debug and monitor chat functionality while keeping your console clean and organized.