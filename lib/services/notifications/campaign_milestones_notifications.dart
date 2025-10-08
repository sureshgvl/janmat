import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../../features/notifications/models/notification_type.dart';
import '../../features/notifications/services/notification_manager.dart';

/// Service for handling campaign milestone notifications
/// Celebrates candidate achievements and progress
class CampaignMilestonesNotifications {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();

  /// Check and send profile completion milestone notifications
  Future<void> checkProfileCompletionMilestone({
    required String candidateId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      AppLogger.notifications('🏆 [CampaignMilestones] Checking profile completion milestones...');

      // Calculate profile completion percentage
      final completionPercentage = _calculateProfileCompletion(profileData);

      // Define milestone thresholds
      final milestones = [25, 50, 75, 90, 100];
      final reachedMilestone = milestones.where((m) => completionPercentage >= m).lastOrNull;

      if (reachedMilestone != null) {
        // Check if this milestone was already celebrated
        final alreadySent = await _hasMilestoneBeenSent(
          candidateId,
          'profile_completion_$reachedMilestone',
        );

        if (!alreadySent) {
          await _sendProfileCompletionMilestoneNotification(
            candidateId: candidateId,
            milestone: reachedMilestone,
            completionPercentage: completionPercentage,
          );

          // Mark milestone as sent
          await _markMilestoneAsSent(candidateId, 'profile_completion_$reachedMilestone');
        }
      }
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error checking profile completion', error: e);
    }
  }

  /// Check and send manifesto completion milestone notifications
  Future<void> checkManifestoCompletionMilestone({
    required String candidateId,
    required Map<String, dynamic> manifestoData,
  }) async {
    try {
      AppLogger.notifications('📜 [CampaignMilestones] Checking manifesto completion milestones...');

      // Calculate manifesto completion score
      final completionScore = _calculateManifestoCompletion(manifestoData);

      // Define milestone thresholds (out of 100)
      final milestones = [25, 50, 75, 100];
      final reachedMilestone = milestones.where((m) => completionScore >= m).lastOrNull;

      if (reachedMilestone != null) {
        final milestoneKey = 'manifesto_completion_$reachedMilestone';
        final alreadySent = await _hasMilestoneBeenSent(candidateId, milestoneKey);

        if (!alreadySent) {
          await _sendManifestoCompletionMilestoneNotification(
            candidateId: candidateId,
            milestone: reachedMilestone,
            completionScore: completionScore,
          );

          await _markMilestoneAsSent(candidateId, milestoneKey);
        }
      }
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error checking manifesto completion', error: e);
    }
  }

  /// Check and send event creation milestone notifications
  Future<void> checkEventCreationMilestone({
    required String candidateId,
    required int eventCount,
  }) async {
    try {
      AppLogger.notifications('📅 [CampaignMilestones] Checking event creation milestones...');

      // Define milestone thresholds
      final milestones = [1, 5, 10, 25, 50, 100];

      for (final milestone in milestones) {
        if (eventCount >= milestone) {
          final milestoneKey = 'event_creation_$milestone';
          final alreadySent = await _hasMilestoneBeenSent(candidateId, milestoneKey);

          if (!alreadySent) {
            await _sendEventCreationMilestoneNotification(
              candidateId: candidateId,
              milestone: milestone,
              totalEvents: eventCount,
            );

            await _markMilestoneAsSent(candidateId, milestoneKey);
          }
        }
      }
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error checking event creation', error: e);
    }
  }

  /// Check and send social engagement milestone notifications
  Future<void> checkSocialEngagementMilestone({
    required String candidateId,
    required Map<String, int> engagementMetrics,
  }) async {
    try {
      AppLogger.notifications('💬 [CampaignMilestones] Checking social engagement milestones...');

      // Check different engagement types
      final followerCount = engagementMetrics['followers'] ?? 0;
      final totalInteractions = engagementMetrics['interactions'] ?? 0;
      final manifestoViews = engagementMetrics['manifestoViews'] ?? 0;

      // Follower milestones
      final followerMilestones = [10, 50, 100, 500, 1000, 5000];
      for (final milestone in followerMilestones) {
        if (followerCount >= milestone) {
          final milestoneKey = 'followers_$milestone';
          final alreadySent = await _hasMilestoneBeenSent(candidateId, milestoneKey);

          if (!alreadySent) {
            await _sendSocialEngagementMilestoneNotification(
              candidateId: candidateId,
              milestoneType: 'followers',
              milestone: milestone,
              currentValue: followerCount,
            );

            await _markMilestoneAsSent(candidateId, milestoneKey);
          }
        }
      }

      // Interaction milestones
      final interactionMilestones = [50, 100, 500, 1000, 5000];
      for (final milestone in interactionMilestones) {
        if (totalInteractions >= milestone) {
          final milestoneKey = 'interactions_$milestone';
          final alreadySent = await _hasMilestoneBeenSent(candidateId, milestoneKey);

          if (!alreadySent) {
            await _sendSocialEngagementMilestoneNotification(
              candidateId: candidateId,
              milestoneType: 'interactions',
              milestone: milestone,
              currentValue: totalInteractions,
            );

            await _markMilestoneAsSent(candidateId, milestoneKey);
          }
        }
      }

      // Manifesto view milestones
      final viewMilestones = [100, 500, 1000, 5000, 10000];
      for (final milestone in viewMilestones) {
        if (manifestoViews >= milestone) {
          final milestoneKey = 'manifesto_views_$milestone';
          final alreadySent = await _hasMilestoneBeenSent(candidateId, milestoneKey);

          if (!alreadySent) {
            await _sendSocialEngagementMilestoneNotification(
              candidateId: candidateId,
              milestoneType: 'manifesto_views',
              milestone: milestone,
              currentValue: manifestoViews,
            );

            await _markMilestoneAsSent(candidateId, milestoneKey);
          }
        }
      }
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error checking social engagement', error: e);
    }
  }

  /// Send profile completion milestone notification
  Future<void> _sendProfileCompletionMilestoneNotification({
    required String candidateId,
    required int milestone,
    required int completionPercentage,
  }) async {
    try {
      final candidate = await _getCandidateData(candidateId);
      if (candidate == null) return;

      final candidateName = candidate['name'] ?? 'Candidate';

      String title;
      String body;

      switch (milestone) {
        case 25:
          title = '🚀 Getting Started!';
          body = '$candidateName reached 25% profile completion. Keep building your campaign!';
          break;
        case 50:
          title = '📈 Halfway There!';
          body = '$candidateName reached 50% profile completion. You\'re making great progress!';
          break;
        case 75:
          title = '💪 Almost Complete!';
          body = '$candidateName reached 75% profile completion. Almost ready to connect with voters!';
          break;
        case 90:
          title = '🎯 Nearly Perfect!';
          body = '$candidateName reached 90% profile completion. Just a few more details!';
          break;
        case 100:
          title = '🎉 Profile Complete!';
          body = '$candidateName completed their profile 100%! Ready to engage with the community!';
          break;
        default:
          title = '📊 Profile Milestone';
          body = '$candidateName reached $milestone% profile completion!';
      }

      await _notificationManager.sendNotification(
        type: NotificationType.profileCompletionMilestone,
        title: title,
        body: body,
        data: {
          'milestone': milestone,
          'completionPercentage': completionPercentage,
          'candidateId': candidateId,
          'candidateName': candidateName,
        },
      );

      AppLogger.notifications('✅ [CampaignMilestones] Profile completion milestone sent: $milestone%');
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error sending profile completion milestone', error: e);
    }
  }

  /// Send manifesto completion milestone notification
  Future<void> _sendManifestoCompletionMilestoneNotification({
    required String candidateId,
    required int milestone,
    required int completionScore,
  }) async {
    try {
      final candidate = await _getCandidateData(candidateId);
      if (candidate == null) return;

      final candidateName = candidate['name'] ?? 'Candidate';

      String title;
      String body;

      switch (milestone) {
        case 25:
          title = '📝 Manifesto Started!';
          body = '$candidateName began building their manifesto. Share your vision!';
          break;
        case 50:
          title = '📖 Manifesto Progress!';
          body = '$candidateName reached 50% manifesto completion. Voters are waiting!';
          break;
        case 75:
          title = '🎯 Manifesto Almost Ready!';
          body = '$candidateName reached 75% manifesto completion. Almost time to share!';
          break;
        case 100:
          title = '📣 Manifesto Complete!';
          body = '$candidateName completed their manifesto! Ready to share with voters!';
          break;
        default:
          title = '📜 Manifesto Milestone';
          body = '$candidateName reached $milestone% manifesto completion!';
      }

      await _notificationManager.sendNotification(
        type: NotificationType.manifestoCompletionMilestone,
        title: title,
        body: body,
        data: {
          'milestone': milestone,
          'completionScore': completionScore,
          'candidateId': candidateId,
          'candidateName': candidateName,
        },
      );

      AppLogger.notifications('✅ [CampaignMilestones] Manifesto completion milestone sent: $milestone%');
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error sending manifesto completion milestone', error: e);
    }
  }

  /// Send event creation milestone notification
  Future<void> _sendEventCreationMilestoneNotification({
    required String candidateId,
    required int milestone,
    required int totalEvents,
  }) async {
    try {
      final candidate = await _getCandidateData(candidateId);
      if (candidate == null) return;

      final candidateName = candidate['name'] ?? 'Candidate';

      String title;
      String body;

      switch (milestone) {
        case 1:
          title = '🎪 First Event!';
          body = '$candidateName created their first campaign event. Great start!';
          break;
        case 5:
          title = '📅 Event Organizer!';
          body = '$candidateName created 5 campaign events. Building momentum!';
          break;
        case 10:
          title = '🎭 Event Master!';
          body = '$candidateName reached 10 events! Voters are taking notice!';
          break;
        case 25:
          title = '🏛️ Campaign Leader!';
          body = '$candidateName created 25 events. Leading the way!';
          break;
        case 50:
          title = '⭐ Event Champion!';
          body = '$candidateName reached 50 events! Extraordinary engagement!';
          break;
        case 100:
          title = '👑 Event Legend!';
          body = '$candidateName created 100 events! Unmatched community outreach!';
          break;
        default:
          title = '📅 Event Milestone';
          body = '$candidateName created $milestone campaign events!';
      }

      await _notificationManager.sendNotification(
        type: NotificationType.eventCreationMilestone,
        title: title,
        body: body,
        data: {
          'milestone': milestone,
          'totalEvents': totalEvents,
          'candidateId': candidateId,
          'candidateName': candidateName,
        },
      );

      AppLogger.notifications('✅ [CampaignMilestones] Event creation milestone sent: $milestone events');
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error sending event creation milestone', error: e);
    }
  }

  /// Send social engagement milestone notification
  Future<void> _sendSocialEngagementMilestoneNotification({
    required String candidateId,
    required String milestoneType,
    required int milestone,
    required int currentValue,
  }) async {
    try {
      final candidate = await _getCandidateData(candidateId);
      if (candidate == null) return;

      final candidateName = candidate['name'] ?? 'Candidate';

      String title;
      String body;
      String emoji;

      switch (milestoneType) {
        case 'followers':
          emoji = '👥';
          title = '$emoji Follower Milestone!';
          body = '$candidateName reached $milestone followers! Growing your community!';
          break;
        case 'interactions':
          emoji = '💬';
          title = '$emoji Engagement Milestone!';
          body = '$candidateName reached $milestone total interactions! Voters are engaging!';
          break;
        case 'manifesto_views':
          emoji = '👁️';
          title = '$emoji Manifesto Views!';
          body = '$candidateName\'s manifesto reached $milestone views! Your message is spreading!';
          break;
        default:
          emoji = '🎯';
          title = '$emoji Engagement Milestone';
          body = '$candidateName reached milestone: $milestone!';
      }

      await _notificationManager.sendNotification(
        type: NotificationType.socialEngagementMilestone,
        title: title,
        body: body,
        data: {
          'milestoneType': milestoneType,
          'milestone': milestone,
          'currentValue': currentValue,
          'candidateId': candidateId,
          'candidateName': candidateName,
        },
      );

      AppLogger.notifications('✅ [CampaignMilestones] Social engagement milestone sent: $milestoneType - $milestone');
    } catch (e) {
      AppLogger.notificationsError('❌ [CampaignMilestones] Error sending social engagement milestone', error: e);
    }
  }

  /// Calculate profile completion percentage
  int _calculateProfileCompletion(Map<String, dynamic> profileData) {
    int completedFields = 0;
    int totalFields = 8; // Basic profile fields to check

    // Check basic info
    if (profileData['name']?.isNotEmpty == true) completedFields++;
    if (profileData['party']?.isNotEmpty == true) completedFields++;
    if (profileData['photo']?.isNotEmpty == true) completedFields++;

    // Check manifesto
    final manifesto = profileData['extraInfo']?['manifesto'];
    if (manifesto != null && manifesto['title']?.isNotEmpty == true) completedFields++;

    // Check contact info
    final contact = profileData['extraInfo']?['contact'];
    if (contact != null && contact['phone']?.isNotEmpty == true) completedFields++;

    // Check achievements
    final achievements = profileData['extraInfo']?['achievements'];
    if (achievements != null && achievements.isNotEmpty) completedFields++;

    // Check events
    final events = profileData['extraInfo']?['events'];
    if (events != null && events.isNotEmpty) completedFields++;

    // Check highlight/banner
    final highlight = profileData['extraInfo']?['highlight'];
    if (highlight != null && highlight['enabled'] == true) completedFields++;

    return ((completedFields / totalFields) * 100).round();
  }

  /// Calculate manifesto completion score
  int _calculateManifestoCompletion(Map<String, dynamic> manifestoData) {
    int score = 0;
    int maxScore = 100;

    // Title (20 points)
    if (manifestoData['title']?.isNotEmpty == true) score += 20;

    // Promises (30 points)
    final promises = manifestoData['promises'];
    if (promises is List && promises.isNotEmpty) {
      final promiseCount = promises.length;
      if (promiseCount >= 5) score += 30;
      else if (promiseCount >= 3) score += 20;
      else if (promiseCount >= 1) score += 10;
    }

    // PDF attachment (15 points)
    if (manifestoData['pdfUrl']?.isNotEmpty == true) score += 15;

    // Image attachment (15 points)
    if (manifestoData['image']?.isNotEmpty == true) score += 15;

    // Video attachment (20 points)
    if (manifestoData['videoUrl']?.isNotEmpty == true) score += 20;

    return score > maxScore ? maxScore : score;
  }

  /// Check if milestone has already been sent
  Future<bool> _hasMilestoneBeenSent(String candidateId, String milestoneKey) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(candidateId)
          .collection('campaign_milestones')
          .doc(milestoneKey)
          .get();

      return doc.exists;
    } catch (e) {
      AppLogger.notificationsError('❌ Error checking milestone status', error: e);
      return false;
    }
  }

  /// Mark milestone as sent
  Future<void> _markMilestoneAsSent(String candidateId, String milestoneKey) async {
    try {
      await _firestore
          .collection('users')
          .doc(candidateId)
          .collection('campaign_milestones')
          .doc(milestoneKey)
          .set({
            'sentAt': FieldValue.serverTimestamp(),
            'milestoneKey': milestoneKey,
          });
    } catch (e) {
      AppLogger.notificationsError('❌ Error marking milestone as sent', error: e);
    }
  }

  /// Get candidate data
  Future<Map<String, dynamic>?> _getCandidateData(String candidateId) async {
    try {
      // This would need to be implemented based on your candidate data structure
      // For now, return basic candidate info
      final userDoc = await _firestore.collection('users').doc(candidateId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      AppLogger.notificationsError('❌ Error getting candidate data', error: e);
      return null;
    }
  }
}
