import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/multi_level_cache.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/controllers/candidate_user_controller.dart';
import '../../candidate/repositories/candidate_repository.dart';

class HomeServices {
  final MultiLevelCache _cache = MultiLevelCache();

  Future<Map<String, dynamic>> getUserData(String? uid, {bool forceRefresh = false}) async {
    AppLogger.common('🏠 [HOME_SERVICES] getUserData called - uid: $uid, forceRefresh: $forceRefresh');

    // Check if user is authenticated before attempting to fetch data
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || uid == null) {
      AppLogger.common('ℹ️ [HOME_SERVICES] User not authenticated, skipping data fetch - currentUser: ${currentUser?.uid}, uid: $uid');
      return {'user': null, 'candidate': null};
    }

    // Verify the requested uid matches the authenticated user
    if (currentUser.uid != uid) {
      AppLogger.common('⚠️ [HOME_SERVICES] UID mismatch - requested: $uid, authenticated: ${currentUser.uid}');
      return {'user': null, 'candidate': null};
    }

    final cacheKey = 'home_user_data_$uid';
    AppLogger.common('🔑 [HOME_SERVICES] Using cache key: $cacheKey');

    // Try cache first (unless force refresh)
    if (!forceRefresh) {
      try {
        final cachedData = await _cache.get<Map<String, dynamic>>(cacheKey);
        if (cachedData != null && cachedData['user'] != null) {
          final userData = cachedData['user'] as Map<String, dynamic>;
          final userRole = userData['role'];
          final hasCandidate = cachedData['candidate'] != null;

          // CRITICAL FIX: Check for data corruption - missing role field
          if (userRole == null || userRole.toString().isEmpty) {
            AppLogger.common('🚨 CRITICAL DATA CORRUPTION: User document $uid is missing role field! This indicates background operations are corrupting user data.');
            AppLogger.common('🔄 [HOME_SERVICES] Force fresh load due to corrupted cache data');
            // Force fresh load if cached data is corrupted
          } else {
            AppLogger.common('⚡ [HOME_SERVICES] Cache hit for home user data: $uid - role: $userRole, hasCandidate: $hasCandidate');
            return cachedData;
          }
        } else {
          AppLogger.common('📭 [HOME_SERVICES] Cache miss or invalid data for: $uid');
        }
      } catch (e) {
        AppLogger.common('⚠️ [HOME_SERVICES] Cache retrieval failed, will fetch fresh data: $e');
      }
    } else {
      AppLogger.common('🔄 [HOME_SERVICES] Force refresh requested, skipping cache');
    }

    AppLogger.common('🔄 [HOME_SERVICES] Fetching fresh user data for home: $uid');

    try {
      // Try to fetch from server with retry logic for unavailable errors
      final userDoc = await _fetchUserDocWithRetry(uid);

      UserModel? userModel;
      Candidate? candidateModel;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userModel = UserModel.fromJson(userData);

        AppLogger.common('👤 User loaded: ${userModel.name}, role: ${userModel.role}, profileCompleted: ${userModel.profileCompleted}, roleSelected: ${userModel.roleSelected}');

        // Load candidate data for candidates - use direct repository approach for reliability
        if (userModel.role == 'candidate') {
          AppLogger.common('🎯 Loading candidate data for ${userModel.name} (role: ${userModel.role})');
          try {
            // Use direct repository load for reliable home screen display
            candidateModel = await _loadCandidateDataOptimized(userModel.uid);
            if (candidateModel != null) {
              AppLogger.common('✅ Loaded candidate data directly: ${candidateModel.basicInfo!.fullName}');

              // Synchronize with CandidateUserController for other parts of the app
              try {
                final candidateUserController = CandidateUserController.to;
                candidateUserController.user.value = userModel;
                candidateUserController.candidate.value = candidateModel;
                candidateUserController.isInitialized.value = true;
                AppLogger.common('✅ Synchronized candidate data with controller');
              } catch (syncError) {
                AppLogger.common('⚠️ Failed to sync with controller, but home screen data loaded: $syncError');
                // Continue - home screen has the data it needs
              }
            } else {
              AppLogger.common('⚠️ No candidate data found for user: ${userModel.uid}');
            }
          } catch (e) {
            AppLogger.commonError('❌ Failed to load candidate data: $e');
            // Continue without candidate data - home screen can handle partial data
          }
        } else {
          AppLogger.common('ℹ️ Skipping candidate data load - not a candidate (role: ${userModel.role})');
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

      // Use CandidateRepository to fetch from the correct nested structure
      final candidateRepository = CandidateRepository();
      final candidate = await candidateRepository.getCandidateData(uid);

      if (candidate != null) {
        // Cache for future use
        try {
          await candidateCache.set(candidateCacheKey, candidate.toJson(), ttl: const Duration(hours: 1));
          AppLogger.common('💾 Candidate data cached');
        } catch (e) {
          AppLogger.common('⚠️ Failed to cache candidate data');
        }
      }

      return candidate;
    } catch (e) {
      AppLogger.common('⚠️ Candidate data load failed: $e');
    }
    return null;
  }



  /// Fetch user document with retry logic for transient Firestore errors
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDocWithRetry(String uid) async {
    const maxRetries = 3;
    const baseDelayMs = 1000; // 1 second initial delay

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        // Try server fetch first
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 3));

        AppLogger.common('✅ User data fetched successfully on attempt ${attempt + 1}');
        return userDoc;
      } catch (e) {
        // Check if this is a retriable error
        if (_isRetriableFirestoreError(e) && attempt < maxRetries) {
          final delayMs = baseDelayMs * (1 << attempt); // Exponential backoff: 1s, 2s, 4s
          AppLogger.common('⏳ Retriable Firestore error on attempt ${attempt + 1}, retrying in ${delayMs}ms: $e');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // If this is the last attempt or not retriable, try cache-only fallback
        if (attempt == maxRetries || !_isRetriableFirestoreError(e)) {
          try {
            AppLogger.common('🔄 Attempting cache-only fallback after server failures');
            final cachedDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get(const GetOptions(source: Source.cache))
                .timeout(const Duration(seconds: 2));

            if (cachedDoc.exists) {
              AppLogger.common('✅ Retrieved user data from cache as fallback');
              return cachedDoc;
            }
          } catch (cacheError) {
            AppLogger.common('❌ Cache fallback also failed: $cacheError');
          }
        }

        // Re-throw the original error if we can't recover
        AppLogger.common('❌ All retry attempts and fallback failed: $e');
        rethrow;
      }
    }

    // This should never be reached, but just in case
    throw Exception('Unexpected error in fetch retry logic');
  }

  /// Check if a Firestore error is retriable (transient)
  bool _isRetriableFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      // UNAVAILABLE errors are transient and should be retried
      // Other retriable codes: DEADLINE_EXCEEDED, RESOURCE_EXHAUSTED (with backoff)
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'resource-exhausted';
    }

    // Timeout exceptions are also retriable
    if (error is TimeoutException) {
      return true;
    }

    return false;
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
