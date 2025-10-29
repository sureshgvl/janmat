import 'package:get/get.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/models/candidate_party_model.dart';
import '../features/candidate/repositories/candidate_repository.dart';
import '../features/candidate/controllers/candidate_user_controller.dart';
import 'symbol_utils.dart';
import 'app_logger.dart';

/// Utility class for managing candidate data updates across the application.
/// Provides consistent methods for updating candidate data in both Firebase and local cache.
class CandidateDataManager {
  static final CandidateDataManager _instance =
      CandidateDataManager._internal();
  final CandidateRepository _repository = CandidateRepository();

  factory CandidateDataManager() => _instance;

  CandidateDataManager._internal();

  /// Update candidate data in Firebase database only
  Future<void> updateCandidateInFirebase(Candidate candidate) async {
    await _repository.updateCandidateExtraInfo(candidate);
    AppLogger.candidate(
      '✅ [CandidateDataManager] Firebase updated: ${candidate.candidateId}',
    );
  }

  /// Update candidate data in local cache (CandidateUserController) only
  void updateCandidateInLocalCache(Candidate updatedCandidate) {
    try {
      final candidateUserController = Get.find<CandidateUserController>();
      if (candidateUserController.candidate.value?.candidateId ==
          updatedCandidate.candidateId) {
        candidateUserController.candidate.value = updatedCandidate;
        AppLogger.candidate(
          '✅ [CandidateDataManager] Local cache updated: ${updatedCandidate.candidateId}',
        );
      }
    } catch (e) {
      AppLogger.candidateError(
        '[CandidateDataManager] Local cache update failed: $e',
      );
    }
  }

  /// Combined method: Update candidate in both Firebase and local cache
  Future<void> updateCandidateData({
    required Candidate candidate,
    bool updateFirebase = true,
    bool updateLocalCache = true,
    String? logContext,
  }) async {
    final context = logContext ?? 'Unknown';
    AppLogger.candidate(
      '🔄 [CandidateDataManager] Starting update for $context: ${candidate.candidateId}',
    );

    // Update Firebase first (if requested) - COMMENTED OUT
    // if (updateFirebase) {
    //   await updateCandidateInFirebase(candidate);
    // }

    // Update local cache (if requested)
    if (updateLocalCache) {
      updateCandidateInLocalCache(candidate);
    }

    AppLogger.candidate(
      '✅ [CandidateDataManager] Complete for $context: Party=${candidate.party}',
    );
  }

  /// Get current candidate from local cache
  Candidate? getCurrentCandidate() {
    try {
      return Get.find<CandidateUserController>().candidate.value;
    } catch (e) {
      AppLogger.candidateError(
        '[CandidateDataManager] Failed to get current candidate: $e',
      );
      return null;
    }
  }

  /// Utility method: Create updated candidate with new party
  Candidate createUpdatedCandidate({
    required Candidate original,
    required String newParty,
    String? symbolName,
    String? symbolUrl,
  }) {
    return original.copyWith(
      party: newParty,
      symbolName:
          symbolName ??
          (newParty.toLowerCase().contains('independent')
              ? (symbolName ?? original.symbolName)
              : SymbolUtils.getPartySymbolNameLocal(
                  newParty,
                  Get.locale?.languageCode ?? 'en',
                )),
      symbolUrl: newParty.toLowerCase().contains('independent')
          ? (symbolUrl ?? original.symbolUrl)
          : null,
    );
  }
}
