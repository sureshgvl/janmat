import 'dart:async';
import 'package:flutter/material.dart';
import 'media_file.dart';
import 'media_picker.dart';
import 'media_uploader_advanced.dart';
import 'media_preview.dart';

/// Gallery-style uploader for multiple files with thumbnails
/// Instagram/WhatsApp-style interface with grid layout
class GalleryUploaderWidget extends StatefulWidget {
  final String userId;
  final String category;
  final int maxFiles;
  final List<String>? allowedExtensions;
  final Function(List<String> urls)? onUploadComplete;
  final Function(String error)? onUploadError;

  const GalleryUploaderWidget({
    super.key,
    required this.userId,
    required this.category,
    this.maxFiles = 10,
    this.allowedExtensions,
    this.onUploadComplete,
    this.onUploadError,
  });

  @override
  State<GalleryUploaderWidget> createState() => _GalleryUploaderWidgetState();
}

class _GalleryUploaderWidgetState extends State<GalleryUploaderWidget> {
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
        allowMultiple: true,
      );

      if (files.isNotEmpty && mounted) {
        setState(() {
          // Limit to maxFiles
          final availableSlots = widget.maxFiles - selectedFiles.length;
          final filesToAdd = files.take(availableSlots);
          selectedFiles.addAll(filesToAdd);
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
          debugPrint('Gallery upload completed: $fileId -> $url');
        },
        onError: (fileId, error) {
          debugPrint('Gallery upload error: $fileId -> $error');
          widget.onUploadError?.call('Upload failed for $fileId: $error');
        },
      );

      // Collect successful uploads
      final urls = selectedFiles
          .where((file) => uploadProgress[file.id] == 100.0)
          .map((file) => 'uploaded_url_${file.id}')
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery Upload (${selectedFiles.length}/${widget.maxFiles})'),
        actions: [
          if (selectedFiles.isNotEmpty && !isUploading)
            TextButton.icon(
              onPressed: _startUpload,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add Files Button
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (isUploading || selectedFiles.length >= widget.maxFiles)
                    ? null
                    : _pickFiles,
                icon: isPicking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(
                  selectedFiles.length >= widget.maxFiles
                      ? 'Maximum files reached'
                      : isPicking
                          ? 'Picking files...'
                          : 'Add Files',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: colorScheme.outline),
                ),
              ),
            ),
          ),

          // Files Grid
          Expanded(
            child: selectedFiles.isEmpty
                ? _buildEmptyState(theme, colorScheme)
                : _buildFilesGrid(theme, colorScheme),
          ),

          // Upload Progress Summary
          if (isUploading || uploadProgress.isNotEmpty)
            _buildProgressSummary(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No files selected',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Files" to select photos, videos, or documents',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesGrid(ThemeData theme, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: selectedFiles.length,
      itemBuilder: (context, index) {
        final file = selectedFiles[index];
        final progress = uploadProgress[file.id] ?? 0.0;

        return _buildFileItem(file, index, progress, theme, colorScheme);
      },
    );
  }

  Widget _buildFileItem(
    MediaFile file,
    int index,
    double progress,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Stack(
      children: [
        // File Preview
        GestureDetector(
          onTap: isUploading ? null : () => _removeFile(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: progress == 100
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: progress == 100 ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: buildMediaPreview(file, size: double.infinity),
            ),
          ),
        ),

        // Progress Overlay
        if (progress > 0 && progress < 100)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Remove Button
        if (!isUploading)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Success Checkmark
        if (progress == 100)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSummary(ThemeData theme, ColorScheme colorScheme) {
    final completed = uploadProgress.values.where((p) => p == 100).length;
    final total = selectedFiles.length;
    final overallProgress = total > 0 ? (completed / total) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isUploading
                      ? 'Uploading files...'
                      : 'Upload Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$completed/$total completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: overallProgress / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
      ),
    );
  }
}