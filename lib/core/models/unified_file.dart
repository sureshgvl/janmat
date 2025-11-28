// lib/core/models/unified_file.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'dart:io' as io show File; // used only as a type, safe if not referenced on web runtime
import 'package:image_picker/image_picker.dart'; // For XFile support

/// A unified file representation that works across both web and mobile platforms.
/// This abstraction solves the dart:io compatibility issue between platforms.
class UnifiedFile {
  final Uint8List? bytes;        // Web/browser path - raw file data
  final io.File? file;           // Mobile/desktop path (dart:io File object)
  final XFile? xFile;            // Cross-platform file picker (XFile)
  final String name;
  final String? mimeType;
  final int size;

  const UnifiedFile({
    required this.name,
    required this.size,
    this.bytes,
    this.file,
    this.xFile,
    this.mimeType,
  });

  /// Check if this is a web platform file (bytes-based)
  bool get isWeb => bytes != null;

  /// Check if this is a mobile/desktop platform file (file-based)
  bool get isMobile => file != null && !kIsWeb;

  /// Get the actual data (bytes) regardless of platform
  Uint8List get data {
    if (bytes != null) {
      return bytes!;
    } else if (file != null) {
      // For mobile, we'll need to read the file synchronously or asynchronously
      // This method should be called in async context when possible
      throw StateError('Cannot get bytes from file directly. Use async methods.');
    }
    throw StateError('No file data available');
  }

  /// Get file extension from name
  String? get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : null;
  }

  /// Check if file is an image
  bool get isImage {
    final imageMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    
    if (mimeType != null) {
      return imageMimeTypes.any((type) => mimeType!.toLowerCase().contains(type));
    }
    
    if (extension != null) {
      return imageExtensions.contains(extension!.toLowerCase());
    }
    
    return false;
  }

  /// Check if file is a video
  bool get isVideo {
    final videoMimeTypes = ['video/mp4', 'video/avi', 'video/mov', 'video/wmv', 'video/webm'];
    final videoExtensions = ['mp4', 'avi', 'mov', 'wmv', 'webm', 'mkv'];
    
    if (mimeType != null) {
      return videoMimeTypes.any((type) => mimeType!.toLowerCase().contains(type));
    }
    
    if (extension != null) {
      return videoExtensions.contains(extension!.toLowerCase());
    }
    
    return false;
  }

  /// Check if file is a PDF
  bool get isPdf {
    if (mimeType != null) {
      return mimeType!.toLowerCase().contains('pdf');
    }
    return extension?.toLowerCase() == 'pdf';
  }

  /// Get file type category
  FileType get fileType {
    if (isImage) return FileType.image;
    if (isVideo) return FileType.video;
    if (isPdf) return FileType.pdf;
    return FileType.other;
  }

  @override
  String toString() {
    return 'UnifiedFile(name: $name, size: $size, isWeb: $isWeb, isMobile: $isMobile, mimeType: $mimeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UnifiedFile &&
        other.name == name &&
        other.size == size &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode {
    return name.hashCode ^ size.hashCode ^ mimeType.hashCode;
  }
}

/// File type enumeration for categorization
enum FileType {
  image,
  video,
  pdf,
  document,
  audio,
  other
}

/// Extension for UnifiedFile to provide async utility methods
extension UnifiedFileAsync on UnifiedFile {
  /// Read file bytes asynchronously (works for both platforms)
  Future<Uint8List> readAsBytes() async {
    if (bytes != null) {
      return bytes!;
    } else if (file != null) {
      return await file!.readAsBytes();
    }
    throw StateError('No file data available');
  }
}
