import 'package:flutter/material.dart';
import 'media_file.dart';
import 'media_preview.dart';
import 'media_upload_handler.dart';

/// Example usage of the generalized media upload system
class MediaUploadExample extends StatefulWidget {
  const MediaUploadExample({super.key});

  @override
  State<MediaUploadExample> createState() => _MediaUploadExampleState();
}

class _MediaUploadExampleState extends State<MediaUploadExample> {
  List<MediaFile> selectedFiles = [];
  Map<String, double> uploadProgress = {};
  bool isUploading = false;

  final String userId = 'example_user_id';
  final String category = 'example_category';

  /// Pick multiple media files
  Future<void> _pickFiles() async {
    final handler = MediaUploadHandler(
      context: context,
      userId: userId,
      category: category,
    );

    final files = await handler.pickMediaFiles(allowMultiple: true);
    if (files.isNotEmpty) {
      setState(() {
        selectedFiles = files;
        uploadProgress.clear();
      });
    }
  }

  /// Upload files with basic progress
  Future<void> _uploadBasic() async {
    if (selectedFiles.isEmpty) return;

    setState(() => isUploading = true);

    try {
      final handler = MediaUploadHandler(
        context: context,
        userId: userId,
        category: category,
      );

      final urls = await handler.uploadMediaFiles(selectedFiles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${urls.length} files successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  /// Upload files with advanced progress tracking
  Future<void> _uploadAdvanced() async {
    if (selectedFiles.isEmpty) return;

    setState(() => isUploading = true);

    try {
      final handler = MediaUploadHandler(
        context: context,
        userId: userId,
        category: category,
      );

      await handler.uploadMediaFilesAdvanced(
        selectedFiles,
        onProgress: (fileId, progress) {
          if (mounted) {
            setState(() {
              uploadProgress[fileId] = progress.percent;
            });
          }
        },
        onComplete: (fileId, url) {
          debugPrint('Completed: $fileId -> $url');
        },
        onError: (fileId, error) {
          debugPrint('Error: $fileId -> $error');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advanced upload completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Advanced upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Upload Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Action buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: isUploading ? null : _pickFiles,
                  child: const Text('Pick Files'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isUploading || selectedFiles.isEmpty ? null : _uploadBasic,
                  child: const Text('Upload Basic'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isUploading || selectedFiles.isEmpty ? null : _uploadAdvanced,
                  child: const Text('Upload Advanced'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Selected files preview
            if (selectedFiles.isNotEmpty) ...[
              Text('Selected Files (${selectedFiles.length}):'),
              const SizedBox(height: 10),
              Expanded(
                child: MediaGridView(
                  files: selectedFiles,
                  onTap: (file) {
                    // Handle file tap
                    debugPrint('Tapped: ${file.name}');
                  },
                ),
              ),

              // Upload progress indicators
              if (uploadProgress.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Upload Progress:'),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = selectedFiles[index];
                      final progress = uploadProgress[file.id] ?? 0.0;

                      return ListTile(
                        leading: buildMediaPreview(file, size: 40.0),
                        title: Text(file.name),
                        subtitle: Text('${file.type} • ${(file.size / 1024).toStringAsFixed(1)} KB'),
                        trailing: SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: progress / 100,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text('No files selected'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}