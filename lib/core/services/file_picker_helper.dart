// lib/core/services/file_picker_helper.dart
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';
import 'package:janmat/core/models/unified_file.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

/// A unified file picker service that works across web and mobile platforms.
/// This service abstracts platform differences and provides a consistent API.
class FilePickerHelper {
  /// Pick a single file and return UnifiedFile
  /// 
  /// [allowedExtensions] - List of allowed file extensions (e.g., ['pdf', 'jpg', 'png'])
  /// [maxFileSize] - Maximum file size in MB
  static Future<UnifiedFile?> pickSingle({
    List<String>? allowedExtensions,
    int maxFileSize = 50, // Default 50MB
    UnifiedFileType fileType = UnifiedFileType.any,
  }) async {
    try {
      // Check storage permission on mobile
      if (!kIsWeb) {
        final status = await Permission.storage.request();
        if (!status.isGranted && !status.isLimited) {
          throw Exception('Storage permission denied');
        }
      }

      final fp.FileType filePickerType = _mapFileType(fileType);
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        withData: true, // Always get bytes for unified handling
        type: filePickerType,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final picked = result.files.first;
      
      // Validate file size
      if (picked.size > maxFileSize * 1024 * 1024) {
        throw Exception('File size exceeds ${maxFileSize}MB limit');
      }

      final name = picked.name;
      // Use mime type lookup based on filename
      final mimeType = lookupMimeType(name) ?? 'application/octet-stream';

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null) return null;
        
        return UnifiedFile(
          name: name,
          size: bytes.lengthInBytes,
          bytes: bytes,
          mimeType: mimeType,
        );
      } else {
        final path = picked.path;
        if (path == null) return null;
        
        final file = io.File(path);
        final size = await file.length();
        
        return UnifiedFile(
          name: name,
          size: size,
          file: file,
          mimeType: mimeType,
        );
      }
    } catch (e) {
      debugPrint('FilePickerHelper error: $e');
      rethrow;
    }
  }

  /// Pick multiple files and return list of UnifiedFile
  static Future<List<UnifiedFile>> pickMultiple({
    List<String>? allowedExtensions,
    int maxFileSize = 50,
    int maxFiles = 10,
    UnifiedFileType fileType = UnifiedFileType.any,
  }) async {
    try {
      // Check storage permission on mobile
      if (!kIsWeb) {
        final status = await Permission.storage.request();
        if (!status.isGranted && !status.isLimited) {
          throw Exception('Storage permission denied');
        }
      }

      final fp.FileType filePickerType = _mapFileType(fileType);
      final fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        withData: true,
        type: filePickerType,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      // Limit number of files
      final files = result.files.take(maxFiles).toList();
      final unifiedFiles = <UnifiedFile>[];

      for (final picked in files) {
        // Validate file size
        if (picked.size > maxFileSize * 1024 * 1024) {
          debugPrint('Skipping ${picked.name}: exceeds size limit');
          continue;
        }

        final name = picked.name;
        final mimeType = lookupMimeType(name) ?? 'application/octet-stream';

        if (kIsWeb) {
          final bytes = picked.bytes;
          if (bytes != null) {
            unifiedFiles.add(UnifiedFile(
              name: name,
              size: bytes.lengthInBytes,
              bytes: bytes,
              mimeType: mimeType,
            ));
          }
        } else {
          final path = picked.path;
          if (path != null) {
            final file = io.File(path);
            final size = await file.length();
            
            unifiedFiles.add(UnifiedFile(
              name: name,
              size: size,
              file: file,
              mimeType: mimeType,
            ));
          }
        }
      }

      return unifiedFiles;
    } catch (e) {
      debugPrint('FilePickerHelper multiple pick error: $e');
      rethrow;
    }
  }

  /// Pick image specifically with camera or gallery options
  static Future<UnifiedFile?> pickImage({
    bool allowCamera = true,
    bool allowGallery = true,
    int maxFileSize = 10, // Images usually smaller
  }) async {
    try {
      final source = await _showImageSourceDialog(allowCamera, allowGallery);
      if (source == null) return null;

      // Use image_picker for better image handling
      return await _pickWithImagePicker(source, maxFileSize);
    } catch (e) {
      debugPrint('Image picker error: $e');
      // Fallback to file picker
      return await pickSingle(
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
        maxFileSize: maxFileSize,
        fileType: UnifiedFileType.image,
      );
    }
  }

  /// Pick video file
  static Future<UnifiedFile?> pickVideo({
    int maxFileSize = 100, // Videos can be larger
  }) async {
    return await pickSingle(
      allowedExtensions: ['mp4', 'avi', 'mov', 'wmv', 'webm', 'mkv'],
      maxFileSize: maxFileSize,
      fileType: UnifiedFileType.video,
    );
  }

  /// Pick PDF document
  static Future<UnifiedFile?> pickPdf({
    int maxFileSize = 25, // PDFs typically smaller
  }) async {
    return await pickSingle(
      allowedExtensions: ['pdf'],
      maxFileSize: maxFileSize,
      fileType: UnifiedFileType.pdf,
    );
  }

  /// Get common file type icons based on file type
  static String getFileTypeIcon(UnifiedFile file) {
    switch (file.fileType) {
      case FileType.image:
        return '🖼️';
      case FileType.video:
        return '🎥';
      case FileType.pdf:
        return '📄';
      case FileType.audio:
        return '🎵';
      default:
        return '📎';
    }
  }

  /// Get readable file size string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Private helper methods

  static fp.FileType _mapFileType(UnifiedFileType type) {
    switch (type) {
      case UnifiedFileType.image:
        return fp.FileType.image;
      case UnifiedFileType.video:
        return fp.FileType.video;
      case UnifiedFileType.pdf:
        return fp.FileType.custom; // PDFs need custom handling
      case UnifiedFileType.audio:
        return fp.FileType.media; // Audio files
      default:
        return fp.FileType.any;
    }
  }

  static Future<ImageSource?> _showImageSourceDialog(bool allowCamera, bool allowGallery) async {
    if (kIsWeb) {
      return ImageSource.gallery; // Web only supports gallery
    }

    // For mobile, we'd typically show a dialog here
    // Since we can't show UI dialogs in this service, 
    // we'll return gallery as default and let caller handle the choice
    return ImageSource.gallery;
  }

  static Future<UnifiedFile?> _pickWithImagePicker(ImageSource source, int maxFileSize) async {
    // This would require importing image_picker and implementing the logic
    // For now, we'll throw to fall back to file picker
    throw Exception('Image picker implementation pending');
  }
}

/// Image source enum for consistency
enum ImageSource {
  camera,
  gallery
}

/// UnifiedFile type enum (avoiding conflict with file_picker's FileType)
enum UnifiedFileType {
  any,
  image,
  video,
  pdf,
  audio,
  document,
}
