import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/file_upload_service.dart';
import 'package:janmat/features/candidate/screens/highlight/candidate_dashboard_highlight_screen.dart';
import '../controllers/candidate_user_controller.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../core/app_theme.dart';
import '../../monetization/services/plan_service.dart';
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
    with TickerProviderStateMixin {
  late TabController _tabController;
  final CandidateUserController controller = CandidateUserController.to;
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
    _tabController = TabController(
      length: 3,
      vsync: this,
    ); // Start with basic tabs
    _tabController.addListener(_handleTabChange);
    _loadPlanFeatures();
    // Refresh data when dashboard is opened and cleanup deleted storage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshCandidateData().then((_) {
        // After data refresh, asynchronously cleanup deleted storage files
        _cleanupDeletedStorage();
      });
    });
  }

  /// Cleanup deleted storage files asynchronously when candidate opens dashboard
  void _cleanupDeletedStorage() {
    final candidate = controller.candidate.value;
    if (candidate == null) {
      return;
    }

    // Check if location fields are available
    final stateId = candidate.location.stateId;
    final districtId = candidate.location.districtId;
    final bodyId = candidate.location.bodyId;
    final wardId = candidate.location.wardId;

    if (stateId == null || districtId == null || bodyId == null || wardId == null) {
      return;
    }

    final fileUploadService = Get.find<FileUploadService>();
    unawaited(fileUploadService.cleanupDeletedStorageFiles(
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      candidateId: candidate.candidateId,
    ));
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
          canDisplayAchievements =
              plan.dashboardTabs?.achievements.enabled ?? false;
          canUploadMedia = plan.dashboardTabs?.media.enabled ?? false;
          canManageEvents = plan.dashboardTabs?.events.enabled ?? false;
          canViewAnalytics = plan.dashboardTabs?.analytics.enabled ?? false;
          canManageHighlights =
              plan.profileFeatures.highlightCarousel ||
              plan.profileFeatures.multipleHighlights == true;
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

      // Additionally check for active highlight subscriptions (for users who have highlight plans + candidate plans)
      try {
        final highlightSubscription = await FirebaseFirestore.instance
            .collection('subscriptions')
            .where('userId', isEqualTo: userId)
            .where('planType', isEqualTo: 'highlight')
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (highlightSubscription.docs.isNotEmpty) {
          // User has active highlight subscription, enable highlight management
          canManageHighlights = true;
        }
      } catch (e) {
        // Error checking highlight subscription, keep existing logic
      }

      // Update tab controller with correct length after loading features
      final availableTabs = _getAvailableTabs();
      if (mounted && availableTabs.length != _tabController.length) {
        setState(() {
          _tabController.dispose();
          _tabController = TabController(
            length: availableTabs.length,
            vsync: this,
          );
        });
      }
    }
  }

  List<Map<String, dynamic>> _getAvailableTabs() {
    final tabs = <Map<String, dynamic>>[];

    // Basic Info - always available
    tabs.add({
      'title': CandidateLocalizations.of(context)!.basicInfo,
      'widget': const CandidateDashboardBasicInfo(),
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
          tabs: availableTabs
              .map((tab) => Tab(text: tab['title'] as String))
              .toList(),
        ),
        actions: null,
      ),
      backgroundColor: AppTheme.homeBackgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.candidateData.value == null) {
          return Center(
            child: Text(
              CandidateLocalizations.of(context)!.candidateDataNotFound,
            ),
          );
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

        return TabBarView(controller: _tabController, children: tabWidgets);
      }),
    );
  }
}
