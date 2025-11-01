import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../controllers/candidate_user_controller.dart';
import '../controllers/manifesto_controller.dart';
import '../../monetization/services/plan_service.dart';
import '../widgets/edit/manifesto/manifesto_edit.dart';
import '../widgets/view/manifesto/manifesto_view.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../utils/app_logger.dart';

class CandidateDashboardManifesto extends StatefulWidget {
  const CandidateDashboardManifesto({super.key});

  @override
  State<CandidateDashboardManifesto> createState() =>
      _CandidateDashboardManifestoState();
}

class _CandidateDashboardManifestoState
    extends State<CandidateDashboardManifesto> {
  final CandidateUserController controller = CandidateUserController.to;
  final ManifestoController manifestoController = Get.put(ManifestoController());
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
    final localizations = CandidateLocalizations.of(context)!;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return Center(child: Text(localizations.translate('candidateDataNotFound')));
      }

      return Scaffold(
        body: SingleChildScrollView(
          child: isEditing
              ? ManifestoTabEdit(
                  key: _manifestoSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onManifestoChange: (manifesto) =>
                      controller.updateManifestoInfo('title', manifesto),
                  onManifestoPdfChange: (pdf) =>
                      controller.updateManifestoInfo('pdfUrl', pdf),
                  onManifestoTitleChange: (title) =>
                      controller.updateManifestoInfo('title', title),
                  onManifestoPromisesChange:
                      (List<Map<String, dynamic>> manifestoPromises) =>
                          controller.updateManifestoInfo(
                            'promises',
                            manifestoPromises,
                          ),
                  onManifestoImageChange: (image) =>
                      controller.updateManifestoInfo('image', image),
                  onManifestoVideoChange: (video) =>
                      controller.updateManifestoInfo('videoUrl', video),
                )
              : ManifestoTabView(
                  candidate: controller.candidateData.value!,
                  isOwnProfile: true,
                  showVoterInteractions:
                      true, // Show voter interactions so candidate can see how it looks to voters
                ),
        ),
        floatingActionButton: canEditManifesto ? (isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_manifesto',
                      onPressed: isSaving ? null : () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add(
                          'Preparing to save manifesto...',
                        );

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save manifesto...',
                          messageStream: messageController.stream,
                        );

                        try {
                          final uploadSuccess = await _manifestoSectionKey.currentState!.uploadPendingFiles();
                          if (!uploadSuccess) {
                            AppLogger.candidate(
                              '❌ [MANIFESTO_SAVE] File upload failed',
                              tag: 'DASHBOARD_SAVE_MANIFESTO',
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              Get.snackbar(
                                'Error',
                                'Failed to upload files. Please try again.',
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            }
                            return;
                          }

                          AppLogger.candidate(
                            '✅ [MANIFESTO_SAVE] Files uploaded successfully, now getting manifesto data...',
                            tag: 'DASHBOARD_SAVE_MANIFESTO',
                          );

                          // NOW get the manifesto data from the form (URLs should be updated by upload callbacks)
                          final manifestoData = _manifestoSectionKey.currentState!.getManifestoData();

                          AppLogger.candidate(
                            '📝 [MANIFESTO_SAVE] Manifesto data from form after uploads: title="${manifestoData.title}", pdfUrl="${manifestoData.pdfUrl?.isNotEmpty == true ? 'SET' : 'null'}", image="${manifestoData.image?.isNotEmpty == true ? 'SET' : 'null'}", video="${manifestoData.videoUrl?.isNotEmpty == true ? 'SET' : 'null'}", promises=${manifestoData.promises?.length ?? 0}',
                            tag: 'DASHBOARD_SAVE_MANIFESTO',
                          );

                          // Use editedData if available (contains uploaded file updates), otherwise fallback to candidateData
                          final candidate =
                              controller.editedData.value ??
                              controller.candidateData.value!;

                          final success = await manifestoController
                              .saveManifestoTab(
                                candidateId: candidate.candidateId,
                                candidate: candidate,
                                manifesto: manifestoData,
                                onProgress: (message) =>
                                    messageController.add(message),
                              );

                          if (success) {
                            AppLogger.candidate(
                              '🎉 [MANIFESTO_SAVE] Save operation successful!',
                              tag: 'DASHBOARD_SAVE_MANIFESTO',
                            );
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

                              // Update the candidate data with the saved manifesto for immediate view update
                              controller.candidateData.value = candidate.copyWith(
                                manifestoData: manifestoData,
                              );

                              setState(() => isEditing = false);
                              Get.snackbar(
                                'Success',
                                'Manifesto updated successfully',
                                backgroundColor: Colors.green.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          } else {
                            AppLogger.candidate(
                              '❌ [MANIFESTO_SAVE] Save operation failed',
                              tag: 'DASHBOARD_SAVE_MANIFESTO',
                            );

                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar(
                                'Error',
                                'Failed to update manifesto',
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            }
                          }
                        } catch (e) {
                          AppLogger.candidateError('❌ [MANIFESTO_SAVE] Exception during save',
                            tag: 'DASHBOARD_SAVE_MANIFESTO', error: e);
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar(
                              'Error',
                              'An error occurred: $e',
                              backgroundColor: Colors.red.shade600,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                            );
                          }
                        } finally {
                          // Clean up the stream controller
                          await messageController.close();
                        }
                      }, //onpress
                      backgroundColor: Colors.green,
                      tooltip: 'Save Manifesto',
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
                  onPressed: () {
                    setState(() => isEditing = true);
                    controller.editedData.value =
                        controller.candidateData.value;
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Manifesto',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}
