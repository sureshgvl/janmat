import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'media_file.dart';

/// Multi-media picker that works across web and mobile platforms.
/// Supports multiple file selection and various media types.
class MediaPicker {
  static final Map<String, Uint8List> _webTemp = {};

  /// Pick multiple files with customizable extensions
  static Future<List<MediaFile>> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      withData: true, // IMPORTANT for web
      type: FileType.custom,
      allowedExtensions: allowedExtensions ??
          [
            'jpg', 'jpeg', 'png', 'webp', // images
            'pdf', // document
            'mp4', // video
            'mp3', 'wav', // audio
            'zip', 'rar', // archives
          ],
    );

    if (result == null) return [];

    List<MediaFile> files = [];

    for (final file in result.files) {
      if (kIsWeb) {
        // WEB → bytes already available
        final bytes = file.bytes!;
        final id = "web_${DateTime.now().millisecondsSinceEpoch}_${files.length}";
        _webTemp[id] = bytes;

        files.add(
          MediaFile(
            id: id,
            name: file.name,
            type: _inferType(file.extension),
            bytes: bytes,
            size: bytes.length,
          ),
        );
      } else {
        // MOBILE → load bytes from path
        final path = file.path!;
        final bytes = await File(path).readAsBytes();

        final id = "mob_${DateTime.now().millisecondsSinceEpoch}_${files.length}";

        files.add(
          MediaFile(
            id: id,
            name: file.name,
            type: _inferType(file.extension),
            bytes: bytes,
            size: bytes.length,
          ),
        );
      }
    }

    return files;
  }

  /// Pick single file (convenience method)
  static Future<MediaFile?> pickFile({
    List<String>? allowedExtensions,
  }) async {
    final files = await pickFiles(allowMultiple: false, allowedExtensions: allowedExtensions);
    return files.isNotEmpty ? files.first : null;
  }

  /// Clear web temporary files (call when done uploading)
  static void clearWebTemp() {
    _webTemp.clear();
  }

  static String _inferType(String? ext) {
    ext = ext?.toLowerCase();

    if (["jpg", "jpeg", "png", "webp"].contains(ext)) return "image";
    if (ext == "pdf") return "pdf";
    if (ext == "mp4") return "video";
    if (["mp3", "wav"].contains(ext)) return "audio";

    return "other";
  }
}