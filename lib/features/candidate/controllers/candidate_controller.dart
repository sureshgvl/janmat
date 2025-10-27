import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import '../../../features/user/models/user_model.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/candidate_follow_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/controllers/user_controller.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/memory_manager.dart';
import '../../../services/notifications/candidate_following_notifications.dart';
import '../../../services/local_database_service.dart';
import '../../../utils/app_logger.dart';

class CandidateController extends GetxController {
  final CandidateRepository _repository = CandidateRepository();
  final CandidateFollowRepository _followRepository = CandidateFollowRepository();

  // Optimization systems
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final MemoryManager _memoryManager = MemoryManager();

  // Public getter for repository access
  CandidateRepository get candidateRepository => _repository;
  CandidateFollowRepository get followRepository => _followRepository;

  List<Candidate> candidates = [];
  List<Ward> wards = [];
  List<District> districts = [];
  bool isLoading = false;
  String? errorMessage;

  // Follow/Unfollow state management
  Map<String, bool> followStatus = {}; // candidateId -> isFollowing
  Map<String, bool> followLoading = {}; // candidateId -> isLoading
  List<String>? _cachedFollowingIds; // Cache following IDs for session
  DateTime? _followStatusLastFetched; // Track when follow status was last fetched

  // Fetch candidates for a user based on their election areas (NEW METHOD)
  Future<void> fetchCandidatesForUser([UserModel? user]) async {
    // Use UserController if no user provided
    final userModel = user ?? UserController.to.user.value;
    if (userModel == null) {
      AppLogger.database('No user available for fetching candidates', tag: 'CANDIDATE_CONTROLLER');
      return;
    }
    AppLogger.database('Fetching candidates for user: ${userModel.uid}', tag: 'CANDIDATE_CONTROLLER');
    AppLogger.database('User has ${userModel.electionAreas.length} election areas', tag: 'CANDIDATE_CONTROLLER');

    // Track user interaction
    _analytics.trackUserInteraction(
      'fetch_candidates_for_user',
      'candidate_list_screen',
      metadata: {
        'userId': userModel.uid,
        'electionAreasCount': userModel.electionAreas.length,
        'electionTypes': userModel.electionAreas.map((e) => e.type.name).toList(),
      },
    );

    isLoading = true;
    errorMessage = null;
    update();

    final startTime = DateTime.now();

    try {
      candidates = await _repository.getCandidatesForUser(userModel);

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;

      AppLogger.database('Found ${candidates.length} candidates for user: ${userModel.uid}', tag: 'CANDIDATE_CONTROLLER');

      // Track successful operation
      _analytics.trackPerformanceMetric(
        'candidate_load_time_for_user',
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
        'user_candidates_${userModel.uid}',
        candidates,
        ttl: Duration(minutes: 15),
        category: 'user_candidates',
        metadata: {'count': candidates.length, 'userId': userModel.uid},
      );

      // Populate follow status for current user
      await _populateFollowStatusForCandidates();
    } catch (e) {
      AppLogger.candidateError('Failed to fetch candidates for user: $e');

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

  // Fetch candidates by ward with analytics and SQLite caching
  Future<void> fetchCandidatesByWard(
    String districtId,
    String bodyId,
    String wardId,
  ) async {
    final overallStartTime = DateTime.now();
    AppLogger.database('Starting candidate fetch operation', tag: 'CANDIDATE_CONTROLLER');
    AppLogger.database('Location: $districtId → $bodyId → $wardId', tag: 'CANDIDATE_CONTROLLER');

    // Track user interaction
    _analytics.trackUserInteraction(
      'fetch_candidates',
      'candidate_list_screen',
      metadata: {'districtId': districtId, 'bodyId': bodyId, 'wardId': wardId},
    );

    isLoading = true;
    errorMessage = null;
    update();

    try {
      // Phase 1: Try to load from SQLite cache first
      AppLogger.candidate('📊 [Controller:Candidates] Phase 1: Checking SQLite cache...');
      final cacheCheckStart = DateTime.now();
      final cachedCandidates = await _loadCandidatesFromSQLite(wardId);
      final cacheCheckTime = DateTime.now().difference(cacheCheckStart).inMilliseconds;

      if (cachedCandidates != null) {
        candidates = cachedCandidates;
        AppLogger.candidate('CACHE HIT - Using SQLite cached data');
        AppLogger.candidate('Candidates loaded: ${candidates.length}');
        AppLogger.candidate('Cache check time: ${cacheCheckTime}ms');

        // Phase 2: Populate follow status
        AppLogger.candidate('Phase 2: Populating follow status...');
        final followStartTime = DateTime.now();
        await _populateFollowStatusForCandidates();
        final followTime = DateTime.now().difference(followStartTime).inMilliseconds;

        final totalTime = DateTime.now().difference(overallStartTime).inMilliseconds;
        AppLogger.candidate('Operation completed successfully');
        AppLogger.candidate('Total time: ${totalTime}ms');
        AppLogger.candidate('Cache hit: Yes');
        AppLogger.candidate('Firebase calls: 0');
        AppLogger.candidate('Follow status time: ${followTime}ms');

        isLoading = false;
        update();
        return;
      }

      // Phase 1: Cache miss - fetch from Firebase
      AppLogger.candidate('CACHE MISS - Fetching from Firebase');
      final firebaseStartTime = DateTime.now();
      candidates = await _repository.getCandidatesByWard(
        districtId,
        bodyId,
        wardId,
      );
      final firebaseTime = DateTime.now().difference(firebaseStartTime).inMilliseconds;

      AppLogger.candidate('Firebase fetch completed');
      AppLogger.candidate('Candidates fetched: ${candidates.length}');
      AppLogger.candidate('Firebase time: ${firebaseTime}ms');

      // Phase 2: Cache candidates in SQLite for future use
      AppLogger.candidate('Phase 2: Caching to SQLite...');
      final cacheStartTime = DateTime.now();
      await _cacheCandidatesInSQLite(candidates, wardId);
      final cacheTime = DateTime.now().difference(cacheStartTime).inMilliseconds;

      // Phase 3: Populate follow status
      AppLogger.candidate('Phase 3: Populating follow status...');
      final followStartTime = DateTime.now();
      await _populateFollowStatusForCandidates();
      final followTime = DateTime.now().difference(followStartTime).inMilliseconds;

      // Track successful operation
      _analytics.trackPerformanceMetric(
        'candidate_load_time',
        firebaseTime.toDouble(),
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

      final totalTime = DateTime.now().difference(overallStartTime).inMilliseconds;
      AppLogger.candidate('Operation completed successfully');
      AppLogger.candidate('Total time: ${totalTime}ms');
      AppLogger.candidate('Cache hit: No');
      AppLogger.candidate('Firebase calls: 1');
      AppLogger.candidate('SQLite cache time: ${cacheTime}ms');
      AppLogger.candidate('Follow status time: ${followTime}ms');

    } catch (e) {
      final totalTime = DateTime.now().difference(overallStartTime).inMilliseconds;
      AppLogger.candidateError('Operation failed (${totalTime}ms): $e');

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

      // Populate follow status for current user
      await _populateFollowStatusForCandidates();
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
    AppLogger.candidate('Fetching wards for district: $districtId, body: $bodyId');
    try {
      wards = await _repository.getWardsByDistrictAndBody(districtId, bodyId);
      AppLogger.candidate(
        'Loaded ${wards.length} wards for district: $districtId, body: $bodyId',
      );
      update();
    } catch (e) {
      AppLogger.candidateError('Failed to load wards for district $districtId, body $bodyId: $e');
      errorMessage = 'Failed to load wards: $e';
      wards = [];
      update();
    }
  }

  // Fetch all districts
  Future<void> fetchAllDistricts() async {
    AppLogger.candidate('Fetching all districts...');
    try {
      districts = await _repository.getAllDistricts();
      AppLogger.candidate('Loaded ${districts.length} districts');
      update();
    } catch (e) {
      AppLogger.candidateError('Failed to load districts: $e');
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
      final isFollowing = await _followRepository.isUserFollowingCandidate(
        userId,
        candidateId,
      );
      followStatus[candidateId] = isFollowing;
      update();
    } catch (e) {
      AppLogger.candidateError('Failed to check follow status: $e');
    }
  }

  // Follow a candidate
  Future<void> followCandidate(
    String userId,
    String candidateId, {
    bool notificationsEnabled = true,
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) async {
    if (followLoading[candidateId] == true) return;

    followLoading[candidateId] = true;
    update();

    try {
      await _followRepository.followCandidate(
        userId,
        candidateId,
        notificationsEnabled: notificationsEnabled,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
      followStatus[candidateId] = true;

      // Invalidate session cache since follow relationships changed
      _invalidateFollowStatusCache();

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

      AppLogger.candidate(
        'Successfully followed candidate: $candidateId',
      );

      // Send new follower notification to candidate
      try {
        AppLogger.candidate('Sending new follower notification...');
        AppLogger.candidate('Follower ID: $userId');
        AppLogger.candidate('Candidate ID: $candidateId');

        // Get candidate info for notification
        final candidate = await _repository.getCandidateDataById(candidateId);
        if (candidate != null) {
          AppLogger.candidate('Candidate found: ${candidate.name} (${candidate.userId})');
          await CandidateFollowingNotifications().sendNewFollowerNotification(
            candidateId: candidateId,
            followerId: userId,
            candidateName: candidate.name,
            candidateUserId: candidate.userId,
          );
          AppLogger.candidate('New follower notification sent successfully');
        } else {
          AppLogger.candidate('Candidate data not found, sending basic notification');
          // Fallback without candidate info
          await CandidateFollowingNotifications().sendNewFollowerNotification(
            candidateId: candidateId,
            followerId: userId,
          );
          AppLogger.candidate('Basic new follower notification sent');
        }
      } catch (e) {
        AppLogger.candidateError('Failed to send new follower notification: $e');
        AppLogger.candidate('Error details: ${e.toString()}');
      }

      // Notify chat controller to refresh cache since followed candidates changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        AppLogger.candidate('Could not notify chat controller: $e');
      }
    } catch (e) {
      AppLogger.candidateError('Failed to follow candidate: $e');
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
      // Get candidate location from the candidates list
      final candidate = candidates.firstWhere(
        (c) => c.candidateId == candidateId,
        orElse: () => throw Exception('Candidate not found in list'),
      );
      final location = candidate.location;
      await _followRepository.unfollowCandidate(
        userId,
        candidateId,
        stateId: location.stateId,
        districtId: location.districtId,
        bodyId: location.bodyId,
        wardId: location.wardId,
      );
      followStatus[candidateId] = false;

      // Invalidate session cache since follow relationships changed
      _invalidateFollowStatusCache();

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

      AppLogger.candidate(
        'Successfully unfollowed candidate: $candidateId',
      );

      // Send unfollow notification to candidate
      try {
        // Get candidate info for notification
        final candidate = await _repository.getCandidateDataById(candidateId);
        if (candidate != null) {
          await CandidateFollowingNotifications().sendUnfollowNotification(
            candidateId: candidateId,
            unfollowerId: userId,
          );
        } else {
          // Fallback without candidate info
          await CandidateFollowingNotifications().sendUnfollowNotification(
            candidateId: candidateId,
            unfollowerId: userId,
          );
        }
      } catch (e) {
        AppLogger.candidate('Could not send unfollow notification: $e');
      }

      // Notify chat controller to refresh cache since followed candidates changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        AppLogger.candidate('Could not notify chat controller: $e');
      }
    } catch (e) {
      AppLogger.candidateError('Failed to unfollow candidate: $e');
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
      // Get candidate location from the candidates list
      final candidate = candidates.firstWhere(
        (c) => c.candidateId == candidateId,
        orElse: () => throw Exception('Candidate not found in list'),
      );
      final location = candidate.location;
      await _followRepository.updateFollowNotificationSettings(
        userId,
        candidateId,
        notificationsEnabled,
        stateId: location.stateId,
        districtId: location.districtId,
        bodyId: location.bodyId,
        wardId: location.wardId,
      );

      // Notify chat controller to refresh cache since follow relationship changed
      try {
        final chatController = Get.find<ChatController>();
        chatController.invalidateUserCache(userId);
      } catch (e) {
        AppLogger.candidate('Could not notify chat controller: $e');
      }

      AppLogger.candidate(
        'Updated notification settings for candidate: $candidateId',
      );
    } catch (e) {
      AppLogger.candidateError('Failed to update notification settings: $e');
      errorMessage = 'Failed to update notification settings: $e';
      update();
    }
  }

  // Get followers list for a candidate
  Future<List<Map<String, dynamic>>> getCandidateFollowers(
    String candidateId,
  ) async {
    try {
      // Get candidate location from the candidates list
      final candidate = candidates.firstWhere(
        (c) => c.candidateId == candidateId,
        orElse: () => throw Exception('Candidate not found in list'),
      );
      final location = candidate.location;
      return await _followRepository.getCandidateFollowers(candidateId,
        stateId: location.stateId,
        districtId: location.districtId,
        bodyId: location.bodyId,
        wardId: location.wardId,
      );
    } catch (e) {
      AppLogger.candidateError('Failed to get followers: $e');
      errorMessage = 'Failed to get followers: $e';
      update();
      return [];
    }
  }

  // Get following list for a user
  Future<List<String>> getUserFollowing(String userId) async {
    try {
      return await _followRepository.getUserFollowing(userId);
    } catch (e) {
      AppLogger.candidateError('Failed to get following list: $e');
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

  // Invalidate follow status session cache
  void _invalidateFollowStatusCache() {
    _cachedFollowingIds = null;
    _followStatusLastFetched = null;
    AppLogger.candidate('Invalidated follow status session cache');
  }

  // Load candidates from SQLite cache
  Future<List<Candidate>?> _loadCandidatesFromSQLite(String wardId) async {
    final startTime = DateTime.now();
    try {
      AppLogger.candidate('Checking candidates cache for ward: $wardId');

      final localDb = LocalDatabaseService();

      // Check cache validity
      final lastUpdate = await localDb.getLastUpdateTime('candidates_$wardId');
      final cacheAge = lastUpdate != null ? DateTime.now().difference(lastUpdate) : null;
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < const Duration(hours: 24);

      AppLogger.candidate('Candidates cache status for ward $wardId:');
      AppLogger.candidate('Last update: ${lastUpdate?.toIso8601String() ?? 'Never'}');
      AppLogger.candidate('Cache age: ${cacheAge?.inMinutes ?? 'N/A'} minutes');
      AppLogger.candidate('Is valid: $isCacheValid');

      if (!isCacheValid) {
        AppLogger.candidate('Candidates cache expired for ward: $wardId');
        return null;
      }

      final candidates = await localDb.getCandidatesForWard(wardId);
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;

      if (candidates == null || candidates.isEmpty) {
        AppLogger.candidate('No candidates found in cache for ward: $wardId (${loadTime}ms)');
        return null;
      }

      AppLogger.candidate('CACHE HIT - Loaded ${candidates.length} candidates from SQLite');
      AppLogger.candidate('Ward: $wardId');
      AppLogger.candidate('Load time: ${loadTime}ms');
      AppLogger.candidate('Sample candidates: ${candidates.take(2).map((c) => '${c.candidateId}:${c.name}').join(', ')}');

      return candidates;
    } catch (e) {
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidateError('Error loading candidates from SQLite (${loadTime}ms): $e');
      return null;
    }
  }

  // Cache candidates in SQLite
  Future<void> _cacheCandidatesInSQLite(List<Candidate> candidates, String wardId) async {
    final startTime = DateTime.now();
    try {
      AppLogger.candidate('Caching ${candidates.length} candidates for ward: $wardId');

      final localDb = LocalDatabaseService();
      await localDb.insertCandidates(candidates, wardId);

      final cacheTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidate('Successfully cached ${candidates.length} candidates');
      AppLogger.candidate('Ward: $wardId');
      AppLogger.candidate('Cache time: ${cacheTime}ms');
      AppLogger.candidate('Cache key: candidates_$wardId');
    } catch (e) {
      final cacheTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidateError('Error caching candidates (${cacheTime}ms): $e');
    }
  }

  // Populate follow status for current candidates with session caching
  Future<void> _populateFollowStatusForCandidates() async {
    final startTime = DateTime.now();
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        AppLogger.candidate('No current user - skipping follow status population');
        return;
      }

      AppLogger.candidate('Populating follow status for ${candidates.length} candidates');

      // Check if we have valid cached following IDs (cache for 30 minutes during session)
      const sessionCacheDuration = Duration(minutes: 30);
      final now = DateTime.now();
      final cacheAge = _followStatusLastFetched != null ? now.difference(_followStatusLastFetched!) : null;
      final hasValidCache = _cachedFollowingIds != null &&
          _followStatusLastFetched != null &&
          now.difference(_followStatusLastFetched!) < sessionCacheDuration;

      AppLogger.candidate('Session cache status:');
      AppLogger.candidate('Has cached data: ${_cachedFollowingIds != null}');
      AppLogger.candidate('Cache age: ${cacheAge?.inMinutes ?? 'N/A'} minutes');
      AppLogger.candidate('Is valid: $hasValidCache');

      List<String> followingIds;
      if (hasValidCache) {
        followingIds = _cachedFollowingIds!;
        AppLogger.candidate('CACHE HIT - Using session cached following IDs (${followingIds.length} follows)');
      } else {
        // Fetch from Firebase and cache for session
        AppLogger.candidate('CACHE MISS - Fetching following IDs from Firebase');
        final fetchStartTime = DateTime.now();
        followingIds = await getUserFollowing(currentUser.uid);
        final fetchTime = DateTime.now().difference(fetchStartTime).inMilliseconds;

        _cachedFollowingIds = followingIds;
        _followStatusLastFetched = now;

        AppLogger.candidate('Fetched and cached following IDs (${followingIds.length} follows, ${fetchTime}ms)');
      }

      // Set follow status for all candidates
      int followedCount = 0;
      for (final candidate in candidates) {
        final isFollowing = followingIds.contains(candidate.candidateId);
        followStatus[candidate.candidateId] = isFollowing;
        if (isFollowing) followedCount++;
      }

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidate('Follow status populated successfully');
      AppLogger.candidate('Total candidates: ${candidates.length}');
      AppLogger.candidate('Already following: $followedCount');
      AppLogger.candidate('Not following: ${candidates.length - followedCount}');
      AppLogger.candidate('Total time: ${totalTime}ms');

    } catch (e) {
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidateError('Failed to populate follow status (${totalTime}ms): $e');
    }
  }

  // Provisional Candidate Management Methods

  // Create a new candidate (self-registration)
  Future<String?> createCandidate(Candidate candidate, {String? stateId}) async {
    try {
      final candidateId = await _repository.createCandidate(candidate, stateId: stateId);
      AppLogger.candidate('Successfully created candidate: $candidateId');
      return candidateId;
    } catch (e) {
      AppLogger.candidateError('Failed to create candidate: $e');
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
      AppLogger.candidate(
        'Found ${candidates.length} candidates with status: $status',
      );

      // Populate follow status for current user
      await _populateFollowStatusForCandidates();
    } catch (e) {
      AppLogger.candidateError('Failed to fetch candidates by status: $e');
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

      AppLogger.candidate(
        'Successfully ${approved ? 'approved' : 'rejected'} candidate: $candidateId',
      );
      update();
    } catch (e) {
      AppLogger.candidateError('Failed to update candidate approval: $e');
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

      AppLogger.candidate(
        'Successfully finalized ${candidateIds.length} candidates',
      );
      update();
    } catch (e) {
      AppLogger.candidateError('Failed to finalize candidates: $e');
      errorMessage = 'Failed to finalize candidates: $e';
      update();
    }
  }

  // Get all pending approval candidates
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() async {
    try {
      return await _repository.getPendingApprovalCandidates();
    } catch (e) {
      AppLogger.candidateError(
        'Failed to get pending approval candidates: $e',
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
      AppLogger.candidateError(
        'Failed to check user candidate registration: $e',
      );
      return false;
    }
  }
}
