import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/repositories/candidate_repository.dart';

class EventNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final CandidateRepository _candidateRepository = CandidateRepository();

  // Send notification when user RSVPs to an event
  Future<void> sendRSVPNotification({
    required String userId,
    required String candidateId,
    required String eventId,
    required String rsvpType,
  }) async {
    try {
      // Get event details
      final event = await _getEventDetails(candidateId, eventId);
      if (event == null) return;

      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(
        candidateId,
      );
      if (candidate == null) return;

      // Get user's FCM token
      final userToken = await _getUserFCMToken(userId);
      if (userToken == null) return;

      // Create notification message
      final title = 'RSVP Confirmed!';
      final body =
          'You are $rsvpType for "${event.title}" by ${candidate.name}';

      // Send push notification
      await _sendPushNotification(userToken, title, body, {
        'type': 'event_rsvp',
        'eventId': eventId,
        'candidateId': candidateId,
        'rsvpType': rsvpType,
      });

      // Store notification in database
      await _storeNotification(userId, title, body, {
        'type': 'event_rsvp',
        'eventId': eventId,
        'candidateId': candidateId,
        'rsvpType': rsvpType,
        'eventTitle': event.title,
        'candidateName': candidate.name,
      });
    } catch (e) {
      print('Error sending RSVP notification: $e');
    }
  }

  // Send reminder notification for upcoming events
  Future<void> sendEventReminder({
    required String userId,
    required String candidateId,
    required String eventId,
  }) async {
    try {
      // Get event details
      final event = await _getEventDetails(candidateId, eventId);
      if (event == null) return;

      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(
        candidateId,
      );
      if (candidate == null) return;

      // Get user's FCM token
      final userToken = await _getUserFCMToken(userId);
      if (userToken == null) return;

      // Create notification message
      final title = 'Event Reminder';
      final body =
          'Don\'t forget: "${event.title}" by ${candidate.name} is tomorrow!';

      // Send push notification
      await _sendPushNotification(userToken, title, body, {
        'type': 'event_reminder',
        'eventId': eventId,
        'candidateId': candidateId,
      });

      // Store notification in database
      await _storeNotification(userId, title, body, {
        'type': 'event_reminder',
        'eventId': eventId,
        'candidateId': candidateId,
        'eventTitle': event.title,
        'candidateName': candidate.name,
      });
    } catch (e) {
      print('Error sending event reminder: $e');
    }
  }

  // Send notification to candidate when someone RSVPs
  Future<void> sendCandidateRSVPNotification({
    required String candidateId,
    required String eventId,
    required String userId,
    required String rsvpType,
  }) async {
    try {
      // Get event details
      final event = await _getEventDetails(candidateId, eventId);
      if (event == null) return;

      // Get candidate details
      final candidate = await _candidateRepository.getCandidateDataById(
        candidateId,
      );
      if (candidate == null) return;

      // Get candidate's FCM token
      final candidateToken = await _getUserFCMToken(candidate.userId!);
      if (candidateToken == null) return;

      // Get user details
      final userData = await _candidateRepository.getUserData(userId);
      final userName = userData?['name'] ?? 'Someone';

      // Create notification message
      final title = 'New RSVP!';
      final body = '$userName is $rsvpType for your event "${event.title}"';

      // Send push notification
      await _sendPushNotification(candidateToken, title, body, {
        'type': 'candidate_rsvp',
        'eventId': eventId,
        'userId': userId,
        'rsvpType': rsvpType,
      });

      // Store notification in database
      await _storeNotification(candidate.userId!, title, body, {
        'type': 'candidate_rsvp',
        'eventId': eventId,
        'userId': userId,
        'rsvpType': rsvpType,
        'eventTitle': event.title,
        'userName': userName,
      });
    } catch (e) {
      print('Error sending candidate RSVP notification: $e');
    }
  }

  // Helper method to get event details (supports events stored as List)
  Future<EventData?> _getEventDetails(
    String candidateId,
    String eventId,
  ) async {
    try {
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) return null;

      final candidateDoc = await _firestore
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (!candidateDoc.exists) return null;

      final candidateData = candidateDoc.data()!;
      final extraInfo = (candidateData['extra_info'] as Map?)
          ?.cast<String, dynamic>();
      final eventsList = (extraInfo?['events'] as List?)?.cast<dynamic>();

      if (eventsList == null) return null;

      // Resolve by synthetic id `event_<index>` or by embedded `id` field
      for (var i = 0; i < eventsList.length; i++) {
        final raw = eventsList[i];
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
        final embeddedId = map['id'] as String? ?? 'event_$i';
        if (embeddedId == eventId) {
          map['id'] = embeddedId; // ensure id present
          return EventData.fromJson(map);
        }
      }

      return null;
    } catch (e) {
      print('Error getting event details: $e');
      return null;
    }
  }

  // Helper method to find candidate location
  Future<Map<String, String>?> _findCandidateLocation(
    String candidateId,
  ) async {
    try {
      final districtsSnapshot = await _firestore.collection('districts').get();

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
              return {'districtId': districtDoc.id, 'bodyId': bodyDoc.id, 'wardId': wardDoc.id};
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error finding candidate location: $e');
      return null;
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
      print('Error getting FCM token: $e');
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
      // Note: In a real implementation, you would send this to your backend
      // which would then use FCM to send the notification
      // For now, we'll just log it
      print('Sending push notification:');
      print('Token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');

      // You could implement a cloud function or backend API call here
      // For example:
      // await http.post('your-backend-url/send-notification', body: {
      //   'token': token,
      //   'title': title,
      //   'body': body,
      //   'data': jsonEncode(data),
      // });
    } catch (e) {
      print('Error sending push notification: $e');
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
      print('Error storing notification: $e');
    }
  }

  // Get user's notifications
  Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Schedule event reminders (would be called by a cloud function or cron job)
  Future<void> scheduleEventReminders() async {
    try {
      // This would typically be run as a scheduled cloud function
      // For now, we'll just log the concept

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      // Find all events happening tomorrow
      final districtsSnapshot = await _firestore.collection('districts').get();

      for (var districtDoc in districtsSnapshot.docs) {
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

        for (var bodyDoc in bodiesSnapshot.docs) {
          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

          for (var wardDoc in wardsSnapshot.docs) {
            final candidatesSnapshot = await wardDoc.reference
                .collection('candidates')
                .get();

            for (var candidateDoc in candidatesSnapshot.docs) {
              final candidateData = candidateDoc.data();
              final extraInfo = (candidateData['extra_info'] as Map?)
                  ?.cast<String, dynamic>();
              final eventsList =
                  (extraInfo?['events'] as List?)?.cast<dynamic>() ??
                  const <dynamic>[];

              for (var i = 0; i < eventsList.length; i++) {
                final raw = eventsList[i];
                if (raw is! Map) continue;
                final map = Map<String, dynamic>.from(
                  raw.cast<String, dynamic>(),
                );
                final event = EventData.fromJson(map);
                final eventDate = DateTime.tryParse(event.date);
                final eventId = (map['id'] as String?) ?? 'event_$i';

                if (eventDate != null &&
                    eventDate.year == tomorrow.year &&
                    eventDate.month == tomorrow.month &&
                    eventDate.day == tomorrow.day) {
                  final rsvp = event.rsvp;
                  if (rsvp != null) {
                    final interested =
                        (rsvp['interested'] as List?)?.cast<String>() ??
                        const <String>[];
                    final going =
                        (rsvp['going'] as List?)?.cast<String>() ??
                        const <String>[];
                    final allUsers = <String>{...interested, ...going}.toList();

                    for (final userId in allUsers) {
                      await sendEventReminder(
                        userId: userId,
                        candidateId: candidateDoc.id,
                        eventId: eventId,
                      );
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error scheduling event reminders: $e');
    }
  }
}
