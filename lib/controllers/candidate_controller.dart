import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../models/ward_model.dart';
import '../models/city_model.dart';
import '../repositories/candidate_repository.dart';

class CandidateController extends GetxController {
  final CandidateRepository _repository = CandidateRepository();

  List<Candidate> candidates = [];
  List<Ward> wards = [];
  List<City> cities = [];
  bool isLoading = false;
  String? errorMessage;

  // Follow/Unfollow state management
  Map<String, bool> followStatus = {}; // candidateId -> isFollowing
  Map<String, bool> followLoading = {}; // candidateId -> isLoading

  // Fetch candidates by ward
  Future<void> fetchCandidatesByWard(String cityId, String wardId) async {
    print('🔄 [Controller] Fetching candidates for city: $cityId, ward: $wardId');
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByWard(cityId, wardId);
      print('✅ [Controller] Found ${candidates.length} candidates in city: $cityId, ward: $wardId');
    } catch (e) {
      print('❌ [Controller] Failed to fetch candidates: $e');
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

  // Fetch wards for a city
  Future<void> fetchWardsByCity(String cityId) async {
    print('🔄 [Controller] Fetching wards for city: $cityId');
    try {
      wards = await _repository.getWardsByCity(cityId);
      print('✅ [Controller] Loaded ${wards.length} wards for city: $cityId');
      update();
    } catch (e) {
      print('❌ [Controller] Failed to load wards for city $cityId: $e');
      errorMessage = 'Failed to load wards: $e';
      wards = [];
      update();
    }
  }

  // Fetch all cities
  Future<void> fetchAllCities() async {
    print('🔄 [Controller] Fetching all cities...');
    try {
      cities = await _repository.getAllCities();
      print('✅ [Controller] Loaded ${cities.length} cities');
      update();
    } catch (e) {
      print('❌ [Controller] Failed to load cities: $e');
      errorMessage = 'Failed to load cities: $e';
      cities = [];
      update();
    }
  }

  // Search candidates
  Future<void> searchCandidates(String query, {String? cityId, String? wardId}) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.searchCandidates(query, cityId: cityId, wardId: wardId);
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
      final isFollowing = await _repository.isUserFollowingCandidate(userId, candidateId);
      followStatus[candidateId] = isFollowing;
      update();
    } catch (e) {
      print('❌ [Controller] Failed to check follow status: $e');
    }
  }

  // Follow a candidate
  Future<void> followCandidate(String userId, String candidateId, {bool notificationsEnabled = true}) async {
    if (followLoading[candidateId] == true) return;

    followLoading[candidateId] = true;
    update();

    try {
      await _repository.followCandidate(userId, candidateId, notificationsEnabled: notificationsEnabled);
      followStatus[candidateId] = true;

      // Update candidate's followers count in the list
      final candidateIndex = candidates.indexWhere((c) => c.candidateId == candidateId);
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          followersCount: candidates[candidateIndex].followersCount + 1,
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      print('✅ [Controller] Successfully followed candidate: $candidateId');
    } catch (e) {
      print('❌ [Controller] Failed to follow candidate: $e');
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
      final candidateIndex = candidates.indexWhere((c) => c.candidateId == candidateId);
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          followersCount: candidates[candidateIndex].followersCount - 1,
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      print('✅ [Controller] Successfully unfollowed candidate: $candidateId');
    } catch (e) {
      print('❌ [Controller] Failed to unfollow candidate: $e');
      errorMessage = 'Failed to unfollow candidate: $e';
    }

    followLoading[candidateId] = false;
    update();
  }

  // Toggle follow/unfollow
  Future<void> toggleFollow(String userId, String candidateId, {bool notificationsEnabled = true}) async {
    final isFollowing = followStatus[candidateId] ?? false;

    if (isFollowing) {
      await unfollowCandidate(userId, candidateId);
    } else {
      await followCandidate(userId, candidateId, notificationsEnabled: notificationsEnabled);
    }
  }

  // Update notification settings for a follow relationship
  Future<void> updateFollowNotificationSettings(String userId, String candidateId, bool notificationsEnabled) async {
    try {
      await _repository.updateFollowNotificationSettings(userId, candidateId, notificationsEnabled);
      print('✅ [Controller] Updated notification settings for candidate: $candidateId');
    } catch (e) {
      print('❌ [Controller] Failed to update notification settings: $e');
      errorMessage = 'Failed to update notification settings: $e';
      update();
    }
  }

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId) async {
    try {
      return await _repository.getCandidateFollowers(candidateId);
    } catch (e) {
      print('❌ [Controller] Failed to get followers: $e');
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
      print('❌ [Controller] Failed to get following list: $e');
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
      print('✅ [Controller] Successfully created candidate: $candidateId');
      return candidateId;
    } catch (e) {
      print('❌ [Controller] Failed to create candidate: $e');
      errorMessage = 'Failed to create candidate: $e';
      update();
      return null;
    }
  }

  // Get candidates by approval status
  Future<void> fetchCandidatesByApprovalStatus(String cityId, String wardId, bool approved) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByApprovalStatus(cityId, wardId, approved);
      print('✅ [Controller] Found ${candidates.length} candidates with approved: $approved');
    } catch (e) {
      print('❌ [Controller] Failed to fetch candidates by approval status: $e');
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Get candidates by status
  Future<void> fetchCandidatesByStatus(String cityId, String wardId, String status) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      candidates = await _repository.getCandidatesByStatus(cityId, wardId, status);
      print('✅ [Controller] Found ${candidates.length} candidates with status: $status');
    } catch (e) {
      print('❌ [Controller] Failed to fetch candidates by status: $e');
      errorMessage = e.toString();
      candidates = [];
    }

    isLoading = false;
    update();
  }

  // Approve or reject a candidate
  Future<void> updateCandidateApproval(String cityId, String wardId, String candidateId, bool approved) async {
    try {
      await _repository.updateCandidateApproval(cityId, wardId, candidateId, approved);

      // Update the candidate in the current list if it exists
      final candidateIndex = candidates.indexWhere((c) => c.candidateId == candidateId);
      if (candidateIndex != -1) {
        final updatedCandidate = candidates[candidateIndex].copyWith(
          approved: approved,
          status: approved ? 'pending_election' : 'rejected',
        );
        candidates[candidateIndex] = updatedCandidate;
      }

      print('✅ [Controller] Successfully ${approved ? 'approved' : 'rejected'} candidate: $candidateId');
      update();
    } catch (e) {
      print('❌ [Controller] Failed to update candidate approval: $e');
      errorMessage = 'Failed to update candidate approval: $e';
      update();
    }
  }

  // Finalize candidates
  Future<void> finalizeCandidates(String cityId, String wardId, List<String> candidateIds) async {
    try {
      await _repository.finalizeCandidates(cityId, wardId, candidateIds);

      // Update the candidates in the current list
      for (final candidateId in candidateIds) {
        final candidateIndex = candidates.indexWhere((c) => c.candidateId == candidateId);
        if (candidateIndex != -1) {
          final updatedCandidate = candidates[candidateIndex].copyWith(
            status: 'finalized',
            approved: true,
          );
          candidates[candidateIndex] = updatedCandidate;
        }
      }

      print('✅ [Controller] Successfully finalized ${candidateIds.length} candidates');
      update();
    } catch (e) {
      print('❌ [Controller] Failed to finalize candidates: $e');
      errorMessage = 'Failed to finalize candidates: $e';
      update();
    }
  }

  // Get all pending approval candidates
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      return await _repository.getPendingApprovalCandidates();
    } catch (e) {
      print('❌ [Controller] Failed to get pending approval candidates: $e');
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
      print('❌ [Controller] Failed to check user candidate registration: $e');
      return false;
    }
  }
}