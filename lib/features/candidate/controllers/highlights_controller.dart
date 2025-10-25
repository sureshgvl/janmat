import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/highlights_model.dart';
import '../models/candidate_model.dart';
import '../repositories/highlights_repository.dart';

class HighlightsController extends GetxController {
  final HighlightsRepository _highlightsRepository = HighlightsRepository();

  var highlights = Rx<HighlightsModel?>(null);
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    AppLogger.candidate('HighlightsController initialized');
  }

  Future<void> loadHighlights(String candidateId) async {
    try {
      isLoading.value = true;
      AppLogger.candidate('Loading highlights for candidate: $candidateId');

      final highlightsModel = await _highlightsRepository.getCandidateHighlights(candidateId);
      highlights.value = highlightsModel ?? HighlightsModel(highlights: []);
      AppLogger.candidate('Loaded ${highlights.value?.length ?? 0} highlights');
    } catch (e) {
      AppLogger.candidateError('Error loading highlights: $e');
      highlights.value = HighlightsModel(highlights: []);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateHighlight(String candidateId, HighlightData highlightData) async {
    try {
      AppLogger.candidate('Updating highlight for candidate: $candidateId');

      // Update the candidate's highlights with the new highlight
      final updateData = {
        'highlights': [highlightData.toJson()],
      };

      final success = await _highlightsRepository.updateCandidateHighlight(candidateId, highlightData);

      if (success) {
        // Update local state
        highlights.value = HighlightsModel(highlights: [highlightData]);
        AppLogger.candidate('Highlight updated successfully');
      }

      return success;
    } catch (e) {
      AppLogger.candidateError('Error updating highlight: $e');
      return false;
    }
  }

  Future<bool> deleteHighlight(String candidateId) async {
    try {
      AppLogger.candidate('Deleting highlight for candidate: $candidateId');

      // Remove the highlight from candidate's highlights
      final updateData = {
        'highlights': [],
      };

      final success = await _highlightsRepository.deleteCandidateHighlight(candidateId);

      if (success) {
        // Update local state
        highlights.value = HighlightsModel(highlights: []);
        AppLogger.candidate('Highlight deleted successfully');
      }

      return success;
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

  /// TAB-SPECIFIC SAVE: Direct highlights tab save method
  /// Handles all highlights operations for the tab independently
  Future<bool> saveHighlightsTab({
    required String candidateId,
    required HighlightData? highlight,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.candidate('🎯 TAB SAVE: Highlights tab for $candidateId');

      onProgress?.call('Saving highlights...');

      // For highlights tab, we save the highlight data
      bool success;
      if (highlight != null) {
        success = await updateHighlight(candidateId, highlight);
      } else {
        // If no highlight, delete existing one
        success = await deleteHighlight(candidateId);
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

  /// TAB-SPECIFIC SAVE WITH CANDIDATE: Direct highlights tab save method with candidate context
  /// Handles all highlights operations for the tab independently with full candidate data
  Future<bool> saveHighlightsTabWithCandidate({
    required String candidateId,
    required dynamic candidate,
    required HighlightData? highlight,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.candidate('🎯 TAB SAVE: Highlights tab with candidate for $candidateId');

      onProgress?.call('Saving highlights...');

      // For highlights tab, we save the highlight data
      bool success;
      if (highlight != null) {
        success = await updateHighlight(candidateId, highlight);
      } else {
        // If no highlight, delete existing one
        success = await deleteHighlight(candidateId);
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
  Future<bool> saveHighlightsFast(
    String candidateId,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.candidate('🚀 FAST SAVE: Highlights for $candidateId');

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
}
