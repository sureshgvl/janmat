import 'dart:async';
import 'package:get/get.dart';
import '../models/candidate_model.dart';
import '../services/candidate_search_service.dart';
import '../../../utils/app_logger.dart';

class SearchController extends GetxController {
  final CandidateSearchService _searchService = CandidateSearchService();

  // Reactive state
  final RxString searchQuery = ''.obs;
  final Rx<SortOption> sortBy = SortOption.none.obs;
  final RxBool isSearching = false.obs;
  final RxBool isSearchDebouncing = false.obs;

  // Search results
  final RxList<Candidate> searchResults = <Candidate>[].obs;
  final RxList<String> searchSuggestions = <String>[].obs;

  // Search metadata
  final Rx<Map<String, dynamic>> lastSearchStats = Rx<Map<String, dynamic>>({});

  // Debounce timer
  Timer? _debounceTimer;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchQuery.close();
    sortBy.close();
    isSearching.close();
    isSearchDebouncing.close();
    searchResults.close();
    searchSuggestions.close();
    lastSearchStats.close();
    super.onClose();
  }

  /// Perform search with debouncing
  void search(String query, List<Candidate> candidates) {
    searchQuery.value = query;

    // Cancel existing timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    isSearchDebouncing.value = true;

    // Debounce search by 300ms
    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () => _performSearch(query, candidates),
    );
  }

  /// Perform the actual search
  void _performSearch(String query, List<Candidate> candidates) {
    isSearching.value = true;
    isSearchDebouncing.value = false;

    try {
      final results = _searchService.searchCandidates(candidates, query);
      searchResults.assignAll(results);

      // Update search statistics
      final stats = _searchService.getSearchStats(candidates, results, query);
      lastSearchStats.value = stats;

      // Generate suggestions
      updateSuggestions(candidates, query);

      AppLogger.candidate('🔍 Search completed: "$query" -> ${results.length} results');
    } catch (e) {
      AppLogger.candidateError('Search failed: $e');
      searchResults.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Update search suggestions
  void updateSuggestions(List<Candidate> candidates, String query) {
    if (query.length < 2) {
      searchSuggestions.clear();
      return;
    }

    final suggestions = _searchService.getSearchSuggestions(candidates, query);
    searchSuggestions.assignAll(suggestions);
  }

  /// Apply sorting to current results
  void applySorting(SortOption option) {
    sortBy.value = option;

    if (searchResults.isEmpty) return;

    final sorted = _searchService.sortCandidates(searchResults, option);
    searchResults.assignAll(sorted);

    AppLogger.candidate('🔄 Applied sorting: ${option.displayName}');
  }

  /// Filter candidates by location
  void filterByLocation(List<Candidate> candidates, {
    String? districtId,
    String? bodyId,
    String? wardId,
  }) {
    final filtered = _searchService.filterByLocation(
      candidates,
      districtId,
      bodyId,
      wardId,
    );

    if (searchQuery.isNotEmpty) {
      // If there's an active search, filter the search results
      final searchFiltered = _searchService.searchCandidates(filtered, searchQuery.value);
      searchResults.assignAll(searchFiltered);
    } else {
      // No active search, show all filtered results
      searchResults.assignAll(filtered);
    }

    AppLogger.candidate('🔍 Applied location filter: district=$districtId, body=$bodyId, ward=$wardId -> ${searchResults.length} results');
  }

  /// Clear search and reset to original state
  void clearSearch() {
    _debounceTimer?.cancel();
    searchQuery.value = '';
    isSearching.value = false;
    isSearchDebouncing.value = false;
    searchResults.clear();
    searchSuggestions.clear();
    lastSearchStats.value = {};

    AppLogger.candidate('🧹 Cleared search');
  }

  /// Check if a candidate matches current search
  bool matchesCurrentSearch(Candidate candidate) {
    if (searchQuery.isEmpty) return true;
    return _searchService.matchesSearch(candidate, searchQuery.value);
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStats() {
    return {
      'query': searchQuery.value,
      'result_count': searchResults.length,
      'is_searching': isSearching.value,
      'is_debouncing': isSearchDebouncing.value,
      'sort_by': sortBy.value.displayName,
      'suggestion_count': searchSuggestions.length,
      'last_stats': lastSearchStats.value,
    };
  }

  /// Set search results manually (useful for external filtering)
  void setSearchResults(List<Candidate> results) {
    searchResults.assignAll(results);
    AppLogger.candidate('📝 Set search results manually: ${results.length} items');
  }

  /// Add candidates to search results
  void addToSearchResults(List<Candidate> candidates) {
    // Avoid duplicates
    final existingIds = searchResults.map((c) => c.candidateId).toSet();
    final uniqueNew = candidates.where((c) => !existingIds.contains(c.candidateId)).toList();

    searchResults.addAll(uniqueNew);
    AppLogger.candidate('➕ Added ${uniqueNew.length} candidates to search results');
  }

  /// Remove candidates from search results
  void removeFromSearchResults(List<String> candidateIds) {
    searchResults.removeWhere((c) => candidateIds.contains(c.candidateId));
    AppLogger.candidate('➖ Removed ${candidateIds.length} candidates from search results');
  }

  /// Refresh search with current query
  void refreshSearch(List<Candidate> allCandidates) {
    if (searchQuery.isNotEmpty) {
      search(searchQuery.value, allCandidates);
    }
  }

  /// Check if search is active
  bool get hasActiveSearch => searchQuery.isNotEmpty;

  /// Check if there are search results
  bool get hasResults => searchResults.isNotEmpty;

  /// Get current search results (immutable)
  List<Candidate> get currentResults => List.unmodifiable(searchResults);
}
