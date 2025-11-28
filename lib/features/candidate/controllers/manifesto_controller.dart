import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../../services/sync/i_sync_service.dart';
import '../../../utils/app_logger.dart';
import '../models/candidate_model.dart';
import '../models/manifesto_model.dart';
import '../repositories/manifesto_repository.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../notifications/services/constituency_notifications.dart';
import '../../../core/services/firebase_uploader.dart';
import '../../../core/models/unified_file.dart';

abstract class IManifestoController {
  Future<ManifestoModel?> getManifesto(dynamic candidate);
  Future<bool> saveManifestoTab({
    required String candidateId,
    required Candidate candidate,
    required ManifestoModel manifesto,
    Function(String)? onProgress,
  });
  Future<bool> updateManifestoUrls(
    Candidate candidate, {
    String? pdfUrl,
    String? imageUrl,
    String? videoUrl,
  });
  ManifestoModel getUpdatedCandidate(
    ManifestoModel current,
    String field,
    dynamic value,
  );
}

class ManifestoController extends GetxController
    implements IManifestoController {
  final IManifestoRepository _repository;

  ManifestoController({IManifestoRepository? repository})
    : _repository = repository ?? ManifestoRepository();

  @override
  Future<ManifestoModel?> getManifesto(dynamic candidate) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database(
        'ManifestoController: Fetching manifesto for $candidateId',
        tag: 'MANIFESTO_CTRL',
      );
      return await _repository.getManifesto(candidate);
    } catch (e) {
      AppLogger.databaseError(
        'ManifestoController: Error fetching manifesto',
        tag: 'MANIFESTO_CTRL',
        error: e,
      );
      throw Exception('Failed to fetch manifesto: $e');
    }
  }

  @override
  ManifestoModel getUpdatedCandidate(
    ManifestoModel current,
    String field,
    dynamic value,
  ) {
    AppLogger.database(
      'ManifestoController: Updating field $field with value $value',
      tag: 'MANIFESTO_CTRL',
    );

    switch (field) {
      case 'title':
        return current.copyWith(title: value);
      case 'promises':
        return current.copyWith(
          promises: value is List
              ? List<Map<String, dynamic>>.from(value)
              : [value],
        );
      case 'pdfUrl':
        return current.copyWith(pdfUrl: value);
      case 'image':
        return current.copyWith(image: value);
      case 'videoUrl':
        return current.copyWith(videoUrl: value);
      default:
        AppLogger.database(
          'ManifestoController: Unknown field $field, returning unchanged',
          tag: 'MANIFESTO_CTRL',
        );
        return current;
    }
  }

  void updateManifestoField(String field, dynamic value) {
    // This method is called from candidate_data_controller to update the local state
    // The actual saving happens through updateManifestoFields
    AppLogger.database(
      'ManifestoController: updateManifestoField called with field=$field, value=$value',
      tag: 'MANIFESTO_CTRL',
    );
    // Implementation will be handled by the calling controller
  }

  /// Optimistic update for manifesto using ISyncService
  /// Updates UI immediately and queues background sync
  Future<void> updateManifestoOptimistically(
    String candidateId,
    ManifestoModel currentManifesto,
    String field,
    dynamic value,
  ) async {
    try {
      // Update local state immediately (optimistic)
      final updatedManifesto = getUpdatedCandidate(currentManifesto, field, value);
      // TODO: Update the Rx model or notify UI

      // Create sync operation
      final op = SyncOperation(
        id: '${candidateId}_manifesto_${field}_${DateTime.now().millisecondsSinceEpoch}',
        type: SyncOperationType.update,
        candidateId: candidateId,
        target: 'candidates/$candidateId/manifesto',
        payload: {field: value},
      );

      // Queue operation for background sync
      final syncService = Get.find<ISyncService>();
      await syncService.queueOperation(op);

      AppLogger.database(
        '🎯 Optimistic manifesto update queued: $field=$value',
        tag: 'OPTIMIST_UPDATE',
      );
    } catch (e) {
      AppLogger.databaseError(
        'Failed optimistic manifesto update: $e',
        tag: 'OPTIMIST_UPDATE',
        error: e,
      );
    }
  }

  /// TAB-SPECIFIC SAVE: Direct manifesto tab save method
  /// Handles all manifesto operations for the tab independently
  @override
  Future<bool> saveManifestoTab({
    required String candidateId,
    required Candidate candidate,
    required ManifestoModel manifesto,
    Function(String)? onProgress,
  }) async {
    AppLogger.database(
      '📝 MANIFESTO_SAVE: Starting manifesto save operation',
      tag: 'MANIFESTO_SAVE_DEBUG',
    );
    AppLogger.database(
      '📝 MANIFESTO_SAVE: candidateId: $candidateId',
      tag: 'MANIFESTO_SAVE_DEBUG',
    );
    AppLogger.database(
      '📝 MANIFESTO_SAVE: manifesto.pdfUrl: "${manifesto.pdfUrl}"',
      tag: 'MANIFESTO_SAVE_DEBUG',
    );
    AppLogger.database(
      '📝 MANIFESTO_SAVE: manifesto.image: "${manifesto.image}"',
      tag: 'MANIFESTO_SAVE_DEBUG',
    );
    AppLogger.database(
      '📝 MANIFESTO_SAVE: manifesto.videoUrl: "${manifesto.videoUrl}"',
      tag: 'MANIFESTO_SAVE_DEBUG',
    );

    try {
      onProgress?.call('Preparing manifesto data...');

      // Check if manifesto media needs to be uploaded (same as basic_info)
      String? finalPdfUrl = manifesto.pdfUrl;
      String? finalImageUrl = manifesto.image;
      String? finalVideoUrl = manifesto.videoUrl;
      List<String> updatedDeleteStorage = List<String>.from(
        candidate.deleteStorage ?? [],
      );

      // Analyze what needs to be uploaded
      List<String> uploadsNeeded = [];
      if (manifesto.pdfUrl != null && manifesto.pdfUrl!.startsWith('local:'))
        uploadsNeeded.add('PDF');
      if (manifesto.image != null && manifesto.image!.startsWith('local:'))
        uploadsNeeded.add('image');
      if (manifesto.videoUrl != null &&
          manifesto.videoUrl!.startsWith('local:'))
        uploadsNeeded.add('video');

      if (uploadsNeeded.isNotEmpty) {
        onProgress?.call('Uploading ${uploadsNeeded.join(', ')} to storage...');
      }

      // Handle PDF upload
      if (manifesto.pdfUrl != null && manifesto.pdfUrl!.startsWith('local:')) {
        AppLogger.database(
          '📄 PDF UPLOAD: Uploading manifesto PDF...',
          tag: 'MANIFESTO_TAB',
        );
        onProgress?.call('📄 Uploading PDF document...');

        try {
          final pdfUrl = await _uploadMediaFile(
            manifesto.pdfUrl!,
            'pdfs',
            candidateId,
          );
          finalPdfUrl = pdfUrl;
          AppLogger.database(
            '📄 PDF UPLOAD: Success! URL: $pdfUrl',
            tag: 'MANIFESTO_TAB',
          );
          onProgress?.call('✅ PDF uploaded successfully');

          // Add old PDF to deleteStorage if it exists
          if (candidate.manifestoData?.pdfUrl != null &&
              candidate.manifestoData!.pdfUrl!.isNotEmpty &&
              !candidate.manifestoData!.pdfUrl!.startsWith('local:')) {
            updatedDeleteStorage.add(candidate.manifestoData!.pdfUrl!);
            AppLogger.database(
              '🗑️ DELETE STORAGE: Added old manifesto PDF to deletion list',
              tag: 'MANIFESTO_TAB',
            );
          }
        } catch (e) {
          AppLogger.databaseError(
            '❌ PDF UPLOAD: Failed to upload manifesto PDF',
            tag: 'MANIFESTO_TAB',
            error: e,
          );
          onProgress?.call('⚠️ PDF upload failed - using original');
        }
      }

      // Handle image upload
      if (manifesto.image != null && manifesto.image!.startsWith('local:')) {
        AppLogger.database(
          '🖼️ IMAGE UPLOAD: Uploading manifesto image...',
          tag: 'MANIFESTO_TAB',
        );
        onProgress?.call('🖼️ Uploading banner image...');

        try {
          final imageUrl = await _uploadMediaFile(
            manifesto.image!,
            'images',
            candidateId,
          );
          finalImageUrl = imageUrl;
          AppLogger.database(
            '🖼️ IMAGE UPLOAD: Success! URL: $imageUrl',
            tag: 'MANIFESTO_TAB',
          );
          onProgress?.call('✅ Image uploaded successfully');

          // Add old image to deleteStorage if it exists
          if (candidate.manifestoData?.image != null &&
              candidate.manifestoData!.image!.isNotEmpty &&
              !candidate.manifestoData!.image!.startsWith('local:')) {
            updatedDeleteStorage.add(candidate.manifestoData!.image!);
            AppLogger.database(
              '🗑️ DELETE STORAGE: Added old manifesto image to deletion list',
              tag: 'MANIFESTO_TAB',
            );
          }
        } catch (e) {
          AppLogger.databaseError(
            '❌ IMAGE UPLOAD: Failed to upload manifesto image',
            tag: 'MANIFESTO_TAB',
            error: e,
          );
          onProgress?.call('⚠️ Image upload failed - using original');
        }
      }

      // Handle video upload
      if (manifesto.videoUrl != null &&
          manifesto.videoUrl!.startsWith('local:')) {
        AppLogger.database(
          '🎬 VIDEO UPLOAD: Uploading manifesto video...',
          tag: 'MANIFESTO_TAB',
        );
        onProgress?.call('🎬 Uploading promotional video...');

        try {
          final videoUrl = await _uploadMediaFile(
            manifesto.videoUrl!,
            'videos',
            candidateId,
          );
          finalVideoUrl = videoUrl;
          AppLogger.database(
            '🎬 VIDEO UPLOAD: Success! URL: $videoUrl',
            tag: 'MANIFESTO_TAB',
          );
          onProgress?.call('✅ Video uploaded successfully');

          // Add old video to deleteStorage if it exists
          if (candidate.manifestoData?.videoUrl != null &&
              candidate.manifestoData!.videoUrl!.isNotEmpty &&
              !candidate.manifestoData!.videoUrl!.startsWith('local:')) {
            updatedDeleteStorage.add(candidate.manifestoData!.videoUrl!);
            AppLogger.database(
              '🗑️ DELETE STORAGE: Added old manifesto video to deletion list',
              tag: 'MANIFESTO_TAB',
            );
          }
        } catch (e) {
          AppLogger.databaseError(
            '❌ VIDEO UPLOAD: Failed to upload manifesto video',
            tag: 'MANIFESTO_TAB',
            error: e,
          );
          onProgress?.call('⚠️ Video upload failed - using original');
        }
      }

      // Create updated manifesto with final URLs
      final updatedManifesto = manifesto.copyWith(
        pdfUrl: finalPdfUrl,
        image: finalImageUrl,
        videoUrl: finalVideoUrl,
      );

      // Create updated candidate with deleteStorage changes
      final updatedCandidate = candidate.copyWith(
        deleteStorage: updatedDeleteStorage,
      );

      // Direct save using the repository with updated candidate object
      AppLogger.database(
        '📝 REPOSITORY SAVE: Calling updateManifestoWithCandidate',
        tag: 'MANIFESTO_SAVE_DEBUG',
      );
      AppLogger.database(
        '📝 REPOSITORY SAVE: updatedManifesto: ${updatedManifesto.toJson()}',
        tag: 'MANIFESTO_SAVE_DEBUG',
      );
      AppLogger.database(
        '📝 REPOSITORY SAVE: updatedCandidate.deleteStorage: ${updatedCandidate.deleteStorage}',
        tag: 'MANIFESTO_SAVE_DEBUG',
      );

      try {
        final success = await _repository.updateManifestoWithCandidate(
          candidateId,
          updatedManifesto,
          updatedCandidate,
        );

        if (success) {
          // 🔄 CRITICAL SYNCHRONOUS UPDATES (MUST COMPLETE BEFORE SCREEN DISPOSES)
          await _runSynchronousUpdates();

          // ✅ NOW mark as successful - screen can safely dispose
          onProgress?.call('Manifesto saved successfully!');
          AppLogger.database(
            '🎉 SUCCESS: Manifesto saved successfully!',
            tag: 'MANIFESTO_SAVE_DEBUG',
          );

          // 🔄 BACKGROUND OPERATIONS (fire-and-forget, don't block dispose)
          _runBackgroundSyncOperations(
            candidateId,
            candidate.basicInfo!.fullName,
            candidate.basicInfo!.photo,
            updatedManifesto.toJson(),
          );

          AppLogger.database(
            '✅ TAB SAVE: Manifesto completed successfully',
            tag: 'MANIFESTO_TAB',
          );
          return true;
        } else {
          AppLogger.databaseError(
            '❌ TAB SAVE: Manifesto save failed',
            tag: 'MANIFESTO_SAVE_DEBUG',
          );
          return false;
        }
      } catch (repoError) {
        AppLogger.databaseError(
          '💥 REPOSITORY ERROR: ${repoError.toString()}',
          tag: 'MANIFESTO_SAVE_DEBUG',
          error: repoError,
        );
        return false;
      }
    } catch (e) {
      AppLogger.databaseError(
        '❌ TAB SAVE: Manifesto tab save failed',
        tag: 'MANIFESTO_TAB',
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
        tag: 'MANIFESTO_FAST',
      );

      // These operations run in parallel but don't block the main save
      List<Future> backgroundOperations = [];

      // 2. Send manifesto update notification
      backgroundOperations.add(
        _sendManifestoUpdateNotification(candidateId, updates),
      );

      // 3. Update caches
      backgroundOperations.add(
        _updateCaches(candidateId, candidateName, photoUrl),
      );

      // Run all background operations in parallel (fire-and-forget)
      await Future.wait(backgroundOperations);

      AppLogger.database(
        '✅ BACKGROUND: All sync operations completed',
        tag: 'MANIFESTO_FAST',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Some sync operations failed (non-critical)',
        tag: 'MANIFESTO_FAST',
        error: e,
      );
      // Don't throw - background operations shouldn't affect save success
    }
  }

  /// Send notification in background
  Future<void> _sendManifestoUpdateNotification(
    String candidateId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final constituencyNotifications = ConstituencyNotifications();
      await constituencyNotifications.sendManifestoUpdateNotification(
        candidateId: candidateId,
        updateType: 'update',
        manifestoTitle: updates['title'] ?? 'Manifesto',
        manifestoDescription: 'Updated manifesto content',
      );

      AppLogger.database(
        '🔔 BACKGROUND: Manifesto notification sent',
        tag: 'MANIFESTO_FAST',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Notification failed',
        tag: 'MANIFESTO_FAST',
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

      AppLogger.database(
        '💾 BACKGROUND: Caches updated',
        tag: 'MANIFESTO_FAST',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ BACKGROUND: Cache update failed',
        tag: 'MANIFESTO_FAST',
        error: e,
      );
    }
  }

  /// Update manifesto URLs atomically (for batch updates)
  @override
  Future<bool> updateManifestoUrls(
    Candidate candidate, {
    String? pdfUrl,
    String? imageUrl,
    String? videoUrl,
  }) async {
    final candidateId = candidate.candidateId;
    try {
      AppLogger.database(
        'Updating manifesto URLs for $candidateId: pdf=$pdfUrl, image=$imageUrl, video=$videoUrl',
        tag: 'MANIFESTO_URLS',
      );

      // Use the repository's updateManifestoFields method which already handles the location lookup
      final Map<String, dynamic> fieldUpdates = {};
      if (pdfUrl != null) fieldUpdates['pdfUrl'] = pdfUrl;
      if (imageUrl != null) fieldUpdates['image'] = imageUrl;
      if (videoUrl != null) fieldUpdates['videoUrl'] = videoUrl;

      if (fieldUpdates.isEmpty) {
        AppLogger.database('No URLs to update', tag: 'MANIFESTO_URLS');
        return true;
      }

      // Use the repository method that already handles location lookup
      final success = await _repository.updateManifestoFields(
        candidate,
        fieldUpdates,
      );

      if (success) {
        AppLogger.database(
          '✅ Manifesto URLs updated successfully',
          tag: 'MANIFESTO_URLS',
        );
      } else {
        AppLogger.databaseError(
          '❌ Failed to update manifesto URLs via repository',
          tag: 'MANIFESTO_URLS',
        );
      }

      return success;
    } catch (e) {
      AppLogger.databaseError(
        '❌ Failed to update manifesto URLs: $e',
        tag: 'MANIFESTO_URLS',
      );
      return false;
    }
  }

  /// Upload media file to Firebase Storage (same as basic_info)
  Future<String> _uploadMediaFile(
    String localFilePath,
    String mediaType,
    String candidateId,
  ) async {
    final localPath = localFilePath.substring(6);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final extension = mediaType == 'pdfs' ? '.pdf' : '.jpg';
    final fileName =
        '${mediaType}_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';

    String contentType;
    switch (mediaType) {
      case 'pdfs':
        contentType = 'application/pdf';
        break;
      case 'images':
        contentType = 'image/jpeg';
        break;
      case 'videos':
        contentType = 'video/mp4';
        break;
      default:
        contentType = 'application/octet-stream';
    }

    if (kIsWeb && localPath.startsWith('blob:')) {
      // Web: Download blob with enhanced error handling
      try {
        // Validate blob URL format
        if (!localPath.startsWith('blob:')) {
          throw Exception('Invalid blob URL format. Please select the file again.');
        }

        // Fetch blob data with timeout
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(localPath));
          final streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200) {
            if (response.bodyBytes.isEmpty) {
              throw Exception('Selected file appears to be empty. Please choose a different file.');
            }

            // Validate file size (50MB limit for manifesto files)
            const maxSizeBytes = 50 * 1024 * 1024; // 50MB
            if (response.bodyBytes.length > maxSizeBytes) {
              throw Exception('$mediaType file is too large (${(response.bodyBytes.length / (1024 * 1024)).toStringAsFixed(1)}MB). Maximum allowed size is 50MB.');
            }

            final unifiedFile = UnifiedFile(
              name: fileName,
              size: response.bodyBytes.length,
              bytes: response.bodyBytes,
              mimeType: contentType,
            );
            return await FirebaseUploader.uploadUnifiedFile(
              f: unifiedFile,
              storagePath: 'manifesto_media/${candidateId}/${mediaType}/$fileName',
              metadata: SettableMetadata(contentType: contentType),
            ) ?? '';
          } else {
            throw Exception('Failed to read file data (HTTP ${response.statusCode}). Please try selecting the file again.');
          }
        } finally {
          client.close();
        }
      } catch (blobError) {
        if (blobError.toString().contains('timeout')) {
          throw Exception('$mediaType upload timed out. The file may be too large or your connection is slow.');
        } else if (blobError.toString().contains('CORS') || blobError.toString().contains('cross-origin')) {
          throw Exception('Unable to access file due to browser security restrictions. Please try selecting the file again.');
        } else {
          throw Exception('Failed to process selected file: ${blobError.toString().split('Exception: ').last}');
        }
      }
    } else {
      // Mobile: Upload file using FirebaseUploader with error handling
      try {
        final file = File(localPath);
        if (!await file.exists()) {
          throw Exception('Local file not found: $localPath');
        }

        final fileSize = await file.length();
        // Validate file size (50MB limit for manifesto files)
        const maxSizeBytes = 50 * 1024 * 1024; // 50MB
        if (fileSize > maxSizeBytes) {
          throw Exception('$mediaType file is too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Maximum allowed size is 50MB.');
        }

        final unifiedFile = UnifiedFile(
          name: fileName,
          size: fileSize,
          file: file,
          mimeType: contentType,
        );
        return await FirebaseUploader.uploadUnifiedFile(
          f: unifiedFile,
          storagePath: 'manifesto_media/${candidateId}/${mediaType}/$fileName',
          metadata: SettableMetadata(contentType: contentType),
        ) ?? '';
      } catch (fileError) {
        if (fileError.toString().contains('quota-exceeded')) {
          throw Exception('Storage quota exceeded. Please contact support or try a smaller file.');
        } else if (fileError.toString().contains('unauthorized')) {
          throw Exception('Upload permission denied. Please try logging in again.');
        } else if (fileError.toString().contains('network')) {
          throw Exception('Network error. Please check your internet connection and try again.');
        } else {
          throw Exception('Failed to upload $mediaType: ${fileError.toString().split('Exception: ').last}');
        }
      }
    }
  }

  /// SYNCHRONOUS OPERATIONS: Critical updates that must complete before screen dispose
  Future<void> _runSynchronousUpdates() async {
    try {
      AppLogger.database(
        '🔄 SYNC: Starting critical synchronous updates',
        tag: 'MANIFESTO_SYNC_OPS',
      );
      // For manifesto, we don't need specific synchronous updates since
      // media files are updated at manifesto level, not user level
      AppLogger.database(
        '✅ SYNC: All critical updates completed successfully',
        tag: 'MANIFESTO_SYNC_OPS',
      );
    } catch (e) {
      AppLogger.databaseError(
        '⚠️ SYNC: Critical synchronous update failed',
        tag: 'MANIFESTO_SYNC_OPS',
        error: e,
      );
    }
  }
}
