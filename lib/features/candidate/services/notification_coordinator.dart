import '../../../utils/app_logger.dart';
import '../../../services/notifications/constituency_notifications.dart';
import '../../../services/notifications/campaign_milestones_notifications.dart';
import '../models/candidate_model.dart';

/// Service responsible for coordinating all notification operations.
/// Follows Single Responsibility Principle - handles only notifications.
class NotificationCoordinator {
  final ConstituencyNotifications _constituencyNotifications = ConstituencyNotifications();
  final CampaignMilestonesNotifications _campaignMilestones = CampaignMilestonesNotifications();

  /// Send profile update notification
  Future<void> sendProfileUpdateNotification({
    required String candidateId,
    required String updateType,
    required String updateDescription,
  }) async {
    try {
      AppLogger.database('Sending profile update notification: $updateType - $updateDescription', tag: 'NOTIFICATION_COORDINATOR');

      await _constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: updateType,
        updateDescription: updateDescription,
      );

      AppLogger.database('Profile update notification sent successfully', tag: 'NOTIFICATION_COORDINATOR');
    } catch (e) {
      AppLogger.databaseError('Error sending profile update notification', tag: 'NOTIFICATION_COORDINATOR', error: e);
      // Don't throw - profile save should succeed even if notification fails
    }
  }

  /// Send manifesto update notification
  Future<void> sendManifestoUpdateNotification({
    required String candidateId,
    required String updateType,
    required String manifestoTitle,
    String? manifestoDescription,
  }) async {
    try {
      AppLogger.database('Sending manifesto notification: $updateType - $manifestoTitle', tag: 'NOTIFICATION_COORDINATOR');

      await _constituencyNotifications.sendManifestoUpdateNotification(
        candidateId: candidateId,
        updateType: updateType,
        manifestoTitle: manifestoTitle,
        manifestoDescription: manifestoDescription,
      );

      AppLogger.database('Manifesto update notification sent successfully', tag: 'NOTIFICATION_COORDINATOR');
    } catch (e) {
      AppLogger.databaseError('Error sending manifesto update notification', tag: 'NOTIFICATION_COORDINATOR', error: e);
      // Don't throw - manifesto save should succeed even if notification fails
    }
  }

  /// Check for campaign milestones after profile updates
  Future<void> checkCampaignMilestones({
    required String candidateId,
    required Map<String, dynamic> profileData,
    Map<String, dynamic>? manifestoData,
  }) async {
    try {
      // Check profile completion milestones
      await _campaignMilestones.checkProfileCompletionMilestone(
        candidateId: candidateId,
        profileData: profileData,
      );

      // Check manifesto completion milestones if manifesto was updated
      if (manifestoData != null) {
        await _campaignMilestones.checkManifestoCompletionMilestone(
          candidateId: candidateId,
          manifestoData: manifestoData,
        );
      }

      AppLogger.database('Milestone checks completed', tag: 'NOTIFICATION_COORDINATOR');
    } catch (e) {
      AppLogger.databaseError('Error checking milestones', tag: 'NOTIFICATION_COORDINATOR', error: e);
      // Don't throw - milestone checks shouldn't block profile saves
    }
  }

  /// Run post-save notification operations in parallel
  Future<void> runPostSaveNotifications({
    required String tabName,
    required String candidateId,
    required Map<String, dynamic> changedExtraInfoFields,
    required Candidate candidate,
  }) async {
    try {
      List<Future> notificationOperations = [];

      // Send notifications in parallel
      if (tabName == 'basic_info') {
        notificationOperations.add(_sendProfileUpdateNotificationForTab(candidateId, changedExtraInfoFields));
      }

      if (tabName == 'manifesto' && changedExtraInfoFields.containsKey('manifesto')) {
        notificationOperations.add(_sendManifestoUpdateNotificationForTab(candidateId, changedExtraInfoFields));
      }

      // Check milestones in parallel
      notificationOperations.add(_checkMilestonesForTab(candidateId, candidate, changedExtraInfoFields));

      // Run all notification operations in parallel
      await Future.wait(notificationOperations);

      AppLogger.database('Post-save notifications completed for tab: $tabName', tag: 'NOTIFICATION_COORDINATOR');
    } catch (e) {
      AppLogger.databaseError('Error in post-save notifications', tag: 'NOTIFICATION_COORDINATOR', error: e);
      // Don't throw - post-save operations shouldn't block the save success
    }
  }

  /// Send profile update notification for tab save
  Future<void> _sendProfileUpdateNotificationForTab(
    String candidateId,
    Map<String, dynamic> changedExtraInfoFields,
  ) async {
    // Determine what type of update occurred
    String updateType = 'profile';
    String updateDescription = 'updated their profile';

    // Check what fields were changed to provide more specific notifications
    if (changedExtraInfoFields.containsKey('profession')) {
      updateType = 'profession';
      updateDescription = 'updated their profession to ${changedExtraInfoFields['profession']}';
    } else if (changedExtraInfoFields.containsKey('education')) {
      updateType = 'education';
      updateDescription = 'updated their education details';
    } else if (changedExtraInfoFields.containsKey('manifesto')) {
      updateType = 'manifesto';
      updateDescription = 'updated their manifesto';
    } else if (changedExtraInfoFields.containsKey('contact')) {
      updateType = 'contact';
      updateDescription = 'updated their contact information';
    } else if (changedExtraInfoFields.containsKey('achievements')) {
      updateType = 'achievements';
      updateDescription = 'updated their achievements';
    }

    await sendProfileUpdateNotification(
      candidateId: candidateId,
      updateType: updateType,
      updateDescription: updateDescription,
    );
  }

  /// Send manifesto update notification for tab save
  Future<void> _sendManifestoUpdateNotificationForTab(
    String candidateId,
    Map<String, dynamic> changedExtraInfoFields,
  ) async {
    // Check if manifesto was actually changed
    if (!changedExtraInfoFields.containsKey('manifesto')) {
      AppLogger.database('No manifesto changes detected, skipping notification', tag: 'NOTIFICATION_COORDINATOR');
      return;
    }

    final manifestoData = changedExtraInfoFields['manifesto'];
    if (manifestoData is! Map<String, dynamic>) {
      AppLogger.database('Invalid manifesto data format, skipping notification', tag: 'NOTIFICATION_COORDINATOR');
      return;
    }

    // Determine update type and details
    String updateType = 'update';
    String manifestoTitle = manifestoData['title'] ?? 'Manifesto';
    String? manifestoDescription;

    // Get description from promises if available
    final promises = manifestoData['promises'];
    if (promises is List && promises.isNotEmpty) {
      manifestoDescription = '${promises.length} key promises';
    }

    await sendManifestoUpdateNotification(
      candidateId: candidateId,
      updateType: updateType,
      manifestoTitle: manifestoTitle,
      manifestoDescription: manifestoDescription,
    );
  }

  /// Check milestones for tab save
  Future<void> _checkMilestonesForTab(
    String candidateId,
    Candidate candidate,
    Map<String, dynamic> changedExtraInfoFields,
  ) async {
    final profileData = {
      'name': candidate.name,
      'party': candidate.party,
      'photo': candidate.photo,
      'achievements': candidate.achievements?.map((a) => a.toJson()).toList(),
      'basic_info': candidate.basicInfo?.toJson(),
      'manifesto_data': candidate.manifestoData?.toJson(),
      'contact': candidate.contact?.toJson(),
      'events': candidate.events?.map((e) => e.toJson()).toList(),
      'highlights': candidate.highlights?.map((h) => h.toJson()).toList(),
      'media': candidate.media?.map((m) => m.toJson()).toList(),
      'analytics': candidate.analytics?.toJson(),
    };

    Map<String, dynamic>? manifestoData;
    if (changedExtraInfoFields.containsKey('manifesto')) {
      manifestoData = changedExtraInfoFields['manifesto'];
    }

    await checkCampaignMilestones(
      candidateId: candidateId,
      profileData: profileData,
      manifestoData: manifestoData,
    );
  }
}