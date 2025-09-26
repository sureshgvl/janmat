import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Reusable file upload components for candidate profile editing
class FileUploadComponents {
  /// Creates a standardized upload card for different file types
  static Widget buildUploadCard({
    required BuildContext context,
    required FileType fileType,
    required String title,
    required String subtitle,
    required bool isUploading,
    required VoidCallback onUpload,
    required Color cardColor,
    required Color iconColor,
    required IconData icon,
    bool isPremium = false,
    bool isPremiumUser = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: iconColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isPremium) ...[
                  Text(
                    isPremiumUser
                        ? 'Premium Feature - Multi-resolution processing'
                        : 'Premium subscription required',
                    style: TextStyle(
                      fontSize: 10,
                      color: isPremiumUser ? Colors.purple : Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPremium || isPremiumUser)
            ElevatedButton.icon(
              onPressed: !isUploading ? onUpload : null,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_getUploadIcon(fileType)),
              label: Text(_getUploadButtonText(fileType)),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This feature requires premium subscription'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              icon: const Icon(Icons.lock),
              label: const Text('Premium'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.purple),
                foregroundColor: Colors.purple,
              ),
            ),
        ],
      ),
    );
  }

  /// Standard PDF upload card
  static Widget buildPdfUploadCard({
    required BuildContext context,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    return buildUploadCard(
      context: context,
      fileType: FileType.custom,
      title: 'Upload PDF',
      subtitle: 'File must be < 20 MB',
      isUploading: isUploading,
      onUpload: onUpload,
      cardColor: Colors.red,
      iconColor: Colors.red.shade700,
      icon: Icons.picture_as_pdf,
    );
  }

  /// Standard Image upload card
  static Widget buildImageUploadCard({
    required BuildContext context,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    return buildUploadCard(
      context: context,
      fileType: FileType.image,
      title: 'Upload Image',
      subtitle: 'File must be < 10 MB',
      isUploading: isUploading,
      onUpload: onUpload,
      cardColor: Colors.green,
      iconColor: Colors.green.shade700,
      icon: Icons.image,
    );
  }

  /// Standard Video upload card with premium support
  static Widget buildVideoUploadCard({
    required BuildContext context,
    required bool isUploading,
    required VoidCallback onUpload,
    required bool isPremiumUser,
  }) {
    return buildUploadCard(
      context: context,
      fileType: FileType.video,
      title: isPremiumUser
          ? 'Upload Video'
          : 'Premium Video',
      subtitle: isPremiumUser
          ? 'File must be < 100 MB'
          : 'Premium feature required',
      isUploading: isUploading,
      onUpload: onUpload,
      cardColor: Colors.purple,
      iconColor: Colors.purple.shade700,
      icon: isPremiumUser ? Icons.video_call : Icons.lock,
      isPremium: true,
      isPremiumUser: isPremiumUser,
    );
  }

  /// Helper method to get appropriate upload icon
  static IconData _getUploadIcon(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return Icons.photo_camera;
      case FileType.video:
        return Icons.videocam;
      case FileType.custom:
        return Icons.upload_file;
      default:
        return Icons.upload_file;
    }
  }

  /// Helper method to get appropriate upload button text
  static String _getUploadButtonText(FileType fileType) {
    switch (fileType) {
      case FileType.image:
        return 'Choose Image';
      case FileType.video:
        return 'Choose Video';
      case FileType.custom:
        return 'Choose PDF';
      default:
        return 'Choose File';
    }
  }
}

/// Enum for file types
enum FileType {
  image,
  video,
  custom, // For PDF and other custom file types
}
