import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/services/home_data_preloader.dart';
import 'package:janmat/features/home/services/home_services.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/user/services/user_status_manager.dart';

/// Stream-based service for HomeScreen data loading
class HomeScreenStreamService {
  static final HomeScreenStreamService _instance = HomeScreenStreamService._internal();
  factory HomeScreenStreamService() => _instance;

  HomeScreenStreamService._internal();

  final StreamController<HomeScreenData> _dataController = StreamController<HomeScreenData>.broadcast();
  Stream<HomeScreenData> get dataStream => _dataController.stream;

  bool _isListening = false;
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;

  /// Initialize stream service
  void initialize() {
    if (_isListening) return;

    AppLogger.common('🎯 Initializing HomeScreen stream service');

    // Listen to authentication state
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);

    // Initialize preloader
    homeDataPreloader.initializeWithAppStartup();

    _isListening = true;
    AppLogger.common('✅ HomeScreen stream service initialized');
  }

  /// 🚀 INSTANT HOME: Pre-load cached data for immediate UI display
  void preloadWithCachedData(Map<String, dynamic> cachedData) {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      // 🚀 INSTANT DISPLAY: Try to load cached candidate data first for immediate UI
      _tryEmitInstantCachedData(userId).then((success) {
        if (!success) {
          // Fallback to routing data if no cached candidate data
          final role = cachedData['role'];
          final hasSelectedRole = cachedData['hasSelectedRole'] ?? false;

          final cachedHomeData = HomeScreenData.partial(
            userId: userId,
            role: role,
            hasCompletedProfile: null, // Null means "don't know yet"
            hasSelectedRole: hasSelectedRole,
          );

          if (!_dataController.isClosed) {
            _dataController.add(cachedHomeData);
            AppLogger.common('⚡ INSTANT HOME: Pre-loaded partial cached data');
          }
        }
      });
    } catch (e) {
      AppLogger.common('⚠️ Failed to preload cached data: $e');
    }
  }

  /// 🚀 INSTANT DISPLAY: Try to emit cached candidate data immediately (no-op)
  Future<bool> _tryEmitInstantCachedData(String userId) async {
    AppLogger.common('⚡ INSTANT HOME: Cached data loading skipped (no caching)');
    return false;
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) {
    final userId = user?.uid;

    if (userId != _currentUserId) {
      _currentUserId = userId;

      if (userId != null) {
        // User signed in
        _emitLoadingState(userId);
        _loadDataForUser(userId);
      } else {
        // User signed out
        _emitSignedOutState();
      }
    }
  }

  /// Emit loading state
  void _emitLoadingState(String userId) {
    if (!_dataController.isClosed) {
      _dataController.add(HomeScreenData.loading(userId));
    }
  }

  /// Emit signed out state
  void _emitSignedOutState() {
    if (!_dataController.isClosed) {
      _dataController.add(HomeScreenData.signedOut());
    }
  }

  /// Load data for authenticated user
  void _loadDataForUser(String userId) async {
    try {
      // First emit with cached/placeholder data if available
      await _emitCachedOrPartialData(userId);

      // Then load fresh data in background
      await _loadFreshData(userId);
    } catch (e) {
      AppLogger.commonError('❌ Error loading home data', error: e);
      if (!_dataController.isClosed) {
        _dataController.add(HomeScreenData.error(e.toString(), userId));
      }
    }
  }

  /// Emit cached or partial data for instant UI (no-op)
  Future<void> _emitCachedOrPartialData(String userId) async {
    AppLogger.common('⚡ Partial data loading skipped (no caching) for: $userId');
    _emitLoadingState(userId);
  }

  /// Try to emit cached candidate data for instant display (no-op)
  Future<void> _tryEmitCachedCandidateData(String userId, Map<String, dynamic> routingData) async {
    AppLogger.common('⚡ Cached candidate data loading skipped (no caching) for: $userId');
    // Fall back to partial data if cached candidate data not available
    if (!_dataController.isClosed) {
      _dataController.add(HomeScreenData.partial(
        userId: userId,
        role: routingData['role'],
        hasCompletedProfile: routingData['hasCompletedProfile'] ?? false,
        hasSelectedRole: routingData['hasSelectedRole'] ?? false,
      ));
      AppLogger.common('⚠️ Fell back to partial data (no cached candidate data) for: $userId');
    }
  }

  /// Load fresh data from services
  Future<void> _loadFreshData(String userId) async {
    try {
      AppLogger.common('🔄 [STREAM_SERVICE] Loading fresh home data for: $userId');

      // Use HomeServices with preload integration
      AppLogger.common('🔄 [STREAM_SERVICE] Calling HomeServices.getUserDataWithPreload for: $userId');
      final result = await HomeServices().getUserDataWithPreload(
        userId,
        enablePreload: true,
      );
      AppLogger.common('✅ [STREAM_SERVICE] HomeServices returned result - user: ${result['user'] != null}, candidate: ${result['candidate'] != null}');

      // Handle both UserModel object and raw Map from cache/partial data
      final userModel = result['user'] is Map<String, dynamic>
        ? UserModel.fromJson(result['user'] as Map<String, dynamic>)
        : result['user'] as UserModel?;
      final rawCandidate = result['candidate'];
      final candidateModel = rawCandidate is Map<String, dynamic>
        ? Candidate.fromJson(rawCandidate)
        : rawCandidate as Candidate?;

      AppLogger.common('👤 [STREAM_SERVICE] Processed data - userModel: ${userModel?.name} (${userModel?.role}), candidateModel: ${candidateModel?.basicInfo?.fullName ?? 'null'}');

      if (userModel != null) {
        // Extract navigation data for routing cache
        final routingData = {
          'hasCompletedProfile': userModel.profileCompleted,
          'hasSelectedRole': userModel.roleSelected,
          'role': userModel.role,
          'lastLogin': DateTime.now().toIso8601String(),
        };

        // Cache routing data for future instant loads (no-op)
        AppLogger.common('⚡ Routing data caching skipped (no caching) for: $userId');

        // Initialize candidate controller if user is a candidate - ARCHITECTURAL FIX
        if (userModel.role == 'candidate') {
          try {
            final candidateController = Get.find<CandidateUserController>();

            // ARCHITECTURAL FIX: Prevent redundant controller initialization during app lifecycle events
            // Only call initializeForCandidate() on first initialization, not on every data refresh
            if (!candidateController.isInitialized.value || candidateController.user.value?.uid != userModel.uid) {
              AppLogger.common('🎯 Initializing candidate controller (first-time or user changed): $userId');

              // Set user data first (critical for initialization order)
              candidateController.user.value = userModel;
              AppLogger.common('👤 Candidate controller user role: ${candidateController.user.value?.role}', tag: 'HOME_CHECK');

              if (candidateModel != null) {
                candidateController.candidate.value = candidateModel;
                candidateController.isInitialized.value = true;
                AppLogger.common('✅ Synchronized candidate data to controller for user: $userId');
              } else {
                candidateController.isInitialized.value = false;
                AppLogger.common('⚠️ No candidate data available, will load via initializeForCandidate()', tag: 'HOME_CHECK');
              }

              candidateController.initializeForCandidate();
              AppLogger.common('✅ Candidate controller initialization triggered for user: $userId');
            } else {
              // Controller already initialized - just sync latest data without re-initialization
              AppLogger.common('🔄 Skipping redundant candidate controller initialization for: $userId');

              // Still sync latest user/candidate data for consistency
              candidateController.user.value = userModel;
              if (candidateModel != null) {
                candidateController.candidate.value = candidateModel;
              }
            }
          } catch (e) {
            AppLogger.commonError('❌ Failed to initialize candidate controller', error: e);
          }
        }

        // Emit complete data
        if (!_dataController.isClosed) {
          _dataController.add(HomeScreenData.complete(
            userId: userId,
            userModel: userModel,
            candidateModel: candidateModel,
          ));
          AppLogger.common('✅ Fresh home data loaded for: $userId');
        }
      } else {
        if (!_dataController.isClosed) {
          _dataController.add(HomeScreenData.noData(userId));
        }
      }
    } catch (e) {
      AppLogger.commonError('❌ Error loading fresh home data', error: e);
      if (!_dataController.isClosed) {
        _dataController.add(HomeScreenData.error(e.toString(), userId));
      }
    }
  }

  /// Refresh data (called by user interaction)
  Future<void> refreshData({bool forceRefresh = false}) async {
    if (_currentUserId != null) {
      if (forceRefresh) {
        _emitLoadingState(_currentUserId!);
      }
      await _loadFreshData(_currentUserId!);
    }
  }

  /// Re-emit current data (useful when screen comes back into focus)
  void reEmitCurrentData() {
    if (_currentUserId != null) {
      // Try to emit cached data first for instant UI
      _emitCachedOrPartialData(_currentUserId!).then((_) {
        // Then load fresh data in background
        _loadFreshData(_currentUserId!);
      }).catchError((e) {
        AppLogger.common('⚠️ Could not re-emit cached data: $e');
        // Fall back to loading fresh data
        _loadFreshData(_currentUserId!);
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _dataController.close();
    homeDataPreloader.dispose();
    _isListening = false;
    AppLogger.common('🧹 HomeScreen stream service disposed');
  }
}

/// Data model for HomeScreen stream
class HomeScreenData {
  final HomeScreenState state;
  final String? userId;
  final UserModel? userModel;
  final dynamic candidateModel;
  final dynamic cachedCandidateModel; // Cached candidate data for offline-first loading
  final String? errorMessage;
  final bool? hasCompletedProfile;
  final bool? hasSelectedRole;
  final String? role;

  HomeScreenData._({
    required this.state,
    this.userId,
    this.userModel,
    this.candidateModel,
    this.cachedCandidateModel,
    this.errorMessage,
    this.hasCompletedProfile,
    this.hasSelectedRole,
    this.role,
  });

  // Factory constructors for different states
  factory HomeScreenData.loading(String userId) => HomeScreenData._(
    state: HomeScreenState.loading,
    userId: userId,
  );

  factory HomeScreenData.signedOut() => HomeScreenData._(
    state: HomeScreenState.signedOut,
  );

  factory HomeScreenData.partial({
    required String userId,
    bool? hasCompletedProfile,
    bool? hasSelectedRole,
    String? role,
  }) => HomeScreenData._(
    state: HomeScreenState.partial,
    userId: userId,
    hasCompletedProfile: hasCompletedProfile,
    hasSelectedRole: hasSelectedRole,
    role: role,
  );

  factory HomeScreenData.cachedCandidate({
    required String userId,
    required UserModel userModel,
    required Candidate cachedCandidateModel,
  }) => HomeScreenData._(
    state: HomeScreenState.cachedCandidate,
    userId: userId,
    userModel: userModel,
    cachedCandidateModel: cachedCandidateModel,
  );

  factory HomeScreenData.complete({
    required String userId,
    required UserModel userModel,
    dynamic candidateModel,
  }) => HomeScreenData._(
    state: HomeScreenState.complete,
    userId: userId,
    userModel: userModel,
    candidateModel: candidateModel,
  );

  factory HomeScreenData.noData(String userId) => HomeScreenData._(
    state: HomeScreenState.noData,
    userId: userId,
  );

  factory HomeScreenData.error(String errorMessage, String userId) => HomeScreenData._(
    state: HomeScreenState.error,
    userId: userId,
    errorMessage: errorMessage,
  );

  // Computed properties
  bool get isLoading => state == HomeScreenState.loading;
  bool get isSignedOut => state == HomeScreenState.signedOut;
  bool get isComplete => state == HomeScreenState.complete;
  bool get hasError => state == HomeScreenState.error;
  bool get hasPartialData => state == HomeScreenState.partial;
  bool get hasNoData => state == HomeScreenState.noData;
  bool get hasCachedCandidate => state == HomeScreenState.cachedCandidate;

  // Navigation logic using UserStatusManager (priority: role selection first, then profile completion)
  Future<bool> get needsNavigation async {
    if (userId == null) return false;

    // Use UserStatusManager for instant navigation checks
    return await UserStatusManager().needsNavigation(userId!);
  }

  Future<String?> get navigationRoute async {
    if (userId == null) return null;

    // Use UserStatusManager for instant navigation route determination
    return await UserStatusManager().getNavigationRoute(userId!);
  }

  // For voter mode
  bool get isVoterMode => (isComplete || hasCachedCandidate) && userModel?.role != 'candidate';
  bool get isCandidateMode => (isComplete || hasCachedCandidate) && userModel?.role == 'candidate';

  // Get the effective candidate model (from fresh data or cached)
  Candidate? get effectiveCandidateModel => candidateModel ?? cachedCandidateModel;

  @override
  String toString() {
    return 'HomeScreenData(state: $state, userId: $userId, hasUser: ${userModel != null}, hasCandidate: ${candidateModel != null})';
  }
}

/// States for HomeScreen data loading
enum HomeScreenState {
  loading,
  signedOut,
  partial,
  cachedCandidate, // Offline-first cached candidate data state
  complete,
  noData,
  error,
}
