import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

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
      debugPrint('📜 [ManifestoUpdate] Starting manifesto update notification...');
      debugPrint('   - Candidate ID: $candidateId');
      debugPrint('   - Update type: $updateType');
      debugPrint('   - Manifesto title: $manifestoTitle');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        debugPrint('❌ [ManifestoUpdate] Candidate data not found');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      debugPrint('   - Candidate name: $candidateName');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        debugPrint('❌ [ManifestoUpdate] Could not determine candidate location');
        return;
      }

      debugPrint('📍 [ManifestoUpdate] Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      debugPrint('👥 [ManifestoUpdate] Found ${constituencyUsers.length} users in constituency');

      if (constituencyUsers.isEmpty) return;

      // Get candidate followers (primary audience)
      final followers = await _getCandidateFollowers(candidateId);
      debugPrint('👥 [ManifestoUpdate] Found ${followers.length} direct followers');

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

      debugPrint('👥 [ManifestoUpdate] Total target users: ${allTargetUsers.length}');

      if (allTargetUsers.isEmpty) return;

      // Filter users who have manifesto update notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in allTargetUsers) {
        // Skip if this is the candidate updating their own manifesto
        if (user['userId'] == candidateData['userId']) {
          debugPrint('⏭️ [ManifestoUpdate] Skipping candidate themselves: ${user['userId']}');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['manifestoUpdates'] == true) {
          eligibleUsers.add(user);
        }
      }

      debugPrint('✅ [ManifestoUpdate] ${eligibleUsers.length} users have manifesto update notifications enabled');

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

      debugPrint('📱 [ManifestoUpdate] ${tokens.length} valid FCM tokens found');

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
      debugPrint('📤 [ManifestoUpdate] Sending notifications to ${tokens.length} users...');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user
      debugPrint('💾 [ManifestoUpdate] Storing notifications in database...');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      debugPrint('🎉 [ManifestoUpdate] Manifesto update notifications sent successfully to ${validUsers.length} users');
    } catch (e) {
      debugPrint('❌ [ManifestoUpdate] Error sending manifesto update notification: $e');
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
      debugPrint('📤 [ManifestoShared] Starting manifesto sharing notification...');
      debugPrint('   - Candidate ID: $candidateId');
      debugPrint('   - Manifesto title: $manifestoTitle');
      debugPrint('   - Share platform: $sharePlatform');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        debugPrint('❌ [ManifestoShared] Candidate data not found');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      debugPrint('   - Candidate name: $candidateName');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        debugPrint('❌ [ManifestoShared] Could not determine candidate location');
        return;
      }

      debugPrint('📍 [ManifestoShared] Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      debugPrint('👥 [ManifestoShared] Found ${constituencyUsers.length} users in constituency');

      if (constituencyUsers.isEmpty) return;

      // Get candidate followers (primary audience)
      final followers = await _getCandidateFollowers(candidateId);
      debugPrint('👥 [ManifestoShared] Found ${followers.length} direct followers');

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

      debugPrint('👥 [ManifestoShared] Total target users: ${allTargetUsers.length}');

      if (allTargetUsers.isEmpty) return;

      // Filter users who have content sharing notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in allTargetUsers) {
        // Skip if this is the candidate sharing their own manifesto
        if (user['userId'] == candidateData['userId']) {
          debugPrint('⏭️ [ManifestoShared] Skipping candidate themselves: ${user['userId']}');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['contentSharing'] == true) {
          eligibleUsers.add(user);
        }
      }

      debugPrint('✅ [ManifestoShared] ${eligibleUsers.length} users have content sharing notifications enabled');

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

      debugPrint('📱 [ManifestoShared] ${tokens.length} valid FCM tokens found');

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
      debugPrint('📤 [ManifestoShared] Sending notifications to ${tokens.length} users...');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user
      debugPrint('💾 [ManifestoShared] Storing notifications in database...');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      debugPrint('🎉 [ManifestoShared] Manifesto sharing notifications sent successfully to ${validUsers.length} users');
    } catch (e) {
      debugPrint('❌ [ManifestoShared] Error sending manifesto sharing notification: $e');
    }
  }

  /// Notify voters in constituency when a new candidate creates their profile
  Future<void> sendCandidateProfileCreatedNotification({
    required String candidateId,
  }) async {
    try {
      debugPrint('🆕 [CandidateProfileCreated] Starting candidate profile created notification...');
      debugPrint('   - Candidate ID: $candidateId');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        debugPrint('❌ [CandidateProfileCreated] Candidate data not found');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'New Candidate';
      debugPrint('   - Candidate name: $candidateName');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        debugPrint('❌ [CandidateProfileCreated] Could not determine candidate location');
        return;
      }

      debugPrint('📍 [CandidateProfileCreated] Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      debugPrint('👥 [CandidateProfileCreated] Found ${constituencyUsers.length} users in constituency');

      if (constituencyUsers.isEmpty) return;

      // Filter users who have new candidate notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in constituencyUsers) {
        // Skip if this is the candidate creating their own profile
        if (user['userId'] == candidateData['userId']) {
          debugPrint('⏭️ [CandidateProfileCreated] Skipping candidate themselves: ${user['userId']}');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['newCandidates'] == true) {
          eligibleUsers.add(user);
        }
      }

      debugPrint('✅ [CandidateProfileCreated] ${eligibleUsers.length} users have new candidate notifications enabled');

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

      debugPrint('📱 [CandidateProfileCreated] ${tokens.length} valid FCM tokens found');

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
      debugPrint('📤 [CandidateProfileCreated] Sending notifications to ${tokens.length} users...');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user (include full constituency data for local storage)
      debugPrint('💾 [CandidateProfileCreated] Storing notifications in database...');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      debugPrint('🎉 [CandidateProfileCreated] New candidate notifications sent successfully to ${validUsers.length} constituency users');
    } catch (e) {
      debugPrint('❌ [CandidateProfileCreated] Error sending candidate profile created notification: $e');
    }
  }

  /// Notify voters and candidates in same constituency about candidate profile updates
  Future<void> sendProfileUpdateNotification({
    required String candidateId,
    required String updateType, // 'photo', 'bio', 'contact', 'manifesto', etc.
    required String updateDescription,
  }) async {
    try {
      debugPrint('🏠 [ConstituencyProfileUpdate] Starting constituency-aware profile update notification...');
      debugPrint('   - Candidate ID: $candidateId');
      debugPrint('   - Update type: $updateType');
      debugPrint('   - Update description: $updateDescription');

      // Get candidate details and location
      final candidateData = await _getCandidateData(candidateId);
      if (candidateData == null) {
        debugPrint('❌ [ConstituencyProfileUpdate] Candidate data not found');
        return;
      }

      final candidateName = candidateData['name'] as String? ?? 'Candidate';
      debugPrint('   - Candidate name: $candidateName');

      // Get candidate's constituency location
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        debugPrint('❌ [ConstituencyProfileUpdate] Could not determine candidate location');
        return;
      }

      debugPrint('📍 [ConstituencyProfileUpdate] Candidate location: ${candidateLocation['stateId']}/${candidateLocation['districtId']}/${candidateLocation['bodyId']}/${candidateLocation['wardId']}');

      // Get all users in the same constituency (voters and candidates)
      final constituencyUsers = await _getConstituencyUsers(
        candidateLocation['stateId']!,
        candidateLocation['districtId']!,
        candidateLocation['bodyId']!,
        candidateLocation['wardId']!,
      );

      debugPrint('👥 [ConstituencyProfileUpdate] Found ${constituencyUsers.length} users in constituency');

      if (constituencyUsers.isEmpty) return;

      // Filter users who have profile update notifications enabled
      // Exclude the candidate themselves from receiving their own notification
      final eligibleUsers = <Map<String, dynamic>>[];
      for (final user in constituencyUsers) {
        // Skip if this is the candidate updating their own profile
        if (user['userId'] == candidateData['userId']) {
          debugPrint('⏭️ [ConstituencyProfileUpdate] Skipping candidate themselves: ${user['userId']}');
          continue;
        }

        final userPrefs = await _getUserNotificationPreferences(user['userId']);
        if (userPrefs['profileUpdates'] == true) {
          eligibleUsers.add(user);
        }
      }

      debugPrint('✅ [ConstituencyProfileUpdate] ${eligibleUsers.length} users have profile update notifications enabled');

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

      debugPrint('📱 [ConstituencyProfileUpdate] ${tokens.length} valid FCM tokens found');

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
      debugPrint('📤 [ConstituencyProfileUpdate] Sending notifications to ${tokens.length} users...');
      for (final token in tokens) {
        await _sendPushNotification(token, title, body, notificationData);
      }

      // Store notifications in database for each user (include full constituency data for local storage)
      debugPrint('💾 [ConstituencyProfileUpdate] Storing notifications in database...');
      final dbNotificationData = {
        ...notificationData,
        'constituency': candidateLocation, // Keep full map for database storage
      };

      for (final user in validUsers) {
        await _storeNotification(user['userId'], title, body, dbNotificationData);
      }

      debugPrint('🎉 [ConstituencyProfileUpdate] Profile update notifications sent successfully to ${validUsers.length} constituency users');
    } catch (e) {
      debugPrint('❌ [ConstituencyProfileUpdate] Error sending profile update notification: $e');
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

      debugPrint('❌ Candidate not found in any location: $candidateId');
      return null;
    } catch (e) {
      debugPrint('Error getting candidate data: $e');
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
      debugPrint('Error finding candidate location: $e');
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
      debugPrint('🔍 [ConstituencyUsers] Finding users in constituency: $stateId/$districtId/$bodyId/$wardId');

      // Query users collection for voters - filter by basic location fields first
      debugPrint('👥 [ConstituencyUsers] Querying users collection for voters...');
      final votersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'voter')
          .where('stateId', isEqualTo: stateId)
          .where('districtId', isEqualTo: districtId)
          .get();

      debugPrint('👥 [ConstituencyUsers] Found ${votersQuery.docs.length} potential voters, filtering by electionAreas...');

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
            debugPrint('   ✅ Added voter: ${voterDoc.id} (${voterData['name'] ?? 'Voter'})');
          }
        }
      }

      debugPrint('👥 [ConstituencyUsers] After filtering: ${users.where((u) => u['type'] == 'voter').length} voters in constituency');

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

      debugPrint('🏛️ [ConstituencyUsers] Found ${candidatesSnapshot.docs.length} candidates in subcollection');
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
            debugPrint('   ✅ Added candidate: ${candidateData['userId']} (${candidateData['name'] ?? 'Candidate'})');
          } else {
            debugPrint('   ⏭️ Skipped duplicate candidate: ${candidateData['userId']}');
          }
        }
      }

      debugPrint('📊 [ConstituencyUsers] Total users found: ${users.length}');
      for (final user in users) {
        debugPrint('   - ${user['type']}: ${user['userId']} (${user['name']})');
      }

      return users;
    } catch (e) {
      debugPrint('❌ [ConstituencyUsers] Error getting constituency users: $e');
      debugPrint('   Error details: $e');
      return [];
    }
  }

  /// Get candidate's followers
  Future<List<Map<String, dynamic>>> _getCandidateFollowers(String candidateId) async {
    try {
      // Query users who follow this candidate
      // This would need to be implemented based on your following system
      // For now, return empty list - constituency users will still get notifications
      debugPrint('👥 [Followers] Getting followers for candidate: $candidateId');
      // TODO: Implement based on your following data structure
      return [];
    } catch (e) {
      debugPrint('Error getting candidate followers: $e');
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
      debugPrint('Error getting user notification preferences: $e');
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
      debugPrint('Error getting FCM token: $e');
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
      debugPrint('🚀 Sending constituency push notification:');
      debugPrint('Token: $token');
      debugPrint('Title: $title');
      debugPrint('Body: $body');
      debugPrint('Data: $data');

      // Call Firebase Cloud Function to send push notification
      final callable = _functions.httpsCallable('sendPushNotification');
      await callable.call({
        'token': token,
        'title': title,
        'body': body,
        'notificationData': data,
      });

      debugPrint('✅ Constituency push notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending constituency push notification: $e');
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
      debugPrint('💾 [ConstituencyStore] Storing notification in database...');
      debugPrint('   - User ID: $userId');
      debugPrint('   - Title: $title');

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

      debugPrint('✅ [ConstituencyStore] Notification stored successfully');
    } catch (e) {
      debugPrint('❌ [ConstituencyStore] Error storing notification: $e');
    }
  }
}