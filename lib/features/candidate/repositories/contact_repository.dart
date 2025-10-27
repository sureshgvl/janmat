import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../models/contact_model.dart';
import '../models/candidate_model.dart';

abstract class IContactRepository {
  Future<ContactModel?> getContact(Candidate candidate);
  Future<bool> updateContact(Candidate candidate, ContactModel contact);
  Future<bool> updateContactFields(Candidate candidate, Map<String, dynamic> updates);
  Future<void> updateContactFast(Candidate candidate, Map<String, dynamic> updateData);
}

class ContactRepository implements IContactRepository {
  final FirebaseFirestore _firestore;

  ContactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ContactModel?> getContact(Candidate candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Fetching contact for candidate: $candidateId', tag: 'CONTACT_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      // Get candidate document from hierarchical path - using states path to match other repos
      final candidateDoc = await _firestore
          .collection('states')
          .doc(stateId)
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
  Future<bool> updateContact(Candidate candidate, ContactModel contact) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating contact for candidate: $candidateId', tag: 'CONTACT_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final updates = {
        'extra_info.contact': contact.toJson(),
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
        await candidateRef.set({
          ...updates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(updates);
      }

      AppLogger.database('Contact updated successfully', tag: 'CONTACT_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating contact', tag: 'CONTACT_REPO', error: e);
      throw Exception('Failed to update contact: $e');
    }
  }

  @override
  Future<bool> updateContactFields(Candidate candidate, Map<String, dynamic> updates) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('Updating contact fields for candidate: $candidateId', tag: 'CONTACT_REPO');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

      final fieldUpdates = <String, dynamic>{};

      // Convert field names to dot notation for Firestore
      updates.forEach((key, value) {
        fieldUpdates['extra_info.contact.$key'] = value;
      });

      fieldUpdates['updatedAt'] = FieldValue.serverTimestamp();

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

      // Check if document exists first, like other repos do
      final docSnapshot = await candidateRef.get();
      if (!docSnapshot.exists) {
        AppLogger.database('Document does not exist, creating new document', tag: 'CONTACT_REPO');
        await candidateRef.set({
          ...fieldUpdates,
          'candidateId': candidateId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await candidateRef.update(fieldUpdates);
      }

      AppLogger.database('Contact fields updated successfully', tag: 'CONTACT_REPO');
      return true;
    } catch (e) {
      AppLogger.databaseError('Error updating contact fields', tag: 'CONTACT_REPO', error: e);
      throw Exception('Failed to update contact fields: $e');
    }
  }

  @override
  Future<void> updateContactFast(Candidate candidate, Map<String, dynamic> updateData) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST UPDATE: Contact for $candidateId', tag: 'CONTACT_FAST');
      AppLogger.database('   Update data keys: ${updateData.keys.toList()}', tag: 'CONTACT_FAST');

      // Get candidate location from candidate object
      final stateId = candidate.location.stateId ?? 'maharashtra';
      final districtId = candidate.location.districtId!;
      final bodyId = candidate.location.bodyId!;
      final wardId = candidate.location.wardId!;

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
      final candidateDoc = await candidateRef.get();
      final documentExists = candidateDoc.exists;

      AppLogger.database('   Candidate document exists: $documentExists', tag: 'CONTACT_FAST');

      if (!documentExists) {
        AppLogger.database('❌ CANDIDATE DOCUMENT NOT FOUND - Creating new document', tag: 'CONTACT_FAST');

        // Create the candidate document with the contact data
        final Map<String, dynamic> candidateData = {
          'candidateId': candidateId,
          'userId': candidate.candidateId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'approved': false,
          'sponsored': false,
          ...updateData,
        };

        AppLogger.database('   Creating document with data: $candidateData', tag: 'CONTACT_FAST');
        await candidateRef.set(candidateData);

        AppLogger.database('✅ CANDIDATE DOCUMENT CREATED with contact data', tag: 'CONTACT_FAST');
        return;
      }

      // Document exists, update it
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

      AppLogger.database('   Final structured update data: $structuredUpdateData', tag: 'CONTACT_FAST');

      await candidateRef.update(structuredUpdateData);

      AppLogger.database('✅ FAST UPDATE: Completed successfully', tag: 'CONTACT_FAST');
    } catch (e) {
      AppLogger.databaseError('❌ FAST UPDATE: Failed', tag: 'CONTACT_FAST', error: e);
      throw Exception('Failed to fast update contact: $e');
    }
  }
}
