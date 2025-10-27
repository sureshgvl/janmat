import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:janmat/features/candidate/controllers/manifesto_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/manifesto_model.dart';
import 'package:janmat/features/candidate/widgets/edit/promise_management_section.dart';
import 'package:janmat/features/common/confirmation_dialog.dart';
import 'package:janmat/features/common/file_upload_section.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/l10n/app_localizations.dart';
import 'package:janmat/services/video_processing_service.dart';
import 'package:janmat/utils/app_logger.dart';


class ManifestoTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onManifestoChange;
  final Function(String) onManifestoPdfChange;
  final Function(String) onManifestoTitleChange;
  final Function(List<Map<String, dynamic>>) onManifestoPromisesChange;
  final Function(String) onManifestoImageChange;
  final Function(String) onManifestoVideoChange;

  const ManifestoTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onManifestoChange,
    required this.onManifestoPdfChange,
    required this.onManifestoTitleChange,
    required this.onManifestoPromisesChange,
    required this.onManifestoImageChange,
    required this.onManifestoVideoChange,
  });

  @override
  State<ManifestoTabEdit> createState() => ManifestoTabEditState();
}

class ManifestoTabEditState extends State<ManifestoTabEdit> {
  // Get controller reference for reactive data access
  CandidateUserController get _candidateController => CandidateUserController.to;

  final ManifestoController _manifestoController = Get.find<ManifestoController>();
  late TextEditingController _manifestoTextController;
  late TextEditingController _titleController;
  late List<Map<String, dynamic>> _promiseControllers;
  String? _originalText;
  List<Map<String, dynamic>> _localFiles = [];
  bool _isSaving = false;

  // Files marked for deletion (will be deleted on save)
  final Map<String, bool> _filesMarkedForDeletion = {
    'pdf': false,
    'image': false,
    'video': false,
  };

  // Store original URLs for safe deletion (captured when file deletion is marked)
  final Map<String, String> _originalUrlsBeforeDeletion = {};

  @override
  void initState() {
    super.initState();
    AppLogger.candidate('ManifestoTabEdit initState called');
    final data = _getData();
    _originalText = data.manifestoData?.title ?? '';
    _manifestoTextController = TextEditingController(text: _originalText);

    // Initialize title controller with model data
    final manifestoTitle = data.manifestoData?.title ?? '';
    _titleController = TextEditingController(
      text: _stripBoldMarkers(manifestoTitle),
    );

    // Initialize manifesto promises list with structured format from model
    final rawPromises = data.manifestoData?.promises ?? [];
    _promiseControllers = _initializeControllers(rawPromises);
    AppLogger.candidate('Initialized with ${_promiseControllers.length} promises');
  }

  @override
  void didUpdateWidget(ManifestoTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    AppLogger.candidate('ManifestoTabEdit didUpdateWidget called, isEditing: ${widget.isEditing}');
    final data = _getData();
    final newText = data.manifestoData?.title ?? '';
    if (_originalText != newText) {
      _originalText = newText;
      _manifestoTextController.text = newText;
    }

    final newTitle = data.manifestoData?.title ?? '';
    _titleController.text = _stripBoldMarkers(newTitle);

    // Only update promises if not in editing mode
    if (!widget.isEditing) {
      final rawPromises = data.manifestoData?.promises ?? [];
      _promiseControllers = _initializeControllers(rawPromises);
    } else {
      AppLogger.candidate('In editing mode, skipping promise updates');
    }
  }

  // Helper method to get data from controller (reactive)
  Candidate _getData() => _candidateController.editedData.value ?? widget.candidateData;

  // Helper method to initialize promise controllers
  List<Map<String, dynamic>> _initializeControllers(List<dynamic> rawPromises) {
    final manifestoPromises = rawPromises.map((promise) => promise as Map<String, dynamic>).toList();

    return manifestoPromises.map((promise) {
      final title = promise['title'] as String? ?? '';
      final points = promise['points'] as List<dynamic>? ?? <dynamic>[];
      return <String, dynamic>{
        'title': TextEditingController(text: _stripBoldMarkers(title)),
        'points': points.map((point) =>
            TextEditingController(text: _stripBoldMarkers(point.toString()))
        ).toList(),
      };
    }).toList();
  }

  void _showDemoTitleOptions() {
    String selectedLanguage = 'en';
    final wardId = widget.candidateData.location.wardId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.chooseManifestoTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Selection and title options...
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stripBoldMarkers(String s) {
    if (s.isEmpty) return s;
    final trimmed = s.trim();
    if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length >= 4) {
      return trimmed.substring(2, trimmed.length - 2).trim();
    }
    return trimmed.replaceAll('**', '').trim();
  }

  @override
  void dispose() {
    _manifestoTextController.dispose();
    _titleController.dispose();
    for (var controllerMap in _promiseControllers) {
      (controllerMap['title'] as TextEditingController?)?.dispose();
      for (var pointController in (controllerMap['points'] as List<TextEditingController>? ?? [])) {
        pointController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      AppLogger.candidate('🧹 [Local Storage] Cleaning up local file: $localPath');
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.candidate('🧹 [Local Storage] Local file deleted successfully');
      }
    } catch (e) {
      AppLogger.candidateError('🧹 [Local Storage] Error cleaning up local file: $e');
    }
  }

  // Sequential upload method to avoid race conditions
  Future<void> _uploadLocalFilesToFirebase() async {
    if (_localFiles.isEmpty) {
      AppLogger.candidate('☁️ [Sequential Upload] No local files to upload');
      return;
    }

    AppLogger.candidate('☁️ [Sequential Upload] Starting sequential upload for ${_localFiles.length} local files...');

    final uploadedUrls = <String, String>{};
    final filesToProcess = List<Map<String, dynamic>>.from(_localFiles); // Create a copy to avoid modification during iteration

    for (final localFile in filesToProcess) {
      try {
        final type = localFile['type'] as String;
        final localPath = localFile['localPath'] as String;
        final fileName = localFile['fileName'] as String;
        final isPremiumVideo = localFile['isPremium'] as bool? ?? false;

        // Check if we already uploaded a file of this type (safety net)
        if (uploadedUrls.containsKey(type)) {
          AppLogger.candidate('⚠️ [Sequential Upload] Already uploaded $type, skipping duplicate');
          await _cleanupLocalFile(localPath);
          continue;
        }

        AppLogger.candidate('☁️ [Sequential Upload] Processing $type file: $fileName');

        final file = File(localPath);
        String? uploadedUrl;

        // Handle video uploads with Cloudinary for premium users
        if (type == 'video' && isPremiumVideo) {
          uploadedUrl = await _uploadVideoFile(file, fileName, localPath);
        } else {
          uploadedUrl = await _uploadRegularFileToFirebase(file, localPath, fileName, type);
        }

        if (uploadedUrl != null) {
          uploadedUrls[type] = uploadedUrl;
          AppLogger.candidate('✅ [Sequential Upload] $type uploaded successfully');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$type uploaded and ready!'), backgroundColor: Colors.green),
            );
          }
        } else {
          AppLogger.candidate('❌ [Sequential Upload] Failed to upload $type, skipping');
        }

        await _cleanupLocalFile(localPath);
      } catch (e) {
        AppLogger.candidateError('☁️ [Sequential Upload] Error processing ${localFile['type']}: $e');
        // Don't break the loop - continue with other files
      }
    }

    // Clear local files after processing all
    setState(() => _localFiles.clear());

    if (uploadedUrls.isNotEmpty) {
      AppLogger.candidate('🔄 [Batch Update] Updating URLs: $uploadedUrls');
      await _batchUpdateManifestoUrls(uploadedUrls);
    } else {
      AppLogger.candidate('⚠️ [Sequential Upload] No files were successfully uploaded');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No files were uploaded successfully. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<String?> _uploadVideoFile(File file, String fileName, String localPath) async {
    try {
      final videoService = VideoProcessingService();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Processing premium video with multi-resolution optimization...'), backgroundColor: Colors.purple),
        );
      }

      final processedVideo = await videoService.uploadAndProcessVideo(
        file, widget.candidateData.userId ?? 'unknown_user',
        onProgress: (progress) => AppLogger.candidate('🎥 [Cloudinary Progress] ${progress.toStringAsFixed(1)}%'),
      );

      AppLogger.candidate('🎥 [Cloudinary Success] Video processed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium video processed and optimized! Available in ${processedVideo.resolutions.length} resolutions.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return processedVideo.originalUrl;
    } catch (cloudinaryError) {
      AppLogger.candidateError('🎥 [Cloudinary Error] $cloudinaryError');
      return await _uploadRegularFileToFirebase(file, localPath, fileName, 'video');
    }
  }

  Future<String?> _uploadRegularFileToFirebase(File file, String localPath, String fileName, String type) async {
    try {
      AppLogger.candidate('📄 [Firebase Upload] Uploading $type file: $fileName');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final firebaseFileName = '${type}_${timestamp}.${_getFileExtension(type)}';

      final storagePath = 'manifesto_files/$firebaseFileName';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(type),
          customMetadata: {
            'uploadedBy': widget.candidateData.userId ?? 'unknown',
            'uploadTime': DateTime.now().toIso8601String(),
            'fileType': type,
          },
        ),
      );

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        AppLogger.candidate('📄 [Firebase Upload] $type upload progress: ${progress.toStringAsFixed(1)}%');
      });

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.candidate('📄 [Firebase Upload] $type uploaded successfully');
      return downloadUrl;
    } catch (e) {
      AppLogger.candidateError('📄 [Firebase Upload] Failed to upload $type: $e');
      return null;
    }
  }

  // Batch update all URLs at once to avoid race conditions
  Future<void> _batchUpdateManifestoUrls(Map<String, String> uploadedUrls) async {
    try {
      AppLogger.candidate('🔄 [Batch URL Update] Updating manifesto URLs: $uploadedUrls');

      final controller = Get.find<ManifestoController>();
      final success = await controller.updateManifestoUrls(
        widget.candidateData,
        pdfUrl: uploadedUrls['pdf'],
        imageUrl: uploadedUrls['image'],
        videoUrl: uploadedUrls['video'],
      );

      if (success) {
        AppLogger.candidate('✅ [Batch URL Update] Manifesto URLs updated successfully');

        // Update the local data with the new URLs so getManifestoData() returns correct values
        // Only update if the URL is not null and not empty
        if (uploadedUrls['pdf'] != null && uploadedUrls['pdf']!.isNotEmpty) {
          widget.onManifestoPdfChange(uploadedUrls['pdf']!);
        }
        if (uploadedUrls['image'] != null && uploadedUrls['image']!.isNotEmpty) {
          widget.onManifestoImageChange(uploadedUrls['image']!);
        }
        if (uploadedUrls['video'] != null && uploadedUrls['video']!.isNotEmpty) {
          widget.onManifestoVideoChange(uploadedUrls['video']!);
        }

        await _refreshParentData();
      } else {
        AppLogger.candidate('❌ [Batch URL Update] Failed to update manifesto URLs');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Files uploaded but failed to save URLs'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      AppLogger.candidateError('❌ [Batch URL Update] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file URLs: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _refreshParentData() async {
    final manifestoData = getManifestoData();
    widget.onManifestoChange(manifestoData.toJson()['title'] ?? '');
  }

  String _getFileExtension(String type) {
    switch (type) {
      case 'pdf': return 'pdf';
      case 'image': return 'jpg';
      case 'video': return 'mp4';
      default: return 'tmp';
    }
  }

  String _getContentType(String type) {
    switch (type) {
      case 'pdf': return 'application/pdf';
      case 'image': return 'image/jpeg';
      case 'video': return 'video/mp4';
      default: return 'application/octet-stream';
    }
  }

  ManifestoModel getManifestoData() {
    final data = _getData(); // Use reactive controller data

    AppLogger.candidate('🎯 [getManifestoData] Getting manifesto data for save');

    // Get current URLs, but override with cleared URLs for files marked for deletion
    String? currentPdfUrl = data.manifestoData?.pdfUrl;
    String? currentImageUrl = data.manifestoData?.image;
    String? currentVideoUrl = data.manifestoData?.videoUrl;

    // CRITICAL FIX: Override with empty strings for deleted files to ensure getManifestoData returns correct values
    if (_filesMarkedForDeletion['pdf'] == true) {
      currentPdfUrl = '';
      AppLogger.candidate('🗑️ [getManifestoData] Overriding PDF URL to empty string (marked for deletion)');
    }
    if (_filesMarkedForDeletion['image'] == true) {
      currentImageUrl = '';
      AppLogger.candidate('🗑️ [getManifestoData] Overriding Image URL to empty string (marked for deletion)');
    }
    if (_filesMarkedForDeletion['video'] == true) {
      currentVideoUrl = '';
      AppLogger.candidate('🗑️ [getManifestoData] Overriding Video URL to empty string (marked for deletion)');
    }

    // Check if we have any pending uploads that should override the current URLs
    // This handles the case where files were uploaded but not yet saved to database
    if (_localFiles.isNotEmpty) {
      for (final localFile in _localFiles) {
        final type = localFile['type'] as String;
        // Note: We don't have the uploaded URL here since it's not stored locally
        // The URLs will be updated after the batch update completes
      }
    }

    final result = ManifestoModel(
      title: _titleController.text,
      promises: _promiseControllers.map((controllerMap) {
        final title = (controllerMap['title'] as TextEditingController).text;
        final points = (controllerMap['points'] as List<TextEditingController>).map((pointController) => pointController.text).where((point) => point.isNotEmpty).toList();
        return {'title': title, 'points': points};
      }).toList(),
      pdfUrl: currentPdfUrl,
      image: currentImageUrl,
      videoUrl: currentVideoUrl,
    );

    AppLogger.candidate('🎯 [getManifestoData] Final result - PDF: "${result.pdfUrl ?? 'null'}", Image: "${result.image ?? 'null'}", Video: "${result.videoUrl ?? 'null'}"');
    return result;
  }

  Future<bool> uploadPendingFiles() async {
    try {
      bool hasDeletions = _filesMarkedForDeletion.values.any((marked) => marked);

      if (hasDeletions) {
        AppLogger.candidate('🗑️ [Save] Files marked for deletion detected, deleting first...');
        await _deleteMarkedFiles();
        AppLogger.candidate('🗑️ [Save] Marked files deleted successfully');
      }

      if (_localFiles.isNotEmpty) {
        AppLogger.candidate('☁️ [Save] Uploading ${_localFiles.length} pending local files...');
        await _uploadLocalFilesToFirebase();
        AppLogger.candidate('✅ [Save] Local files uploaded successfully');
      }

      return true;
    } catch (e) {
      AppLogger.candidateError('💾 [Save] Error during file operations: $e');
      return false;
    }
  }

  Future<void> _deleteMarkedFiles() async {
    final data = _getData();

    AppLogger.candidate('🗑️ [DeleteFiles] ===== STARTING SEQUENTIAL DELETION PROCESS =====');

    final deletionTasks = <Future<void> Function()>[];

    // Store original URLs and capture them before any clearing
    // CRITICAL: Get URLs before any widget callbacks can modify them
    final Map<String, String> urlsToDelete = {};
    final Map<String, bool> filesToReset = {};

    // First pass: Capture URLs from cached original URLs (definite source of truth)
    for (final entry in _originalUrlsBeforeDeletion.entries) {
      if (_filesMarkedForDeletion[entry.key] == true) {
        urlsToDelete[entry.key] = entry.value;
        filesToReset[entry.key] = true;
        AppLogger.candidate('🗑️ [UrlsToDelete] ${entry.key.toUpperCase()} URL captured from cache: ${entry.value}');
      }
    }

    // Fallback: If cache is empty, try getting from current data (but this shouldn't happen if we cached properly)
    if (urlsToDelete.isEmpty) {
      AppLogger.candidate('⚠️ [UrlsToDelete] Cache is empty, falling back to data (this should not happen)');

      if (_filesMarkedForDeletion['pdf'] == true) {
        final url = data.manifestoData?.pdfUrl;
        if (url != null && url.isNotEmpty) {
          urlsToDelete['pdf'] = url;
          filesToReset['pdf'] = true;
          AppLogger.candidate('🗑️ [UrlsToDelete] Fallback PDF URL captured: $url');
        }
      }

      if (_filesMarkedForDeletion['image'] == true) {
        final url = data.manifestoData?.image;
        if (url != null && url.isNotEmpty) {
          urlsToDelete['image'] = url;
          filesToReset['image'] = true;
          AppLogger.candidate('🗑️ [UrlsToDelete] Fallback Image URL captured: $url');
        }
      }

      if (_filesMarkedForDeletion['video'] == true) {
        final url = data.manifestoData?.videoUrl;
        if (url != null && url.isNotEmpty) {
          urlsToDelete['video'] = url;
          filesToReset['video'] = true;
          AppLogger.candidate('🗑️ [UrlsToDelete] Fallback Video URL captured: $url');
        }
      }
    }

    AppLogger.candidate('🗑️ [UrlsToDelete] Captured ${urlsToDelete.length} URLs to delete');

    // Second pass: Execute deletions using captured URLs
    for (final entry in urlsToDelete.entries) {
      final type = entry.key;
      final url = entry.value;
      AppLogger.candidate('🗑️ [ExecuteDeletion] Executing deletion for $type: $url');
      await _deleteFileFromStorageOnly(type, url);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (urlsToDelete.isEmpty) {
      AppLogger.candidate('🗑️ [DeleteFiles] No files to delete');
      return;
    }

    // Third pass: Clear URLs in data after all storage deletions are complete
    for (final type in filesToReset.keys) {
      _clearUrlInData(type, '');
      _filesMarkedForDeletion[type] = false;
      AppLogger.candidate('🗑️ [DataReset] Cleared $type URL in data');
    }

    AppLogger.candidate('🗑️ [DeleteFiles] ===== SEQUENTIAL DELETION PROCESS COMPLETED =====');
  }

  Future<void> _deleteFileFromStorageOnly(String type, String url) async {
    try {
      AppLogger.candidate('🗑️ [DeleteFileOnly] Starting storage deletion of $type file: $url');
      await _deleteFileFromStorageWithRetry(url, type.toUpperCase());
      AppLogger.candidate('✅ [DeleteFileOnly] Successfully deleted $type file from storage');
    } catch (e) {
      AppLogger.candidate('❌ [DeleteFileOnly] Failed to delete $type file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $type file from storage. File may still exist.'), backgroundColor: Colors.orange),
        );
      }
      // Re-throw to maintain error propagation
      throw e;
    }
  }

  Future<void> _deleteFileAndClearUrl(String type, String url) async {
    try {
      AppLogger.candidate('🗑️ [DeleteFile] Starting deletion of $type file with URL: $url');
      _clearUrlInData(type, '');
      AppLogger.candidate('🗑️ [DeleteFile] Cleared URL from local data');

      await _deleteFileFromStorageWithRetry(url, type.toUpperCase());
      AppLogger.candidate('✅ [DeleteFile] Successfully deleted $type file and cleared URL');
    } catch (e) {
      AppLogger.candidate('❌ [DeleteFile] Failed to delete $type file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete $type file. It may still be referenced in your manifesto.'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _clearUrlInData(String type, String url) {
    switch (type) {
      case 'pdf':
        widget.onManifestoPdfChange(url);
        break;
      case 'image':
        widget.onManifestoImageChange(url);
        break;
      case 'video':
        widget.onManifestoVideoChange(url);
        break;
    }
    _filesMarkedForDeletion[type] = false;
  }

  Future<void> _deleteFileFromStorageWithRetry(String fileUrl, String fileType, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        await _deleteFileFromStorage(fileUrl, fileType);
        return;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          AppLogger.candidate('❌ [Retry Delete] Giving up on deleting $fileType after $maxRetries attempts');
          throw Exception('Failed to delete $fileType after $maxRetries attempts');
        }
        AppLogger.candidate('⚠️ [Retry Delete] Attempt $attempts failed for $fileType, retrying...');
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }

  Future<void> _deleteFileFromStorage(String fileUrl, String fileType) async {
    try {
      AppLogger.candidate('🗑️ [Storage Delete] Deleting $fileType from Firebase Storage: $fileUrl');

      // Validate URL format first
      if (!fileUrl.startsWith('https://firebasestorage.googleapis.com/')) {
        AppLogger.candidate('❌ [Storage Delete] Invalid Firebase Storage URL format: $fileUrl');
        throw Exception('Invalid Firebase Storage URL format');
      }

      // Try to create reference from URL
      final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
      AppLogger.candidate('🗑️ [Storage Delete] Created storage reference successfully');

      // Check if file exists first (optional)
      try {
        await storageRef.getMetadata();
        AppLogger.candidate('🗑️ [Storage Delete] File exists, proceeding with deletion');
      } catch (metadataError) {
        AppLogger.candidate('⚠️ [Storage Delete] File may not exist: $metadataError');
      }

      // Attempt deletion
      await storageRef.delete();
      AppLogger.candidate('✅ [Storage Delete] Successfully deleted $fileType from Firebase Storage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileType deleted successfully from storage'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      String errorDetails = e.toString().toLowerCase();

      if (errorDetails.contains('object-not-found') || errorDetails.contains('object does not exist') ||
          errorDetails.contains('404') || errorDetails.contains('no such object')) {
        AppLogger.candidate('⚠️ [Storage Delete] $fileType file already deleted or never existed: $e');
        // This is actually okay - the file is already gone
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileType already removed from storage'), backgroundColor: Colors.blue),
          );
        }
      } else if (errorDetails.contains('permission') || errorDetails.contains('unauthorized') ||
                 errorDetails.contains('forbidden') || errorDetails.contains('403')) {
        AppLogger.candidateError('🚫 [Storage Delete] Permission denied deleting $fileType: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permission denied: cannot delete $fileType from storage'), backgroundColor: Colors.red),
          );
        }
      } else if (errorDetails.contains('invalid') || errorDetails.contains('malformed')) {
        AppLogger.candidateError('❌ [Storage Delete] Invalid URL format for $fileType: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid storage URL format for $fileType'), backgroundColor: Colors.red),
          );
        }
      } else {
        AppLogger.candidateError('❌ [Storage Delete] Unknown error deleting $fileType from storage: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete $fileType from storage: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }

      // Re-throw to ensure calling code knows deletion failed
      throw e;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Unknown File';
    } catch (e) {
      return 'Unknown File';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getData();
    final manifesto = data.manifestoData?.title ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form fields
            _buildTitleField(context),
            const SizedBox(height: 16),
            PromiseManagementSection(
              promiseControllers: _promiseControllers,
              onPromisesChange: widget.onManifestoPromisesChange,
              isEditing: widget.isEditing,
            ),
            const SizedBox(height: 16),

            // Unified file management section
            _buildFileManagementSection(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.manifestoTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.manifestoTitleLabel,
            border: const OutlineInputBorder(),
            hintText: AppLocalizations.of(context)!.manifestoTitleHint,
            suffixIcon: IconButton(
              icon: const Icon(Icons.lightbulb, color: Colors.amber),
              onPressed: _showDemoTitleOptions,
              tooltip: AppLocalizations.of(context)!.useDemoTitle,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: widget.onManifestoTitleChange,
        ),
      ],
    );
  }

  Widget _buildFileManagementSection(BuildContext context, Candidate data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.uploadFiles,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),

        // Upload section
        FileUploadSection(
          candidateData: widget.candidateData,
          isEditing: widget.isEditing,
          onManifestoPdfChange: widget.onManifestoPdfChange,
          onManifestoImageChange: widget.onManifestoImageChange,
          onManifestoVideoChange: widget.onManifestoVideoChange,
          onLocalFilesUpdate: (files) => setState(() => _localFiles = files),
        ),

        // Display existing files
        _buildUploadedFilesSection(context, data),
      ],
    );
  }

  Widget _buildUploadedFilesSection(BuildContext context, Candidate data) {
    final fileTypes = ['pdf', 'image', 'video'];
    final fileUrls = {
      'pdf': data.manifestoData?.pdfUrl,
      'image': data.manifestoData?.image,
      'video': data.manifestoData?.videoUrl,
    };

    return Column(
      children: fileTypes.map((type) {
        final url = fileUrls[type];
        if (url == null || url.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 8),
            _buildFileCard(context, type, url),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFileCard(BuildContext context, String type, String url) {
    final isMarkedForDeletion = _filesMarkedForDeletion[type]!;

    switch (type) {
      case 'pdf':
        return _buildFileDisplayCard(
          context: context,
          icon: Icons.picture_as_pdf,
          iconColor: isMarkedForDeletion ? Colors.red.shade900 : Colors.red.shade700,
          bgColor: isMarkedForDeletion ? Colors.red.shade50 : Colors.red.shade50,
          borderColor: isMarkedForDeletion ? Colors.red.shade300 : Colors.red.shade200,
          fileType: 'PDF',
          fileName: _getFileNameFromUrl(url),
          isMarkedForDeletion: isMarkedForDeletion,
          onDeletionToggle: (checked) => _handleDeletionToggle(context, type, checked),
        );
      case 'image':
        return _buildImageDisplayCard(
          context: context,
          imageUrl: url,
          fileName: _getFileNameFromUrl(url),
          isMarkedForDeletion: isMarkedForDeletion,
          onDeletionToggle: (checked) => _handleDeletionToggle(context, type, checked),
        );
      case 'video':
        return _buildVideoDisplayCard(
          context: context,
          videoUrl: url,
          fileName: _getFileNameFromUrl(url),
          isMarkedForDeletion: isMarkedForDeletion,
          onDeletionToggle: (checked) => _handleDeletionToggle(context, type, checked),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleDeletionToggle(BuildContext context, String type, bool? checked) async {
    if (checked == true) {
      final title = 'Mark ${type.toUpperCase()} for Deletion';
      final content = '${type.toUpperCase()} will be deleted when you save changes.';
      final confirmText = 'Mark for Deletion';
      final snackBarMessage = '${type.toUpperCase()} marked for deletion';

      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: title,
        content: content,
        confirmText: confirmText,
      );

      if (confirmed == true) {
        // CRITICAL FIX: Capture the original URL BEFORE marking for deletion
        // This ensures we have the URL even if the controller state changes
        final data = _getData();
        String? originalUrl;
        switch (type) {
          case 'pdf':
            originalUrl = data.manifestoData?.pdfUrl;
            break;
          case 'image':
            originalUrl = data.manifestoData?.image;
            break;
          case 'video':
            originalUrl = data.manifestoData?.videoUrl;
            break;
        }

        if (originalUrl != null && originalUrl.isNotEmpty) {
          _originalUrlsBeforeDeletion[type] = originalUrl;
          AppLogger.candidate('💾 [URLCapture] Stored original $type URL for deletion: $originalUrl');
        } else {
          AppLogger.candidate('⚠️ [URLCapture] No original $type URL found to capture');
        }

        setState(() => _filesMarkedForDeletion[type] = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(snackBarMessage), backgroundColor: Colors.orange),
          );
        }
      }
    } else {
      // Clear the captured URL when unmarking
      _originalUrlsBeforeDeletion.remove(type);
      setState(() => _filesMarkedForDeletion[type] = false);
    }
  }

  Widget _buildFileDisplayCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String fileType,
    required String fileName,
    required bool isMarkedForDeletion,
    required Function(bool?) onDeletionToggle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
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
                  'Manifesto $fileType',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: isMarkedForDeletion ? Colors.red.shade600 : Colors.grey,
                    decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isMarkedForDeletion) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.willBeDeletedWhenYouSave,
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Checkbox(value: isMarkedForDeletion, onChanged: onDeletionToggle, activeColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildImageDisplayCard({
    required BuildContext context,
    required String imageUrl,
    required String fileName,
    required bool isMarkedForDeletion,
    required Function(bool?) onDeletionToggle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMarkedForDeletion ? Colors.red.shade100 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMarkedForDeletion ? Colors.red.shade300 : Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                color: isMarkedForDeletion ? Colors.red.shade900 : Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.manifestoImage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMarkedForDeletion ? Colors.red.shade900 : Colors.green.shade700,
                        decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMarkedForDeletion ? Colors.red.shade600 : Colors.grey,
                        decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isMarkedForDeletion) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.willBeDeletedWhenYouSave,
                        style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(value: isMarkedForDeletion, onChanged: onDeletionToggle, activeColor: Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          ReusableImageWidget(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            minHeight: 120,
            maxHeight: 200,
            borderColor: Colors.grey.shade300,
            fullScreenTitle: 'Manifesto Image',
          ),
        ],
      ),
    );
  }

  Widget _buildVideoDisplayCard({
    required BuildContext context,
    required String videoUrl,
    required String fileName,
    required bool isMarkedForDeletion,
    required Function(bool?) onDeletionToggle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMarkedForDeletion ? Colors.red.shade100 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMarkedForDeletion ? Colors.red.shade300 : Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_call,
                color: isMarkedForDeletion ? Colors.red.shade900 : Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.manifestoVideo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMarkedForDeletion ? Colors.red.shade900 : Colors.purple.shade700,
                        decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMarkedForDeletion ? Colors.red.shade600 : Colors.grey,
                        decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.premiumFeatureMultiResolution,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMarkedForDeletion ? Colors.red.shade700 : Colors.purple,
                        fontStyle: FontStyle.italic,
                        decoration: isMarkedForDeletion ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (isMarkedForDeletion) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.willBeDeletedWhenYouSave,
                        style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(value: isMarkedForDeletion, onChanged: onDeletionToggle, activeColor: Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.black,
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
