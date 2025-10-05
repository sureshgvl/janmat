import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_data_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../services/plan_service.dart';
import 'candidate_dashboard_info.dart';
import 'candidate_dashboard_achievements.dart';
import 'candidate_dashboard_manifesto.dart';
import 'candidate_dashboard_contact.dart';
import 'candidate_dashboard_media.dart';
import 'candidate_dashboard_events.dart';
import 'candidate_dashboard_analytics.dart';
import 'candidate_dashboard_highlight.dart';

class CandidateDashboardScreen extends StatefulWidget {
  const CandidateDashboardScreen({super.key});

  @override
  State<CandidateDashboardScreen> createState() =>
      _CandidateDashboardScreenState();
}

class _CandidateDashboardScreenState extends State<CandidateDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final CandidateDataController controller = Get.put(CandidateDataController());
  bool isEditing = false;

  // Plan-based feature access
  bool canEditManifesto = false;
  bool canDisplayAchievements = false;
  bool canUploadMedia = false;
  bool canManageEvents = false;
  bool canViewAnalytics = false;
  bool canManageHighlights = false;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with default length, will be updated when plan features are loaded
    _tabController = TabController(length: 3, vsync: this); // Start with basic tabs
    _tabController.addListener(_handleTabChange);
    _loadPlanFeatures();
    // Refresh data when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshCandidateData();
    });
  }

  void _handleTabChange() {
    // Handle tab change if needed
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPlanFeatures() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      final plan = await PlanService.getUserPlan(userId);

      if (plan != null) {
        // Check if this is a highlight plan (no dashboard access)
        if (plan.type == 'highlight') {
          // Highlight plans don't have dashboard access
          canEditManifesto = false;
          canDisplayAchievements = false;
          canUploadMedia = false;
          canManageEvents = false;
          canViewAnalytics = false;
          canManageHighlights = true; // They can manage their highlights
        } else {
          // Candidate plan with dashboard access
          canEditManifesto = plan.dashboardTabs?.manifesto.enabled ?? false;
          canDisplayAchievements = plan.dashboardTabs?.achievements.enabled ?? false;
          canUploadMedia = plan.dashboardTabs?.media.enabled ?? false;
          canManageEvents = plan.dashboardTabs?.events.enabled ?? false;
          canViewAnalytics = plan.dashboardTabs?.analytics.enabled ?? false;
          canManageHighlights = plan.profileFeatures.highlightCarousel || plan.profileFeatures.multipleHighlights == true;
        }
      } else {
        // Free plan defaults
        canEditManifesto = true; // Basic manifesto access
        canDisplayAchievements = false;
        canUploadMedia = false;
        canManageEvents = false;
        canViewAnalytics = false;
        canManageHighlights = false;
      }

      // Update tab controller with correct length after loading features
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
      'title': CandidateLocalizations.of(context)!.basicInfo,
      'widget': const CandidateDashboardInfo(),
    });

    // Manifesto - available if can edit manifesto or at least view
    tabs.add({
      'title': CandidateLocalizations.of(context)!.manifesto,
      'widget': const CandidateDashboardManifesto(),
    });

    // Achievements - available if can display achievements
    if (canDisplayAchievements) {
      tabs.add({
        'title': CandidateLocalizations.of(context)!.achievements,
        'widget': const CandidateDashboardAchievements(),
      });
    }

    // Media - available if can upload media
    if (canUploadMedia) {
      tabs.add({
        'title': CandidateLocalizations.of(context)!.media,
        'widget': const CandidateDashboardMedia(),
      });
    }

    // Highlights - available for Gold and Platinum plans
    if (canManageHighlights) {
      tabs.add({
        'title': 'Highlights', // TODO: Add to localizations
        'widget': const CandidateDashboardHighlight(),
      });
    }

    // Contact - always available
    tabs.add({
      'title': CandidateLocalizations.of(context)!.contact,
      'widget': const CandidateDashboardContact(),
    });

    // Events - available if can manage events
    if (canManageEvents) {
      tabs.add({
        'title': CandidateLocalizations.of(context)!.events,
        'widget': const CandidateDashboardEvents(),
      });
    }

    // Analytics - available if can view analytics
    if (canViewAnalytics) {
      tabs.add({
        'title': CandidateLocalizations.of(context)!.analytics,
        'widget': const CandidateDashboardAnalytics(),
      });
    }

    return tabs;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableTabs = _getAvailableTabs();

    return Scaffold(
      appBar: AppBar(
        title: Text(CandidateLocalizations.of(context)!.candidateDashboard),
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
          return Center(child: Text(CandidateLocalizations.of(context)!.candidateDataNotFound));
        }

        // Create a list of widgets that matches the TabController length
        final tabWidgets = <Widget>[];

        // Add available tabs
        for (final tab in availableTabs) {
          tabWidgets.add(tab['widget'] as Widget);
        }

        // Fill remaining slots with empty containers to match TabController length
        while (tabWidgets.length < _tabController.length) {
          tabWidgets.add(const SizedBox.shrink());
        }

        return TabBarView(
          controller: _tabController,
          children: tabWidgets,
        );
      }),
    );
  }
}

