import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/candidate_data_controller.dart';
import '../widgets/view/info_tab_view.dart';
import '../widgets/view/manifesto_tab_view.dart';
import '../widgets/view/profile_tab_view.dart';
import '../widgets/view/media_tab_view.dart';
import '../widgets/view/contact_tab_view.dart';
import '../widgets/edit/candidate_achievements_tab_edit.dart';
import '../widgets/edit/candidate_events_tab_edit.dart';
import '../widgets/view/voter_events_tab_view.dart';
import '../widgets/view/followers_analytics_tab_view.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/follow_stats_widget.dart';
import '../widgets/profile_tab_bar_widget.dart';
import '../../../utils/symbol_utils.dart';
import '../../../services/plan_service.dart';
import '../repositories/candidate_repository.dart';
import 'candidate_dashboard_screen.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen>
    with TickerProviderStateMixin {
  Candidate? candidate;
  final CandidateController controller = Get.find<CandidateController>();
  final CandidateDataController dataController =
      Get.find<CandidateDataController>();
  final CandidateRepository candidateRepository = CandidateRepository();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  TabController? _tabController;
  final bool _isUploadingPhoto = false;
  bool _isOwnProfile = false;
  bool _hasSponsoredBanner = false;
  bool _hasPremiumBadge = false;
  bool _hasHighlightCarousel = false;

  @override
  void initState() {
    super.initState();

    // Initialize TabController for performance monitoring
    _tabController = TabController(length: 8, vsync: this);
    _tabController?.addListener(_onTabChanged);

    // Check if arguments are provided
    if (Get.arguments == null) {
      // Handle the case where no candidate data is provided
      // You might want to show an error or navigate back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          AppLocalizations.of(context)!.error,
          CandidateLocalizations.of(context)?.candidateDataNotFound ?? 'Candidate data not found',
        );
        Get.back();
      });
      return;
    }

    candidate = Get.arguments as Candidate;

    // Determine if this is the user's own profile
    _isOwnProfile =
        currentUserId != null &&
        candidate != null &&
        currentUserId == candidate!.userId;

    // Add dummy data for demonstration if data is missing
    _addDummyDataIfNeeded();

    // Check follow status when screen loads
    if (currentUserId != null && candidate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.checkFollowStatus(currentUserId!, candidate!.candidateId);
      });
    }

    // If this is the user's own profile, ensure we have the latest data from the controller
    if (_isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncWithControllerData();
      });
    }

    // Load plan features
    _loadPlanFeatures();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == false) {
      // Only log when tab change is complete
      //final tabNames = ['Info', 'Profile', 'Achievements', 'Manifesto', 'Contact', 'Media', 'Events', 'Highlight', 'Analytics'];
      final tabNames = [
        CandidateLocalizations.of(context)!.info,
        CandidateLocalizations.of(context)!.manifesto,
        CandidateLocalizations.of(context)!.achievements,
        CandidateLocalizations.of(context)!.media,
        CandidateLocalizations.of(context)!.contact,
        CandidateLocalizations.of(context)!.events,
        CandidateLocalizations.of(context)!.analytics,
        //'Profile',
        //'Highlight',
      ];
      final currentTab = tabNames[_tabController!.index];

      // Only log in debug mode
      assert(() {
        debugPrint('🔄 Tab switched to: $currentTab');
        return true;
      }());
    }
  }

  String _formatNumber(String value) {
    try {
      final num = int.parse(value);
      if (num >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(1)}M';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}K';
      }
      return value;
    } catch (e) {
      return value;
    }
  }

  /// Get current locale for party name translation
  String _getCurrentLocale() {
    final locale = Localizations.localeOf(context);
    return locale.languageCode; // Returns 'en' or 'mr'
  }

  void _addDummyDataIfNeeded() {
    // Removed all dummy data - now showing actual Firebase data only
    // The app will display real data from Firestore or show empty states
  }

  // Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Sync with controller data for own profile
  void _syncWithControllerData() {
    if (_isOwnProfile && dataController.candidateData.value != null) {
      debugPrint('🔄 Syncing profile screen with controller data');
      setState(() {
        candidate = dataController.candidateData.value;
      });
    }
  }

  // Load plan features
  Future<void> _loadPlanFeatures() async {
    if (candidate?.userId?.isNotEmpty == true) {
      try {
        final plan = await PlanService.getUserPlan(candidate!.userId!);
        if (plan != null && mounted) {
          setState(() {
            _hasSponsoredBanner = plan.profileFeatures.sponsoredBanner;
            _hasPremiumBadge = plan.profileFeatures.premiumBadge;
            _hasHighlightCarousel = plan.profileFeatures.highlightCarousel;
          });
        }
      } catch (e) {
        // Ignore errors, use default values
      }
    }
  }

  // Refresh candidate data
  Future<void> _refreshCandidateData() async {
    try {
      // For own profile, refresh from controller
      if (_isOwnProfile) {
        await dataController.refreshCandidateData();
        _syncWithControllerData();
      }

      // Refresh follow status if user is logged in
      if (currentUserId != null && candidate != null) {
        await controller.checkFollowStatus(
          currentUserId!,
          candidate!.candidateId,
        );
      }

      // Simulate a brief delay for refresh animation
      await Future.delayed(const Duration(seconds: 1));

      Get.snackbar(
        'Success',
        'Profile data refreshed!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to refresh data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where candidate is null
    if (candidate == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(CandidateLocalizations.of(context)!.candidateProfile),
        ),
        body: Center(
          child: Text(CandidateLocalizations.of(context)!.candidateDataNotAvailable),
        ),
      );
    }

    // Check if candidate is premium based on plan permissions
    bool isPremiumCandidate = candidate!.premium || _hasPremiumBadge;

    return Scaffold(
      appBar: AppBar(
        title: Text(CandidateLocalizations.of(context)!.candidateProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (currentUserId == candidate!.userId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to candidate dashboard screen
                Get.to(() => const CandidateDashboardScreen());
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // Sliver app bar that can be scrolled away
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: false,
              floating: false,
              automaticallyImplyLeading: false, // Prevent automatic back button
              expandedHeight: 220, // Height of the scrollable header
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      ProfileHeaderWidget(
                        candidate: candidate!,
                        hasSponsoredBanner: _hasSponsoredBanner,
                        hasPremiumBadge: _hasPremiumBadge,
                        isUploadingPhoto: _isUploadingPhoto,
                        getCurrentLocale: _getCurrentLocale,
                      ),
                      FollowStatsWidget(
                        candidate: candidate!,
                        currentUserId: currentUserId,
                        formatNumber: _formatNumber,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pinned Tab Bar
            ProfileTabBarWidget(tabController: _tabController!),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshCandidateData,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Info Tab
              InfoTab(
                candidate: candidate!,
                getPartySymbolPath: (party) =>
                    SymbolUtils.getPartySymbolPath(
                      party,
                      candidate: candidate,
                    ),
                formatDate: formatDate,
              ),

              // Manifesto Tab
              ManifestoTabView(
                candidate: candidate!,
                isOwnProfile: _isOwnProfile,
                showVoterInteractions:
                    true, // Show voter interactions in profile view
              ),

              // Profile Tab
              ProfileTabView(
                candidate: candidate!,
                isOwnProfile: _isOwnProfile,
                showVoterInteractions:
                    !_isOwnProfile, // Show like/share buttons for voters only
              ),

              // Achievements Tab
              AchievementsSection(
                candidateData: candidate!,
                editedData: null,
                isEditing: false,
                onAchievementsChange: (value) {},
              ),

              // Media Tab
              MediaTabView(
                candidate: candidate!,
                isOwnProfile: false,
              ),

              // Contact Tab
              ContactTab(candidate: candidate!),

              // Events Tab
              Builder(
                builder: (context) {
                  if (currentUserId == candidate!.userId) {
                    return EventsTabEdit(
                      candidateData: candidate!,
                      editedData: null,
                      isEditing: false,
                      onEventsChange: (value) {},
                    );
                  } else {
                    return VoterEventsSection(candidateData: candidate!);
                  }
                },
              ),

              // Highlight Tab
              // Builder(
              //   builder: (context) {
              //     debugPrint('📊 [TAB LOG] Highlight Tab - Candidate: ${candidate!.name}');
              //     debugPrint('📊 [TAB LOG] Highlight Tab - Has Highlight: ${candidate!.extraInfo?.highlight != null}');
              //     debugPrint('📊 [TAB LOG] Highlight Tab - Highlight Enabled: ${candidate!.extraInfo?.highlight?.enabled ?? false}');
              //     return HighlightTabEdit(
              //       candidateData: candidate!,
              //       editedData: null,
              //       isEditing: false,
              //       onHighlightChange: (value) {},
              //     );
              //   },
              // ),

              // Analytics Tab
              FollowersAnalyticsSection(candidateData: candidate!),

              // Profile Tab (Bio section)
              // Builder(
              //   builder: (context) {
              //     debugPrint('📊 [TAB LOG] Profile Tab - Candidate: ${candidate!.name}');
              //     debugPrint('📊 [TAB LOG] Profile Tab - Bio: ${candidate!.extraInfo?.bio ?? "No bio available"}');
              //     debugPrint('📊 [TAB LOG] Profile Tab - Has Bio: ${candidate!.extraInfo?.bio?.isNotEmpty ?? false}');
              //     return ProfileTabEdit(
              //       candidateData: candidate!,
              //       editedData: null,
              //       isEditing: false,
              //       onBioChange: (value) {},
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

