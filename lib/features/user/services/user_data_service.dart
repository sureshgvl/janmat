import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../../../../../../../utils/app_logger.dart';

/// Centralized service for managing user data across the entire app.
/// Eliminates redundant Firebase calls by caching user data and providing reactive updates.
class UserDataService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive user data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  // Cache timestamps for data freshness
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 30);

  // Getters for commonly accessed user properties
  String? get userId => currentUser.value?.uid;
  String? get userName => currentUser.value?.name;
  String? get userEmail => currentUser.value?.email;
  String? get userRole => currentUser.value?.role;
  String? get stateId => currentUser.value?.location?.stateId;
  String? get districtId => currentUser.value?.location?.districtId;
  String? get bodyId => currentUser.value?.location?.bodyId;
  String? get wardId => currentUser.value?.location?.wardId;
  String? get area => currentUser.value?.area;
  bool get isProfileCompleted => currentUser.value?.profileCompleted ?? false;
  bool get isRoleSelected => currentUser.value?.roleSelected ?? false;

  // Reactive streams for components that need to react to user data changes
  Stream<UserModel?> get userStream => currentUser.stream;
  Stream<bool> get loadingStream => isLoading.stream;

  @override
  void onInit() {
    super.onInit();
    AppLogger.core('🧑 UserDataService initialized');
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Setup Firebase Auth state listener to automatically load user data on login
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        AppLogger.core('🔐 User authenticated, loading user data: ${firebaseUser.uid}');
        loadUserData(firebaseUser.uid);
      } else {
        AppLogger.core('🚪 User logged out, clearing user data');
        clearUserData();
      }
    });
  }

  /// Load user data from Firestore and setup real-time updates
  Future<void> loadUserData(String userId) async {
    if (isLoading.value) return; // Prevent concurrent loads

    isLoading.value = true;
    AppLogger.core('📥 Loading user data for: $userId');

    try {
      // Check if we have valid cached data
      if (_hasValidCache() && currentUser.value?.uid == userId) {
        AppLogger.core('✅ Using cached user data (still valid)');
        isLoading.value = false;
        isInitialized.value = true;
        return;
      }

      // Direct Firestore call (no controller dependency for clean architecture)
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final userData = doc.data()!;
        currentUser.value = UserModel.fromJson(userData);
        _lastFetchTime = DateTime.now();

        AppLogger.core('✅ User data loaded: ${currentUser.value?.name} (${currentUser.value?.role})');
        isInitialized.value = true;

        // Setup real-time updates
        _setupRealtimeUpdates(userId);
      } else {
        AppLogger.core('⚠️ User document not found: $userId');
        currentUser.value = null;
      }
    } catch (e) {
      AppLogger.coreError('❌ Failed to load user data', error: e);
      currentUser.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup real-time updates for user data changes
  void _setupRealtimeUpdates(String userId) {
    // Cancel existing subscription
    _userDocSubscription?.cancel();

    // Setup new subscription
    _userDocSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final userData = doc.data()!;
              final newUserModel = UserModel.fromJson(userData);

              // Only update if data actually changed
              if (_hasUserDataChanged(newUserModel)) {
                currentUser.value = newUserModel;
                _lastFetchTime = DateTime.now();
                AppLogger.core('🔄 User data updated in real-time: ${newUserModel.name}');
              }
            } else {
              AppLogger.core('⚠️ User document deleted, clearing data');
              clearUserData();
            }
          },
          onError: (error) {
            AppLogger.coreError('❌ Real-time user data subscription error', error: error);
          },
        );

    AppLogger.core('📡 Real-time user data updates enabled');
  }

  /// Check if cached data is still valid
  bool _hasValidCache() {
    if (_lastFetchTime == null || currentUser.value == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Check if user data has actually changed to avoid unnecessary updates
  bool _hasUserDataChanged(UserModel newUser) {
    final current = currentUser.value;
    if (current == null) return true;

    return current.name != newUser.name ||
           current.email != newUser.email ||
           current.role != newUser.role ||
           current.location?.stateId != newUser.location?.stateId ||
           current.location?.districtId != newUser.location?.districtId ||
           current.location?.bodyId != newUser.location?.bodyId ||
           current.location?.wardId != newUser.location?.wardId ||
           current.area != newUser.area ||
           current.profileCompleted != newUser.profileCompleted ||
           current.roleSelected != newUser.roleSelected;
  }

  /// Force refresh user data (useful for critical operations)
  Future<void> refreshUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      AppLogger.core('🔄 Force refreshing user data');
      await loadUserData(userId);
    }
  }

  /// Update user data locally and in Firestore
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      AppLogger.core('📝 Updating user data: $updates');

      // Update in Firestore
      await _firestore.collection('users').doc(userId).update(updates);

      // Local update will happen via real-time listener
      // No need to manually update currentUser.value

    } catch (e) {
      AppLogger.coreError('❌ Failed to update user data', error: e);
      rethrow;
    }
  }

  /// Clear user data (on logout)
  void clearUserData() {
    currentUser.value = null;
    isInitialized.value = false;
    _lastFetchTime = null;
    _userDocSubscription?.cancel();
    _userDocSubscription = null;
    AppLogger.core('🧹 User data cleared');
  }

  /// Get fresh user data from Firestore (for critical operations)
  Future<UserModel?> getFreshUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      AppLogger.core('🔍 Fetching fresh user data for critical operation');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      AppLogger.coreError('❌ Failed to fetch fresh user data', error: e);
    }

    return null;
  }

  /// Check if user has specific role
  bool hasRole(String role) => userRole == role;

  /// Check if user is a candidate
  bool get isCandidate => hasRole('candidate');

  /// Check if user is a voter
  bool get isVoter => hasRole('voter');

  /// Get user location as a map (useful for location-based operations)
  Map<String, String?> getLocationData() {
    return {
      'stateId': stateId,
      'districtId': districtId,
      'bodyId': bodyId,
      'wardId': wardId,
      'area': area,
    };
  }

  /// Cleanup resources
  void _cleanup() {
    _userDocSubscription?.cancel();
    _authStateSubscription?.cancel();
    clearUserData();
    AppLogger.core('🧹 UserDataService cleaned up');
  }

  // Utility methods for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoading': isLoading.value,
      'isInitialized': isInitialized.value,
      'hasUserData': currentUser.value != null,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheValid': _hasValidCache(),
    };
  }
}
