import 'dart:convert';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../models/candidate_model.dart';
import '../models/contact_model.dart';
import '../models/location_model.dart';
import '../repositories/candidate_repository.dart';
import '../../../utils/app_logger.dart';
import '../../../features/user/controllers/user_controller.dart';

/// Service responsible for candidate data fetching, caching, and persistence.
/// Follows Single Responsibility Principle - handles only data operations.
class CandidateDataService {
  final CandidateRepository _candidateRepository = CandidateRepository();

  /// Fetch candidate data from Firebase
  Future<Candidate?> fetchCandidateData(String userId) async {
    AppLogger.database('Fetching candidate data from Firebase', tag: 'CANDIDATE_DATA_SERVICE');

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
      AppLogger.database('Successfully fetched candidate data', tag: 'CANDIDATE_DATA_SERVICE');
      return data;
    }

    AppLogger.database('Failed to fetch candidate data', tag: 'CANDIDATE_DATA_SERVICE');
    return null;
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

}
