import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import '../repositories/candidate_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/memory_manager.dart';

class CandidateController extends GetxController {
  final CandidateRepository _repository = CandidateRepository();

  // Optimization systems
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final MemoryManager _memoryManager = MemoryManager();

  // Public getter for repository access
  CandidateRepository get candidateRepository => _repository;

  List<Candidate> candidates = [];
  List<Ward> wards = [];
  List<District> districts = [];
  bool isLoading = false;
  String? errorMessage;

  // Follow/Unfollow state management
  Map<String, bool> followStatus = {}; // candidateId -> isFollowing
  Map<String, bool> followLoading = {}; // candidateId -> isLoading

  // Fetch candidates by ward with analytics
  Future<void> fetchCandidatesByWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    debugPrint(
      '🔄 [Controller] Fetching candidates for district: $districtId, body: $bodyId, ward: $wardId',
    );

    // Track user interaction
    _analytics.trackUserInteraction(
      'fetch_candidates',
      'candidate_list_screen',
      metadata: {'districtId': districtId, 'bodyId': bodyId, 'wardId': wardId},
    );

    isLoading = true;
    errorMessage = null;
    update();

    final startTime = DateTime.now();

    try {
      candidates = await _repository.getCandidatesByWard(
        districtId,
        bodyId,
        wardId,
      );

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint(
        '✅ [Controller] Found ${candidates.length} candidates in district: $districtId, body: $bodyId, ward: $wardId',
      );

      // Track successful operation
      _analytics.trackPerformanceMetric(
        'candidate_load_time',
        loadTime.toDouble(),
      );
      _analytics.trackFirebaseOperation(
        'read',
        'candidates',
        candidates.length,
        success: true,
      );

      // Memory management - register for cleanup
      _memoryManager.registerObject(
        'candidates_${districtId}_${bodyId}_$wardId',
        candidates,
        ttl: Duration(minutes: 15),
        category: 'candidates',
        metadata: {'count': candidates.length},
      );
    } catch (e) {
      debugPrint('❌ [Controller] Failed to fetch candidates: $e');

      // Track failed operation
      _analytics.trackFirebaseOperation(
        'read',
        'candidates',
        0,
        success: false,
        error: e.toString(),
      );

      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Fetch candidates by city
  Future<void> fetchCandidatesByCity(String cityId) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByCity(cityId);
    } catch (e) {
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Fetch wards for a district and body
  Future<void> fetchWardsByDistrictAndBody(
    String districtId,
    String bodyId,
  ) async {
    debugPrint('🔄 [Controller] Fetching wards for district: $districtId, body: $bodyId');
    try {
      wards = await _repository.getWardsByDistrictAndBody(districtId, bodyId);
      debugPrint(
        '✅ [Controller] Loaded ${wards.length} wards for district: $districtId, body: $bodyId',
      );
      update();
    } catch (e) {
      debugPrint('❌ [Controller] Failed to load wards for district $districtId, body $bodyId: $e');
      errorMessage = 'Failed to load wards: $e';
      wards = [];
      update();
    }
  }

  // Fetch all districts
  Future<void> fetchAllDistricts() async {
    debugPrint('🔄 [Controller] Fetching all districts...');
    try {
      districts = await _repository.getAllDistricts();
      debugPrint('✅ [Controller] Loaded ${districts.length} districts');
      update();
    } catch (e) {
      debugPrint('❌ [Controller] Failed to load districts: $e');
      errorMessage = 'Failed to load districts: $e';
      districts = [];
      update();
    }
  }

  // Search candidates
  Future<void> searchCandidates(
    String query, {
    String? cityId,
    String? wardId,
  }) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.searchCandidates(
        query,
        cityId: cityId,
        wardId: wardId,
      );
    } catch (e) {
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Clear candidates
  void clearCandidates() {
    candidates = [];
    update();
  }

  // Clear error
  void clearError() {
    errorMessage = null;
    update();
  }

  // Follow/Unfollow Methods

  // Check if user is following a candidate
  Future<void> checkFollowStatus(String userId, String candidateId) async {
    try {
      final isFollowing = await _repository.isUserFollowingCandidate(
        userId,
        candidateId,
      );
      followStatus[candidateId] = isFollowing;
      update();
    } catch (e) {
      debugPrint('❌ [Controller] Failed to check follow status: $e');
    }
  }

  // Follow a candidate
  Future<void> followCandidate(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
  }) async {
    if (followLoading[candidateId] == true) return;

    followLoading[candidateId] = true;
    update();

    try {
      await _repository.followCandidate(
        userId,
        candidateId,
        notificationsEnabled: notificationsEnabled,
      );
      followStatus[candidateId] = true;

      // Update candidate's followers count in the list
      final candidateIndex = candidates.indexWhere(
        (c) => c.candidateId == candidateId,
      );
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          followersCount: candidates[candidateIndex].followersCount + 1,
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      debugPrint(
        '✅ [Controller] Successfully followed candidate: $candidateId',
      );

      // Notify chat controller to refresh cache since followed candidates changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        debugPrint('⚠️ Could not notify chat controller: $e');
      }
    } catch (e) {
      debugPrint('❌ [Controller] Failed to follow candidate: $e');
      errorMessage = 'Failed to follow candidate: $e';
    }

    followLoading[candidateId] = false;
    update();
  }

  // Unfollow a candidate
  Future<void> unfollowCandidate(String userId, String candidateId) async {
    if (followLoading[candidateId] == true) return;

    followLoading[candidateId] = true;
    update();

    try {
      await _repository.unfollowCandidate(userId, candidateId);
      followStatus[candidateId] = false;

      // Update candidate's followers count in the list
      final candidateIndex = candidates.indexWhere(
        (c) => c.candidateId == candidateId,
      );
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          followersCount: candidates[candidateIndex].followersCount - 1,
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      debugPrint(
        '✅ [Controller] Successfully unfollowed candidate: $candidateId',
      );

      // Notify chat controller to refresh cache since followed candidates changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        debugPrint('⚠️ Could not notify chat controller: $e');
      }
    } catch (e) {
      debugPrint('❌ [Controller] Failed to unfollow candidate: $e');
      errorMessage = 'Failed to unfollow candidate: $e';
    }

    followLoading[candidateId] = false;
    update();
  }

  // Toggle follow/unfollow
  Future<void> toggleFollow(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
  }) async {
    final isFollowing = followStatus[candidateId] ?? false;

    if (isFollowing) {
      await unfollowCandidate(userId, candidateId);
    } else {
      await followCandidate(
        userId,
        candidateId,
        notificationsEnabled: notificationsEnabled,
      );
    }
  }

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(
    String userId,
    String candidateId,
    bool notificationsEnabled,
  ) async {
    try {
      await _repository.updateFollowNotificationSettings(
        userId,
        candidateId,
        notificationsEnabled,
      );

      // Notify chat controller to refresh cache since follow relationship changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        debugPrint('⚠️ Could not notify chat controller: $e');
      }

      debugPrint(
        '✅ [Controller] Updated notification settings for candidate: $candidateId',
      );
    } catch (e) {
      debugPrint('❌ [Controller] Failed to update notification settings: $e');
      errorMessage = 'Failed to update notification settings: $e';
      update();
    }
  }

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(
    String candidateId,
  ) async {
    try {
      return await _repository.getCandidateFollowers(candidateId);
    } catch (e) {
      debugPrint('❌ [Controller] Failed to get followers: $e');
      errorMessage = 'Failed to get followers: $e';
      update();
      return [];
    }
  }

  // Get following list for a user
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      return await _repository.getUserFollowing(userId);
    } catch (e) {
      debugPrint('❌ [Controller] Failed to get following list: $e');
      errorMessage = 'Failed to get following list: $e';
      update();
      return [];
    }
  }

  // Clear follow status cache
  void clearFollowStatus() {
    followStatus.clear();
    followLoading.clear();
    update();
  }

  // Provisional Candidate Management Methods

  // Create a new candidate (self-registration)
  Future<String?> createCandidate(Candidate candidate) async {
    try {
      final candidateId = await _repository.createCandidate(candidate);
      debugPrint('✅ [Controller] Successfully created candidate: $candidateId');
      return candidateId;
    } catch (e) {
      debugPrint('❌ [Controller] Failed to create candidate: $e');
      errorMessage = 'Failed to create candidate: $e';
      update();
      return null;
    }
  }

  // Get candidates by status
  Future<void> fetchCandidatesByStatus(
    String districtId,
    String bodyId,
    String wardId,
    String status,
  ) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByStatus(
        districtId,
        bodyId,
        wardId,
        status,
      );
      debugPrint(
        '✅ [Controller] Found ${candidates.length} candidates with status: $status',
      );
    } catch (e) {
      debugPrint('❌ [Controller] Failed to fetch candidates by status: $e');
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Approve or reject a candidate
  Future<void> updateCandidateApproval(
    String districtId,
    String bodyId,
    String wardId,
    String candidateId,
    bool approved,
  ) async {
    try {
      await _repository.updateCandidateApproval(
        districtId,
        bodyId,
        wardId,
        candidateId,
        approved,
      );

      // Update the candidate in the current list if it exists
      final candidateIndex = candidates.indexWhere(
        (c) => c.candidateId == candidateId,
      );
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          approved: approved,
          status: approved ? 'pending_election' : 'rejected',
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      debugPrint(
        '✅ [Controller] Successfully ${approved ? 'approved' : 'rejected'} candidate: $candidateId',
      );
      update();
    } catch (e) {
      debugPrint('❌ [Controller] Failed to update candidate approval: $e');
      errorMessage = 'Failed to update candidate approval: $e';
      update();
    }
  }

  // Finalize candidates
  Future<void> finalizeCandidates(
    String districtId,
    String bodyId,
    String wardId,
    List<String> candidateIds,
  ) async {
    try {
      await _repository.finalizeCandidates(
        districtId,
        bodyId,
        wardId,
        candidateIds,
      );

      // Update the candidates in the current list
      for (final candidateId in candidateIds) {
        final candidateIndex = candidates.indexWhere(
          (c) => c.candidateId == candidateId,
        );
        if (candidateIndex != -1) {
          final updatedCandidate = candidates[candidateIndex].copyWith(
            status: 'finalized',
            approved: true,
          );
          candidates[candidateIndex] = updatedCandidate;
        }
      }

      debugPrint(
        '✅ [Controller] Successfully finalized ${candidateIds.length} candidates',
      );
      update();
    } catch (e) {
      debugPrint('❌ [Controller] Failed to finalize candidates: $e');
      errorMessage = 'Failed to finalize candidates: $e';
      update();
    }
  }

  // Get all pending approval candidates
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      return await _repository.getPendingApprovalCandidates();
    } catch (e) {
      debugPrint(
        '❌ [Controller] Failed to get pending approval candidates: $e',
      );
      errorMessage = 'Failed to get pending approval candidates: $e';
      update();
      return [];
    }
  }

  // Check if user has registered as candidate
  Future<bool> hasUserRegisteredAsCandidate(String userId) async {
    try {
      return await _repository.hasUserRegisteredAsCandidate(userId);
    } catch (e) {
      debugPrint(
        '❌ [Controller] Failed to check user candidate registration: $e',
      );
      return false;
    }
  }
}
