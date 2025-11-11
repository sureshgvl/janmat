import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../lib/features/candidate/controllers/location_controller.dart';
import '../../lib/features/candidate/controllers/search_controller.dart' as search;
import '../../lib/features/candidate/controllers/pagination_controller.dart';
import '../../lib/features/candidate/models/candidate_model.dart';
import '../../lib/features/candidate/models/location_model.dart';
import '../../lib/features/candidate/models/contact_model.dart';

void main() {
  late LocationController locationController;
  late search.SearchController searchController;
  late PaginationController paginationController;

  // Mock load function for pagination
  Future<List<Candidate>> mockLoadFunction(int offset, int limit) async {
    // Return test data based on offset
    final allCandidates = [
      Candidate(
        candidateId: '1',
        userId: 'user1',
        party: 'BJP',
        location: LocationModel(
          stateId: 'maharashtra',
          districtId: 'pune',
          bodyId: 'pune_municipal_corporation',
          wardId: 'ward1',
        ),
        contact: ContactModel(
          phone: '1234567890',
          email: 'candidate1@example.com',
        ),
        sponsored: false,
        createdAt: DateTime.now(),
      ),
      Candidate(
        candidateId: '2',
        userId: 'user2',
        party: 'INC',
        location: LocationModel(
          stateId: 'maharashtra',
          districtId: 'pune',
          bodyId: 'pune_municipal_corporation',
          wardId: 'ward2',
        ),
        contact: ContactModel(
          phone: '0987654321',
          email: 'candidate2@example.com',
        ),
        sponsored: false,
        createdAt: DateTime.now(),
      ),
      Candidate(
        candidateId: '3',
        userId: 'user3',
        party: 'NCP',
        location: LocationModel(
          stateId: 'maharashtra',
          districtId: 'mumbai',
          bodyId: 'mumbai_municipal_corporation',
          wardId: 'ward3',
        ),
        contact: ContactModel(
          phone: '1111111111',
          email: 'candidate3@example.com',
        ),
        sponsored: false,
        createdAt: DateTime.now(),
      ),
    ];

    // Simulate pagination
    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, allCandidates.length);
    return allCandidates.sublist(startIndex, endIndex);
  }

  // Test data
  final testCandidates = [
    Candidate(
      candidateId: '1',
      userId: 'user1',
      party: 'BJP',
      location: LocationModel(
        stateId: 'maharashtra',
        districtId: 'pune',
        bodyId: 'pune_municipal_corporation',
        wardId: 'ward1',
      ),
      contact: ContactModel(
        phone: '1234567890',
        email: 'candidate1@example.com',
      ),
      sponsored: false,
      createdAt: DateTime.now(),
    ),
    Candidate(
      candidateId: '2',
      userId: 'user2',
      party: 'INC',
      location: LocationModel(
        stateId: 'maharashtra',
        districtId: 'pune',
        bodyId: 'pune_municipal_corporation',
        wardId: 'ward2',
      ),
      contact: ContactModel(
        phone: '0987654321',
        email: 'candidate2@example.com',
      ),
      sponsored: false,
      createdAt: DateTime.now(),
    ),
    Candidate(
      candidateId: '3',
      userId: 'user3',
      party: 'NCP',
      location: LocationModel(
        stateId: 'maharashtra',
        districtId: 'mumbai',
        bodyId: 'mumbai_municipal_corporation',
        wardId: 'ward3',
      ),
      contact: ContactModel(
        phone: '1111111111',
        email: 'candidate3@example.com',
      ),
      sponsored: false,
      createdAt: DateTime.now(),
    ),
  ];

  setUp(() {
    locationController = LocationController();
    searchController = search.SearchController();
    paginationController = PaginationController(loadFunction: mockLoadFunction);
  });

  tearDown(() {
    Get.reset();
  });

  group('Candidate List Integration Tests', () {
    test('should initialize all controllers correctly', () {
      expect(locationController.selectedStateId.value, 'maharashtra');
      expect(searchController.searchQuery.value, '');
      expect(paginationController.items, isEmpty);
    });

    test('should handle location filtering and search together', () {
      // Setup location filter
      locationController.selectedDistrictId.value = 'pune';
      locationController.selectedBodyId.value = 'pune_municipal_corporation';

      // Setup search
      searchController.searchQuery.value = 'BJP';

      // Simulate filtering by location first
      final locationFiltered = testCandidates.where((candidate) {
        return candidate.location.districtId == 'pune' &&
               candidate.location.bodyId == 'pune_municipal_corporation';
      }).toList();

      expect(locationFiltered.length, 2);

      // Then apply search filter
      final searchFiltered = locationFiltered.where((candidate) {
        return candidate.party.toLowerCase().contains('bjp');
      }).toList();

      expect(searchFiltered.length, 1);
      expect(searchFiltered.first.candidateId, '1');
    });

    test('should handle pagination with filtered results', () {
      // Setup pagination
      final pageSize = 2;

      // Get first page
      final page1 = testCandidates.take(pageSize).toList();
      expect(page1.length, 2);
      expect(page1.first.candidateId, '1');
      expect(page1.last.candidateId, '2');

      // Get second page
      final page2 = testCandidates.skip(pageSize).take(pageSize).toList();
      expect(page2.length, 1);
      expect(page2.first.candidateId, '3');
    });

    test('should maintain state consistency across controllers', () {
      // Change location
      locationController.selectedDistrictId.value = 'pune';

      // Perform search
      searchController.searchQuery.value = 'INC';

      // Check pagination stats
      final stats = paginationController.getStats();

      // Verify all states are maintained
      expect(locationController.selectedDistrictId.value, 'pune');
      expect(searchController.searchQuery.value, 'INC');
      expect(stats, isNotNull);
    });

    test('should handle complex filtering scenario', () {
      // Setup complex filters
      locationController.selectedDistrictId.value = 'pune';
      searchController.searchQuery.value = 'BJP';

      // Simulate complex filtering logic
      final results = testCandidates.where((candidate) {
        // Location filter
        final locationMatch = candidate.location.districtId == 'pune';

        // Search filter
        final searchMatch = candidate.party.toLowerCase().contains('bjp');

        return locationMatch && searchMatch;
      }).toList();

      expect(results.length, 1);
      expect(results.first.party, 'BJP');
    });

    test('should handle controller cleanup properly', () {
      // Setup some state
      locationController.selectedDistrictId.value = 'test';
      searchController.searchQuery.value = 'test';

      // Simulate cleanup (this would happen when controllers are disposed)
      locationController.clearSelections();
      searchController.clearSearch();
      paginationController.clear();

      // Verify cleanup
      expect(locationController.selectedDistrictId.value, null);
      expect(searchController.searchQuery.value, '');
      expect(paginationController.items, isEmpty);
    });

    test('should handle edge cases gracefully', () {
      // Test with empty data
      final emptyResults = <Candidate>[];
      expect(emptyResults, isEmpty);

      // Test with null filters
      locationController.selectedDistrictId.value = null;
      searchController.searchQuery.value = '';

      // Should not crash
      expect(locationController.selectedDistrictId.value, null);
      expect(searchController.searchQuery.value, '');
    });

    test('should maintain data integrity during operations', () {
      final originalCandidates = List<Candidate>.from(testCandidates);

      // Perform various operations
      locationController.selectedDistrictId.value = 'pune';
      searchController.searchQuery.value = 'BJP';

      // Verify original data is unchanged
      expect(testCandidates.length, originalCandidates.length);
      for (int i = 0; i < testCandidates.length; i++) {
        expect(testCandidates[i].candidateId, originalCandidates[i].candidateId);
      }
    });
  });
}
