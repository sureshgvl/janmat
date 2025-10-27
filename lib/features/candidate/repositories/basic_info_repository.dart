import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/basic_info_model.dart';
import '../models/candidate_model.dart';

abstract class IBasicInfoRepository {
  Future<BasicInfoModel?> getBasicInfo(Candidate candidate);
  Future<bool> updateBasicInfoWithCandidate(String candidateId, BasicInfoModel basicInfo, Candidate candidate);
}

class BasicInfoRepository implements IBasicInfoRepository {
  final FirebaseFirestore _firestore;

  BasicInfoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<BasicInfoModel?> getBasicInfo(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching basic info for candidate: $candidateId', tag: 'BASIC_INFO_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'BASIC_INFO_REPO');

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
        AppLogger.database('Candidate document not found: $candidateId', tag: 'BASIC_INFO_REPO');
        return null;
      }

      final data = candidateDoc.data()!;

      // Read all BasicInfoModel fields from basic_info map at root level
      if (!data.containsKey('basic_info')) {
        AppLogger.database('No basic info found in candidate document', tag: 'BASIC_INFO_REPO');
        return null;
      }

      final basicInfoData = data['basic_info'] as Map<String, dynamic>;
      return BasicInfoModel.fromJson(basicInfoData);
    } catch (e) {
      AppLogger.databaseError('Error fetching basic info', tag: 'BASIC_INFO_REPO', error: e);
      throw Exception('Failed to fetch basic info: $e');
    }
  }



  @override
  Future<bool> updateBasicInfoWithCandidate(String candidateId, BasicInfoModel basicInfo, Candidate candidate) async {
    try {
      AppLogger.database('Updating basic info with candidate object for candidate: $candidateId', tag: 'BASIC_INFO_REPO');
      AppLogger.database('BasicInfo data: ${basicInfo.toJson()}', tag: 'BASIC_INFO_REPO');
      AppLogger.database('Candidate photo field: "${candidate.photo}"', tag: 'BASIC_INFO_REPO');

      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'BASIC_INFO_REPO');

      // Save all BasicInfoModel fields inside basic_info map at root level
      final updates = <String, dynamic>{
        'basic_info': basicInfo.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Also update photo field if it's changed in the candidate object
      if (candidate.photo != null && candidate.photo!.isNotEmpty) {
        updates['photo'] = candidate.photo;
        AppLogger.database('✓ Including photo field in update: "${candidate.photo}"', tag: 'BASIC_INFO_REPO');
      } else {
        AppLogger.database('⚠️ No photo field to include - candidate.photo is: ${candidate.photo}', tag: 'BASIC_INFO_REPO');
      }

      AppLogger.database('Final update data: $updates', tag: 'BASIC_INFO_REPO');

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

      AppLogger.database('Updating document at path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'BASIC_INFO_REPO');

      // Check if document exists first, if not, create it
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('Document does not exist, creating new document', tag: 'BASIC_INFO_REPO');
        await candidateRef.set({
          ...updates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updates);
      }

      AppLogger.database('Basic info updated successfully with candidate object', tag: 'BASIC_INFO_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating basic info with candidate', tag: 'BASIC_INFO_REPO', error: e);
      throw Exception('Failed to update basic info with candidate: $e');
    }
  }

}
