import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:firebase_storage/firebase_storage.dart';
import '../../utils/app_logger.dart';
import '../../core/services/firebase_uploader.dart';
import '../../core/models/unified_file.dart';
import 'dart:html' as html show window, Blob, FileReader;

/// Failed upload record for retry functionality
class FailedUpload {
  final dynamic file;
  final String type;
  final String userId;
  final DateTime timestamp;

  const FailedUpload({
    required this.file,
    required this.type,
    required this.userId,
    required this.timestamp,
  });
}

/// Manages file storage operations across platforms
class FileStorageManager {
  static const String tempDirName = 'manifesto_temp';
  final Map<String, Uint8List> _webFileData = {}; // Web file data storage
  static const int _maxWebDataSizeMB = 20; // Maximum 20MB of web file data to prevent browser storage quota issues
  int _currentWebDataSize = 0; // Track current size in bytes

  /// Save file temporarily for preview (unified approach)
  Future<String?> saveTempFile(dynamic file, String type) async {
    try {
      AppLogger.candidate(
        '💾 [FileStorage] Saving $type file temporarily for preview...',
      );

      if (kIsWeb) {
        return await _saveWebFile(file, type);
      } else {
        return await _saveLocalFile(file, type);
      }
    } catch (e) {
      AppLogger.candidate('💾 [FileStorage] Error saving temp file: $e');
      return null;
    }
  }

  /// Save web file to memory and return temp reference
  Future<String?> _saveWebFile(dynamic file, String type) async {
    final tempId = 'web_${DateTime.now().millisecondsSinceEpoch}';

    if (file is XFile) {
      final bytes = await file.readAsBytes();

      // Check if adding this file would exceed storage limit
      if (_currentWebDataSize + bytes.length > _maxWebDataSizeMB * 1024 * 1024) {
        // Clean up old files to make space
        await _cleanupWebDataToMakeSpace(bytes.length);
      }

      _webFileData[tempId] = bytes;
      _currentWebDataSize += bytes.length;

      AppLogger.candidate('🌐 [FileStorage] Web $type stored: $tempId (${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB), total: ${(_currentWebDataSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
      return 'temp:$tempId:$type:${file.name}:$bytes.length';

    } else if (file is file_picker.PlatformFile && file.bytes != null) {
      final bytes = file.bytes!;

      // Check if adding this file would exceed storage limit
      if (_currentWebDataSize + bytes.length > _maxWebDataSizeMB * 1024 * 1024) {
        // Clean up old files to make space
        await _cleanupWebDataToMakeSpace(bytes.length);
      }

      _webFileData[tempId] = bytes;
      _currentWebDataSize += bytes.length;

      AppLogger.candidate('🌐 [FileStorage] Web $type stored: $tempId (${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB), total: ${(_currentWebDataSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
      return 'temp:$tempId:$type:${file.name}:${file.size}';
    }

    throw Exception(
      'Unsupported web file type: ${file.runtimeType} for type $type',
    );
  }

  /// Save local file to temp directory
  Future<String?> _saveLocalFile(dynamic file, String type) async {
    try {
      // Clean up old temp files first (keep only files from last 30 minutes)
      await _cleanupOldTempFiles();

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/$tempDirName');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
        AppLogger.candidate(
          '💾 [FileStorage] Created temp directory: ${localDir.path}',
        );
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = 'unknown_user'; // This should be passed from context
      final fileName =
          'temp_${type}_${userId}_$timestamp.${type == 'pdf' ? 'pdf' : 'tmp'}';
      final localPath = '${localDir.path}/$fileName';

      // Save file locally
      if (file is file_picker.PlatformFile) {
        if (file.bytes != null) {
          // Web platform PDF or other files with bytes
          final localFile = File(localPath);
          await localFile.writeAsBytes(file.bytes!);
          AppLogger.candidate('💾 [FileStorage] Saved web file to: $localPath');
        } else if (file.path != null) {
          // Mobile platform
          await File(file.path!).copy(localPath);
          AppLogger.candidate(
            '💾 [FileStorage] Copied mobile file to: $localPath',
          );
        }
      } else if (file is XFile) {
        // Image picker file
        await File(file.path).copy(localPath);
        AppLogger.candidate(
          '💾 [FileStorage] Copied image file to: $localPath',
        );
      }

      AppLogger.candidate(
        '💾 [FileStorage] File saved successfully at: $localPath',
      );
      return localPath;
    } catch (e) {
      AppLogger.candidate('💾 [FileStorage] Error saving local file: $e');
      return null;
    }
  }

  /// Clean up old temporary files (older than 30 minutes) - Mobile only
  Future<void> _cleanupOldTempFiles() async {
    if (kIsWeb) return; // Web cleanup handled separately

    try {
      AppLogger.candidate('🧹 [FileStorage] Starting temp file cleanup...');

      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/$tempDirName');

      if (!await localDir.exists()) return;

      final files = await localDir.list().toList();
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));
      int cleanedCount = 0;
      int totalSize = 0;

      for (final entity in files) {
        if (entity is File) {
          try {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffTime)) {
              final size = stat.size;
              await entity.delete();
              cleanedCount++;
              totalSize += size;
              AppLogger.candidate(
                '🧹 [FileStorage] Deleted old file: ${entity.path} (${(size / (1024 * 1024)).toStringAsFixed(2)} MB)',
              );
            }
          } catch (e) {
            AppLogger.candidate(
              '⚠️ [FileStorage] Failed to delete ${entity.path}: $e',
            );
          }
        }
      }

      if (cleanedCount > 0) {
        AppLogger.candidate(
          '🧹 [FileStorage] Cleaned up $cleanedCount old files, freed ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      } else {
        AppLogger.candidate('🧹 [FileStorage] No old files to clean');
      }
    } catch (e) {
      AppLogger.candidate(
        '⚠️ [FileStorage] Error during temp file cleanup: $e',
      );
    }
  }

  /// Clean up web file data to make space for new files (web only)
  Future<void> _cleanupWebDataToMakeSpace(int requiredBytes) async {
    if (!kIsWeb) return;

    try {
      AppLogger.candidate('🧹 [WebCleanup] Starting web data cleanup, need ${(requiredBytes / (1024 * 1024)).toStringAsFixed(2)} MB space...');

      final maxSizeBytes = _maxWebDataSizeMB * 1024 * 1024;
      final targetSizeBytes = maxSizeBytes - requiredBytes;

      // If we can't fit the required bytes even after clearing everything, reject
      if (requiredBytes > maxSizeBytes) {
        throw Exception('File too large: ${(requiredBytes / (1024 * 1024)).toStringAsFixed(2)} MB exceeds limit of $_maxWebDataSizeMB MB');
      }

      // Sort files by age (oldest first) - we need to extract timestamps from tempIds
      final sortedEntries = _webFileData.entries.toList()
        ..sort((a, b) {
          // Extract timestamp from tempId (format: web_timestamp)
          final aTimestamp = int.tryParse(a.key.split('_').last) ?? 0;
          final bTimestamp = int.tryParse(b.key.split('_').last) ?? 0;
          return aTimestamp.compareTo(bTimestamp); // Oldest first
        });

      int cleanedCount = 0;
      int freedBytes = 0;

      // Remove oldest files until we have enough space
      for (final entry in sortedEntries) {
        if (_currentWebDataSize <= targetSizeBytes) break;

        final size = entry.value.length;
        _webFileData.remove(entry.key);
        _currentWebDataSize -= size;
        cleanedCount++;
        freedBytes += size;

        AppLogger.candidate(
          '🧹 [WebCleanup] Removed ${entry.key}: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      }

      if (cleanedCount > 0) {
        AppLogger.candidate(
          '🧹 [WebCleanup] Cleaned up $cleanedCount files, freed ${(freedBytes / (1024 * 1024)).toStringAsFixed(2)} MB. Current size: ${(_currentWebDataSize / (1024 * 1024)).toStringAsFixed(2)} MB',
        );
      } else {
        AppLogger.candidate('🧹 [WebCleanup] No cleanup needed');
      }

    } catch (e) {
      AppLogger.candidate('⚠️ [WebCleanup] Error during web data cleanup: $e');
      rethrow;
    }
  }

  /// Clean up specific temp file
  void cleanupTempFile(String tempPath) {
    try {
      if (kIsWeb && tempPath.startsWith('temp:')) {
        // Web cleanup: remove from memory and update size tracking
        final tempId = tempPath.split(':')[1];
        final bytes = _webFileData[tempId];
        if (bytes != null) {
          _currentWebDataSize -= bytes.length;
          _webFileData.remove(tempId);
          AppLogger.candidate(
            '🌐 [FileStorage] Cleaned up web file data for $tempId, freed ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
          );
        }
      } else {
        // Local file cleanup
        _cleanupLocalFile(tempPath);
      }
    } catch (e) {
      AppLogger.candidate('⚠️ [FileStorage] Error cleaning up temp file: $e');
    }
  }

  /// Clear all web file data (call on app initialization to prevent storage quota issues)
  void clearAllWebData() {
    if (!kIsWeb) return;

    final clearedCount = _webFileData.length;
    final clearedSize = _currentWebDataSize;

    _webFileData.clear();
    _currentWebDataSize = 0;

    if (clearedCount > 0) {
      AppLogger.candidate(
        '🧹 [WebCleanup] Cleared all web data: $clearedCount files, ${(clearedSize / (1024 * 1024)).toStringAsFixed(2)} MB freed',
      );
    }
  }

  /// Clean up specific local file
  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      if (!kIsWeb) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.candidate(
            '🧹 [FileStorage] Local file deleted successfully',
          );
        } else {
          AppLogger.candidate(
            '🧹 [FileStorage] Local file not found, nothing to clean',
          );
        }
      }
    } catch (e) {
      AppLogger.candidate('🧹 [FileStorage] Error cleaning up local file: $e');
    }
  }

  /// Upload single file to Firebase Storage
  Future<String?> uploadFileToStorage(
    dynamic file,
    String storagePath,
    String tempPath,
    String type,
  ) async {
    try {
      final metadata = _createMetadata(type);

      if (kIsWeb && tempPath.startsWith('temp:')) {
        // Web upload from memory
        return await _uploadWebFileToStorage(
          storagePath,
          file,
          type,
          metadata,
          tempPath,
        );
      } else if (kIsWeb && tempPath.startsWith('blob:')) {
        // Web upload from blob URL (videos)
        return await _uploadWebBlobFileToStorage(
          storagePath,
          tempPath,
          type,
          metadata,
        );
      } else {
        // Mobile upload from local file
        return await _uploadLocalFileToStorage(
          storagePath,
          file,
          metadata,
          type,
        );
      }
    } catch (e) {
      AppLogger.candidate('❌ [FileStorage] Error uploading file: $e');
      return null;
    }
  }

  /// Upload single web file from memory to Firebase Storage
  Future<String?> _uploadWebFileToStorage(
    String storagePath,
    dynamic file,
    String type,
    SettableMetadata metadata,
    String tempPath,
  ) async {
    // Web: Upload from stored memory data
    final parts = tempPath.split(':');
    if (parts.length >= 4) {
      final tempId = parts[1];
      final fileType = parts[2];
      final originalFileName = parts[3];

      final bytes = _webFileData[tempId];
      if (bytes != null) {
        AppLogger.candidate(
          '🌐 [FileStorage] Web upload for $fileType: $originalFileName',
        );

        final unifiedFile = UnifiedFile(
          name: originalFileName,
          size: bytes.length,
          bytes: bytes,
          mimeType: _getMimeType(fileType),
        );

        final downloadUrl = await FirebaseUploader.uploadUnifiedFile(
          f: unifiedFile,
          storagePath: storagePath,
          metadata: metadata,
        );

        // Clean up memory after successful upload
        _webFileData.remove(tempId);
        AppLogger.candidate(
          '🌐 [FileStorage] Web file data cleaned up for $tempId',
        );

        return downloadUrl;
      } else {
        AppLogger.candidate(
          '⚠️ [FileStorage] Web file data not found for $tempId',
        );
      }
    }
    return null;
  }

  /// Upload single local file to Firebase Storage
  Future<String?> _uploadLocalFileToStorage(
    String storagePath,
    dynamic file,
    SettableMetadata metadata,
    String type,
  ) async {
    // Mobile: Upload from local file
    final localFile = File(file.path);
    if (!await localFile.exists()) {
      AppLogger.candidate(
        '⚠️ [FileStorage] Local file not found: ${file.path}',
      );
      return null;
    }

    final unifiedFile = UnifiedFile(
      name: file.name,
      size: await localFile.length(),
      file: localFile,
      mimeType: _getMimeType(type),
    );

    return await FirebaseUploader.uploadUnifiedFile(
      f: unifiedFile,
      storagePath: storagePath,
      metadata: metadata,
    );
  }

  /// Bulk upload all pending files
  Future<Map<String, String>> uploadBulkFiles(
    List<Map<String, dynamic>> localFiles,
    String candidateId,
  ) async {
    final Map<String, String> uploadedUrls = {};
    AppLogger.candidate(
      '🚀 [FileStorage] Starting bulk upload of ${localFiles.length} files...',
    );

    for (final localFile in localFiles) {
      final type = localFile['type'] as String;
      final tempPath = localFile['localPath'] as String;
      final fileName = localFile['fileName'] as String;
      final bytes =
          localFile['bytes'] as Uint8List?; // Check for pre-read bytes

      try {
        AppLogger.candidate('🚀 [FileStorage] Uploading $type: $fileName');

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageFileName =
            '${type}_${candidateId}_$timestamp.${_getFileExtension(type)}';
        final storagePath = 'manifesto_files/$candidateId/$storageFileName';

        String? downloadUrl;

        // If we have pre-read bytes (from web video upload), use them directly
        if (bytes != null && bytes.isNotEmpty) {
          AppLogger.candidate(
            '🚀 [FileStorage] Using pre-read bytes for $type upload',
          );
          downloadUrl = await _uploadBytesDirectlyToStorage(
            bytes,
            storagePath,
            type,
            fileName,
          );
        } else {
          // Fallback to original method
          downloadUrl = await uploadFileToStorage(
            XFile(tempPath),
            storagePath,
            tempPath,
            type,
          );
        }

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          uploadedUrls[type] = downloadUrl;
          AppLogger.candidate(
            '✅ [FileStorage] Successfully uploaded $type: $downloadUrl',
          );

          // Clean up temp file after successful upload
          cleanupTempFile(tempPath);
        } else {
          AppLogger.candidate(
            '❌ [FileStorage] Failed to upload $type: $fileName',
          );
        }
      } catch (e) {
        AppLogger.candidate(
          '❌ [FileStorage] Error uploading $type $fileName: $e',
        );
      }
    }

    AppLogger.candidate(
      '🚀 [FileStorage] Bulk upload completed. Uploaded ${uploadedUrls.length} files.',
    );
    return uploadedUrls;
  }

  /// Delete file from Firebase Storage
  Future<bool> deleteFromStorage(String fileUrl) async {
    try {
      AppLogger.candidate(
        '🗑️ [FileStorage] Deleting file from Firebase Storage: $fileUrl',
      );

      // Validate URL format first
      if (!fileUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        throw Exception('Invalid Firebase Storage URL format');
      }

      // Create reference from URL and delete
      final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
      await storageRef.delete();

      AppLogger.candidate(
        '✅ [FileStorage] File successfully deleted from Firebase Storage',
      );
      return true;
    } catch (e) {
      AppLogger.candidateError(
        '❌ [FileStorage] Failed to delete from storage: $e',
      );
      return false;
    }
  }

  /// Create Firebase Storage metadata for file type
  SettableMetadata _createMetadata(String type) {
    return SettableMetadata(
      contentType: _getMimeType(type),
      // Explicitly set cache control for immediate availability
      cacheControl: 'public,max-age=31536000',
    );
  }

  /// Get MIME type for file type
  String _getMimeType(String type) {
    switch (type) {
      case 'video':
        return 'video/mp4';
      case 'image':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get file extension for file type
  String _getFileExtension(String type) {
    switch (type) {
      case 'pdf':
        return 'pdf';
      case 'video':
        return 'mp4';
      case 'image':
        return 'jpg';
      default:
        return 'tmp';
    }
  }

  /// Check if web file data exists for temp ID
  bool hasWebFileData(String tempId) {
    return _webFileData.containsKey(tempId);
  }

  /// Upload bytes directly to Firebase Storage (for pre-read web files)
  Future<String?> _uploadBytesDirectlyToStorage(
    Uint8List bytes,
    String storagePath,
    String type,
    String fileName,
  ) async {
    try {
      final metadata = _createMetadata(type);

      AppLogger.candidate(
        '🚀 [FileStorage] Direct bytes upload for $type: $fileName (${bytes.length} bytes)',
      );

      final unifiedFile = UnifiedFile(
        name: fileName,
        size: bytes.length,
        bytes: bytes,
        mimeType: _getMimeType(type),
      );

      final downloadUrl = await FirebaseUploader.uploadUnifiedFile(
        f: unifiedFile,
        storagePath: storagePath,
        metadata: metadata,
      );

      return downloadUrl;
    } catch (e) {
      AppLogger.candidate('❌ [FileStorage] Direct bytes upload failed: $e');
      return null;
    }
  }

  /// Upload single web file from blob URL to Firebase Storage
  Future<String?> _uploadWebBlobFileToStorage(
    String storagePath,
    String blobUrl,
    String type,
    SettableMetadata metadata,
  ) async {
    try {
      // Extract filename from blob URL if possible, otherwise use generic name
      String originalFileName =
          'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Read bytes from blob URL using web APIs
      final bytes = await _readBlobAsBytes(blobUrl);

      AppLogger.candidate(
        '🌐 [FileStorage] Web blob upload for $type: $originalFileName',
      );

      final unifiedFile = UnifiedFile(
        name: originalFileName,
        size: bytes.length,
        bytes: bytes,
        mimeType: _getMimeType(type),
      );

      final downloadUrl = await FirebaseUploader.uploadUnifiedFile(
        f: unifiedFile,
        storagePath: storagePath,
        metadata: metadata,
      );

      return downloadUrl;
    } catch (e) {
      AppLogger.candidate('⚠️ [FileStorage] Blob upload failed: $e');
      return null;
    }
  }

  /// Read bytes from blob URL using web APIs
  Future<Uint8List> _readBlobAsBytes(String blobUrl) async {
    if (!kIsWeb) {
      throw UnsupportedError('Blob reading is only supported on web');
    }

    try {
      final response = await html.window.fetch(blobUrl);
      final blob = await response.blob();
      final reader = html.FileReader();

      final completer = Completer<Uint8List>();
      reader.onLoad.listen((event) {
        final result = reader.result;
        if (result is ByteBuffer) {
          // Convert ByteBuffer to Uint8List
          completer.complete(Uint8List.view(result));
        } else {
          completer.completeError(
            'Failed to read blob as bytes: unexpected result type ${result.runtimeType}',
          );
        }
      });

      reader.onError.listen((event) {
        completer.completeError('Error reading blob: ${reader.error}');
      });

      reader.readAsArrayBuffer(blob);
      return completer.future;
    } catch (e) {
      throw Exception('Failed to read blob: $e');
    }
  }

  /// Get web file data size
  int getWebFileDataSize(String tempId) {
    return _webFileData[tempId]?.length ?? 0;
  }

  /// Get web file data (public accessor for media upload system)
  Uint8List? getWebFileData(String tempId) {
    return _webFileData[tempId];
  }

  /// Get storage path for candidate files
  static String getStoragePath(
    String candidateId,
    String type,
    String fileName,
  ) {
    return 'manifesto/${type}s/${type}_${candidateId}_${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';
  }

  /// Get download URL from storage reference
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      AppLogger.candidateError(
        '❌ [FileStorage] Failed to get download URL: $e',
      );
      return null;
    }
  }
}
