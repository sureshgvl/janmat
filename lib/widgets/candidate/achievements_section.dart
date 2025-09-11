import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../models/achievement_model.dart';
import '../../services/file_upload_service.dart';
import 'demo_data_modal.dart';

class AchievementsSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Achievement>) onAchievementsChange;

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
  late List<Achievement> _achievements;
  final FileUploadService _fileUploadService = FileUploadService();

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  @override
  void didUpdateWidget(AchievementsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      _loadAchievements();
    }
  }

  void _loadAchievements() {
    final data = widget.editedData ?? widget.candidateData;
    _achievements = List.from(data.extraInfo?.achievements ?? []);
  }

  void _updateAchievements() {
    widget.onAchievementsChange(_achievements);
  }

  void _addAchievement() {
    setState(() {
      _achievements.add(Achievement(
        title: '',
        description: '',
        year: DateTime.now().year,
      ));
    });
    _updateAchievements();
  }

  void _removeAchievement(int index) {
    setState(() {
      _achievements.removeAt(index);
    });
    _updateAchievements();
  }

  void _updateAchievement(int index, Achievement achievement) {
    setState(() {
      _achievements[index] = achievement;
    });
    _updateAchievements();
  }

  void _reorderAchievements(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _achievements.removeAt(oldIndex);
      _achievements.insert(newIndex, item);
    });
    _updateAchievements();
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Achievement'),
        content: const Text('Are you sure you want to delete this achievement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _removeAchievement(index);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPhoto(int index) async {
    try {
      final candidateId = widget.candidateData.candidateId;
      final achievement = _achievements[index];
      final photoUrl = await _fileUploadService.uploadAchievementPhoto(
        candidateId,
        achievement.title,
      );

      if (photoUrl != null) {
        _updateAchievement(
          index,
          achievement.copyWith(photoUrl: photoUrl),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isEditing)
                  Row(
                    children: [
                      IconButton(
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
                                if (selectedData is List<Achievement>) {
                                  setState(() {
                                    _achievements = selectedData;
                                  });
                                  _updateAchievements();
                                }
                              },
                            ),
                          );
                        },
                        tooltip: 'Use demo achievements',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addAchievement,
                        tooltip: 'Add achievement',
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_achievements.isEmpty && !widget.isEditing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No achievements available')),
              )
            else if (_achievements.isEmpty && widget.isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      const Text('No achievements yet. Add your first achievement!'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addAchievement,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Achievement'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(_achievements.length, (index) {
                      final achievement = _achievements[index];
                      return Card(
                        key: widget.isEditing ? ValueKey(achievement.title + index.toString()) : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.isEditing)
                                Row(
                                  children: [
                                    if (achievement.photoUrl != null)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: NetworkImage(achievement.photoUrl!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: achievement.title,
                                        decoration: const InputDecoration(
                                          labelText: 'Title',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          _updateAchievement(
                                            index,
                                            achievement.copyWith(title: value),
                                          );
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteConfirmation(index),
                                      tooltip: 'Remove achievement',
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  achievement.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (widget.isEditing)
                                TextFormField(
                                  initialValue: achievement.description,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  onChanged: (value) {
                                    _updateAchievement(
                                      index,
                                      achievement.copyWith(description: value),
                                    );
                                  },
                                )
                              else
                                Text(achievement.description),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (widget.isEditing)
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: achievement.year.toString(),
                                        decoration: const InputDecoration(
                                          labelText: 'Year',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final year = int.tryParse(value) ?? achievement.year;
                                          _updateAchievement(
                                            index,
                                            achievement.copyWith(year: year),
                                          );
                                        },
                                      ),
                                    )
                                  else
                                    Text(
                                      'Year: ${achievement.year}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              if (achievement.photoUrl != null && achievement.photoUrl!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        insetPadding: const EdgeInsets.all(10),
                                        child: Container(
                                          width: double.infinity,
                                          height: MediaQuery.of(context).size.height * 0.8,
                                          child: InteractiveViewer(
                                            minScale: 0.5,
                                            maxScale: 4.0,
                                            child: Image.network(
                                              achievement.photoUrl!,
                                              fit: BoxFit.contain,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(child: CircularProgressIndicator());
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Center(
                                                  child: Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 48,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                      image: DecorationImage(
                                        image: NetworkImage(achievement.photoUrl!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton.icon(
                                    onPressed: () => _uploadPhoto(index),
                                    icon: const Icon(Icons.photo_camera),
                                    label: Text(achievement.photoUrl != null ? 'Change Photo' : 'Add Photo (Optional)'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}