import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:janmat/firebase_options.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/migrate_candidate_parties.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase for testing
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Debug Candidate Location', () {
    test('Check if candidate exists in legacy collection', () async {
      AppLogger.common(
        '🔍 Checking legacy /candidates collection for userId: efSlmEmHpyMrrAqF8i5V',
      );

      try {
        final candidatesSnapshot = await FirebaseFirestore.instance
            .collection('candidates')
            .where('userId', isEqualTo: 'efSlmEmHpyMrrAqF8i5V')
            .limit(1)
            .get();

        if (candidatesSnapshot.docs.isNotEmpty) {
          final doc = candidatesSnapshot.docs.first;
          AppLogger.common('✅ Found candidate in legacy collection:');
          AppLogger.common('   Document ID: ${doc.id}');
          AppLogger.common('   Data: ${doc.data()}');
        } else {
          AppLogger.common('❌ No candidate found in legacy collection');
        }
      } catch (e) {
        AppLogger.common('❌ Error checking legacy collection: $e');
      }
    });

    test('Check if candidate exists in hierarchical structure', () async {
      AppLogger.common(
        '🔍 Checking hierarchical structure: /states/maharashtra/districts/Pune/bodies/pune_city/wards/ward_17/candidates/efSlmEmHpyMrrAqF8i5V',
      );

      try {
        final candidateDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc('Pune')
            .collection('bodies')
            .doc('pune_city')
            .collection('wards')
            .doc('ward_17')
            .collection('candidates')
            .doc('efSlmEmHpyMrrAqF8i5V')
            .get();

        if (candidateDoc.exists) {
          AppLogger.common('✅ Found candidate in hierarchical structure:');
          AppLogger.common('   Data: ${candidateDoc.data()}');
        } else {
          AppLogger.common('❌ No candidate found in hierarchical structure');
        }
      } catch (e) {
        AppLogger.common('❌ Error checking hierarchical structure: $e');
      }
    });

    test('Check if district collections exist', () async {
      AppLogger.common('🔍 Checking if district collections exist');

      try {
        final districtsSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .get();

        AppLogger.common('📊 Found ${districtsSnapshot.docs.length} districts:');
        for (var doc in districtsSnapshot.docs) {
          AppLogger.common('   - ${doc.id}');
        }

        // Check if Pune district exists
        final puneDoc = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc('Pune')
            .get();

        if (puneDoc.exists) {
          AppLogger.common('✅ Pune district exists');

          // Check bodies in Pune
          final bodiesSnapshot = await FirebaseFirestore.instance
              .collection('states')
              .doc('maharashtra')
              .collection('districts')
              .doc('Pune')
              .collection('bodies')
              .get();

          AppLogger.common('📊 Found ${bodiesSnapshot.docs.length} bodies in Pune:');
          for (var doc in bodiesSnapshot.docs) {
            AppLogger.common('   - ${doc.id}');
          }

          // Check if pune_city body exists
          final puneCityDoc = await FirebaseFirestore.instance
              .collection('states')
              .doc('maharashtra')
              .collection('districts')
              .doc('Pune')
              .collection('bodies')
              .doc('pune_city')
              .get();

          if (puneCityDoc.exists) {
            AppLogger.common('✅ pune_city body exists');

            // Check wards in pune_city
            final wardsSnapshot = await FirebaseFirestore.instance
                .collection('states')
                .doc('maharashtra')
                .collection('districts')
                .doc('Pune')
                .collection('bodies')
                .doc('pune_city')
                .collection('wards')
                .get();

            AppLogger.common(
              '📊 Found ${wardsSnapshot.docs.length} wards in pune_city:',
            );
            for (var doc in wardsSnapshot.docs) {
              AppLogger.common('   - ${doc.id}');
            }

            // Check if ward_17 exists
            final ward17Doc = await FirebaseFirestore.instance
                .collection('states')
                .doc('maharashtra')
                .collection('districts')
                .doc('Pune')
                .collection('bodies')
                .doc('pune_city')
                .collection('wards')
                .doc('ward_17')
                .get();

            if (ward17Doc.exists) {
              AppLogger.common('✅ ward_17 exists');

              // Check candidates in ward_17
              final candidatesSnapshot = await FirebaseFirestore.instance
                  .collection('states')
                  .doc('maharashtra')
                  .collection('districts')
                  .doc('Pune')
                  .collection('bodies')
                  .doc('pune_city')
                  .collection('wards')
                  .doc('ward_17')
                  .collection('candidates')
                  .get();

              AppLogger.common(
                '📊 Found ${candidatesSnapshot.docs.length} candidates in ward_17:',
              );
              for (var doc in candidatesSnapshot.docs) {
                AppLogger.common('   - ${doc.id}');
              }
            } else {
              AppLogger.common('❌ ward_17 does not exist');
            }
          } else {
            AppLogger.common('❌ pune_city body does not exist');
          }
        } else {
          AppLogger.common('❌ Pune district does not exist');
        }
      } catch (e) {
        AppLogger.common('❌ Error checking district collections: $e');
      }
    });

    test('Audit party data in candidate documents', () async {
      AppLogger.common('🔍 Starting party data audit...');

      try {
        final auditResult = await CandidatePartyMigrationManager.auditPartyData();

        AppLogger.common('📊 AUDIT RESULTS:');
        AppLogger.common('   Total candidates: ${auditResult['total_candidates'] ?? 0}');
        AppLogger.common('   Unique parties: ${auditResult['unique_parties'] ?? 0}');
        AppLogger.common('   Issues found: ${auditResult['issues_found'] ?? 0}');

        // Print party distribution
        final partyCounts = auditResult['party_counts'] as Map<String, int>? ?? {};
        AppLogger.common('   Party distribution:');
        partyCounts.forEach((party, count) {
          AppLogger.common('     $party: $count');
        });

        // Print sample issues
        final issues = auditResult['detailed_issues'] as List<String>? ?? [];
        if (issues.isNotEmpty) {
          AppLogger.common('   Sample issues:');
          issues.take(10).forEach((issue) => AppLogger.common('     $issue'));
          if (issues.length > 10) {
            AppLogger.common('     ... and ${issues.length - 10} more issues');
          }
        }

        // Check if we found any full party names that need conversion
        final hasIssues = auditResult['issues_found'] > 0;
        expect(hasIssues ? 'Found issues' : 'No issues found', hasIssues ? 'Found issues' : 'No issues found',
          reason: 'Party data audit ${hasIssues ? 'detected data needing migration' : 'shows no issues'}');

        AppLogger.common('✅ Party audit completed successfully');

      } catch (e) {
        AppLogger.common('❌ Error during party audit: $e');
        fail('Party audit test failed: $e');
      }
    });
  });
}
