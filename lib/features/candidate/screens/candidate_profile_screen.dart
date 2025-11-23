import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../services/guest_routing_service.dart';
import '../../../services/public_candidate_service.dart';
import '../../../services/share_candidate_profile_service.dart';
import '../../../widgets/common/shimmer_loading_widgets.dart';
import '../../../widgets/common/error_state_widgets.dart';
import '../../../core/app_route_names.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/candidate_user_controller.dart';
import '../widgets/view/basic_info/basic_info_tab_view.dart';
import '../widgets/view/manifesto/manifesto_view.dart';
import '../widgets/view/media/media_view.dart';
import '../widgets/view/contact/contact_tab_view.dart';
import '../widgets/view/achievements/achievements_tab_view.dart';

import '../widgets/view/events/events_tab_view.dart';
import '../widgets/view/followers_analytics_tab_view.dart';
import '../widgets/profile_header_widget.dart';
import '../widgets/follow_stats_widget.dart';
import '../widgets/profile_tab_bar_widget.dart';
import '../../../utils/symbol_utils.dart';
import '../../monetization/services/plan_service.dart';
import '../../../services/local_database_service.dart';
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
  final bool isGuestAccess;

  const CandidateProfileScreen({
    super.key,
    this.isGuestAccess = false,
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

    // Check if this is guest access (from URL parameters)
    final args = Get.arguments;
    if (args is PublicCandidateUrlParams) {
      // Handle guest access via URL parameters
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _handleGuestAccess(args);
      });
      return;
    }

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

    candidate = Get.arguments as Candidate;

    // Determine if this is the user's own profile
    _isOwnProfile =
        currentUserId != null &&
        candidate != null &&
        currentUserId == candidate!.userId;

    AppLogger.candidate(
      '👤 Profile ownership check: currentUserId=$currentUserId, candidateUserId=${candidate!.userId}, isOwnProfile=$_isOwnProfile',
    );

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

  /// Handle guest access via URL parameters
  Future<void> _handleGuestAccess(PublicCandidateUrlParams urlParams) async {
    try {
      AppLogger.candidate('🚪 Handling guest access for URL: ${urlParams.toString()}');

      // Set guest access flag
      _isOwnProfile = false; // Guests can't edit profiles

      // Initialize TabController for guest access (6 tabs, no analytics)
      _tabController = TabController(length: 6, vsync: this);
      _tabController?.addListener(_onTabChanged);

      // Fetch candidate data using public service
      final fetchedCandidate = await PublicCandidateService().getCandidateByFullPath(
        stateId: urlParams.stateId,
        districtId: urlParams.districtId,
        bodyId: urlParams.bodyId,
        wardId: urlParams.wardId,
        candidateId: urlParams.candidateId,
      );

      if (fetchedCandidate == null) {
        AppLogger.candidate('❌ Guest access failed - candidate not found');
        SnackbarUtils.showError(
          CandidateLocalizations.of(context)?.candidateDataNotFound ??
              'Candidate profile not found',
        );
        _navigateGuestBack();
        return;
      }

      AppLogger.candidate('✅ Guest access successful - loaded candidate: ${fetchedCandidate.basicInfo?.fullName}');

      setState(() {
        candidate = fetchedCandidate;
      });

      // Track guest profile view
      await PublicCandidateService().trackGuestProfileView(
        candidateId: urlParams.candidateId,
        candidateName: fetchedCandidate.basicInfo?.fullName,
        source: 'direct_url',
      );

      // Load location data for display (optimized batched queries)
      await _loadLocationData();

      // Note: Plan features are skipped for guests (no auth required)

      // ✅ Mark screen as loaded after guest access success
      if (mounted) {
        setState(() {
          _screenState = ProfileScreenState.loaded;
        });
      }

    } catch (e, stackTrace) {
      AppLogger.candidateError('❌ Guest access failed: $e $stackTrace');
      SnackbarUtils.showError('Failed to load candidate profile');
      _navigateGuestBack();
    }
  }

  /// Navigate back for guest users (different from authenticated users)
  void _navigateGuestBack() {
    if (GuestRoutingService.isCurrentlyInGuestMode()) {
      // For guests, navigate to login screen
      Get.offAllNamed(AppRouteNames.login);
    } else {
      // For authenticated users, normal back navigation
      Navigator.of(context).pop();
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

  // Load location data (optimized for different access types)
  Future<void> _loadLocationData() async {
    AppLogger.candidate(
      '🔍 [Candidate Profile] Loading location data for candidate ${candidate?.candidateId} (${widget.isGuestAccess ? 'guest' : 'authenticated'})',
    );
    AppLogger.candidate(
      '📍 [Candidate Profile] IDs: district=${candidate?.location.districtId}, body=${candidate?.location.bodyId}, ward=${candidate?.location.wardId}',
    );

    if (candidate == null) return;

    try {
      // For guest access: Use optimized PublicCandidateService with batched, cached queries
      if (widget.isGuestAccess) {
        AppLogger.candidate('🚀 [Guest Access] Using optimized batched location loading...');

        final locationData = await PublicCandidateService().getLocationDisplayData(
          stateId: candidate!.location.stateId ?? 'maharashtra',
          districtId: candidate!.location.districtId ?? '',
          bodyId: candidate!.location.bodyId ?? '',
          wardId: candidate!.location.wardId ?? '',
        );

        if (mounted) {
          setState(() {
            _districtName = locationData['districtName'];
            _bodyName = locationData['bodyName'];
            _wardName = locationData['wardName'];
          });
        }

        AppLogger.candidate(
          '✅ [Guest Access] Location data loaded from cache/batch:',
        );
        AppLogger.candidate('   📍 District: $_districtName');
        AppLogger.candidate('   🏛️ Body: $_bodyName');
        AppLogger.candidate('   🏛️ Ward: $_wardName');
        return;
      }

      // For authenticated users: Use platform-aware location loading (works on web and mobile)
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
    // Load location data using platform-aware method (works on web and mobile)
    final locationData = await _locationDatabase.getCandidateLocationDataWeb(
      candidate!.location.districtId ?? '',
      candidate!.location.bodyId ?? '',
      candidate!.location.wardId ?? '',
      candidate!.location.stateId ?? 'maharashtra',
    );

    if (mounted) {
      setState(() {
        _districtName = locationData['districtName'];
        _bodyName = locationData['bodyName'];
        _wardName = locationData['wardName'];
      });
    }

    AppLogger.candidate(
      '✅ [Candidate Profile] Location data loaded successfully (platform-aware):',
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

      // Achievements Tab
      AchievementsTabView(candidate: candidate!),

      // Media Tab
      MediaTabView(candidate: candidate!, isOwnProfile: false),

      // Contact Tab - Show data immediately, refresh happens in background
      ContactTabView(candidate: candidate!),

      // Events Tab - Always show VoterEventsSection for viewing events with RSVP functionality
      VoterEventsSection(candidateData: candidate!),
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

  // Retry loading candidate - for error states
  Future<void> _retryLoadCandidate() async {
    setState(() {
      _screenState = ProfileScreenState.loading;
    });

    // For guest access, retry the guest access flow
    if (Get.arguments is PublicCandidateUrlParams) {
      await _handleGuestAccess(Get.arguments as PublicCandidateUrlParams);
      return;
    }

    // For normal access, restart the init flow
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
            isGuest: widget.isGuestAccess,
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
            // Check if this is guest access (accessed via direct URL)
            final isGuestUser = GuestRoutingService.isCurrentlyInGuestMode();

            if (isGuestUser) {
              // Guest user behavior: Navigate to login screen for exploration
              AppLogger.common('🚪 Guest user navigating back from profile');
              Get.offAllNamed(AppRouteNames.login);
            } else {
              // Normal authenticated user behavior
              Navigator.of(context).pop();
            }
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
}
