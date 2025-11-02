import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_user_controller.dart';
import '../widgets/view/media/media_view.dart';

class CandidateDashboardMedia extends StatefulWidget {
  const CandidateDashboardMedia({super.key});

  @override
  State<CandidateDashboardMedia> createState() =>
      _CandidateDashboardMediaState();
}

class _CandidateDashboardMediaState extends State<CandidateDashboardMedia> {
  final CandidateUserController controller = CandidateUserController.to;

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
        body: MediaTabView(
          candidate: controller.candidateData.value!,
          isOwnProfile: true, // This is the candidate's own profile/dashboard
          key: ValueKey(controller.candidateData.value!.media?.length ?? 0), // Force rebuild when media data changes
        ),
      );
    });
  }
}
