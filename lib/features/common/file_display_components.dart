import 'package:flutter/material.dart';
import 'reusable_image_widget.dart';
import 'reusable_video_widget.dart';

/// Reusable file display components for showing uploaded files
class FileDisplayComponents {
  /// Displays an uploaded PDF file with delete option
  static Widget buildPdfDisplay({
    required BuildContext context,
    required String fileName,
    required bool isEditing,
    VoidCallback? onDelete,
    VoidCallback? onView,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manifesto PDF',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  fileName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (!isEditing) ...[
                  const Text(
                    'Tap to view your manifesto document',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          if (!isEditing && onView != null) ...[
            IconButton(
              onPressed: onView,
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open PDF',
            ),
          ] else if (isEditing && onDelete != null) ...[
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remove PDF',
            ),
          ],
        ],
      ),
    );
  }

  /// Displays an uploaded image with preview and delete option
  static Widget buildImageDisplay({
    required BuildContext context,
    required String imageUrl,
    required String fileName,
    required bool isEditing,
    VoidCallback? onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manifesto Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      fileName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isEditing && onDelete != null) ...[
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Image',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ReusableImageWidget(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            minHeight: 120,
            maxHeight: 200,
            borderColor: Colors.grey.shade300,
            fullScreenTitle: 'Image',
          ),
          if (!isEditing) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap image to view in full screen',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Displays an uploaded video with preview and delete option
  static Widget buildVideoDisplay({
    required BuildContext context,
    required String videoUrl,
    required String fileName,
    required bool isEditing,
    required bool isPremiumUser,
    VoidCallback? onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_call, color: Colors.purple.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manifesto Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    Text(
                      fileName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    // Premium feature comment
                    const Text(
                      'Premium Feature - Multi-resolution video processing',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEditing && onDelete != null) ...[
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Video',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          VideoPreviewWidget(
            videoUrl: videoUrl,
            title: 'Manifesto Video',
            showDuration: false,
            durationText: 'Premium Video',
          ),
          if (!isEditing) ...[
            const SizedBox(height: 8),
            const Text(
              'Premium video content available',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Displays pending files that are ready for upload
  static Widget buildPendingFilesDisplay({
    required BuildContext context,
    required List<Map<String, dynamic>> localFiles,
    required Function(int) onRemoveFile,
  }) {
    if (localFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pending, color: Colors.amber.shade700, size: 24),
              const SizedBox(width: 12),
              Text(
                '${localFiles.length} file${localFiles.length == 1 ? '' : 's'} ready for upload',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Files will be uploaded when you press Save.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...localFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final localFile = entry.value;
            final type = localFile['type'] as String;
            final fileName = localFile['fileName'] as String;
            final fileSize = localFile['fileSize'] as double;

            IconData icon;
            Color color;
            switch (type) {
              case 'pdf':
                icon = Icons.picture_as_pdf;
                color = Colors.red;
                break;
              case 'image':
                icon = Icons.image;
                color = Colors.green;
                break;
              case 'video':
                icon = Icons.video_call;
                color = Colors.purple;
                break;
              default:
                icon = Icons.file_present;
                color = Colors.grey;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${fileSize.toStringAsFixed(2)} MB • Ready for upload',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => onRemoveFile(index),
                      tooltip: 'Remove from upload queue',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Helper class for file information
class FileInfo {
  final String name;
  final String url;
  final String type;

  const FileInfo({required this.name, required this.url, required this.type});
}

