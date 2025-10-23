import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/contact_model.dart';

abstract class IContactRepository {
  Future<ContactModel?> getContact(String candidateId);
  Future<bool> updateContact(String candidateId, ContactModel contact);
  Future<bool> updateContactFields(String candidateId, Map<String, dynamic> updates);
  Future<void> updateContactFast(String candidateId, Map<String, dynamic> updateData);
}

class ContactRepository implements IContactRepository {
  final FirebaseFirestore _firestore;

  ContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ContactModel?> getContact(String candidateId) async {
    try {
      AppLogger.database('Fetching contact for candidate: $candidateId', tag: 'CONTACT_REPO');

      // Get candidate location from index first
      final indexDoc = await _firestore.collection('candidate_index').doc(candidateId).get();

      if (!indexDoc.exists) {
        AppLogger.database('Candidate index not found: $candidateId', tag: 'CONTACT_REPO');
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
        AppLogger.database('Candidate document not found: $candidateId', tag: 'CONTACT_REPO');
        return null;
      }

      final data = candidateDoc.data()!;
      final extraInfo = data['extra_info'] as Map<String, dynamic>?;

      if (extraInfo == null || !extraInfo.containsKey('contact')) {
        AppLogger.database('No contact found in candidate document', tag: 'CONTACT_REPO');
        return null;
      }

      final contactData = extraInfo['contact'] as Map<String, dynamic>;
      return ContactModel.fromJson(contactData);
    } catch (e) {
      AppLogger.databaseError('Error fetching contact', tag: 'CONTACT_REPO', error: e);
      throw Exception('Failed to fetch contact: $e');
    }
  }

  @override
  Future<bool> updateContact(String candidateId, ContactModel contact) async {
    try {
      AppLogger.database('Updating contact for candidate: $candidateId', tag: 'CONTACT_REPO');

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
        'extra_info.contact': contact.toJson(),
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

      AppLogger.database('Contact updated successfully', tag: 'CONTACT_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating contact', tag: 'CONTACT_REPO', error: e);
      throw Exception('Failed to update contact: $e');
    }
  }

  @override
  Future<bool> updateContactFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('Updating contact fields for candidate: $candidateId', tag: 'CONTACT_REPO');

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
        fieldUpdates['extra_info.contact.$key'] = value;
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

      AppLogger.database('Contact fields updated successfully', tag: 'CONTACT_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating contact fields', tag: 'CONTACT_REPO', error: e);
      throw Exception('Failed to update contact fields: $e');
    }
  }

  @override
  Future<void> updateContactFast(String candidateId, Map<String, dynamic> updateData) async {
    try {
      AppLogger.database('🚀 FAST UPDATE: Contact for $candidateId', tag: 'CONTACT_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'CONTACT_FAST');

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

      // Ensure the data is properly structured for extra_info.contact
      final structuredUpdateData = <String, dynamic>{};

      updateData.forEach((key, value) {
        if (key == 'extra_info.contact') {
          // If it's already structured as a map, merge each field
          if (value is Map<String, dynamic>) {
            value.forEach((fieldKey, fieldValue) {
              structuredUpdateData['extra_info.contact.$fieldKey'] = fieldValue;
            });
          } else {
            // If it's not a map, store it as-is (fallback)
            structuredUpdateData[key] = value;
          }
        } else {
          // For other fields like updatedAt, keep them as-is
          structuredUpdateData[key] = value;
        }
      });

      AppLogger.database('   Structured update data: $structuredUpdateData', tag: 'CONTACT_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'CONTACT_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'CONTACT_FAST', error: e);
      throw Exception('Failed to fast update contact: $e');
    }
  }
}
