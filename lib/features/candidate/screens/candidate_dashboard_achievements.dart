import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/snackbar_utils.dart';
import '../controllers/candidate_user_controller.dart';
import '../../monetization/services/plan_service.dart';
import '../widgets/edit/achievements/achievements_tab_edit.dart';
import '../widgets/view/achievements/achievements_tab_view.dart';
import '../models/achievements_model.dart';
import '../controllers/achievements_controller.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../utils/app_logger.dart';

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

  // Global key to access achievements tab edit widget for file uploads and data extraction
  final GlobalKey<AchievementsTabEditState> _achievementsTabEditKey =
      GlobalKey<AchievementsTabEditState>();

  @override
  void initState() {
    super.initState();
    _loadPlanPermissions();
    _ensureCandidateDataLoaded();
  }

  Future<void> _ensureCandidateDataLoaded() async {
    // DEBUG: Log current controller state
    AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] Checking candidate data loading state');
    AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] User: ${controller.user.value?.name} (${controller.user.value?.role})');
    AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] Candidate data exists: ${controller.candidateData.value != null}');
    AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] Controller initialized: ${controller.isInitialized.value}');
    AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] Controller loading: ${controller.isLoading.value}');

      // If candidate data is not loaded and we have a logged in user who should be a candidate, load it
    if (controller.candidateData.value == null && controller.user.value?.role == 'candidate') {
      AppLogger.common('🔄 [DASHBOARD_ACHIEVEMENTS] No candidate data found, initializing...');
      // Initialize candidate data loading if not already done
      if (!controller.isInitialized.value) {
        AppLogger.common('🔄 [DASHBOARD_ACHIEVEMENTS] Controller not initialized, calling initializeForCandidate()');
        controller.initializeForCandidate();
      } else {
        // If initialized but no candidate data, try to refresh
        AppLogger.common('🔄 [DASHBOARD_ACHIEVEMENTS] Controller initialized but no data, calling loadCandidateUserData()');
        await controller.loadCandidateUserData(controller.user.value!.uid);
      }
    } else if (controller.candidateData.value != null && controller.candidateData.value!.achievements == null) {
      // DATA EXISTS but achievements is null - need to refresh from Firebase
      AppLogger.common('🔄 [DASHBOARD_ACHIEVEMENTS] Candidate data exists but achievements null, refreshing...');
      await controller.refreshCandidateData();
    } else {
      AppLogger.common('✅ [DASHBOARD_ACHIEVEMENTS] Candidate data already available or user not candidate');

      // DEBUG: Show what's actually in the candidate data
      AppLogger.common('🔍 [DASHBOARD_ACHIEVEMENTS] Existing candidate data:');
      AppLogger.common('   Name: ${controller.candidateData.value?.basicInfo!.fullName ?? "null"}');
      AppLogger.common('   ID: ${controller.candidateData.value?.candidateId ?? "null"}');
      AppLogger.common('   Achievements count: ${controller.candidateData.value?.achievements?.length ?? "null"}');

      if (controller.candidateData.value?.achievements != null) {
        for (int i = 0; i < (controller.candidateData.value!.achievements!.length); i++) {
          final achievement = controller.candidateData.value!.achievements![i];
          AppLogger.common('   Achievement $i: ${achievement.title} (id: ${achievement.id})');
        }
      }
    }
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
        // Addition: If we're not loading but also don't have candidate data,
        // it means we failed to load it. Show a message with retry option.
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No candidate data found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _ensureCandidateDataLoaded();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        body: isEditing
            ? SingleChildScrollView(
                child: AchievementsTabEdit(
                  key: _achievementsTabEditKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onAchievementsChange: controller.updateAchievementsInfo,
                ),
              )
            : AchievementsTabView(
                candidate: controller.candidateData.value!,
                isOwnProfile: true,
              ),
        floatingActionButton: canDisplayAchievements ? (isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_achievements',
                      onPressed: isSaving ? null : () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save achievements...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save achievements...',
                          messageStream: messageController.stream,
                        );

                        try {
                          AppLogger.candidate(
                            '🔄 [ACHIEVEMENTS_SAVE] Starting achievements save operation',
                            tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                          );

                          // Upload any pending files FIRST (must complete before getting achievements data)
                          AppLogger.candidate(
                            '📤 [ACHIEVEMENTS_SAVE] Uploading pending files first...',
                            tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                          );
                          final achievementsTabEditState = _achievementsTabEditKey.currentState;
                          await achievementsTabEditState!.uploadPendingFiles();

                          AppLogger.candidate(
                            '✅ [ACHIEVEMENTS_SAVE] Files uploaded successfully, now getting achievements data...',
                            tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                          );

                          // Get the achievements data from the widget state
                          final achievements = achievementsTabEditState.getAchievements();
                          final achievementsModel = AchievementsModel(achievements: achievements);

                          AppLogger.candidate(
                            '📝 [ACHIEVEMENTS_SAVE] Achievements data: ${achievements.length} items',
                            tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                          );

                          // Use editedData if available (contains uploaded file updates), otherwise fallback to candidateData
                          final candidate = controller.editedData.value ?? controller.candidateData.value!;

                          final achievementsController = Get.find<AchievementsController>(tag: 'achievements_tab');
                          final success = await achievementsController.saveAchievementsTab(
                            candidate: candidate,
                            achievements: achievementsModel,
                            onProgress: (message) => messageController.add(message),
                          );

                          if (success) {
                            AppLogger.candidate(
                              '🎉 [ACHIEVEMENTS_SAVE] Save operation successful!',
                              tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                            );

                            // Update progress: Success
                            messageController.add('Achievements saved successfully!');

                            // Wait a moment to show success message
                            await Future.delayed(const Duration(milliseconds: 800));

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog

                              // Update the candidate data with the saved achievements for immediate view update
                              controller.candidateData.value = candidate.copyWith(
                                achievements: achievements,
                              );

                              setState(() => isEditing = false);
                              SnackbarUtils.showSuccess('Achievements updated successfully');
                            }
                          } else {
                            AppLogger.candidate(
                              '❌ [ACHIEVEMENTS_SAVE] Save operation failed',
                              tag: 'DASHBOARD_SAVE_ACHIEVEMENTS',
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              SnackbarUtils.showError('Failed to update achievements');
                            }
                          }
                        } catch (e) {
                          AppLogger.candidateError('❌ [ACHIEVEMENTS_SAVE] Exception during save',
                            tag: 'DASHBOARD_SAVE_ACHIEVEMENTS', error: e);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            SnackbarUtils.showError('An error occurred: $e');
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
                  onPressed: () {
                    setState(() => isEditing = true);
                    controller.editedData.value = controller.candidateData.value;
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Achievements',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}
