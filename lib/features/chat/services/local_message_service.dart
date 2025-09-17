import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/chat_message.dart';

class LocalMessageService {
  static const String _messagesDir = 'chat_messages';
  static const String _mediaDir = 'chat_media';

  // In-memory cache for faster access
  final Map<String, List<Message>> _messageCache = {};
  Directory? _appDir;

  Future<void> initialize() async {
    try {
      _appDir = await getApplicationDocumentsDirectory();
      debugPrint('LocalMessageService: Initialized with directory: ${_appDir!.path}');
    } catch (e) {
      debugPrint('LocalMessageService: Failed to initialize: $e');
    }
  }

  Future<void> saveMessage(Message message, String roomId) async {
    if (_appDir == null) await initialize();

    // Add to cache
    if (!_messageCache.containsKey(roomId)) {
      _messageCache[roomId] = [];
    }
    _messageCache[roomId]!.add(message);

    // Save to file - convert to JSON-compatible format
    try {
      final roomDir = Directory(path.join(_appDir!.path, _messagesDir, roomId));
      await roomDir.create(recursive: true);

      final file = File(path.join(roomDir.path, '${message.messageId}.json'));

      // Create a JSON-compatible version of the message
      final jsonData = {
        'messageId': message.messageId,
        'text': message.text,
        'senderId': message.senderId,
        'type': message.type,
        'createdAt': message.createdAt.toIso8601String(), // Convert DateTime to string
        'readBy': message.readBy,
        'mediaUrl': message.mediaUrl,
        'mediaLocalPath': message.mediaLocalPath,
        'reactions': message.reactions?.map((r) => r.toJson()).toList(),
        'status': message.status.index,
        'retryCount': message.retryCount,
        'isDeleted': message.isDeleted,
        'metadata': message.metadata,
      };

      await file.writeAsString(jsonEncode(jsonData));
      debugPrint('LocalMessageService: Saved message ${message.messageId} to local storage');
    } catch (e) {
      debugPrint('LocalMessageService: Failed to save message: $e');
    }
  }

  List<Message> getMessagesForRoom(String roomId) {
    // Return from cache if available
    if (_messageCache.containsKey(roomId)) {
      return List.from(_messageCache[roomId]!);
    }

    // Load from files synchronously (for now)
    final messages = <Message>[];
    try {
      if (_appDir == null) return messages;

      final roomDir = Directory(path.join(_appDir!.path, _messagesDir, roomId));
      if (!roomDir.existsSync()) return messages;

      final files = roomDir.listSync().whereType<File>();
      for (final file in files) {
        try {
          final content = file.readAsStringSync();
          final json = jsonDecode(content);
          final message = Message.fromJson(json);
          messages.add(message);
        } catch (e) {
          debugPrint('LocalMessageService: Failed to load message from ${file.path}: $e');
        }
      }

      // Sort by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Cache the loaded messages
      _messageCache[roomId] = List.from(messages);

      debugPrint('LocalMessageService: Loaded ${messages.length} messages for room $roomId');
    } catch (e) {
      debugPrint('LocalMessageService: Failed to load messages for room $roomId: $e');
    }

    return messages;
  }

  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    // Update in cache
    for (final roomMessages in _messageCache.values) {
      final index = roomMessages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        roomMessages[index] = roomMessages[index].copyWith(status: status);
        break;
      }
    }

    // Update in file
    try {
      if (_appDir == null) return;

      // Find the message file (we need to search all rooms)
      final messagesDir = Directory(path.join(_appDir!.path, _messagesDir));
      if (!messagesDir.existsSync()) return;

      final roomDirs = messagesDir.listSync().whereType<Directory>();
      for (final roomDir in roomDirs) {
        final file = File(path.join(roomDir.path, '$messageId.json'));
        if (file.existsSync()) {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          json['status'] = status.index;
          await file.writeAsString(jsonEncode(json));
          debugPrint('LocalMessageService: Updated status for message $messageId');
          break;
        }
      }
    } catch (e) {
      debugPrint('LocalMessageService: Failed to update message status: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    // Remove from cache
    for (final roomId in _messageCache.keys) {
      _messageCache[roomId]!.removeWhere((m) => m.messageId == messageId);
    }

    // Delete file
    try {
      if (_appDir == null) return;

      final messagesDir = Directory(path.join(_appDir!.path, _messagesDir));
      if (!messagesDir.existsSync()) return;

      final roomDirs = messagesDir.listSync().whereType<Directory>();
      for (final roomDir in roomDirs) {
        final file = File(path.join(roomDir.path, '$messageId.json'));
        if (file.existsSync()) {
          await file.delete();
          debugPrint('LocalMessageService: Deleted message file for $messageId');
          break;
        }
      }
    } catch (e) {
      debugPrint('LocalMessageService: Failed to delete message: $e');
    }
  }

  Future<String?> saveMediaFile(String messageId, String remoteUrl, List<int> bytes, String fileName) async {
    try {
      if (_appDir == null) await initialize();

      final mediaDir = Directory(path.join(_appDir!.path, _mediaDir));
      await mediaDir.create(recursive: true);

      final file = File(path.join(mediaDir.path, '$messageId${path.extension(fileName)}'));
      await file.writeAsBytes(bytes);

      final localPath = file.path;
      debugPrint('LocalMessageService: Saved media file for $messageId at $localPath');
      return localPath;
    } catch (e) {
      debugPrint('LocalMessageService: Failed to save media file: $e');
      return null;
    }
  }

  String? getLocalMediaPath(String messageId) {
    try {
      if (_appDir == null) return null;

      final mediaDir = Directory(path.join(_appDir!.path, _mediaDir));
      if (!mediaDir.existsSync()) return null;

      // Try different extensions
      final extensions = ['.jpg', '.png', '.mp4', '.m4a', '.aac', '.mp3'];
      for (final ext in extensions) {
        final file = File(path.join(mediaDir.path, '$messageId$ext'));
        if (file.existsSync()) {
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('LocalMessageService: Failed to get local media path: $e');
    }
    return null;
  }

  bool isMediaAvailableLocally(String messageId) {
    return getLocalMediaPath(messageId) != null;
  }

  Future<void> cleanupOldMessages(String roomId) async {
    // Keep only last 100 messages per room
    try {
      final messages = getMessagesForRoom(roomId);
      if (messages.length <= 100) return;

      final messagesToDelete = messages.take(messages.length - 100);
      for (final message in messagesToDelete) {
        await deleteMessage(message.messageId);
      }

      debugPrint('LocalMessageService: Cleaned up ${messagesToDelete.length} old messages from room $roomId');
    } catch (e) {
      debugPrint('LocalMessageService: Failed to cleanup old messages: $e');
    }
  }

  Map<String, dynamic> getStorageStats() {
    int totalMessages = 0;
    int totalSize = 0;

    try {
      if (_appDir != null) {
        final messagesDir = Directory(path.join(_appDir!.path, _messagesDir));
        if (messagesDir.existsSync()) {
          final files = messagesDir.listSync(recursive: true).whereType<File>();
          totalMessages = files.length;
          for (final file in files) {
            totalSize += file.lengthSync();
          }
        }
      }
    } catch (e) {
      debugPrint('LocalMessageService: Failed to get storage stats: $e');
    }

    return {
      'totalMessages': totalMessages,
      'totalSizeBytes': totalSize,
      'totalSizeMB': totalSize / (1024 * 1024),
    };
  }

  Future<void> clearAllData() async {
    _messageCache.clear();

    try {
      if (_appDir != null) {
        final messagesDir = Directory(path.join(_appDir!.path, _messagesDir));
        final mediaDir = Directory(path.join(_appDir!.path, _mediaDir));

        if (messagesDir.existsSync()) {
          await messagesDir.delete(recursive: true);
        }
        if (mediaDir.existsSync()) {
          await mediaDir.delete(recursive: true);
        }
      }
      debugPrint('LocalMessageService: Cleared all local data');
    } catch (e) {
      debugPrint('LocalMessageService: Failed to clear data: $e');
    }
  }

  Future<void> close() async {
    _messageCache.clear();
    debugPrint('LocalMessageService: Closed');
  }

  Future<void> updateMessageMediaUrl(String messageId, String remoteUrl) async {
    // Update in cache
    for (final roomMessages in _messageCache.values) {
      final index = roomMessages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        roomMessages[index] = roomMessages[index].copyWith(mediaUrl: remoteUrl);
        break;
      }
    }

    // Update in file
    try {
      if (_appDir == null) return;

      // Find the message file (we need to search all rooms)
      final messagesDir = Directory(path.join(_appDir!.path, _messagesDir));
      if (!messagesDir.existsSync()) return;

      final roomDirs = messagesDir.listSync().whereType<Directory>();
      for (final roomDir in roomDirs) {
        final file = File(path.join(roomDir.path, '$messageId.json'));
        if (file.existsSync()) {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          json['mediaUrl'] = remoteUrl;
          await file.writeAsString(jsonEncode(json));
          debugPrint('LocalMessageService: Updated media URL for message $messageId');
          break;
        }
      }
    } catch (e) {
      debugPrint('LocalMessageService: Failed to update message media URL: $e');
    }
  }
}