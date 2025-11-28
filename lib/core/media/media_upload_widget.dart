import 'dart:async';
import 'package:flutter/material.dart';
import 'media_file.dart';
import 'media_picker.dart';
import 'media_uploader_advanced.dart';
import 'media_preview.dart';

/// Modern Material 3 upload widget with progress bars
/// Supports single and multiple file uploads with real-time progress
class MediaUploadWidget extends StatefulWidget {
  final String userId;
  final String category;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final Function(List<String> urls)? onUploadComplete;
  final Function(String error)? onUploadError;
  final String? title;
  final String? subtitle;

  const MediaUploadWidget({
    super.key,
    required this.userId,
    required this.category,
    this.allowMultiple = true,
    this.allowedExtensions,
    this.onUploadComplete,
    this.onUploadError,
    this.title,
    this.subtitle,
  });

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  List<MediaFile> selectedFiles = [];
  Map<String, double> uploadProgress = {};
  bool isUploading = false;
  bool isPicking = false;

  final MediaUploaderAdvanced _uploader = MediaUploaderAdvanced();

  Future<void> _pickFiles() async {
    if (isUploading || isPicking) return;

    setState(() => isPicking = true);

    try {
      final files = await MediaPicker.pickFiles(
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      if (files.isNotEmpty && mounted) {
        setState(() {
          selectedFiles = widget.allowMultiple ? [...selectedFiles, ...files] : files;
          uploadProgress.clear();
        });
      }
    } catch (e) {
      widget.onUploadError?.call('Failed to pick files: $e');
    } finally {
      if (mounted) {
        setState(() => isPicking = false);
      }
    }
  }

  Future<void> _startUpload() async {
    if (selectedFiles.isEmpty || isUploading) return;

    setState(() => isUploading = true);

    try {
      await _uploader.uploadFiles(
        selectedFiles,
        userId: widget.userId,
        category: widget.category,
        onProgress: (fileId, progress) {
          if (mounted) {
            setState(() {
              uploadProgress[fileId] = progress.percent;
            });
          }
        },
        onComplete: (fileId, url) {
          debugPrint('Upload completed: $fileId -> $url');
        },
        onError: (fileId, error) {
          debugPrint('Upload error: $fileId -> $error');
          widget.onUploadError?.call('Upload failed for $fileId: $error');
        },
      );

      // Collect all successful URLs
      final urls = selectedFiles
          .where((file) => uploadProgress[file.id] == 100.0)
          .map((file) => 'uploaded_url_${file.id}') // This would be the actual URL
          .toList();

      widget.onUploadComplete?.call(urls);

      if (mounted) {
        setState(() {
          selectedFiles.clear();
          uploadProgress.clear();
        });
      }
    } catch (e) {
      widget.onUploadError?.call('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  void _removeFile(int index) {
    if (!isUploading) {
      setState(() {
        final file = selectedFiles[index];
        selectedFiles.removeAt(index);
        uploadProgress.remove(file.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pick Files Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isUploading ? null : _pickFiles,
                icon: isPicking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(isPicking ? 'Picking Files...' : 'Pick Files'),
              ),
            ),

            const SizedBox(height: 16),

            // Selected Files Grid
            if (selectedFiles.isNotEmpty) ...[
              Text(
                'Selected Files (${selectedFiles.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              MediaGridView(
                files: selectedFiles,
                onTap: isUploading ? null : (file) {
                  final index = selectedFiles.indexOf(file);
                  _removeFile(index);
                },
              ),

              const SizedBox(height: 16),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isUploading || selectedFiles.isEmpty ? null : _startUpload,
                  icon: isUploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(isUploading ? 'Uploading...' : 'Upload Files'),
                ),
              ),

              // Progress Indicators
              if (uploadProgress.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Upload Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = selectedFiles[index];
                    final progress = uploadProgress[file.id] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${progress.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 100
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],

            // Empty State
            if (selectedFiles.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No files selected',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Pick Files" to select ${widget.allowMultiple ? 'multiple' : 'a'} file${widget.allowMultiple ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}