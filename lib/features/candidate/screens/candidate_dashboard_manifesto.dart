import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../controllers/candidate_user_controller.dart';
import '../controllers/manifesto_controller.dart';
import '../../../services/plan_service.dart';
import '../widgets/edit/manifesto/manifesto_edit.dart';
import '../widgets/view/manifesto/manifesto_view.dart';
import '../../../widgets/loading_overlay.dart';
import '../../../utils/app_logger.dart';

class CandidateDashboardManifesto extends StatefulWidget {
  const CandidateDashboardManifesto({super.key});

  @override
  State<CandidateDashboardManifesto> createState() =>
      _CandidateDashboardManifestoState();
}

class _CandidateDashboardManifestoState
    extends State<CandidateDashboardManifesto> {
  final CandidateUserController controller = CandidateUserController.to;
  final ManifestoController manifestoController = Get.put(ManifestoController());
  bool isEditing = false;
  bool isSaving = false;
  bool canEditManifesto = false;

  // Global key to access manifesto section for file uploads
  final GlobalKey<ManifestoTabEditState> _manifestoSectionKey =
      GlobalKey<ManifestoTabEditState>();

  @override
  void initState() {
    super.initState();
    _loadPlanPermissions();
  }

  Future<void> _loadPlanPermissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      canEditManifesto = await PlanService.canEditManifesto(currentUser.uid);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CandidateLocalizations.of(context)!;
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return Center(child: Text(localizations.translate('candidateDataNotFound')));
      }

      return Scaffold(
        body: isEditing
            ? SingleChildScrollView(
                child: ManifestoTabEdit(
                  key: _manifestoSectionKey,
                  candidateData: controller.candidateData.value!,
                  editedData: controller.editedData.value,
                  isEditing: isEditing,
                  onManifestoChange: (manifesto) =>
                      controller.updateExtraInfo('manifesto', manifesto),
                  onManifestoPdfChange: (pdf) =>
                      controller.updateExtraInfo('manifesto_pdf', pdf),
                  onManifestoTitleChange: (title) =>
                      controller.updateExtraInfo('manifesto_title', title),
                  onManifestoPromisesChange:
                      (List<Map<String, dynamic>> manifestoPromises) =>
                          controller.updateExtraInfo(
                            'manifesto_promises',
                            manifestoPromises,
                          ),
                  onManifestoImageChange: (image) =>
                      controller.updateExtraInfo('manifesto_image', image),
                  onManifestoVideoChange: (video) =>
                      controller.updateExtraInfo('manifesto_video', video),
                ),
              )
            : ManifestoTabView(
                candidate: controller.candidateData.value!,
                isOwnProfile: true,
                showVoterInteractions:
                    true, // Show voter interactions so candidate can see how it looks to voters
              ),
        floatingActionButton: canEditManifesto ? (isEditing
            ? null // Remove the common save button - each tab now has its own save/cancel buttons
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 16),
                child: FloatingActionButton(
                  heroTag: 'edit_manifesto',
                  onPressed: () => setState(() => isEditing = true),
                  backgroundColor: Colors.blue,
                  tooltip: 'Edit Manifesto',
                  child: const Icon(Icons.edit, size: 28),
                ),
              )) : null,
      );
    });
  }
}
