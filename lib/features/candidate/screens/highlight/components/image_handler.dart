import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';


class ImageHandler {
  // Image picker functionality
  static Future<String?> pickBannerImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        AppLogger.candidate('📸 [HighlightDashboard] Image selected: ${image.path}');
        return image.path;
      }
    } catch (e) {
      AppLogger.candidateError('❌ [HighlightDashboard] Error picking image: $e');
      SnackbarUtils.showError('Failed to select image');
    }
    return null;
  }

  // Helper method to get banner image widget
  static Widget getBannerImageWidget({
    required String? localBannerImagePath,
    required String? firebaseImageUrl,
    required bool isUploadingImage,
    required VoidCallback onPickImage,
  }) {
    // Priority: Local image > Firebase image > Placeholder with add button
    if (localBannerImagePath != null) {
      // Show locally selected image with change overlay
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(localBannerImagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Change button overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: isUploadingImage ? null : onPickImage,
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                tooltip: 'Change Image',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    }

    if (firebaseImageUrl != null && firebaseImageUrl.isNotEmpty) {
      // Show Firebase image with change overlay
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              firebaseImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Change button overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: isUploadingImage ? null : onPickImage,
                icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                tooltip: 'Change Image',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    }

    // Show placeholder with add image button
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 32,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 4),
                Text(
                  'No banner image',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: isUploadingImage ? null : onPickImage,
                  icon: const Icon(Icons.upload, size: 14),
                  label: const Text('Add Image', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
