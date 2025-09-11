import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../widgets/candidate/manifesto_section.dart';

class CandidateDashboardManifesto extends StatefulWidget {
  const CandidateDashboardManifesto({super.key});

  @override
  State<CandidateDashboardManifesto> createState() => _CandidateDashboardManifestoState();
}

class _CandidateDashboardManifestoState extends State<CandidateDashboardManifesto> {
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
          title: const Text('Manifesto'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: controller.isPaid.value ? [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Manifesto',
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
                        Get.snackbar('Success', 'Manifesto updated successfully');
                      } else {
                        Get.snackbar('Error', 'Failed to update manifesto');
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
          child: ManifestoSection(
            candidateData: controller.candidateData.value!,
            editedData: controller.editedData.value,
            isEditing: isEditing,
            onManifestoChange: (manifesto) => controller.updateExtraInfo('manifesto', manifesto),
            onManifestoPdfChange: (pdf) => controller.updateExtraInfo('manifesto_pdf', pdf),
          ),
        ),
      );
    });
  }
}