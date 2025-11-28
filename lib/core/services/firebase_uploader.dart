// lib/core/services/firebase_uploader.dart
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:janmat/core/models/unified_file.dart';

/// A universal Firebase Storage uploader service that works across web and mobile platforms.
/// This service abstracts platform differences and provides a consistent upload API.
class FirebaseUploader {
  /// Upload a UnifiedFile to Firebase Storage with progress tracking
  ///
  /// [f] - The UnifiedFile to upload
  /// [storagePath] - Firebase Storage path (e.g., 'candidates/123/profile.jpg')
  /// [onProgress] - Optional progress callback (0.0 to 100.0)
  /// [onProgressBytes] - Optional detailed progress callback with bytes transferred/total
  /// Returns the download URL on success
  static Future<String?> uploadUnifiedFile({
    required UnifiedFile f,
    required String storagePath,
    Function(double progress)? onProgress,
    Function(int bytesTransferred, int totalBytes)? onProgressBytes,
    SettableMetadata? metadata,
  }) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      // Create metadata with content type
      final fileMetadata = metadata ?? SettableMetadata(
        contentType: f.mimeType ?? 'application/octet-stream',
        customMetadata: {
          'originalName': f.name,
          'fileSize': f.size.toString(),
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask;

      if (f.isMobile && f.file != null) {
        // Mobile platform: use putFile with metadata
        uploadTask = ref.putFile(f.file!, fileMetadata);
      } else if (f.bytes != null) {
        // Web platform: use putData with bytes and metadata
        final Uint8List bytes = f.bytes!;
        uploadTask = ref.putData(bytes, fileMetadata);
      } else {
        throw Exception('No file data available to upload');
      }

      // Track upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final bytesTransferred = snapshot.bytesTransferred;
        final totalBytes = snapshot.totalBytes == 0 ? 1 : snapshot.totalBytes;
        final progressPercent = (bytesTransferred / totalBytes) * 100;

        if (onProgress != null) {
          onProgress(progressPercent);
        }

        if (onProgressBytes != null) {
          onProgressBytes(bytesTransferred, totalBytes);
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('FirebaseUploader: Successfully uploaded ${f.name} to $storagePath');
      return downloadUrl;

    } catch (e) {
      // Enhanced error handling for web platform edge cases
      if (kIsWeb) {
        // Handle web-specific Firebase Storage errors
        if (e.toString().contains('quota-exceeded')) {
          throw Exception('Storage quota exceeded. Please try a smaller file or contact support.');
        } else if (e.toString().contains('unauthorized')) {
          throw Exception('Upload permission denied. Please check your authentication and try again.');
        } else if (e.toString().contains('cancelled')) {
          throw Exception('Upload was cancelled. Please try again.');
        } else if (e.toString().contains('invalid-argument')) {
          throw Exception('Invalid file data. Please try selecting the file again.');
        } else if (e.toString().contains('deadline-exceeded')) {
          throw Exception('Upload timed out. Please check your internet connection and try again.');
        } else if (e.toString().contains('not-found')) {
          throw Exception('Storage location not found. Please try again.');
        } else if (e.toString().contains('already-exists')) {
          throw Exception('File already exists. Please rename your file and try again.');
        }
      }

      // Handle general Firebase Storage errors
      if (e.toString().contains('network-request-failed')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('storage/retry-limit-exceeded')) {
        throw Exception('Upload failed after multiple attempts. Please try again later.');
      }

      debugPrint('FirebaseUploader error: ${f.name} -> ${e.toString().split('\n').first}');
      throw Exception('Upload failed: ${e.toString().split(']').last.trim()}');
    }
  }

  /// Delete a file from Firebase Storage using URL
  static Future<void> deleteByUrl(String url) async {
    try {
      if (url.isEmpty) {
        debugPrint('FirebaseUploader: Empty URL provided for deletion');
        return;
      }

      // Validate it's a Firebase Storage URL
      if (!url.startsWith('https://firebasestorage.googleapis.com/')) {
        throw Exception('Not a valid Firebase Storage URL: $url');
      }

      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      
      debugPrint('FirebaseUploader: Successfully deleted $url');
    } catch (e) {
      debugPrint('FirebaseUploader delete error: ${e.toString().split('\n').first}');
      rethrow;
    }
  }

  /// Generate a unique filename for Firebase Storage
  static String generateUniqueFileName(UnifiedFile file, {String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.extension ?? '';
    final cleanName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final filePrefix = prefix != null ? '${prefix}_' : '';
    
    if (extension.isNotEmpty) {
      return '${filePrefix}${timestamp}_$cleanName';
    }
    
    return '${filePrefix}${timestamp}_${cleanName}';
  }

  /// Get recommended storage path based on file type and context
  static String getRecommendedStoragePath(UnifiedFile file, String userId, String category) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    switch (file.fileType) {
      case FileType.image:
        return 'images/$userId/$category/${timestamp}_${file.name}';
      case FileType.video:
        return 'videos/$userId/$category/${timestamp}_${file.name}';
      case FileType.pdf:
        return 'documents/$userId/$category/${timestamp}_${file.name}';
      default:
        return 'files/$userId/$category/${timestamp}_${file.name}';
    }
  }

  /// Upload with retry mechanism
  static Future<String?> uploadWithRetry({
    required UnifiedFile f,
    required String storagePath,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    Function(double progress)? onProgress,
    Function(int bytesTransferred, int totalBytes)? onProgressBytes,
    SettableMetadata? metadata,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        return await uploadUnifiedFile(
          f: f,
          storagePath: storagePath,
          onProgress: onProgress,
          onProgressBytes: onProgressBytes,
          metadata: metadata,
        );
      } catch (e) {
        lastError = e as Exception;
        attempt++;
        
        if (attempt >= maxRetries) {
          debugPrint('FirebaseUploader: Failed to upload after $maxRetries attempts: $lastError');
          throw lastError;
        }

        debugPrint('FirebaseUploader: Upload attempt $attempt failed, retrying in ${retryDelay.inSeconds}s...');
        await Future.delayed(retryDelay);
      }
    }
    
    throw Exception('Upload failed after $maxRetries attempts');
  }
}
