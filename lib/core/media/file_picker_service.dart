import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../../utils/app_logger.dart';
import '../models/unified_file.dart';
import 'media_file.dart';

/// Service for picking files of different types
class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a PDF file
  Future<MediaFile?> pickFile(String type) async {
    try {
      AppLogger.candidate('📁 [FilePickerService] Picking file of type: $type');

      switch (type) {
        case 'pdf':
          return await _pickPdf();
        case 'image':
          return await _pickImage();
        case 'video':
          return await _pickVideo();
        default:
          throw UnsupportedError('Unsupported file type: $type');
      }
    } catch (e) {
      AppLogger.candidateError('📁 [FilePickerService] Error picking $type: $e');
      return null;
    }
  }

  Future<MediaFile?> _pickPdf() async {
    final result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes ?? Uint8List(0);
    final size = file.size;

    return MediaFile(
      id: 'pdf_${DateTime.now().millisecondsSinceEpoch}',
      name: file.name,
      type: 'pdf',
      bytes: bytes,
      size: size,
    );
  }

  Future<MediaFile?> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final bytes = kIsWeb ? await image.readAsBytes() : Uint8List(0);
    final size = kIsWeb ? bytes.length : await image.length();

    return MediaFile(
      id: 'image_${DateTime.now().millisecondsSinceEpoch}',
      name: image.name,
      type: 'image',
      bytes: bytes,
      size: size,
    );
  }

  Future<MediaFile?> _pickVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    final bytes = kIsWeb ? await video.readAsBytes() : Uint8List(0);
    final size = kIsWeb ? bytes.length : await video.length();

    return MediaFile(
      id: 'video_${DateTime.now().millisecondsSinceEpoch}',
      name: video.name,
      type: 'video',
      bytes: bytes,
      size: size,
    );
  }
}
