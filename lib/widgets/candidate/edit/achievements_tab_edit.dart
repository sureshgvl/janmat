import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/candidate_model.dart';
import '../../../models/achievement_model.dart';
import '../../../services/file_upload_service.dart';
import '../../common/reusable_image_widget.dart';
import '../demo_data_modal.dart';

class AchievementsSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Achievement>) onAchievementsChange;
  final Function()? onCancelEditing; // Callback for cleanup when editing is cancelled

  const AchievementsSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onAchievementsChange,
    this.onCancelEditing,
  });

  @override
  State<AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<AchievementsSection> {
  late List<Achievement> _achievements;
  final FileUploadService _fileUploadService = FileUploadService();
  final Map<int, bool> _uploadingPhotos = {}; // Track uploading state per achievement
  final Set<String> _uploadedPhotoUrls = {}; // Track photos uploaded in this session

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

    // Check if editing was cancelled (isEditing changed from true to false)
    if (oldWidget.isEditing && !widget.isEditing && widget.onCancelEditing != null) {
      _cleanupDanglingPhotos();
    }
  }

  @override
  void dispose() {
    // Cleanup any dangling photos when the widget is disposed
    _cleanupDanglingPhotos();
    super.dispose();
  }

  void _loadAchievements() {
    final data = widget.editedData ?? widget.candidateData;
    _achievements = List.from(data.extraInfo?.achievements ?? []);

    // Track existing photo URLs to avoid deleting them during cleanup
    _uploadedPhotoUrls.clear();
    for (final achievement in _achievements) {
      if (achievement.photoUrl != null && achievement.photoUrl!.isNotEmpty) {
        _uploadedPhotoUrls.add(achievement.photoUrl!);
      }
    }
  }

  void _updateAchievements() {
    widget.onAchievementsChange(_achievements);
  }

  // Cleanup dangling photos when editing is cancelled
  Future<void> _cleanupDanglingPhotos() async {
    try {
      // Clean up all temporary local photos since editing was cancelled
      await _fileUploadService.cleanupTempPhotos();
      debugPrint('🗑️ Cleaned up all temporary local photos');

      // Clear the tracking set
      _uploadedPhotoUrls.clear();
    } catch (e) {
      debugPrint('❌ Error during photo cleanup: $e');
    }
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
    setState(() {
      _uploadingPhotos[index] = true;
    });

    try {
      final candidateId = widget.candidateData.candidateId;
      final achievement = _achievements[index];

      // First, save photo locally with optimization
      final localPath = await _fileUploadService.savePhotoLocally(
        candidateId,
        achievement.title,
      );

      if (localPath == null) return;

      // Validate file size and show warnings if needed
      final validation = await _fileUploadService.validateFileSize(localPath);

      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Show warning for large files
      if (validation.warning) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Large File Warning'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(validation.message),
                if (validation.recommendation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    validation.recommendation!,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Choose Different Photo'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue Anyway'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }

      // Track this local photo path
      _uploadedPhotoUrls.add(localPath);

      _updateAchievement(
        index,
        achievement.copyWith(photoUrl: localPath),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved locally')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save photo: $e')),
      );
    } finally {
      setState(() {
        _uploadingPhotos[index] = false;
      });
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
                                ReusableImageWidget(
                                  imageUrl: achievement.photoUrl!,
                                  isLocal: _fileUploadService.isLocalPath(achievement.photoUrl!),
                                  fit: BoxFit.contain,
                                  minHeight: 120,
                                  maxHeight: 200,
                                  borderColor: Colors.grey.shade300,
                                  fullScreenTitle: 'Achievement Photo',
                                ),
                              ],
                              if (widget.isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadingPhotos[index] == true ? null : () => _uploadPhoto(index),
                                    icon: _uploadingPhotos[index] == true
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.photo_camera),
                                    label: Text(_uploadingPhotos[index] == true
                                        ? 'Uploading...'
                                        : (achievement.photoUrl != null ? 'Change Photo' : 'Add Photo (Optional)')),
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
