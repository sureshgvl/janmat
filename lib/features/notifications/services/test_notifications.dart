import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_type.dart';
import 'notification_manager.dart';

/// Test service for manually testing notification functionality
class NotificationTester {
  final NotificationManager _notificationManager = NotificationManager();

  /// Test New Follower notification with real user data
  Future<void> testNewFollowerNotification() async {
    try {
      debugPrint('🧪 Testing New Follower Notification...');

      // Get current user (who will receive the notification)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      // Use current user as the candidate receiving the notification
      final candidateId = currentUser.uid;
      final followerId = 'demo_follower_${DateTime.now().millisecondsSinceEpoch}';
      const String candidateName = 'You'; // Since it's the current user
      const int followerCount = 25;

      // Create notification data
      final data = {
        'candidateId': candidateId,
        'followerId': followerId,
        'followerName': 'John Doe',
        'followerCount': followerCount.toString(),
      };

      // Send notification using the manager
      await _notificationManager.sendNotification(
        type: NotificationType.newFollower,
        title: 'New Follower!',
        body: 'John Doe started following you. You now have $followerCount followers!',
        data: data,
      );

      // Update badge count
      await _notificationManager.updateBadgeCount();

      // Track analytics
      final notificationId = 'test_new_follower_${DateTime.now().millisecondsSinceEpoch}';
      await _notificationManager.trackNotificationDelivered(
        notificationId: notificationId,
        type: NotificationType.newFollower,
        deliveryMethod: 'both',
      );

      debugPrint('✅ New Follower notification test completed for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ New Follower notification test failed: $e');
    }
  }

  /// Test Level Up notification with real user data
  Future<void> testLevelUpNotification() async {
    try {
      debugPrint('🧪 Testing Level Up Notification...');

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      const int newLevel = 5;
      const int points = 450;

      await _notificationManager.sendNotification(
        type: NotificationType.levelUp,
        title: '🎉 Level Up!',
        body: 'Congratulations! You\'ve reached Level $newLevel with $points points!',
        data: {
          'newLevel': newLevel.toString(),
          'points': points.toString(),
          'levelTitle': 'Community Member',
        },
      );

      // Track analytics
      final notificationId = 'test_level_up_${DateTime.now().millisecondsSinceEpoch}';
      await _notificationManager.trackNotificationDelivered(
        notificationId: notificationId,
        type: NotificationType.levelUp,
        deliveryMethod: 'both',
      );

      debugPrint('✅ Level Up notification test completed for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ Level Up notification test failed: $e');
    }
  }

  /// Test Badge Earned notification
  Future<void> testBadgeEarnedNotification() async {
    try {
      debugPrint('🧪 Testing Badge Earned Notification...');

      await _notificationManager.sendNotification(
        type: NotificationType.badgeEarned,
        title: '🏆 Achievement Unlocked!',
        body: 'You earned the "Social Butterfly" badge for reaching 50 RSVP points!',
        data: {
          'badgeType': 'social_butterfly',
          'badgeTitle': 'Social Butterfly',
          'badgeDescription': 'Earned 50+ RSVP points',
          'badgeIcon': '🦋',
          'points': '50',
        },
      );

      debugPrint('✅ Badge Earned notification test completed');
    } catch (e) {
      debugPrint('❌ Badge Earned notification test failed: $e');
    }
  }

  /// Test Event Reminder notification
  Future<void> testEventReminderNotification() async {
    try {
      debugPrint('🧪 Testing Event Reminder Notification...');

      await _notificationManager.sendNotification(
        type: NotificationType.eventReminder,
        title: 'Event Reminder',
        body: '"Town Hall Meeting" starts in 1 hour',
        data: {
          'eventId': 'event_123',
          'eventTitle': 'Town Hall Meeting',
          'eventTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'reminderBefore': '60', // minutes
        },
      );

      debugPrint('✅ Event Reminder notification test completed');
    } catch (e) {
      debugPrint('❌ Event Reminder notification test failed: $e');
    }
  }

  /// Test Chat Message notification with real user data
  Future<void> testChatMessageNotification() async {
    try {
      debugPrint('🧪 Testing Chat Message Notification...');

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      await _notificationManager.sendNotification(
        type: NotificationType.newMessage,
        title: 'New Message',
        body: 'Rajesh Kumar: Hello, how are you doing?',
        data: {
          'senderId': 'demo_sender_${DateTime.now().millisecondsSinceEpoch}',
          'senderName': 'Rajesh Kumar',
          'chatRoomId': 'demo_chat_${DateTime.now().millisecondsSinceEpoch}',
          'messagePreview': 'Hello, how are you doing?',
        },
      );

      // Track analytics
      final notificationId = 'test_chat_${DateTime.now().millisecondsSinceEpoch}';
      await _notificationManager.trackNotificationDelivered(
        notificationId: notificationId,
        type: NotificationType.newMessage,
        deliveryMethod: 'both',
      );

      debugPrint('✅ Chat Message notification test completed for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ Chat Message notification test failed: $e');
    }
  }

  /// Test Poll notification with real user data
  Future<void> testPollNotification() async {
    try {
      debugPrint('🧪 Testing Poll Notification...');

      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No user logged in');
        return;
      }

      await _notificationManager.sendNotification(
        type: NotificationType.newPoll,
        title: 'New Poll Available',
        body: 'Should we increase the local infrastructure budget?',
        data: {
          'pollId': 'demo_poll_${DateTime.now().millisecondsSinceEpoch}',
          'pollQuestion': 'Should we increase the local infrastructure budget?',
          'endDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        },
      );

      // Track analytics
      final notificationId = 'test_poll_${DateTime.now().millisecondsSinceEpoch}';
      await _notificationManager.trackNotificationDelivered(
        notificationId: notificationId,
        type: NotificationType.newPoll,
        deliveryMethod: 'both',
      );

      debugPrint('✅ Poll notification test completed for user: ${currentUser.uid}');
    } catch (e) {
      debugPrint('❌ Poll notification test failed: $e');
    }
  }

  /// Test all notification types
  Future<void> testAllNotifications() async {
    debugPrint('🧪 Starting comprehensive notification test...');

    await testNewFollowerNotification();
    await Future.delayed(const Duration(seconds: 2));

    await testLevelUpNotification();
    await Future.delayed(const Duration(seconds: 2));

    await testBadgeEarnedNotification();
    await Future.delayed(const Duration(seconds: 2));

    await testEventReminderNotification();
    await Future.delayed(const Duration(seconds: 2));

    await testChatMessageNotification();
    await Future.delayed(const Duration(seconds: 2));

    await testPollNotification();

    debugPrint('✅ All notification tests completed');
  }

  /// Clear all test notifications
  Future<void> clearTestNotifications() async {
    try {
      debugPrint('🧪 Clearing test notifications...');
      await _notificationManager.deleteAllNotifications();
      await _notificationManager.clearBadge();
      debugPrint('✅ Test notifications cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear test notifications: $e');
    }
  }

  /// Get notification statistics
  Future<void> printNotificationStats() async {
    try {
      final unreadCount = await _notificationManager.getUnreadCount();
      final analytics = await _notificationManager.getNotificationAnalytics();

      debugPrint('📊 Notification Statistics:');
      debugPrint('   Unread Count: $unreadCount');
      debugPrint('   Total Delivered: ${analytics['totalDelivered']}');
      debugPrint('   Total Opened: ${analytics['totalOpened']}');
      debugPrint('   Open Rate: ${analytics['openRate']}');
    } catch (e) {
      debugPrint('❌ Failed to get notification stats: $e');
    }
  }
}

/// Global instance for easy access
final notificationTester = NotificationTester();