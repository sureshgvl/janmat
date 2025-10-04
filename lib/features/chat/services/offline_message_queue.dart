import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/chat_message.dart';

class OfflineMessageQueue {
  static const String _queueFileName = 'offline_messages.json';
  final Connectivity _connectivity = Connectivity();

  // Queue storage
  List<QueuedMessage> _messageQueue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  // Callbacks
  Function(QueuedMessage)? onMessageQueued;
  Function(QueuedMessage)? onMessageSent;
  Function(QueuedMessage, String)? onMessageFailed;

  Future<void> initialize() async {
    debugPrint('🔄 OfflineMessageQueue: Initializing...');

    // Load existing queue from storage
    await _loadQueueFromStorage();

    // Monitor connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isOnlineStatus(results);

    debugPrint('✅ OfflineMessageQueue: Initialized with ${_messageQueue.length} queued messages');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  // Add message to offline queue
  Future<void> queueMessage(
    Message message,
    String roomId,
    Future<void> Function(Message, String) sendFunction,
  ) async {
    final queuedMessage = QueuedMessage(
      message: message,
      roomId: roomId,
      sendFunction: sendFunction,
      queuedAt: DateTime.now(),
      retryCount: 0,
    );

    _messageQueue.add(queuedMessage);
    await _saveQueueToStorage();

    onMessageQueued?.call(queuedMessage);

    debugPrint('📋 OfflineMessageQueue: Queued message ${message.messageId} for room $roomId');

    // Try to send immediately if online
    if (_isOnline) {
      _processQueue();
    }
  }

  // Process the offline queue
  Future<void> _processQueue() async {
    if (!_isOnline || _messageQueue.isEmpty) return;

    debugPrint('🔄 OfflineMessageQueue: Processing queue (${_messageQueue.length} messages)...');

    final messagesToRemove = <QueuedMessage>[];

    for (final queuedMessage in _messageQueue) {
      try {
        await queuedMessage.sendFunction(queuedMessage.message, queuedMessage.roomId);

        messagesToRemove.add(queuedMessage);
        onMessageSent?.call(queuedMessage);

        debugPrint('✅ OfflineMessageQueue: Successfully sent queued message ${queuedMessage.message.messageId}');

        // Small delay between sends to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        queuedMessage.retryCount++;
        queuedMessage.lastError = e.toString();
        queuedMessage.lastRetryAt = DateTime.now();

        // Remove from queue after max retries
        if (queuedMessage.retryCount >= 3) {
          messagesToRemove.add(queuedMessage);
          onMessageFailed?.call(queuedMessage, e.toString());
          debugPrint('❌ OfflineMessageQueue: Failed to send message ${queuedMessage.message.messageId} after ${queuedMessage.retryCount} retries: $e');
        } else {
          debugPrint('⚠️ OfflineMessageQueue: Failed to send message ${queuedMessage.message.messageId}, will retry (attempt ${queuedMessage.retryCount}/3): $e');
        }
      }
    }

    // Remove processed messages
    _messageQueue.removeWhere((msg) => messagesToRemove.contains(msg));
    await _saveQueueToStorage();

    debugPrint('📋 OfflineMessageQueue: Queue processing complete. Remaining: ${_messageQueue.length}');
  }

  // Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isOnlineStatus(results);

    debugPrint('🌐 OfflineMessageQueue: Connectivity changed - ${wasOnline ? 'online' : 'offline'} → ${_isOnline ? 'online' : 'offline'}');

    // If we just came back online, process the queue
    if (!wasOnline && _isOnline && _messageQueue.isNotEmpty) {
      debugPrint('🔄 OfflineMessageQueue: Back online, processing ${_messageQueue.length} queued messages...');
      Future.delayed(const Duration(seconds: 2), _processQueue); // Small delay to ensure connection is stable
    }
  }

  bool _isOnlineStatus(List<ConnectivityResult> results) {
    // Consider online if any connection type is available (not none)
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Get queue statistics
  Map<String, dynamic> getQueueStats() {
    final now = DateTime.now();
    final recentFailures = _messageQueue.where((msg) =>
      msg.lastRetryAt != null &&
      now.difference(msg.lastRetryAt!).inMinutes < 5
    ).length;

    return {
      'totalQueued': _messageQueue.length,
      'isOnline': _isOnline,
      'recentFailures': recentFailures,
      'oldestMessage': _messageQueue.isNotEmpty ? _messageQueue.first.queuedAt : null,
      'newestMessage': _messageQueue.isNotEmpty ? _messageQueue.last.queuedAt : null,
    };
  }

  // Clear old messages from queue (older than specified days)
  Future<void> clearOldMessages({int daysOld = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final initialCount = _messageQueue.length;

    _messageQueue.removeWhere((msg) => msg.queuedAt.isBefore(cutoffDate));

    if (_messageQueue.length != initialCount) {
      await _saveQueueToStorage();
      debugPrint('🧹 OfflineMessageQueue: Cleared ${initialCount - _messageQueue.length} old messages');
    }
  }

  // Force retry all failed messages
  Future<void> retryAllFailed() async {
    if (!_isOnline) {
      debugPrint('⚠️ OfflineMessageQueue: Cannot retry - device is offline');
      return;
    }

    final failedMessages = _messageQueue.where((msg) => msg.retryCount > 0).toList();
    if (failedMessages.isEmpty) {
      debugPrint('ℹ️ OfflineMessageQueue: No failed messages to retry');
      return;
    }

    debugPrint('🔄 OfflineMessageQueue: Retrying ${failedMessages.length} failed messages...');
    await _processQueue();
  }

  // Load queue from persistent storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final queueFile = File('${appDir.path}/$_queueFileName');

      if (await queueFile.exists()) {
        final jsonString = await queueFile.readAsString();
        final jsonList = json.decode(jsonString) as List;

        _messageQueue = jsonList.map((json) => QueuedMessage.fromJson(json)).toList();
        debugPrint('📂 OfflineMessageQueue: Loaded ${_messageQueue.length} messages from storage');
      }
    } catch (e) {
      debugPrint('❌ OfflineMessageQueue: Failed to load queue from storage: $e');
      _messageQueue = [];
    }
  }

  // Save queue to persistent storage
  Future<void> _saveQueueToStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final queueFile = File('${appDir.path}/$_queueFileName');

      final jsonList = _messageQueue.map((msg) => msg.toJson()).toList();
      await queueFile.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ OfflineMessageQueue: Failed to save queue to storage: $e');
    }
  }
}

// Data class for queued messages
class QueuedMessage {
  final Message message;
  final String roomId;
  final Future<void> Function(Message, String) sendFunction;
  final DateTime queuedAt;
  int retryCount;
  String? lastError;
  DateTime? lastRetryAt;

  QueuedMessage({
    required this.message,
    required this.roomId,
    required this.sendFunction,
    required this.queuedAt,
    this.retryCount = 0,
    this.lastError,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'roomId': roomId,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      message: Message.fromJson(json['message']),
      roomId: json['roomId'],
      sendFunction: (msg, roomId) async {
        // This will be replaced when the message is dequeued
        throw Exception('Send function not available for loaded message');
      },
      queuedAt: DateTime.parse(json['queuedAt']),
      retryCount: json['retryCount'] ?? 0,
      lastError: json['lastError'],
      lastRetryAt: json['lastRetryAt'] != null ? DateTime.parse(json['lastRetryAt']) : null,
    );
  }
}

