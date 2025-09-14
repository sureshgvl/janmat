import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../utils/symbol_utils.dart';
import '../../widgets/candidate/view/basic_info_tab_view.dart';
import '../../widgets/loading_overlay.dart';
import '../../l10n/app_localizations.dart';

class CandidateDashboardInfo extends StatefulWidget {
  const CandidateDashboardInfo({super.key});

  @override
  State<CandidateDashboardInfo> createState() => _CandidateDashboardInfoState();
}

class _CandidateDashboardInfoState extends State<CandidateDashboardInfo> {
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
          child: BasicInfoSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            getPartySymbolPath: (party) => SymbolUtils.getPartySymbolPath(party, candidate: controller.candidateData.value),
            onNameChange: (value) => controller.updateBasicInfo('name', value),
            onCityChange: (value) => controller.updateBasicInfo('cityId', value),
            onWardChange: (value) => controller.updateBasicInfo('wardId', value),
            onPartyChange: (value) => controller.updateBasicInfo('party', value),
            onPhotoChange: (value) => controller.updatePhoto(value),
            onBasicInfoChange: (field, value) => controller.updateBasicInfo(field, value),
          ),
        ),
        floatingActionButton: isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_info',
                      onPressed: () async {
                        // Create a stream controller for progress updates
                        final messageController = StreamController<String>();
                        messageController.add('Preparing to save basic info...');

                        // Show loading dialog with message stream
                        LoadingDialog.show(
                          context,
                          initialMessage: 'Preparing to save basic info...',
                          messageStream: messageController.stream,
                        );

                        try {
                          final success = await controller.saveExtraInfo(
                            onProgress: (message) => messageController.add(message),
                          );

                          if (success) {
                            // Update progress: Success
                            messageController.add('Basic info saved successfully!');

                            // Wait a moment to show success message
                            await Future.delayed(const Duration(milliseconds: 800));

                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              setState(() => isEditing = false);
                              Get.snackbar(
                                AppLocalizations.of(context)!.success,
                                AppLocalizations.of(context)!.basicInfoUpdatedSuccessfully,
                                backgroundColor: Colors.green.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                                duration: const Duration(seconds: 3),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close loading dialog
                              Get.snackbar(
                                AppLocalizations.of(context)!.error,
                                'Failed to update basic info',
                                backgroundColor: Colors.red.shade600,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close loading dialog
                            Get.snackbar(
                              AppLocalizations.of(context)!.error,
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
                      },
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.save, size: 28),
                      tooltip: 'Save Changes',
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'cancel_info',
                      onPressed: () {
                        controller.resetEditedData();
                        setState(() => isEditing = false);
                      },
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.cancel, size: 28),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  heroTag: 'edit_info',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit, size: 28),
                  tooltip: 'Edit Basic Info',
                ),
              ),
      );
    });
  }
}
