import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/events_model.dart';
import '../models/candidate_model.dart';
import '../repositories/candidate_event_repository.dart';

class EventsController extends GetxController {
  final EventRepository _eventRepository = EventRepository();

  // Reactive data
  var events = RxList<EventData>([]);
  var isLoading = false.obs;
  var eventsLastFetched = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Events are loaded on-demand by the main controller
  }

  /// Fetch events for the current candidate with caching
  Future<void> fetchEvents(Candidate candidate, {bool forceRefresh = false}) async {
    // Check if we have recent data and don't need to refresh
    if (!forceRefresh &&
        eventsLastFetched.value != null &&
        events.isNotEmpty &&
        DateTime.now().difference(eventsLastFetched.value!) <
            const Duration(minutes: 5)) {
      return;
    }

    isLoading.value = true;
    try {
      final fetchedEvents = await _eventRepository.getCandidateEvents(candidate);
      events.assignAll(fetchedEvents);
      eventsLastFetched.value = DateTime.now();
    } catch (e) {
      events.clear();
      eventsLastFetched.value = null;
      // Don't show error snackbar for missing candidate data - this is expected
      if (!e.toString().contains('No candidate found')) {
        Get.snackbar('Error', 'Failed to load events: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh events data (force reload from server)
  Future<void> refreshEvents(Candidate candidate) async {
    await fetchEvents(candidate, forceRefresh: true);
  }

  /// Get events data (ensures data is loaded if not already)
  Future<List<EventData>> getEventsData(Candidate candidate) async {
    if (events.isEmpty && !isLoading.value) {
      await fetchEvents(candidate);
    }
    return events.toList();
  }

  /// Clear events cache
  void clearEventsCache() {
    events.clear();
    eventsLastFetched.value = null;
  }

  /// Update events after creation/editing/deletion
  void updateEventsCache(List<EventData> updatedEvents) {
    events.assignAll(updatedEvents);
    eventsLastFetched.value = DateTime.now();
  }

  /// Create a new event
  Future<bool> createEvent(Candidate candidate, EventData eventData) async {
    final candidateId = candidate.candidateId;
    try {
      await _eventRepository.createEvent(candidate, eventData);
      await refreshEvents(candidate); // Refresh the list
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to create event: $e');
      return false;
    }
  }

  /// Update an existing event
  Future<bool> updateEvent(Candidate candidate, String eventId, EventData eventData) async {
    final candidateId = candidate.candidateId;
    try {
      await _eventRepository.updateEvent(candidate, eventId, eventData);
      await refreshEvents(candidate); // Refresh the list
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update event: $e');
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(Candidate candidate, String eventId) async {
    final candidateId = candidate.candidateId;
    try {
      await _eventRepository.deleteEvent(candidate, eventId);
      await refreshEvents(candidate); // Refresh the list
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete event: $e');
      return false;
    }
  }

  /// RSVP to an event
  Future<bool> rsvpToEvent(Candidate candidate, String eventId, String userId, String rsvpType) async {
    final candidateId = candidate.candidateId;
    try {
      await _eventRepository.rsvpToEvent(candidate, eventId, userId, rsvpType);
      await refreshEvents(candidate); // Refresh to get updated RSVP counts
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to RSVP: $e');
      return false;
    }
  }

  void updateEvents(dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through the event repository methods
    if (value is List<EventData>) {
      events.assignAll(value);
      eventsLastFetched.value = DateTime.now();
    }
  }

  /// Update events after editing in UI
  void updateEventsFromUI(List<EventData> updatedEvents) {
    events.assignAll(updatedEvents);
    eventsLastFetched.value = DateTime.now();
  }

  @override
  /// TAB-SPECIFIC SAVE: Direct events tab save method
  /// Handles all events operations for the tab independently
  Future<bool> saveEventsTab({
    required Candidate candidate,
    required List<EventData> events,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🎪 TAB SAVE: Events tab for $candidateId', tag: 'EVENTS_TAB');

      onProgress?.call('Saving events...');

      // For events tab, we don't actually save events data to the candidate document
      // Events are managed separately through the event repository
      // This method is here for consistency with other tabs
      // In practice, events are created/updated/deleted through specific methods

      onProgress?.call('Events saved successfully!');

      AppLogger.database('✅ TAB SAVE: Events completed successfully', tag: 'EVENTS_TAB');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Events tab save failed', tag: 'EVENTS_TAB', error: e);
      return false;
    }
  }

  /// TAB-SPECIFIC SAVE WITH CANDIDATE: Direct events tab save method with candidate context
  /// Handles all events operations for the tab independently with full candidate data
  Future<bool> saveEventsTabWithCandidate({
    required Candidate candidate,
    required List<EventData> events,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🎪 TAB SAVE: Events tab with candidate for $candidateId', tag: 'EVENTS_TAB');

      onProgress?.call('Saving events...');

      // For events tab, we don't actually save events data to the candidate document
      // Events are managed separately through the event repository
      // Individual events are created/updated/deleted through specific methods
      // This method is here for consistency with other tabs and dashboard patterns

      onProgress?.call('Events updated successfully!');

      AppLogger.database('✅ TAB SAVE: Events completed successfully', tag: 'EVENTS_TAB');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Events tab save failed', tag: 'EVENTS_TAB', error: e);
      return false;
    }
  }

  @override
  /// FAST SAVE: Direct events update for simple field changes
  /// Main save is fast, but triggers essential background operations
  Future<bool> saveEventsFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST SAVE: Events for $candidateId', tag: 'EVENTS_FAST');

      // For events, we typically don't do direct field updates like other tabs
      // Events are managed through specific CRUD operations
      // This method is here for consistency with other controllers
      // In practice, events are saved through createEvent/updateEvent methods

      // For now, we'll treat this as a no-op since events don't have simple field updates
      // like basic info, manifesto, etc.
      AppLogger.database('✅ FAST SAVE: Events fast save completed (no-op)', tag: 'EVENTS_FAST');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ FAST SAVE: Events failed', tag: 'EVENTS_FAST', error: e);
      return false;
    }
  }
}
