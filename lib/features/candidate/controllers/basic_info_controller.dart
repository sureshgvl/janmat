import 'dart:io';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../utils/app_logger.dart';
import '../models/basic_info_model.dart';
import '../repositories/basic_info_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../../../services/notifications/constituency_notifications.dart';
import '../widgets/edit/basic_info/photo_upload_handler.dart';

abstract class IBasicInfoController {
  Future<BasicInfoModel?> getBasicInfo(dynamic candidate); // Accept candidate object
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
  Future<BasicInfoModel?> getBasicInfo(dynamic candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database('BasicInfoController: Fetching basic info for $candidateId', tag: 'BASIC_INFO_CTRL');
      return await _repository.getBasicInfo(candidate);
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

      // DEBUG: Check languages field specifically
      AppLogger.database('📝 TAB SAVE: Languages debug - type: ${basicInfo.languages?.runtimeType}, value: ${basicInfo.languages}', tag: 'BASIC_INFO_TAB');
      if (basicInfo.languages != null && basicInfo.languages!.isNotEmpty) {
        AppLogger.database('📝 TAB SAVE: First language type: ${basicInfo.languages!.first.runtimeType}', tag: 'BASIC_INFO_TAB');
      }

      AppLogger.database('📝 TAB SAVE: BasicInfo data: ${basicInfo.toJson()}', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: Candidate location: districtId=${candidate.location.districtId}, bodyId=${candidate.location.bodyId}, wardId=${candidate.location.wardId}', tag: 'BASIC_INFO_TAB');

      onProgress?.call('Saving basic info...');

      // Check if photo needs to be uploaded
      String? finalPhotoUrl = basicInfo.photo;
      List<String> updatedDeleteStorage = List<String>.from(candidate.deleteStorage ?? []);

      if (basicInfo.photo != null && basicInfo.photo!.startsWith('local:')) {
        AppLogger.database('📸 PHOTO UPLOAD: Detected local photo, uploading to Firebase...', tag: 'BASIC_INFO_TAB');
        onProgress?.call('Uploading profile photo...');

        // Extract local file path
        final localFilePath = basicInfo.photo!.substring(6);
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        try {
          // Upload directly using Firebase Storage (avoid PhotoUploadHandler's UI dependencies)
          final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/$userId/$fileName');
          final uploadTask = storageRef.putFile(
            File(localFilePath),
            SettableMetadata(contentType: 'image/jpeg'),
          );

          final snapshot = await uploadTask.whenComplete(() {});
          final uploadedUrl = await snapshot.ref.getDownloadURL();

          finalPhotoUrl = uploadedUrl;
          AppLogger.database('📸 PHOTO UPLOAD: Success! URL: $uploadedUrl', tag: 'BASIC_INFO_TAB');

          // Add old photo to deleteStorage if it exists
          if (candidate.photo != null && candidate.photo!.isNotEmpty) {
            updatedDeleteStorage.add(candidate.photo!);
            AppLogger.database('🗑️ DELETE STORAGE: Added old photo to deletion list: ${candidate.photo}', tag: 'BASIC_INFO_TAB');
          }
        } catch (e) {
          AppLogger.databaseError('❌ PHOTO UPLOAD: Failed to upload photo', tag: 'BASIC_INFO_TAB', error: e);
          // Continue with save but keep original photo
          finalPhotoUrl = candidate.photo;
        }
      }

      // Create updated basicInfo with final photo URL
      final updatedBasicInfo = basicInfo.copyWith(photo: finalPhotoUrl);

      // DEBUG: Check candidate fields
      AppLogger.database('📝 TAB SAVE: Candidate debug - candidate.photo: ${candidate.photo}', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: Candidate debug - deleteStorage (original): ${candidate.deleteStorage}', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: Candidate debug - deleteStorage (updated): $updatedDeleteStorage', tag: 'BASIC_INFO_TAB');
      AppLogger.database('📝 TAB SAVE: Candidate debug - deleteStorage types: ${updatedDeleteStorage.map((s) => s.runtimeType)}', tag: 'BASIC_INFO_TAB');

      // Create updated candidate with deleteStorage changes
      final updatedCandidate = candidate.copyWith(deleteStorage: updatedDeleteStorage);

      // Direct save using the repository with updated candidate object
      final success = await _repository.updateBasicInfoWithCandidate(candidateId, updatedBasicInfo, updatedCandidate);
      AppLogger.database('📝 TAB SAVE: Repository result: $success', tag: 'BASIC_INFO_TAB');

      if (success) {
        onProgress?.call('Basic info saved successfully!');

        // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block UI)
        _runBackgroundSyncOperations(candidateId, updatedBasicInfo.fullName, updatedBasicInfo.photo, updatedBasicInfo.toJson());

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
