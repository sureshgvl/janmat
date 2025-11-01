import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/following_model.dart';
import '../../../utils/app_logger.dart';

/// Centralized controller for managing user following relationships across the entire app.
/// Eliminates redundant following data fetches by caching relationships.
/// Follows the GetX controller pattern for consistency with the app architecture.
class FollowingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive following data
  final Rx<FollowingModel?> following = Rx<FollowingModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isInitialized = false.obs;

  // Stream subscriptions
  StreamSubscription<DocumentSnapshot>? _followingDocSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  // Cache timestamps for data freshness
  DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 10);

  // Getters for commonly accessed following properties
  String? get userId => following.value?.userId;
  List<String> get followingIds => following.value?.followingIds ?? [];
  int get followingCount => following.value?.followingCount ?? 0;
  Map<String, FollowingDetails> get followingDetails => following.value?.followingDetails ?? {};

  // Reactive streams for components that need to react to following changes
  Stream<FollowingModel?> get followingStream => following.stream;
  Stream<bool> get loadingStream => isLoading.stream;

  @override
  void onInit() {
    super.onInit();
    AppLogger.core('👥 FollowingController initialized');
    _setupAuthStateListener();
  }

  @override
  void onClose() {
    _cleanup();
    super.onClose();
  }

  /// Setup Firebase Auth state listener to automatically load following data on login
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadFollowingData(user.uid);
      } else {
        clearFollowing();
      }
    });
  }

  /// Load following data from Firestore with caching
  Future<void> loadFollowingData(String userId) async {
    try {
      isLoading.value = true;

      // Check if we have valid cached data
      if (_hasValidCache() && following.value?.userId == userId) {
        AppLogger.core('✅ Using cached following data for $userId');
        isInitialized.value = true;
        isLoading.value = false;
        return;
      }

      AppLogger.core('🔍 Loading following data from Firestore for $userId');

      // Set up real-time listener for following data
      _followingDocSubscription?.cancel();
      _followingDocSubscription = _firestore
          .collection('user_following')
          .doc(userId)
          .snapshots()
          .listen((docSnapshot) {
        if (docSnapshot.exists) {
          final followingData = docSnapshot.data() as Map<String, dynamic>;
          following.value = FollowingModel.fromJson(followingData);
          _lastFetchTime = DateTime.now();
          isInitialized.value = true;
          AppLogger.core('📡 Following data updated via real-time listener for $userId');
        } else {
          // Create empty following model if none exists
          final emptyFollowing = FollowingModel(
            userId: userId,
            followingIds: [],
            followingDetails: {},
            followingCount: 0,
            lastUpdated: DateTime.now(),
          );
          following.value = emptyFollowing;
          _lastFetchTime = DateTime.now();
          isInitialized.value = true;
          // Save empty following to Firestore
          _saveFollowingToFirestore(emptyFollowing);
          AppLogger.core('📝 Created empty following data for $userId');
        }
      });

      // Wait for initial data load
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
      AppLogger.coreError('❌ Failed to load following data', error: e);
      // Create fallback empty following
      following.value = FollowingModel(
        userId: userId,
        followingIds: [],
        followingDetails: {},
        followingCount: 0,
        lastUpdated: DateTime.now(),
      );
      isInitialized.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Follow a candidate/user
  Future<void> follow(String targetId, {String? reason, Map<String, dynamic> customSettings = const {}}) async {
    if (following.value == null || following.value!.isFollowing(targetId)) return;

    try {
      final details = FollowingDetails(
        targetId: targetId,
        followedAt: DateTime.now(),
        followReason: reason,
        customSettings: customSettings,
      );

      final updatedFollowing = following.value!.addFollowing(targetId, details: details);
      following.value = updatedFollowing;

      await _saveFollowingToFirestore(updatedFollowing);

      // Update candidate's follower count
      await _updateCandidateFollowerCount(targetId, increment: true);

      AppLogger.core('✅ User ${following.value!.userId} followed $targetId');
    } catch (e) {
      AppLogger.coreError('❌ Failed to follow $targetId', error: e);
      rethrow;
    }
  }

  /// Unfollow a candidate/user
  Future<void> unfollow(String targetId) async {
    if (following.value == null || !following.value!.isFollowing(targetId)) return;

    try {
      final updatedFollowing = following.value!.removeFollowing(targetId);
      following.value = updatedFollowing;

      await _saveFollowingToFirestore(updatedFollowing);

      // Update candidate's follower count
      await _updateCandidateFollowerCount(targetId, increment: false);

      AppLogger.core('✅ User ${following.value!.userId} unfollowed $targetId');
    } catch (e) {
      AppLogger.coreError('❌ Failed to unfollow $targetId', error: e);
      rethrow;
    }
  }

  /// Toggle follow/unfollow
  Future<void> toggleFollow(String targetId, {String? reason}) async {
    if (isFollowing(targetId)) {
      await unfollow(targetId);
    } else {
      await follow(targetId, reason: reason);
    }
  }

  /// Update following details
  Future<void> updateFollowingDetails(String targetId, FollowingDetails details) async {
    if (following.value == null) return;

    try {
      final updatedFollowing = following.value!.updateFollowingDetails(targetId, details);
      following.value = updatedFollowing;

      await _saveFollowingToFirestore(updatedFollowing);

      AppLogger.core('✅ Updated following details for $targetId');
    } catch (e) {
      AppLogger.coreError('❌ Failed to update following details for $targetId', error: e);
      rethrow;
    }
  }

  /// Toggle notifications for a following relationship
  Future<void> toggleNotifications(String targetId, bool enabled) async {
    final currentDetails = getFollowingDetails(targetId);
    if (currentDetails == null) return;

    final updatedDetails = currentDetails.copyWith(notificationsEnabled: enabled);
    await updateFollowingDetails(targetId, updatedDetails);
  }

  /// Check if user is following a specific candidate/user
  bool isFollowing(String targetId) {
    return following.value?.isFollowing(targetId) ?? false;
  }

  /// Get following details for a specific relationship
  FollowingDetails? getFollowingDetails(String targetId) {
    return following.value?.getFollowingDetails(targetId);
  }

  /// Get all following IDs with notifications enabled
  List<String> getFollowingWithNotificationsEnabled() {
    return following.value?.getFollowingWithNotificationsEnabled() ?? [];
  }

  /// Get following statistics
  Map<String, dynamic> getFollowingStats() {
    return following.value?.getStats() ?? {};
  }

  /// Bulk operations for following multiple candidates
  Future<void> followMultiple(List<String> targetIds, {String? reason}) async {
    if (following.value == null || targetIds.isEmpty) return;

    try {
      FollowingModel updatedFollowing = following.value!;
      for (final targetId in targetIds) {
        if (!updatedFollowing.isFollowing(targetId)) {
          final details = FollowingDetails(
            targetId: targetId,
            followedAt: DateTime.now(),
            followReason: reason,
          );
          updatedFollowing = updatedFollowing.addFollowing(targetId, details: details);
        }
      }

      following.value = updatedFollowing;
      await _saveFollowingToFirestore(updatedFollowing);

      // Update follower counts for all candidates
      for (final targetId in targetIds) {
        await _updateCandidateFollowerCount(targetId, increment: true);
      }

      AppLogger.core('✅ User ${following.value!.userId} followed ${targetIds.length} candidates');
    } catch (e) {
      AppLogger.coreError('❌ Failed to follow multiple candidates', error: e);
      rethrow;
    }
  }

  /// Bulk unfollow operation
  Future<void> unfollowMultiple(List<String> targetIds) async {
    if (following.value == null || targetIds.isEmpty) return;

    try {
      FollowingModel updatedFollowing = following.value!;
      for (final targetId in targetIds) {
        if (updatedFollowing.isFollowing(targetId)) {
          updatedFollowing = updatedFollowing.removeFollowing(targetId);
        }
      }

      following.value = updatedFollowing;
      await _saveFollowingToFirestore(updatedFollowing);

      // Update follower counts for all candidates
      for (final targetId in targetIds) {
        await _updateCandidateFollowerCount(targetId, increment: false);
      }

      AppLogger.core('✅ User ${following.value!.userId} unfollowed ${targetIds.length} candidates');
    } catch (e) {
      AppLogger.coreError('❌ Failed to unfollow multiple candidates', error: e);
      rethrow;
    }
  }

  /// Clear following data (on logout)
  void clearFollowing() {
    following.value = null;
    isInitialized.value = false;
    _lastFetchTime = null;
    _followingDocSubscription?.cancel();
    _followingDocSubscription = null;
    AppLogger.core('🧹 Following data cleared');
  }

  /// Save following data to Firestore
  Future<void> _saveFollowingToFirestore(FollowingModel followingModel) async {
    await _firestore
        .collection('user_following')
        .doc(followingModel.userId)
        .set(followingModel.toJson());
  }

  /// Update candidate's follower count
  Future<void> _updateCandidateFollowerCount(String candidateId, {required bool increment}) async {
    try {
      final candidateRef = _firestore.collection('candidates').doc(candidateId);
      await candidateRef.update({
        'followersCount': FieldValue.increment(increment ? 1 : -1),
      });
    } catch (e) {
      AppLogger.coreError('❌ Failed to update follower count for candidate $candidateId', error: e);
      // Don't throw - this shouldn't break the follow/unfollow operation
    }
  }

  /// Check if cache is valid
  bool _hasValidCache() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Cleanup resources
  void _cleanup() {
    _followingDocSubscription?.cancel();
    _authStateSubscription?.cancel();
    clearFollowing();
    AppLogger.core('🧹 FollowingController cleaned up');
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoading': isLoading.value,
      'isInitialized': isInitialized.value,
      'hasFollowingData': following.value != null,
      'userId': userId,
      'followingCount': followingCount,
      'followingIds': followingIds.take(5), // First 5 for debugging
      'lastFetchTime': _lastFetchTime?.toIso8601String(),
      'cacheValid': _hasValidCache(),
    };
  }
}
