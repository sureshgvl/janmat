import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/services/home_data_preloader.dart';
import 'package:janmat/utils/multi_level_cache.dart';
import 'package:janmat/features/home/services/home_services.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';

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
    _dataController.add(HomeScreenData.loading(userId));
  }

  /// Emit signed out state
  void _emitSignedOutState() {
    _dataController.add(HomeScreenData.signedOut());
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
      _dataController.add(HomeScreenData.error(e.toString(), userId));
    }
  }

  /// Emit cached or partial data for instant UI
  Future<void> _emitCachedOrPartialData(String userId) async {
    try {
      // Check for cached user routing data first
      final routingData = await MultiLevelCache().getUserRoutingData(userId);

      if (routingData != null && routingData['role'] == 'candidate') {
        // For candidates, try to load cached candidate data for instant display
        await _tryEmitCachedCandidateData(userId, routingData);
      } else if (routingData != null) {
        // For non-candidates, emit partial data from routing cache
        _dataController.add(HomeScreenData.partial(
          userId: userId,
          role: routingData['role'],
          hasCompletedProfile: routingData['hasCompletedProfile'] ?? false,
          hasSelectedRole: routingData['hasSelectedRole'] ?? false,
        ));
        AppLogger.common('⚡ Emitted partial data from routing cache for: $userId');
      } else {
        // No routing data, keep loading
        _emitLoadingState(userId);
      }
    } catch (e) {
      // Ignore cache errors, continue with fresh load
      AppLogger.common('⚠️ Could not load partial data: $e');
    }
  }

  /// Try to emit cached candidate data for instant display
  Future<void> _tryEmitCachedCandidateData(String userId, Map<String, dynamic> routingData) async {
    try {
      // Try to get cached user and candidate data
      final cacheKey = 'home_user_data_$userId';
      final cachedHomeData = await MultiLevelCache().get<Map<String, dynamic>>(cacheKey);

      if (cachedHomeData != null && cachedHomeData['user'] != null && cachedHomeData['candidate'] != null) {
        // Convert cached data to models
        final userModel = cachedHomeData['user'] is Map<String, dynamic>
          ? UserModel.fromJson(cachedHomeData['user'] as Map<String, dynamic>)
          : cachedHomeData['user'] as UserModel;

        final candidateModel = cachedHomeData['candidate'] is Map<String, dynamic>
          ? Candidate.fromJson(cachedHomeData['candidate'] as Map<String, dynamic>)
          : cachedHomeData['candidate'] as Candidate;

        // Emit cached candidate data state for instant UI
        _dataController.add(HomeScreenData.cachedCandidate(
          userId: userId,
          userModel: userModel,
          cachedCandidateModel: candidateModel,
        ));

        AppLogger.common('⚡ Emitted cached candidate data for instant display: $userId');
        return;
      }
    } catch (e) {
      AppLogger.common('⚠️ Could not load cached candidate data: $e');
    }

    // Fall back to partial data if cached candidate data not available
    _dataController.add(HomeScreenData.partial(
      userId: userId,
      role: routingData['role'],
      hasCompletedProfile: routingData['hasCompletedProfile'] ?? false,
      hasSelectedRole: routingData['hasSelectedRole'] ?? false,
    ));
    AppLogger.common('⚠️ Fell back to partial data (no cached candidate data) for: $userId');
  }

  /// Load fresh data from services
  Future<void> _loadFreshData(String userId) async {
    try {
      AppLogger.common('🔄 Loading fresh home data for: $userId');

      // Use HomeServices with preload integration
      final result = await HomeServices().getUserDataWithPreload(
        userId,
        enablePreload: true,
      );

      // Handle both UserModel object and raw Map from cache/partial data
      final userModel = result['user'] is Map<String, dynamic>
        ? UserModel.fromJson(result['user'] as Map<String, dynamic>)
        : result['user'] as UserModel?;
      final rawCandidate = result['candidate'];
      final candidateModel = rawCandidate is Map<String, dynamic>
        ? Candidate.fromJson(rawCandidate)
        : rawCandidate as Candidate?;

      if (userModel != null) {
        // Extract navigation data for routing cache
        final routingData = {
          'hasCompletedProfile': userModel.profileCompleted,
          'hasSelectedRole': userModel.roleSelected,
          'role': userModel.role,
          'lastLogin': DateTime.now().toIso8601String(),
        };

        // Cache routing data for future instant loads
        await MultiLevelCache().setUserRoutingData(userId, routingData);

        // Initialize candidate controller if user is a candidate
        if (userModel.role == 'candidate') {
          try {
            final candidateController = Get.find<CandidateUserController>();
            // Ensure controller has the candidate data synchronized
            if (candidateModel != null && candidateController.candidate.value == null) {
              candidateController.candidate.value = candidateModel;
              candidateController.isInitialized.value = true;
              AppLogger.common('✅ Synchronized candidate data to controller for user: $userId');
            }
            candidateController.initializeForCandidate();
            AppLogger.common('✅ Candidate controller initialized for user: $userId');
          } catch (e) {
            AppLogger.commonError('❌ Failed to initialize candidate controller', error: e);
          }
        }

        // Emit complete data
        _dataController.add(HomeScreenData.complete(
          userId: userId,
          userModel: userModel,
          candidateModel: candidateModel,
        ));

        AppLogger.common('✅ Fresh home data loaded for: $userId');
      } else {
        _dataController.add(HomeScreenData.noData(userId));
      }
    } catch (e) {
      AppLogger.commonError('❌ Error loading fresh home data', error: e);
      _dataController.add(HomeScreenData.error(e.toString(), userId));
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

  bool get needsNavigation => isComplete && (
    !(userModel?.roleSelected ?? true) ||
    !(userModel?.profileCompleted ?? true)
  );

  String? get navigationRoute {
    if (!isComplete || userModel == null) return null;

    if (!userModel!.roleSelected) return '/role-selection';
    if (!userModel!.profileCompleted) return '/profile-completion';

    return null; // Stay on home
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
