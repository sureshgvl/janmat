import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../../utils/app_logger.dart';
import '../../../services/sync/i_sync_service.dart';
import '../controllers/candidate_user_controller.dart';
import '../models/basic_info_model.dart';
import '../repositories/basic_info_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../../features/user/services/user_cache_service.dart';
import '../../notifications/services/constituency_notifications.dart';

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
          final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/$userId/$fileName');

          UploadTask uploadTask;

          if (kIsWeb && localFilePath.startsWith('blob:')) {
            // Web: Download blob data and upload as bytes
            AppLogger.database('🌐 WEB UPLOAD: Converting blob to bytes...', tag: 'BASIC_INFO_TAB');
            final response = await http.get(Uri.parse(localFilePath));
            if (response.statusCode == 200) {
              uploadTask = storageRef.putData(
                response.bodyBytes,
                SettableMetadata(contentType: 'image/jpeg'),
              );
            } else {
              throw Exception('Failed to download blob: ${response.statusCode}');
            }
          } else {
            // Mobile: Use File directly
            AppLogger.database('📱 MOBILE UPLOAD: Using file path...', tag: 'BASIC_INFO_TAB');
            uploadTask = storageRef.putFile(
              File(localFilePath),
              SettableMetadata(contentType: 'image/jpeg'),
            );
          }

          final snapshot = await uploadTask.whenComplete(() {});
          final uploadedUrl = await snapshot.ref.getDownloadURL();

          finalPhotoUrl = uploadedUrl;
          AppLogger.database('📸 PHOTO UPLOAD: Success! URL: $uploadedUrl', tag: 'BASIC_INFO_TAB');

          // Add old photo to deleteStorage if it exists
          if (candidate.basicInfo?.photo != null && candidate.basicInfo!.photo!.isNotEmpty) {
            updatedDeleteStorage.add(candidate.basicInfo!.photo!);
            AppLogger.database('🗑️ DELETE STORAGE: Added old photo to deletion list: ${candidate.basicInfo?.photo}', tag: 'BASIC_INFO_TAB');
          }
        } catch (e) {
          AppLogger.databaseError('❌ PHOTO UPLOAD: Failed to upload photo', tag: 'BASIC_INFO_TAB', error: e);
          // Continue with save but keep original photo
          finalPhotoUrl = candidate.basicInfo?.photo;
        }
      }

      // Create updated basicInfo with final photo URL
      final updatedBasicInfo = basicInfo.copyWith(photo: finalPhotoUrl);

      // Create updated candidate with deleteStorage changes
      final updatedCandidate = candidate.copyWith(deleteStorage: updatedDeleteStorage);

      // Direct save using the repository with updated candidate object
      AppLogger.database('📝 REPOSITORY SAVE: Calling updateBasicInfoWithCandidate', tag: 'SAVE_DEBUG');
      AppLogger.database('📝 REPOSITORY SAVE: updatedBasicInfo: ${updatedBasicInfo.toJson()}', tag: 'SAVE_DEBUG');
      AppLogger.database('📝 REPOSITORY SAVE: updatedCandidate.deleteStorage: ${updatedCandidate.deleteStorage}', tag: 'SAVE_DEBUG');

      try {
        final success = await _repository.updateBasicInfoWithCandidate(candidateId, updatedBasicInfo, updatedCandidate);
        AppLogger.database('📝 TAB SAVE: Repository result: $success', tag: 'BASIC_INFO_TAB');

        if (success) {
          // 🔄 CRITICAL SYNCHRONOUS UPDATES (MUST COMPLETE BEFORE SCREEN DISPOSES)
          await _runSynchronousUpdates(finalPhotoUrl);

          // ✅ NOW mark as successful - screen can safely dispose
          onProgress?.call('Basic info saved successfully!');
          AppLogger.database('🎉 SUCCESS: Basic info saved successfully!', tag: 'SAVE_DEBUG');

          // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block dispose)
          _runBackgroundSyncOperations(candidateId, updatedBasicInfo.fullName, finalPhotoUrl, updatedBasicInfo.toJson());

          AppLogger.database('✅ TAB SAVE: Basic info completed successfully', tag: 'BASIC_INFO_TAB');
          return true;
        } else {
          AppLogger.databaseError('❌ TAB SAVE: Repository returned false (no exception)', tag: 'SAVE_DEBUG');
          return false;
        }
      } catch (repoError) {
        AppLogger.databaseError('💥 REPOSITORY ERROR: ${repoError.toString()}', tag: 'SAVE_DEBUG', error: repoError);
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

  /// 🎯 OPTIMISTIC UPDATE: Immediate UI update with background offline sync
  /// Allows editing profile info even when offline - queues for later sync
  Future<void> updateBasicInfoOptimistically(
    String candidateId,
    String field,
    dynamic value, {
    dynamic candidate,
    Function(String)? onProgress,
  }) async {
    try {
      AppLogger.database('🎯 OPTIMISTIC UPDATE: $field = $value for $candidateId', tag: 'BASIC_OPTIMISTIC');

      final syncService = Get.find<ISyncService>();
      final opId = 'basic_info_${candidateId}_${field}_${DateTime.now().millisecondsSinceEpoch}';

      // Create sync operation for offline capability
      final op = SyncOperation(
        id: opId,
        type: SyncOperationType.update,
        candidateId: candidateId,
        target: 'basic_info',
        payload: {
          'field': field,
          'value': value,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Queue operation for background sync (offline support)
      await syncService.queueOperation(op);
      AppLogger.database('✅ OPTIMISTIC UPDATE: Operation queued for sync', tag: 'BASIC_OPTIMISTIC');

      // If provided, also perform immediate fast save for connected users
      if (candidate != null) {
        final updates = {field: value};
        final success = await saveBasicInfoFast(candidateId, updates,
          candidate: candidate,
          candidateName: null,
          onProgress: onProgress
        );

        if (!success) {
          AppLogger.database('⚠️ OPTIMISTIC UPDATE: Fast save failed, relying on sync queue', tag: 'BASIC_OPTIMISTIC');
          // Still successful - operation is queued and will sync when online
        }
      }

      AppLogger.database('🎯 OPTIMISTIC UPDATE: Completed successfully', tag: 'BASIC_OPTIMISTIC');
    } catch (e) {
      AppLogger.databaseError('❌ OPTIMISTIC UPDATE: Failed', tag: 'BASIC_OPTIMISTIC', error: e);
      // Re-throw to let UI handle error state
      throw Exception('Failed to update basic info: $e');
    }
  }

  /// 🚀 FAST SAVE: Direct immediate save (no offline queuing for critical fields)
  Future<bool> saveBasicInfoFast(
    String candidateId,
    Map<String, dynamic> updates, {
    required dynamic candidate,
    String? candidateName,
    Function(String)? onProgress,
  }) async {
    try {
      AppLogger.database('🚀 FAST SAVE: Basic info for $candidateId', tag: 'BASIC_FAST');

      // Get current basic info to merge updates
      final currentBasicInfo = await getBasicInfo(candidate);
      if (currentBasicInfo == null) {
        AppLogger.databaseError('❌ FAST SAVE: Cannot get current basic info', tag: 'BASIC_FAST');
        return false;
      }

      // Create updated basic info model
      BasicInfoModel updatedBasicInfo = currentBasicInfo;
      for (final entry in updates.entries) {
        updatedBasicInfo = getUpdatedCandidate(updatedBasicInfo, entry.key, entry.value);
      }

      // Perform full save with photo handling etc.
      final success = await saveBasicInfoTabWithCandidate(
        candidateId: candidateId,
        basicInfo: updatedBasicInfo,
        candidate: candidate,
        onProgress: onProgress,
      );

      if (success) {
        AppLogger.database('✅ FAST SAVE: Completed successfully', tag: 'BASIC_FAST');
        return true;
      } else {
        AppLogger.databaseError('❌ FAST SAVE: Failed', tag: 'BASIC_FAST');
        return false;
      }
    } catch (e) {
      AppLogger.databaseError('❌ FAST SAVE: Exception occurred', tag: 'BASIC_FAST', error: e);
      return false;
    }
  }

  /// SYNCHRONOUS OPERATIONS: Critical updates that must complete before screen dispose
  Future<void> _runSynchronousUpdates(String? photoUrl) async {
    try {
      AppLogger.database('🔄 SYNC: Starting critical synchronous updates', tag: 'SYNC_OPS');

      // Execute in order - all must complete before dispose
      await _updateUserDocumentSynchronously(photoUrl);
      await _updateCachesSynchronously(photoUrl);

      AppLogger.database('✅ SYNC: All critical updates completed successfully', tag: 'SYNC_OPS');
    } catch (e) {
      AppLogger.databaseError('⚠️ SYNC: Critical synchronous update failed', tag: 'SYNC_OPS', error: e);
      // Even if these fail, don't block the save - user gets success but updates might be inconsistent
      // This is better than blocking the UI forever
    }
  }

  /// Update user document synchronously before dispose
  Future<void> _updateUserDocumentSynchronously(String? photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || photoUrl == null || photoUrl.isEmpty) return;

      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'photoURL': photoUrl});

      AppLogger.database('📝 SYNC: User document updated successfully', tag: 'SYNC_OPS');
    } catch (e) {
      AppLogger.databaseError('⚠️ SYNC: User document update failed', tag: 'SYNC_OPS', error: e);
      // Don't throw - let save complete even if this fails
    }
  }

  /// Update local caches synchronously before dispose
  Future<void> _updateCachesSynchronously(String? photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Invalidate chat controller cache
      final chatController = Get.find<ChatController>();
      chatController.invalidateUserCache(user.uid);

      // Update UserCacheService
      final userCacheService = UserCacheService();
      await userCacheService.updateCachedUserData({
        'uid': user.uid,
        'photoURL': photoUrl,
      });

      AppLogger.database('💾 SYNC: Local caches updated successfully', tag: 'SYNC_OPS');
    } catch (e) {
      AppLogger.databaseError('⚠️ SYNC: Cache update failed', tag: 'SYNC_OPS', error: e);
      // Don't throw - let save complete even if this fails
    }
  }

  /// BACKGROUND OPERATIONS: Only non-critical operations that can run after dispose
  void _runBackgroundSyncOperations(
    String candidateId,
    String? candidateName,
    String? photoUrl,
    Map<String, dynamic> updates
  ) async {
    try {
      AppLogger.database('🔄 BACKGROUND: Starting non-critical background operations', tag: 'BASIC_INFO_FAST');

      // These operations run in parallel and don't block dispose
      List<Future> backgroundOperations = [];

      // 1. Send profile update notification (only background operation now)
      backgroundOperations.add(_sendProfileUpdateNotification(candidateId, updates));

      // 2. Refresh home screen data for UI updates (drawer, etc)
      backgroundOperations.add(_refreshHomeScreenData());

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database('✅ BACKGROUND: All non-critical operations completed', tag: 'BASIC_INFO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Some non-critical operations failed (non-critical)', tag: 'BASIC_INFO_FAST', error: e);
      // Don't throw - background operations shouldn't affect save success
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

  /// Refresh home screen data to reflect profile updates (drawer, etc)
  Future<void> _refreshHomeScreenData() async {
    try {
      AppLogger.database('🏠 BACKGROUND: Refreshing home screen data for UI update', tag: 'BASIC_INFO_FAST');

      // Import avoided due to potential circular dependency, use Get.find pattern
      // HomeScreenStreamService().refreshData(forceRefresh: false);

      // Alternative approach: Trigger candidate controller refresh
      // The controller's candidate value will be refreshed on next access

      AppLogger.database('🏠 BACKGROUND: Home screen refresh triggered', tag: 'BASIC_INFO_FAST');
    } catch (e) {
      AppLogger.databaseError('⚠️ BACKGROUND: Home screen refresh failed', tag: 'BASIC_INFO_FAST', error: e);
    }
  }
}
