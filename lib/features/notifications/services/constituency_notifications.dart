import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../utils/app_logger.dart';

/// Service for sending notifications to users in the same constituency
/// Follows Single Responsibility Principle - handles only constituency-based notifications
class ConstituencyNotifications {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Notify followers and constituency voters when candidate updates manifesto
  Future<void> sendManifestoUpdateNotification({
    required String candidateId,
    required String updateType, // 'new', 'update', 'delete'
    required String manifestoTitle,
    String? manifestoDescription,
  }) async {
    try {
      AppLogger.notifications('📜 [ManifestoUpdate] Starting manifesto update notification...');
      AppLogger.notifications('   - Candidate ID: $candidateId');
      AppLogger.notifications('   - Update type: $updateType');
      AppLogger.notifications('   - Manifesto title: $manifestoTitle');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        AppLogger.notifications('❌ [ManifestoUpdate] Candidate data not found');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      AppLogger.notifications('   - Candidate name: $candidateName');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        AppLogger.notifications('❌ [ManifestoUpdate] Could not determine candidate location');
        return;
      }

      AppLogger.notifications('📍 [ManifestoUpdate] Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      AppLogger.notifications('👥 [ManifestoUpdate] Found ${constituencyUsers.length} users in constituency');

      if (constituencyUsers.isEmpty) return;

      // Get candidate followers (primary audience)
      final followers = await _getCandidateFollowers(candidateId);
      AppLogger.notifications('👥 [ManifestoUpdate] Found ${followers.length} direct followers');

      // Combine followers and constituency users, removing duplicates
      final allTargetUsers = <Map<String, dynamic>>[];
      final userIds = <String>{};

      // Add followers first (higher priority)
      for (final follower in followers) {
        if (!userIds.contains(follower['userId'])) {
          allTargetUsers.add(follower);
          userIds.add(follower['userId']);
        }
      }

      // Add constituency users (secondary audience)
      for (final user in constituencyUsers) {
        if (!userIds.contains(user['userId'])) {
          allTargetUsers.add(user);
          userIds.add(user['userId']);
        }
      }

      AppLogger.notifications('👥 [ManifestoUpdate] Total target users: ${allTargetUsers.length}');

      if (allTargetUsers.isEmpty) return;

      // Filter users who have manifesto update notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in allTargetUsers) {
        // Skip if this is the candidate updating their own manifesto
        if (user['userId'] == candidateData['userId']) {
          AppLogger.notifications('⏭️ [ManifestoUpdate] Skipping candidate themselves: ${user['userId']}');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['manifestoUpdates'] == true) {
          eligibleUsers.add(user);
        }
      }

      AppLogger.notifications('✅ [ManifestoUpdate] ${eligibleUsers.length} users have manifesto update notifications enabled');

      if (eligibleUsers.isEmpty) return;

      // Get FCM tokens for eligible users
      final tokens = <String>[];
      final validUsers = <Map<String, dynamic>>[];

      for (final user in eligibleUsers) {
        final token = await _getUserFCMToken(user['userId']);
        if (token != null) {
          tokens.add(token);
          validUsers.add(user);
        }
      }

      AppLogger.notifications('📱 [ManifestoUpdate] ${tokens.length} valid FCM tokens found');

      if (tokens.isEmpty) return;

      // Create notification message based on update type
      String title;
      String body;

      switch (updateType) {
        case 'new':
          title = 'New Manifesto Added!';
          body = '$candidateName has published a new manifesto: "$manifestoTitle"';
          break;
        case 'update':
          title = 'Manifesto Updated';
          body = '$candidateName has updated their manifesto: "$manifestoTitle"';
          break;
        case 'delete':
          title = 'Manifesto Removed';
          body = '$candidateName has removed their manifesto: "$manifestoTitle"';
          break;
        default:
          title = 'Manifesto Update';
          body = '$candidateName has updated their manifesto: "$manifestoTitle"';
      }

      final notificationData = {
        'type': 'manifesto_update',
        'candidateId': candidateId,
        'candidateName': candidateName,
        'updateType': updateType,
        'manifestoTitle': manifestoTitle,
        'manifestoDescription': manifestoDescription,
        'stateId': candidateLocation['stateId'] ?? '',
        'districtId': candidateLocation['districtId'] ?? '',
        'bodyId': candidateLocation['bodyId'] ?? '',
        'wardId': candidateLocation['wardId'] ?? '',
      };

      // Send push notifications to eligible users
      AppLogger.notifications('📤 [ManifestoUpdate] Sending notifications to ${tokens.length} users...');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user
      AppLogger.notifications('💾 [ManifestoUpdate] Storing notifications in database...');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      AppLogger.notifications('🎉 [ManifestoUpdate] Manifesto update notifications sent successfully to ${validUsers.length} users');
    } catch (e) {
      AppLogger.common('❌ [ManifestoUpdate] Error sending manifesto update notification: $e', tag: 'NOTIFICATION_ERROR');
    }
  }

  /// Notify followers and constituency voters when candidate shares manifesto
  Future<void> sendManifestoSharedNotification({
    required String candidateId,
    required String manifestoTitle,
    String? shareMessage,
    String? sharePlatform, // 'whatsapp', 'facebook', 'twitter', etc.
  }) async {
    try {
      AppLogger.notifications('Starting manifesto sharing notification...', tag: 'MANIFESTO_SHARED');
      AppLogger.notifications('   - Candidate ID: $candidateId', tag: 'MANIFESTO_SHARED');
      AppLogger.notifications('   - Manifesto title: $manifestoTitle', tag: 'MANIFESTO_SHARED');
      AppLogger.notifications('   - Share platform: $sharePlatform', tag: 'MANIFESTO_SHARED');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        AppLogger.notifications('Candidate data not found', tag: 'MANIFESTO_SHARED');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      AppLogger.notifications('   - Candidate name: $candidateName', tag: 'MANIFESTO_SHARED');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        AppLogger.notifications('Could not determine candidate location', tag: 'MANIFESTO_SHARED');
        return;
      }

      AppLogger.notifications('Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}', tag: 'MANIFESTO_SHARED');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      AppLogger.notifications('Found ${constituencyUsers.length} users in constituency', tag: 'MANIFESTO_SHARED');

      if (constituencyUsers.isEmpty) return;

      // Get candidate followers (primary audience)
      final followers = await _getCandidateFollowers(candidateId);
      AppLogger.notifications('Found ${followers.length} direct followers', tag: 'MANIFESTO_SHARED');

      // Combine followers and constituency users, removing duplicates
      final allTargetUsers = <Map<String, dynamic>>[];
      final userIds = <String>{};

      // Add followers first (higher priority)
      for (final follower in followers) {
        if (!userIds.contains(follower['userId'])) {
          allTargetUsers.add(follower);
          userIds.add(follower['userId']);
        }
      }

      // Add constituency users (secondary audience)
      for (final user in constituencyUsers) {
        if (!userIds.contains(user['userId'])) {
          allTargetUsers.add(user);
          userIds.add(user['userId']);
        }
      }

      AppLogger.notifications('Total target users: ${allTargetUsers.length}', tag: 'MANIFESTO_SHARED');

      if (allTargetUsers.isEmpty) return;

      // Filter users who have content sharing notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in allTargetUsers) {
        // Skip if this is the candidate sharing their own manifesto
        if (user['userId'] == candidateData['userId']) {
          AppLogger.notifications('Skipping candidate themselves: ${user['userId']}', tag: 'MANIFESTO_SHARED');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['contentSharing'] == true) {
          eligibleUsers.add(user);
        }
      }

      AppLogger.notifications('${eligibleUsers.length} users have content sharing notifications enabled', tag: 'MANIFESTO_SHARED');

      if (eligibleUsers.isEmpty) return;

      // Get FCM tokens for eligible users
      final tokens = <String>[];
      final validUsers = <Map<String, dynamic>>[];

      for (final user in eligibleUsers) {
        final token = await _getUserFCMToken(user['userId']);
        if (token != null) {
          tokens.add(token);
          validUsers.add(user);
        }
      }

      AppLogger.notifications('${tokens.length} valid FCM tokens found', tag: 'MANIFESTO_SHARED');

      if (tokens.isEmpty) return;

      // Create notification message
      String title = '📤 Manifesto Shared!';
      String body;

      if (shareMessage != null && shareMessage.isNotEmpty) {
        body = '$candidateName shared their manifesto: "$shareMessage"';
      } else {
        body = '$candidateName shared their manifesto "$manifestoTitle" with their network';
      }

      final notificationData = {
        'type': 'manifesto_shared',
        'candidateId': candidateId,
        'candidateName': candidateName,
        'manifestoTitle': manifestoTitle,
        'shareMessage': shareMessage,
        'sharePlatform': sharePlatform,
        'stateId': candidateLocation['stateId'] ?? '',
        'districtId': candidateLocation['districtId'] ?? '',
        'bodyId': candidateLocation['bodyId'] ?? '',
        'wardId': candidateLocation['wardId'] ?? '',
      };

      // Send push notifications to eligible users
      AppLogger.notifications('Sending notifications to ${tokens.length} users...', tag: 'MANIFESTO_SHARED');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user
      AppLogger.notifications('Storing notifications in database...', tag: 'MANIFESTO_SHARED');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      AppLogger.notifications('Manifesto sharing notifications sent successfully to ${validUsers.length} users', tag: 'MANIFESTO_SHARED');
    } catch (e) {
      AppLogger.common('Error sending manifesto sharing notification: $e', tag: 'MANIFESTO_SHARED_ERROR');
    }
  }

  /// Notify voters in constituency when a new candidate creates their profile
  Future<void> sendCandidateProfileCreatedNotification({
    required String candidateId,
  }) async {
    try {
      AppLogger.notifications('Starting candidate profile created notification...', tag: 'CANDIDATE_PROFILE_CREATED');
      AppLogger.notifications('   - Candidate ID: $candidateId', tag: 'CANDIDATE_PROFILE_CREATED');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        AppLogger.notifications('Candidate data not found', tag: 'CANDIDATE_PROFILE_CREATED');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'New Candidate';
      AppLogger.notifications('   - Candidate name: $candidateName', tag: 'CANDIDATE_PROFILE_CREATED');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        AppLogger.notifications('Could not determine candidate location', tag: 'CANDIDATE_PROFILE_CREATED');
        return;
      }

      AppLogger.notifications('Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}', tag: 'CANDIDATE_PROFILE_CREATED');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      AppLogger.notifications('Found ${constituencyUsers.length} users in constituency', tag: 'CANDIDATE_PROFILE_CREATED');

      if (constituencyUsers.isEmpty) return;

      // Filter users who have new candidate notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in constituencyUsers) {
        // Skip if this is the candidate creating their own profile
        if (user['userId'] == candidateData['userId']) {
          AppLogger.notifications('Skipping candidate themselves: ${user['userId']}', tag: 'CANDIDATE_PROFILE_CREATED');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['newCandidates'] == true) {
          eligibleUsers.add(user);
        }
      }

      AppLogger.notifications('${eligibleUsers.length} users have new candidate notifications enabled', tag: 'CANDIDATE_PROFILE_CREATED');

      if (eligibleUsers.isEmpty) return;

      // Get FCM tokens for eligible users
      final tokens = <String>[];
      final validUsers = <Map<String, dynamic>>[];

      for (final user in eligibleUsers) {
        final token = await _getUserFCMToken(user['userId']);
        if (token != null) {
          tokens.add(token);
          validUsers.add(user);
        }
      }

      AppLogger.notifications('${tokens.length} valid FCM tokens found', tag: 'CANDIDATE_PROFILE_CREATED');

      if (tokens.isEmpty) return;

      // Create notification message
      final title = 'New Candidate in Your Area!';
      final body = '$candidateName has joined the election in your constituency. Learn about their vision and policies!';

      final notificationData = {
        'type': 'candidate_profile_created',
        'candidateId': candidateId,
        'candidateName': candidateName,
        'stateId': candidateLocation['stateId'] ?? '',
        'districtId': candidateLocation['districtId'] ?? '',
        'bodyId': candidateLocation['bodyId'] ?? '',
        'wardId': candidateLocation['wardId'] ?? '',
      };

      // Send push notifications to constituency users
      AppLogger.notifications('Sending notifications to ${tokens.length} users...', tag: 'CANDIDATE_PROFILE_CREATED');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user (include full constituency data for local storage)
      AppLogger.notifications('Storing notifications in database...', tag: 'CANDIDATE_PROFILE_CREATED');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      AppLogger.notifications('New candidate notifications sent successfully to ${validUsers.length} constituency users', tag: 'CANDIDATE_PROFILE_CREATED');
    } catch (e) {
      AppLogger.common('Error sending candidate profile created notification: $e', tag: 'CANDIDATE_PROFILE_CREATED_ERROR');
    }
  }

  /// Notify voters and candidates in same constituency about candidate profile updates
  Future<void> sendProfileUpdateNotification({
    required String candidateId,
    required String updateType, // 'photo', 'bio', 'contact', 'manifesto', etc.
    required String updateDescription,
  }) async {
    try {
      AppLogger.notifications('Starting constituency-aware profile update notification...', tag: 'PROFILE_UPDATE');
      AppLogger.notifications('   - Candidate ID: $candidateId', tag: 'PROFILE_UPDATE');
      AppLogger.notifications('   - Update type: $updateType', tag: 'PROFILE_UPDATE');
      AppLogger.notifications('   - Update description: $updateDescription', tag: 'PROFILE_UPDATE');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        AppLogger.notifications('Candidate data not found', tag: 'PROFILE_UPDATE');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      AppLogger.notifications('   - Candidate name: $candidateName', tag: 'PROFILE_UPDATE');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        AppLogger.notifications('Could not determine candidate location', tag: 'PROFILE_UPDATE');
        return;
      }

      AppLogger.notifications('Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}', tag: 'PROFILE_UPDATE');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      AppLogger.notifications('Found ${constituencyUsers.length} users in constituency', tag: 'PROFILE_UPDATE');

      if (constituencyUsers.isEmpty) return;

      // Filter users who have profile update notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in constituencyUsers) {
        // Skip if this is the candidate updating their own profile
        if (user['userId'] == candidateData['userId']) {
          AppLogger.notifications('Skipping candidate themselves: ${user['userId']}', tag: 'PROFILE_UPDATE');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['profileUpdates'] == true) {
          eligibleUsers.add(user);
        }
      }

      AppLogger.notifications('${eligibleUsers.length} users have profile update notifications enabled', tag: 'PROFILE_UPDATE');

      if (eligibleUsers.isEmpty) return;

      // Get FCM tokens for eligible users
      final tokens = <String>[];
      final validUsers = <Map<String, dynamic>>[];

      for (final user in eligibleUsers) {
        final token = await _getUserFCMToken(user['userId']);
        if (token != null) {
          tokens.add(token);
          validUsers.add(user);
        }
      }

      AppLogger.notifications('${tokens.length} valid FCM tokens found', tag: 'PROFILE_UPDATE');

      if (tokens.isEmpty) return;

      // Create notification message
      final title = 'Profile Update';
      final body = '$candidateName updated their $updateType: $updateDescription';

      final notificationData = {
        'type': 'profile_update',
        'candidateId': candidateId,
        'candidateName': candidateName,
        'updateType': updateType,
        'updateDescription': updateDescription,
        'stateId': candidateLocation['stateId'] ?? '',
        'districtId': candidateLocation['districtId'] ?? '',
        'bodyId': candidateLocation['bodyId'] ?? '',
        'wardId': candidateLocation['wardId'] ?? '',
      };

      // Send push notifications to constituency users
      AppLogger.notifications('Sending notifications to ${tokens.length} users...', tag: 'PROFILE_UPDATE');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user (include full constituency data for local storage)
      AppLogger.notifications('Storing notifications in database...', tag: 'PROFILE_UPDATE');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      AppLogger.notifications('Profile update notifications sent successfully to ${validUsers.length} constituency users', tag: 'PROFILE_UPDATE');
    } catch (e) {
      AppLogger.common('Error sending profile update notification: $e', tag: 'PROFILE_UPDATE_ERROR');
    }
  }

  /// Get candidate data by ID
  Future<Map<String, dynamic>?> _getCandidateData(String candidateId) async {
    try {
      // Search manually across all locations to find candidate
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

      AppLogger.common('Candidate not found in any location: $candidateId', tag: 'CANDIDATE_NOT_FOUND');
      return null;
    } catch (e) {
      AppLogger.common('Error getting candidate data: $e', tag: 'CANDIDATE_DATA_ERROR');
      return null;
    }
  }

  /// Find candidate's location in the hierarchy
  Future<Map<String, String>?> _findCandidateLocation(String candidateId) async {
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
                return {
                  'stateId': stateDoc.id,
                  'districtId': districtDoc.id,
                  'bodyId': bodyDoc.id,
                  'wardId': wardDoc.id,
                };
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.common('Error finding candidate location: $e', tag: 'LOCATION_ERROR');
      return null;
    }
  }

  /// Get all users (voters and candidates) in the same constituency
  Future<List<Map<String, dynamic>>> _getConstituencyUsers(
    String stateId,
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    try {
      final users = <Map<String, dynamic>>[];
      AppLogger.common('Finding users in constituency: $stateId/$districtId/$bodyId/$wardId', tag: 'CONSTITUENCY_USERS');

      // Query users collection for voters - filter by basic location fields first
      AppLogger.common('Querying users collection for voters...', tag: 'CONSTITUENCY_USERS');
      final votersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'voter')
          .where('stateId', isEqualTo: stateId)
          .where('districtId', isEqualTo: districtId)
          .get();

      AppLogger.common('Found ${votersQuery.docs.length} potential voters, filtering by electionAreas...', tag: 'CONSTITUENCY_USERS');

      // Filter voters by their electionAreas to find those in the specific constituency
      for (var voterDoc in votersQuery.docs) {
        final voterData = voterDoc.data();

        // Check if this voter has electionAreas and if any match the constituency
        final electionAreas = voterData['electionAreas'] as List<dynamic>?;
        if (electionAreas != null && electionAreas.isNotEmpty) {
          bool isInConstituency = false;

          for (final area in electionAreas) {
            if (area is Map && area['bodyId'] == bodyId && area['wardId'] == wardId) {
              isInConstituency = true;
              break;
            }
          }

          if (isInConstituency) {
            users.add({
              'userId': voterDoc.id,
              'type': 'voter',
              'name': voterData['name'] ?? 'Voter',
            });
            AppLogger.common('Added voter: ${voterDoc.id} (${voterData['name'] ?? 'Voter'})', tag: 'CONSTITUENCY_USERS');
          }
        }
      }

      AppLogger.common('After filtering: ${users.where((u) => u['type'] == 'voter').length} voters in constituency', tag: 'CONSTITUENCY_USERS');

      // Also get candidates directly from the candidates subcollection
      final candidatesSnapshot = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .get();

      AppLogger.common('Found ${candidatesSnapshot.docs.length} candidates in subcollection', tag: 'CONSTITUENCY_USERS');
      for (var candidateDoc in candidatesSnapshot.docs) {
        final candidateData = candidateDoc.data();
        if (candidateData['userId'] != null) {
          // Check if already added to avoid duplicates
          final existingIndex = users.indexWhere((u) => u['userId'] == candidateData['userId']);
          if (existingIndex == -1) {
            users.add({
              'userId': candidateData['userId'],
              'type': 'candidate',
              'name': candidateData['name'] ?? 'Candidate',
            });
            AppLogger.common('Added candidate: ${candidateData['userId']} (${candidateData['name'] ?? 'Candidate'})', tag: 'CONSTITUENCY_USERS');
          } else {
            AppLogger.common('Skipped duplicate candidate: ${candidateData['userId']}', tag: 'CONSTITUENCY_USERS');
          }
        }
      }

      AppLogger.common('Total users found: ${users.length}', tag: 'CONSTITUENCY_USERS');
      for (final user in users) {
        AppLogger.common('- ${user['type']}: ${user['userId']} (${user['name']})', tag: 'CONSTITUENCY_USERS');
      }

      return users;
    } catch (e) {
      AppLogger.common('Error getting constituency users: $e', tag: 'CONSTITUENCY_USERS_ERROR');
      AppLogger.common('Error details: $e', tag: 'CONSTITUENCY_USERS_ERROR');
      return [];
    }
  }

  /// Get candidate's followers
  Future<List<Map<String, dynamic>>> _getCandidateFollowers(String candidateId) async {
    try {
      // Query users who follow this candidate
      // This would need to be implemented based on your following system
      // For now, return empty list - constituency users will still get notifications
      AppLogger.common('Getting followers for candidate: $candidateId', tag: 'FOLLOWERS');
      // TODO: Implement based on your following data structure
      return [];
    } catch (e) {
      AppLogger.common('Error getting candidate followers: $e', tag: 'FOLLOWERS_ERROR');
      return [];
    }
  }

  /// Get user's notification preferences
  Future<Map<String, bool>> _getUserNotificationPreferences(String userId) async {
    try {
      // For now, return default preferences
      // In a real implementation, this would fetch from user preferences
      return {
        'profileUpdates': true,
        'newCandidates': true,
        'manifestoUpdates': true,
        'contentSharing': true,
        'campaignMilestones': true,
        'newPolls': true,
        'eventReminders': true,
        'chatMessages': true,
        'achievements': true,
      };
    } catch (e) {
      AppLogger.common('Error getting user notification preferences: $e', tag: 'PREFERENCES_ERROR');
      return {};
    }
  }

  /// Get user's FCM token
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData?['fcmToken'] as String?;
      }
      return null;
    } catch (e) {
      AppLogger.common('Error getting FCM token: $e', tag: 'FCM_TOKEN_ERROR');
      return null;
    }
  }

  /// Send push notification
  Future<void> _sendPushNotification(
    String token,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.common('Sending constituency push notification...', tag: 'PUSH_NOTIFICATION');
      AppLogger.common('Token: $token', tag: 'PUSH_NOTIFICATION');
      AppLogger.common('Title: $title', tag: 'PUSH_NOTIFICATION');
      AppLogger.common('Body: $body', tag: 'PUSH_NOTIFICATION');
      AppLogger.common('Data: $data', tag: 'PUSH_NOTIFICATION');

      // Call Firebase Cloud Function to send push notification
      final callable = _functions.httpsCallable('sendPushNotification');
      await callable.call({
        'token': token,
        'title': title,
        'body': body,
        'notificationData': data,
      });

      AppLogger.common('Constituency push notification sent successfully', tag: 'PUSH_NOTIFICATION');
    } catch (e) {
      AppLogger.common('Error sending constituency push notification: $e', tag: 'PUSH_NOTIFICATION_ERROR');
    }
  }

  /// Store notification in database
  Future<void> _storeNotification(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      AppLogger.common('Storing notification in database...', tag: 'STORE_NOTIFICATION');
      AppLogger.common('- User ID: $userId', tag: 'STORE_NOTIFICATION');
      AppLogger.common('- Title: $title', tag: 'STORE_NOTIFICATION');

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

      AppLogger.common('Notification stored successfully', tag: 'STORE_NOTIFICATION');
    } catch (e) {
      AppLogger.common('Error storing notification: $e', tag: 'STORE_NOTIFICATION_ERROR');
    }
  }
}
