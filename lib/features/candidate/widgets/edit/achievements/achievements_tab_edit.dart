import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/achievements_model.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/candidate/widgets/demo_data_modal.dart';
import 'package:janmat/features/candidate/controllers/achievements_controller.dart';


// Reusable Achievement Item Widget
class AchievementItemWidget extends StatelessWidget {
  final Achievement achievement;
  final bool isEditing;
  final int index;
  final Function(int, Achievement) onUpdate;
  final Function(int) onDelete;
  final bool isUploading;
  final Function(int) onUploadPhoto;

  const AchievementItemWidget({
    super.key,
    required this.achievement,
    required this.isEditing,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
    required this.isUploading,
    required this.onUploadPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.grey, width: 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditing)
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 40), // Make room for delete button
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievement ${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: achievement.title,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                onUpdate(index, achievement.copyWith(title: value));
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                          onPressed: () => _showDeleteConfirmation(context),
                          tooltip: 'Remove achievement',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
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
                if (isEditing)
                  TextFormField(
                    initialValue: achievement.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      onUpdate(index, achievement.copyWith(description: value));
                    },
                  )
                else
                  Text(achievement.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: TextFormField(
                          initialValue: achievement.year.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final year = int.tryParse(value);
                            final date = year != null ? DateTime(year) : achievement.date;
                            onUpdate(index, achievement.copyWith(date: date));
                          },
                        ),
                      )
                    else
                      Text(
                        'Year: ${achievement.year}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
                if (achievement.photoUrl != null &&
                    achievement.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReusableImageWidget(
                    imageUrl: achievement.photoUrl!,
                    isLocal: FileUploadService().isLocalPath(achievement.photoUrl!),
                    fit: BoxFit.contain,
                    minHeight: 120,
                    maxHeight: 200,
                    borderColor: Colors.grey.shade300,
                    fullScreenTitle: 'Achievement Photo',
                  ),
                ],
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: isUploading ? null : () => onUploadPhoto(index),
                      icon: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera),
                      label: Text(
                        isUploading
                            ? 'Uploading...'
                            : (achievement.photoUrl != null
                                  ? 'Change Photo'
                                  : 'Add Photo (Optional)'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Achievement'),
        content: const Text(
          'Are you sure you want to delete this achievement?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete(index);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Main AchievementsTabEdit Widget
class AchievementsTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Achievement>) onAchievementsChange;

  const AchievementsTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onAchievementsChange,
  });

  @override
  State<AchievementsTabEdit> createState() => AchievementsTabEditState();
}

class AchievementsTabEditState extends State<AchievementsTabEdit> {
  final AchievementsController _achievementsController = Get.find<AchievementsController>();
  late List<Achievement> _achievements;
  final FileUploadService _fileUploadService = FileUploadService();
  final Map<int, bool> _uploadingPhotos = {};
  final Set<String> _uploadedPhotoUrls = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  @override
  void didUpdateWidget(AchievementsTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      _loadAchievements();
    }
  }

  @override
  void dispose() {
    _cleanupDanglingPhotos();
    super.dispose();
  }

  void _loadAchievements() {
    final data = widget.editedData ?? widget.candidateData;
    _achievements = List.from(data.achievements ?? []);

    // 🧹 CLEANUP: Remove any invalid local photo paths before loading
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      if (achievement.photoUrl != null &&
          achievement.photoUrl!.isNotEmpty &&
          _fileUploadService.isLocalPath(achievement.photoUrl!)) {
        try {
          // Remove local paths - they should not persist in database
          AppLogger.candidate('🧹 [Achievements Cleanup] Removing invalid local photo URL: ${achievement.photoUrl}');
          _achievements[i] = achievement.copyWith(photoUrl: null);
        } catch (e) {
          AppLogger.candidateError('❌ [Achievements Cleanup] Error cleaning up local photo path: $e');
        }
      }
    }

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

  Future<void> _cleanupDanglingPhotos() async {
    try {
      await _fileUploadService.cleanupTempPhotos();
      AppLogger.candidate('🗑️ Cleaned up all temporary local photos');
      _uploadedPhotoUrls.clear();
    } catch (e) {
      AppLogger.candidateError('❌ Error during photo cleanup: $e');
    }
  }

  void _addAchievement() {
    setState(() {
      _achievements.add(
        Achievement(id: DateTime.now().millisecondsSinceEpoch.toString(), title: '', description: '', date: DateTime.now()),
      );
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

  final List<Map<String, dynamic>> _localAchievementPhotos = []; // Similar to manifesto's _localFiles

  Future<void> _uploadPhoto(int index) async {
    setState(() {
      _uploadingPhotos[index] = true;
    });

    try {
      final candidateId = widget.candidateData.candidateId;
      final achievement = _achievements[index];

      final localPath = await _fileUploadService.savePhotoLocally(
        candidateId,
        achievement.title,
      );

      if (localPath == null) return;

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

      // Add to _localAchievementPhotos for upload tracking
      _localAchievementPhotos.add({
        'achievementIndex': index,
        'achievement': achievement,
        'localPath': localPath.replaceFirst('local:', ''), // Store clean path like manifesto does
      });

      // Set the achievement photoUrl to the local path so it shows immediately in the UI
      // The cleanup logic will remove this before saving to database to prevent null URLs
      _updateAchievement(index, achievement.copyWith(photoUrl: localPath));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo saved locally'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save photo: $e')));
    } finally {
      setState(() {
        _uploadingPhotos[index] = false;
      });
    }
  }

  /// Get current achievements list from the state (with final cleanup)
  List<Achievement> getAchievements() {
    AppLogger.candidate('📋 [GetAchievements] Called for ${_achievements.length} achievements');

    // Final cleanup: Remove any remaining invalid local photo paths
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      AppLogger.candidate('🔍 [GetAchievements] Checking ${achievement.title}: photoUrl=${achievement.photoUrl}');

      if (achievement.photoUrl != null &&
          achievement.photoUrl!.isNotEmpty &&
          _fileUploadService.isLocalPath(achievement.photoUrl!)) {
        AppLogger.candidate('🧹 [GetAchievements] Final cleanup removing local photo URL: ${achievement.photoUrl} for ${achievement.title}');
        _achievements[i] = achievement.copyWith(photoUrl: null);
        AppLogger.candidate('✅ [GetAchievements] Set to null for ${achievement.title}');
      } else {
        AppLogger.candidate('⏭️ [GetAchievements] Keeping ${achievement.title} photoUrl: ${achievement.photoUrl}');
      }
    }

    AppLogger.candidate('📋 [GetAchievements] Returning ${_achievements.length} achievements with cleaned photoUrls');
    return List.from(_achievements);
  }

  Future<void> uploadPendingFiles() async {
    if (_localAchievementPhotos.isEmpty) {
      AppLogger.candidate('📤 [Achievements] No local photos to upload');
      return;
    }

    AppLogger.candidate('📤 [Achievements] Starting upload of ${_localAchievementPhotos.length} pending achievement photos...');

    final Map<int, String> uploadedUrls = {};

    for (final localPhoto in _localAchievementPhotos) {
      try {
        final achievementIndex = localPhoto['achievementIndex'] as int;
        final achievement = localPhoto['achievement'] as Achievement;
        final localPath = localPhoto['localPath'] as String;

        AppLogger.candidate('📤 [Achievements] Processing local photo for achievement: ${achievement.title}');

        // Create storage path like the manifesto approach
        final sanitizedTitle = achievement.title
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_');
        final fileName =
            'achievement_${widget.candidateData.candidateId}_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'achievements/$fileName';

        AppLogger.candidate('📄 [Achievements] Storage path: $storagePath');

        // Create file from local path (no need to strip prefix - it's already clean)
        final file = File(localPath);
        final downloadUrl = await _uploadFileToFirebase(file, localPath, fileName, storagePath);

        AppLogger.candidate('🔗 [Achievements] Upload result URL: $downloadUrl');

        if (downloadUrl != null) {
          uploadedUrls[achievementIndex] = downloadUrl;
          AppLogger.candidate('✅ [Achievements] Successfully uploaded photo for: ${achievement.title}');

          // Clean up the local file after successful upload
          await _cleanupLocalFile(localPath);
        }
      } catch (e) {
        AppLogger.candidateError('❌ [Achievements] Failed to upload photo: $e');
        // Continue with other photos - don't fail the entire operation
      }
    }

    // Clear the local photos list after processing
    setState(() => _localAchievementPhotos.clear());

    // Update achievements with uploaded URLs
    if (uploadedUrls.isNotEmpty) {
      AppLogger.candidate('🔄 [Achievements] Updating ${uploadedUrls.length} achievements with Firebase URLs');

      for (final entry in uploadedUrls.entries) {
        final achievementIndex = entry.key;
        final firebaseUrl = entry.value;

        if (achievementIndex < _achievements.length) {
          final updatedAchievement = _achievements[achievementIndex].copyWith(photoUrl: firebaseUrl);
          _updateAchievement(achievementIndex, updatedAchievement);
          AppLogger.candidate('✅ [Achievements] Updated achievement $achievementIndex with Firebase URL');
        }
      }
    }

    AppLogger.candidate('✅ [Achievements] Finished uploading pending photos');
  }

  Future<String?> _uploadFileToFirebase(File file, String localPath, String fileName, String storagePath) async {
    try {
      // Use Firebase Storage directly like the manifesto approach
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': widget.candidateData.userId ?? 'unknown',
            'uploadTime': DateTime.now().toIso8601String(),
            'fileType': 'achievement_photo',
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.candidateError('❌ [Achievements] Failed to upload file to Firebase: $e');
      return null;
    }
  }

  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.candidateError('❌ [Achievements] Failed to cleanup local file $localPath: $e');
    }
  }

  // Helper method to check if a file exists on disk
  Future<bool> _fileExists(String filePath) async {
    try {
      // Extract actual file path from local: prefix
      final actualPath = filePath.replaceFirst('local:', '');

      AppLogger.candidate('🔍 [FileExists] Checking file: $actualPath');

      final file = File(actualPath);
      final exists = await file.exists();

      AppLogger.candidate('📋 [FileExists] File exists at $actualPath: $exists');

      if (exists) {
        // Additional check: Are there any permissions issues or file size validation?
        try {
          final fileSize = await file.length();
          AppLogger.candidate('📏 [FileExists] File size: $fileSize bytes');

          // File should be readable
          final readable = await file.stat().then((stat) => stat.type == FileSystemEntityType.file);
          AppLogger.candidate('✅ [FileExists] File is readable: $readable');

          if (fileSize == 0) {
            AppLogger.candidate('⚠️ [FileExists] File exists but is empty (0 bytes)');
            return false;
          }

          return readable;
        } catch (e) {
          AppLogger.candidate('❌ [FileExists] Error getting file details: $e');
          return false;
        }
      }

      return false;
    } catch (e) {
      AppLogger.candidate('❌ [FileExists] Exception in _fileExists: $e');
      return false;
    }
  }

  Future<void> _saveAchievements() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.editedData ?? widget.candidateData;

      // 🧹 FINAL CLEANUP: Ensure no local paths make it to database
      for (int i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        if (achievement.photoUrl != null &&
            achievement.photoUrl!.isNotEmpty &&
            _fileUploadService.isLocalPath(achievement.photoUrl!)) {
          AppLogger.candidate('🧹 [SAVE FINAL CLEANUP] Removing local photo URL before saving: ${achievement.photoUrl}');
          _achievements[i] = achievement.copyWith(photoUrl: null);
        }
      }

      // 🧹 ABSOLUTE FINAL CLEANUP: Ensure NO local paths reach the database
      for (int i = 0; i < _achievements.length; i++) {
        if (_achievements[i].photoUrl != null &&
            _fileUploadService.isLocalPath(_achievements[i].photoUrl!)) {
          AppLogger.candidate('🧹 [ABSOLUTE FINAL CLEANUP] Forcing null for: ${_achievements[i].title}');
          _achievements[i] = _achievements[i].copyWith(photoUrl: null);
        }
      }

      // Create AchievementsModel from ABSOLUTELY cleaned form data
      final achievementsModel = AchievementsModel(achievements: _achievements);

      final achievements = achievementsModel.achievements ?? [];
      AppLogger.candidate('💾 [SAVE] ABSOLUTELY CLEANED achievements with ${achievements.length} items');
      for (int i = 0; i < achievements.length; i++) {
        AppLogger.candidate('💾 [SAVE] Item $i: ${achievements[i].title} -> photoUrl: ${achievements[i].photoUrl}');
      }

      // Save using the controller - now follows basic info pattern with candidate
      final success = await _achievementsController.saveAchievementsTab(
        candidate: data,
        achievements: achievementsModel,
        onProgress: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievements saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save achievements'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving achievements: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDemoDataModal() {
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
                    color: Color(0xFF374151),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lightbulb, color: Colors.amber),
                      onPressed: _showDemoDataModal,
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
            if (_achievements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'No achievements yet. Add your first achievement!',
                      ),
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
            Column(
              children: List.generate(_achievements.length, (index) {
                final achievement = _achievements[index];
                return AchievementItemWidget(
                  achievement: achievement,
                  isEditing: widget.isEditing,
                  index: index,
                  onUpdate: _updateAchievement,
                  onDelete: _removeAchievement,
                  isUploading: _uploadingPhotos[index] == true,
                  onUploadPhoto: _uploadPhoto,
                );
              }),
            ),
          const SizedBox(height: 120), // Added 100px bottom padding
          ],
        ),
      ),
    );
  }
}
