import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../l10n/app_localizations.dart';
import 'candidate_dashboard_info.dart';
import 'candidate_dashboard_achievements.dart';
import 'candidate_dashboard_manifesto.dart';
import 'candidate_dashboard_contact.dart';
import 'candidate_dashboard_media.dart';
import 'candidate_dashboard_events.dart';
import 'candidate_dashboard_analytics.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
        title: Text(AppLocalizations.of(context)!.candidateDashboard),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.basicInfo),
            Tab(text: AppLocalizations.of(context)!.manifesto),
            Tab(text: AppLocalizations.of(context)!.achievements),
            Tab(text: AppLocalizations.of(context)!.media),
            Tab(text: AppLocalizations.of(context)!.contact),
            Tab(text: AppLocalizations.of(context)!.events),
            Tab(text: AppLocalizations.of(context)!.analytics),
            //Tab(text: AppLocalizations.of(context)!.highlight),
            //Tab(text: AppLocalizations.of(context)!.profile),
          ],
        ),
        actions: null,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.candidateData.value == null) {
          return Center(child: Text(AppLocalizations.of(context)!.candidateDataNotFound));
        }

        return TabBarView(
          controller: _tabController,
          children: const [
            CandidateDashboardInfo(),
            CandidateDashboardManifesto(),
            CandidateDashboardAchievements(),
            CandidateDashboardMedia(),
            CandidateDashboardContact(),
            CandidateDashboardEvents(),
            CandidateDashboardAnalytics(),
            //CandidateDashboardProfile(),
            //CandidateDashboardHighlight(),
          ],
        );
      }),
    );
  }
}
