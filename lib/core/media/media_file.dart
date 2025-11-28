import 'dart:typed_data';
import '../models/unified_file.dart';

/// A unified media file representation that works across web and mobile platforms.
/// This is a simplified wrapper around UnifiedFile for media-specific operations.
class MediaFile {
  final String id;
  final String name;
  final String type; // image, pdf, video, audio, other
  final Uint8List bytes;
  final int size;
  final UnifiedFile? _unifiedFile; // Reference to original UnifiedFile if available

  MediaFile({
    required this.id,
    required this.name,
    required this.type,
    required this.bytes,
    required this.size,
    UnifiedFile? unifiedFile,
  }) : _unifiedFile = unifiedFile;

  /// Create MediaFile from UnifiedFile
  factory MediaFile.fromUnifiedFile(UnifiedFile unifiedFile, String id) {
    return MediaFile(
      id: id,
      name: unifiedFile.name,
      type: _inferTypeFromUnifiedFile(unifiedFile),
      bytes: unifiedFile.bytes ?? Uint8List(0), // Will be populated async if needed
      size: unifiedFile.size,
      unifiedFile: unifiedFile,
    );
  }

  /// Get the underlying UnifiedFile if available
  UnifiedFile? get unifiedFile => _unifiedFile;

  /// Safe map for debugging (without full bytes)
  Map<String, dynamic> toSafeMap() {
    return {
      "id": id,
      "name": name,
      "type": type,
      "size": size,
      "bytes": "[length=${bytes.length}]",
    };
  }

  static String _inferTypeFromUnifiedFile(UnifiedFile file) {
    if (file.isImage) return "image";
    if (file.isVideo) return "video";
    if (file.isPdf) return "pdf";
    return "other";
  }
}