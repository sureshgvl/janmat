import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/manifesto_section.dart';
import '../../widgets/common/save_button.dart';
import '../../widgets/loading_overlay.dart';

class CandidateDashboardManifesto extends StatefulWidget {
  const CandidateDashboardManifesto({super.key});

  @override
  State<CandidateDashboardManifesto> createState() => _CandidateDashboardManifestoState();
}

class _CandidateDashboardManifestoState extends State<CandidateDashboardManifesto> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;
  bool isSaving = false;

  // Global key to access manifesto section for file uploads
  final GlobalKey<ManifestoSectionState> _manifestoSectionKey = GlobalKey<ManifestoSectionState>();

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
          title: const Text('Manifesto'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Manifesto',
              )
            else
              Row(
                children: [
                  SaveButton(
                    isSaving: isSaving,
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
                        final manifestoSectionState = _manifestoSectionKey.currentState;
                        if (manifestoSectionState != null) {
                          messageController.add('Uploading files to cloud...');
                          await manifestoSectionState.uploadPendingFiles();
                        }

                        // Then save the manifesto data
                        final success = await controller.saveExtraInfo(
                          onProgress: (message) => messageController.add(message),
                        );

                        if (success) {
                          // Update progress: Success
                          messageController.add('Manifesto saved successfully!');

                          // Wait a moment to show success message
                          await Future.delayed(const Duration(milliseconds: 800));

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            setState(() => isEditing = false);
                            Get.snackbar('Success', 'Manifesto updated successfully');
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar('Error', 'Failed to update manifesto');
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
        body: SingleChildScrollView(
          child: ManifestoSection(
            key: _manifestoSectionKey,
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onManifestoChange: (manifesto) => controller.updateExtraInfo('manifesto', manifesto),
            onManifestoPdfChange: (pdf) => controller.updateExtraInfo('manifesto_pdf', pdf),
            onManifestoTitleChange: (title) => controller.updateExtraInfo('manifesto_title', title),
            onManifestoPromisesChange: (List<Map<String, dynamic>> manifestoPromises) => controller.updateExtraInfo('manifesto_promises', manifestoPromises),
            onManifestoImageChange: (image) => controller.updateExtraInfo('manifesto_image', image),
            onManifestoVideoChange: (video) => controller.updateExtraInfo('manifesto_video', video),
          ),
        ),
      );
    });
  }
}
