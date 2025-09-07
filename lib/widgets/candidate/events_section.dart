import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class EventsSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Map<String, dynamic>>) onEventsChange;

  const EventsSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onEventsChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Events management to be implemented'),
            if (isEditing)
              ElevatedButton(
                onPressed: () => onEventsChange([{'title': 'Sample Event', 'date': '2025-01-01'}]),
                child: const Text('Add Event'),
              ),
          ],
        ),
      ),
    );
  }
}