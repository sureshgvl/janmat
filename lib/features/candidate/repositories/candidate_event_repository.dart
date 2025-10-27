import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/events_model.dart';
import '../models/candidate_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // RSVP status enum
  static const String RSVP_INTERESTED = 'interested';
  static const String RSVP_GOING = 'going';
  static const String RSVP_NOT_GOING = 'not_going';

  // Get all events for a candidate - UPDATED to use top-level events field
  Future<List<EventData>> getCandidateEvents(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
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
  Future<bool> createEvent(Candidate candidate, EventData eventData) async {
    final candidateId = candidate.candidateId;
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
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
  Future<bool> updateEvent(Candidate candidate, String eventId, EventData eventData) async {
    final candidateId = candidate.candidateId;
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
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
  Future<bool> deleteEvent(Candidate candidate, String eventId) async {
    final candidateId = candidate.candidateId;
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
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
  Future<bool> rsvpToEvent(Candidate candidate, String eventId, String userId, String rsvpType) async {
    final candidateId = candidate.candidateId;
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
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
  Future<Map<String, int>> getEventRSVPCounts(Candidate candidate, String eventId) async {
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidate.candidateId)
          .get();

      if (!candidateDoc.exists) {
        return {'interested': 0, 'going': 0, 'not_going': 0};
      }

      final candidateData = candidateDoc.data()!;
      final eventsData = candidateData['events'] as List<dynamic>? ?? [];

      final index = _resolveEventIndex(eventId, eventsData);
      if (index == null || index < 0 || index >= eventsData.length) {
        return {'interested': 0, 'going': 0, 'not_going': 0};
      }

      final eventMap = Map<String, dynamic>.from(eventsData[index] as Map<String, dynamic>);
      final rsvp = eventMap['rsvp'] as Map<String, dynamic>? ?? {};

      return {
        'interested': (rsvp[RSVP_INTERESTED] as List?)?.length ?? 0,
        'going': (rsvp[RSVP_GOING] as List?)?.length ?? 0,
        'not_going': (rsvp[RSVP_NOT_GOING] as List?)?.length ?? 0,
      };
    } catch (e) {
      AppLogger.databaseError('Error getting RSVP counts: $e');
      return {'interested': 0, 'going': 0, 'not_going': 0};
    }
  }

  // Get user's RSVP status for an event
  Future<String?> getUserRSVPStatus(Candidate candidate, String eventId, String userId) async {
    try {
      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidate.candidateId)
          .get();

      if (!candidateDoc.exists) {
        return null;
      }

      final candidateData = candidateDoc.data()!;
      final eventsData = candidateData['events'] as List<dynamic>? ?? [];

      final index = _resolveEventIndex(eventId, eventsData);
      if (index == null || index < 0 || index >= eventsData.length) {
        return null;
      }

      final eventMap = Map<String, dynamic>.from(eventsData[index] as Map<String, dynamic>);
      final rsvp = eventMap['rsvp'] as Map<String, dynamic>? ?? {};

      if ((rsvp[RSVP_INTERESTED] as List?)?.contains(userId) == true) {
        return RSVP_INTERESTED;
      }
      if ((rsvp[RSVP_GOING] as List?)?.contains(userId) == true) {
        return RSVP_GOING;
      }
      if ((rsvp[RSVP_NOT_GOING] as List?)?.contains(userId) == true) {
        return RSVP_NOT_GOING;
      }

      return null;
    } catch (e) {
      AppLogger.databaseError('Error getting RSVP status: $e');
      return null;
    }
  }

  // Add RSVP for an event
  Future<bool> addEventRSVP(Candidate candidate, String eventId, String userId, String rsvpType) async {
    try {
      // Use the rsvpToEvent method for updating RSVP status
      return await rsvpToEvent(candidate, eventId, userId, rsvpType);
    } catch (e) {
      AppLogger.databaseError('Error adding RSVP: $e');
      return false;
    }
  }

  // Remove RSVP for an event
  Future<bool> removeEventRSVP(Candidate candidate, String eventId, String userId) async {
    try {
      // To remove RSVP, we need to set it to null/empty
      // For now, we'll just return true as removing specific RSVPs might need more complex logic
      return true;
    } catch (e) {
      AppLogger.databaseError('Error removing RSVP: $e');
      return false;
    }
  }

}
