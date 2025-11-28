import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../services/share_candidate_profile_service.dart';
import '../../../widgets/common/shimmer_loading_widgets.dart';
import '../../../widgets/common/error_state_widgets.dart';
import '../../../core/app_route_names.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/candidate_user_controller.dart';
import '../widgets/view/basic_info/basic_info_tab_view.dart';
import '../widgets/view/manifesto/manifesto_view.dart';
import '../widgets/view/media/media_view_refactored.dart';
import '../widgets/view/contact/contact_tab_view.dart';
import '../widgets/view/achievements/achievements_tab_view.dart';

import '../widgets/view/events/events_tab_view.dart';
import '../widgets/view/followers_analytics_tab_view.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/follow_stats_widget.dart';
import '../widgets/profile_tab_bar_widget.dart';
import '../../../utils/symbol_utils.dart';
import '../../monetization/services/plan_service.dart';
import '../services/analytics_data_collection_service.dart';
import '../../../utils/app_logger.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../models/ward_model.dart';
import '../repositories/candidate_repository.dart';
import 'candidate_dashboard_screen.dart';

enum ProfileScreenState {
  loading,
  loaded,
  error,
  candidateNotFound,
  networkError,
}

/// Loading States for candidate profile
class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({
    super.key,
  });

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen>
    with TickerProviderStateMixin {
  // Screen state management
  ProfileScreenState _screenState = ProfileScreenState.loading;
  Candidate? candidate;
  final CandidateController controller = Get.isRegistered<CandidateController>()
      ? Get.find<CandidateController>()
      : Get.put<CandidateController>(CandidateController());
  final CandidateUserController dataController = CandidateUserController.to;
  final CandidateRepository candidateRepository = CandidateRepository();
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

    // Standard access with candidate object or own profile loading
    if (Get.arguments == null) {
      // Handle the case where no candidate data is provided
      // First try to get candidate data from the controller for own profile
      if (currentUserId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await dataController.loadCandidateUserData(currentUserId!);
            if (dataController.candidate.value != null) {
              AppLogger.candidate(
                '✅ Retrieved candidate data for own profile: ${dataController.candidate.value!.basicInfo!.fullName}',
              );
              setState(() {
                candidate = dataController.candidate.value;
                _isOwnProfile = true;
              });

              // Initialize TabController after getting candidate data
              _tabController?.dispose();
              _tabController = TabController(
                length: _isOwnProfile ? 7 : 6,
                vsync: this,
              );
              _tabController?.addListener(_onTabChanged);
              _loadPlanFeatures();
              await _loadLocationData();

            }
          } catch (e) {
            AppLogger.candidateError(
              '❌ Failed to load candidate data for own profile: $e',
            );
          }

          // If we still don't have candidate data, show error
          SnackbarUtils.showError(
            CandidateLocalizations.of(context)?.candidateDataNotFound ??
                'Candidate data not found',
          );
          Get.back();
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackbarUtils.showError(
            CandidateLocalizations.of(context)?.candidateDataNotFound ??
                'Candidate data not found',
          );
          Get.back();
        });
      }
      return;
    }

    // Check if arguments contain candidate data
    final argumentsCandidate = Get.arguments != null ? Get.arguments as Candidate : null;

    // Determine if this is the user's own profile
    // If arguments contain candidate data and it matches current user, OR if no arguments (direct navigation to own profile)
    _isOwnProfile = (argumentsCandidate != null && currentUserId != null && currentUserId == argumentsCandidate.userId) ||
                   (Get.arguments == null && currentUserId != null);

    AppLogger.candidate(
      '👤 Profile ownership check: currentUserId=$currentUserId, argumentsCandidateUserId=${argumentsCandidate?.userId}, isOwnProfile=$_isOwnProfile',
    );

    // For own profile, use session caching - only load if not already cached
    if (_isOwnProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Check if we already have cached data in the controller
          if (dataController.candidate.value != null) {
            AppLogger.candidate('✅ Using cached candidate data for own profile: ${dataController.candidate.value!.basicInfo!.fullName}');

            setState(() {
              candidate = dataController.candidate.value;
            });

            // Initialize TabController after getting candidate data
            _tabController?.dispose();
            _tabController = TabController(
              length: _isOwnProfile ? 7 : 6,
              vsync: this,
            );
            _tabController?.addListener(_onTabChanged);
            _loadPlanFeatures();
            await _loadLocationData();

            // Mark screen as loaded after all data is ready
            if (mounted) {
              setState(() {
                _screenState = ProfileScreenState.loaded;
              });
            }

            // Do a background refresh to ensure data is up to date
            _refreshCandidateDataSilently();
          } else {
            AppLogger.candidate('🔄 No cached data found, loading fresh candidate data for own profile');

            // Load fresh data directly from repository
            final candidateRepository = CandidateRepository();
            final freshCandidate = await candidateRepository.getCandidateData(currentUserId!);

            if (freshCandidate != null) {
              AppLogger.candidate(
                '✅ LOADED fresh candidate data directly from repository: ${freshCandidate.basicInfo!.fullName}',
              );

              // Update controller with fresh data
              dataController.candidate.value = freshCandidate;
              dataController.editedData.value = freshCandidate;

              setState(() {
                candidate = freshCandidate;
              });

              // Initialize TabController after getting candidate data
              _tabController?.dispose();
              _tabController = TabController(
                length: _isOwnProfile ? 7 : 6,
                vsync: this,
              );
              _tabController?.addListener(_onTabChanged);
              _loadPlanFeatures();
              await _loadLocationData();

              // Mark screen as loaded after all data is ready
              if (mounted) {
                setState(() {
                  _screenState = ProfileScreenState.loaded;
                });
              }
            } else {
              AppLogger.candidate('❌ LOAD: No candidate data found in repository');
              if (mounted) {
                setState(() {
                  _screenState = ProfileScreenState.candidateNotFound;
                });
              }
            }
          }
        } catch (e) {
          AppLogger.candidateError(
            '❌ Failed to load own candidate data: $e',
          );
          if (mounted) {
            setState(() {
              _screenState = ProfileScreenState.error;
            });
          }
        }
      });

      // Listen to candidate data changes for real-time updates (only for own profile)
      ever(dataController.candidate, (Candidate? newCandidate) {
        if (newCandidate != null && mounted) {
          AppLogger.candidate('🔄 Own candidate data updated in profile screen, refreshing UI');
          setState(() {
            candidate = newCandidate;
          });
        }
      });
    } else {
      // For other profiles, check cache first
      if (argumentsCandidate != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final cachedCandidate = dataController.getCachedProfile(argumentsCandidate.candidateId);
          if (cachedCandidate != null) {
            AppLogger.candidate('✅ Using cached data for candidate profile: ${argumentsCandidate.candidateId}');
            setState(() {
              candidate = cachedCandidate;
            });

            // Initialize TabController after getting candidate data
            _tabController?.dispose();
            _tabController = TabController(
              length: _isOwnProfile ? 7 : 6,
              vsync: this,
            );
            _tabController?.addListener(_onTabChanged);
            _loadPlanFeatures();
            await _loadLocationData();

            // Mark screen as loaded after all data is ready
            if (mounted) {
              setState(() {
                _screenState = ProfileScreenState.loaded;
              });
            }

            // Do a background refresh to ensure data is up to date
            _refreshOtherCandidateDataSilently(argumentsCandidate.candidateId);
          } else {
            AppLogger.candidate('🔄 No cached data found, using arguments data for candidate: ${argumentsCandidate.candidateId}');
            candidate = argumentsCandidate;

            // Cache this profile for future use
            dataController.cacheProfile(argumentsCandidate);
          }
        });
      }
    }

    // Initialize TabController after determining profile ownership
    // Length is 6 for non-own profiles (no analytics), 7 for own profile (with analytics)
    _tabController = TabController(length: _isOwnProfile ? 7 : 6, vsync: this);
    _tabController?.addListener(_onTabChanged);

    // Always refresh candidate data to get latest contact and other info for all profiles
    if (candidate != null) {
      AppLogger.candidate('🔄 Calling _refreshCandidateFollowingData for all profiles');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _refreshCandidateFollowingData();
      });
    }

    // Check follow status when screen loads
    if (currentUserId != null && candidate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('📋 PROFILE_SCREEN_INIT: Checking follow status for $currentUserId -> ${candidate!.candidateId}');
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

    // Mark screen as loaded after all data is ready
    if (mounted) {
      setState(() {
        _screenState = ProfileScreenState.loaded;
      });
    }

    // Track profile view (only for other users viewing this profile)
    if (!_isOwnProfile && candidate != null) {
      _trackProfileView();
    }
  }



  // Refresh candidate data using direct document path (fast!)
  // Note: This preserves controller follow status to avoid UI inconsistencies
  Future<void> _refreshCandidateFollowingData() async {
    final location = candidate!.location;
    final stateId = location.stateId ?? 'maharashtra';
    final districtId = location.districtId;
    final bodyId = location.bodyId;
    final wardId = location.wardId;

    if (districtId == null || bodyId == null || wardId == null) {
      AppLogger.candidate('⚠️ Missing location data, skipping refresh');
      return;
    }

    try {
      // Direct document query using embedded location data
      final candidateDoc = await FirebaseFirestore.instance
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidate!.candidateId)
          .get();

      if (candidateDoc.exists && mounted) {
        final data = candidateDoc.data()!;
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = candidateDoc.id;

        late Candidate freshCandidate = Candidate.fromJson(candidateData);

        AppLogger.candidate(
          '✅ Refreshed candidate data instantly - following count: ${freshCandidate.followingCount}',
        );

        // CRITICAL: Preserve UI state when server data is stale
        // Don't let server refreshes override controller's optimistic follow updates
        final currentFollowStatus = controller.followStatus[candidate!.candidateId] ?? false;
        final serverFollowingCount = freshCandidate.followingCount ?? 0;

        // If controller shows user followed this candidate but server shows 0 followers,
        // it means the follow hasn't been processed by background sync yet.
        // Preserve UI state to avoid visual inconsistencies.
        if (currentFollowStatus && freshCandidate.followersCount == 0) {
          AppLogger.candidate(
            '⚠️ Controller shows followed but server reports 0. Preserving optimistic UI state.',
          );

          // Use copyWith to create new candidate with preserved follower counts
          // Update only non-follow-related data from server
          freshCandidate = freshCandidate.copyWith(
            contact: freshCandidate.contact,
            events: freshCandidate.events,
            media: freshCandidate.media,
            analytics: freshCandidate.analytics,
            followersCount: candidate!.followersCount, // PRESERVE UI STATE
            followingCount: candidate!.followingCount, // PRESERVE UI STATE
          );
        }

        setState(() {
          candidate = freshCandidate;
        });
      } else {
        AppLogger.candidate('⚠️ Could not refresh candidate data');
      }
    } catch (e) {
      AppLogger.candidateError(
        '❌ Error refreshing candidate following data: $e',
      );
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

  // Load location data (platform-aware for authenticated users)
  Future<void> _loadLocationData() async {
    AppLogger.candidate(
      '🔍 [Candidate Profile] Loading location data for candidate ${candidate?.candidateId}',
    );
    AppLogger.candidate(
      '📍 [Candidate Profile] IDs: district=${candidate?.location.districtId}, body=${candidate?.location.bodyId}, ward=${candidate?.location.wardId}',
    );

    if (candidate == null) return;

    try {
      // Use platform-aware location loading (works on web and mobile)
      AppLogger.candidate('🔐 [Authenticated User] Using platform-aware location loading...');
      await _loadAuthenticatedLocationData();

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

  // Platform-aware location loading for authenticated users (works on web and mobile)
  Future<void> _loadAuthenticatedLocationData() async {
    // Since database is not available, use IDs as names
    if (mounted) {
      setState(() {
        _districtName = candidate!.location.districtId;
        _bodyName = candidate!.location.bodyId;
        _wardName = 'Ward ${candidate!.location.wardId}';
      });
    }

    AppLogger.candidate(
      '✅ [Candidate Profile] Location data loaded successfully (using IDs):',
    );
    AppLogger.candidate('   📍 District: $_districtName');
    AppLogger.candidate('   🏛️ Body: $_bodyName');
    AppLogger.candidate('   🏛️ Ward: $_wardName');
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

      // Achievements Tab
      AchievementsTabView(candidate: candidate!),

      // Media Tab
      MediaTabViewReactive(candidate: candidate!, isOwnProfile: false),

      // Contact Tab - Show data immediately, refresh happens in background
      ContactTabView(candidate: candidate!),

      // Events Tab - Always show VoterEventsSection for viewing events with RSVP functionality
      VoterEventsSection(candidateData: candidate!),

      // Analytics Tab (only for own profile)
      if (_isOwnProfile)
        FollowersAnalyticsSection(candidateData: candidate!),
    ];

    return tabViews;
  }

  // Tab change listener
  void _onTabChanged() {
    if (_tabController?.indexIsChanging == false) {
      // Only log when tab change is complete
      final tabNames = [
        CandidateLocalizations.of(context)?.info ?? 'Info',
        CandidateLocalizations.of(context)?.manifesto ?? 'Manifesto',
        CandidateLocalizations.of(context)?.achievements ?? 'Achievements',
        CandidateLocalizations.of(context)?.media ?? 'Media',
        CandidateLocalizations.of(context)?.contact ?? 'Contact',
        CandidateLocalizations.of(context)?.events ?? 'Events',
      ];

      // Add analytics tab name only for own profile
      if (_isOwnProfile) {
        tabNames.add(CandidateLocalizations.of(context)?.analytics ?? 'Analytics');
      }

      if (_tabController!.index < tabNames.length) {
        final currentTab = tabNames[_tabController!.index];
        AppLogger.candidate('🔄 Tab switched to: $currentTab');
      }
    }
  }

  // Format date helper
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get current locale
  String _getCurrentLocale() {
    final locale = Localizations.localeOf(context);
    return locale.languageCode;
  }

  // Format number helper
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

  // Sync with controller data for own profile
  void _syncWithControllerData() {
    if (_isOwnProfile && dataController.candidateData.value != null) {
      AppLogger.candidate('🔄 Syncing profile screen with controller data');
      setState(() {
        candidate = dataController.candidateData.value;
      });
    }
  }

  // Share profile functionality
  Future<void> _shareProfile() async {
    if (candidate == null) return;

    final candidateName = candidate!.basicInfo?.fullName ?? 'This candidate';

    try {
      // Generate the profile URL
      final url = ShareCandidateProfileService().generateFullProfileUrl(
        candidateId: candidate!.candidateId,
        stateId: candidate!.location.stateId ?? 'maharashtra',
        districtId: candidate!.location.districtId ?? '',
        bodyId: candidate!.location.bodyId ?? '',
        wardId: candidate!.location.wardId ?? '',
      );

      final subject = 'Check out $candidateName\'s candidate profile on Janmat';

      // Use native share sheet
      await Share.share(url, subject: subject);

      SnackbarUtils.showSuccess('Profile link shared successfully!');
    } catch (e) {
      AppLogger.candidateError('❌ Error sharing profile: $e');
      SnackbarUtils.showError('Failed to share profile');
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

      SnackbarUtils.showSuccess('Profile data refreshed!');
    } catch (e) {
      SnackbarUtils.showError('Failed to refresh data: $e');
    }
  }

  // Silent background refresh without UI feedback
  Future<void> _refreshCandidateDataSilently() async {
    try {
      AppLogger.candidate('🔄 Background refresh: Updating candidate data silently');

      // For own profile, refresh from controller silently
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

      AppLogger.candidate('✅ Background refresh completed successfully');
    } catch (e) {
      AppLogger.candidateError('❌ Background refresh failed: $e');
      // Don't show error to user for silent refresh
    }
  }

  // Silent background refresh for other candidates' profiles
  Future<void> _refreshOtherCandidateDataSilently(String candidateId) async {
    try {
      AppLogger.candidate('🔄 Background refresh for other candidate: $candidateId');

      // Load fresh data from repository
      final candidateRepository = CandidateRepository();
      final freshCandidate = await candidateRepository.getCandidateData(candidateId);

      if (freshCandidate != null) {
        // Update cache with fresh data
        dataController.cacheProfile(freshCandidate);

        // Update UI if this screen is still showing this candidate
        if (mounted && candidate != null && candidate!.candidateId == candidateId) {
          setState(() {
            candidate = freshCandidate;
          });
          AppLogger.candidate('✅ Background refresh updated UI for candidate: $candidateId');
        }
      }

      // Refresh follow status if user is logged in
      if (currentUserId != null) {
        await controller.checkFollowStatus(currentUserId!, candidateId);
      }

      AppLogger.candidate('✅ Background refresh for other candidate completed: $candidateId');
    } catch (e) {
      AppLogger.candidateError('❌ Background refresh for other candidate failed: $e');
      // Don't show error to user for silent refresh
    }
  }

  // Retry loading candidate - for error states
  Future<void> _retryLoadCandidate() async {
    setState(() {
      _screenState = ProfileScreenState.loading;
    });

    // Restart the init flow
    // This is a simplified retry - in production we'd want to extract the loading logic
    if (candidate != null) {
      setState(() {
        _screenState = ProfileScreenState.loaded;
      });
    } else {
      // If candidate is still null, try reloading for own profile
      if (currentUserId != null) {
        try {
          await dataController.loadCandidateUserData(currentUserId!);
          if (dataController.candidate.value != null) {
            setState(() {
              candidate = dataController.candidate.value;
              _screenState = ProfileScreenState.loaded;
            });
            return;
          }
        } catch (e) {
          // Continue to error state
        }
      }

      setState(() {
        _screenState = ProfileScreenState.candidateNotFound;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // Handle different screen states
    switch (_screenState) {
      case ProfileScreenState.loading:
        return Scaffold(
          appBar: AppBar(
            title: Text(CandidateLocalizations.of(context)!.candidateProfile),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: const CandidateProfileSkeletonLoader(),
        );

      case ProfileScreenState.candidateNotFound:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Candidate Profile'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: CandidateNotFoundError(
            onRetry: _retryLoadCandidate,
            onBrowseCandidates: () => Get.offAllNamed(AppRouteNames.home),
          ),
        );

      case ProfileScreenState.networkError:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Candidate Profile'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: NetworkErrorWidget(
            onRetry: _retryLoadCandidate,
            customMessage: 'Unable to load candidate profile. Please check your connection.',
          ),
        );

      case ProfileScreenState.error:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Candidate Profile'),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ErrorStateWidget(
            errorType: ErrorType.server,
            onRetry: _retryLoadCandidate,
          ),
        );

      case ProfileScreenState.loaded:
        // Check if candidate data is actually available
        if (candidate == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(CandidateLocalizations.of(context)!.candidateProfile),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: CandidateNotFoundError(
              onRetry: _retryLoadCandidate,
              onBrowseCandidates: () => Get.offAllNamed(AppRouteNames.home),
            ),
          );
        }
        // Continue with normal profile view
        break;
    }

    // Check if candidate is premium based on plan permissions
    bool isPremiumCandidate = _hasPremiumBadge;

    return Scaffold(
      appBar: AppBar(
        title: Text(CandidateLocalizations.of(context)!.candidateProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Share button for all users (guests and authenticated)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProfile(),
            tooltip: 'Share Profile',
          ),

          // Edit button only for profile owner
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
                            // AppLogger.candidate(
                            //   '🏛️ [Profile Screen] Building ProfileHeaderWidget:',
                            // );
                            // AppLogger.candidate(
                            //   '   wardName passed: $_wardName',
                            // );
                            // AppLogger.candidate(
                            //   '   districtName passed: $_districtName',
                            // );
                            // AppLogger.candidate(
                            //   '   body name passed: $_bodyName',
                            // );

                            // AppLogger.candidate(
                            //   '   candidate wardId: ${candidate!.location.wardId}',
                            // );
                            // AppLogger.candidate(
                            //   '   candidate districtId: ${candidate!.location.districtId}',
                            // );
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
