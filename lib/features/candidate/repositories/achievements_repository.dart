import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/achievements_model.dart';

abstract class IAchievementsRepository {
  Future<AchievementsModel?> getAchievements(String candidateId);
  Future<bool> updateAchievements(String candidateId, AchievementsModel achievements);
  Future<bool> updateAchievementsFields(String candidateId, Map<String, dynamic> updates);
  Future<void> updateAchievementsFast(String candidateId, Map<String, dynamic> updateData);
}

class AchievementsRepository implements IAchievementsRepository {
  final FirebaseFirestore _firestore;

  AchievementsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AchievementsModel?> getAchievements(String candidateId) async {
    try {
      AppLogger.database('Fetching achievements for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from index first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();

      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId', tag: 'ACHIEVEMENTS_REPO');
        return null;
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      // Get candidate document from hierarchical path
      final candidateDoc = await _firestore
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
  Future<bool> updateAchievements(String candidateId, AchievementsModel achievements) async {
    try {
      AppLogger.database('Updating achievements for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final updates = {
        'achievements': achievements.toJson()['achievements'],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
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
  Future<bool> updateAchievementsFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('Updating achievements fields for candidate: $candidateId', tag: 'ACHIEVEMENTS_REPO');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['achievements'] = value;
      });

      fieldUpdates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
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
  Future<void> updateAchievementsFast(String candidateId, Map<String, dynamic> updateData) async {
    try {
      AppLogger.database('🚀 FAST UPDATE: Achievements for $candidateId', tag: 'ACHIEVEMENTS_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'ACHIEVEMENTS_FAST');

      // Get candidate location from index
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();
      if (!indexDoc.exists) {
        throw Exception('Candidate index not found: $candidateId');
      }

      final indexData = indexDoc.data()!;
      final districtId = indexData['districtId'];
      final bodyId = indexData['bodyId'];
      final wardId = indexData['wardId'];

      final candidateRef = _firestore
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
