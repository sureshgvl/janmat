import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/manifesto_model.dart';
import '../repositories/manifesto_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

abstract class IManifestoController {
  Future<ManifestoModel?> getManifesto(String candidateId);
  Future<bool> saveManifesto(String candidateId, ManifestoModel manifesto);
  Future<bool> updateManifestoFields(String candidateId, Map<String, dynamic> updates);
  Future<bool> saveManifestoTab({required String candidateId, required ManifestoModel manifesto, String? candidateName, String? photoUrl, Function(String)? onProgress});
  ManifestoModel getUpdatedCandidate(ManifestoModel current, String field, dynamic value);
}

class ManifestoController extends GetxController implements IManifestoController {
  final IManifestoRepository _repository;

  ManifestoController({IManifestoRepository? repository})
      : _repository = repository ?? ManifestoRepository();

  @override
  Future<ManifestoModel?> getManifesto(String candidateId) async {
    try {
      AppLogger.database('ManifestoController: Fetching manifesto for $candidateId', tag: 'MANIFESTO_CTRL');
      return await _repository.getManifesto(candidateId);
    } catch (e) {
      AppLogger.databaseError('ManifestoController: Error fetching manifesto', tag: 'MANIFESTO_CTRL', error: e);
      throw Exception('Failed to fetch manifesto: $e');
    }
  }

  @override
  Future<bool> saveManifesto(String candidateId, ManifestoModel manifesto) async {
    try {
      AppLogger.database('ManifestoController: Saving manifesto for $candidateId', tag: 'MANIFESTO_CTRL');
      AppLogger.database('  Manifesto data: title=${manifesto.title}, promises=${manifesto.promises?.length ?? 0}', tag: 'MANIFESTO_CTRL');
      final result = await _repository.updateManifesto(candidateId, manifesto);
      AppLogger.database('ManifestoController: Manifesto saved successfully for $candidateId', tag: 'MANIFESTO_CTRL');
      return result;
    } catch (e) {
      AppLogger.databaseError('❌ ManifestoController: Error saving manifesto for $candidateId', tag: 'MANIFESTO_CTRL', error: e);
      AppLogger.databaseError('❌ Error details: ${e.toString()}', tag: 'MANIFESTO_CTRL');
      AppLogger.databaseError('❌ Stack trace: ${StackTrace.current}', tag: 'MANIFESTO_CTRL');
      throw Exception('Failed to save manifesto: $e');
    }
  }

  @override
  Future<bool> updateManifestoFields(String candidateId, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('ManifestoController: Updating manifesto fields for $candidateId', tag: 'MANIFESTO_CTRL');
      return await _repository.updateManifestoFields(candidateId, updates);
    } catch (e) {
      AppLogger.databaseError('ManifestoController: Error updating manifesto fields', tag: 'MANIFESTO_CTRL', error: e);
      throw Exception('Failed to update manifesto fields: $e');
    }
  }

  @override
  ManifestoModel getUpdatedCandidate(ManifestoModel current, String field, dynamic value) {
    AppLogger.database('ManifestoController: Updating field $field with value $value', tag: 'MANIFESTO_CTRL');

    switch (field) {
      case 'title':
        return current.copyWith(title: value);
      case 'promises':
        return current.copyWith(promises: value is List ? List<Map<String, dynamic>>.from(value) : [value]);
      case 'pdfUrl':
        return current.copyWith(pdfUrl: value);
      case 'image':
        return current.copyWith(image: value);
      case 'videoUrl':
        return current.copyWith(videoUrl: value);
      default:
        AppLogger.database('ManifestoController: Unknown field $field, returning unchanged', tag: 'MANIFESTO_CTRL');
        return current;
    }
  }

  void updateManifestoField(String field, dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateManifestoFields
    AppLogger.database('ManifestoController: updateManifestoField called with field=$field, value=$value', tag: 'MANIFESTO_CTRL');
    // Implementation will be handled by the calling controller
  }

  /// TAB-SPECIFIC SAVE: Direct manifesto tab save method
  /// Handles all manifesto operations for the tab independently
  Future<bool> saveManifestoTab({
    required String candidateId,
    required ManifestoModel manifesto,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.database('📝 TAB SAVE: Manifesto tab for $candidateId', tag: 'MANIFESTO_TAB');

      onProgress?.call('Saving manifesto...');

      // Direct save using the repository
      final success = await _repository.updateManifesto(candidateId, manifesto);

      if (success) {
        onProgress?.call('Manifesto saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        _runBackgroundSyncOperations(candidateId, candidateName, photoUrl, manifesto.toJson());

        AppLogger.database('✅ TAB SAVE: Manifesto completed successfully', tag: 'MANIFESTO_TAB');
        return true;
      } else {
        AppLogger.databaseError('❌ TAB SAVE: Manifesto save failed', tag: 'MANIFESTO_TAB');
        return false;
      }
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Manifesto tab save failed', tag: 'MANIFESTO_TAB', error: e);
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
      AppLogger.database('🔄 BACKGROUND: Starting essential sync operations', tag: 'MANIFESTO_FAST');

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 1. Update user document if name/photo changed
      if (candidateName != null || photoUrl != null) {
        backgroundOperations.add(_syncUserDocument(candidateName, photoUrl));
      }

      // 2. Send manifesto update notification
      backgroundOperations.add(_sendManifestoUpdateNotification(candidateId, updates));

      // 3. Update caches
      backgroundOperations.add(_updateCaches(candidateId, candidateName, photoUrl));

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All sync operations completed', tag: 'MANIFESTO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some sync operations failed (non-critical)', tag: 'MANIFESTO_FAST', error: e);
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

        AppLogger.database('📝 BACKGROUND: User document synced', tag: 'MANIFESTO_FAST');
      }
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: User document sync failed', tag: 'MANIFESTO_FAST', error: e);
    }
  }

  /// Send notification in background
  Future<void> _sendManifestoUpdateNotification(String candidateId, Map<String, dynamic> updates) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendManifestoUpdateNotification(
        candidateId: candidateId,
        updateType: 'update',
        manifestoTitle: updates['title'] ?? 'Manifesto',
        manifestoDescription: 'Updated manifesto content',
      );

      AppLogger.database('🔔 BACKGROUND: Manifesto notification sent', tag: 'MANIFESTO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Notification failed', tag: 'MANIFESTO_FAST', error: e);
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

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'MANIFESTO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Cache update failed', tag: 'MANIFESTO_FAST', error: e);
    }
  }
}
