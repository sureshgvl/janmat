import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/multi_level_cache.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/controllers/candidate_user_controller.dart';

class HomeServices {
  final MultiLevelCache _cache = MultiLevelCache();

  Future<Map<String, dynamic>> getUserData(String? uid, {bool forceRefresh = false}) async {
    // Check if user is authenticated before attempting to fetch data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || uid == null) {
      AppLogger.common('ℹ️ User not authenticated, skipping data fetch');
      return {'user': null, 'candidate': null};
    }

    // Verify the requested uid matches the authenticated user
    if (currentUser.uid != uid) {
      AppLogger.common('⚠️ UID mismatch - requested: $uid, authenticated: ${currentUser.uid}');
      return {'user': null, 'candidate': null};
    }

    final cacheKey = 'home_user_data_$uid';

    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      try {
        final cachedData = await _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && cachedData['user'] != null) {
          AppLogger.common('⚡ Cache hit for home user data: $uid');
          return cachedData;
        }
      } catch (e) {
        AppLogger.common('⚠️ Cache retrieval failed, will fetch fresh data: $e');
      }
    }

    AppLogger.common('🔄 Fetching fresh user data for home: $uid');

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));

      UserModel? userModel;
      Candidate? candidateModel;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userModel = UserModel.fromJson(userData);

        // Load candidate data for candidates - prioritizes controller first
        if (userModel.profileCompleted && userModel.role == 'candidate') {
          try {
            // FIRST: Try centralized CandidateUserController (preferred approach)
            final candidateUserController = CandidateUserController.to;
            if (candidateUserController.candidate.value != null) {
              candidateModel = candidateUserController.candidate.value;
              AppLogger.common('🎯 Using centralized CandidateUserController data');
            } else {
              // Load via centralized controller
              await candidateUserController.loadCandidateUserData(userModel.uid);
              candidateModel = candidateUserController.candidate.value;
              AppLogger.common('📥 Loaded candidate data via CandidateUserController');
            }
          } catch (e) {
            AppLogger.common('⚠️ Centralized controller failed, using direct load: $e');
            // Fallback to direct load
            candidateModel = await _loadCandidateDataOptimized(userModel.uid);
          }
        }

        // Prepare result data
        final result = {'user': userModel, 'candidate': candidateModel};

        // Cache the result with high priority for home screen
        try {
          await _cache.set<Map<String, dynamic>>(cacheKey, result,
            priority: CachePriority.high,
            ttl: const Duration(minutes: 30)); // Cache for 30 minutes
          AppLogger.common('✅ Cached home user data for: $uid');
        } catch (e) {
          AppLogger.common('⚠️ Failed to cache home data, continuing without cache: $e');
        }

        return result;
      }
    } catch (e) {
      AppLogger.commonError('❌ User data fetch failed', error: e);
      // Try to return cached data even if old, as fallback
      try {
        final cachedData = await _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          AppLogger.common('🔄 Returning stale cached data as fallback');
          return cachedData;
        }
      } catch (cacheError) {
        AppLogger.common('⚠️ Even cache fallback failed: $cacheError');
      }
    }

    return {'user': null, 'candidate': null};
  }

  // Optimized candidate data loading for home screen
  Future<Candidate?> _loadCandidateDataOptimized(String uid) async {
    try {
      // Try cache first
      final candidateCache = MultiLevelCache();
      final candidateCacheKey = 'candidate_data_$uid';
      final cachedCandidate = await candidateCache.get<Map<String, dynamic>>(candidateCacheKey);

      if (cachedCandidate != null) {
        AppLogger.common('⚡ Using cached candidate data');
        return Candidate.fromJson(cachedCandidate);
      }

      // Fast fetch with short timeout
      final candidateDoc = await FirebaseFirestore.instance
          .collection('candidates')
          .doc(uid)
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 1), onTimeout: () async {
            // Fallback to server with 2 second timeout
            return await FirebaseFirestore.instance
                .collection('candidates')
                .doc(uid)
                .get(const GetOptions(source: Source.server))
                .timeout(const Duration(seconds: 2));
          });

      if (candidateDoc.exists) {
        final candidateData = candidateDoc.data()!;
        final candidate = Candidate.fromJson(candidateData);

        // Cache for future use
        try {
          await candidateCache.set(candidateCacheKey, candidateData, ttl: const Duration(hours: 1));
          AppLogger.common('💾 Candidate data cached');
        } catch (e) {
          AppLogger.common('⚠️ Failed to cache candidate data');
        }

        return candidate;
      }
    } catch (e) {
      AppLogger.common('⚠️ Candidate data load failed: $e');
    }
    return null;
  }

  // Background refresh for cache updates
  void _refreshUserDataInBackground(String uid, MultiLevelCache cache, String cacheKey) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 3));

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromJson(userData);
        final result = {'user': userModel, 'candidate': null};

        await cache.set(cacheKey, result, ttl: const Duration(hours: 1));
        AppLogger.common('🔄 Background cache refresh completed');
      }
    } catch (e) {
      AppLogger.common('⚠️ Background cache refresh failed');
    }
  }
}
