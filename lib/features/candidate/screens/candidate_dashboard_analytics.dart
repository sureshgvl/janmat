import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/view/followers_analytics_tab_view.dart';
import '../widgets/view/events_analytics_tab_view.dart';

class CandidateDashboardAnalytics extends StatelessWidget {
  const CandidateDashboardAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final CandidateDataController controller = Get.put(
      CandidateDataController(),
    );

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.candidateData.value == null) {
        return const Center(child: Text('No candidate data found'));
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            FollowersAnalyticsSection(
              candidateData: controller.candidateData.value!,
            ),
            const Divider(height: 32),
            EventsAnalyticsSection(
              candidateData: controller.candidateData.value!,
            ),
          ],
        ),
      );
    });
  }
}

