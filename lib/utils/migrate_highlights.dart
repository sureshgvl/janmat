import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class HighlightMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all highlights from the old flat structure to the new hierarchical structure
  Future<void> migrateHighlightsToHierarchicalStructure() async {
    try {
      AppLogger.common('🚀 Starting highlight migration to hierarchical structure');

      // Get all highlights from the old flat collection
      final highlightsSnapshot = await _firestore.collection('highlights').get();

      AppLogger.common('📊 Found ${highlightsSnapshot.docs.length} highlights to migrate');

      int migratedCount = 0;
      int errorCount = 0;

      for (final doc in highlightsSnapshot.docs) {
        try {
          final highlightData = doc.data();
          final highlightId = doc.id;

          // Extract location information from locationKey or individual fields
          final locationKey = highlightData['locationKey'] as String?;
          final districtId = highlightData['districtId'] as String?;
          final bodyId = highlightData['bodyId'] as String?;
          final wardId = highlightData['wardId'] as String?;

          String finalDistrictId = districtId ?? '';
          String finalBodyId = bodyId ?? '';
          String finalWardId = wardId ?? '';

          // If we have a locationKey, parse it
          if (locationKey != null && locationKey.contains('_')) {
            final parts = locationKey.split('_');
            if (parts.length >= 3) {
              finalDistrictId = parts[0];
              finalBodyId = parts[1];
              finalWardId = parts[2];
            }
          }

          // Skip if we don't have complete location info
          if (finalDistrictId.isEmpty || finalBodyId.isEmpty || finalWardId.isEmpty) {
            AppLogger.common('⚠️ Skipping highlight $highlightId - missing location info');
            errorCount++;
            continue;
          }

          // Create the hierarchical path
          final hierarchicalPath = _firestore
              .collection('states')
              .doc('maharashtra')
              .collection('districts')
              .doc(finalDistrictId)
              .collection('bodies')
              .doc(finalBodyId)
              .collection('wards')
              .doc(finalWardId)
              .collection('highlights')
              .doc(highlightId);

          // Copy the highlight data to the new location
          await hierarchicalPath.set(highlightData);

          AppLogger.common('✅ Migrated highlight $highlightId to $finalDistrictId/$finalBodyId/$finalWardId');
          migratedCount++;

          // Optional: Delete from old location after successful migration
          // await doc.reference.delete();

        } catch (e) {
          AppLogger.commonError('❌ Error migrating highlight ${doc.id}', error: e);
          errorCount++;
        }
      }

      AppLogger.common('🎉 Migration completed: $migratedCount migrated, $errorCount errors');

    } catch (e) {
      AppLogger.commonError('❌ Migration failed', error: e);
      throw Exception('Migration failed: $e');
    }
  }

  /// Verify that highlights exist in the new hierarchical structure
  Future<void> verifyMigration() async {
    try {
      AppLogger.common('🔍 Verifying highlight migration');

      // Get all states
      final statesSnapshot = await _firestore.collection('states').get();

      int totalHighlights = 0;

      for (final stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (final districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (final bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (final wardDoc in wardsSnapshot.docs) {
              final highlightsSnapshot = await wardDoc.reference.collection('highlights').get();

              if (highlightsSnapshot.docs.isNotEmpty) {
                AppLogger.common('📍 Ward ${stateDoc.id}/${districtDoc.id}/${bodyDoc.id}/${wardDoc.id}: ${highlightsSnapshot.docs.length} highlights');
                totalHighlights += highlightsSnapshot.docs.length;
              }
            }
          }
        }
      }

      AppLogger.common('✅ Verification complete: $totalHighlights highlights found in hierarchical structure');

    } catch (e) {
      AppLogger.commonError('❌ Verification failed', error: e);
    }
  }

  /// Clean up old highlights collection (use with caution!)
  Future<void> cleanupOldHighlights() async {
    try {
      AppLogger.common('🧹 Starting cleanup of old highlights collection');

      // This is dangerous - only run after thorough verification
      // const batchSize = 10;
      // final highlightsSnapshot = await _firestore.collection('highlights').limit(batchSize).get();

      // For now, just log what would be deleted
      final highlightsSnapshot = await _firestore.collection('highlights').get();
      AppLogger.common('📊 Would delete ${highlightsSnapshot.docs.length} documents from old highlights collection');

      // Uncomment the following lines when ready to actually delete:
      // final batch = _firestore.batch();
      // for (final doc in highlightsSnapshot.docs) {
      //   batch.delete(doc.reference);
      // }
      // await batch.commit();

      AppLogger.common('✅ Cleanup simulation complete');

    } catch (e) {
      AppLogger.commonError('❌ Cleanup failed', error: e);
    }
  }
}
