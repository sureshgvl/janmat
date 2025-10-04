import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

// RSVP Status enum
enum RSVPStatus { none, interested, going, maybe }

class EventsTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;

  const EventsTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
  });

  @override
  State<EventsTabView> createState() => _EventsTabViewState();
}

class _EventsTabViewState extends State<EventsTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // RSVP state for each event
  final Map<int, RSVPStatus> _rsvpStatuses = {};
  final Map<int, int> _interestedCounts = {};
  final Map<int, int> _goingCounts = {};
  final Map<int, int> _maybeCounts = {};

  @override
  void initState() {
    super.initState();
    // Initialize with mock data - in real app this would come from server
    final events = widget.candidate.extraInfo?.events ?? [];
    for (int i = 0; i < events.length; i++) {
      _rsvpStatuses[i] = RSVPStatus.none;
      _interestedCounts[i] = (i + 1) * 5; // Mock data
      _goingCounts[i] = (i + 1) * 3; // Mock data
      _maybeCounts[i] = (i + 1) * 2; // Mock data
    }
  }

  void _updateRSVP(int eventIndex, RSVPStatus newStatus) {
    setState(() {
      final oldStatus = _rsvpStatuses[eventIndex] ?? RSVPStatus.none;

      // Remove from old count
      if (oldStatus == RSVPStatus.interested) {
        _interestedCounts[eventIndex] =
            (_interestedCounts[eventIndex] ?? 0) - 1;
      } else if (oldStatus == RSVPStatus.going) {
        _goingCounts[eventIndex] = (_goingCounts[eventIndex] ?? 0) - 1;
      } else if (oldStatus == RSVPStatus.maybe) {
        _maybeCounts[eventIndex] = (_maybeCounts[eventIndex] ?? 0) - 1;
      }

      // Add to new count
      if (newStatus == RSVPStatus.interested) {
        _interestedCounts[eventIndex] =
            (_interestedCounts[eventIndex] ?? 0) + 1;
      } else if (newStatus == RSVPStatus.going) {
        _goingCounts[eventIndex] = (_goingCounts[eventIndex] ?? 0) + 1;
      } else if (newStatus == RSVPStatus.maybe) {
        _maybeCounts[eventIndex] = (_maybeCounts[eventIndex] ?? 0) + 1;
      }

      _rsvpStatuses[eventIndex] = newStatus;
    });

    String statusText;
    switch (newStatus) {
      case RSVPStatus.interested:
        statusText = 'Interested';
        break;
      case RSVPStatus.going:
        statusText = 'Going';
        break;
      case RSVPStatus.maybe:
        statusText = 'Maybe';
        break;
      case RSVPStatus.none:
        statusText = 'Not interested';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RSVP updated: $statusText'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final events = widget.candidate.extraInfo?.events ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Events Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.event_note_outlined,
                        color: Colors.blue.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Events',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${events.length} event${events.length != 1 ? 's' : ''} scheduled',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Events List
          if (events.isNotEmpty) ...[
            ...events.map((event) {
              final index = events.indexOf(event);
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.red,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ];
              final color = colors[index % colors.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Icon(
                            Icons.event,
                            color: color.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title ?? 'Event ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1f2937),
                                ),
                              ),
                              ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(event.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.shade200),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          event.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                    if (event.venue != null && event.venue!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.venue!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.time != null && event.time!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.time!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // RSVP Section
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RSVP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Interested Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _updateRSVP(
                                    index,
                                    _rsvpStatuses[index] ==
                                            RSVPStatus.interested
                                        ? RSVPStatus.none
                                        : RSVPStatus.interested,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _rsvpStatuses[index] ==
                                              RSVPStatus.interested
                                          ? Colors.blue.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            _rsvpStatuses[index] ==
                                                RSVPStatus.interested
                                            ? Colors.blue.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color:
                                              _rsvpStatuses[index] ==
                                                  RSVPStatus.interested
                                              ? Colors.blue
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Interested',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _rsvpStatuses[index] ==
                                                    RSVPStatus.interested
                                                ? Colors.blue.shade800
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '${_interestedCounts[index] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Going Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _updateRSVP(
                                    index,
                                    _rsvpStatuses[index] == RSVPStatus.going
                                        ? RSVPStatus.none
                                        : RSVPStatus.going,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _rsvpStatuses[index] ==
                                              RSVPStatus.going
                                          ? Colors.green.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            _rsvpStatuses[index] ==
                                                RSVPStatus.going
                                            ? Colors.green.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color:
                                              _rsvpStatuses[index] ==
                                                  RSVPStatus.going
                                              ? Colors.green
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Going',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _rsvpStatuses[index] ==
                                                    RSVPStatus.going
                                                ? Colors.green.shade800
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '${_goingCounts[index] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Maybe Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _updateRSVP(
                                    index,
                                    _rsvpStatuses[index] == RSVPStatus.maybe
                                        ? RSVPStatus.none
                                        : RSVPStatus.maybe,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _rsvpStatuses[index] ==
                                              RSVPStatus.maybe
                                          ? Colors.orange.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            _rsvpStatuses[index] ==
                                                RSVPStatus.maybe
                                            ? Colors.orange.shade300
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.question_mark,
                                          size: 16,
                                          color:
                                              _rsvpStatuses[index] ==
                                                  RSVPStatus.maybe
                                              ? Colors.orange
                                              : Colors.grey[600],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Maybe',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _rsvpStatuses[index] ==
                                                    RSVPStatus.maybe
                                                ? Colors.orange.shade800
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          '${_maybeCounts[index] ?? 0}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // No events placeholder
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      color: Colors.blue.shade400,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Events Scheduled',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upcoming events and activities will be displayed here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

