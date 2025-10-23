import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/events_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RSVP status enum
  static const String RSVP_INTERESTED = 'interested';
  static const String RSVP_GOING = 'going';
  static const String RSVP_NOT_GOING = 'not_going';

  // Get candidate's actual state ID (helper method)
  Future<String> _getCandidateStateId(String candidateId) async {
    try {
      // First try to get from index
      final indexDoc = await _firestore
          .collection('candidate_index')
          .doc(candidateId)
          .get();

      if (indexDoc.exists) {
        final indexData = indexDoc.data()!;
        final stateId = indexData['stateId'];
        if (stateId != null && stateId.isNotEmpty) {
          return stateId;
        }
      }

      // Fallback: Search across all states to find the candidate
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
                return stateDoc.id; // Return the actual state ID
              }
            }
          }
        }
      }

      // Candidate not found in any state
      throw Exception('Candidate $candidateId not found in any state');
    } catch (e) {
      AppLogger.candidateError('❌ Failed to get candidate state ID: $e');
      throw Exception('Unable to determine candidate state: $e');
    }
  }

  // Get all events for a candidate - UPDATED to use top-level events field
  Future<List<EventData>> getCandidateEvents(String candidateId) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        return [];
      }

      final candidateDoc = await _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (!candidateDoc.exists) {
        return [];
      }

      final candidateData = candidateDoc.data()!;
      final eventsData = candidateData['events'] as List<dynamic>?;

      if (eventsData == null) {
        return [];
      }

      final events = <EventData>[];
      for (int i = 0; i < eventsData.length; i++) {
        final eventMap = Map<String, dynamic>.from(
          eventsData[i] as Map<String, dynamic>,
        );
        eventMap['id'] = 'event_$i'; // Generate ID if not present
        events.add(EventData.fromJson(eventMap));
      }

      // Sort by date (upcoming first)
      events.sort((a, b) {
        final aDate = DateTime.tryParse(a.date) ?? DateTime.now();
        final bDate = DateTime.tryParse(b.date) ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      return events;
    } catch (e) {
      throw Exception('Failed to get candidate events: $e');
    }
  }

  // Create a new event - UPDATED to save directly to events field
  Future<bool> createEvent(String candidateId, EventData eventData) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        throw Exception('Candidate not found');
      }

      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId);

      final candidateDoc = await candidateRef.get();
      if (!candidateDoc.exists) {
        throw Exception('Candidate document missing');
      }

      final data = candidateDoc.data()!;
      final eventsData = (data['events'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      // Add new event
      eventsData.add(eventData.toJson());

      await candidateRef.update({
        'events': eventsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update an existing event - UPDATED to save directly to events field
  Future<bool> updateEvent(String candidateId, String eventId, EventData eventData) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        throw Exception('Candidate not found');
      }

      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId);

      final candidateDoc = await candidateRef.get();
      if (!candidateDoc.exists) {
        throw Exception('Candidate document missing');
      }

      final data = candidateDoc.data()!;
      final eventsData = (data['events'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      final index = _resolveEventIndex(eventId, eventsData);
      if (index == null || index < 0 || index >= eventsData.length) {
        throw Exception('Event not found');
      }

      // Update event
      eventsData[index] = eventData.toJson();

      await candidateRef.update({
        'events': eventsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete an event - UPDATED to save directly to events field
  Future<bool> deleteEvent(String candidateId, String eventId) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        throw Exception('Candidate not found');
      }

      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId);

      final candidateDoc = await candidateRef.get();
      if (!candidateDoc.exists) {
        throw Exception('Candidate document missing');
      }

      final data = candidateDoc.data()!;
      final eventsData = (data['events'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      final index = _resolveEventIndex(eventId, eventsData);
      if (index == null || index < 0 || index >= eventsData.length) {
        throw Exception('Event not found');
      }

      // Remove event
      eventsData.removeAt(index);

      await candidateRef.update({
        'events': eventsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // RSVP to an event - UPDATED to save directly to events field
  Future<bool> rsvpToEvent(String candidateId, String eventId, String userId, String rsvpType) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final candidateLocation = await _findCandidateLocation(candidateId);
      if (candidateLocation == null) {
        throw Exception('Candidate not found');
      }

      final candidateRef = _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .doc(candidateLocation['districtId'])
          .collection('bodies')
          .doc(candidateLocation['bodyId'])
          .collection('wards')
          .doc(candidateLocation['wardId'])
          .collection('candidates')
          .doc(candidateId);

      // Load full events list
      final candidateDoc = await candidateRef.get();
      if (!candidateDoc.exists) {
        throw Exception('Candidate document missing');
      }

      final data = candidateDoc.data()!;
      final eventsData = (data['events'] as List?)?.cast<dynamic>() ?? <dynamic>[];

      if (eventsData.isEmpty) {
        throw Exception('No events found to RSVP');
      }

      // Resolve event index by id or by "event_<index>" pattern
      final index = _resolveEventIndex(eventId, eventsData);

      if (index == null || index < 0 || index >= eventsData.length) {
        throw Exception('Event not found for id: $eventId');
      }

      // Normalize event map
      final eventMap = Map<String, dynamic>.from(
        (eventsData[index] as Map?)?.cast<String, dynamic>() ?? {},
      );
      final rsvp = Map<String, dynamic>.from(
        (eventMap['rsvp'] as Map?)?.cast<String, dynamic>() ?? {},
      );

      final interested =
          (rsvp[RSVP_INTERESTED] as List?)?.cast<dynamic>().toSet() ?? <dynamic>{};
      final going =
          (rsvp[RSVP_GOING] as List?)?.cast<dynamic>().toSet() ?? <dynamic>{};
      final notGoing =
          (rsvp[RSVP_NOT_GOING] as List?)?.cast<dynamic>().toSet() ?? <dynamic>{};

      // Remove from all first
      interested.remove(userId);
      going.remove(userId);
      notGoing.remove(userId);

      // Add to selected
      if (rsvpType == RSVP_INTERESTED) interested.add(userId);
      if (rsvpType == RSVP_GOING) going.add(userId);
      if (rsvpType == RSVP_NOT_GOING) notGoing.add(userId);

      rsvp[RSVP_INTERESTED] = interested.toList();
      rsvp[RSVP_GOING] = going.toList();
      rsvp[RSVP_NOT_GOING] = notGoing.toList();
      eventMap['rsvp'] = rsvp;

      // Write back updated event into list
      eventsData[index] = eventMap;

      await candidateRef.update({
        'events': eventsData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to add RSVP: $e');
    }
  }

  // Helper method to find candidate location
  Future<Map<String, String>?> _findCandidateLocation(String candidateId) async {
    try {
      final candidateStateId = await _getCandidateStateId(candidateId);
      final districtsSnapshot = await _firestore
          .collection('states')
          .doc(candidateStateId)
          .collection('districts')
          .get();

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
      throw Exception('Failed to find candidate location: $e');
    }
  }

  // Helper: resolve index from 'event_<index>' id or by matching 'id' field in list
  int? _resolveEventIndex(String eventId, List<dynamic> eventsData) {
    if (eventId.startsWith('event_')) {
      final idxStr = eventId.substring('event_'.length);
      final idx = int.tryParse(idxStr);
      if (idx != null) return idx;
    }
    for (var i = 0; i < eventsData.length; i++) {
      final map = (eventsData[i] as Map?)?.cast<String, dynamic>();
      if (map != null && map['id'] == eventId) return i;
    }
    return null;
  }

  // Get RSVP counts for an event
  Future<Map<String, int>> getEventRSVPCounts(String eventId) async {
    try {
      // This is a simplified implementation - in a real app you'd need to find the event first
      // For now, return mock data
      return {
        'interested': 0,
        'going': 0,
        'not_going': 0,
      };
    } catch (e) {
      throw Exception('Failed to get RSVP counts: $e');
    }
  }

  // Get user's RSVP status for an event
  Future<String?> getUserRSVPStatus(String eventId, String userId) async {
    try {
      // This is a simplified implementation - in a real app you'd need to find the event first
      // For now, return null (no RSVP)
      return null;
    } catch (e) {
      throw Exception('Failed to get RSVP status: $e');
    }
  }

  // Add RSVP for an event
  Future<bool> addEventRSVP(String eventId, String userId, String rsvpType) async {
    try {
      // This is a simplified implementation - in a real app you'd need to find the event first
      // For now, return true
      return true;
    } catch (e) {
      throw Exception('Failed to add RSVP: $e');
    }
  }

  // Remove RSVP for an event
  Future<bool> removeEventRSVP(String eventId, String userId) async {
    try {
      // This is a simplified implementation - in a real app you'd need to find the event first
      // For now, return true
      return true;
    } catch (e) {
      throw Exception('Failed to remove RSVP: $e');
    }
  }

}
