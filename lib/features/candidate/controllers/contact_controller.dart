import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/contact_model.dart';
import '../models/candidate_model.dart';
import '../repositories/contact_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../notifications/services/constituency_notifications.dart';

abstract class IContactController {
  Future<ContactModel?> getContact(Candidate candidate);
  Future<bool> saveContact(Candidate candidate, ContactModel contact);
  Future<bool> updateContactFields(
    Candidate candidate,
    Map<String, dynamic> updates,
  );
  Future<bool> saveContactTab({
    required Candidate candidate,
    required ContactModel contact,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress,
  });
  Future<bool> saveContactFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress,
  });
  ContactModel getUpdatedCandidate(
    ContactModel current,
    String field,
    dynamic value,
  );
}

class ContactController extends GetxController implements IContactController {
  final IContactRepository _repository;

  ContactController({IContactRepository? repository})
    : _repository = repository ?? ContactRepository();

  @override
  Future<ContactModel?> getContact(Candidate candidate) async {
    try {
      AppLogger.database(
        'ContactController: Fetching contact for ${candidate.candidateId}',
        tag: 'CONTACT_CTRL',
      );
      return await _repository.getContact(candidate);
    } catch (e) {
      AppLogger.databaseError(
        'ContactController: Error fetching contact',
        tag: 'CONTACT_CTRL',
        error: e,
      );
      throw Exception('Failed to fetch contact: $e');
    }
  }

  @override
  Future<bool> saveContact(Candidate candidate, ContactModel contact) async {
    try {
      AppLogger.database(
        'ContactController: Saving contact for ${candidate.candidateId}',
        tag: 'CONTACT_CTRL',
      );
      return await _repository.updateContact(candidate, contact);
    } catch (e) {
      AppLogger.databaseError(
        'ContactController: Error saving contact',
        tag: 'CONTACT_CTRL',
        error: e,
      );
      throw Exception('Failed to save contact: $e');
    }
  }

  @override
  Future<bool> updateContactFields(
    Candidate candidate,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.database(
        'ContactController: Updating contact fields for ${candidate.candidateId}',
        tag: 'CONTACT_CTRL',
      );
      return await _repository.updateContactFields(candidate, updates);
    } catch (e) {
      AppLogger.databaseError(
        'ContactController: Error updating contact fields',
        tag: 'CONTACT_CTRL',
        error: e,
      );
      throw Exception('Failed to update contact fields: $e');
    }
  }

  @override
  ContactModel getUpdatedCandidate(
    ContactModel current,
    String field,
    dynamic value,
  ) {
    AppLogger.database(
      'ContactController: Updating field $field with value $value',
      tag: 'CONTACT_CTRL',
    );

    switch (field) {
      case 'phone':
        return current.copyWith(phone: value);
      case 'email':
        return current.copyWith(email: value);
      case 'address':
        return current.copyWith(address: value);
      case 'socialLinks':
        return current.copyWith(
          socialLinks: value is Map
              ? Map<String, String>.from(value)
              : current.socialLinks,
        );
      case 'officeAddress':
        return current.copyWith(officeAddress: value);
      case 'officeHours':
        return current.copyWith(officeHours: value);
      default:
        AppLogger.database(
          'ContactController: Unknown field $field, returning unchanged',
          tag: 'CONTACT_CTRL',
        );
        return current;
    }
  }

  void updateContact(dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateContactFields
    AppLogger.database(
      'ContactController: updateContact called with $value',
      tag: 'CONTACT_CTRL',
    );
    // Implementation will be handled by the calling controller
  }

  @override
  /// TAB-SPECIFIC SAVE: Direct contact tab save method
  /// Handles all contact operations for the tab independently
  Future<bool> saveContactTab({
    required Candidate candidate,
    required ContactModel contact,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress,
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database(
        '📞 TAB SAVE: Contact tab for $candidateId',
        tag: 'CONTACT_TAB',
      );

      onProgress?.call('Saving contact information...');

      // Direct save using the repository
      final success = await _repository.updateContact(candidate, contact);

      if (success) {
        onProgress?.call('Contact information saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        _runBackgroundSyncOperations(
          candidateId,
          candidateName,
          photoUrl,
          contact.toJson(),
        );

        AppLogger.database(
          '✅ TAB SAVE: Contact completed successfully',
          tag: 'CONTACT_TAB',
        );
        return true;
      } else {
        AppLogger.databaseError(
          '❌ TAB SAVE: Contact save failed',
          tag: 'CONTACT_TAB',
        );
        return false;
      }
    } catch (e) {
      AppLogger.databaseError(
        '❌ TAB SAVE: Contact tab save failed',
        tag: 'CONTACT_TAB',
        error: e,
      );
      return false;
    }
  }

  @override
  /// FAST SAVE: Direct contact update for simple field changes
  /// Main save is fast, but triggers essential background operations
  Future<bool> saveContactFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress,
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database(
        '🚀 FAST SAVE: Contact for $candidateId',
        tag: 'CONTACT_FAST',
      );

      // Direct Firestore update - NO batch operations, NO parallel ops
      final updateData = {
        'extra_info.contact': updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _repository.updateContactFast(candidate, updateData);

      // ✅ MAIN SAVE COMPLETE - UI can update immediately

      // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
      _runBackgroundSyncOperations(
        candidateId,
        candidateName,
        photoUrl,
        updates,
      );

      AppLogger.database(
        '✅ FAST SAVE: Completed successfully',
        tag: 'CONTACT_FAST',
      );
      return true;
    } catch (e) {
      AppLogger.databaseError(
        '❌ FAST SAVE: Failed',
        tag: 'CONTACT_FAST',
        error: e,
      );
      return false;
    }
  }

  /// BACKGROUND OPERATIONS: Essential sync operations that don't block UI
  void _runBackgroundSyncOperations(
    String candidateId,
    String? candidateName,
    String? photoUrl,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.database(
        '🔄 BACKGROUND: Starting essential sync operations',
        tag: 'CONTACT_FAST',
      );

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 1. Send contact update notification
      backgroundOperations.add(
        _sendContactUpdateNotification(candidateId, updates),
      );

      // 2. Update caches
      backgroundOperations.add(
        _updateCaches(candidateId, candidateName, photoUrl),
      );

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database(
        '✅ BACKGROUND: All sync operations completed',
        tag: 'CONTACT_FAST',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Some sync operations failed (non-critical)',
        tag: 'CONTACT_FAST',
        error: e,
      );
      // Don't throw - background operations shouldn't affect save success
    }
  }

  /// Send notification in background
  Future<void> _sendContactUpdateNotification(
    String candidateId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: 'contact',
        updateDescription: 'updated their contact information',
      );

      AppLogger.database(
        '🔔 BACKGROUND: Contact notification sent',
        tag: 'CONTACT_FAST',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Notification failed',
        tag: 'CONTACT_FAST',
        error: e,
      );
    }
  }

  /// Update caches in background
  Future<void> _updateCaches(
    String candidateId,
    String? candidateName,
    String? photoUrl,
  ) async {
    try {
      // Invalidate and update user cache
      final chatController = Get.find<ChatController>();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        chatController.invalidateUserCache(user.uid);
      }

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'CONTACT_FAST');
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Cache update failed',
        tag: 'CONTACT_FAST',
        error: e,
      );
    }
  }
}
