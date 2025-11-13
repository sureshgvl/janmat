import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/candidate_model.dart';
import '../../../models/events_model.dart';
import '../../../repositories/candidate_event_repository.dart';
import '../../../services/event_notification_service.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../utils/snackbar_utils.dart';
import '../../../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../../../controllers/background_color_controller.dart';

class VoterEventsSection extends StatefulWidget {
  final Candidate candidateData;

  const VoterEventsSection({super.key, required this.candidateData});

  @override
  State<VoterEventsSection> createState() => _VoterEventsSectionState();
}

class _VoterEventsSectionState extends State<VoterEventsSection> {
  late final EventRepository _eventRepository;
  late final EventNotificationService _notificationService;
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
      SnackbarUtils.showError('Please login to RSVP to events');
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

        SnackbarUtils.showSuccess('RSVP updated successfully!');
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to update RSVP: $e');
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
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to remove RSVP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColorController = Get.find<BackgroundColorController>();

    return Obx(() => Container(
      color: backgroundColorController.currentBackgroundColor.value,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CandidateLocalizations.of(context)!.events,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Get events from candidate's data
                    ..._buildEventsContent(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  List<Widget> _buildEventsContent(BuildContext context) {
    final candidateEvents = widget.candidateData.events ?? [];

    // Separate events into upcoming and completed
    final upcomingEvents = candidateEvents.where((event) => event.isUpcoming()).toList();
    final completedEvents = candidateEvents.where((event) => event.isExpired()).toList();

    if (_isLoadingRSVP && candidateEvents.isEmpty) {
      return [
        const Center(child: CircularProgressIndicator())
      ];
    } else if (candidateEvents.isEmpty) {
      return [
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
                  CandidateLocalizations.of(context)!.noEventsAvailable,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        )
      ];
    } else {
      final List<Widget> content = [];

      // Upcoming Events Section
      if (upcomingEvents.isNotEmpty) {
        content.addAll([
          Text(
            CandidateLocalizations.of(context)!.upcomingEvents,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
          ),
          const SizedBox(height: 12),
          ...upcomingEvents.map((event) => _buildEventCard(event)),
          const SizedBox(height: 24),
        ]);
      }

      // Completed Events Section
      if (completedEvents.isNotEmpty) {
        content.addAll([
          Text(
            CandidateLocalizations.of(context)!.completedEvents,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...completedEvents.map((event) => _buildEventCard(event)),
        ]);
      }

      return content;
    }
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
    final isExpired = event.isExpired();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title with Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isExpired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Upcoming',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

            const SizedBox(height: 12),

            // RSVP Counts - only show if event has valid ID
            if (hasValidId)
              Row(
                children: [
                  _buildRSVPCount(CandidateLocalizations.of(context)!.rsvpGoing, counts['going'] ?? 0, Colors.green),
                  const SizedBox(width: 16),
                  _buildRSVPCount(
                    CandidateLocalizations.of(context)!.rsvpInterested,
                    counts['interested'] ?? 0,
                    Colors.orange,
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // RSVP Buttons - only show if event has valid ID and is not expired
            if (hasValidId && _currentUserId != null && !isExpired)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRSVPButton(
                    CandidateLocalizations.of(context)!.rsvpGoing,
                    EventRepository.RSVP_GOING,
                    userRSVP == EventRepository.RSVP_GOING,
                    Colors.green,
                    eventId,
                  ),
                  _buildRSVPButton(
                    CandidateLocalizations.of(context)!.rsvpInterested,
                    EventRepository.RSVP_INTERESTED,
                    userRSVP == EventRepository.RSVP_INTERESTED,
                    Colors.orange,
                    eventId,
                  ),
                  _buildRSVPButton(
                    CandidateLocalizations.of(context)!.rsvpNotGoing,
                    EventRepository.RSVP_NOT_GOING,
                    userRSVP == EventRepository.RSVP_NOT_GOING,
                    Colors.red,
                    eventId,
                  ),
                ],
              )
            else if (isExpired)
              Center(
                child: Text(
                  CandidateLocalizations.of(context)!.eventExpired,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            else if (!hasValidId)
              Center(
                child: Text(
                  CandidateLocalizations.of(context)!.rsvpNotAvailable,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              )
            else
              Center(
                child: Text(
                  CandidateLocalizations.of(context)!.loginToRsvp,
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
            label == CandidateLocalizations.of(context)!.rsvpGoing ? Icons.check_circle : Icons.thumb_up,
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
      SnackbarUtils.showError('Could not open map link');
    }
  }
}
