import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/multi_level_cache.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/controllers/candidate_user_controller.dart';

class HomeServices {

  Future<Map<String, dynamic>> getUserData(String? uid) async {
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

    // PERFORMANCE OPTIMIZATION: Use cache-first strategy for instant loading
    final cache = MultiLevelCache();
    final cacheKey = 'user_data_$uid';

    try {
      // Try cache first (should be instant)
      final cachedData = await cache.get<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        AppLogger.common('⚡ Using cached user data for instant loading');
        // Return cached data immediately, refresh in background
        _refreshUserDataInBackground(uid, cache, cacheKey);
        return cachedData;
      }
    } catch (e) {
      AppLogger.common('⚠️ Cache read failed, proceeding with fresh fetch');
    }

    // Fallback: Fast fetch with short timeout and cache-first strategy
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.cache)) // Try cache first
          .timeout(const Duration(seconds: 2), onTimeout: () async {
            // If cache fails, try server with very short timeout
            return await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(const GetOptions(source: Source.server))
                .timeout(const Duration(seconds: 1));
          });

      UserModel? userModel;
      Candidate? candidateModel;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userModel = UserModel.fromJson(userData);

        // CRITICAL: Load candidate data for candidates - this is required for home screen
        // Accept 2-3 second delay for this essential functionality
        if (userModel.profileCompleted && userModel.role == 'candidate') {
          try {
            // FIRST: Try centralized CandidateUserController (preferred approach)
            final candidateUserController = CandidateUserController.to;
            if (candidateUserController.candidate.value != null) {
              candidateModel = candidateUserController.candidate.value;
              AppLogger.common('🎯 Using centralized CandidateUserController data');
            } else {
              // Load via centralized controller - always load for candidates
              await candidateUserController.loadCandidateUserData(userModel.uid);
              candidateModel = candidateUserController.candidate.value;
              AppLogger.common('📥 Loaded candidate data via CandidateUserController');
            }
          } catch (e) {
            AppLogger.common('⚠️ Centralized controller failed, using direct load: $e');
            // Load directly if controller fails (2-3 seconds acceptable)
            candidateModel = await _loadCandidateDataOptimized(userModel.uid);
          }
        }

        // Cache the result for future instant loads (without candidate data initially)
        final result = {'user': userModel, 'candidate': candidateModel};
        try {
          await cache.set(cacheKey, result, ttl: const Duration(hours: 1));
          AppLogger.common('💾 User data cached for future instant loads');
        } catch (e) {
          AppLogger.common('⚠️ Failed to cache user data');
        }

        return result;
      }
    } catch (e) {
      AppLogger.commonError('❌ Fast user data fetch failed', error: e);
      // Return minimal data to allow app to continue
      return {'user': null, 'candidate': null};
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
