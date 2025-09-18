import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/edit/candidate_contact_tab_edit.dart';
import '../../../widgets/loading_overlay.dart';

class CandidateDashboardContact extends StatefulWidget {
  const CandidateDashboardContact({super.key});

  @override
  State<CandidateDashboardContact> createState() =>
      _CandidateDashboardContactState();
}

class _CandidateDashboardContactState extends State<CandidateDashboardContact> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;
  bool isSaving = false;

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
        body: SingleChildScrollView(
          child: ContactSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onContactChange: (field, value) =>
                controller.updateContact(field, value),
            onSocialChange: (field, value) =>
                controller.updateContact('social_$field', value),
          ),
        ),
        floatingActionButton: isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_contact',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save contact...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save contact...',
                          messageStream: messageController.stream,
                        );

                        try {
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) =>
                                messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add(
                              'Contact saved successfully!',
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
                                'Contact updated successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pop(); // Close loading dialog
                              Get.snackbar('Error', 'Failed to update contact');
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
                      heroTag: 'cancel_contact',
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
                  heroTag: 'edit_contact',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Contact',
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}
