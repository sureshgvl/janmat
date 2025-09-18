import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_data_controller.dart';
import '../../../services/plan_service.dart';
import '../widgets/edit/candidate_manifesto_tab_edit.dart';
import '../widgets/view/manifesto_tab_view.dart';
import '../../../widgets/loading_overlay.dart';

class CandidateDashboardManifesto extends StatefulWidget {
  const CandidateDashboardManifesto({super.key});

  @override
  State<CandidateDashboardManifesto> createState() =>
      _CandidateDashboardManifestoState();
}

class _CandidateDashboardManifestoState
    extends State<CandidateDashboardManifesto> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;
  bool isSaving = false;
  bool canEditManifesto = false;

  // Global key to access manifesto section for file uploads
  final GlobalKey<ManifestoTabEditState> _manifestoSectionKey =
      GlobalKey<ManifestoTabEditState>();

  @override
  void initState() {
    super.initState();
    _loadPlanPermissions();
  }

  Future<void> _loadPlanPermissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      canEditManifesto = await PlanService.canEditManifesto(currentUser.uid);
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
                child: ManifestoTabEdit(
                  key: _manifestoSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onManifestoChange: (manifesto) =>
                      controller.updateExtraInfo('manifesto', manifesto),
                  onManifestoPdfChange: (pdf) =>
                      controller.updateExtraInfo('manifesto_pdf', pdf),
                  onManifestoTitleChange: (title) =>
                      controller.updateExtraInfo('manifesto_title', title),
                  onManifestoPromisesChange:
                      (List<Map<String, dynamic>> manifestoPromises) =>
                          controller.updateExtraInfo(
                            'manifesto_promises',
                            manifestoPromises,
                          ),
                  onManifestoImageChange: (image) =>
                      controller.updateExtraInfo('manifesto_image', image),
                  onManifestoVideoChange: (video) =>
                      controller.updateExtraInfo('manifesto_video', video),
                ),
              )
            : ManifestoTabView(
                candidate: controller.candidateData.value!,
                isOwnProfile: true,
                showVoterInteractions:
                    false, // Hide voter interactions in dashboard
              ),
        floatingActionButton: canEditManifesto ? (isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_manifesto',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save manifesto...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save manifesto...',
                          messageStream: messageController.stream,
                        );

                        try {
                          // First, upload any pending local files to Firebase/Cloudinary
                          final manifestoSectionState =
                              _manifestoSectionKey.currentState;
                          if (manifestoSectionState != null) {
                            messageController.add(
                              'Uploading files to cloud...',
                            );
                            await manifestoSectionState.uploadPendingFiles();
                          }

                          // Then save the manifesto data
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add(
                              'Manifesto saved successfully!',
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
                                'Manifesto updated successfully',
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
                                'Failed to update manifesto',
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
                      heroTag: 'cancel_manifesto',
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
                  heroTag: 'edit_manifesto',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Manifesto',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}
