import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';

class AchievementsSection extends StatelessWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<String>) onAchievementsChange;

  const AchievementsSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onAchievementsChange,
  });

  @override
  Widget build(BuildContext context) {
    final data = editedData ?? candidateData;
    final achievements = data.extraInfo?.achievements ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isEditing)
              TextFormField(
                initialValue: achievements.join('\n'),
                decoration: const InputDecoration(
                  labelText: 'Achievements (one per line)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                onChanged: (value) {
                  final list = value.split('\n').where((e) => e.isNotEmpty).toList();
                  onAchievementsChange(list);
                },
              )
            else
              achievements.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: achievements.map((achievement) => Text('• $achievement')).toList(),
                    )
                  : const Text('No achievements available'),
          ],
        ),
      ),
    );
  }
}