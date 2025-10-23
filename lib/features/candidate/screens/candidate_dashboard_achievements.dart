import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_user_controller.dart';
import '../../../services/plan_service.dart';
import '../widgets/edit/achievements/achievements_edit.dart';
import '../../../widgets/loading_overlay.dart';

class CandidateDashboardAchievements extends StatefulWidget {
  const CandidateDashboardAchievements({super.key});

  @override
  State<CandidateDashboardAchievements> createState() =>
      _CandidateDashboardAchievementsState();
}

class _CandidateDashboardAchievementsState
    extends State<CandidateDashboardAchievements> {
  final CandidateUserController controller = CandidateUserController.to;
  bool isEditing = false;
  bool isSaving = false;
  bool canDisplayAchievements = false;

  // Global key to access achievements section for file uploads
  final GlobalKey<AchievementsTabEditState> _achievementsSectionKey =
      GlobalKey<AchievementsTabEditState>();

  @override
  void initState() {
    super.initState();
    _loadPlanPermissions();
  }

  Future<void> _loadPlanPermissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      canDisplayAchievements = await PlanService.canDisplayAchievements(currentUser.uid);
      if (mounted) setState(() {});
    }
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
        body: isEditing
            ? SingleChildScrollView(
                child: AchievementsTabEdit(
                  key: _achievementsSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onAchievementsChange: (achievements) =>
                      controller.updateExtraInfo('achievements', achievements),
                ),
              )
            : AchievementsSection(
                candidateData: controller.candidateData.value!,
                editedData: null,
                isEditing: false,
                onAchievementsChange: (value) {},
              ),
        floatingActionButton: canDisplayAchievements ? (isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_achievements',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add(
                          'Preparing to save achievements...',
                        );

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save achievements...',
                          messageStream: messageController.stream,
                        );

                        try {
                          // First, upload any pending local files to Firebase
                          final achievementsSectionState =
                              _achievementsSectionKey.currentState;
                          if (achievementsSectionState != null) {
                            messageController.add(
                              'Uploading photos to cloud...',
                            );
                            await achievementsSectionState.uploadPendingFiles();
                          }

                          // Then save the achievements data
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add(
                              'Achievements saved successfully!',
                            );

                            // Wait a moment to show success message
                            await Future.delayed(
                              const Duration(milliseconds: 800),
                            );

                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              setState(() => isEditing = false);
                              Get.snackbar(
                                'Success',
                                'Achievements updated successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar(
                                'Error',
                                'Failed to update achievements',
                              );
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
                      backgroundColor: Colors.green,
                      tooltip: 'Save Changes',
                      child: const Icon(Icons.save, size: 28),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'cancel_achievements',
                      onPressed: () {
                        controller.resetEditedData();
                        setState(() => isEditing = false);
                      },
                      backgroundColor: Colors.red,
                      tooltip: 'Cancel',
                      child: const Icon(Icons.cancel, size: 28),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  heroTag: 'edit_achievements',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Achievements',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}
