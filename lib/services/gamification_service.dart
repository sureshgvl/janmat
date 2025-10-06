import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../features/notifications/services/gamification_notification_service.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationNotificationService _notificationService = GamificationNotificationService();

  // Point values for different actions
  static const int POINTS_EVENT_INTERESTED = 5;
  static const int POINTS_EVENT_GOING = 10;
  static const int POINTS_EVENT_ATTENDED = 25; // For future check-in feature
  static const int POINTS_FIRST_RSVP = 15; // Bonus for first RSVP

  // Achievement thresholds
  static const int ACHIEVEMENT_SOCIAL_BUTTERFLY = 50; // Total RSVP points
  static const int ACHIEVEMENT_EVENT_ENTHUSIAST = 100;
  static const int ACHIEVEMENT_COMMUNITY_CHAMPION = 200;

  // Award points for RSVP
  Future<void> awardRSVPPoints({
    required String userId,
    required String eventId,
    required String candidateId,
    required String rsvpType,
  }) async {
    try {
      final points = rsvpType == 'going'
          ? POINTS_EVENT_GOING
          : POINTS_EVENT_INTERESTED;

      // Check if this is the user's first RSVP
      final isFirstRSVP = await _isFirstRSVP(userId);
      final totalPoints = isFirstRSVP ? points + POINTS_FIRST_RSVP : points;

      // Update user points
      await _updateUserPoints(userId, totalPoints);

      // Record the RSVP activity
      await _recordRSVPActivity(
        userId,
        eventId,
        candidateId,
        rsvpType,
        totalPoints,
      );

      // Check for achievements
      await _checkAndAwardAchievements(userId);

      // Check for level up
      await _notificationService.checkAndNotifyLevelUp(userId);

      debugPrint('Awarded $totalPoints points to user $userId for RSVP');
    } catch (e) {
      debugPrint('Error awarding RSVP points: $e');
    }
  }

  // Remove points when RSVP is cancelled
  Future<void> removeRSVPPoints({
    required String userId,
    required String eventId,
  }) async {
    try {
      // Find the RSVP activity record
      final activityDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('type', isEqualTo: 'event_rsvp')
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (activityDoc.docs.isNotEmpty) {
        final activity = activityDoc.docs.first;
        final points = activity.data()['points'] as int;

        // Subtract points
        await _updateUserPoints(userId, -points);

        // Remove the activity record
        await activity.reference.delete();

        // Check if achievements need to be revoked
        await _checkAndRevokeAchievements(userId);

        debugPrint('Removed $points points from user $userId for cancelled RSVP');
      }
    } catch (e) {
      debugPrint('Error removing RSVP points: $e');
    }
  }

  // Get user's current points and level
  Future<Map<String, dynamic>> getUserGamificationData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {
          'points': 0,
          'level': 1,
          'achievements': [],
          'nextLevelPoints': 100,
        };
      }

      final userData = userDoc.data()!;
      final points = userData['gamification_points'] ?? 0;
      final level = _calculateLevel(points);
      final achievements = userData['achievements'] ?? [];

      return {
        'points': points,
        'level': level,
        'achievements': achievements,
        'nextLevelPoints': _getNextLevelPoints(level),
      };
    } catch (e) {
      debugPrint('Error getting user gamification data: $e');
      return {
        'points': 0,
        'level': 1,
        'achievements': [],
        'nextLevelPoints': 100,
      };
    }
  }

  // Get leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('gamification_points', descending: true)
          .limit(limit)
          .get();

      final leaderboard = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        leaderboard.add({
          'userId': doc.id,
          'name': userData['name'] ?? 'Anonymous',
          'points': userData['gamification_points'] ?? 0,
          'level': _calculateLevel(userData['gamification_points'] ?? 0),
        });
      }

      return leaderboard;
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  // Private helper methods

  Future<bool> _isFirstRSVP(String userId) async {
    try {
      final activitiesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .where('type', isEqualTo: 'event_rsvp')
          .limit(1)
          .get();

      return activitiesSnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking first RSVP: $e');
      return false;
    }
  }

  Future<void> _updateUserPoints(String userId, int points) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'gamification_points': FieldValue.increment(points),
      });
    } catch (e) {
      // If the field doesn't exist, set it
      try {
        await _firestore.collection('users').doc(userId).set({
          'gamification_points': points,
        }, SetOptions(merge: true));
      } catch (setError) {
        debugPrint('Error setting user points: $setError');
      }
    }
  }

  Future<void> _recordRSVPActivity(
    String userId,
    String eventId,
    String candidateId,
    String rsvpType,
    int points,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
            'type': 'event_rsvp',
            'eventId': eventId,
            'candidateId': candidateId,
            'rsvpType': rsvpType,
            'points': points,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error recording RSVP activity: $e');
    }
  }

  Future<void> _checkAndAwardAchievements(String userId) async {
    try {
      final userData = await getUserGamificationData(userId);
      final points = userData['points'] as int;
      final currentAchievements = List<String>.from(userData['achievements']);

      final newAchievements = <String>[];

      if (points >= ACHIEVEMENT_SOCIAL_BUTTERFLY &&
          !currentAchievements.contains('social_butterfly')) {
        newAchievements.add('social_butterfly');
      }

      if (points >= ACHIEVEMENT_EVENT_ENTHUSIAST &&
          !currentAchievements.contains('event_enthusiast')) {
        newAchievements.add('event_enthusiast');
      }

      if (points >= ACHIEVEMENT_COMMUNITY_CHAMPION &&
          !currentAchievements.contains('community_champion')) {
        newAchievements.add('community_champion');
      }

      if (newAchievements.isNotEmpty) {
        final allAchievements = [...currentAchievements, ...newAchievements];
        await _firestore.collection('users').doc(userId).update({
          'achievements': allAchievements,
        });

        // Send achievement notifications
        for (final achievement in newAchievements) {
          try {
            await _notificationService.sendBadgeEarnedNotification(
              userId: userId,
              badgeType: achievement,
              points: points,
            );
          } catch (e) {
            debugPrint('Failed to send achievement notification: $e');
          }
        }

        debugPrint('User $userId earned achievements: $newAchievements');
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _checkAndRevokeAchievements(String userId) async {
    try {
      final userData = await getUserGamificationData(userId);
      final points = userData['points'] as int;
      final currentAchievements = List<String>.from(userData['achievements']);

      final achievementsToRemove = <String>[];

      if (points < ACHIEVEMENT_SOCIAL_BUTTERFLY &&
          currentAchievements.contains('social_butterfly')) {
        achievementsToRemove.add('social_butterfly');
      }

      if (points < ACHIEVEMENT_EVENT_ENTHUSIAST &&
          currentAchievements.contains('event_enthusiast')) {
        achievementsToRemove.add('event_enthusiast');
      }

      if (points < ACHIEVEMENT_COMMUNITY_CHAMPION &&
          currentAchievements.contains('community_champion')) {
        achievementsToRemove.add('community_champion');
      }

      if (achievementsToRemove.isNotEmpty) {
        final updatedAchievements = currentAchievements
            .where((achievement) => !achievementsToRemove.contains(achievement))
            .toList();

        await _firestore.collection('users').doc(userId).update({
          'achievements': updatedAchievements,
        });

        debugPrint('User $userId lost achievements: $achievementsToRemove');
      }
    } catch (e) {
      debugPrint('Error revoking achievements: $e');
    }
  }

  int _calculateLevel(int points) {
    // Simple level calculation: every 100 points = 1 level
    return (points / 100).floor() + 1;
  }

  int _getNextLevelPoints(int currentLevel) {
    return currentLevel * 100;
  }

  // Get achievement details
  static Map<String, Map<String, String>> getAchievementDetails() {
    return {
      'social_butterfly': {
        'title': 'Social Butterfly',
        'description': 'Earned 50+ RSVP points',
        'icon': '🦋',
      },
      'event_enthusiast': {
        'title': 'Event Enthusiast',
        'description': 'Earned 100+ RSVP points',
        'icon': '🎉',
      },
      'community_champion': {
        'title': 'Community Champion',
        'description': 'Earned 200+ RSVP points',
        'icon': '🏆',
      },
    };
  }

  // Get level details
  static Map<String, String> getLevelDetails(int level) {
    final levelTitles = [
      'Newcomer',
      'Engaged Citizen',
      'Community Member',
      'Active Participant',
      'Community Leader',
      'Ward Champion',
      'City Influencer',
      'Election Expert',
    ];

    if (level <= levelTitles.length) {
      return {
        'title': levelTitles[level - 1],
        'description': 'Level $level - Keep engaging with events!',
      };
    } else {
      return {
        'title': 'Election Master',
        'description': 'Level $level - You\'re a true democracy champion!',
      };
    }
  }
}

