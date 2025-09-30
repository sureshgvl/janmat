import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../features/candidate/repositories/candidate_repository.dart';
import '../event_notification_service.dart';

class CandidateFollowingNotifications {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final CandidateRepository _candidateRepository = CandidateRepository();
  final EventNotificationService _eventNotificationService = EventNotificationService();

  // Notify candidate when they gain a new follower
  Future<void> sendNewFollowerNotification({
    required String candidateId,
    required String followerId,
    String? candidateName,
    String? candidateUserId,
  }) async {
    try {
      // Get follower details
      final followerData = await _candidateRepository.getUserData(followerId);
      final followerName = followerData?['name'] ?? 'Someone';

      // Use provided candidate info or try to get it
      String? finalCandidateName = candidateName;
      String? finalCandidateUserId = candidateUserId;

      if (finalCandidateUserId == null) {
        // Try to get candidate data with fallback method
        final candidateData = await _getCandidateDataWithFallback(candidateId);
        if (candidateData != null) {
          finalCandidateName = candidateData['name'] as String?;
          finalCandidateUserId = candidateData['userId'] as String?;
        }
      }

      if (finalCandidateUserId == null) {
        debugPrint('⚠️ No candidate userId available for notification: $candidateId');
        return;
      }

      // Get candidate's FCM token
      final candidateToken = await _getUserFCMToken(finalCandidateUserId);
      if (candidateToken == null) {
        debugPrint('⚠️ No FCM token found for candidate: $finalCandidateUserId');
        return;
      }

      // Get current follower count
      final followerCount = await _getCandidateFollowerCount(candidateId);

      // Create notification message
      final displayName = finalCandidateName ?? 'Candidate';
      final title = 'New Follower!';
      final body = '$followerName started following you. You now have ${followerCount + 1} followers!';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'new_follower',
        'candidateId': candidateId,
        'followerId': followerId,
        'followerName': followerName,
        'followerCount': followerCount + 1,
      });

      // Store notification in database
      await _storeNotification(finalCandidateUserId, title, body, {
        'type': 'new_follower',
        'candidateId': candidateId,
        'followerId': followerId,
        'followerName': followerName,
        'followerCount': followerCount + 1,
      });

      // Check for follower milestones
      await _checkAndSendFollowerMilestoneNotification(candidateId, followerCount + 1);
    } catch (e) {
      debugPrint('Error sending new follower notification: $e');
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
        'followerCount': followerCount,
        'milestone': followerCount,
      });

      // Store notification in database
      await _storeNotification(candidateUserId, title, body, {
        'type': 'follower_milestone',
        'candidateId': candidateId,
        'followerCount': followerCount,
        'milestone': followerCount,
      });
    } catch (e) {
      debugPrint('Error sending follower milestone notification: $e');
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
        'followerCount': followerCount,
      });

      // Store notification in database
      await _storeNotification(candidateUserId, title, body, {
        'type': 'unfollow',
        'candidateId': candidateId,
        'unfollowerId': unfollowerId,
        'unfollowerName': unfollowerName,
        'followerCount': followerCount,
      });
    } catch (e) {
      debugPrint('Error sending unfollow notification: $e');
    }
  }

  // Notify followers about candidate profile updates
  Future<void> sendProfileUpdateNotification({
    required String candidateId,
    required String updateType, // 'photo', 'bio', 'contact', 'manifesto', etc.
    required String updateDescription,
  }) async {
    try {
      // Get candidate details with fallback
      final candidateData = await _getCandidateDataWithFallback(candidateId);
      if (candidateData == null) return;

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
      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      final title = 'Profile Update';
      final body = '$candidateName updated their $updateType: $updateDescription';

      // Send push notifications to all followers
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, {
          'type': 'profile_update',
          'candidateId': candidateId,
          'candidateName': candidateName,
          'updateType': updateType,
          'updateDescription': updateDescription,
        });
      }

      // Store notifications in database for each follower
      for (final follower in followers) {
        if (follower['notificationsEnabled'] == true) {
          await _storeNotification(follower['userId'], title, body, {
            'type': 'profile_update',
            'candidateId': candidateId,
            'candidateName': candidateName,
            'updateType': updateType,
            'updateDescription': updateDescription,
          });
        }
      }
    } catch (e) {
      debugPrint('Error sending profile update notification: $e');
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
      final title = 'New Post from ${candidate.name}';
      final body = postTitle;

      // Send push notifications to all followers
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, {
          'type': 'new_post',
          'candidateId': candidateId,
          'candidateName': candidate.name,
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
            'candidateName': candidate.name,
            'postId': postId,
            'postTitle': postTitle,
            'postType': postType,
          });
        }
      }
    } catch (e) {
      debugPrint('Error sending new post notification: $e');
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
      debugPrint('Error sending profile view spike notification: $e');
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
      debugPrint('Error sending weekly performance notification: $e');
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
          'name': candidate.name,
          'userId': candidate.userId,
          'followersCount': candidate.followersCount,
        };
      }

      // Fallback: Search manually across all locations
      debugPrint('🔄 Using fallback method to find candidate: $candidateId');
      return await _findCandidateManually(candidateId);
    } catch (e) {
      debugPrint('Error getting candidate data with fallback: $e');
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

      debugPrint('❌ Candidate not found in any location: $candidateId');
      return null;
    } catch (e) {
      debugPrint('Error in manual candidate search: $e');
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
      debugPrint('Error getting follower count: $e');
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
      debugPrint('⚠️ Cannot determine follower count without candidate location');
      return 0;
    } catch (e) {
      debugPrint('Error getting follower count from collection: $e');
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
      debugPrint('Error getting followers: $e');
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
      debugPrint('Error getting notification preferences: $e');
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
      debugPrint('Error getting performance metrics: $e');
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
      debugPrint('Error getting FCM token: $e');
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
      debugPrint('🚀 Sending push notification:');
      debugPrint('Token: $token');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');

      // Call Firebase Cloud Function to send push notification
      try {
        final callable = _functions.httpsCallable('sendPushNotification');
        final result = await callable.call({
          'token': token,
          'title': title,
          'body': body,
          'notificationData': data,
        });

        debugPrint('✅ Push notification sent successfully: ${result.data}');
      } catch (functionError) {
        debugPrint('❌ Firebase Function error: $functionError');

        // Fallback: Try HTTP request to Firebase Functions URL
        // Uncomment and configure if you prefer direct HTTP calls
        /*
        final response = await http.post(
          Uri.parse('YOUR_FIREBASE_FUNCTIONS_URL/sendPushNotification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'token': token,
            'title': title,
            'body': body,
            'notificationData': data,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Push notification sent via HTTP');
        } else {
          debugPrint('❌ HTTP push notification failed: ${response.statusCode}');
        }
        */
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
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
      await _firestore
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
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }
}