import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../../../utils/app_logger.dart';
import '../../../../../core/services/file_picker_helper.dart';
import '../../../../../core/services/firebase_uploader.dart';
import '../../../models/candidate_model.dart';

/// A simple profile photo widget for basic info editing
/// Displays current photo and allows upload without Card wrapper
class ProfilePhotoWidget extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(String?) onPhotoSelected;
  final String storagePath;

  const ProfilePhotoWidget({
    super.key,
    required this.currentPhotoUrl,
    required this.onPhotoSelected,
    required this.storagePath,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  bool _isUploading = false;
  double? _uploadProgress;

  Future<void> _pickAndUploadPhoto() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Pick image file
      final file = await FilePickerHelper.pickSingle(
        maxFileSize: 10, // 10MB for profile photos
        fileType: UnifiedFileType.image,
      );

      if (file == null) {
        setState(() {
          _isUploading = false;
        });
        return; // User cancelled
      }

      // Upload to Firebase
      final uploadUrl = await FirebaseUploader.uploadUnifiedFile(
        f: file,
        storagePath: widget.storagePath,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress / 100;
          });
        },
      );

      if (uploadUrl != null) {
        widget.onPhotoSelected(uploadUrl);
        AppLogger.candidate('📸 Profile photo uploaded successfully: $uploadUrl');
      } else {
        AppLogger.candidate('❌ Profile photo upload failed - no URL returned');
        _showError('Upload failed - no URL returned');
      }
    } catch (e) {
      AppLogger.candidate('❌ Profile photo upload error: $e');
      _showError('Upload failed: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadPhoto,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: Border.all(
            color: _isUploading ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: _isUploading
            ? _buildUploadingState()
            : _buildPhotoDisplay(),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Current photo or placeholder
        _buildPhotoDisplay(),
        // Overlay with progress
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Uploading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoDisplay() {
    if (widget.currentPhotoUrl != null && widget.currentPhotoUrl!.isNotEmpty) {
      // Show uploaded photo
      return ClipOval(
        child: Image.network(
          widget.currentPhotoUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      // Show placeholder with camera icon
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to\nupload',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}