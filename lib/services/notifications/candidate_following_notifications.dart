import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import '../../features/candidate/repositories/candidate_repository.dart';
import '../event_notification_service.dart';

class CandidateFollowingNotifications {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final CandidateRepository _candidateRepository = CandidateRepository();

  // Notify candidate when they gain a new follower
  Future<void> sendNewFollowerNotification({
    required String candidateId,
    required String followerId,
    String? candidateName,
    String? candidateUserId,
    String? followerName,  // OPTIMIZED: Pass follower name to avoid fetch
    int? followerCount,    // OPTIMIZED: Pass follower count to avoid fetch
    String? fcmToken,      // OPTIMIZED: Pass FCM token from candidate model
  }) async {
    final startTime = DateTime.now();
    AppLogger.notifications('🚀 [FollowerNotification] Starting new follower notification process...');

    try {
      // OPTIMIZED: Use passed follower name or default
      final finalFollowerName = followerName ?? 'Someone';

      // Use provided candidate info
      final finalCandidateName = candidateName;
      final finalCandidateUserId = candidateUserId;

      if (finalCandidateUserId == null) {
        AppLogger.notifications('❌ [FollowerNotification] No candidate userId available for notification: $candidateId');
        return;
      }

      // OPTIMIZED: Use passed FCM token or fallback to fetch
      final candidateToken = fcmToken ?? await _getUserFCMToken(finalCandidateUserId);
      if (candidateToken == null) {
        AppLogger.notifications('❌ [FollowerNotification] No FCM token found for candidate: $finalCandidateUserId');
        return;
      }

      // OPTIMIZED: Use passed follower count or candidate data
      final currentFollowerCount = followerCount ?? 0;

      // Create notification message
      final title = 'New Follower!';
      final body = '$finalFollowerName started following you. You now have ${currentFollowerCount + 1} followers!';

      final notificationData = {
        'type': 'new_follower',
        'candidateId': candidateId,
        'followerId': followerId,
        'followerName': finalFollowerName,
        'followerCount': (currentFollowerCount + 1).toString(),
      };

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, notificationData);

      // Store notification in database
      await _storeNotification(finalCandidateUserId, title, body, notificationData);

      // Check for follower milestones
      await _checkAndSendFollowerMilestoneNotification(candidateId, currentFollowerCount + 1);

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.notifications('🎉 [FollowerNotification] New follower notification completed successfully (${totalTime}ms)');
    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending new follower notification', error: e);
    }
  }

  // Notify candidate when follower count reaches milestones
  Future<void> _checkAndSendFollowerMilestoneNotification(
    String candidateId,
    int followerCount,
  ) async {
    final milestones = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000];
    if (!milestones.contains(followerCount)) return;

    try {
      // Get candidate details with fallback
      final candidateData = await _getCandidateDataWithFallback(candidateId);
      if (candidateData == null) return;

      // Get candidate's FCM token
      final candidateUserId = candidateData['userId'] as String?;
      if (candidateUserId == null) return;

      final candidateToken = await _getUserFCMToken(candidateUserId);
      if (candidateToken == null) return;

      // Create milestone message
      final title = '🎉 Follower Milestone!';
      final body = 'Congratulations! You now have $followerCount followers. Keep up the great work!';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'follower_milestone',
        'candidateId': candidateId,
        'followerCount': followerCount.toString(),
        'milestone': followerCount.toString(),
      });

      // Store notification in database
      await _storeNotification(candidateUserId, title, body, {
        'type': 'follower_milestone',
        'candidateId': candidateId,
        'followerCount': followerCount.toString(),
        'milestone': followerCount.toString(),
      });
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending follower milestone notification', error: e);
    }
  }

  // Notify candidate about unfollow (optional - candidates can opt-in)
  Future<void> sendUnfollowNotification({
    required String candidateId,
    required String unfollowerId,
  }) async {
    try {
      // Check if candidate has opted in for unfollow notifications
      final candidatePrefs = await _getCandidateNotificationPreferences(candidateId);
      if (!(candidatePrefs['unfollowAlerts'] ?? false)) return;

      // Get candidate details with fallback
      final candidateData = await _getCandidateDataWithFallback(candidateId);
      if (candidateData == null) return;

      // Get unfollower details
      final unfollowerData = await _candidateRepository.getUserData(unfollowerId);
      final unfollowerName = unfollowerData?['name'] ?? 'Someone';

      // Get candidate's FCM token
      final candidateUserId = candidateData['userId'] as String?;
      if (candidateUserId == null) return;

      final candidateToken = await _getUserFCMToken(candidateUserId);
      if (candidateToken == null) return;

      // Get current follower count
      final followerCount = await _getCandidateFollowerCount(candidateId);

      // Create notification message
      final title = 'Follower Update';
      final body = '$unfollowerName unfollowed you. You now have $followerCount followers.';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'unfollow',
        'candidateId': candidateId,
        'unfollowerId': unfollowerId,
        'unfollowerName': unfollowerName,
        'followerCount': followerCount.toString(),
      });

      // Store notification in database
      await _storeNotification(candidateUserId, title, body, {
        'type': 'unfollow',
        'candidateId': candidateId,
        'unfollowerId': unfollowerId,
        'unfollowerName': unfollowerName,
        'followerCount': followerCount.toString(),
      });
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending unfollow notification', error: e);
    }
  }


  // Notify followers about new candidate posts/content (future feature)
  Future<void> sendNewPostNotification({
    required String candidateId,
    required String postId,
    required String postTitle,
    required String postType, // 'announcement', 'update', 'event', etc.
  }) async {
    try {
      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(candidateId);
      if (candidate == null) return;

      // Get all followers
      final followers = await _getCandidateFollowers(candidateId);
      if (followers.isEmpty) return;

      // Get candidate's FCM tokens for followers who have notifications enabled
      final tokens = <String>[];
      for (final follower in followers) {
        if (follower['notificationsEnabled'] == true) {
          final token = await _getUserFCMToken(follower['userId']);
          if (token != null) {
            tokens.add(token);
          }
        }
      }

      if (tokens.isEmpty) return;

      // Create notification message
      final title = 'New Post from ${candidate.basicInfo!.fullName}';
      final body = postTitle;

      // Send push notifications to all followers
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, {
          'type': 'new_post',
          'candidateId': candidateId,
          'candidateName': candidate.basicInfo!.fullName,
          'postId': postId,
          'postTitle': postTitle,
          'postType': postType,
        });
      }

      // Store notifications in database for each follower
      for (final follower in followers) {
        if (follower['notificationsEnabled'] == true) {
          await _storeNotification(follower['userId'], title, body, {
            'type': 'new_post',
            'candidateId': candidateId,
            'candidateName': candidate.basicInfo!.fullName,
            'postId': postId,
            'postTitle': postTitle,
            'postType': postType,
          });
        }
      }
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending new post notification', error: e);
    }
  }

  // Notify candidate about profile view spikes
  Future<void> sendProfileViewSpikeNotification({
    required String candidateId,
    required int viewCount,
    required int previousCount,
  }) async {
    try {
      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(candidateId);
      if (candidate == null) return;

      // Get candidate's FCM token
      final candidateToken = await _getUserFCMToken(candidate.userId!);
      if (candidateToken == null) return;

      // Calculate increase
      final increase = viewCount - previousCount;
      final percentage = previousCount > 0 ? ((increase / previousCount) * 100).round() : 100;

      // Create notification message
      final title = '📈 Profile Views Spike!';
      final body = 'Your profile views increased by $increase ($percentage%) in the last hour. Total views: $viewCount';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'profile_view_spike',
        'candidateId': candidateId,
        'viewCount': viewCount,
        'previousCount': previousCount,
        'increase': increase,
        'percentage': percentage,
      });

      // Store notification in database
      await _storeNotification(candidate.userId!, title, body, {
        'type': 'profile_view_spike',
        'candidateId': candidateId,
        'viewCount': viewCount,
        'previousCount': previousCount,
        'increase': increase,
        'percentage': percentage,
      });
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending profile view spike notification', error: e);
    }
  }

  // Send weekly content performance summary to candidates
  Future<void> sendWeeklyContentPerformanceNotification(String candidateId) async {
    try {
      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(candidateId);
      if (candidate == null) return;

      // Get candidate's FCM token
      final candidateToken = await _getUserFCMToken(candidate.userId!);
      if (candidateToken == null) return;

      // Get performance metrics (this would need to be implemented based on actual tracking)
      final metrics = await _getWeeklyPerformanceMetrics(candidateId);

      // Create notification message
      final title = '📊 Weekly Performance Summary';
      final body = 'Views: ${metrics['views']}, Engagement: ${metrics['engagement']}%, Followers: ${metrics['newFollowers']}';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'weekly_performance',
        'candidateId': candidateId,
        'metrics': metrics,
      });

      // Store notification in database
      await _storeNotification(candidate.userId!, title, body, {
        'type': 'weekly_performance',
        'candidateId': candidateId,
        'metrics': metrics,
      });
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error sending weekly performance notification', error: e);
    }
  }

  // Helper method to get candidate data with fallback
  Future<Map<String, dynamic>?> _getCandidateDataWithFallback(String candidateId) async {
    try {
      // First try the standard method
      final candidate = await _candidateRepository.getCandidateDataById(candidateId);
      if (candidate != null) {
        return {
          'candidateId': candidate.candidateId,
          'name': candidate.basicInfo!.fullName,
          'userId': candidate.userId,
          'followersCount': candidate.followersCount,
        };
      }

      // Fallback: Search manually across all locations
      AppLogger.notifications('🔄 Using fallback method to find candidate: $candidateId');
      return await _findCandidateManually(candidateId);
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting candidate data with fallback', error: e);
      return null;
    }
  }

  // Manual search for candidate across all locations
  Future<Map<String, dynamic>?> _findCandidateManually(String candidateId) async {
    try {
      final statesSnapshot = await _firestore.collection('states').get();

      for (var stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (var districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (var bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (var wardDoc in wardsSnapshot.docs) {
              final candidateDoc = await wardDoc.reference
                  .collection('candidates')
                  .doc(candidateId)
                  .get();

              if (candidateDoc.exists) {
                final data = candidateDoc.data()!;
                return {
                  'candidateId': candidateDoc.id,
                  'name': data['name'] ?? 'Unknown',
                  'userId': data['userId'],
                  'followersCount': data['followersCount'] ?? 0,
                };
              }
            }
          }
        }
      }

      AppLogger.notifications('❌ Candidate not found in any location: $candidateId');
      return null;
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error in manual candidate search', error: e);
      return null;
    }
  }

  // Helper method to get candidate follower count
  Future<int> _getCandidateFollowerCount(String candidateId) async {
    try {
      // Try to get from candidate data first
      final candidateData = await _getCandidateDataWithFallback(candidateId);
      if (candidateData != null) {
        return candidateData['followersCount'] ?? 0;
      }

      // Fallback: Query followers collection directly
      return await _getFollowerCountFromCollection(candidateId);
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting follower count', error: e);
      return 0;
    }
  }

  // Get follower count by querying followers collection directly
  Future<int> _getFollowerCountFromCollection(String candidateId) async {
    try {
      // Try to find candidate location first
      final candidateData = await _findCandidateManually(candidateId);
      if (candidateData == null) return 0;

      // This is a simplified approach - in reality you'd need to find the candidate location
      // For now, return 0 as we can't easily query across all possible locations
      AppLogger.notifications('⚠️ Cannot determine follower count without candidate location for candidate: $candidateId');
      return 0;
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting follower count from collection', error: e);
      return 0;
    }
  }

  // Helper method to get candidate followers
  Future<List<Map<String, dynamic>>> _getCandidateFollowers(String candidateId) async {
    try {
      // This would need to be implemented based on the following system
      // For now, return empty list
      return [];
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting followers', error: e);
      return [];
    }
  }

  // Helper method to get candidate notification preferences
  Future<Map<String, bool>> _getCandidateNotificationPreferences(String candidateId) async {
    try {
      // Default preferences
      return {
        'newFollowers': true,
        'followerMilestones': true,
        'unfollowAlerts': false, // Opt-in
        'profileUpdates': true,
        'newPosts': true,
        'performanceReports': true,
      };
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting notification preferences', error: e);
      return {};
    }
  }

  // Helper method to get weekly performance metrics
  Future<Map<String, dynamic>> _getWeeklyPerformanceMetrics(String candidateId) async {
    try {
      // Placeholder metrics - would need actual implementation
      return {
        'views': 0,
        'engagement': 0,
        'newFollowers': 0,
        'posts': 0,
        'interactions': 0,
      };
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting performance metrics', error: e);
      return {};
    }
  }

  // Helper method to get user's FCM token
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      AppLogger.notificationsError('❌ [FollowerNotification] Error getting FCM token', error: e);
      return null;
    }
  }

  // Helper method to send push notification
  Future<void> _sendPushNotification(
    String token,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Call Firebase Cloud Function to send push notification
      try {
        final callable = _functions.httpsCallable('sendPushNotification');

        final result = await callable.call({
          'token': token,
          'title': title,
          'body': body,
          'notificationData': data,
        });

        AppLogger.notifications('✅ Push notification sent successfully via Firebase Function');
      } catch (functionError) {
        if (functionError is FirebaseFunctionsException) {
          AppLogger.notificationsError(
            '❌ Firebase Function push notification failed',
            error: 'Code: ${functionError.code}, Message: ${functionError.message}'
          );
        } else {
          AppLogger.notificationsError('❌ Firebase Function push notification failed', error: functionError);
        }

        // Note: Direct FCM fallback removed - now only using Firebase Functions
        AppLogger.notifications('⚠️ Firebase Function failed - no fallback available');
      }
    } catch (e) {
      AppLogger.notificationsError('❌ Error sending push notification', error: e);
      // Don't throw - allow the app to continue even if push notifications fail
    }
  }


  // Helper method to store notification in database
  Future<void> _storeNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'data': data,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      AppLogger.notifications('✅ Notification stored successfully in database for user: $userId');
    } catch (e) {
      AppLogger.notificationsError('❌ [StoreNotification] Error storing notification', error: e);
    }
  }
}
