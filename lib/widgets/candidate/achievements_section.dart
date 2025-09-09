import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import 'demo_data_modal.dart';

class AchievementsSection extends StatefulWidget {
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
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  late TextEditingController _achievementsController;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    final achievements = data.extraInfo?.achievements ?? [];
    _achievementsController = TextEditingController(text: achievements.join('\n'));
  }

  @override
  void didUpdateWidget(AchievementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      final data = widget.editedData ?? widget.candidateData;
      final achievements = data.extraInfo?.achievements ?? [];
      _achievementsController.text = achievements.join('\n');
    }
  }

  @override
  void dispose() {
    _achievementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;
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
            if (widget.isEditing)
              TextFormField(
                controller: _achievementsController,
                decoration: InputDecoration(
                  labelText: 'Achievements (one per line)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.lightbulb,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DemoDataModal(
                          category: 'achievements',
                          onDataSelected: (selectedData) {
                            _achievementsController.text = selectedData;
                            final list = selectedData.split('\n').where((e) => e.isNotEmpty).toList();
                            widget.onAchievementsChange(list);
                          },
                        ),
                      );
                    },
                    tooltip: 'Use demo achievements',
                  ),
                ),
                maxLines: 5,
                onChanged: (value) {
                  final list = value.split('\n').where((e) => e.isNotEmpty).toList();
                  widget.onAchievementsChange(list);
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