import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_data_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/plan_service.dart';
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

  // Plan-based feature access
  bool canEditManifesto = false;
  bool canDisplayAchievements = false;
  bool canUploadMedia = false;
  bool canManageEvents = false;
  bool canViewAnalytics = false;

  @override
  void initState() {
    super.initState();
    // Initialize TabController synchronously with default length (basic tabs that are always available)
    _tabController = TabController(length: 3, vsync: this); // Basic Info, Manifesto, Contact
    _loadPlanFeatures();
    // Refresh data when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshCandidateData();
    });
  }

  Future<void> _loadPlanFeatures() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      canEditManifesto = await PlanService.canEditManifesto(userId);
      canDisplayAchievements = await PlanService.canDisplayAchievements(userId);
      canUploadMedia = await PlanService.canUploadMedia(userId);
      canManageEvents = await PlanService.canManageEvents(userId);
      canViewAnalytics = await PlanService.canViewAnalytics(userId);

      // Update tab controller with available tabs
      final availableTabs = _getAvailableTabs();
      if (mounted && availableTabs.length != _tabController.length) {
        setState(() {
          _tabController.dispose();
          _tabController = TabController(length: availableTabs.length, vsync: this);
        });
      }
    }
  }

  List<Map<String, dynamic>> _getAvailableTabs() {
    final tabs = <Map<String, dynamic>>[];

    // Basic Info - always available
    tabs.add({
      'title': AppLocalizations.of(context)!.basicInfo,
      'widget': const CandidateDashboardInfo(),
    });

    // Manifesto - available if can edit manifesto or at least view
    tabs.add({
      'title': AppLocalizations.of(context)!.manifesto,
      'widget': const CandidateDashboardManifesto(),
    });

    // Achievements - available if can display achievements
    if (canDisplayAchievements) {
      tabs.add({
        'title': AppLocalizations.of(context)!.achievements,
        'widget': const CandidateDashboardAchievements(),
      });
    }

    // Media - available if can upload media
    if (canUploadMedia) {
      tabs.add({
        'title': AppLocalizations.of(context)!.media,
        'widget': const CandidateDashboardMedia(),
      });
    }

    // Contact - always available
    tabs.add({
      'title': AppLocalizations.of(context)!.contact,
      'widget': const CandidateDashboardContact(),
    });

    // Events - available if can manage events
    if (canManageEvents) {
      tabs.add({
        'title': AppLocalizations.of(context)!.events,
        'widget': const CandidateDashboardEvents(),
      });
    }

    // Analytics - available if can view analytics
    if (canViewAnalytics) {
      tabs.add({
        'title': AppLocalizations.of(context)!.analytics,
        'widget': const CandidateDashboardAnalytics(),
      });
    }

    return tabs;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableTabs = _getAvailableTabs();

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
          tabs: availableTabs.map((tab) => Tab(text: tab['title'] as String)).toList(),
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
          children: availableTabs.map((tab) => tab['widget'] as Widget).toList(),
        );
      }),
    );
  }
}
