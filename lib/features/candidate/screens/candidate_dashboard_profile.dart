import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/edit/profile_tab_edit.dart';
import '../widgets/view/profile_tab_view.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';

class CandidateDashboardProfile extends StatefulWidget {
  const CandidateDashboardProfile({super.key});

  @override
  State<CandidateDashboardProfile> createState() =>
      _CandidateDashboardProfileState();
}

class _CandidateDashboardProfileState extends State<CandidateDashboardProfile> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

  // Global key to access profile section for file uploads
  final GlobalKey<ProfileTabEditState> _profileSectionKey =
      GlobalKey<ProfileTabEditState>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return Center(child: Text(AppLocalizations.of(context)!.candidateDataNotFound));
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.profile),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: isEditing
            ? SingleChildScrollView(
                child: ProfileTabEdit(
                  key: _profileSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onBioChange: (bio) => controller.updateExtraInfo('bio', bio),
                ),
              )
            : ProfileTabView(
                candidate: controller.candidateData.value!,
                isOwnProfile: true,
              ),
        floatingActionButton: isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_profile',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add(AppLocalizations.of(context)!.preparingToSaveProfile);

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: AppLocalizations.of(context)!.preparingToSaveProfile,
                          messageStream: messageController.stream,
                        );

                        try {
                          // First, upload any pending local files to Firebase
                          final profileSectionState =
                              _profileSectionKey.currentState;
                          if (profileSectionState != null) {
                            messageController.add(
                              AppLocalizations.of(context)!.uploadingFilesToCloud,
                            );
                            await profileSectionState.uploadPendingFiles();
                          }

                          // Then save the profile data
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add(
                              AppLocalizations.of(context)!.profileSavedSuccessfully,
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
                                AppLocalizations.of(context)!.success,
                                AppLocalizations.of(context)!.profileUpdatedSuccessfully,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar(AppLocalizations.of(context)!.error, AppLocalizations.of(context)!.failedToUpdateProfile);
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar(AppLocalizations.of(context)!.error, "${AppLocalizations.of(context)!.anErrorOccurred}: ${e.toString()}");
                          }
                        } finally {
                          // Clean up the stream controller
                          await messageController.close();
                        }
                      },
                      backgroundColor: Colors.green,
                      tooltip: AppLocalizations.of(context)!.saveChanges,
                      child: const Icon(Icons.save, size: 28),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'cancel_profile',
                      onPressed: () {
                        controller.resetEditedData();
                        setState(() => isEditing = false);
                      },
                      backgroundColor: Colors.red,
                      tooltip: AppLocalizations.of(context)!.cancel,
                      child: const Icon(Icons.cancel, size: 28),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  heroTag: 'edit_profile',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: AppLocalizations.of(context)!.editProfile,
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}

