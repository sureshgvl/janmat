import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/media_model.dart';
import '../repositories/media_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

abstract class IMediaController {
  Future<List<Media>?> getMedia(String candidateId);
  Future<bool> saveMedia(String candidateId, List<Media> media);
  Future<bool> updateMediaFields(String candidateId, Map<String, dynamic> updates);
  Future<bool> saveMediaTab({required String candidateId, required List<Media> media, String? candidateName, String? photoUrl, Function(String)? onProgress});
  Future<bool> saveMediaFast(String candidateId, Map<String, dynamic> updates, {String? candidateName, String? photoUrl, Function(String)? onProgress});
  List<Media> getUpdatedMedia(List<Media> current, String field, dynamic value);
}

class MediaController extends GetxController implements IMediaController {
  final IMediaRepository _repository;

  MediaController({IMediaRepository? repository})
      : _repository = repository ?? MediaRepository();

  @override
  Future<List<Media>?> getMedia(String candidateId) async {
    try {
      AppLogger.database('MediaController: Fetching media for $candidateId', tag: 'MEDIA_CTRL');
      return await _repository.getMedia(candidateId);
    } catch (e) {
      AppLogger.databaseError('MediaController: Error fetching media', tag: 'MEDIA_CTRL', error: e);
      throw Exception('Failed to fetch media: $e');
    }
  }

  @override
  Future<bool> saveMedia(String candidateId, List<Media> media) async {
    try {
      AppLogger.database('MediaController: Saving media for $candidateId', tag: 'MEDIA_CTRL');
      return await _repository.updateMedia(candidateId, media);
    } catch (e) {
      AppLogger.databaseError('MediaController: Error saving media', tag: 'MEDIA_CTRL', error: e);
      throw Exception('Failed to save media: $e');
    }
  }

  @override
  Future<bool> updateMediaFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('MediaController: Updating media fields for $candidateId', tag: 'MEDIA_CTRL');
      return await _repository.updateMediaFields(candidateId, updates);
    } catch (e) {
      AppLogger.databaseError('MediaController: Error updating media fields', tag: 'MEDIA_CTRL', error: e);
      throw Exception('Failed to update media fields: $e');
    }
  }

  @override
  List<Media> getUpdatedMedia(List<Media> current, String field, dynamic value) {
    AppLogger.database('MediaController: Updating field $field with value $value', tag: 'MEDIA_CTRL');

    switch (field) {
      case 'add':
        if (value is Media) {
          return [...current, value];
        }
        return current;
      case 'remove':
        if (value is int && value >= 0 && value < current.length) {
          final updated = List<Media>.from(current);
          updated.removeAt(value);
          return updated;
        }
        return current;
      case 'update':
        if (value is Map<String, dynamic> &&
            value.containsKey('index') &&
            value.containsKey('media') &&
            value['index'] is int &&
            value['media'] is Media) {
          final index = value['index'] as int;
          final media = value['media'] as Media;
          if (index >= 0 && index < current.length) {
            final updated = List<Media>.from(current);
            updated[index] = media;
            return updated;
          }
        }
        return current;
      default:
        AppLogger.database('MediaController: Unknown field $field, returning unchanged', tag: 'MEDIA_CTRL');
        return current;
    }
  }

  void updateMedia(dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateMediaFields
    AppLogger.database('MediaController: updateMedia called with $value', tag: 'MEDIA_CTRL');
    // Implementation will be handled by the calling controller
  }

  /// TAB-SPECIFIC SAVE: Direct media tab save method
  /// Handles all media operations for the tab independently
  Future<bool> saveMediaTab({
    required String candidateId,
    required List<Media> media,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.database('🎬 TAB SAVE: Media tab for $candidateId', tag: 'MEDIA_TAB');

      onProgress?.call('Saving media...');

      // Save using the repository
      final success = await _repository.updateMedia(candidateId, media);

      if (success) {
        onProgress?.call('Media saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        _runBackgroundSyncOperations(candidateId, candidateName, photoUrl, {'media': media.map((m) => m.toJson()).toList()});

        AppLogger.database('✅ TAB SAVE: Media completed successfully', tag: 'MEDIA_TAB');
        return true;
      } else {
        AppLogger.databaseError('❌ TAB SAVE: Media save failed', tag: 'MEDIA_TAB');
        return false;
      }
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Media tab save failed', tag: 'MEDIA_TAB', error: e);
      return false;
    }
  }

  /// FAST SAVE: Direct media update for simple field changes
  /// Main save is fast, but triggers essential background operations
  Future<bool> saveMediaFast(
    String candidateId,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.database('🚀 FAST SAVE: Media for $candidateId', tag: 'MEDIA_FAST');

      // Direct Firestore update - NO batch operations, NO parallel ops
      final updateData = {
        'media': updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _repository.updateMediaFast(candidateId, updateData);

      // ✅ MAIN SAVE COMPLETE - UI can update immediately

      // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
      _runBackgroundSyncOperations(candidateId, candidateName, photoUrl, updates);

      AppLogger.database('✅ FAST SAVE: Completed successfully', tag: 'MEDIA_FAST');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ FAST SAVE: Failed', tag: 'MEDIA_FAST', error: e);
      return false;
    }
  }

  /// BACKGROUND OPERATIONS: Essential sync operations that don't block UI
  void _runBackgroundSyncOperations(
    String candidateId,
    String? candidateName,
    String? photoUrl,
    Map<String, dynamic> updates
  ) async {
    try {
      AppLogger.database('🔄 BACKGROUND: Starting essential sync operations', tag: 'MEDIA_FAST');

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 1. Update user document if name/photo changed
      if (candidateName != null || photoUrl != null) {
        backgroundOperations.add(_syncUserDocument(candidateName, photoUrl));
      }

      // 2. Send media update notification
      backgroundOperations.add(_sendMediaUpdateNotification(candidateId, updates));

      // 3. Update caches
      backgroundOperations.add(_updateCaches(candidateId, candidateName, photoUrl));

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All sync operations completed', tag: 'MEDIA_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some sync operations failed (non-critical)', tag: 'MEDIA_FAST', error: e);
      // Don't throw - background operations shouldn't affect save success
    }
  }

  /// Sync user document in background
  Future<void> _syncUserDocument(String? candidateName, String? photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> userUpdates = {};

      if (candidateName != null) {
        userUpdates['name'] = candidateName;
      }

      if (photoUrl != null) {
        userUpdates['photo'] = photoUrl;
      }

      if (userUpdates.isNotEmpty) {
        await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(userUpdates);

        AppLogger.database('📝 BACKGROUND: User document synced', tag: 'MEDIA_FAST');
      }
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: User document sync failed', tag: 'MEDIA_FAST', error: e);
    }
  }

  /// Send notification in background
  Future<void> _sendMediaUpdateNotification(String candidateId, Map<String, dynamic> updates) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: 'media',
        updateDescription: 'updated their media gallery',
      );

      AppLogger.database('🔔 BACKGROUND: Media notification sent', tag: 'MEDIA_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Notification failed', tag: 'MEDIA_FAST', error: e);
    }
  }

  /// Update caches in background
  Future<void> _updateCaches(String candidateId, String? candidateName, String? photoUrl) async {
    try {
      // Invalidate and update user cache
      final chatController = Get.find<ChatController>();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        chatController.invalidateUserCache(user.uid);
      }

      // Update UserCacheService
      final userCacheService = UserCacheService();
      await userCacheService.updateCachedUserData({
        'uid': user?.uid ?? '',
        'name': candidateName,
        'photoURL': photoUrl,
      });

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'MEDIA_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Cache update failed', tag: 'MEDIA_FAST', error: e);
    }
  }
}
