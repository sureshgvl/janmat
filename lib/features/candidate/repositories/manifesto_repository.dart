import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/candidate_model.dart';
import '../models/manifesto_model.dart';

abstract class IManifestoRepository {
  Future<ManifestoModel?> getManifesto(Candidate candidate);
  Future<bool> updateManifesto(Candidate candidate, ManifestoModel manifesto);
  Future<bool> updateManifestoWithCandidate(String candidateId, ManifestoModel manifesto, Candidate candidate);
  Future<bool> updateManifestoFields(Candidate candidate, Map<String, dynamic> updates);
  Future<void> updateManifestoFast(Candidate candidate, Map<String, dynamic> updateData);
}

class ManifestoRepository implements IManifestoRepository {
  final FirebaseFirestore _firestore;

  ManifestoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ManifestoModel?> getManifesto(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      print('🔍 MANIFESTO_REPO: Fetching manifesto for candidate: $candidateId');
      AppLogger.database('Fetching manifesto for candidate: $candidateId', tag: 'MANIFESTO_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      print('🔍 MANIFESTO_REPO: Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId');

      // Get candidate document from hierarchical path - use states path
      print('🔍 MANIFESTO_REPO: About to get candidate document');
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

      print('🔍 MANIFESTO_REPO: Candidate doc exists: ${candidateDoc.exists}');
      if (!candidateDoc.exists) {
        print('🔍 MANIFESTO_REPO: Candidate document not found: $candidateId');
        AppLogger.database('Candidate document not found: $candidateId', tag: 'MANIFESTO_REPO');
        return null;
      }

      print('🔍 MANIFESTO_REPO: Getting candidate data');
      final data = candidateDoc.data()!;
      print('🔍 MANIFESTO_REPO: Candidate data keys: ${data.keys.toList()}');

      if (!data.containsKey('manifesto_data')) {
        print('🔍 MANIFESTO_REPO: No manifesto_data found in candidate document');
        AppLogger.database('No manifesto_data found in candidate document', tag: 'MANIFESTO_REPO');

        // ManifestoCacheService is disabled - no caching
        AppLogger.database('⚠️ ManifestoCacheService disabled - no cache to clear for candidate: $candidateId', tag: 'MANIFESTO_REPO');

        return null;
      }

      print('🔍 MANIFESTO_REPO: Manifesto data found, parsing...');
      final manifestoData = data['manifesto_data'] as Map<String, dynamic>;
      print('🔍 MANIFESTO_REPO: Manifesto data: $manifestoData');

      // Check if manifesto data is essentially empty (no meaningful content)
      final hasTitle = manifestoData['title'] != null && manifestoData['title'].toString().trim().isNotEmpty;
      final hasPromises = manifestoData['promises'] != null && (manifestoData['promises'] as List?)?.isNotEmpty == true;

      if (!hasTitle && !hasPromises) {
        print('🔍 MANIFESTO_REPO: Manifesto data exists but is empty, clearing cache');
        AppLogger.database('Manifesto data exists but is empty, clearing cache', tag: 'MANIFESTO_REPO');

        // ManifestoCacheService is disabled - no caching
        AppLogger.database('⚠️ ManifestoCacheService disabled - no cache to clear for empty manifesto: $candidateId', tag: 'MANIFESTO_REPO');

        return null;
      }

      print('🔍 MANIFESTO_REPO: About to create ManifestoModel');
      final result = ManifestoModel.fromJson(manifestoData);
      print('🔍 MANIFESTO_REPO: Manifesto model created successfully: title=${result.title}');
      return result;
    } catch (e) {
      AppLogger.databaseError('Error fetching manifesto', tag: 'MANIFESTO_REPO', error: e);
      throw Exception('Failed to fetch manifesto: $e');
    }
  }

  @override
  Future<bool> updateManifestoWithCandidate(String candidateId, ManifestoModel manifesto, Candidate candidate) async {
    try {
      AppLogger.database('Updating manifesto with candidate object for candidate: $candidateId', tag: 'MANIFESTO_REPO');
      AppLogger.database('Manifesto data: ${manifesto.toJson()}', tag: 'MANIFESTO_REPO');

      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'MANIFESTO_REPO');

      // Save all ManifestoModel fields inside manifesto_data map at root level
      final updates = <String, dynamic>{
        'manifesto_data': manifesto.toJson(),
        'deleteStorage': candidate.deleteStorage,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      AppLogger.database('Final update data: $updates', tag: 'MANIFESTO_REPO');

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

      AppLogger.database('Updating document at path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'MANIFESTO_REPO');

      // Check if document exists first, if not, create it
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('Document does not exist, creating new document', tag: 'MANIFESTO_REPO');
        await candidateRef.set({
          ...updates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updates);
      }

      AppLogger.database('Manifesto updated successfully with candidate object', tag: 'MANIFESTO_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating manifesto with candidate', tag: 'MANIFESTO_REPO', error: e);
      throw Exception('Failed to update manifesto with candidate: $e');
    }
  }

  @override
  Future<bool> updateManifesto(Candidate candidate, ManifestoModel manifesto) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🔄 MANIFESTO_REPO: Updating manifesto for candidate: $candidateId', tag: 'MANIFESTO_REPO');
      AppLogger.database('   Manifesto title: ${manifesto.title}', tag: 'MANIFESTO_REPO');
      AppLogger.database('   Promises count: ${manifesto.promises?.length ?? 0}', tag: 'MANIFESTO_REPO');

      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('   Candidate location from object: $stateId/$districtId/$bodyId/$wardId', tag: 'MANIFESTO_REPO');

      final manifestoJson = manifesto.toJson();
      final updates = {
        'manifesto_data': manifestoJson,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Check if document exists first, create if not
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('   Document does not exist, creating new document', tag: 'MANIFESTO_REPO');
        await candidateRef.set({
          ...updates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updates);
      }

      AppLogger.database('✅ MANIFESTO_REPO: Manifesto updated successfully for $candidateId', tag: 'MANIFESTO_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ MANIFESTO_REPO: Error updating manifesto for $candidateId', tag: 'MANIFESTO_REPO', error: e);
      throw Exception('Failed to update manifesto: $e');
    }
  }

  @override
  Future<bool> updateManifestoFields(Candidate candidate, Map<String, dynamic> updates) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating manifesto fields for candidate: $candidateId', tag: 'MANIFESTO_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'MANIFESTO_REPO');

      // Prepare updates similar to basic_info pattern
      final allUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore manifesto_data fields
      updates.forEach((key, value) {
        allUpdates['manifesto_data.$key'] = value;
      });

      allUpdates['updatedAt'] = FieldValue.serverTimestamp();

      AppLogger.database('Final field updates: $allUpdates', tag: 'MANIFESTO_REPO');

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      AppLogger.database('Updating document at path: states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId', tag: 'MANIFESTO_REPO');

      // Check if document exists first, if not, create it (like basic_info does)
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('Document does not exist, creating new document', tag: 'MANIFESTO_REPO');
        await candidateRef.set({
          ...allUpdates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(allUpdates);
      }

      AppLogger.database('Manifesto fields updated successfully', tag: 'MANIFESTO_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating manifesto fields', tag: 'MANIFESTO_REPO', error: e);
      throw Exception('Failed to update manifesto fields: $e');
    }
  }

  @override
  Future<void> updateManifestoFast(Candidate candidate, Map<String, dynamic> updateData) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST UPDATE: Manifesto for $candidateId', tag: 'MANIFESTO_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'MANIFESTO_FAST');
      AppLogger.database('   Update data values: $updateData', tag: 'MANIFESTO_FAST');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      AppLogger.database('   Candidate location from object: state=$stateId, district=$districtId, body=$bodyId, ward=$wardId', tag: 'MANIFESTO_FAST');

      final candidatePath = 'states/$stateId/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/$candidateId';
      AppLogger.database('   Candidate document path: $candidatePath', tag: 'MANIFESTO_FAST');

      final candidateRef = _firestore
          .collection('states')
          .doc(stateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .doc(wardId)
          .collection('candidates')
          .doc(candidateId);

      // Check if candidate document exists first
      AppLogger.database('   Checking if candidate document exists...', tag: 'MANIFESTO_FAST');
      final candidateDoc = await candidateRef.get();
      final documentExists = candidateDoc.exists;

      AppLogger.database('   Candidate document exists: $documentExists', tag: 'MANIFESTO_FAST');

      if (!documentExists) {
        AppLogger.database('❌ CANDIDATE DOCUMENT NOT FOUND - Creating new document', tag: 'MANIFESTO_FAST');

        // Create the candidate document with the manifesto data
        final Map<String, dynamic> candidateData = {
          'candidateId': candidateId,
          'userId': candidateId, // Assuming candidateId is also userId
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'approved': false,
          'sponsored': false,
          ...updateData,
        };

        AppLogger.database('   Creating document with data: $candidateData', tag: 'MANIFESTO_FAST');
        await candidateRef.set(candidateData);

        AppLogger.database('✅ CANDIDATE DOCUMENT CREATED with manifesto data', tag: 'MANIFESTO_FAST');
        return;
      }

      // Document exists, update it
      AppLogger.database('   Document exists, proceeding with update', tag: 'MANIFESTO_FAST');

      // Ensure the data is properly structured for manifesto_data
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'manifesto_data') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            AppLogger.database('   Processing manifesto map with keys: ${value.keys.toList()}', tag: 'MANIFESTO_FAST');
            value.forEach((fieldKey, fieldValue) {
              structuredUpdateData['manifesto_data.$fieldKey'] = fieldValue;
            });
          } else {
            // If it's not a map, store it as-is (fallback)
            AppLogger.database('   Manifesto data is not a map, storing as-is', tag: 'MANIFESTO_FAST');
            structuredUpdateData[key] = value;
          }
        } else {
          // For other fields like updatedAt, keep them as-is
          structuredUpdateData[key] = value;
        }
      });

      AppLogger.database('   Final structured update data: $structuredUpdateData', tag: 'MANIFESTO_FAST');
      AppLogger.database('   Attempting Firestore update...', tag: 'MANIFESTO_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'MANIFESTO_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'MANIFESTO_FAST', error: e);
      AppLogger.databaseError('❌ Error details: ${e.toString()}', tag: 'MANIFESTO_FAST');
      AppLogger.databaseError('❌ Stack trace: ${StackTrace.current}', tag: 'MANIFESTO_FAST');
      throw Exception('Failed to fast update manifesto: $e');
    }
  }
}
