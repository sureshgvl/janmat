import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/controllers/events_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/events_model.dart';
import 'package:janmat/features/candidate/widgets/event_creation_dialog.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';


// Main EventsTabEdit Widget
class EventsTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Map<String, dynamic>>) onEventsChange;

  const EventsTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onEventsChange,
  });

  @override
  State<EventsTabEdit> createState() => EventsTabEditState();
}

class EventsTabEditState extends State<EventsTabEdit> {
  final CandidateUserController _controller =
      CandidateUserController.to;
  final EventsController _eventsController = Get.find<EventsController>();
  late Worker _eventsWorker;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Ensure events are loaded when widget initializes
    _ensureEventsLoaded();

    // Listen to events changes for reactive updates
    _eventsWorker = ever(_controller.events, (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _eventsWorker.dispose();
    super.dispose();
  }

  Future<void> _ensureEventsLoaded() async {
    // Only fetch if we don't have cached data or if it's been more than 5 minutes
    if (_controller.events.isEmpty && !_controller.isEventsLoading.value) {
      await _controller.fetchEvents();
    }
  }

  void _showEventCreationDialog([EventData? eventToEdit]) {
    showDialog(
      context: context,
      builder: (context) => EventCreationDialog(
        eventToEdit: eventToEdit,
        candidateId: widget.candidateData.candidateId,
        onEventSaved: (event) {
          // Refresh events after saving
          _controller.refreshEvents();
        },
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Remove event from candidate's events
        final currentEvents = _controller.events.toList();
        final updatedEvents = currentEvents
            .where((e) => e.id != eventId)
            .toList();
        widget.onEventsChange(updatedEvents.map((e) => e.toJson()).toList());

        // Update controller's cache
        _controller.updateEventsCache(updatedEvents);

        Get.snackbar('Success', 'Event deleted successfully');
      } catch (e) {
        Get.snackbar('Error', 'Failed to delete event: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Obx(() {
      final displayEvents =
          widget.editedData?.events ?? _controller.events.toList();

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Events',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showEventCreationDialog(),
                      tooltip: 'Add Event',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_controller.isEventsLoading.value)
                const Center(child: CircularProgressIndicator())
              else if (displayEvents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No upcoming events',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        if (widget.isEditing) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showEventCreationDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Event'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayEvents.length,
                  itemBuilder: (context, index) {
                    final event = displayEvents[index];
                    return _buildEventCard(event);
                  },
                ),
            ],
          ),
        ),
      );
    });

    // Add Save and Cancel buttons at the bottom
    return Stack(
      children: [
        card,
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEvents,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Events'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(EventData event) {
    final date = DateTime.tryParse(event.date);
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : event.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEventCreationDialog(event),
                    tooltip: 'Edit Event',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteEvent(event.id!),
                    tooltip: 'Delete Event',
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(formattedDate, style: const TextStyle(fontSize: 14)),
                if (event.time != null && event.time!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(event.time!, style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),

            // Venue
            if (event.venue != null && event.venue!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.venue!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (event.mapLink != null && event.mapLink!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.map, size: 16),
                      onPressed: () => _openMap(event.mapLink!),
                      tooltip: 'Open in Maps',
                    ),
                ],
              ),
            ],

            // Description
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],

            // RSVP Counts
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRSVPCount('Going', event.getGoingCount(), Colors.green),
                const SizedBox(width: 16),
                _buildRSVPCount(
                  'Interested',
                  event.getInterestedCount(),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPCount(String label, int count, Color color) {
    return Row(
      children: [
        Icon(Icons.people, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(String mapLink) async {
    final uri = Uri.parse(mapLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open map link');
    }
  }

  Future<void> _saveEvents() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.editedData ?? widget.candidateData;
      final events = _controller.events.toList();

      // Save using the events controller
      final success = await _eventsController.saveEventsTab(
        candidateId: data.userId ?? '',
        events: events,
        candidateName: data.name,
        photoUrl: data.photo,
        onProgress: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Events saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save events'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving events: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Method to upload pending files (required by dashboard pattern)
  Future<void> uploadPendingFiles() async {
    // Events don't have file uploads, so this is a no-op
    AppLogger.candidate('📤 [Events] No pending files to upload');
  }
}
