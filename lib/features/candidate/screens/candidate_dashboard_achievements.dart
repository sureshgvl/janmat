import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_user_controller.dart';
import '../../../services/plan_service.dart';
import '../widgets/edit/achievements/achievements_edit.dart';
import '../models/achievements_model.dart';
import '../controllers/achievements_controller.dart';

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
                  onAchievementsChange: controller.updateAchievementsInfo,
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
                        setState(() => isSaving = true);

                        try {
                          // Upload any pending local files to Firebase
                          final achievementsSectionState =
                              _achievementsSectionKey.currentState;
                          if (achievementsSectionState != null) {
                            await achievementsSectionState.uploadPendingFiles();
                          }

                          // Get the achievements data from the widget state and save
                          if (achievementsSectionState != null) {
                            final achievements = achievementsSectionState.getAchievements();
                            final achievementsModel = AchievementsModel(achievements: achievements);

                            // Save achievements using the achievements controller
                            final achievementsController = Get.find<AchievementsController>();
                            final success = await achievementsController.saveAchievementsTabWithCandidate(
                              candidateId: controller.candidateData.value!.candidateId,
                              achievements: achievementsModel,
                              candidate: controller.candidateData.value,
                              onProgress: (message) {},
                            );

                            if (success) {
                              setState(() => isEditing = false);
                              Get.snackbar(
                                'Success',
                                'Achievements updated successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              Get.snackbar(
                                'Error',
                                'Failed to update achievements',
                              );
                            }
                          } else {
                            Get.snackbar('Error', 'Failed to access achievements data');
                          }
                        } catch (e) {
                          Get.snackbar('Error', 'An error occurred: $e');
                        } finally {
                          if (mounted) setState(() => isSaving = false);
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
