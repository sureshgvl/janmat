import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './app_logger.dart';

class CandidateMigrationManager {
  static Future<void> migrateCandidatesToStates() async {
    final firestore = FirebaseFirestore.instance;

    try {
      AppLogger.core('🔄 Starting candidate migration from old structure to new state-based structure...');

      // Step 1: Get all candidates from the old structure
      final oldCandidatesSnapshot = await firestore.collection('candidates').get();
      AppLogger.core('📊 Found ${oldCandidatesSnapshot.docs.length} candidates in old structure');

      int migratedCount = 0;
      int skippedCount = 0;

      for (final candidateDoc in oldCandidatesSnapshot.docs) {
        try {
          final candidateData = candidateDoc.data();
          final candidateId = candidateDoc.id;

          // Extract location information
          final districtId = candidateData['districtId'] as String?;
          final bodyId = candidateData['bodyId'] as String?;
          final wardId = candidateData['wardId'] as String?;

          if (districtId == null || bodyId == null || wardId == null) {
            AppLogger.core('⚠️ Skipping candidate $candidateId - missing location data');
            AppLogger.core('   districtId: $districtId, bodyId: $bodyId, wardId: $wardId');
            skippedCount++;
            continue;
          }

          // Determine state ID (default to maharashtra for now)
          final stateId = 'maharashtra';

          // Create the new path
          final newPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId';

          // Check if candidate already exists in new location
          final existingDoc = await firestore.doc(newPath).get();
          if (existingDoc.exists) {
            AppLogger.core('⚠️ Candidate $candidateId already exists in new structure, skipping');
            skippedCount++;
            continue;
          }

          // Copy candidate to new location
          await firestore.doc(newPath).set(candidateData);
          AppLogger.core('✅ Migrated candidate: ${candidateData['name']} ($candidateId)');
          AppLogger.core('   From: /candidates/$candidateId');
          AppLogger.core('   To: $newPath');

          migratedCount++;

          // Optional: Delete from old location after successful migration
          // await firestore.collection('candidates').doc(candidateId).delete();

        } catch (e) {
          AppLogger.coreError('❌ Error migrating candidate ${candidateDoc.id}', error: e);
          skippedCount++;
        }
      }

      AppLogger.core('🎉 Migration completed!');
      AppLogger.core('   ✅ Migrated: $migratedCount candidates');
      AppLogger.core('   ⚠️ Skipped: $skippedCount candidates');

      // Step 2: Also check for candidates in the old district-based structure
      await _migrateFromDistrictStructure(firestore);

    } catch (e) {
      AppLogger.coreError('❌ Migration failed', error: e);
      rethrow;
    }
  }

  static Future<void> _migrateFromDistrictStructure(FirebaseFirestore firestore) async {
    try {
      AppLogger.core('🔄 Checking for candidates in old district-based structure...');

      // Get all districts
      final districtsSnapshot = await firestore.collection('districts').get();

      for (final districtDoc in districtsSnapshot.docs) {
        final districtId = districtDoc.id;

        // Get bodies in this district
        final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

        for (final bodyDoc in bodiesSnapshot.docs) {
          final bodyId = bodyDoc.id;

          // Get wards in this body
          final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

          for (final wardDoc in wardsSnapshot.docs) {
            final wardId = wardDoc.id;

            // Get candidates in this ward
            final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();

            if (candidatesSnapshot.docs.isNotEmpty) {
              AppLogger.core('📊 Found ${candidatesSnapshot.docs.length} candidates in old structure: districts/$districtId/bodies/$bodyId/wards/$wardId');

              final stateId = 'maharashtra';

              for (final candidateDoc in candidatesSnapshot.docs) {
                final candidateData = candidateDoc.data();
                final candidateId = candidateDoc.id;

                // Create new path
                final newPath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId';

                // Check if already exists
                final existingDoc = await firestore.doc(newPath).get();
                if (!existingDoc.exists) {
                  await firestore.doc(newPath).set(candidateData);
                  AppLogger.core('✅ Migrated candidate from district structure: ${candidateData['name']} ($candidateId)');
                }
              }
            }
          }
        }
      }

    } catch (e) {
      AppLogger.coreError('❌ Error migrating from district structure', error: e);
    }
  }

  static Future<void> verifyMigration() async {
    final firestore = FirebaseFirestore.instance;

    try {
      AppLogger.core('🔍 Verifying migration...');

      // Count candidates in old structure
      final oldCount = (await firestore.collection('candidates').get()).docs.length;
      AppLogger.core('📊 Candidates in old structure (/candidates/): $oldCount');

      // Count candidates in new structure
      final statesSnapshot = await firestore.collection('states').get();
      int newCount = 0;

      for (final stateDoc in statesSnapshot.docs) {
        final districtsSnapshot = await stateDoc.reference.collection('districts').get();

        for (final districtDoc in districtsSnapshot.docs) {
          final bodiesSnapshot = await districtDoc.reference.collection('bodies').get();

          for (final bodyDoc in bodiesSnapshot.docs) {
            final wardsSnapshot = await bodyDoc.reference.collection('wards').get();

            for (final wardDoc in wardsSnapshot.docs) {
              final candidatesSnapshot = await wardDoc.reference.collection('candidates').get();
              newCount += candidatesSnapshot.docs.length;
            }
          }
        }
      }

      AppLogger.core('📊 Candidates in new structure (/states/.../candidates/): $newCount');

      if (newCount > 0) {
        AppLogger.core('✅ Migration appears successful!');
      } else {
        AppLogger.core('⚠️ No candidates found in new structure. Migration may have failed.');
      }

    } catch (e) {
      AppLogger.coreError('❌ Error verifying migration', error: e);
    }
  }
}
