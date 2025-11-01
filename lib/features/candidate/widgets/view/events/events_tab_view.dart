import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/candidate_model.dart';
import '../../../models/events_model.dart';
import '../../../repositories/candidate_event_repository.dart';
import '../../../services/event_notification_service.dart';
import '../../../../../services/gamification_service.dart';
import '../../../../../utils/app_logger.dart';

class VoterEventsSection extends StatefulWidget {
  final Candidate candidateData;

  const VoterEventsSection({super.key, required this.candidateData});

  @override
  State<VoterEventsSection> createState() => _VoterEventsSectionState();
}

class _VoterEventsSectionState extends State<VoterEventsSection> {
  late final EventRepository _eventRepository;
  late final EventNotificationService _notificationService;
  late final GamificationService _gamificationService;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, String?> _userRSVPStatuses = {};
  Map<String, Map<String, int>> _rsvpCounts = {};
  bool _isLoadingRSVP = false;

  @override
  void initState() {
    super.initState();
    // Initialize services lazily to avoid circular dependencies
    _eventRepository = EventRepository();
    _notificationService = EventNotificationService();
    _gamificationService = GamificationService();
    // Load RSVP data when widget initializes
    _loadRSVPData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRSVPData() async {
    // Get events from candidate data
    final candidateEvents = widget.candidateData.events ?? [];
    if (candidateEvents.isEmpty) return;

    setState(() {
      _isLoadingRSVP = true;
    });

    try {
      final rsvpStatuses = <String, String?>{};
      final rsvpCounts = <String, Map<String, int>>{};

      for (final event in candidateEvents) {
        if (event.id != null && _currentUserId != null) {
          rsvpStatuses[event.id!] = await _eventRepository.getUserRSVPStatus(widget.candidateData, event.id!, _currentUserId);
        }

        if (event.id != null) {
          rsvpCounts[event.id!] = await _eventRepository.getEventRSVPCounts(widget.candidateData, event.id!);
        }
      }

      if (mounted) {
        setState(() {
          _userRSVPStatuses = rsvpStatuses;
          _rsvpCounts = rsvpCounts;
          _isLoadingRSVP = false;
        });
      }
    } catch (e) {
      AppLogger.candidateError('❌ VoterEventsSection: Failed to load RSVP data: $e');
      if (mounted) {
        setState(() {
          _isLoadingRSVP = false;
        });
      }
    }
  }

  Future<void> _handleRSVP(String eventId, String rsvpType) async {
    if (_currentUserId == null) {
      Get.snackbar('Error', 'Please login to RSVP to events');
      return;
    }

    try {
      final success = await _eventRepository.addEventRSVP(widget.candidateData, eventId, _currentUserId, rsvpType);

      if (success) {
        // Update local state
        setState(() {
          _userRSVPStatuses[eventId] = rsvpType;
        });

        // Reload RSVP counts
        final counts = await _eventRepository.getEventRSVPCounts(widget.candidateData, eventId);
        setState(() {
          _rsvpCounts[eventId] = counts;
        });

        // Send notifications
        try {
          // Send notification to user
          await _notificationService.sendRSVPNotification(
            userId: _currentUserId,
            candidateId: widget.candidateData.candidateId,
            eventId: eventId,
            rsvpType: rsvpType,
          );

          // Send notification to candidate
          await _notificationService.sendCandidateRSVPNotification(
            candidateId: widget.candidateData.candidateId,
            eventId: eventId,
            userId: _currentUserId,
            rsvpType: rsvpType,
          );
        } catch (notificationError) {
          // Don't fail the RSVP if notification fails
          AppLogger.candidateError('Notification error: $notificationError');
        }

        // Award gamification points
        try {
          await _gamificationService.awardRSVPPoints(
            userId: _currentUserId,
            eventId: eventId,
            candidateId: widget.candidateData.candidateId,
            rsvpType: rsvpType,
          );
        } catch (gamificationError) {
          // Don't fail the RSVP if gamification fails
          AppLogger.candidateError('Gamification error: $gamificationError');
        }

        Get.snackbar(
          'Success',
          'RSVP updated successfully! You earned points!',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update RSVP: $e');
    }
  }

  Future<void> _removeRSVP(String eventId) async {
    if (_currentUserId == null) return;

    try {
      final success = await _eventRepository.removeEventRSVP(widget.candidateData, eventId, _currentUserId);

      if (success) {
        // Update local state
        setState(() {
          _userRSVPStatuses[eventId] = null;
        });

        // Reload RSVP counts
        final counts = await _eventRepository.getEventRSVPCounts(widget.candidateData, eventId);
        setState(() {
          _rsvpCounts[eventId] = counts;
        });

        // Remove gamification points
        try {
          await _gamificationService.removeRSVPPoints(
            userId: _currentUserId,
            eventId: eventId,
          );
        } catch (gamificationError) {
          // Don't fail the RSVP removal if gamification fails
          AppLogger.candidateError('Gamification error: $gamificationError');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove RSVP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get events from candidate's data
    final candidateEvents = widget.candidateData.events ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLoadingRSVP && candidateEvents.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (candidateEvents.isEmpty)
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
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: candidateEvents.length,
                itemBuilder: (context, index) {
                  final event = candidateEvents[index];
                  return _buildEventCard(event);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventData event) {
    final date = DateTime.tryParse(event.date);
    final formattedDate = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : event.date;
    final eventId = event.id;
    final hasValidId = eventId != null && eventId.isNotEmpty;
    final userRSVP = hasValidId ? _userRSVPStatuses[eventId] : null;
    final counts = hasValidId
        ? _rsvpCounts[eventId] ?? {'interested': 0, 'going': 0, 'not_going': 0}
        : {'interested': 0, 'going': 0, 'not_going': 0};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            Text(
              event.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 12),

            // RSVP Counts - only show if event has valid ID
            if (hasValidId)
              Row(
                children: [
                  _buildRSVPCount('Going', counts['going'] ?? 0, Colors.green),
                  const SizedBox(width: 16),
                  _buildRSVPCount(
                    'Interested',
                    counts['interested'] ?? 0,
                    Colors.orange,
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // RSVP Buttons - only show if event has valid ID
            if (hasValidId && _currentUserId != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRSVPButton(
                    'Going',
                    EventRepository.RSVP_GOING,
                    userRSVP == EventRepository.RSVP_GOING,
                    Colors.green,
                    eventId!,
                  ),
                  _buildRSVPButton(
                    'Interested',
                    EventRepository.RSVP_INTERESTED,
                    userRSVP == EventRepository.RSVP_INTERESTED,
                    Colors.orange,
                    eventId!,
                  ),
                  _buildRSVPButton(
                    'Not Going',
                    EventRepository.RSVP_NOT_GOING,
                    userRSVP == EventRepository.RSVP_NOT_GOING,
                    Colors.red,
                    eventId!,
                  ),
                ],
              )
            else if (!hasValidId)
              Center(
                child: Text(
                  'RSVP not available for this event',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            else
              Center(
                child: Text(
                  'Login to RSVP',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRSVPButton(
    String label,
    String rsvpType,
    bool isSelected,
    Color color,
    String eventId,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            if (isSelected) {
              _removeRSVP(eventId);
            } else {
              _handleRSVP(eventId, rsvpType);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildRSVPCount(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Going' ? Icons.check_circle : Icons.thumb_up,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
}
