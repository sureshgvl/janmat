import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/gamification_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../models/notification_type.dart';
import '../models/notification_status.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

/// Service for handling gamification-related notifications
class GamificationNotificationService {
  final NotificationRepository _notificationRepository = NotificationRepositoryImpl();

  // Get gamification service when needed to avoid circular dependency
  GamificationService get _gamificationService => Get.find<GamificationService>();

  /// Send level up notification when user reaches a new level
  Future<void> sendLevelUpNotification({
    required String userId,
    required int newLevel,
    required int points,
  }) async {
    try {
      final levelDetails = GamificationService.getLevelDetails(newLevel);

      final notification = NotificationModel(
        id: 'level_up_${userId}_${newLevel}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.levelUp,
        title: '🎉 Level Up!',
        body: 'Congratulations! You\'ve reached ${levelDetails['title']} (Level $newLevel) with $points points!',
        data: {
          'newLevel': newLevel.toString(),
          'points': points.toString(),
          'levelTitle': levelDetails['title'],
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      AppLogger.common('🔔 Level up notification sent for user $userId (Level $newLevel)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to send level up notification', error: e);
    }
  }

  /// Send badge earned notification when user achieves a milestone
  Future<void> sendBadgeEarnedNotification({
    required String userId,
    required String badgeType,
    required int points,
  }) async {
    try {
      final allBadgeDetails = GamificationService.getAchievementDetails();
      final badgeDetails = allBadgeDetails[badgeType];

      if (badgeDetails == null) {
        AppLogger.common('⚠️ Badge type $badgeType not found');
        return;
      }

      final notification = NotificationModel(
        id: 'badge_${userId}_${badgeType}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.badgeEarned,
        title: '🏆 Achievement Unlocked!',
        body: 'You earned the "${badgeDetails['title']}" badge for reaching $points points!',
        data: {
          'badgeType': badgeType,
          'badgeTitle': badgeDetails['title'],
          'badgeDescription': badgeDetails['description'],
          'badgeIcon': badgeDetails['icon'],
          'points': points.toString(),
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      AppLogger.common('🔔 Badge earned notification sent for user $userId ($badgeType)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to send badge earned notification', error: e);
    }
  }

  /// Send streak achievement notification
  Future<void> sendStreakAchievementNotification({
    required String userId,
    required int streakCount,
    required String streakType, // 'rsvp', 'login', etc.
  }) async {
    try {
      final notification = NotificationModel(
        id: 'streak_${userId}_${streakType}_${streakCount}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.streakAchievement,
        title: '🔥 Streak Achievement!',
        body: 'Amazing! You\'ve maintained a $streakCount-day streak for $streakType activities!',
        data: {
          'streakCount': streakCount.toString(),
          'streakType': streakType,
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      AppLogger.common('🔔 Streak achievement notification sent for user $userId ($streakCount days)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to send streak achievement notification', error: e);
    }
  }

  /// Send points earned notification
  Future<void> sendPointsEarnedNotification({
    required String userId,
    required int pointsEarned,
    required String reason,
    required int totalPoints,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'points_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.pointsEarned,
        title: '⭐ Points Earned!',
        body: 'You earned $pointsEarned points for $reason. Total points: $totalPoints',
        data: {
          'pointsEarned': pointsEarned.toString(),
          'reason': reason,
          'totalPoints': totalPoints.toString(),
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      AppLogger.common('🔔 Points earned notification sent for user $userId (+$pointsEarned points)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to send points earned notification', error: e);
    }
  }

  /// Check for level up and send notification if needed
  Future<void> checkAndNotifyLevelUp(String userId) async {
    try {
      final gamificationData = await _gamificationService.getUserGamificationData(userId);
      final currentPoints = gamificationData['points'] as int;
      final currentLevel = gamificationData['level'] as int;

      // Calculate level using simple formula (every 100 points = 1 level)
      final calculatedLevel = (currentPoints / 100).floor() + 1;

      // If user leveled up
      if (calculatedLevel > currentLevel) {
        await sendLevelUpNotification(
          userId: userId,
          newLevel: calculatedLevel,
          points: currentPoints,
        );
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to check level up', error: e);
    }
  }

  /// Check for new achievements and send notifications
  Future<void> checkAndNotifyAchievements(String userId) async {
    try {
      final gamificationData = await _gamificationService.getUserGamificationData(userId);
      final currentPoints = gamificationData['points'] as int;
      final currentAchievements = List<String>.from(gamificationData['achievements']);

      // Check each achievement type with known thresholds
      final achievements = {
        'social_butterfly': 50,
        'event_enthusiast': 100,
        'community_champion': 200,
      };

      for (final entry in achievements.entries) {
        final achievementType = entry.key;
        final threshold = entry.value;

        // If user qualifies for achievement and doesn't have it yet
        if (currentPoints >= threshold && !currentAchievements.contains(achievementType)) {
          await sendBadgeEarnedNotification(
            userId: userId,
            badgeType: achievementType,
            points: currentPoints,
          );

          // Note: The actual achievement granting is handled by GamificationService
        }
      }
    } catch (e) {
      AppLogger.commonError('❌ Failed to check achievements', error: e);
    }
  }

  /// Handle RSVP points and check for notifications
  Future<void> handleRSVPEarned({
    required String userId,
    required String eventTitle,
    required int pointsEarned,
  }) async {
    try {
      // Send points earned notification
      final gamificationData = await _gamificationService.getUserGamificationData(userId);
      final totalPoints = gamificationData['points'] as int;

      await sendPointsEarnedNotification(
        userId: userId,
        pointsEarned: pointsEarned,
        reason: 'RSVP to "$eventTitle"',
        totalPoints: totalPoints,
      );

      // Check for level up
      await checkAndNotifyLevelUp(userId);

      // Check for achievements
      await checkAndNotifyAchievements(userId);

    } catch (e) {
      AppLogger.commonError('❌ Failed to handle RSVP earned', error: e);
    }
  }

  /// Handle ad watching XP reward and check for notifications
  Future<void> handleXPFromAd({
    required String userId,
    required int xpEarned,
  }) async {
    try {
      // Send points earned notification
      final gamificationData = await _gamificationService.getUserGamificationData(userId);
      final totalPoints = gamificationData['points'] as int;

      await sendPointsEarnedNotification(
        userId: userId,
        pointsEarned: xpEarned,
        reason: 'watching a rewarded ad',
        totalPoints: totalPoints,
      );

      // Check for level up
      await checkAndNotifyLevelUp(userId);

    } catch (e) {
      AppLogger.commonError('❌ Failed to handle XP from ad', error: e);
    }
  }

  /// Send milestone celebration notifications
  Future<void> sendMilestoneNotification({
    required String userId,
    required String milestoneType, // 'first_rsvp', 'hundred_points', etc.
    required String description,
  }) async {
    try {
      final notification = NotificationModel(
        id: 'milestone_${userId}_${milestoneType}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: NotificationType.badgeEarned, // Using badge type for milestones
        title: '🎊 Milestone Reached!',
        body: description,
        data: {
          'milestoneType': milestoneType,
          'description': description,
        },
        status: NotificationStatus.unread,
        createdAt: DateTime.now(),
      );

      await _notificationRepository.createNotification(notification);
      AppLogger.common('🔔 Milestone notification sent for user $userId ($milestoneType)');
    } catch (e) {
      AppLogger.commonError('❌ Failed to send milestone notification', error: e);
    }
  }
}
