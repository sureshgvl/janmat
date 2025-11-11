import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/features/candidate/controllers/search_controller.dart' as search;
import '../../lib/features/candidate/models/candidate_model.dart';
import '../../lib/features/candidate/models/location_model.dart';
import '../../lib/features/candidate/models/contact_model.dart';

// Helper function to create test candidates
Candidate createTestCandidate({
  required String candidateId,
  required String party,
  String? userId,
}) {
  return Candidate(
    candidateId: candidateId,
    userId: userId,
    party: party,
    location: LocationModel(
      stateId: 'maharashtra',
      districtId: 'district1',
      bodyId: 'body1',
      wardId: 'ward1',
    ),
    contact: ContactModel(
      phone: '1234567890',
      email: 'test@example.com',
    ),
    sponsored: false,
    createdAt: DateTime.now(),
  );
}

void main() {
  late search.SearchController controller;

  setUp(() {
    controller = search.SearchController();
  });

  tearDown(() {
    Get.reset();
  });

  group('SearchController', () {
    test('should initialize with default values', () {
      expect(controller.searchQuery.value, '');
      expect(controller.sortBy.value, isNotNull);
      expect(controller.isSearching.value, false);
      expect(controller.isSearchDebouncing.value, false);
      expect(controller.searchResults, isEmpty);
      expect(controller.searchSuggestions, isEmpty);
    });

    test('should have reactive properties', () {
      expect(controller.searchQuery, isA<RxString>());
      expect(controller.sortBy, isA<Rx<dynamic>>());
      expect(controller.isSearching, isA<RxBool>());
      expect(controller.isSearchDebouncing, isA<RxBool>());
      expect(controller.searchResults, isA<RxList<Candidate>>());
      expect(controller.searchSuggestions, isA<RxList<String>>());
    });

    test('should clear search correctly', () {
      // Setup initial state
      controller.searchQuery.value = 'test query';
      controller.isSearching.value = true;
      controller.isSearchDebouncing.value = true;
      controller.searchResults.add(createTestCandidate(candidateId: 'test', party: 'test'));
      controller.searchSuggestions.add('suggestion');

      // Clear search
      controller.clearSearch();

      // Verify all search state is cleared
      expect(controller.searchQuery.value, '');
      expect(controller.isSearching.value, false);
      expect(controller.isSearchDebouncing.value, false);
      expect(controller.searchResults, isEmpty);
      expect(controller.searchSuggestions, isEmpty);
    });

    test('should check active search correctly', () {
      expect(controller.hasActiveSearch, false);

      controller.searchQuery.value = 'test';
      expect(controller.hasActiveSearch, true);

      controller.searchQuery.value = '';
      expect(controller.hasActiveSearch, false);
    });

    test('should check search results correctly', () {
      expect(controller.hasResults, false);

      controller.searchResults.add(createTestCandidate(candidateId: 'test', party: 'test'));
      expect(controller.hasResults, true);

      controller.searchResults.clear();
      expect(controller.hasResults, false);
    });

    test('should get current results immutably', () {
      final candidate = createTestCandidate(candidateId: 'test', party: 'test');
      controller.searchResults.add(candidate);

      final results = controller.currentResults;
      expect(results.length, 1);
      expect(results.first.candidateId, 'test');

      // Verify it's immutable
      expect(() => results.add(candidate), throwsUnsupportedError);
    });

    test('should set search results manually', () {
      final candidates = [
        createTestCandidate(candidateId: '1', party: 'party1'),
        createTestCandidate(candidateId: '2', party: 'party2'),
      ];

      controller.setSearchResults(candidates);

      expect(controller.searchResults.length, 2);
      expect(controller.searchResults.first.candidateId, '1');
      expect(controller.searchResults.last.candidateId, '2');
    });

    test('should add candidates to search results', () {
      final initialCandidate = createTestCandidate(candidateId: '1', party: 'party1');
      final newCandidates = [
        createTestCandidate(candidateId: '2', party: 'party2'),
        createTestCandidate(candidateId: '3', party: 'party3'),
      ];

      controller.searchResults.add(initialCandidate);
      controller.addToSearchResults(newCandidates);

      expect(controller.searchResults.length, 3);
      expect(controller.searchResults.map((c) => c.candidateId), containsAll(['1', '2', '3']));
    });

    test('should not add duplicate candidates', () {
      final candidate1 = createTestCandidate(candidateId: '1', party: 'party1');
      final candidate2 = createTestCandidate(candidateId: '1', party: 'party1'); // Duplicate

      controller.searchResults.add(candidate1);
      controller.addToSearchResults([candidate2]);

      expect(controller.searchResults.length, 1);
      expect(controller.searchResults.first.candidateId, '1');
    });

    test('should remove candidates from search results', () {
      final candidate1 = createTestCandidate(candidateId: '1', party: 'party1');
      final candidate2 = createTestCandidate(candidateId: '2', party: 'party2');
      final candidate3 = createTestCandidate(candidateId: '3', party: 'party3');

      controller.searchResults.addAll([candidate1, candidate2, candidate3]);
      controller.removeFromSearchResults(['1', '3']);

      expect(controller.searchResults.length, 1);
      expect(controller.searchResults.first.candidateId, '2');
    });

    test('should get search statistics correctly', () {
      controller.searchQuery.value = 'test query';
      controller.isSearching.value = true;
      controller.isSearchDebouncing.value = false;
      controller.searchResults.add(createTestCandidate(candidateId: '1', party: 'party1'));
      controller.searchSuggestions.addAll(['sug1', 'sug2']);

      final stats = controller.getSearchStats();

      expect(stats['query'], 'test query');
      expect(stats['result_count'], 1);
      expect(stats['is_searching'], true);
      expect(stats['is_debouncing'], false);
      expect(stats['suggestion_count'], 2);
    });

    test('should handle empty search query in refresh', () {
      controller.searchQuery.value = '';
      final allCandidates = [createTestCandidate(candidateId: '1', party: 'party1')];

      // This should not perform any search since query is empty
      controller.refreshSearch(allCandidates);

      // Results should remain empty
      expect(controller.searchResults, isEmpty);
    });

    test('should handle non-empty search query in refresh', () async {
      controller.searchQuery.value = 'party1';
      final allCandidates = [
        createTestCandidate(candidateId: '1', party: 'party1'),
        createTestCandidate(candidateId: '2', party: 'party2'),
      ];

      // This should perform search since query is not empty
      controller.refreshSearch(allCandidates);

      // Wait for debounced search to complete
      await Future.delayed(const Duration(milliseconds: 350));

      // Should have found the matching candidate
      expect(controller.searchResults.length, 1);
      expect(controller.searchResults.first.candidateId, '1');
    });
  });
}
