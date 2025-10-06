import 'package:firebase_messaging/firebase_messaging.dart';

/// Service responsible for FCM topic subscriptions
class FCMTopicService {
  final FirebaseMessaging _firebaseMessaging;

  FCMTopicService({
    FirebaseMessaging? firebaseMessaging,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  /// Subscribe to a topic (for broadcasting to multiple users)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      throw Exception('Failed to subscribe to topic "$topic": $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      throw Exception('Failed to unsubscribe from topic "$topic": $e');
    }
  }

  /// Subscribe to multiple topics
  Future<void> subscribeToTopics(List<String> topics) async {
    try {
      final futures = topics.map((topic) => subscribeToTopic(topic));
      await Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to subscribe to multiple topics: $e');
    }
  }

  /// Unsubscribe from multiple topics
  Future<void> unsubscribeFromTopics(List<String> topics) async {
    try {
      final futures = topics.map((topic) => unsubscribeFromTopic(topic));
      await Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to unsubscribe from multiple topics: $e');
    }
  }

  /// Subscribe to election-related topics
  Future<void> subscribeToElectionTopics(String stateId, String districtId, String bodyId, String wardId) async {
    final topics = [
      'election_all',
      'election_$stateId',
      'election_${stateId}_$districtId',
      'election_${stateId}_${districtId}_$bodyId',
      'election_${stateId}_${districtId}_${bodyId}_$wardId',
    ];

    await subscribeToTopics(topics);
  }

  /// Unsubscribe from election-related topics
  Future<void> unsubscribeFromElectionTopics(String stateId, String districtId, String bodyId, String wardId) async {
    final topics = [
      'election_all',
      'election_$stateId',
      'election_${stateId}_$districtId',
      'election_${stateId}_${districtId}_$bodyId',
      'election_${stateId}_${districtId}_${bodyId}_$wardId',
    ];

    await unsubscribeFromTopics(topics);
  }

  /// Subscribe to candidate-specific topics
  Future<void> subscribeToCandidateTopics(String candidateId) async {
    final topics = [
      'candidate_$candidateId',
      'candidate_${candidateId}_updates',
      'candidate_${candidateId}_events',
    ];

    await subscribeToTopics(topics);
  }

  /// Unsubscribe from candidate-specific topics
  Future<void> unsubscribeFromCandidateTopics(String candidateId) async {
    final topics = [
      'candidate_$candidateId',
      'candidate_${candidateId}_updates',
      'candidate_${candidateId}_events',
    ];

    await unsubscribeFromTopics(topics);
  }

  /// Subscribe to general app topics
  Future<void> subscribeToGeneralTopics() async {
    final topics = [
      'app_updates',
      'breaking_news',
      'system_announcements',
    ];

    await subscribeToTopics(topics);
  }

  /// Unsubscribe from general app topics
  Future<void> unsubscribeFromGeneralTopics() async {
    final topics = [
      'app_updates',
      'breaking_news',
      'system_announcements',
    ];

    await unsubscribeFromTopics(topics);
  }

  /// Subscribe to user-specific topics (based on preferences)
  Future<void> subscribeToUserTopics(String userId, List<String> preferredTopics) async {
    final topics = preferredTopics.map((topic) => 'user_${userId}_$topic').toList();
    await subscribeToTopics(topics);
  }

  /// Unsubscribe from user-specific topics
  Future<void> unsubscribeFromUserTopics(String userId, List<String> preferredTopics) async {
    final topics = preferredTopics.map((topic) => 'user_${userId}_$topic').toList();
    await unsubscribeFromTopics(topics);
  }
}