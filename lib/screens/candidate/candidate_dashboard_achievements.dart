import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/achievements_section.dart';

class CandidateDashboardAchievements extends StatefulWidget {
  const CandidateDashboardAchievements({super.key});

  @override
  State<CandidateDashboardAchievements> createState() => _CandidateDashboardAchievementsState();
}

class _CandidateDashboardAchievementsState extends State<CandidateDashboardAchievements> {
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
          title: const Text('Achievements'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: controller.isPaid.value ? [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Achievements',
              )
            else
              Row(
                children: [
                  IconButton(
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                          )
                        : const Icon(Icons.save),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setState(() => isSaving = true);
                            try {
                              final success = await controller.saveExtraInfo();
                              if (success) {
                                setState(() => isEditing = false);
                                Get.snackbar('Success', 'Achievements updated successfully');
                              } else {
                                Get.snackbar('Error', 'Failed to update achievements');
                              }
                            } finally {
                              setState(() => isSaving = false);
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
        body: AchievementsSection(
          candidateData: controller.candidateData.value!,
          editedData: controller.editedData.value,
          isEditing: isEditing,
          onAchievementsChange: (achievements) => controller.updateExtraInfo('achievements', achievements),
        ),
      );
    });
  }
}