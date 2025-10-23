import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../models/basic_info_model.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/data_compression.dart';
import '../../../utils/error_recovery_manager.dart';
import '../../../utils/advanced_analytics.dart';
import '../../../utils/multi_level_cache.dart';
import '../../../utils/app_logger.dart';

import 'candidate_cache_manager.dart';
import 'candidate_state_manager.dart';
import 'candidate_operations.dart';
import 'candidate_follow_manager.dart';
import 'candidate_search_manager.dart';
import 'basic_info_repository.dart';

class CandidateRepository {
  // Shared services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCompressionManager _compressionManager = DataCompressionManager();
  final FirebaseDataOptimizer _dataOptimizer = FirebaseDataOptimizer();
  final ErrorRecoveryManager _errorRecovery = ErrorRecoveryManager();
  final AdvancedAnalyticsManager _analytics = AdvancedAnalyticsManager();
  final MultiLevelCache _cache = MultiLevelCache();

  // Manager instances
  late final CandidateCacheManager _cacheManager;
  late final CandidateStateManager _stateManager;
  late final CandidateOperations _operations;
  late final CandidateFollowManager _followManager;
  late final IBasicInfoRepository _basicInfoRepository;
  CandidateSearchManager? _searchManager;

  // Additional initialization
  CandidateRepository() {
    _cacheManager = CandidateCacheManager();
    _stateManager = CandidateStateManager(_firestore, _cacheManager);
    _operations = CandidateOperations(_firestore, _compressionManager, _dataOptimizer, _errorRecovery, _analytics, _cache, _cacheManager);
    _followManager = CandidateFollowManager(_firestore, _cacheManager, _stateManager);
    _basicInfoRepository = BasicInfoRepository(firestore: _firestore);
    // Initialize search manager after operations and follow manager are ready
    _initializeSearchManager();
  }

  void _initializeSearchManager() {
    _searchManager = CandidateSearchManager(_firestore, _dataOptimizer, _errorRecovery, _analytics, _cache, _cacheManager, _stateManager, _operations, _followManager);
  }

  // Delegate methods to managers
  // State management methods
  Future<List<Map<String, dynamic>>> getAllStates() => _stateManager.getAllStates();
  Future<Map<String, dynamic>?> getStateById(String stateId) => _stateManager.getStateById(stateId);
  Future<bool> validateState(String stateId) => _stateManager.validateState(stateId);
  // TODO: These methods need to be updated for multi-state support
  // For now, using a temporary approach to maintain backward compatibility
  Future<List<Ward>> getWardsByDistrictAndBody(String districtId, String bodyId, [String? stateId]) async {
    // If stateId is provided, use it directly
    if (stateId != null && stateId.isNotEmpty) {
      AppLogger.candidate('Using provided stateId: $stateId', tag: 'CANDIDATE_REPO');
      return _stateManager.getWardsByDistrictAndBody(stateId, districtId, bodyId);
    }

    // For backward compatibility, try to determine state from context
    // This is a temporary solution - these methods should take stateId parameters
    try {
      // Try to get state from user's current context or use first available state
      final states = await getAllStates();
      if (states.isNotEmpty) {
        final defaultStateId = states.first['stateId'] as String;
        AppLogger.candidate('No stateId provided, using first state: $defaultStateId', tag: 'CANDIDATE_REPO');
        return _stateManager.getWardsByDistrictAndBody(defaultStateId, districtId, bodyId);
      }
      throw Exception('No states available');
    } catch (e) {
      AppLogger.candidate('Failed to get wards, using empty list: $e', tag: 'CANDIDATE_REPO');
      return [];
    }
  }

  Future<List<District>> getAllDistricts() async {
    // For backward compatibility, try to determine state from context
    // This is a temporary solution - these methods should take stateId parameters
    try {
      // Try to get state from user's current context or use first available state
      final states = await getAllStates();
      if (states.isNotEmpty) {
        final stateId = states.first['stateId'] as String;
        return _stateManager.getAllDistricts(stateId);
      }
      throw Exception('No states available');
    } catch (e) {
      AppLogger.candidate('Failed to get districts, using empty list: $e', tag: 'CANDIDATE_REPO');
      return [];
    }
  }

  // Operations methods
  Future<String> createCandidate(Candidate candidate, {String? stateId}) => _operations.createCandidate(candidate, stateId: stateId);
  Future<Candidate?> getCandidateData(String userId) => _operations.getCandidateData(userId);
  Future<Candidate?> getCandidateDataById(String candidateId) => _operations.getCandidateDataById(candidateId);
  Future<bool> updateCandidateExtraInfo(Candidate candidate) => _operations.updateCandidateExtraInfo(candidate);
  Future<bool> updateCandidateFields(String candidateId, Map<String, dynamic> fieldUpdates) => _operations.updateCandidateFields(candidateId, fieldUpdates);
  Future<bool> updateCandidateExtraInfoFields(String candidateId, Map<String, dynamic> extraInfoUpdates) => _operations.updateCandidateExtraInfoFields(candidateId, extraInfoUpdates);
  Future<bool> batchUpdateCandidateFields(String candidateId, Map<String, dynamic> updates) => _operations.batchUpdateCandidateFields(candidateId, updates);
  Future<List<Candidate>> getCandidatesByApprovalStatus(String districtId, String bodyId, String wardId, bool approved) => _operations.getCandidatesByApprovalStatus(districtId, bodyId, wardId, approved);
  Future<List<Candidate>> getCandidatesByStatus(String districtId, String bodyId, String wardId, String status) => _operations.getCandidatesByStatus(districtId, bodyId, wardId, status);
  Future<void> updateCandidateApproval(String districtId, String bodyId, String wardId, String candidateId, bool approved) => _operations.updateCandidateApproval(districtId, bodyId, wardId, candidateId, approved);
  Future<void> finalizeCandidates(String districtId, String bodyId, String wardId, List<String> candidateIds) => _operations.finalizeCandidates(districtId, bodyId, wardId, candidateIds);
  Future<List<Map<String, dynamic>>> getPendingApprovalCandidates() => _operations.getPendingApprovalCandidates();
  Future<bool> hasUserRegisteredAsCandidate(String userId) => _operations.hasUserRegisteredAsCandidate(userId);
  Future<void> ensureUserDocumentExists(String userId, {String? districtId, String? bodyId, String? wardId, String? cityId}) => _operations.ensureUserDocumentExists(userId, districtId: districtId, bodyId: bodyId, wardId: wardId, cityId: cityId);

  // Follow methods
  Future<void> followCandidate(String userId, String candidateId, {bool notificationsEnabled = true, String? stateId, String? districtId, String? bodyId, String? wardId}) => _followManager.followCandidate(userId, candidateId, notificationsEnabled: notificationsEnabled, stateId: stateId, districtId: districtId, bodyId: bodyId, wardId: wardId);
  Future<void> unfollowCandidate(String userId, String candidateId) => _followManager.unfollowCandidate(userId, candidateId);
  Future<bool> isUserFollowingCandidate(String userId, String candidateId) => _followManager.isUserFollowingCandidate(userId, candidateId);
  Future<List<Map<String, dynamic>>> getCandidateFollowers(String candidateId) => _followManager.getCandidateFollowers(candidateId);
  Future<List<String>> getUserFollowing(String userId) => _followManager.getUserFollowing(userId);
  Future<Map<String, dynamic>?> getUserData(String userId) => _followManager.getUserData(userId);
  Future<void> updateFollowNotificationSettings(String userId, String candidateId, bool notificationsEnabled) => _followManager.updateFollowNotificationSettings(userId, candidateId, notificationsEnabled);

  // Search methods
  Future<List<Candidate>> getCandidatesForUser(UserModel user) => _searchManager!.getCandidatesForUser(user);
  Future<List<Candidate>> getCandidatesByWard(String districtId, String bodyId, String wardId) => _searchManager!.getCandidatesByWard(districtId, bodyId, wardId);
  Future<Map<String, dynamic>> getCandidatesByCityPaginated(String cityId, {int limit = 50, DocumentSnapshot? startAfter}) => _searchManager!.getCandidatesByCityPaginated(cityId, limit: limit, startAfter: startAfter);
  Future<List<Candidate>> getCandidatesByCity(String cityId) => _searchManager!.getCandidatesByCity(cityId);
  Future<Map<String, dynamic>> searchCandidatesPaginated(String query, {String? cityId, String? wardId, int limit = 20, DocumentSnapshot? startAfter}) => _searchManager!.searchCandidatesPaginated(query, cityId: cityId, wardId: wardId, limit: limit, startAfter: startAfter);
  Future<List<Candidate>> searchCandidates(String query, {String? cityId, String? wardId}) => _searchManager!.searchCandidates(query, cityId: cityId, wardId: wardId);
  Future<List<Candidate?>> getCandidatesByIds(List<String> candidateIds) => _searchManager!.getCandidatesByIds(candidateIds);
  Future<void> batchUpdateCandidates(List<String> candidateIds, Map<String, dynamic> fieldUpdates) => _searchManager!.batchUpdateCandidates(candidateIds, fieldUpdates);
  Future<Map<String, dynamic>> getUserDataAndFollowing(String userId) => _searchManager!.getUserDataAndFollowing(userId);
  Future<void> logAllCandidatesInSystem() => _searchManager!.logAllCandidatesInSystem();

  // Basic info methods (delegate to BasicInfoRepository)
  Future<BasicInfoModel?> getBasicInfo(String candidateId) => _basicInfoRepository.getBasicInfo(candidateId);
  // Removed updateBasicInfo delegation - handled directly by BasicInfoController

  // Cache methods
  void invalidateCache(String cacheKey) => _cacheManager.invalidateCache(cacheKey);
  void invalidateAllCache() => _cacheManager.invalidateAllCache();
  void invalidateQueryCache(String pattern) => _cacheManager.invalidateQueryCache(pattern);
  void clearExpiredCache() => _cacheManager.clearExpiredCache();
  Map<String, dynamic> getCacheStats() => _cacheManager.getCacheStats();
}
