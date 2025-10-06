import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

/// Service for managing notification badges on app icons
class NotificationBadgeService {
  final NotificationRepository _notificationRepository = NotificationRepositoryImpl();

  static const MethodChannel _platformChannel = MethodChannel('com.janmat.notifications/badge');

  /// Update the app icon badge with unread notification count
  Future<void> updateBadgeCount(String userId) async {
    try {
      final unreadCount = await _notificationRepository.getUnreadCount(userId);

      // Update platform-specific badge
      await _updatePlatformBadge(unreadCount);

      debugPrint('🔔 Updated app badge count to: $unreadCount');
    } catch (e) {
      debugPrint('❌ Failed to update badge count: $e');
    }
  }

  /// Clear the app icon badge
  Future<void> clearBadge() async {
    try {
      await _updatePlatformBadge(0);
      debugPrint('🔔 Cleared app badge');
    } catch (e) {
      debugPrint('❌ Failed to clear badge: $e');
    }
  }

  /// Increment badge count by 1
  Future<void> incrementBadge(String userId) async {
    try {
      final currentCount = await _notificationRepository.getUnreadCount(userId);
      final newCount = currentCount + 1;

      await _updatePlatformBadge(newCount);
      debugPrint('🔔 Incremented badge count to: $newCount');
    } catch (e) {
      debugPrint('❌ Failed to increment badge: $e');
    }
  }

  /// Decrement badge count by 1 (minimum 0)
  Future<void> decrementBadge(String userId) async {
    try {
      final currentCount = await _notificationRepository.getUnreadCount(userId);
      final newCount = (currentCount - 1).clamp(0, double.infinity).toInt();

      await _updatePlatformBadge(newCount);
      debugPrint('🔔 Decremented badge count to: $newCount');
    } catch (e) {
      debugPrint('❌ Failed to decrement badge: $e');
    }
  }

  /// Update platform-specific badge implementation
  Future<void> _updatePlatformBadge(int count) async {
    try {
      // For Android
      await _platformChannel.invokeMethod('updateBadge', {'count': count});
    } catch (e) {
      debugPrint('⚠️ Platform badge update failed (may not be supported): $e');
      // This is expected on some platforms, so we don't throw
    }
  }

  /// Initialize badge service (call this on app start)
  Future<void> initialize(String userId) async {
    try {
      // Set up platform channel handler for iOS badge updates
      _platformChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'requestBadgeUpdate':
            await updateBadgeCount(userId);
            break;
          case 'clearBadge':
            await clearBadge();
            break;
          default:
            debugPrint('⚠️ Unknown badge method: ${call.method}');
        }
      });

      // Initial badge update
      await updateBadgeCount(userId);

      debugPrint('✅ Notification badge service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize badge service: $e');
    }
  }

  /// Refresh badge when app comes to foreground
  Future<void> refreshBadgeOnForeground(String userId) async {
    try {
      await updateBadgeCount(userId);
      debugPrint('🔄 Refreshed badge on app foreground');
    } catch (e) {
      debugPrint('❌ Failed to refresh badge on foreground: $e');
    }
  }

  /// Handle notification read/unread changes
  Future<void> onNotificationStatusChanged(String userId, bool isRead) async {
    try {
      if (isRead) {
        await decrementBadge(userId);
      } else {
        await incrementBadge(userId);
      }
    } catch (e) {
      debugPrint('❌ Failed to handle notification status change: $e');
    }
  }

  /// Handle bulk notification operations
  Future<void> onBulkNotificationOperation(String userId, String operation) async {
    try {
      switch (operation) {
        case 'markAllRead':
          await clearBadge();
          break;
        case 'deleteAll':
          await clearBadge();
          break;
        case 'newNotification':
          await incrementBadge(userId);
          break;
        default:
          debugPrint('⚠️ Unknown bulk operation: $operation');
      }
    } catch (e) {
      debugPrint('❌ Failed to handle bulk notification operation: $e');
    }
  }
}