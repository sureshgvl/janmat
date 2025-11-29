import 'package:flutter/material.dart';
import '../../core/media/media_file.dart';

/// Reusable tile component for file uploads
class FileUploadTile extends StatelessWidget {
  final String type;        // pdf, image, video
  final String label;
  final String? uploadedUrl;
  final MediaFile? localFile;
  final Function() onPick;
  final Function()? onDelete;
  final Widget Function()? thumbnailBuilder;

  const FileUploadTile({
    super.key,
    required this.type,
    required this.label,
    required this.onPick,
    this.onDelete,
    this.uploadedUrl,
    this.localFile,
    this.thumbnailBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localFile != null;
    final hasUploaded = uploadedUrl != null && uploadedUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      color: hasLocal ? Colors.orange.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(hasLocal, hasUploaded),
            const SizedBox(height: 10),

            if (hasLocal && thumbnailBuilder != null)
              SizedBox(height: 90, child: thumbnailBuilder!()),

            Row(
              children: [
                ElevatedButton(
                  onPressed: onPick,
                  child: Text(hasLocal ? "Change" : "Choose"),
                ),
                const SizedBox(width: 10),
                if (hasUploaded && onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasLocal, bool hasUploaded) {
    if (hasLocal) {
      return Row(
        children: [
          Icon(Icons.upload_file, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$label Selected", style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  localFile?.name ?? "Unknown file",
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (hasUploaded) {
      return Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Text("$label Uploaded"),
        ],
      );
    }
    return Row(
      children: [
        Icon(Icons.info, color: Colors.grey),
        const SizedBox(width: 8),
        Text("No $label Selected"),
      ],
    );
  }
}
