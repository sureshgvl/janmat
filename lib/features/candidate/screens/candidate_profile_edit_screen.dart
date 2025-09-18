import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/edit/profile_tab_edit.dart';

class CandidateProfileEditScreen extends StatefulWidget {
  const CandidateProfileEditScreen({super.key});

  @override
  State<CandidateProfileEditScreen> createState() =>
      _CandidateProfileEditScreenState();
}

class _CandidateProfileEditScreenState
    extends State<CandidateProfileEditScreen> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(() {
            if (controller.isPaid.value) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      final success = await controller.saveExtraInfo();
                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'Success',
                          'Profile updated successfully',
                          backgroundColor: Colors.green.shade100,
                          colorText: Colors.green.shade800,
                        );
                      } else {
                        Get.snackbar('Error', 'Failed to update profile');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      controller.resetEditedData();
                      Get.back();
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.candidateData.value == null) {
          return const Center(child: Text('No candidate data found'));
        }

        return SingleChildScrollView(
          child: ProfileTabEdit(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onBioChange: (bio) => controller.updateExtraInfo('bio', bio),
          ),
        );
      }),
    );
  }
}
