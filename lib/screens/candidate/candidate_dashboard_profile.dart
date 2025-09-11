import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/profile_section.dart';

class CandidateDashboardProfile extends StatefulWidget {
  const CandidateDashboardProfile({super.key});

  @override
  State<CandidateDashboardProfile> createState() => _CandidateDashboardProfileState();
}

class _CandidateDashboardProfileState extends State<CandidateDashboardProfile> {
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

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
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: controller.isPaid.value ? [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Profile',
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      final success = await controller.saveExtraInfo();
                      if (success) {
                        setState(() => isEditing = false);
                        Get.snackbar('Success', 'Profile updated successfully');
                      } else {
                        Get.snackbar('Error', 'Failed to update profile');
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
          ] : null,
        ),
        body: SingleChildScrollView(
          child: ProfileSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onBioChange: (bio) => controller.updateExtraInfo('bio', bio),
          ),
        ),
      );
    });
  }
}