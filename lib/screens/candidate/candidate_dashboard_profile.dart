import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/edit/profile_tab_edit.dart';

class CandidateDashboardProfile extends StatefulWidget {
  const CandidateDashboardProfile({super.key});

  @override
  State<CandidateDashboardProfile> createState() => _CandidateDashboardProfileState();
}

class _CandidateDashboardProfileState extends State<CandidateDashboardProfile> {
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
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: ProfileSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onBioChange: (bio) => controller.updateExtraInfo('bio', bio),
          ),
        ),
        floatingActionButton: isEditing
            ? Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'save_profile',
                      onPressed: isSaving ? null : () async {
                        setState(() => isSaving = true);
                        try {
                          final success = await controller.saveExtraInfo();
                          if (success) {
                            setState(() => isEditing = false);
                            Get.snackbar('Success', 'Profile updated successfully');
                          } else {
                            Get.snackbar('Error', 'Failed to update profile');
                          }
                        } finally {
                          setState(() => isSaving = false);
                        }
                      },
                      backgroundColor: Colors.green,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 28),
                      tooltip: isSaving ? 'Saving...' : 'Save Changes',
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'cancel_profile',
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
                  heroTag: 'edit_profile',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.edit, size: 28),
                  tooltip: 'Edit Profile',
                ),
              ),
      );
    });
  }
}
