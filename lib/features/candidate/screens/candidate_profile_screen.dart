import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/candidate_user_controller.dart';
import '../widgets/view/basic_info/basic_info_tab_view.dart';
import '../widgets/view/manifesto/manifesto_view.dart';
import '../widgets/view/profile/profile_tab_view.dart';
import '../widgets/view/media/media_view.dart';
import '../widgets/view/contact/contact_tab_view.dart';
import '../widgets/edit/achievements/achievements_edit.dart';
import '../widgets/edit/events/events_edit.dart';
import '../widgets/view/events/events_tab_view.dart';
import '../widgets/view/followers_analytics_tab_view.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/follow_stats_widget.dart';
import '../widgets/profile_tab_bar_widget.dart';
import '../../../utils/symbol_utils.dart';
import '../../../services/plan_service.dart';
import '../../../services/local_database_service.dart';
import '../../../services/analytics_data_collection_service.dart';
import '../../../utils/app_logger.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';
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
  final CandidateUserController dataController = CandidateUserController.to;
  final CandidateRepository candidateRepository = CandidateRepository();
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  TabController? _tabController;
  final bool _isUploadingPhoto = false;
  bool _isOwnProfile = false;
  bool _hasSponsoredBanner = false;
  bool _hasPremiumBadge = false;
  bool _hasHighlightCarousel = false;

  // Location data variables
  String? _wardName;
  String? _districtName;
  String? _bodyName;

  @override
  void initState() {
    super.initState();

    // Check if arguments are provided
    if (Get.arguments == null) {
      // Handle the case where no candidate data is provided
      // You might want to show an error or navigate back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          AppLocalizations.of(context)!.error,
          CandidateLocalizations.of(context)?.candidateDataNotFound ??
              'Candidate data not found',
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

    // Initialize TabController after determining profile ownership
    // Length is 7 for non-own profiles (no analytics), 8 for own profile (with analytics)
    _tabController = TabController(length: _isOwnProfile ? 8 : 7, vsync: this);
    _tabController?.addListener(_onTabChanged);

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

    // Load location data
    _loadLocationData();

    // Track profile view (only for other users viewing this profile)
    if (!_isOwnProfile && candidate != null) {
      _trackProfileView();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController?.indexIsChanging == false) {
      // Only log when tab change is complete
      final tabNames = [
        CandidateLocalizations.of(context)!.info,
        CandidateLocalizations.of(context)!.manifesto,
        CandidateLocalizations.of(context)!.profile,
        CandidateLocalizations.of(context)!.achievements,
        CandidateLocalizations.of(context)!.media,
        CandidateLocalizations.of(context)!.contact,
        CandidateLocalizations.of(context)!.events,
      ];

      // Add analytics tab name only for own profile
      if (_isOwnProfile) {
        tabNames.add(CandidateLocalizations.of(context)!.analytics);
      }

      final currentTab = tabNames[_tabController!.index];

      // Only log in debug mode
      assert(() {
        AppLogger.candidate('🔄 Tab switched to: $currentTab');
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

  // Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Sync with controller data for own profile
  void _syncWithControllerData() {
    if (_isOwnProfile && dataController.candidateData.value != null) {
      AppLogger.candidate('🔄 Syncing profile screen with controller data');
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

  // Load location data
  Future<void> _loadLocationData() async {
    AppLogger.candidate(
      '🔍 [Candidate Profile] Loading location data for candidate ${candidate?.candidateId}',
    );
    AppLogger.candidate(
      '📍 [Candidate Profile] IDs: district=${candidate?.location.districtId}, body=${candidate?.location.bodyId}, ward=${candidate?.location.wardId}',
    );

    if (candidate == null) return;

    try {
      // DEBUG: Print all ward data to see what's stored
      AppLogger.candidate('🔍 [DEBUG] Checking all ward data in SQLite...');
      final db = await _locationDatabase.database;
      final allWards = await db.query('wards');
      AppLogger.candidate(
        '📊 [DEBUG] Total wards in SQLite: ${allWards.length}',
      );
      for (var ward in allWards) {
        AppLogger.candidate(
          '🏛️ [DEBUG] Ward: id=${ward['id']}, name="${ward['name']}", districtId=${ward['districtId']}, bodyId=${ward['bodyId']}, stateId=${ward['stateId']}',
        );
      }

      // Specifically check ward_17 data
      final ward17Data = allWards.where((w) => w['id'] == 'ward_17').toList();
      if (ward17Data.isNotEmpty) {
        AppLogger.candidate('🎯 [DEBUG] ward_17 data: ${ward17Data.first}');
      } else {
        AppLogger.candidate('❌ [DEBUG] ward_17 not found in SQLite');
      }

      // Load location data from SQLite cache
      final locationData = await _locationDatabase.getCandidateLocationData(
        candidate!.location.districtId ?? '',
        candidate!.location.bodyId ?? '',
        candidate!.location.wardId ?? '',
        candidate!.location.stateId ?? 'maharashtra',
      );

      // Check if ward data is missing or corrupted
      final rawWardName = locationData['wardName'];
      final isWardDataCorrupted =
          rawWardName != null &&
          (rawWardName.startsWith('Ward Ward ') ||
              (rawWardName.startsWith('Ward ') &&
                  RegExp(r'^ward_\d+$').hasMatch(rawWardName.substring(5))));

      if (locationData['wardName'] == null || isWardDataCorrupted) {
        AppLogger.candidate(
          '⚠️ [Candidate Profile] Ward data missing or corrupted (raw: "$rawWardName"), triggering sync...',
        );

        // Trigger background sync for missing/corrupted location data
        await _syncMissingLocationData();

        // Try loading again after sync
        final updatedLocationData = await _locationDatabase
            .getCandidateLocationData(
              candidate!.location.districtId ?? '',
              candidate!.location.bodyId ?? '',
              candidate!.location.wardId ?? '',
              candidate!.location.stateId ?? 'maharashtra',
            );

        if (mounted) {
          setState(() {
            _districtName = updatedLocationData['districtName'];
            _bodyName = updatedLocationData['bodyName'];
            _wardName = updatedLocationData['wardName'];
          });
        }

        AppLogger.candidate(
          '✅ [Candidate Profile] Location data loaded after sync:',
        );
        AppLogger.candidate('   📍 District: $_districtName');
        AppLogger.candidate('   🏛️ Body: $_bodyName');
        AppLogger.candidate('   🏛️ Ward: $_wardName');
      } else {
        if (mounted) {
          setState(() {
            _districtName = locationData['districtName'];
            _bodyName = locationData['bodyName'];
            _wardName = locationData['wardName'];
          });
        }

        AppLogger.candidate(
          '✅ [Candidate Profile] Location data loaded successfully from SQLite:',
        );
        AppLogger.candidate('   📍 District: $_districtName');
        AppLogger.candidate('   🏛️ Body: $_bodyName');
        AppLogger.candidate('   🏛️ Ward: $_wardName');
      }
    } catch (e) {
      AppLogger.candidateError(
        '❌ [Candidate Profile] Error loading location data: $e',
      );

      // Fallback to ID-based display if sync fails
      if (mounted) {
        setState(() {
          _districtName = candidate!.location.districtId;
          _bodyName = candidate!.location.bodyId;
          _wardName = 'Ward ${candidate!.location.wardId}';
        });
      }
    }
  }

  // Track profile view for analytics
  Future<void> _trackProfileView() async {
    if (candidate == null) return;

    try {
      await AnalyticsDataCollectionService().trackProfileView(
        candidateId: candidate!.candidateId,
        viewerId: currentUserId,
        viewerRole: currentUserId != null ? 'voter' : 'anonymous',
        source: 'profile_screen',
        metadata: {
          'viewedFrom': 'candidate_profile_screen',
          'tab': 'initial_load',
        },
      );
    } catch (e) {
      // Analytics tracking should not interrupt user experience
      AppLogger.common('⚠️ Failed to track profile view: $e');
    }
  }

  // Sync missing location data from Firebase to SQLite
  Future<void> _syncMissingLocationData() async {
    try {
      AppLogger.candidate(
        '🔄 [Candidate Profile] Syncing missing location data from Firebase...',
      );

      // Sync district data if missing
      if (_districtName == null) {
        AppLogger.candidate(
          '🏙️ [Sync] Fetching district data for ${candidate?.location.districtId}',
        );
        final districts = await candidateRepository.getAllDistricts();
        final district = districts.firstWhere(
          (d) => d.id == candidate?.location.districtId,
          orElse: () => District(
            id: candidate!.location.districtId ?? '',
            name: candidate!.location.districtId ?? '',
            stateId:
                candidate!.location.stateId ??
                'maharashtra', // Use candidate's actual state ID with fallback
          ),
        );
        await _locationDatabase.insertDistricts([district]);
        AppLogger.candidate('✅ [Sync] District data synced');
      }

      // Sync body data if missing
      if (_bodyName == null) {
        AppLogger.candidate(
          '🏛️ [Sync] Fetching body data for ${candidate?.location.bodyId}',
        );
        // Note: We need to get bodies for the district first
        final bodies = await candidateRepository.getWardsByDistrictAndBody(
          candidate!.location.districtId ?? '',
          candidate!.location.bodyId ?? '',
        );
        // Extract body info from wards (since we don't have direct body fetch)
        if (bodies.isNotEmpty) {
          final body = Body(
            id: candidate!.location.bodyId ?? '',
            name: candidate!.location.bodyId ?? '', // Fallback name
            type: BodyType.municipal_corporation, // Default
            districtId: candidate!.location.districtId ?? '',
            stateId:
                candidate!.location.stateId ??
                'maharashtra', // Use candidate's actual state ID
          );
          await _locationDatabase.insertBodies([body]);
          AppLogger.candidate('✅ [Sync] Body data synced');
        }
      }

      // Sync ward data (most critical)
      if (_wardName == null) {
        AppLogger.candidate(
          '🏛️ [Sync] Fetching ward data for ${candidate?.location.wardId}',
        );
        AppLogger.candidate(
          '🏛️ [Sync] Candidate stateId: ${candidate!.location.stateId}',
        );

        // Get the correct stateId for this candidate
        final stateId =
            candidate!.location.stateId ?? 'maharashtra'; // Default fallback
        AppLogger.candidate('🏛️ [Sync] Using stateId: $stateId');

        final wards = await candidateRepository.getWardsByDistrictAndBody(
          candidate!.location.districtId ?? '',
          candidate!.location.bodyId ?? '',
          candidate!.location.stateId ??
              'maharashtra', // Pass the candidate's stateId
        );

        AppLogger.candidate(
          '🏛️ [Sync] Found ${wards.length} wards from Firebase',
        );
        for (var w in wards) {
          AppLogger.candidate('🏛️ [Sync] Ward: ${w.id} -> ${w.name}');
        }

        final ward = wards.firstWhere(
          (w) => w.id == candidate?.location.wardId,
          orElse: () => Ward(
            id: candidate!.location.wardId ?? '',
            name: 'Ward ${candidate!.location.wardId ?? ''}',
            districtId: candidate!.location.districtId ?? '',
            bodyId: candidate!.location.bodyId ?? '',
            stateId: stateId,
          ),
        );

        AppLogger.candidate(
          '🏛️ [Sync] Selected ward: ${ward.id} -> "${ward.name}"',
        );

        // Force update the ward data in SQLite to ensure we have the latest from Firebase
        AppLogger.candidate(
          '🔄 [Sync] Force updating ward data in SQLite: "${ward.name}"',
        );
        await _locationDatabase.insertWards([ward]);
        AppLogger.candidate('✅ [Sync] Ward data synced');
      }

      AppLogger.candidate('✅ [Candidate Profile] Location data sync completed');
    } catch (e) {
      AppLogger.candidateError(
        '❌ [Candidate Profile] Error syncing location data: $e',
      );
      // Continue with fallback display
    }
  }

  // Build tab views conditionally
  List<Widget> _buildTabViews() {
    final List<Widget> tabViews = [
      // Info Tab
      BasicInfoTabView(
        candidate: candidate!,
        getPartySymbolPath: (party) =>
            SymbolUtils.getPartySymbolPath(party, candidate: candidate),
        formatDate: formatDate,
        wardName: _wardName,
        districtName: _districtName,
        bodyName: _bodyName,
      ),

      // Manifesto Tab
      ManifestoTabView(
        candidate: candidate!,
        isOwnProfile: _isOwnProfile,
        showVoterInteractions: true, // Show voter interactions in profile view
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
      MediaTabView(candidate: candidate!, isOwnProfile: false),

      // Contact Tab
      ContactTabView(candidate: candidate!),

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
    ];

    // Add Analytics tab only for own profile
    if (_isOwnProfile) {
      tabViews.add(FollowersAnalyticsSection(candidateData: candidate!));
    }

    return tabViews;
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
          child: Text(
            CandidateLocalizations.of(context)!.candidateDataNotAvailable,
          ),
        ),
      );
    }

    // Check if candidate is premium based on plan permissions
    bool isPremiumCandidate = _hasPremiumBadge;

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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            AppLogger.candidate(
                              '🏛️ [Profile Screen] Building ProfileHeaderWidget:',
                            );
                            AppLogger.candidate(
                              '   wardName passed: $_wardName',
                            );
                            AppLogger.candidate(
                              '   districtName passed: $_districtName',
                            );
                            AppLogger.candidate(
                              '   body name passed: $_bodyName',
                            );

                            AppLogger.candidate(
                              '   candidate wardId: ${candidate!.location.wardId}',
                            );
                            AppLogger.candidate(
                              '   candidate districtId: ${candidate!.location.districtId}',
                            );
                            return ProfileHeaderWidget(
                              candidate: candidate!,
                              hasSponsoredBanner: _hasSponsoredBanner,
                              hasPremiumBadge: _hasPremiumBadge,
                              isUploadingPhoto: _isUploadingPhoto,
                              getCurrentLocale: _getCurrentLocale,
                              wardName: _wardName,
                              districtName: _districtName,
                              bodyName: _bodyName,
                            );
                          },
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
            ),

            // Pinned Tab Bar
            ProfileTabBarWidget(
              tabController: _tabController!,
              isOwnProfile: _isOwnProfile,
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refreshCandidateData,
          child: TabBarView(
            controller: _tabController,
            children: _buildTabViews(),
          ),
        ),
      ),
    );
  }
}
