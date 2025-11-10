import 'dart:async';
import '../../../utils/app_logger.dart';
import '../models/typing_status.dart';

/// Service responsible for managing typing status in chat rooms
/// Handles typing indicators, status updates, and cleanup
/// Note: This is a local implementation - typing status is not persisted to server
class TypingStatusManager {
  // Map to track typing timers for each user in each room
  final Map<String, Map<String, Timer>> _typingTimers = {};

  // Map to track current typing statuses locally
  final Map<String, List<TypingStatus>> _typingStatuses = {};

  // Stream controllers for typing status updates
  final Map<String, StreamController<List<TypingStatus>>> _statusControllers = {};

  /// Get stream of typing status updates for a room
  Stream<List<TypingStatus>> getTypingStatuses(String roomId) {
    _statusControllers.putIfAbsent(roomId, () => StreamController<List<TypingStatus>>.broadcast());
    _typingStatuses.putIfAbsent(roomId, () => []);

    // Emit current status immediately
    Future.microtask(() {
      _statusControllers[roomId]?.add(List.from(_typingStatuses[roomId] ?? []));
    });

    return _statusControllers[roomId]!.stream;
  }

  /// Start typing indicator for a user in a room
  void startTyping(String roomId, String userId, String userName) {
    AppLogger.chat('TypingStatusManager: User $userId started typing in room $roomId');

    // Cancel existing timer if any
    _cancelTypingTimer(roomId, userId);

    // Update typing status
    _updateTypingStatus(roomId, userId, userName, true);

    // Start timer to automatically stop typing after 5 seconds
    _startTypingTimer(roomId, userId);
  }

  /// Stop typing indicator for a user in a room
  void stopTyping(String roomId, String userId) {
    AppLogger.chat('TypingStatusManager: User $userId stopped typing in room $roomId');

    // Cancel timer
    _cancelTypingTimer(roomId, userId);

    // Update typing status
    _updateTypingStatus(roomId, userId, '', false);
  }

  /// Handle text input changes to manage typing status
  void onTextChanged(String roomId, String userId, String userName, String text) {
    if (text.isNotEmpty) {
      // User is typing
      startTyping(roomId, userId, userName);
    } else {
      // User stopped typing (empty text)
      stopTyping(roomId, userId);
    }
  }

  /// Handle message sent - automatically stop typing
  void onMessageSent(String roomId, String userId) {
    stopTyping(roomId, userId);
  }

  /// Update typing status and notify listeners
  void _updateTypingStatus(String roomId, String userId, String userName, bool isTyping) {
    _typingStatuses.putIfAbsent(roomId, () => []);

    final statuses = _typingStatuses[roomId]!;
    final existingIndex = statuses.indexWhere((status) => status.userId == userId);

    if (isTyping) {
      final newStatus = TypingStatus(
        userId: userId,
        userName: userName,
        isTyping: true,
        timestamp: DateTime.now(),
      );

      if (existingIndex >= 0) {
        statuses[existingIndex] = newStatus;
      } else {
        statuses.add(newStatus);
      }
    } else {
      if (existingIndex >= 0) {
        statuses.removeAt(existingIndex);
      }
    }

    // Notify listeners
    _statusControllers[roomId]?.add(List.from(statuses));
  }

  /// Start timer to automatically stop typing after timeout
  void _startTypingTimer(String roomId, String userId) {
    _typingTimers.putIfAbsent(roomId, () => {});
    _typingTimers[roomId]![userId] = Timer(const Duration(seconds: 5), () {
      stopTyping(roomId, userId);
    });
  }

  /// Cancel typing timer for a user
  void _cancelTypingTimer(String roomId, String userId) {
    if (_typingTimers.containsKey(roomId) && _typingTimers[roomId]!.containsKey(userId)) {
      _typingTimers[roomId]![userId]!.cancel();
      _typingTimers[roomId]!.remove(userId);

      // Clean up empty room maps
      if (_typingTimers[roomId]!.isEmpty) {
        _typingTimers.remove(roomId);
      }
    }
  }

  /// Check if a user is currently typing in a room
  bool isUserTyping(String roomId, String userId) {
    final statuses = _typingStatuses[roomId] ?? [];
    return statuses.any((status) => status.userId == userId && status.isTyping);
  }

  /// Get list of users currently typing in a room
  List<String> getTypingUsers(String roomId) {
    final statuses = _typingStatuses[roomId] ?? [];
    return statuses
        .where((status) => status.isTyping)
        .map((status) => status.userName)
        .toList();
  }

  /// Get typing status text for display (e.g., "John is typing...")
  String getTypingStatusText(String roomId) {
    final typingUsers = getTypingUsers(roomId);

    if (typingUsers.isEmpty) {
      return '';
    } else if (typingUsers.length == 1) {
      return '${typingUsers.first} is typing...';
    } else if (typingUsers.length == 2) {
      return '${typingUsers[0]} and ${typingUsers[1]} are typing...';
    } else {
      return '${typingUsers[0]} and ${typingUsers.length - 1} others are typing...';
    }
  }

  /// Clean up all typing timers and controllers (call when leaving room or app)
  void cleanup() {
    AppLogger.chat('TypingStatusManager: Cleaning up all typing timers and controllers');

    // Cancel all timers
    for (final roomTimers in _typingTimers.values) {
      for (final timer in roomTimers.values) {
        timer.cancel();
      }
    }
    _typingTimers.clear();

    // Close all stream controllers
    for (final controller in _statusControllers.values) {
      controller.close();
    }
    _statusControllers.clear();

    // Clear status data
    _typingStatuses.clear();
  }

  /// Clean up typing timers and controllers for a specific room
  void cleanupRoom(String roomId) {
    AppLogger.chat('TypingStatusManager: Cleaning up typing timers for room $roomId');

    // Cancel timers for this room
    if (_typingTimers.containsKey(roomId)) {
      for (final timer in _typingTimers[roomId]!.values) {
        timer.cancel();
      }
      _typingTimers.remove(roomId);
    }

    // Close controller for this room
    if (_statusControllers.containsKey(roomId)) {
      _statusControllers[roomId]!.close();
      _statusControllers.remove(roomId);
    }

    // Clear status data for this room
    _typingStatuses.remove(roomId);
  }

  /// Force stop all typing indicators for a room
  void forceStopAllTyping(String roomId) {
    AppLogger.chat('TypingStatusManager: Force stopping all typing in room $roomId');

    // Clear all statuses for this room
    _typingStatuses[roomId] = [];
    _statusControllers[roomId]?.add([]);

    // Cancel all timers for this room
    cleanupRoom(roomId);
  }
}
