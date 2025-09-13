import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../repositories/event_repository.dart';

class EventsAnalyticsSection extends StatefulWidget {
  final Candidate candidateData;

  const EventsAnalyticsSection({
    Key? key,
    required this.candidateData,
  }) : super(key: key);

  @override
  State<EventsAnalyticsSection> createState() => _EventsAnalyticsSectionState();
}

class _EventsAnalyticsSectionState extends State<EventsAnalyticsSection> {
  final EventRepository _eventRepository = EventRepository();
  List<EventData> _events = [];
  Map<String, Map<String, int>> _eventCounts = {};
  bool _isLoading = true;

  int _totalInterested = 0;
  int _totalGoing = 0;
  int _totalEvents = 0;

  @override
  void initState() {
    super.initState();
    _loadEventsAnalytics();
  }

  Future<void> _loadEventsAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final events = await _eventRepository.getCandidateEvents(widget.candidateData.candidateId);
      final counts = <String, Map<String, int>>{};

      int totalInterested = 0;
      int totalGoing = 0;

      for (final event in events) {
        if (event.id != null) {
          final eventCounts = await _eventRepository.getEventRSVPCounts(
            widget.candidateData.candidateId,
            event.id!,
          );
          counts[event.id!] = eventCounts;
          totalInterested += eventCounts['interested'] ?? 0;
          totalGoing += eventCounts['going'] ?? 0;
        }
      }

      setState(() {
        _events = events;
        _eventCounts = counts;
        _totalInterested = totalInterested;
        _totalGoing = totalGoing;
        _totalEvents = events.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading events analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.event_available, size: 28, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Events Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Key Metrics Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Events',
                    value: _totalEvents.toString(),
                    icon: Icons.event,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Interested',
                    value: _totalInterested.toString(),
                    icon: Icons.thumb_up,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Going',
                    value: _totalGoing.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Response',
                    value: _totalEvents > 0 ? ((_totalInterested + _totalGoing) / _totalEvents).round().toString() : '0',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Events Performance Section
            const Text(
              'Event Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            if (_events.isEmpty)
              _buildEmptyState()
            else
              _buildEventsList(),

            const SizedBox(height: 24),

            // Event Tips
            _buildEventTips(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events created yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create events to engage with voters!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      children: _events.map((event) {
        final counts = _eventCounts[event.id] ?? {'interested': 0, 'going': 0};
        final totalResponses = (counts['interested'] ?? 0) + (counts['going'] ?? 0);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(event.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (event.time != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.time!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildResponseChip(
                      'Going',
                      counts['going'] ?? 0,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildResponseChip(
                      'Interested',
                      counts['interested'] ?? 0,
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildResponseChip(
                      'Total',
                      totalResponses,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResponseChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTips() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Event Engagement Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem('Create events with clear dates, times, and venues'),
            _buildTipItem('Include Google Maps links for easy navigation'),
            _buildTipItem('Post event updates and reminders'),
            _buildTipItem('Engage with RSVPs by acknowledging responses'),
            _buildTipItem('Follow up after events with photos and feedback'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: Colors.orange[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}