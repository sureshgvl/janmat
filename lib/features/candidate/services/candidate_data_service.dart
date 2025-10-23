import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../models/candidate_model.dart';
import '../models/contact_model.dart';
import '../models/location_model.dart';
import '../repositories/candidate_repository.dart';
import '../../../utils/app_logger.dart';
import '../../../services/user_cache_service.dart';
import '../../../services/local_database_service.dart';
import '../../../features/user/controllers/user_controller.dart';

/// Service responsible for candidate data fetching, caching, and persistence.
/// Follows Single Responsibility Principle - handles only data operations.
class CandidateDataService {
  final CandidateRepository _candidateRepository = CandidateRepository();

  /// Fetch candidate data with caching and retry logic
  Future<Candidate?> fetchCandidateData(String userId) async {
    // Check SQLite cache first for instant loading
    final cachedCandidate = await _loadCandidateDataFromSQLite(userId);
    if (cachedCandidate != null) {
      AppLogger.database('⚡ Using cached candidate data from SQLite', tag: 'CANDIDATE_DATA_SERVICE');

      // Refresh from Firebase in background (fire-and-forget)
      _refreshCandidateDataInBackground(userId);

      return cachedCandidate;
    }

    // CACHE MISS: Fetch from Firebase and cache for next time
    AppLogger.database('Cache miss - fetching candidate data from Firebase', tag: 'CANDIDATE_DATA_SERVICE');

    // First check if user has completed their profile with retry logic
    final userDoc = await _fetchUserDocumentWithRetry(userId);

    if (!userDoc.exists) {
      AppLogger.database('User document not found, skipping candidate data fetch', tag: 'CANDIDATE_DATA_SERVICE');
      return null;
    }

    final userData = userDoc.data()!;
    final profileCompleted = userData['profileCompleted'] ?? false;
    final userRole = userData['role'] ?? 'voter';

    // Only fetch candidate data for candidates, not voters
    if (userRole != 'candidate') {
      AppLogger.database('User is not a candidate (role: $userRole), skipping candidate data fetch', tag: 'CANDIDATE_DATA_SERVICE');
      return null;
    }

    if (!profileCompleted) {
      AppLogger.database('Profile not completed, skipping candidate data fetch', tag: 'CANDIDATE_DATA_SERVICE');
      return null;
    }

    // Try to fetch candidate data with retry logic
    final data = await _fetchCandidateDataWithRetry(userId);
    if (data != null) {
      // Cache the candidate data in SQLite for instant future loads
      await _cacheCandidateDataInSQLite(data);

      // Update cache with the successful data for future use
      try {
        final userCacheService = UserCacheService();
        await userCacheService.updateCachedUserData({
          'uid': userData['uid'] ?? '',
          'name': data.name ?? userData['name'] ?? 'Unknown Candidate',
          'email': userData['email'],
          'photoURL': data.photo ?? userData['photo'],
          'party': data.party ?? userData['party'] ?? 'independent',
          'districtId': data.location.districtId ?? userData['districtId'],
          'bodyId': data.location.bodyId ?? userData['bodyId'],
          'wardId': data.location.wardId ?? userData['wardId'],
        });
        AppLogger.database('Updated cache with successful candidate data', tag: 'CANDIDATE_DATA_SERVICE');
      } catch (cacheError) {
        AppLogger.databaseError('Failed to update cache with candidate data', tag: 'CANDIDATE_DATA_SERVICE', error: cacheError);
      }

      return data;
    }

    // Fallback: Try to use cached user data when Firestore is unavailable
    return await _fallbackToCachedUserData(userData);
  }

  /// Check if user has premium access
  Future<bool> checkPremiumAccess(String userId, bool isSponsored) async {
    try {
      // Check premium status and highlight plan from centralized UserController
      final userController = Get.find<UserController>();
      final isPremium = userController.user.value?.premium ?? false;
      final isHighlightPlanActive = userController.user.value?.highlightPlanExpiresAt?.isAfter(DateTime.now()) ?? false;

      return isPremium && isHighlightPlanActive;
    } catch (e) {
      AppLogger.databaseError('Error checking premium access', tag: 'CANDIDATE_DATA_SERVICE', error: e);
      return false;
    }
  }

  /// Helper method to fetch user document with retry logic
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserDocumentWithRetry(String userId) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
      } catch (e) {
        AppLogger.databaseError('User document fetch attempt $attempt failed', tag: 'CANDIDATE_DATA_SERVICE', error: e);

        if (attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final delay = baseDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
        AppLogger.database('Retrying user document fetch in ${delay.inSeconds}s...', tag: 'CANDIDATE_DATA_SERVICE');
        await Future.delayed(delay);
      }
    }

    throw Exception('Failed to fetch user document after $maxRetries attempts');
  }

  /// Helper method to fetch candidate data with retry logic
  Future<Candidate?> _fetchCandidateDataWithRetry(String userId) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _candidateRepository.getCandidateData(userId);
      } catch (e) {
        AppLogger.databaseError('Candidate data fetch attempt $attempt failed', tag: 'CANDIDATE_DATA_SERVICE', error: e);

        if (attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final delay = baseDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
        AppLogger.database('Retrying candidate data fetch in ${delay.inSeconds}s...', tag: 'CANDIDATE_DATA_SERVICE');
        await Future.delayed(delay);
      }
    }

    throw Exception('Failed to fetch candidate data after $maxRetries attempts');
  }

  /// Load candidate data from SQLite cache
  Future<Candidate?> _loadCandidateDataFromSQLite(String userId) async {
    try {
      AppLogger.database('Checking candidate data cache for user: $userId', tag: 'CANDIDATE_DATA_SERVICE');

      final localDb = LocalDatabaseService();

      // Check if candidate data cache is valid (24 hours)
      final lastUpdate = await localDb.getLastUpdateTime('candidate_data_$userId');
      final cacheAge = lastUpdate != null ? DateTime.now().difference(lastUpdate) : null;
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < const Duration(hours: 24);

      AppLogger.database('Candidate data cache status for user $userId:', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Last update: ${lastUpdate?.toIso8601String() ?? 'Never'}', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Cache age: ${cacheAge?.inMinutes ?? 'N/A'} minutes', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Is valid: $isCacheValid', tag: 'CANDIDATE_DATA_SERVICE');

      if (!isCacheValid) {
        AppLogger.database('Candidate data cache expired for user: $userId', tag: 'CANDIDATE_DATA_SERVICE');
        return null;
      }

      // Try to load from a dedicated candidate cache table
      final db = await localDb.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.candidatesTable,
        where: 'id = ?',
        whereArgs: ['user_candidate_$userId']
      );

      if (maps.isEmpty) {
        AppLogger.database('No cached candidate data found for user: $userId', tag: 'CANDIDATE_DATA_SERVICE');
        return null;
      }

      final map = maps.first;
      final data = map['data'] as String;
      final candidate = Candidate.fromJson(Map<String, dynamic>.from(json.decode(data)));

      AppLogger.database('CACHE HIT - Loaded candidate data from SQLite', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  User: $userId', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Name: ${candidate.name}', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Party: ${candidate.party}', tag: 'CANDIDATE_DATA_SERVICE');

      return candidate;
    } catch (e) {
      AppLogger.databaseError('Error loading candidate data from SQLite (${e.toString()})', tag: 'CANDIDATE_DATA_SERVICE', error: e);
      return null;
    }
  }

  /// Cache candidate data in SQLite for instant future loads
  Future<void> _cacheCandidateDataInSQLite(Candidate candidate) async {
    try {
      AppLogger.database('Caching candidate data for user: ${candidate.userId}', tag: 'CANDIDATE_DATA_SERVICE');

      final localDb = LocalDatabaseService();

      // Store in candidates table with special key for user's own data
      final candidateDataMap = {
        'id': 'user_candidate_${candidate.userId}',
        'wardId': candidate.location.wardId ?? 'unknown',
        'districtId': candidate.location.districtId ?? 'unknown',
        'bodyId': candidate.location.bodyId ?? 'unknown',
        'stateId': 'maharashtra',
        'userId': candidate.userId,
        'name': candidate.name ?? 'Unknown',
        'party': candidate.party ?? 'independent',
        'photo': candidate.photo,
        'followersCount': 0, // Not relevant for user's own data
        'data': candidate.toJson().toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final db = await localDb.database;
      await db.insert(
        LocalDatabaseService.candidatesTable,
        candidateDataMap,
        conflictAlgorithm: ConflictAlgorithm.replace
      );

      await localDb.updateCacheMetadata('candidate_data_${candidate.userId}');

      AppLogger.database('Successfully cached candidate data', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Cache key: candidate_data_${candidate.userId}', tag: 'CANDIDATE_DATA_SERVICE');
    } catch (e) {
      AppLogger.databaseError('Error caching candidate data (${e.toString()})', tag: 'CANDIDATE_DATA_SERVICE', error: e);
    }
  }

  /// Refresh candidate data from Firebase in background (fire-and-forget)
  void _refreshCandidateDataInBackground(String userId) async {
    try {
      AppLogger.database('Background refresh: checking for updated candidate data', tag: 'CANDIDATE_DATA_SERVICE');

      // Fetch latest data from Firebase
      final data = await _fetchCandidateDataWithRetry(userId);
      if (data != null) {
        // Update cache with fresh data
        await _cacheCandidateDataInSQLite(data);
        AppLogger.database('Background refresh completed - cache updated', tag: 'CANDIDATE_DATA_SERVICE');
      } else {
        AppLogger.database('Background refresh: no candidate data found', tag: 'CANDIDATE_DATA_SERVICE');
      }
    } catch (e) {
      AppLogger.database('Background refresh failed (non-critical): $e', tag: 'CANDIDATE_DATA_SERVICE');
      // Don't throw - background refresh failure shouldn't affect UI
    }
  }

  /// Fallback method to use cached user data when Firestore is unavailable
  Future<Candidate?> _fallbackToCachedUserData(Map<String, dynamic> userData) async {
    try {
      AppLogger.database('Using cached user data fallback', tag: 'CANDIDATE_DATA_SERVICE');

      // Create a basic candidate object from user data
      final fallbackCandidate = Candidate(
        candidateId: userData['uid'] ?? '',
        userId: userData['uid'] ?? '',
        name: userData['name'] ?? 'Unknown Candidate',
        party: userData['party'] ?? 'independent',
        photo: userData['photo'],
        location: LocationModel(
          districtId: userData['districtId'],
          bodyId: userData['bodyId'],
          wardId: userData['wardId'],
        ),
        sponsored: false, // Default to false when offline
        approved: true, // Assume approved for cached data
        status: 'active',
        createdAt: DateTime.now(),
        contact: ExtendedContact(phone: '', email: null, socialLinks: null),
      );

      AppLogger.database('Fallback candidate data loaded successfully', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Name: ${fallbackCandidate.name}', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  Party: ${fallbackCandidate.party}', tag: 'CANDIDATE_DATA_SERVICE');
      AppLogger.database('  District: ${fallbackCandidate.location.districtId}', tag: 'CANDIDATE_DATA_SERVICE');

      return fallbackCandidate;
    } catch (e) {
      AppLogger.databaseError('Error creating fallback candidate data', tag: 'CANDIDATE_DATA_SERVICE', error: e);
      return null;
    }
  }
}
