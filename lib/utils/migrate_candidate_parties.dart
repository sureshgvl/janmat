import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/candidate/models/candidate_model.dart';
import 'symbol_utils.dart';
import 'app_logger.dart';

/// Migration utility to fix candidate party data format
/// Converts full party names to proper party keys for consistent symbol display
class CandidatePartyMigrationManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Run migration on current user's candidate data
  static Future<void> migrateCurrentUserCandidates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.database('⚠️ No authenticated user, skipping migration', tag: 'MIGRATION');
      return;
    }

    AppLogger.database('🚀 Starting party migration for user: ${user.uid}', tag: 'MIGRATION');
    try {
      final candidatesRef = _firestore.collection('states')
          .doc('maharashtra')  // Assuming all candidates are in Maharashtra
          .collection('districts')
          .doc('mumbai_suburban')  // Will iterate through all districts
          .collection('bodies')
          .doc('municipality')  // Will iterate through all bodies
          .collection('wards')
          .where('userId', isEqualTo: user.uid);

      final candidatesSnapshot = await candidatesRef.get();

      AppLogger.database('📊 Found ${candidatesSnapshot.docs.length} candidates for user ${user.uid}', tag: 'MIGRATION');

      for (final doc in candidatesSnapshot.docs) {
        await _migrateCandidateDocument(doc, user.uid);
      }

      AppLogger.database('✅ Migration completed successfully', tag: 'MIGRATION');
    } catch (e) {
      AppLogger.databaseError('❌ Migration failed', tag: 'MIGRATION', error: e);
    }
  }

  /// Migrate a specific candidate document
  static Future<void> _migrateCandidateDocument(DocumentSnapshot<Map<String, dynamic>> document, String userId) async {
    try {
      final data = document.data();
      if (data == null) return;

      final candidateId = document.id;
      final currentParty = data['party'] as String?;
      final currentPhoto = data['photo'] as String?;
      final currentName = data['name'] as String?;

      AppLogger.database('📋 Processing candidate $candidateId:', tag: 'MIGRATION');
      AppLogger.database('   Name: $currentName', tag: 'MIGRATION');
      AppLogger.database('   Party: $currentParty', tag: 'MIGRATION');
      AppLogger.database('   Photo: ${currentPhoto != null ? 'present' : 'none'}', tag: 'MIGRATION');

      if (currentParty == null || currentParty.isEmpty) {
        AppLogger.database('⚠️ Skipping candidate with no party: $candidateId', tag: 'MIGRATION');
        return;
      }

      // Check if party is already a key (if it starts with a letter and is short)
      if (_isPartyKey(currentParty)) {
        AppLogger.database('✅ Candidate $candidateId already has proper party key: $currentParty', tag: 'MIGRATION');
        return;
      }

      // Convert full party name to key
      final convertedKey = SymbolUtils.convertOldPartyNameToKey(currentParty);
      if (convertedKey == null) {
        AppLogger.database('⚠️ Could not convert party name to key: "$currentParty" for candidate $candidateId', tag: 'MIGRATION');
        // Default to independent if we can't convert
        await _updateCandidateParty(document.reference, 'independent');
        return;
      }

      AppLogger.database('🔄 Converting party for candidate $candidateId:', tag: 'MIGRATION');
      AppLogger.database('   From: "$currentParty"', tag: 'MIGRATION');
      AppLogger.database('   To: "$convertedKey"', tag: 'MIGRATION');

      await _updateCandidateParty(document.reference, convertedKey);

      // Also update user document if this is the current user's candidate
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['candidateId'] == candidateId) {
          AppLogger.database('🔄 Also updating user document party', tag: 'MIGRATION');
          // Note: We don't store party in user document currently, so no update needed
        }
      }

    } catch (e) {
      AppLogger.databaseError('❌ Failed to migrate candidate ${document.id}', tag: 'MIGRATION', error: e);
    }
  }

  /// Update candidate party in Firestore
  static Future<void> _updateCandidateParty(DocumentReference<Map<String, dynamic>> docRef, String newParty) async {
    try {
      await docRef.update({
        'party': newParty,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.database('✅ Successfully updated party to "$newParty"', tag: 'MIGRATION');
    } catch (e) {
      AppLogger.databaseError('❌ Failed to update party to "$newParty"', tag: 'MIGRATION', error: e);
    }
  }

  /// Check if a string is likely a party key (short, starts with letter)
  static bool _isPartyKey(String party) {
    if (party.length > 20) return false;
    if (!RegExp(r'^[a-zA-Z]').hasMatch(party)) return false;
    if (['independent', 'ind', 'indie'].contains(party.toLowerCase())) return true;
    if (['ncp', 'bjp', 'inc', 'vba', 'ss', 'rpi'].contains(party.toLowerCase())) return true;
    return false;
  }

  /// Get all candidates in the system (for admin migration)
  static Future<void> migrateAllCandidates() async {
    AppLogger.database('🚀 Starting full system party migration', tag: 'MIGRATION');

    try {
      final states = await _firestore.collection('states').get();

      for (final stateDoc in states.docs) {
        final stateData = stateDoc.data();
        final stateId = stateDoc.id;
        AppLogger.database('🏛️ Processing state: $stateId - ${stateData['name'] ?? 'Unknown'}', tag: 'MIGRATION');

        final districtsRef = stateDoc.reference.collection('districts');
        final districts = await districtsRef.get();

        for (final districtDoc in districts.docs) {
          final districtData = districtDoc.data();
          final districtId = districtDoc.id;
          AppLogger.database('🏞️ Processing district: $districtId - ${districtData['name'] ?? 'Unknown'}', tag: 'MIGRATION');

          final bodiesRef = districtDoc.reference.collection('bodies');
          final bodies = await bodiesRef.get();

          for (final bodyDoc in bodies.docs) {
            final bodyData = bodyDoc.data();
            final bodyId = bodyDoc.id;
            AppLogger.database('🏢 Processing body: $bodyId - ${bodyData['name'] ?? 'Unknown'}', tag: 'MIGRATION');

            final wardsRef = bodyDoc.reference.collection('wards');
            final wards = await wardsRef.get();

            AppLogger.database('📋 Found ${wards.docs.length} wards in $districtId/$bodyId', tag: 'MIGRATION');

            // Process in batches of 10 to avoid overwhelming Firestore
            const batchSize = 10;
            final batches = <List<DocumentSnapshot<Map<String, dynamic>>>>[];

            for (var i = 0; i < wards.docs.length; i += batchSize) {
              final end = (i + batchSize < wards.docs.length) ? i + batchSize : wards.docs.length;
              batches.add(wards.docs.sublist(i, end));
            }

            for (final batch in batches) {
              final batchPromises = batch.map((doc) => _migrateCandidateDocument(doc, ''));
              await Future.wait(batchPromises);
              AppLogger.database('📊 Processed batch of ${batch.length} candidates', tag: 'MIGRATION');
            }
          }
        }
      }

      AppLogger.database('✅ Full system migration completed', tag: 'MIGRATION');
    } catch (e) {
      AppLogger.databaseError('❌ Full system migration failed', tag: 'MIGRATION', error: e);
    }
  }

  /// Test function to audit party data without making changes
  static Future<Map<String, dynamic>> auditPartyData() async {
    final audit = <String, dynamic>{};
    final issues = <String>[];
    final partyCounts = <String, int>{};
    int totalCandidates = 0;

    AppLogger.database('🔍 Starting party data audit', tag: 'AUDIT');

    try {
      final states = await _firestore.collection('states').get();

      for (final stateDoc in states.docs) {
        final districtsRef = stateDoc.reference.collection('districts');
        final districts = await districtsRef.get();

        for (final districtDoc in districts.docs) {
          final bodiesRef = districtDoc.reference.collection('bodies');
          final bodies = await bodiesRef.get();

          for (final bodyDoc in bodies.docs) {
            final wardsRef = bodyDoc.reference.collection('wards');
            final wards = await wardsRef.get();

            for (final wardDoc in wards.docs) {
              final data = wardDoc.data();
              final party = data['party'] as String?;
              final name = data['name'] as String?;
              final candidateId = wardDoc.id;

              if (party != null) {
                totalCandidates++;

                // Count party usage
                partyCounts[party] = (partyCounts[party] ?? 0) + 1;

                // Check for issues
                if (!_isPartyKey(party)) {
                  issues.add('"$party" - Candidate: $name ($candidateId)');
                }
              }
            }
          }
        }
      }

      audit['total_candidates'] = totalCandidates;
      audit['unique_parties'] = partyCounts.length;
      audit['party_counts'] = partyCounts;
      audit['issues_found'] = issues.length;
      audit['detailed_issues'] = issues;

      AppLogger.database('📊 Audit Results:', tag: 'AUDIT');
      AppLogger.database('   Total candidates: $totalCandidates', tag: 'AUDIT');
      AppLogger.database('   Unique parties: ${partyCounts.length}', tag: 'AUDIT');
      AppLogger.database('   Issues found: ${issues.length}', tag: 'AUDIT');
      AppLogger.database('   Party distribution:', tag: 'AUDIT');

      partyCounts.forEach((party, count) {
        AppLogger.database('     $party: $count', tag: 'AUDIT');
      });

      if (issues.isNotEmpty) {
        AppLogger.database('   Detailed issues:', tag: 'AUDIT');
        issues.take(20).forEach((issue) => AppLogger.database('     $issue', tag: 'AUDIT'));
        if (issues.length > 20) {
          AppLogger.database('     ... and ${issues.length - 20} more', tag: 'AUDIT');
        }
      }

    } catch (e) {
      AppLogger.databaseError('❌ Audit failed', tag: 'AUDIT', error: e);
      audit['error'] = e.toString();
    }

    return audit;
  }
}
