import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../services/file_upload_service.dart';
import '../../../../../utils/snackbar_utils.dart';
import '../highlight_config.dart';

// Banner Image Section Widget
// Follows Single Responsibility Principle - handles only banner image upload

class BannerImageSection extends StatefulWidget {
  final HighlightConfig config;
  final bool isEditing;
  final ValueChanged<String> onImageUrlChanged;

  const BannerImageSection({
    super.key,
    required this.config,
    required this.isEditing,
    required this.onImageUrlChanged,
  });

  @override
  State<BannerImageSection> createState() => _BannerImageSectionState();
}

class _BannerImageSectionState extends State<BannerImageSection> {
  final FileUploadService _fileUploadService = FileUploadService();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.image, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Banner Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload a custom banner image for your highlight (optional)',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),

            // Current image preview or upload area
            if (widget.config.bannerImageUrl.isNotEmpty) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: _getImageProvider(widget.config.bannerImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isEditing ? () => _uploadImage(context) : null,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: widget.isEditing ? () => _removeImage() : null,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Upload area
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to upload banner image',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG up to 5MB',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isEditing ? () => _uploadImage(context) : null,
                  icon: const Icon(Icons.upload),
                  label: _isUploading
                      ? const Text('Uploading...')
                      : const Text('Upload Banner Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (_fileUploadService.isLocalPath(imageUrl)) {
      // Local file path
      final actualPath = imageUrl.replaceFirst('local:', '');
      return FileImage(File(actualPath));
    } else {
      // Firebase URL
      return NetworkImage(imageUrl);
    }
  }

  void _uploadImage(BuildContext context) async {
    try {
      setState(() => _isUploading = true);

      // Use FileUploadService to save photo locally first
      final localPath = await _fileUploadService.savePhotoLocally(
        'banner', // Using 'banner' as candidateId for highlights
        'banner_image',
      );

      if (localPath != null) {
        // Upload to Firebase Storage immediately for banner images
        try {
          final firebaseUrl = await _fileUploadService.uploadLocalPhotoToFirebase(localPath);
          if (firebaseUrl != null) {
            // Update the config with Firebase URL instead of local path
            widget.onImageUrlChanged(firebaseUrl);
            AppLogger.candidate('Banner image uploaded to Firebase: $firebaseUrl');
          } else {
            // Keep local path if Firebase upload fails
            widget.onImageUrlChanged(localPath);
            AppLogger.candidate('Firebase upload failed, keeping local path: $localPath');
          }
        } catch (firebaseError) {
          // Keep local path if Firebase upload fails
          widget.onImageUrlChanged(localPath);
          AppLogger.candidate('Firebase upload error, keeping local path: $firebaseError');
        }
      }

      if (localPath != null) {
        // Update the config with local path
        widget.onImageUrlChanged(localPath);

        SnackbarUtils.showScaffoldInfo(context, 'Banner image saved locally. It will be uploaded to Firebase when you save.');

        AppLogger.candidate('Banner image saved locally: $localPath');
      } else {
        SnackbarUtils.showScaffoldError(context, 'Failed to save banner image');
      }
    } catch (e) {
      AppLogger.candidate('Error uploading banner image: $e');
      SnackbarUtils.showScaffoldError(context, 'Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _removeImage() {
    AppLogger.candidate('Banner image removal requested');
    widget.onImageUrlChanged('');
  }
}
