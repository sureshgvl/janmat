import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/app_logger.dart';
import '../models/basic_info_model.dart';
import '../repositories/basic_info_repository.dart';
import 'base_tab_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';

abstract class IBasicInfoController {
  Future<BasicInfoModel?> getBasicInfo(String candidateId);
  Future<bool> saveBasicInfoTabWithCandidate({
    required String candidateId,
    required BasicInfoModel basicInfo,
    required dynamic candidate,
    Function(String)? onProgress
  });
  // Removed updateBasicInfoFields method - no longer needed
  BasicInfoModel getUpdatedCandidate(BasicInfoModel current, String field, dynamic value);
}

class BasicInfoController extends GetxController implements IBasicInfoController {
  final IBasicInfoRepository _repository;

  BasicInfoController({IBasicInfoRepository? repository})
      : _repository = repository ?? BasicInfoRepository();

  @override
  Future<BasicInfoModel?> getBasicInfo(String candidateId) async {
    try {
      AppLogger.database('BasicInfoController: Fetching basic info for $candidateId', tag: 'BASIC_INFO_CTRL');
      return await _repository.getBasicInfo(candidateId);
    } catch (e) {
      AppLogger.databaseError('BasicInfoController: Error fetching basic info', tag: 'BASIC_INFO_CTRL', error: e);
      throw Exception('Failed to fetch basic info: $e');
    }
  }
  
  @override
  Future<bool> saveBasicInfoTabWithCandidate({
    required String candidateId,
    required BasicInfoModel basicInfo,
    required dynamic candidate,
    Function(String)? onProgress
  }) async {
    try {
      AppLogger.database('📝 TAB SAVE: Basic info tab with candidate for $candidateId', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: BasicInfo data: ${basicInfo.toJson()}', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: Candidate location: districtId=${candidate.location.districtId}, bodyId=${candidate.location.bodyId}, wardId=${candidate.location.wardId}', tag: 'BASIC_INFO_TAB');

      onProgress?.call('Saving basic info...');

      // Direct save using the repository with candidate object
      final success = await _repository.updateBasicInfoWithCandidate(candidateId, basicInfo, candidate);
      AppLogger.database('📝 TAB SAVE: Repository result: $success', tag: 'BASIC_INFO_TAB');

      if (success) {
        onProgress?.call('Basic info saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        _runBackgroundSyncOperations(candidateId, candidate.basicInfo?.fullName, candidate.basicInfo?.photo, basicInfo.toJson());

        AppLogger.database('✅ TAB SAVE: Basic info completed successfully', tag: 'BASIC_INFO_TAB');
        return true;
      } else {
        AppLogger.databaseError('❌ TAB SAVE: Basic info save failed', tag: 'BASIC_INFO_TAB');
        return false;
      }
    } catch (e) {
      AppLogger.databaseError('❌ TAB SAVE: Basic info tab save failed', tag: 'BASIC_INFO_TAB', error: e);
      return false;
    }
  }

  @override
  BasicInfoModel getUpdatedCandidate(BasicInfoModel current, String field, dynamic value) {
    AppLogger.database('BasicInfoController: Updating field $field with value $value', tag: 'BASIC_INFO_CTRL');

    switch (field) {
      case 'fullName':
        return current.copyWith(fullName: value);
      case 'dateOfBirth':
        return current.copyWith(dateOfBirth: value is String ? DateTime.tryParse(value) : value);
      case 'age':
        return current.copyWith(age: value is int ? value : int.tryParse(value.toString()));
      case 'gender':
        return current.copyWith(gender: value);
      case 'education':
        return current.copyWith(education: value);
      case 'profession':
        return current.copyWith(profession: value);
      case 'languages':
        return current.copyWith(languages: value is List ? List<String>.from(value) : [value.toString()]);
      case 'experienceYears':
        return current.copyWith(experienceYears: value is int ? value : int.tryParse(value.toString()));
      case 'previousPositions':
        return current.copyWith(previousPositions: value is List ? List<String>.from(value) : [value.toString()]);
      case 'photo':
        return current.copyWith(photo: value);
      default:
        AppLogger.database('BasicInfoController: Unknown field $field, returning unchanged', tag: 'BASIC_INFO_CTRL');
        return current;
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
      AppLogger.database('🔄 BACKGROUND: Starting essential sync operations', tag: 'BASIC_INFO_FAST');

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 1. Update user document if name/photo changed
      if (candidateName != null || photoUrl != null) {
        backgroundOperations.add(_syncUserDocument(candidateName, photoUrl));
      }

      // 2. Send profile update notification
      backgroundOperations.add(_sendProfileUpdateNotification(candidateId, updates));

      // 3. Update caches
      backgroundOperations.add(_updateCaches(candidateId, candidateName, photoUrl));

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All sync operations completed', tag: 'BASIC_INFO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some sync operations failed (non-critical)', tag: 'BASIC_INFO_FAST', error: e);
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

        AppLogger.database('📝 BACKGROUND: User document synced', tag: 'BASIC_INFO_FAST');
      }
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: User document sync failed', tag: 'BASIC_INFO_FAST', error: e);
    }
  }

  /// Send notification in background
  Future<void> _sendProfileUpdateNotification(String candidateId, Map<String, dynamic> updates) async {
    try {
      // Determine notification type based on what changed
      String updateType = 'profile';
      String updateDescription = 'updated their profile';

      if (updates.containsKey('profession')) {
        updateType = 'profession';
        updateDescription = 'updated their profession';
      } else if (updates.containsKey('education')) {
        updateType = 'education';
        updateDescription = 'updated their education details';
      }

      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendProfileUpdateNotification(
        candidateId: candidateId,
        updateType: updateType,
        updateDescription: updateDescription,
      );

      AppLogger.database('🔔 BACKGROUND: Notification sent', tag: 'BASIC_INFO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Notification failed', tag: 'BASIC_INFO_FAST', error: e);
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

      AppLogger.database('💾 BACKGROUND: Caches updated', tag: 'BASIC_INFO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Cache update failed', tag: 'BASIC_INFO_FAST', error: e);
    }
  }
}
