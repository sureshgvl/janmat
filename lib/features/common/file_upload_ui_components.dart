import 'package:flutter/material.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/features/candidate/candidate_localizations.dart';

/// Base class for file upload UI components
abstract class FileUploadUiComponent {
  /// Build upload row for a specific file type
  Widget buildUploadRow({
    required String type,
    required bool hasFile,
    required bool isUploading,
    required bool isDeleting,
    required String? existingFileName,
    required String? existingFileUrl,
    required VoidCallback onUpload,
    required VoidCallback? onDelete,
    required VoidCallback onFileNameTap,
  });
}

/// Individual file upload row type (PDF, Image, Video)
class FileUploadRowType {
  final String type;
  final IconData icon;
  final Color color;
  final String? uploadText;
  final String? limitText;

  FileUploadRowType({
    required this.type,
    required this.icon,
    required this.color,
    this.uploadText,
    this.limitText,
  });
}

/// Factory for creating upload row types
class FileUploadRowTypes {
  static FileUploadRowType pdf = FileUploadRowType(
    type: 'pdf',
    icon: Icons.picture_as_pdf,
    color: Colors.red,
    uploadText: 'uploadPdf', // localization key
    limitText: 'pdfFileLimit', // localization key
  );

  static FileUploadRowType image = FileUploadRowType(
    type: 'image',
    icon: Icons.image,
    color: Colors.green,
  );

  static FileUploadRowType video = FileUploadRowType(
    type: 'video',
    icon: Icons.video_call,
    color: Colors.purple,
    uploadText: 'uploadVideo', // localization key
    limitText: 'videoFileLimit', // localization key
  );
}

/// Generic file upload row widget
class FileUploadRowWidget extends StatelessWidget {
  final FileUploadRowType rowType;
  final bool hasFile;
  final bool isUploading;
  final bool isDeleting;
  final String? existingFileName;
  final String? existingFileUrl;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;
  final VoidCallback? onFileNameTap;

  const FileUploadRowWidget({
    super.key,
    required this.rowType,
    required this.hasFile,
    required this.isUploading,
    required this.isDeleting,
    required this.onUpload,
    this.onDelete,
    this.existingFileName,
    this.existingFileUrl,
    this.onFileNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(rowType.color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasFile ? colorScheme.backgroundColor : colorScheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasFile ? colorScheme.borderColor : colorScheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            rowType.icon,
            color: hasFile ? colorScheme.foregroundColor : colorScheme.foregroundColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasFile) ...[
                  // Show filename when file exists
                  InkWell(
                    onTap: onFileNameTap,
                    child: Text(
                      existingFileName ?? 'File uploaded',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        decoration: onFileNameTap != null ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Action buttons row
                  _buildActionButtonRow(context, colorScheme.foregroundColor),
                ] else ...[
                  // Upload prompt when no file exists
                  Text(
                    _getUploadText(context, rowType),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    _getLimitText(context, rowType),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.foregroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hasFile)
            // Upload button only when no file exists
            _buildUploadButton(context, colorScheme.foregroundColor),
        ],
      ),
    );
  }

  Row _buildActionButtonRow(BuildContext context, Color color) {
    return Row(
      children: [
        // Change/Edit button
        Flexible(
          child: ElevatedButton.icon(
            onPressed: !isUploading ? onUpload : null,
            icon: isUploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.edit, size: 16),
            label: Text(hasFile ? 'Change ${rowType.type.capitalize()}' : 'Choose ${rowType.type.capitalize()}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Delete button (only for PDFs at this time)
        if (onDelete != null && rowType.type == 'pdf')
          Flexible(
            child: OutlinedButton.icon(
              onPressed: !isDeleting ? onDelete : null,
              icon: isDeleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Icon(Icons.delete, size: 16),
              label: Text(isDeleting ? 'Deleting...' : 'Delete ${rowType.type.capitalize()}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  ElevatedButton _buildUploadButton(BuildContext context, Color color) {
    return ElevatedButton.icon(
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
          : Icon(rowType.type == 'image' ? Icons.photo_camera : Icons.upload_file),
      label: Text('Choose ${rowType.type.capitalize()}'),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _getUploadText(BuildContext context, FileUploadRowType rowType) {
    if (rowType.uploadText != null) {
      final candidateLocalizations = CandidateLocalizations.of(context);
      if (candidateLocalizations != null) {
        // Try candidate localizations first
        return candidateLocalizations.translate(rowType.uploadText!) ??
               AppLocalizations.of(context)?.uploadImage ??
               'Upload ${rowType.type.capitalize()}';
      }
    }

    // Fallback to generic text
    return AppLocalizations.of(context)?.uploadImage ?? 'Upload ${rowType.type.capitalize()}';
  }

  String _getLimitText(BuildContext context, FileUploadRowType rowType) {
    final fileLimits = {
      'pdf': 'pdfFileLimit',
      'image': 'imageFileLimit',
      'video': 'videoFileLimit',
    };

    final limitKey = fileLimits[rowType.type] ?? rowType.limitText;
    if (limitKey != null) {
      final candidateLocalizations = CandidateLocalizations.of(context);
      if (candidateLocalizations != null) {
        final translated = candidateLocalizations.translate(limitKey);
        if (translated != null) return translated;

        // Try app localizations as fallback
        final appLocalizations = AppLocalizations.of(context);
        return appLocalizations?.pdfFileLimit ?? appLocalizations?.imageFileLimit ??
               appLocalizations?.videoFileLimit ?? 'File size limit applies';
      }
    }

    // Final fallback
    return '${rowType.type.toUpperCase()} file size limit applies';
  }

  _ColorScheme _getColorScheme(Color baseColor) {
    return _ColorScheme(
      backgroundColor: hasFile ? baseColor.withValues(alpha: 0.1) : baseColor.withValues(alpha: 0.1),
      borderColor: hasFile ? baseColor.withValues(alpha: 0.3) : baseColor.withValues(alpha: 0.2),
      foregroundColor: hasFile ? baseColor.withValues(alpha: 0.7) : baseColor.withValues(alpha: 0.6),
    );
  }
}

/// Color scheme for file upload rows
class _ColorScheme {
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;

  const _ColorScheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
  });
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// Pending files list widget for showing files ready for upload
class PendingFilesListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> localFiles;
  final void Function(Map<String, dynamic>) onRemoveFile;

  const PendingFilesListWidget({
    super.key,
    required this.localFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out PDFs as they appear in the main section
    final pendingFiles = localFiles.where((file) => file['type'] != 'pdf').toList();

    if (pendingFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
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
                'Files ready for upload: ${pendingFiles.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Press Save to upload these files to the server.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...pendingFiles.map((localFile) => _buildFileRow(context, localFile)),
        ],
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, Map<String, dynamic> localFile) {
    final type = localFile['type'] as String;
    final fileName = localFile['fileName'] as String;
    final fileSize = localFile['fileSize'] as double;

    final (icon, color) = _getFileIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            onPressed: () => onRemoveFile(localFile),
            tooltip: 'Remove from upload queue',
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getFileIcon(String type) {
    switch (type) {
      case 'pdf':
        return (Icons.picture_as_pdf, Colors.red);
      case 'image':
        return (Icons.image, Colors.green);
      case 'video':
        return (Icons.video_call, Colors.purple);
      default:
        return (Icons.file_present, Colors.grey);
    }
  }
}
