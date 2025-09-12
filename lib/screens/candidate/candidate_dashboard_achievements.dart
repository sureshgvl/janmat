import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/achievements_section.dart';
import '../../widgets/common/save_button.dart';
import '../../widgets/loading_overlay.dart';

class CandidateDashboardAchievements extends StatefulWidget {
  const CandidateDashboardAchievements({super.key});

  @override
  State<CandidateDashboardAchievements> createState() => _CandidateDashboardAchievementsState();
}

class _CandidateDashboardAchievementsState extends State<CandidateDashboardAchievements> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;
  bool isSaving = false;

  // Callback for cleanup when editing is cancelled
  Future<void> _onCancelEditing() async {
    // This will be called by the AchievementsSection when editing is cancelled
    debugPrint('🧹 Cleaning up dangling photos on cancel');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return const Center(child: Text('No candidate data found'));
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Achievements',
              )
            else
              Row(
                children: [
                  SaveButton(
                    isSaving: isSaving,
                    onPressed: () async {
                      // Create a stream controller for progress updates
                      final messageController = StreamController<String>();
                      messageController.add('Preparing to save...');

                      // Show loading dialog with message stream
                      LoadingDialog.show(
                        context,
                        initialMessage: 'Preparing to save...',
                        messageStream: messageController.stream,
                      );

                      try {
                        final success = await controller.saveExtraInfo(
                          onProgress: (message) => messageController.add(message),
                        );

                        if (success) {
                          // Update progress: Success
                          messageController.add('Achievements saved successfully!');

                          // Wait a moment to show success message
                          await Future.delayed(const Duration(milliseconds: 800));

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            setState(() => isEditing = false);
                            Get.snackbar('Success', 'Achievements updated successfully');
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar('Error', 'Failed to update achievements');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close loading dialog
                          Get.snackbar('Error', 'An error occurred: $e');
                        }
                      } finally {
                        // Clean up the stream controller
                        await messageController.close();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      controller.resetEditedData();
                      setState(() => isEditing = false);
                    },
                    tooltip: 'Cancel',
                  ),
                ],
              ),
          ],
        ),
        body: AchievementsSection(
          candidateData: controller.candidateData.value!,
          editedData: controller.editedData.value,
          isEditing: isEditing,
          onAchievementsChange: (achievements) => controller.updateExtraInfo('achievements', achievements),
          onCancelEditing: _onCancelEditing,
        ),
      );
    });
  }
}