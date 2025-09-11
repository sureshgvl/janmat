import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../utils/symbol_utils.dart';
import 'candidate_dashboard_info.dart';
import 'candidate_dashboard_profile.dart';
import 'candidate_dashboard_achievements.dart';
import 'candidate_dashboard_manifesto.dart';
import 'candidate_dashboard_contact.dart';
import 'candidate_dashboard_media.dart';
import 'candidate_dashboard_events.dart';
import 'candidate_dashboard_highlight.dart';
import 'candidate_dashboard_analytics.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  State<CandidateDashboardScreen> createState() => _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // Refresh data when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshCandidateData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidate Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Profile'),
            Tab(text: 'Achievements'),
            Tab(text: 'Manifesto'),
            Tab(text: 'Contact'),
            Tab(text: 'Media'),
            Tab(text: 'Events'),
            Tab(text: 'Highlight'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: null,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.candidateData.value == null) {
          return const Center(child: Text('No candidate data found'));
        }

        return TabBarView(
          controller: _tabController,
          children: const [
            CandidateDashboardInfo(),
            CandidateDashboardProfile(),
            CandidateDashboardAchievements(),
            CandidateDashboardManifesto(),
            CandidateDashboardContact(),
            CandidateDashboardMedia(),
            CandidateDashboardEvents(),
            CandidateDashboardHighlight(),
            CandidateDashboardAnalytics(),
          ],
        );
      }),
    );
  }
}