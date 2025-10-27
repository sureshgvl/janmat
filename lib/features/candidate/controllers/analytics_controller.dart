import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/analytics_model.dart';
import '../models/candidate_model.dart';
import '../repositories/analytics_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

abstract class IAnalyticsController {
  Future<AnalyticsModel?> getAnalytics(Candidate candidate);
  Future<bool> saveAnalytics(Candidate candidate, AnalyticsModel analytics);
  Future<bool> updateAnalyticsFields(Candidate candidate, Map<String, dynamic> updates);
  Future<bool> saveAnalyticsFast(Candidate candidate, Map<String, dynamic> updates, {String? candidateName, String? photoUrl, Function(String)? onProgress});
  AnalyticsModel getUpdatedCandidate(AnalyticsModel current, String field, dynamic value);
}

class AnalyticsController extends GetxController implements IAnalyticsController {
  final IAnalyticsRepository _repository;

  AnalyticsController({IAnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository();

  @override
  Future<AnalyticsModel?> getAnalytics(Candidate candidate) async {
    try {
      AppLogger.database('AnalyticsController: Fetching analytics for ${candidate.candidateId}', tag: 'ANALYTICS_CTRL');
      return await _repository.getAnalytics(candidate);
    } catch (e) {
      AppLogger.databaseError('AnalyticsController: Error fetching analytics', tag: 'ANALYTICS_CTRL', error: e);
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  @override
  Future<bool> saveAnalytics(Candidate candidate, AnalyticsModel analytics) async {
    try {
      AppLogger.database('AnalyticsController: Saving analytics for ${candidate.candidateId}', tag: 'ANALYTICS_CTRL');
      return await _repository.updateAnalytics(candidate, analytics);
    } catch (e) {
      AppLogger.databaseError('AnalyticsController: Error saving analytics', tag: 'ANALYTICS_CTRL', error: e);
      throw Exception('Failed to save analytics: $e');
    }
  }

  @override
  Future<bool> updateAnalyticsFields(Candidate candidate, Map<String, dynamic> updates) async {
    try {
      AppLogger.database('AnalyticsController: Updating analytics fields for ${candidate.candidateId}', tag: 'ANALYTICS_CTRL');
      return await _repository.updateAnalyticsFields(candidate, updates);
    } catch (e) {
      AppLogger.databaseError('AnalyticsController: Error updating analytics fields', tag: 'ANALYTICS_CTRL', error: e);
      throw Exception('Failed to update analytics fields: $e');
    }
  }

  @override
  AnalyticsModel getUpdatedCandidate(AnalyticsModel current, String field, dynamic value) {
    AppLogger.database('AnalyticsController: Updating field $field with value $value', tag: 'ANALYTICS_CTRL');

    switch (field) {
      case 'profileViews':
        return current.copyWith(profileViews: value);
      case 'manifestoViews':
        return current.copyWith(manifestoViews: value);
      case 'contactClicks':
        return current.copyWith(contactClicks: value);
      case 'socialMediaClicks':
        return current.copyWith(socialMediaClicks: value);
      case 'locationViews':
        return current.copyWith(locationViews: value is Map ? Map<String, int>.from(value) : current.locationViews);
      case 'lastUpdated':
        return current.copyWith(lastUpdated: value);
      default:
        AppLogger.database('AnalyticsController: Unknown field $field, returning unchanged', tag: 'ANALYTICS_CTRL');
        return current;
    }
  }

  void updateAnalytics(dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateAnalyticsFields
    AppLogger.database('AnalyticsController: updateAnalytics called with $value', tag: 'ANALYTICS_CTRL');
    // Implementation will be handled by the calling controller
  }

  /// FAST SAVE: Direct analytics update for simple field changes
  /// Main save is fast, but triggers essential background operations
  @override
  Future<bool> saveAnalyticsFast(
    Candidate candidate,
    Map<String, dynamic> updates, {
    String? candidateName,
    String? photoUrl,
    Function(String)? onProgress
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('🚀 FAST SAVE: Analytics for $candidateId', tag: 'ANALYTICS_FAST');

      // Direct Firestore update - NO batch operations, NO parallel ops
      final updateData = {
        'analytics': updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _repository.updateAnalyticsFast(candidate, updateData);

      // ✅ MAIN SAVE COMPLETE - UI can update immediately

      // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
      _runBackgroundSyncOperations(candidateId, candidateName, photoUrl, updates);

      AppLogger.database('✅ FAST SAVE: Completed successfully', tag: 'ANALYTICS_FAST');
      return true;
    } catch (e) {
      AppLogger.databaseError('❌ FAST SAVE: Failed', tag: 'ANALYTICS_FAST', error: e);
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
      AppLogger.database('🔄 BACKGROUND: Starting essential sync operations', tag: 'ANALYTICS_FAST');

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 1. Update user document if name/photo changed
      if (candidateName != null || photoUrl != null) {
        backgroundOperations.add(_syncUserDocument(candidateName, photoUrl));
      }

      // 2. Send analytics update notification
      backgroundOperations.add(_sendAnalyticsUpdateNotification(candidateId, updates));

      // 3. Update caches
      backgroundOperations.add(_updateCaches(candidateId, candidateName, photoUrl));

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All sync operations completed', tag: 'ANALYTICS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some sync operations failed (non-critical)', tag: 'ANALYTICS_FAST', error: e);
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

        AppLogger.database('📝 BACKGROUND: User document synced', tag: 'ANALYTICS_FAST');
      }
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: User document sync failed', tag: 'ANALYTICS_FAST', error: e);
    }
  }

  /// Send notification in background
  Future<void> _sendAnalyticsUpdateNotification(String candidateId, Map<String, dynamic> updates) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: 'analytics',
        updateDescription: 'updated their analytics data',
      );

      AppLogger.database('🔔 BACKGROUND: Analytics notification sent', tag: 'ANALYTICS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Notification failed', tag: 'ANALYTICS_FAST', error: e);
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

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'ANALYTICS_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Cache update failed', tag: 'ANALYTICS_FAST', error: e);
    }
  }
}
