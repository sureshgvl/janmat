import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/services/highlight_service.dart';
import '../lib/utils/migrate_highlights.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase for testing
    await Firebase.initializeApp();
  });

  group('Highlight Hierarchical Structure Tests', () {
    test('Should create highlight in hierarchical structure', () async {
      // Test creating a highlight in the new structure
      final highlightId = await HighlightService.createHighlight(
        candidateId: 'test_candidate_123',
        wardId: 'ward_17',
        districtId: 'pune',
        bodyId: 'pune_m_cop',
        package: 'platinum',
        placement: ['carousel', 'top_banner'],
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        candidateName: 'Test Candidate',
        party: 'BJP',
      );

      expect(highlightId, isNotNull);
      expect(highlightId, isNotEmpty);
    });

    test('Should fetch highlights from hierarchical structure', () async {
      // Test fetching highlights from the new structure
      final highlights = await HighlightService.getActiveHighlights(
        'pune',
        'pune_m_cop',
        'ward_17',
      );

      expect(highlights, isA<List<Highlight>>());
    });

    test('Should fetch platinum banner from hierarchical structure', () async {
      // Test fetching platinum banner from the new structure
      final banner = await HighlightService.getPlatinumBanner(
        'pune',
        'pune_m_cop',
        'ward_17',
      );

      // Banner might be null if none exists, which is fine
      expect(banner, isA<Highlight?>());
    });

    test('Migration service should work', () async {
      final migrationService = HighlightMigrationService();

      // Test verification (should not throw)
      await expectLater(
        migrationService.verifyMigration(),
        completes,
      );
    });
  });
}
