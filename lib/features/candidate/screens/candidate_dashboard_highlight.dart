import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/edit/highlight_tab_edit_refactored.dart';
import '../widgets/view/highlight_tab_view.dart';
import '../../../widgets/loading_overlay.dart';

class CandidateDashboardHighlight extends StatefulWidget {
  const CandidateDashboardHighlight({super.key});

  @override
  State<CandidateDashboardHighlight> createState() =>
      _CandidateDashboardHighlightState();
}

class _CandidateDashboardHighlightState
    extends State<CandidateDashboardHighlight> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

  // Global key to access highlight section for file uploads
  final GlobalKey<HighlightTabEditState> _highlightSectionKey =
      GlobalKey<HighlightTabEditState>();

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
          title: const Text('Highlight'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: isEditing
            ? SingleChildScrollView(
                child: HighlightTabEdit(
                  key: _highlightSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onHighlightChange: (highlight) =>
                      controller.updateExtraInfo('highlight', highlight),
                ),
              )
            : HighlightTabView(
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
                      heroTag: 'save_highlight',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save highlight...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save highlight...',
                          messageStream: messageController.stream,
                        );

                        try {
                          // First, upload any pending local files to Firebase
                          final highlightSectionState =
                              _highlightSectionKey.currentState;
                          if (highlightSectionState != null) {
                            messageController.add(
                              'Uploading files to cloud...',
                            );
                            await highlightSectionState.uploadPendingFiles();
                          }

                          // Then save the highlight data
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add(
                              'Highlight saved successfully!',
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
                                'Highlight updated successfully',
                                backgroundColor: Colors.green.shade100,
                                colorText: Colors.green.shade800,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar(
                                'Error',
                                'Failed to update highlight',
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
                      heroTag: 'cancel_highlight',
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
                  heroTag: 'edit_highlight',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Highlight',
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}
