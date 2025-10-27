import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/achievements_model.dart';
import '../models/candidate_model.dart';
import '../repositories/achievements_repository.dart';
import '../repositories/candidate_operations.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

abstract class IAchievementsController {
  Future<AchievementsModel?> getAchievements(Candidate candidate);
  Future<bool> saveAchievements(Candidate candidate, AchievementsModel achievements);
  Future<bool> updateAchievementsFields(Candidate candidate, Map<String, dynamic> updates);
  Future<bool> saveAchievementsTab({required Candidate candidate, required AchievementsModel achievements, String? candidateName, String? photoUrl, Function(String)? onProgress});
  Future<bool> saveAchievementsFast(Candidate candidate, Map<String, dynamic> updates, {String? candidateName, String? photoUrl, Function(String)? onProgress});
  AchievementsModel getUpdatedCandidate(AchievementsModel current, String field, dynamic value);
}

class AchievementsController extends GetxController implements IAchievementsController {
  final IAchievementsRepository _repository;

  AchievementsController({IAchievementsRepository? repository})
      : _repository = repository ?? AchievementsRepository();

  @override
  Future<AchievementsModel?> getAchievements(Candidate candidate) async {
    try {
      AppLogger.database('AchievementsController: Fetching achievements for ${candidate.candidateId}', tag: 'ACHIEVEMENTS_CTRL');
      return await _repository.getAchievements(candidate);
    } catch (e) {
      AppLogger.databaseError('AchievementsController: Error fetching achievements', tag: 'ACHIEVEMENTS_CTRL', error: e);
      throw Exception('Failed to fetch achievements: $e');
    }
  }

  @override
  Future<bool> saveAchievements(Candidate candidate, AchievementsModel achievements) async {
    try {
      AppLogger.database('AchievementsController: Saving achievements for ${candidate.candidateId}', tag: 'ACHIEVEMENTS_CTRL');
      return await _repository.updateAchievements(candidate.candidateId, achievements, candidate);
    } catch (e) {
      AppLogger.databaseError('AchievementsController: Error saving achievements', tag: 'ACHIEVEMENTS_CTRL', error: e);
      throw Exception('Failed to save achievements: $e');
    }
  }

  @override
  Future<bool> updateAchievementsFields(Candidate candidate, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('AchievementsController: Updating achievements fields for ${candidate.candidateId}', tag: 'ACHIEVEMENTS_CTRL');
      return await _repository.updateAchievementsFields(candidate, updates);
    } catch (e) {
      AppLogger.databaseError('AchievementsController: Error updating achievements fields', tag: 'ACHIEVEMENTS_CTRL', error: e);
      throw Exception('Failed to update achievements fields: $e');
    }
  }

  @override
  AchievementsModel getUpdatedCandidate(AchievementsModel current, String field, dynamic value) {
    AppLogger.database('AchievementsController: Updating field $field with value $value', tag: 'ACHIEVEMENTS_CTRL');

    switch (field) {
      case 'achievements':
        return current.copyWith(achievements: value is List ? List<Achievement>.from(value.map((a) => a is Achievement ? a : Achievement.fromJson(a))) : current.achievements);
      default:
        AppLogger.database('AchievementsController: Unknown field $field, returning unchanged', tag: 'ACHIEVEMENTS_CTRL');
        return current;
    }
  }

  /// TAB-SPECIFIC SAVE: Direct achievements tab save method
  /// Handles all achievements operations for the tab independently
  @override
  Future<bool> saveAchievementsTab({
    required Candidate candidate,
    required AchievementsModel achievements,
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🏆 TAB SAVE: Achievements tab for $candidateId', tag: 'ACHIEVEMENTS_TAB');

      onProgress?.call('Saving achievements...');

      // Direct save using the repository
      final success = await _repository.updateAchievements(candidateId, achievements, candidate);

      if (success) {
        onProgress?.call('Achievements saved successfully!');

        AppLogger.database('✅ TAB SAVE: Achievements completed successfully', tag: 'ACHIEVEMENTS_TAB');
        return true;
      } else {
        AppLogger.databaseError('❌ TAB SAVE: Achievements save failed', tag: 'ACHIEVEMENTS_TAB');
        return false;
      }
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Achievements tab save failed', tag: 'ACHIEVEMENTS_TAB', error: e);
      return false;
    }
  }

  @override
  /// FAST SAVE: Direct achievements update for simple field changes
  /// Main save is fast, but triggers essential background operations
  Future<bool> saveAchievementsFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST SAVE: Achievements for $candidateId', tag: 'ACHIEVEMENTS_FAST');

      // Direct Firestore update - NO batch operations, NO parallel ops
      final updateData = {
        'achievements': updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _repository.updateAchievementsFast(candidate, updateData);

      // ✅ MAIN SAVE COMPLETE - UI can update immediately

      // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
      _runBackgroundSyncOperations(candidateId, candidateName, photoUrl, updates);

      AppLogger.database('✅ FAST SAVE: Completed successfully', tag: 'ACHIEVEMENTS_FAST');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ FAST SAVE: Failed', tag: 'ACHIEVEMENTS_FAST', error: e);
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
      AppLogger.database('🔄 BACKGROUND: Starting essential sync operations', tag: 'ACHIEVEMENTS_FAST');

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

// 1. Update user document if name/photo changed
      if (candidateName != null || photoUrl != null) {
        backgroundOperations.add(_syncUserDocument(candidateName, photoUrl));
      }

// 2. Send achievements update notification
      backgroundOperations.add(_sendAchievementsUpdateNotification(candidateId, updates));

// 3. Update caches
      backgroundOperations.add(_updateCaches(candidateId, candidateName, photoUrl));

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All sync operations completed', tag: 'ACHIEVEMENTS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some sync operations failed (non-critical)', tag: 'ACHIEVEMENTS_FAST', error: e);
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

        AppLogger.database('📝 BACKGROUND: User document synced', tag: 'ACHIEVEMENTS_FAST');
      }
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: User document sync failed', tag: 'ACHIEVEMENTS_FAST', error: e);
    }
  }

  /// Send notification in background
  Future<void> _sendAchievementsUpdateNotification(String candidateId, Map<String, dynamic> updates) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: 'achievements',
        updateDescription: 'updated their achievements',
      );

      AppLogger.database('🔔 BACKGROUND: Achievements notification sent', tag: 'ACHIEVEMENTS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Notification failed', tag: 'ACHIEVEMENTS_FAST', error: e);
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

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'ACHIEVEMENTS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Cache update failed', tag: 'ACHIEVEMENTS_FAST', error: e);
    }
  }
}
