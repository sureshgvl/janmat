import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../candidate/models/candidate_model.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_utils.dart';
import '../candidate/controllers/candidate_user_controller.dart';
import '../candidate/controllers/manifesto_controller.dart';
import './file_helpers.dart';
import './file_upload_handler.dart';
import './file_storage_manager.dart';
import '../../core/media/media_file.dart';
import '../../core/media/media_uploader_advanced.dart';

/// FileUploadSection - Now uses clean composition of modular components
class FileUploadSection extends StatefulWidget {
  final Candidate candidateData;
  final bool isEditing;
  final Function(String) onManifestoPdfChange;
  final Function(String) onManifestoImageChange;
  final Function(String) onManifestoVideoChange;
  final Function(List<Map<String, dynamic>>) onLocalFilesUpdate;
  final String? existingPdfUrl;
  final String? existingImageUrl;
  final String? existingVideoUrl;
  final Function(String, bool)? onFileMarkedForDeletion;

  const FileUploadSection({
    super.key,
    required this.candidateData,
    required this.isEditing,
    required this.onManifestoPdfChange,
    required this.onManifestoImageChange,
    required this.onManifestoVideoChange,
    required this.onLocalFilesUpdate,
    this.existingPdfUrl,
    this.existingImageUrl,
    this.existingVideoUrl,
    this.onFileMarkedForDeletion,
  });

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  // State tracking
  bool _isDeletingPdf = false;
  bool _isDeletingImage = false;
  bool _isDeletingVideo = false;
  bool _isUploadingAdvanced = false;
  final List<Map<String, dynamic>> _localFiles = [];
  final Map<String, UploadProgress> _uploadProgress = {};
  final Map<String, String> _uploadUrls = {};
  final Map<String, String> _uploadErrors = {};

  // Components
  late final FileUploadHandler _uploadHandler;
  late final FileStorageManager _storageManager;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    AppLogger.candidate('FileUploadSection initialized with composition');
  }

  void _initializeComponents() {
    _uploadHandler = FileUploadHandler(
      candidateData: widget.candidateData,
      context: context,
      localFiles: _localFiles,
      onLocalFilesUpdate: _handleLocalFilesUpdate,
    );

    _storageManager = FileStorageManager();
  }

  void _handleLocalFilesUpdate(List<Map<String, dynamic>> files) {
    //AppLogger.candidate('🔄 [FileUploadSection] _handleLocalFilesUpdate called with ${files.length} files');
    // AppLogger.candidate('🔄 [FileUploadSection] Files content: $files'); // COMMENTED OUT - HIDES BYTES LOG
    //AppLogger.candidate('🔄 [FileUploadSection] Before clear: _localFiles has ${_localFiles.length} files');

    setState(() {
      _localFiles.clear();
      _localFiles.addAll(files);

      //AppLogger.candidate('🔄 [FileUploadSection] Inside setState: _localFiles now has ${_localFiles.length} files');
      // for (var i = 0; i < _localFiles.length; i++) {
      //   AppLogger.candidate('🔄 [FileUploadSection] File $i: ${_localFiles[i]}'); // COMMENTED OUT - HIDES BYTES LOG
      // }
    });

    widget.onLocalFilesUpdate(_localFiles); // Pass the actual _localFiles, not the parameter
    //AppLogger.candidate('🔄 [FileUploadSection] Final: _localFiles has ${_localFiles.length} files, hasImageLocal: ${_localFiles.any((f) => f['type'] == 'image')}');
  }

  /// Handle PDF deletion with UI updates - OPTIMIZED for speed
  Future<void> _handlePdfDeletion() async {
    final fileUrl = widget.existingPdfUrl ?? '';
    if (fileUrl.isEmpty) {
      AppLogger.candidate('❌ [PDF Delete] No PDF URL to delete');
      return;
    }

    setState(() => _isDeletingPdf = true);

    try {
      AppLogger.candidate('🗑️ [PDF Delete] Starting optimized deletion process...');

      // Step 1: Delete from Firebase Storage (fast operation)
      final success = await _storageManager.deleteFromStorage(fileUrl);
      if (!success) throw Exception('Failed to delete from storage');

      AppLogger.candidate('✅ [PDF Delete] File deleted from storage');

      // Step 2: Update Firestore directly (avoid triggering full app refresh)
      final manifestoController = Get.find<ManifestoController>();
      await manifestoController.updateManifestoUrls(widget.candidateData, pdfUrl: '');

      AppLogger.candidate('✅ [PDF Delete] Firestore updated');

      // Step 3: Update local UI state only (no controller updates that trigger refresh)
      widget.onManifestoPdfChange('');

      if (mounted) {
        SnackbarUtils.showScaffoldSuccess(context, 'PDF file deleted successfully');
      }

      AppLogger.candidate('✅ [PDF Delete] PDF successfully deleted from storage and database');

    } catch (e) {
      AppLogger.candidateError('❌ [PDF Delete] Failed to delete PDF: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to delete PDF file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDeletingPdf = false);
    }
  }

  /// Handle image deletion with UI updates - OPTIMIZED for speed
  Future<void> _handleImageDeletion() async {
    final fileUrl = widget.existingImageUrl ?? '';
    if (fileUrl.isEmpty) {
      AppLogger.candidate('❌ [Image Delete] No image URL to delete');
      return;
    }

    setState(() => _isDeletingImage = true);

    try {
      AppLogger.candidate('🗑️ [Image Delete] Starting optimized deletion process...');

      // Step 1: Delete from Firebase Storage (fast operation)
      final success = await _storageManager.deleteFromStorage(fileUrl);
      if (!success) throw Exception('Failed to delete from storage');

      AppLogger.candidate('✅ [Image Delete] File deleted from storage');

      // Step 2: Update Firestore directly (avoid triggering full app refresh)
      final manifestoController = Get.find<ManifestoController>();
      await manifestoController.updateManifestoUrls(widget.candidateData, imageUrl: '');

      AppLogger.candidate('✅ [Image Delete] Firestore updated');

      // Step 3: Update local UI state only (no controller updates that trigger refresh)
      widget.onManifestoImageChange('');

      if (mounted) {
        SnackbarUtils.showScaffoldSuccess(context, 'Image file deleted successfully');
      }

      AppLogger.candidate('✅ [Image Delete] Image successfully deleted from storage and database');

    } catch (e) {
      AppLogger.candidateError('❌ [Image Delete] Failed to delete image: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to delete image file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDeletingImage = false);
    }
  }

  /// Handle video deletion with UI updates - OPTIMIZED for speed
  Future<void> _handleVideoDeletion() async {
    final fileUrl = widget.existingVideoUrl ?? '';
    if (fileUrl.isEmpty) {
      AppLogger.candidate('❌ [Video Delete] No video URL to delete');
      return;
    }

    setState(() => _isDeletingVideo = true);

    try {
      AppLogger.candidate('🗑️ [Video Delete] Starting optimized deletion process...');

      // Step 1: Delete from Firebase Storage (fast operation)
      final success = await _storageManager.deleteFromStorage(fileUrl);
      if (!success) throw Exception('Failed to delete from storage');

      AppLogger.candidate('✅ [Video Delete] File deleted from storage');

      // Step 2: Update Firestore directly (avoid triggering full app refresh)
      final manifestoController = Get.find<ManifestoController>();
      await manifestoController.updateManifestoUrls(widget.candidateData, videoUrl: '');

      AppLogger.candidate('✅ [Video Delete] Firestore updated');

      // Step 3: Update local UI state only (no controller updates that trigger refresh)
      widget.onManifestoVideoChange('');

      if (mounted) {
        SnackbarUtils.showScaffoldSuccess(context, 'Video file deleted successfully');
      }

      AppLogger.candidate('✅ [Video Delete] Video successfully deleted from storage and database');

    } catch (e) {
      AppLogger.candidateError('❌ [Video Delete] Failed to delete video: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to delete video file. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDeletingVideo = false);
    }
  }

  /// Convert local files to MediaFile objects for advanced uploading
  List<MediaFile> _convertToMediaFiles() {
    return _localFiles.map((fileEntry) {
      final fileName = fileEntry['fileName'] as String? ?? 'unknown';
      final fileType = fileEntry['type'] as String? ?? 'other';
      final fileSize = (fileEntry['fileSize'] as num?)?.toInt() ?? 0;
      final bytes = fileEntry['bytes'] as Uint8List?;

      return MediaFile(
        id: '${fileType}_${DateTime.now().millisecondsSinceEpoch}_${_localFiles.indexOf(fileEntry)}',
        name: fileName,
        type: fileType,
        bytes: bytes ?? Uint8List(0),
        size: fileSize,
      );
    }).toList();
  }

  /// Upload all pending files using advanced uploader with progress tracking
  Future<Map<String, String>> uploadPendingFilesAdvanced() async {
    if (_localFiles.isEmpty) return {};

    setState(() {
      _isUploadingAdvanced = true;
      _uploadProgress.clear();
      _uploadUrls.clear();
      _uploadErrors.clear();
    });

    try {
      AppLogger.candidate('🚀 [Advanced File Upload] Starting upload with progress tracking...');

      // Convert local files to MediaFile objects
      final mediaFiles = _convertToMediaFiles();

      // Create advanced uploader
      final uploader = MediaUploaderAdvanced();

      // Show progress dialog
      if (mounted) {
        _showAdvancedUploadDialog(mediaFiles.length);
      }

      // Upload with progress callbacks
      final urls = await uploader.uploadFiles(
        mediaFiles,
        userId: widget.candidateData.candidateId,
        category: 'manifesto',
        onProgress: (fileId, progress) {
          if (mounted) {
            setState(() => _uploadProgress[fileId] = progress);
          }
        },
        onComplete: (fileId, url) {
          if (mounted) {
            setState(() => _uploadUrls[fileId] = url);
            AppLogger.candidate('✅ [Advanced Upload] Completed: $fileId -> $url');
          }
        },
        onError: (fileId, error) {
          if (mounted) {
            setState(() => _uploadErrors[fileId] = error);
            AppLogger.candidate('❌ [Advanced Upload] Error: $fileId -> $error');
          }
        },
      );

      // Update Firestore with uploaded URLs
      await _updateFirestoreWithUrls(urls);

      // Clear local files after successful upload
      if (mounted) {
        setState(() => _localFiles.clear());
        widget.onLocalFilesUpdate([]);
      }

      // Close progress dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      AppLogger.candidate('🎉 [Advanced File Upload] All files uploaded successfully!');
      return _uploadUrls;

    } catch (e) {
      AppLogger.candidateError('❌ [Advanced File Upload] Failed: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Upload failed: ${e.toString()}');
      }
      return {};
    } finally {
      if (mounted) {
        setState(() => _isUploadingAdvanced = false);
      }
    }
  }

  /// Show advanced upload progress dialog
  void _showAdvancedUploadDialog(int totalFiles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Uploading Files'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Uploading $totalFiles file${totalFiles > 1 ? 's' : ''}...'),
                const SizedBox(height: 16),
                ..._uploadProgress.entries.map((entry) {
                  final fileId = entry.key;
                  final progress = entry.value;
                  final fileName = _getFileNameFromId(fileId);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: progress.percent / 100),
                        const SizedBox(height: 2),
                        Text(
                          '${progress.percent.toStringAsFixed(1)}% • '
                          '${progress.speedKBps.toStringAsFixed(1)} KB/s • '
                          '${progress.eta.inMinutes}:${(progress.eta.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),
                if (_uploadErrors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Errors:',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  ..._uploadErrors.entries.map((entry) => Text(
                    '${_getFileNameFromId(entry.key)}: ${entry.value}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            if (_isUploadingAdvanced)
              TextButton(
                onPressed: () {
                  // TODO: Implement cancel functionality when MediaUploaderAdvanced supports it
                  // For now, just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cancel functionality coming soon')),
                  );
                },
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: _isUploadingAdvanced ? null : () => Navigator.of(context).pop(),
              child: Text(_isUploadingAdvanced ? 'Uploading...' : 'Close'),
            ),
          ],
        ),
      ),
    );
  }

  /// Get filename from file ID
  String _getFileNameFromId(String fileId) {
    // Extract filename from the file ID pattern: type_timestamp_index
    final parts = fileId.split('_');
    if (parts.length >= 3) {
      final index = int.tryParse(parts.last) ?? 0;
      if (index < _localFiles.length) {
        return _localFiles[index]['fileName'] as String? ?? 'Unknown file';
      }
    }
    return 'File';
  }

  /// Update Firestore with uploaded URLs
  Future<void> _updateFirestoreWithUrls(List<String> urls) async {
    try {
      final manifestoController = Get.find<ManifestoController>();

      // Map URLs to file types
      String? pdfUrl, imageUrl, videoUrl;

      for (int i = 0; i < urls.length && i < _localFiles.length; i++) {
        final fileEntry = _localFiles[i];
        final url = urls[i];
        final fileType = fileEntry['type'] as String?;

        switch (fileType) {
          case 'pdf':
            pdfUrl = url;
            break;
          case 'image':
            imageUrl = url;
            break;
          case 'video':
            videoUrl = url;
            break;
        }
      }

      // Update Firestore
      await manifestoController.updateManifestoUrls(
        widget.candidateData,
        pdfUrl: pdfUrl,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );

      // Update local state
      final candidateController = Get.find<CandidateUserController>();
      if (pdfUrl != null) {
        candidateController.updateManifestoInfo('pdfUrl', pdfUrl);
        widget.onManifestoPdfChange(pdfUrl);
      }
      if (imageUrl != null) {
        candidateController.updateManifestoInfo('image', imageUrl);
        widget.onManifestoImageChange(imageUrl);
      }
      if (videoUrl != null) {
        candidateController.updateManifestoInfo('videoUrl', videoUrl);
        widget.onManifestoVideoChange(videoUrl);
      }

    } catch (e) {
      AppLogger.candidateError('❌ [Firestore Update] Failed to update URLs: $e');
      rethrow;
    }
  }

  /// Legacy method for backward compatibility - now uses advanced uploader
  Future<Map<String, String>> uploadPendingFiles() async {
    return await uploadPendingFilesAdvanced();
  }

  // Build row methods with better visual feedback
  Widget _buildPdfRow() {
    final hasPdfInDb = widget.existingPdfUrl != null && widget.existingPdfUrl!.isNotEmpty;
    final hasPdfLocal = _localFiles.any((f) => f['type'] == 'pdf');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasPdfLocal ? Colors.orange.shade50 : hasPdfInDb ? Colors.red.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPdfLocal ? Colors.orange.shade300 : hasPdfInDb ? Colors.red.shade300 : Colors.red.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: hasPdfLocal ? Colors.orange.shade700 : hasPdfInDb ? Colors.red.shade700 : Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPdfLocal) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'PDF Selected for Upload',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Will Save',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _localFiles.firstWhere((f) => f['type'] == 'pdf', orElse: () => {})['fileName'] ?? 'PDF selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ] else if (hasPdfInDb) ...[
                      Text(
                        'PDF File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        FileHelpers.getFileNameFromUrl(widget.existingPdfUrl ?? ''),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'No PDF Selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasPdfInDb || hasPdfLocal) ...[
                SizedBox(
                  width: hasPdfInDb ? 140 : 100, // Constrain button width
                  child: ElevatedButton.icon(
                    onPressed: _uploadHandler.uploadManifestoPdf,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasPdfLocal ? Colors.orange.shade600 : Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (hasPdfInDb) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isDeletingPdf ? null : _handlePdfDeletion,
                    icon: _isDeletingPdf
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete PDF',
                    constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                  ),
                ],
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _uploadHandler.uploadManifestoPdf,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow() {
    final hasImageInDb = widget.existingImageUrl != null && widget.existingImageUrl!.isNotEmpty;
    final hasImageLocal = _localFiles.any((f) => f['type'] == 'image');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasImageLocal ? Colors.orange.shade50 : hasImageInDb ? Colors.green.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasImageLocal ? Colors.orange.shade300 : hasImageInDb ? Colors.green.shade300 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected image preview when local file exists
          if (hasImageLocal) ...[
            // Image preview with controls
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image thumbnail container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildImageThumbnail(),
                  ),
                ),
                const SizedBox(width: 12),
                // Content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and info row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Image Selected for Upload',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Will Save',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Filename and size
                      Text(
                        '${((_localFiles.firstWhere((f) => f['type'] == 'image', orElse: () => {})['fileName'] as String?)?.isNotEmpty ?? false) ? _localFiles.firstWhere((f) => f['type'] == 'image', orElse: () => {})['fileName'] : 'Image selected'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '(${(_localFiles.firstWhere((f) => f['type'] == 'image', orElse: () => {})['fileSize'] as double? ?? 0.0) > 0 ? (_localFiles.firstWhere((f) => f['type'] == 'image', orElse: () => {})['fileSize'] as double?)?.toStringAsFixed(1) ?? '0.0' : 'Processing...'}MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadHandler.uploadManifestoImage,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _localFiles.removeWhere((f) => f['type'] == 'image'));
                      widget.onLocalFilesUpdate(_localFiles);
                    },
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (hasImageInDb) ...[
            // Existing uploaded image display
            Row(
              children: [
                // Image thumbnail container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      widget.existingImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.green.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Uploaded',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Successfully saved to manifesto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140, // Constrain button width
                  child: ElevatedButton.icon(
                    onPressed: _uploadHandler.uploadManifestoImage,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isDeletingImage ? null : _handleImageDeletion,
                  icon: _isDeletingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Image',
                  constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                ),
              ],
            ),
          ] else ...[
            // No image selected - show choose button
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Colors.green.shade700,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Image Selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        'Add an image to your manifesto (Gold+ plan required)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadHandler.uploadManifestoImage,
                  icon: const Icon(Icons.photo_camera, size: 16),
                  label: const Text('Choose Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Build image thumbnail for local files
  Widget _buildImageThumbnail() {
    final imageEntry = _localFiles.firstWhere((f) => f['type'] == 'image', orElse: () => {});

    // PRIORITY 1: Check if we have image bytes (stored during web upload)
    final bytes = imageEntry['bytes'] as Uint8List?;
    if (bytes != null && bytes.isNotEmpty) {
      // AppLogger.candidate('🖼️ [THUMBNAIL] Using memory bytes (${bytes.length} bytes)'); // COMMENTED OUT - HIDES BYTES LOG
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.orange.shade300, size: 40),
      );
    }

    // PRIORITY 2: Check if we have a local file path
    final localPath = imageEntry['localPath'] as String?;
    if (localPath != null && localPath.isNotEmpty) {
      // Check if it's a web blob URL or data URL
      if (localPath.startsWith('blob:') || localPath.startsWith('data:')) {
        // Web file - try to show from network (blob URLs can work with Image.network)
        AppLogger.candidate('🖼️ [THUMBNAIL] Using blob URL: $localPath');
        return Image.network(
          localPath,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null ?
                progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null
            ));
          },
          errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.orange.shade300, size: 40),
        );
      } else if (!kIsWeb) {
        // Mobile file - show from local file path (only on mobile platforms)
        AppLogger.candidate('🖼️ [THUMBNAIL] Using file path: $localPath');
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.orange.shade300, size: 40),
        );
      } else {
        // On web with non-blob URLs (shouldn't happen with our setup), fallback to icon
        AppLogger.candidate('🖼️ [THUMBNAIL] Web non-blob URL: $localPath, using fallback icon');
        return Icon(Icons.image, color: Colors.orange.shade300, size: 40);
      }
    }

    // Fallback icon
    AppLogger.candidate('🖼️ [THUMBNAIL] No image data found, using fallback icon');
    return Icon(Icons.image, color: Colors.orange.shade300, size: 40);
  }

  Widget _buildVideoRow() {
    final hasVideoInDb = widget.existingVideoUrl != null && widget.existingVideoUrl!.isNotEmpty;
    final hasVideoLocal = _localFiles.any((f) => f['type'] == 'video');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasVideoLocal ? Colors.orange.shade50 : hasVideoInDb ? Colors.purple.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasVideoLocal ? Colors.orange.shade300 : hasVideoInDb ? Colors.purple.shade300 : Colors.purple.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected video preview when local file exists
          if (hasVideoLocal) ...[
            // Video preview with controls
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video thumbnail container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Icon(Icons.video_call, color: Colors.orange.shade300, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                // Content column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and info row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Video Selected for Upload',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Will Save',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Filename and size
                      Text(
                        '${((_localFiles.firstWhere((f) => f['type'] == 'video', orElse: () => {})['fileName'] as String?)?.isNotEmpty ?? false) ? _localFiles.firstWhere((f) => f['type'] == 'video', orElse: () => {})['fileName'] : 'Video selected'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '(${(_localFiles.firstWhere((f) => f['type'] == 'video', orElse: () => {})['fileSize'] as double? ?? 0.0) > 0 ? (_localFiles.firstWhere((f) => f['type'] == 'video', orElse: () => {})['fileSize'] as double?)?.toStringAsFixed(1) ?? '0.0' : 'Processing...'}MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadHandler.uploadManifestoVideo,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _localFiles.removeWhere((f) => f['type'] == 'video'));
                      widget.onLocalFilesUpdate(_localFiles);
                    },
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (hasVideoInDb) ...[
            // Existing uploaded video display
            Row(
              children: [
                // Video thumbnail container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Icon(Icons.video_call, color: Colors.purple.shade300, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Uploaded',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        'Premium feature active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140, // Constrain button width
                  child: ElevatedButton.icon(
                    onPressed: _uploadHandler.uploadManifestoVideo,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isDeletingVideo ? null : _handleVideoDeletion,
                  icon: _isDeletingVideo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Video',
                  constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                ),
              ],
            ),
          ] else ...[
            // No video selected - show choose button
            Row(
              children: [
                Icon(
                  Icons.video_call,
                  color: Colors.purple.shade700,
                  size: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Video Selected',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        'Video uploads require Gold+ plan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadHandler.uploadManifestoVideo,
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text('Choose Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PDF Upload Row
        _buildPdfRow(),

        const SizedBox(height: 8),

        // Image Upload Row
        _buildImageRow(),

        const SizedBox(height: 8),

        // Video Upload Row
        _buildVideoRow(),
      ],
    );
  }
}
