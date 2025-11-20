import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_user_controller.dart';
import '../widgets/edit/contact/contact_edit.dart';
import '../widgets/view/contact/contact_tab_view.dart';

class CandidateDashboardContact extends StatefulWidget {
  const CandidateDashboardContact({super.key});

  @override
  State<CandidateDashboardContact> createState() =>
      _CandidateDashboardContactState();
}

class _CandidateDashboardContactState extends State<CandidateDashboardContact> {
  final CandidateUserController controller = CandidateUserController.to;
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
        body: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: SingleChildScrollView(
            child: isEditing
                ? ContactSection(
                    candidateData: controller.candidateData.value!,
                    editedData: controller.editedData.value,
                    isEditing: true,
                    onContactChange: (field, value) =>
                        controller.updateContact(field, value),
                    onSocialChange: (field, value) =>
                        controller.updateContact('social_$field', value),
                  )
                : ContactTabView(
                    candidate: controller.candidateData.value!,
                  ),
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
                        // Save changes
                        final success = await controller.saveExtraInfo();
                        if (success) {
                          setState(() => isEditing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact information updated successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update contact information')),
                          );
                        }
                      },
                      backgroundColor: Colors.green,
                      tooltip: 'Save Contact Information',
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
                      child: const Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  onPressed: () {
                    // Enter edit mode
                    if (controller.editedData.value == null && controller.candidateData.value != null) {
                      controller.editedData.value = controller.candidateData.value;
                    }
                    setState(() => isEditing = true);
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Contact Information',
                  child: const Icon(Icons.edit, size: 28),
                ),
              ),
      );
    });
  }
}
