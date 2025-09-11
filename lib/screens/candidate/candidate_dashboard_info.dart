import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../utils/symbol_utils.dart';
import '../../widgets/candidate/basic_info_section.dart';

class CandidateDashboardInfo extends StatefulWidget {
  const CandidateDashboardInfo({super.key});

  @override
  State<CandidateDashboardInfo> createState() => _CandidateDashboardInfoState();
}

class _CandidateDashboardInfoState extends State<CandidateDashboardInfo> {
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
          title: const Text('Basic Info'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          actions: controller.isPaid.value ? [
            if (!isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => isEditing = true),
                tooltip: 'Edit Basic Info',
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
                        Get.snackbar('Success', 'Basic info updated successfully');
                      } else {
                        Get.snackbar('Error', 'Failed to update basic info');
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
      );
    });
  }
}