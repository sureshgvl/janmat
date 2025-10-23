import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/app_logger.dart';

/// Centralized controller for managing user data across the entire app.
/// Eliminates redundant Firebase calls by caching user data and providing reactive updates.
/// Follows the GetX controller pattern for consistency with the app architecture.
class UserDataController extends GetxController {
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
  String? get stateId => currentUser.value?.stateId;
  String? get districtId => currentUser.value?.districtId;
  String? get bodyId => currentUser.value?.bodyId;
  String? get wardId => currentUser.value?.wardId;
  String? get area => currentUser.value?.area;
  bool get isProfileCompleted => currentUser.value?.profileCompleted ?? false;
  bool get isRoleSelected => currentUser.value?.roleSelected ?? false;

  // Reactive streams for components that need to react to user data changes
  Stream<UserModel?> get userStream => currentUser.stream;
  Stream<bool> get loadingStream => isLoading.stream;

  @override
  void onInit() {
    super.onInit();
    AppLogger.core('🧑 UserDataController initialized');
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Setup Firebase Auth state listener to automatically load user data on login
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadUserData(user.uid);
      } else {
        clearUserData();
      }
    });
  }

  /// Load user data from Firestore with caching
  Future<void> loadUserData(String userId) async {
    try {
      isLoading.value = true;

      // Check if we have valid cached data
      if (_hasValidCache() && currentUser.value?.uid == userId) {
        AppLogger.core('✅ Using cached user data for $userId');
        isInitialized.value = true;
        isLoading.value = false;
        return;
      }

      AppLogger.core('🔍 Loading user data from Firestore for $userId');

      // Set up real-time listener for user data
      _userDocSubscription?.cancel();
      _userDocSubscription = _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          currentUser.value = UserModel.fromJson(userData);
          _lastFetchTime = DateTime.now();
          isInitialized.value = true;
          AppLogger.core('📡 User data updated via real-time listener for $userId');
        } else {
          AppLogger.core('⚠️ User document not found for $userId');
          clearUserData();
        }
      });

      // Wait for initial data load
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
      AppLogger.coreError('❌ Failed to load user data', error: e);
      clearUserData();
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update(updates);

      // Local update will happen via real-time listener
      // No need to manually update currentUser.value

    } catch (e) {
      AppLogger.coreError('❌ Failed to update user data', error: e);
      throw e;
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

  /// Check if cache is valid
  bool _hasValidCache() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Cleanup resources
  void _cleanup() {
    _userDocSubscription?.cancel();
    _authStateSubscription?.cancel();
    clearUserData();
    AppLogger.core('🧹 UserDataController cleaned up');
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