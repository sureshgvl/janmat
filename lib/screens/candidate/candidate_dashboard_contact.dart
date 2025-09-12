import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/contact_section.dart';
import '../../widgets/loading_overlay.dart';

class CandidateDashboardContact extends StatefulWidget {
  const CandidateDashboardContact({super.key});

  @override
  State<CandidateDashboardContact> createState() => _CandidateDashboardContactState();
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
        appBar: AppBar(
          title: const Text('Contact'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Contact',
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.save),
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
                          onProgress: (message) => messageController.add(message),
                        );

                        if (success) {
                          // Update progress: Success
                          messageController.add('Contact saved successfully!');

                          // Wait a moment to show success message
                          await Future.delayed(const Duration(milliseconds: 800));

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            setState(() => isEditing = false);
                            Get.snackbar('Success', 'Contact updated successfully');
                          }
                        } else {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
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
                    tooltip: 'Save Changes',
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
          child: ContactSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onContactChange: (field, value) => controller.updateContact(field, value),
            onSocialChange: (field, value) => controller.updateContact('social_$field', value),
          ),
        ),
      );
    });
  }
}