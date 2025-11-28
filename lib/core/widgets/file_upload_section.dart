// lib/core/widgets/file_upload_section.dart
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:janmat/core/models/unified_file.dart';
import 'package:janmat/core/services/file_picker_helper.dart';
import 'package:janmat/core/services/firebase_uploader.dart';
import 'package:janmat/core/services/cache_service.dart';
import 'package:janmat/utils/app_logger.dart';
import '../../l10n/app_localizations.dart';

/// A unified file upload section widget that works across web and mobile platforms.
/// Integrates FilePickerHelper + FirebaseUploader + CacheService for seamless cross-platform file handling.
class FileUploadSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> allowedExtensions;
  final int maxFileSize;
  final int maxFiles;
  final UnifiedFileType fileType;
  final Function(List<UnifiedFile>) onFilesSelected;
  final Function(String? uploadedUrl) onUploadComplete;
  final String storagePath;
  final String? existingFileUrl;
  final bool showPreview;
  final Widget? customButton;
  final Widget? customPreview;

  const FileUploadSection({
    super.key,
    required this.title,
    this.subtitle,
    this.allowedExtensions = const [],
    this.maxFileSize = 50,
    this.maxFiles = 1,
    this.fileType = UnifiedFileType.any,
    required this.onFilesSelected,
    required this.onUploadComplete,
    required this.storagePath,
    this.existingFileUrl,
    this.showPreview = true,
    this.customButton,
    this.customPreview,
  });

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  List<UnifiedFile> _selectedFiles = [];
  bool _isUploading = false;
  double? _uploadProgress;
  String? _uploadError;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    // Pre-populate existing file if provided
    if (widget.existingFileUrl != null && widget.showPreview) {
      _uploadedUrl = widget.existingFileUrl;
    }
  }

  @override
  void didUpdateWidget(FileUploadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update uploaded URL when existingFileUrl changes
    if (widget.existingFileUrl != oldWidget.existingFileUrl) {
      setState(() {
        _uploadedUrl = widget.existingFileUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Subtitle
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Upload Area or Preview
            if (_uploadedUrl != null && widget.showPreview)
              _buildPreview()
            else
              _buildUploadArea(),

            // File List (if multiple)
            if (_selectedFiles.isNotEmpty) _buildFileList(),

            // Error Message
            if (_uploadError != null) ...[
              const SizedBox(height: 8),
              Text(
                _uploadError!,
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isUploading ? Colors.blue[300]! : Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _isUploading ? Colors.blue[50] : Colors.grey[50],
      ),
      child: InkWell(
        onTap: _isUploading ? null : _pickFiles,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isUploading ? Icons.cloud_upload : Icons.add_photo_alternate,
              size: 32,
              color: _isUploading ? Colors.blue[600] : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              _isUploading ? localizations.uploadingText : localizations.tapToSelectFiles,
              style: TextStyle(
                color: _isUploading ? Colors.blue[600] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.allowedExtensions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${localizations.allowedExtensionsText}${widget.allowedExtensions.join(", ")}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              '${localizations.maxSizeText}${widget.maxFileSize}MB${widget.maxFiles > 1 ? " (max ${widget.maxFiles} ${localizations.filesText})" : ""}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVeryNarrow = constraints.maxWidth < 50; // Very narrow threshold
          final isNarrow = constraints.maxWidth < 200; // Narrow threshold

          if (isVeryNarrow) {
            // Minimal layout for extremely narrow screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        localizations.uploadedText,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _uploadedUrl = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          } else if (isNarrow) {
            // Stack layout for narrow screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.fileUploadedSuccessfully,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _uploadedUrl = null;
                        });
                      },
                    ),
                  ),
                ),
                if (widget.customPreview != null)
                  widget.customPreview!
                else if (kIsWeb && _uploadedUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _uploadedUrl!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            );
          } else {
            // Horizontal layout for wider screens
            return Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.fileUploadedSuccessfully,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _uploadedUrl = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.customPreview != null)
                  widget.customPreview!
                else if (kIsWeb && _uploadedUrl != null && widget.fileType == UnifiedFileType.image)
                  // Show image preview on web for image files
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: Image.network(
                      _uploadedUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          localizations.failedToLoadImage,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  )
                else if (kIsWeb && _uploadedUrl != null)
                  Text(
                    _uploadedUrl!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFileList() {
    return Column(
      children: _selectedFiles.map((file) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(FilePickerHelper.getFileTypeIcon(file)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      FilePickerHelper.formatFileSize(file.size),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: _uploadProgress,
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedFiles.remove(file);
                    });
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickFiles() async {
    try {
      setState(() {
        _uploadError = null;
      });

      List<UnifiedFile> files;

      if (widget.maxFiles == 1) {
        final file = await FilePickerHelper.pickSingle(
          allowedExtensions: widget.allowedExtensions.isNotEmpty
              ? widget.allowedExtensions
              : null,
          maxFileSize: widget.maxFileSize,
          fileType: widget.fileType,
        );

        if (file != null) {
          files = [file];
        } else {
          return; // User cancelled
        }
      } else {
        files = await FilePickerHelper.pickMultiple(
          allowedExtensions: widget.allowedExtensions.isNotEmpty
              ? widget.allowedExtensions
              : null,
          maxFileSize: widget.maxFileSize,
          maxFiles: widget.maxFiles,
          fileType: widget.fileType,
        );
      }

      setState(() {
        _selectedFiles = files;
      });

      // Notify parent of file selection
      widget.onFilesSelected(files);

      // Auto-upload if only one file
      if (widget.maxFiles == 1) {
        _uploadFiles(files);
      }
    } catch (e) {
      setState(() {
        _uploadError = AppLocalizations.of(context)!.fileSelectionFailed(e.toString());
      });
      AppLogger.core('FileUploadSection: File selection error: $e');
    }
  }

  Future<void> _uploadFiles(List<UnifiedFile> files) async {
    if (files.isEmpty) return;

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadError = null;
      });

      if (files.length == 1) {
        // Single file upload
        final url = await FirebaseUploader.uploadUnifiedFile(
          f: files.first,
          storagePath: widget.storagePath,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress / 100; // Convert to 0.0-1.0
            });
          },
        );

        if (url != null) {
          setState(() {
            _uploadedUrl = url;
            _isUploading = false;
          });

          widget.onUploadComplete(url);
          AppLogger.core('FileUploadSection: File uploaded successfully: $url');
        } else {
          throw Exception(AppLocalizations.of(context)!.uploadFailedNoUrl);
        }
      } else {
        // Multiple file upload
        final urls = <String>[];
        var completedUploads = 0;

        for (var i = 0; i < files.length; i++) {
          final file = files[i];
          try {
            final url = await FirebaseUploader.uploadUnifiedFile(
              f: file,
              storagePath: '${widget.storagePath}_$i',
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress / 100;
                });
              },
            );

            if (url != null) {
              urls.add(url);
            }
            completedUploads++;
          } catch (e) {
            AppLogger.core('FileUploadSection: Failed to upload ${file.name}: $e');
            completedUploads++;
          }
        }

        setState(() {
          _isUploading = false;
          if (urls.isNotEmpty) {
            _uploadedUrl = urls.first;
            if (urls.length < files.length) {
              _uploadError = AppLocalizations.of(context)!.uploadsFailed((files.length - urls.length).toString());
            }
          } else {
            _uploadError = AppLocalizations.of(context)!.allUploadsFailed;
          }
        });

        if (urls.isNotEmpty) {
          widget.onUploadComplete(urls.first);
          AppLogger.core('FileUploadSection: ${urls.length}/${files.length} files uploaded successfully');
        } else {
          throw Exception(AppLocalizations.of(context)!.allFileUploadsFailed);
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = AppLocalizations.of(context)!.uploadFailed(e.toString());
      });
      AppLogger.coreError('FileUploadSection: Upload error', error: e);
    }
  }
}

/// Convenience widget for common file upload scenarios
class ImageUploadSection extends StatelessWidget {
  final String title;
  final String storagePath;
  final Function(String? imageUrl) onImageSelected;
  final String? existingImageUrl;
  final int maxFileSize;
  final bool allowCamera;

  const ImageUploadSection({
    super.key,
    required this.title,
    required this.storagePath,
    required this.onImageSelected,
    this.existingImageUrl,
    this.maxFileSize = 10,
    this.allowCamera = true,
  });

  @override
  Widget build(BuildContext context) {
    return FileUploadSection(
      title: title,
      storagePath: storagePath,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      maxFileSize: maxFileSize,
      fileType: UnifiedFileType.image,
      existingFileUrl: existingImageUrl,
      onFilesSelected: (files) {
        // Images only upload one at a time
      },
      onUploadComplete: onImageSelected,
    );
  }
}

class DocumentUploadSection extends StatelessWidget {
  final String title;
  final String storagePath;
  final Function(String? documentUrl) onDocumentSelected;
  final String? existingDocumentUrl;
  final List<String> allowedExtensions;

  const DocumentUploadSection({
    super.key,
    required this.title,
    required this.storagePath,
    required this.onDocumentSelected,
    this.existingDocumentUrl,
    this.allowedExtensions = const ['pdf', 'doc', 'docx'],
  });

  @override
  Widget build(BuildContext context) {
    return FileUploadSection(
      title: title,
      subtitle: AppLocalizations.of(context)!.uploadDocumentsSubtitle,
      storagePath: storagePath,
      allowedExtensions: allowedExtensions,
      maxFileSize: 25,
      fileType: UnifiedFileType.pdf,
      existingFileUrl: existingDocumentUrl,
      showPreview: true,
      onFilesSelected: (files) {
        // Documents upload one at a time
      },
      onUploadComplete: onDocumentSelected,
    );
  }
}
