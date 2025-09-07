import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class HighlightSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(bool) onHighlightChange;

  const HighlightSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onHighlightChange,
  });

  @override
  Widget build(BuildContext context) {
    final data = editedData ?? candidateData;
    final highlight = data.extraInfo?.highlight ?? false;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Highlight',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing)
              SwitchListTile(
                title: const Text('Enable Premium Highlight'),
                value: highlight,
                onChanged: onHighlightChange,
              )
            else
              Text('Premium Highlight: ${highlight ? 'Enabled' : 'Disabled'}'),
          ],
        ),
      ),
    );
  }
}