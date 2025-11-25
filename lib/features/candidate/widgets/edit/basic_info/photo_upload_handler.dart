import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../../utils/app_logger.dart';
import '../../../../../utils/snackbar_utils.dart';

/// PhotoUploadHandler - Handles photo upload functionality
/// Follows Single Responsibility Principle: Only handles photo operations
class PhotoUploadHandler {
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

      // Try to crop the image, but have a fallback if cropping fails (skip cropping on web)
      CroppedFile? croppedFile;
      if (!kIsWeb) {
        // Only attempt cropping on mobile platforms
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
          AppLogger.candidate('Cropping failed on mobile, using original image: $cropError');
        }
      } else {
        AppLogger.candidate('Skipping image cropping on web platform - using original image');
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

      // Upload directly to Firebase Storage with proper path
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/$userId/$fileName');
      final uploadTask = storageRef.putFile(
        File(imagePath),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final photoUrl = await snapshot.ref.getDownloadURL();

      AppLogger.candidate('✅ Photo uploaded successfully to: profile_images/$userId/$fileName');
      if (context.mounted) {
        _showSuccessSnackBar(context, 'Profile photo uploaded successfully!');
      }
      return photoUrl;
    } catch (e) {
      final errorMessage = e.toString();

      // Handle specific Firebase Storage errors
      if (errorMessage.contains('firebase_storage/unauthorized') ||
          errorMessage.contains('Permission denied') ||
          errorMessage.contains('does not have permission')) {
        AppLogger.candidate('⚠️ Firebase Storage permission error - this may be expected in development');
        _showErrorSnackBar(context, 'Storage permissions not configured. Please contact support.');
        return null;
      }

      // Handle network errors
      if (errorMessage.contains('network') || errorMessage.contains('timeout')) {
        _showErrorSnackBar(context, 'Network error. Please check your connection and try again.');
        return null;
      }

      // Generic error
      AppLogger.candidateError('Photo upload failed', error: e);
      _showErrorSnackBar(context, 'Failed to upload photo. Please try again.');
      return null;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    SnackbarUtils.showScaffoldError(context, message);
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    SnackbarUtils.showScaffoldSuccess(context, message);
  }
}
