import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:janmat/features/user/models/user_model.dart';
import '../../../utils/app_logger.dart';
import '../../candidate/models/candidate_model.dart';
import '../../candidate/controllers/candidate_user_controller.dart';
import '../../candidate/repositories/candidate_repository.dart';

class HomeServices {

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

    AppLogger.common('🔄 [HOME_SERVICES] Fetching fresh user data for home: $uid (no caching)');

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
            candidateModel = await _loadCandidateDataDirect(userModel.uid);
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

        // Prepare result data (serialize to JSON Maps)
        final result = {'user': userModel.toJson(), 'candidate': candidateModel?.toJson()};

        AppLogger.common('✅ Fresh user data loaded for: $uid (no caching)');
        return result;
      }
    } catch (e) {
      AppLogger.commonError('❌ User data fetch failed', error: e);
    }

    return {'user': null, 'candidate': null};
  }

  // Direct candidate data loading for home screen (no caching)
  Future<Candidate?> _loadCandidateDataDirect(String uid) async {
    try {
      // Use CandidateRepository to fetch from the correct nested structure
      final candidateRepository = CandidateRepository();
      final candidate = await candidateRepository.getCandidateData(uid);

      if (candidate != null) {
        AppLogger.common('✅ Candidate data loaded directly');
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

}
