import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/achievements_model.dart';
import '../models/candidate_model.dart';

abstract class IAchievementsRepository {
  Future<AchievementsModel?> getAchievements(Candidate candidate);
  Future<bool> updateAchievements(String candidateId, AchievementsModel achievements, Candidate candidate);
  Future<bool> updateAchievementsFields(Candidate candidate, Map<String, dynamic> updates);
  Future<void> updateAchievementsFast(Candidate candidate, Map<String, dynamic> updateData);
}

class AchievementsRepository implements IAchievementsRepository {
  final FirebaseFirestore _firestore;

  AchievementsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AchievementsModel?> getAchievements(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching achievements for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate document from hierarchical path
      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)  // Use stateId from candidate.location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .get();

      if (!candidateDoc.exists) {
        AppLogger.database('Candidate document not found: $candidateId', tag: 'ACHIEVEMENTS_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      if (!data.containsKey('achievements')) {
        AppLogger.database('No achievements found in candidate document', tag: 'ACHIEVEMENTS_REPO');
        return null;
      }

      final achievementsData = data['achievements'] as List<dynamic>;
      return AchievementsModel.fromJson({'achievements': achievementsData});
    } catch (e) {
      AppLogger.databaseError('Error fetching achievements', tag: 'ACHIEVEMENTS_REPO', error: e);
      throw Exception('Failed to fetch achievements: $e');
    }
  }

  @override
  Future<bool> updateAchievements(String candidateId, AchievementsModel achievements, Candidate candidate) async {
    try {
      AppLogger.database('Updating achievements for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from candidate object (following basic info pattern)
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'ACHIEVEMENTS_REPO');

      // 🔧 🏗️ REPOSITORY-LEVEL CLEANUP: Final defense against local paths
      final rawAchievements = achievements.toJson()['achievements'] as List<dynamic>;

      // Clean each achievement to ensure no local paths reach database
      final cleanedAchievements = rawAchievements.map((achievement) {
        final Map<String, dynamic> achMap = Map.from(achievement as Map);

        // Check and clean photoUrl if it's a local path
        if (achMap['photoUrl'] != null &&
            achMap['photoUrl'] is String &&
            achMap['photoUrl'].startsWith('local:')) {
          AppLogger.database('✅ REPO CLEANUP: Removed local photo path for ${achMap['title'] ?? 'Unknown'}', tag: 'ACHIEVEMENTS_REPO');
          achMap['photoUrl'] = null;
        }

        return achMap;
      }).toList();

      final updates = {
        'achievements': cleanedAchievements,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      AppLogger.database('📝 REPO: Final cleaned achievements count: ${cleanedAchievements.length}', tag: 'ACHIEVEMENTS_REPO');
      for (int i = 0; i < cleanedAchievements.length; i++) {
        final ach = cleanedAchievements[i] as Map<String, dynamic>;
        AppLogger.database('📝 REPO: Saved item $i: ${ach['title']} photoUrl: ${ach['photoUrl']}', tag: 'ACHIEVEMENTS_REPO');
      }

      await _firestore
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update(updates);

      AppLogger.database('Achievements updated successfully', tag: 'ACHIEVEMENTS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating achievements', tag: 'ACHIEVEMENTS_REPO', error: e);
      throw Exception('Failed to update achievements: $e');
    }
  }

  @override
  Future<bool> updateAchievementsFields(Candidate candidate, Map<String, dynamic> updates) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating achievements fields for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'ACHIEVEMENTS_REPO');

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['achievements'] = value;
      });

      fieldUpdates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('states')
          .doc(stateId)  // Use stateId from candidate.location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId)
          .update(fieldUpdates);

      AppLogger.database('Achievements fields updated successfully', tag: 'ACHIEVEMENTS_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating achievements fields', tag: 'ACHIEVEMENTS_REPO', error: e);
      throw Exception('Failed to update achievements fields: $e');
    }
  }

  @override
  Future<void> updateAchievementsFast(Candidate candidate, Map<String, dynamic> updateData) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST UPDATE: Achievements for $candidateId', tag: 'ACHIEVEMENTS_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'ACHIEVEMENTS_FAST');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)  // Use stateId from candidate.location
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Ensure the data is properly structured for achievements at top level
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'achievements') {
          // Store achievements directly at top level
          structuredUpdateData[key] = value;
        } else {
          // For other fields like updatedAt, keep them as-is
          structuredUpdateData[key] = value;
        }
      });

      AppLogger.database('   Structured update data: $structuredUpdateData', tag: 'ACHIEVEMENTS_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'ACHIEVEMENTS_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'ACHIEVEMENTS_FAST', error: e);
      throw Exception('Failed to fast update achievements: $e');
    }
  }
}
