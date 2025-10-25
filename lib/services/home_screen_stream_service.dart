import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/services/home_data_preloader.dart';
import 'package:janmat/utils/multi_level_cache.dart';
import 'package:janmat/features/home/services/home_services.dart';

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

      if (routingData != null) {
        // Emit partial data from routing cache
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

  /// Load fresh data from services
  Future<void> _loadFreshData(String userId) async {
    try {
      AppLogger.common('🔄 Loading fresh home data for: $userId');

      // Use HomeServices with preload integration
      final result = await HomeServices().getUserDataWithPreload(
        userId,
        enablePreload: true,
      );

      final userModel = result['user'] as UserModel?;
      final candidateModel = result['candidate'];

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
  final String? errorMessage;
  final bool? hasCompletedProfile;
  final bool? hasSelectedRole;
  final String? role;

  HomeScreenData._({
    required this.state,
    this.userId,
    this.userModel,
    this.candidateModel,
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
  bool get isVoterMode => isComplete && userModel?.role != 'candidate';
  bool get isCandidateMode => isComplete && userModel?.role == 'candidate';

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
  complete,
  noData,
  error,
}
