import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../../../utils/app_logger.dart';

class SearchController extends GetxController {
  // Reactive state
  final RxString searchQuery = ''.obs;

  // Search results
  final RxList<Candidate> searchResults = <Candidate>[].obs;

  @override
  void onClose() {
    searchQuery.close();
    searchResults.close();
    super.onClose();
  }

  /// Simple search by name or party name
  void search(String query, List<Candidate> candidates) {
    searchQuery.value = query.trim();

    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    final lowercaseQuery = query.toLowerCase();

    final filteredCandidates = candidates.where((candidate) {
      // Search in candidate name
      final nameMatch = candidate.basicInfo?.fullName
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      // Search in party name
      final partyMatch = candidate.party
          .toLowerCase()
          .contains(lowercaseQuery);

      return nameMatch || partyMatch;
    }).toList();

    searchResults.assignAll(filteredCandidates);
    AppLogger.candidate('🔍 Search: "$query" -> ${filteredCandidates.length} results');
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    AppLogger.candidate('🧹 Cleared search');
  }

  /// Check if search is active
  bool get hasActiveSearch => searchQuery.isNotEmpty;

  /// Check if there are search results
  bool get hasResults => searchResults.isNotEmpty;

  /// Get current search results (immutable)
  List<Candidate> get currentResults => List.unmodifiable(searchResults);
}
