import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../services/file_upload_service.dart';

/// PhotoUploadHandler - Handles photo upload functionality
/// Follows Single Responsibility Principle: Only handles photo operations
class PhotoUploadHandler {
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  /// Picks and crops an image from gallery
  Future<String?> pickAndCropImage(BuildContext context) async {
    try {
      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Try to crop the image, but have a fallback if cropping fails
      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Photo',
              toolbarColor: Theme.of(context).primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Crop Profile Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPickerButtonHidden: true,
              rotateClockwiseButtonHidden: false,
              rotateButtonsHidden: false,
            ),
          ],
        );
      } catch (cropError) {
        AppLogger.candidate('Cropping failed, using original image: $cropError');
      }

      // Use cropped file if available, otherwise use original
      return croppedFile?.path ?? pickedFile.path;
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to pick image: $e');
      return null;
    }
  }

  /// Uploads a photo to Firebase Storage
  Future<String?> uploadPhoto(String imagePath, String userId, BuildContext context) async {
    if (userId.isEmpty) {
      _showErrorSnackBar(context, 'User ID not found. Please try again.');
      return null;
    }

    try {
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'profile_photos/$fileName';
      final photoUrl = await _fileUploadService.uploadFile(
        imagePath,
        storagePath,
        'image/jpeg',
      );

      if (photoUrl != null) {
        _showSuccessSnackBar(context, 'Profile photo uploaded successfully!');
        return photoUrl;
      }
      return null;
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to upload photo: $e');
      return null;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

