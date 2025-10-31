import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/highlights_model.dart';
import '../models/candidate_model.dart';
import '../repositories/highlights_repository.dart';

abstract class IHighlightsController {
  Future<HighlightsModel?> getHighlights(Candidate candidate);
  Future<bool> saveHighlights(Candidate candidate, HighlightsModel highlights);
  Future<bool> updateHighlightsFields(Candidate candidate, Map<String, dynamic> updates);
  Future<bool> saveHighlightsTab({required Candidate candidate, required HighlightData? highlight, String? candidateName, String? photoUrl, Function(String)? onProgress});
  Future<bool> saveHighlightsTabWithCandidate({required Candidate candidate, required HighlightData? highlight, String? candidateName, String? photoUrl, Function(String)? onProgress});
  Future<bool> saveHighlightsFast(Candidate candidate, Map<String, dynamic> updates, {String? candidateName, String? photoUrl, Function(String)? onProgress});
  Future<bool> updateCandidateHighlight(Candidate candidate, String highlightId, HighlightData highlightData);
  Future<bool> deleteCandidateHighlight(Candidate candidate, String highlightId);
  Future<String?> getCandidateSymbol(Candidate candidate);
  Future<bool> updateHighlightImageUrl(Candidate candidate, String highlightId, String imageUrl);
  Future<bool> addImagesToDeleteStorage(Candidate candidate, List<String> imageUrls);
  void updateHighlightLocal(dynamic value);
}

class HighlightsController extends GetxController implements IHighlightsController {
  final HighlightsRepository _highlightsRepository = HighlightsRepository();

  var highlights = Rx<HighlightsModel?>(null);
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.candidate('HighlightsController initialized');
  }

  @override
  Future<HighlightsModel?> getHighlights(Candidate candidate) async {
    try {
      isLoading.value = true;
      AppLogger.candidate('Loading highlights for candidate: ${candidate.candidateId}');

      final highlightsModel = await _highlightsRepository.getCandidateHighlights(candidate);
      highlights.value = highlightsModel ?? HighlightsModel(highlights: []);
      AppLogger.candidate('Loaded ${highlights.value?.length ?? 0} highlights');
      return highlights.value;
    } catch (e) {
      AppLogger.candidateError('Error loading highlights: $e');
      highlights.value = HighlightsModel(highlights: []);
      return HighlightsModel(highlights: []);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<bool> saveHighlights(Candidate candidate, HighlightsModel highlights) async {
    try {
      AppLogger.candidate('Saving highlights for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.saveHighlights(candidate, highlights);
    } catch (e) {
      AppLogger.candidateError('Error saving highlights: $e');
      return false;
    }
  }

  @override
  Future<bool> updateHighlightsFields(Candidate candidate, Map<String, dynamic> updates) async {
    try {
      AppLogger.candidate('Updating highlights fields for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.updateHighlightsFields(candidate, updates);
    } catch (e) {
      AppLogger.candidateError('Error updating highlights fields: $e');
      return false;
    }
  }

  @override
  Future<bool> updateCandidateHighlight(Candidate candidate, String highlightId, HighlightData highlightData) async {
    try {
      AppLogger.candidate('Updating highlight for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.updateCandidateHighlight(
          candidate.candidateId, highlightData, candidate);
    } catch (e) {
      AppLogger.candidateError('Error updating highlight: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteCandidateHighlight(Candidate candidate, String highlightId) async {
    try {
      AppLogger.candidate('Deleting highlight for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.deleteCandidateHighlight(
          candidate.candidateId, candidate);
    } catch (e) {
      AppLogger.candidateError('Error deleting highlight: $e');
      return false;
    }
  }

  void clearHighlights() {
    highlights.value = null;
    AppLogger.candidate('Highlights cleared');
  }

  void updateHighlightLocal(dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateHighlight method
    if (value is HighlightData) {
      highlights.value = HighlightsModel(highlights: [value]);
      AppLogger.candidate('Highlight updated in local state');
    } else if (value is Map<String, dynamic>) {
      // Handle Map input (from UI)
      final highlightData = HighlightData.fromJson(value);
      highlights.value = HighlightsModel(highlights: [highlightData]);
      AppLogger.candidate('Highlight updated from Map in local state');
    }
  }

  @override
  /// TAB-SPECIFIC SAVE: Direct highlights tab save method
  /// Handles all highlights operations for the tab independently
  Future<bool> saveHighlightsTab({
    required Candidate candidate,
    required HighlightData? highlight,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.candidate('🎯 TAB SAVE: Highlights tab for ${candidate.candidateId}');

      onProgress?.call('Saving highlights...');

      // For highlights tab, we save the highlight data
      bool success;
      if (highlight != null) {
        success = await updateCandidateHighlight(candidate, 'dummy', highlight);
      } else {
        // If no highlight, delete existing one
        success = await deleteCandidateHighlight(candidate, 'dummy');
      }

      if (success) {
        onProgress?.call('Highlights saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        // Highlights don't typically need additional background operations
        // like notifications or cache updates since they're profile-specific

        AppLogger.candidate('✅ TAB SAVE: Highlights completed successfully');
        return true;
      } else {
        AppLogger.candidateError('❌ TAB SAVE: Highlights save failed');
        return false;
      }
    } catch (e) {
      AppLogger.candidateError('❌ TAB SAVE: Highlights tab save failed', error: e);
      return false;
    }
  }

  /// FAST SAVE: Direct highlights update for simple field changes
  /// Main save is fast, but triggers essential background operations
  @override
  Future<bool> saveHighlightsFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.candidate('🚀 FAST SAVE: Highlights for ${candidate.candidateId}');

      // For highlights, we typically don't do direct field updates like other tabs
      // Highlights are managed through specific update operations
      // This method is here for consistency with other controllers
      // In practice, highlights are saved through updateHighlight method

      // For now, we'll treat this as a no-op since highlights don't have simple field updates
      // like basic info, manifesto, etc.
      AppLogger.candidate('✅ FAST SAVE: Highlights fast save completed (no-op)');
      return true;
    } catch (e) {
      AppLogger.candidateError('❌ FAST SAVE: Highlights failed', error: e);
      return false;
    }
  }

  @override
  Future<String?> getCandidateSymbol(Candidate candidate) async {
    try {
      AppLogger.candidate('Getting candidate symbol for: ${candidate.candidateId}');
      return await _highlightsRepository.getCandidateSymbol(candidate);
    } catch (e) {
      AppLogger.candidateError('Error getting candidate symbol: $e');
      return null;
    }
  }

  @override
  Future<bool> updateHighlightImageUrl(Candidate candidate, String highlightId, String imageUrl) async {
    try {
      AppLogger.candidate('Updating highlight image URL for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.updateHighlightImageUrl(candidate, highlightId, imageUrl);
    } catch (e) {
      AppLogger.candidateError('Error updating highlight image URL: $e');
      return false;
    }
  }

  @override
  Future<bool> addImagesToDeleteStorage(Candidate candidate, List<String> imageUrls) async {
    try {
      AppLogger.candidate('Adding images to delete storage for candidate: ${candidate.candidateId}');
      return await _highlightsRepository.addImagesToDeleteStorage(candidate, imageUrls);
    } catch (e) {
      AppLogger.candidateError('Error adding images to delete storage: $e');
      return false;
    }
  }

  @override
  Future<bool> saveHighlightsTabWithCandidate({String? candidateId, Candidate? candidate, HighlightData? highlight, String? candidateName, String? photoUrl, Function(String)? onProgress}) async {
    if (candidate != null) {
      return saveHighlightsTab(candidate: candidate, highlight: highlight, candidateName: candidateName, photoUrl: photoUrl, onProgress: onProgress);
    }
    return false;
  }
}
