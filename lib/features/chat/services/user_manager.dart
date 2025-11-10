import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../user/models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';

/// Service responsible for user management in chat functionality
/// Handles user authentication, data caching, and premium status
class UserManager {
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cached user data to avoid repeated Firestore calls
  UserModel? _cachedUser;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Reactive user data
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  /// Get current authenticated user with caching
  Future<UserModel?> getCurrentUser() async {
    try {
      // Check cache validity
      if (_cachedUser != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
        AppLogger.chat('UserManager: Returning cached user: ${_cachedUser!.name}');
        return _cachedUser;
      }

      // Get Firebase user
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        AppLogger.chat('UserManager: No authenticated Firebase user');
        _clearCache();
        return null;
      }

      // Fetch complete user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        AppLogger.chat('UserManager: User document not found in Firestore');
        _clearCache();
        return null;
      }

      // Parse user data
      final userData = userDoc.data()!;
      _cachedUser = UserModel.fromJson(userData);
      _lastFetchTime = DateTime.now();

      // Update reactive state
      currentUser.value = _cachedUser;

      AppLogger.chat('UserManager: Loaded user: ${_cachedUser!.name} (${_cachedUser!.role})');
      return _cachedUser;

    } catch (e) {
      AppLogger.chat('UserManager: Error getting current user: $e');
      _clearCache();
      return null;
    }
  }

  /// Check if current user can send messages (premium or has quota)
  Future<bool> canSendMessage() async {
    final user = await getCurrentUser();
    if (user == null) return false;

    // Premium users always can send
    if (user.premium) return true;

    // Check quota - this will be handled by UserQuotaManager
    // For now, assume they can send (quota checking delegated)
    return true;
  }

  /// Check if user should see watch ads button
  Future<bool> shouldShowWatchAdsButton() async {
    final user = await getCurrentUser();
    if (user == null || user.premium) return false;

    // Show if user is not premium (ads are alternative to premium)
    return true;
  }

  /// Get remaining messages for current user
  Future<int> getRemainingMessages() async {
    final user = await getCurrentUser();
    if (user == null) return 0;

    // Premium users have unlimited
    if (user.premium) return 999;

    // This will be calculated by UserQuotaManager
    // For now return a default
    return 10;
  }

  /// Get user election areas for room filtering
  Future<List<ElectionArea>> getUserElectionAreas() async {
    final user = await getCurrentUser();
    return user?.electionAreas ?? [];
  }

  /// Get user's regular election area (most commonly used)
  Future<ElectionArea?> getRegularElectionArea() async {
    final areas = await getUserElectionAreas();
    return areas.isNotEmpty
        ? areas.firstWhere(
            (area) => area.type == ElectionType.regular,
            orElse: () => areas.first,
          )
        : null;
  }

  /// Invalidate user cache (useful after profile updates)
  void invalidateCache() {
    AppLogger.chat('UserManager: Invalidating user cache');
    _clearCache();
  }

  /// Clear cached data
  void _clearCache() {
    _cachedUser = null;
    _lastFetchTime = null;
    currentUser.value = null;
  }

  /// Listen to user data changes in real-time
  Stream<UserModel?> watchCurrentUser() {
    return currentUser.stream;
  }

  /// Update user data in cache (after local changes)
  void updateCachedUser(UserModel user) {
    _cachedUser = user;
    _lastFetchTime = DateTime.now();
    currentUser.value = user;
    AppLogger.chat('UserManager: Updated cached user: ${user.name}');
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authRepository.currentUser != null;

  /// Get Firebase user ID
  String? get currentUserId => _authRepository.currentUser?.uid;
}
