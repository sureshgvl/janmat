import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../utils/app_logger.dart';
import '../models/notification_type.dart';
import '../models/notification_status.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

/// Service for scheduling notifications and reminders
class NotificationSchedulerService {
  final NotificationRepository _notificationRepository = NotificationRepositoryImpl();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Schedule a reminder notification
  Future<void> scheduleReminder({
    required String userId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationType type,
    Map<String, dynamic> data = const {},
    String? payload,
  }) async {
    try {
      final notificationId = _generateNotificationId(userId, type, scheduledTime);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'scheduled_notifications',
        'Scheduled Notifications',
        channelDescription: 'Reminders and scheduled notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        payload: payload ?? data.toString(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Store the scheduled notification in database
      final scheduledNotification = NotificationModel(
        id: 'scheduled_${notificationId}',
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: {
          ...data,
          'scheduledTime': scheduledTime.toIso8601String(),
          'isScheduled': true,
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(scheduledNotification);

      AppLogger.common('⏰ Scheduled notification for ${scheduledTime.toString()}');
    } catch (e) {
      AppLogger.commonError('❌ Failed to schedule notification', error: e);
    }
  }

  /// Schedule event reminder
  Future<void> scheduleEventReminder({
    required String userId,
    required String eventId,
    required String eventTitle,
    required DateTime eventTime,
    required Duration reminderBefore,
  }) async {
    final reminderTime = eventTime.subtract(reminderBefore);

    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      AppLogger.common('⚠️ Reminder time is in the past, skipping');
      return;
    }

    await scheduleReminder(
      userId: userId,
      title: 'Event Reminder',
      body: '"$eventTitle" starts ${reminderBefore.inHours}h from now',
      scheduledTime: reminderTime,
      type: NotificationType.eventReminder,
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventTime': eventTime.toIso8601String(),
        'reminderBefore': reminderBefore.inMinutes,
      },
    );
  }

  /// Schedule poll deadline reminder
  Future<void> schedulePollDeadlineReminder({
    required String userId,
    required String pollId,
    required String pollQuestion,
    required DateTime deadline,
    required Duration reminderBefore,
  }) async {
    final reminderTime = deadline.subtract(reminderBefore);

    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    await scheduleReminder(
      userId: userId,
      title: 'Poll Deadline',
      body: 'Poll "$pollQuestion" ends ${reminderBefore.inHours}h from now',
      scheduledTime: reminderTime,
      type: NotificationType.pollDeadline,
      data: {
        'pollId': pollId,
        'pollQuestion': pollQuestion,
        'deadline': deadline.toIso8601String(),
        'reminderBefore': reminderBefore.inMinutes,
      },
    );
  }

  /// Schedule daily activity reminder
  Future<void> scheduleDailyActivityReminder({
    required String userId,
    required TimeOfDay reminderTime,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await scheduleReminder(
      userId: userId,
      title: 'Daily Activity Reminder',
      body: 'Don\'t forget to check out today\'s events and polls!',
      scheduledTime: scheduledTime,
      type: NotificationType.appUpdate,
      data: {
        'reminderType': 'daily_activity',
        'scheduledHour': reminderTime.hour,
        'scheduledMinute': reminderTime.minute,
      },
    );
  }

  /// Schedule weekly summary notification
  Future<void> scheduleWeeklySummary({
    required String userId,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required TimeOfDay summaryTime,
  }) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      summaryTime.hour,
      summaryTime.minute,
    );

    // Find the next occurrence of the specified day
    final daysUntilTarget = (dayOfWeek - now.weekday + 7) % 7;
    if (daysUntilTarget == 0 && scheduledTime.isBefore(now)) {
      // Today is the target day but time has passed, schedule for next week
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    } else {
      scheduledTime = scheduledTime.add(Duration(days: daysUntilTarget));
    }

    await scheduleReminder(
      userId: userId,
      title: 'Weekly Summary',
      body: 'Check out your activity summary for this week!',
      scheduledTime: scheduledTime,
      type: NotificationType.contentUpdate,
      data: {
        'summaryType': 'weekly',
        'dayOfWeek': dayOfWeek,
        'scheduledHour': summaryTime.hour,
        'scheduledMinute': summaryTime.minute,
      },
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      AppLogger.common('❌ Cancelled scheduled notification: $notificationId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to cancel scheduled notification', error: e);
    }
  }

  /// Cancel all scheduled notifications for a user
  Future<void> cancelAllScheduledNotifications(String userId) async {
    try {
      // Get all scheduled notifications from database
      final notifications = await _notificationRepository.getUserNotifications(userId);
      final scheduledNotifications = notifications.where((n) =>
        n.data['isScheduled'] == true
      ).toList();

      // Cancel each one
      for (final notification in scheduledNotifications) {
        final scheduledId = _extractNotificationIdFromScheduled(notification.id);
        if (scheduledId != null) {
          await cancelScheduledNotification(scheduledId);
        }
      }

      AppLogger.common('❌ Cancelled all scheduled notifications for user: $userId');
    } catch (e) {
      AppLogger.commonError('❌ Failed to cancel all scheduled notifications', error: e);
    }
  }

  /// Get pending scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingScheduledNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      AppLogger.commonError('❌ Failed to get pending notifications', error: e);
      return [];
    }
  }

  /// Initialize the scheduler service
  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);
      AppLogger.common('✅ Notification scheduler initialized');
    } catch (e) {
      AppLogger.commonError('❌ Failed to initialize notification scheduler', error: e);
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String userId, NotificationType type, DateTime time) {
    final hash = userId.hashCode + type.hashCode + time.millisecondsSinceEpoch.hashCode;
    return hash.abs() % 1000000; // Keep within reasonable range
  }

  /// Extract notification ID from scheduled notification ID
  int? _extractNotificationIdFromScheduled(String scheduledId) {
    if (scheduledId.startsWith('scheduled_')) {
      final idStr = scheduledId.substring(10);
      return int.tryParse(idStr);
    }
    return null;
  }
}
