import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';
import 'package:janmat/features/candidate/controllers/upload_controller.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/manifesto_model.dart';
import 'package:janmat/features/candidate/widgets/edit/promise_management_section.dart';
import 'package:janmat/l10n/app_localizations.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import '../../../../common/file_storage_manager.dart';
import '../../../../../core/media/media_file.dart';
import '../../../../../core/media/media_upload_handler.dart';
import 'manifesto_file_section.dart';


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

  late TextEditingController _manifestoTextController;
  late TextEditingController _titleController;
  late List<Map<String, dynamic>> _promiseControllers;
   String? _originalText;
   List<Map<String, dynamic>> _localFiles = [];
   bool _isUploading = false; // Prevent multiple simultaneous uploads

  // No need for callback anymore - using direct upload logic

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

    // Demo manifesto titles in different languages
    final Map<String, List<String>> demoTitles = {
      'en': [
        'Building a Prosperous Future Together',
        'Empowering Our Community for Tomorrow',
        'Vision for Progress and Development',
        'Commitment to Change and Growth',
        'Together Towards a Better Tomorrow',
        'Your Voice, Our Mission',
        'Leading with Integrity and Purpose',
        'A New Era of Development',
        'Promises for a Brighter Future',
        'Working for You, Every Day',
      ],
      'mr': [
        'एकत्रितपणे समृद्ध भविष्य घडवूया',
        'आमच्या समुदायाला उद्या साठी सशक्त करूया',
        'प्रगती आणि विकासाचे दृष्टीपत्र',
        'बदल आणि वाढीचे वचन',
        'एकत्रितपणे चांगल्या उद्याकडे',
        'तुमचा आवाज, आमचे ध्येय',
        'निष्ठा आणि उद्देशाने नेतृत्व',
        'विकासाचा नवीन युग',
        'उज्ज्वल भविष्यासाठी वचने',
        'तुमच्यासाठी काम करणे, दररोज',
      ],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.chooseManifestoTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Language Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Text('Language: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'mr', label: Text('मराठी')),
                  ],
                  selected: {selectedLanguage},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() {
                      selectedLanguage = selection.first;
                    });
                  },
                ),
              ],
            ),
                const SizedBox(height: 16),

                // Title Options
                Text(
                  'Choose from these suggested manifesto titles:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),

                // Demo titles list
                ...demoTitles[selectedLanguage]!.map((title) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      _titleController.text = title;
                      widget.onManifestoTitleChange(title);
                      Navigator.of(context).pop();
                      SnackbarUtils.showSuccess('Manifesto title updated!');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
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
      // Note: We don't have the uploaded URL here since it's not stored locally
      // The URLs will be updated after the batch update completes
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
    // Prevent multiple simultaneous uploads
    if (_isUploading) {
      AppLogger.candidate('⚠️ [Upload] Upload already in progress, skipping duplicate request');
      AppLogger.candidate('⚠️ [Upload] _isUploading flag is: $_isUploading');
      if (mounted) {
        SnackbarUtils.showScaffoldWarning(context, 'Upload already in progress. Please wait.');
      }
      return false;
    }

    AppLogger.candidate('✅ [Upload] Starting upload process, setting _isUploading = true');

    _isUploading = true;

    try {
      bool hasDeletions = _filesMarkedForDeletion.values.any((marked) => marked);

      if (hasDeletions) {
        AppLogger.candidate('🗑️ [Save] Files marked for deletion detected, deleting first...');
        await _deleteMarkedFiles();
        AppLogger.candidate('🗑️ [Save] Marked files deleted successfully');
      }

      // Check if we have files from the new UploadController
      final uploadController = Get.find<UploadController>(tag: null);
      if (uploadController.localFiles.isNotEmpty) {
        // Convert MediaFile objects to the format expected by the old upload logic
        for (final mediaFile in uploadController.localFiles) {
          final fileEntry = {
            'type': mediaFile.type,
            'fileName': mediaFile.name,
            'fileSize': mediaFile.size,
            'bytes': mediaFile.bytes,
            'localPath': 'temp:${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}',
          };
          _localFiles.add(fileEntry);
        }
        AppLogger.candidate('📁 [Upload] Added ${uploadController.localFiles.length} files from UploadController');
      }

      // Use the FileStorageManager's unified upload logic with stored _localFiles
      final uploadedUrls = await _uploadLocalFilesUsingStorageManager();

      if (uploadedUrls.isNotEmpty) {
        AppLogger.candidate('✅ [Save] Files uploaded successfully: $uploadedUrls');

        // IMMEDIATE UI UPDATES: No delay needed
        // Update the manifesto data with uploaded URLs
        if (uploadedUrls['pdf'] != null) {
          widget.onManifestoPdfChange(uploadedUrls['pdf']!);
        }
        if (uploadedUrls['image'] != null) {
          widget.onManifestoImageChange(uploadedUrls['image']!);
        }
        if (uploadedUrls['video'] != null) {
          widget.onManifestoVideoChange(uploadedUrls['video']!);
        }

        // Clear files from UploadController after successful upload
        uploadController.localFiles.clear();
      }

      return true;
    } catch (e) {
      AppLogger.candidateError('💾 [Save] Error during file operations: ${e.toString().split('\n').first}');
      return false;
    } finally {
      AppLogger.candidate('🔄 [Upload] Upload process finished, resetting _isUploading = false');
      _isUploading = false;
    }
  }

  /// Automatically delete old files when new ones are uploaded to replace them
  Future<void> _autoDeleteOldFilesForUpload() async {
    final data = _getData();
    final Map<String, String> filesToDelete = {};

    // Check each local file type and see if there's an existing file to replace
    for (final localFile in _localFiles) {
      final type = localFile['type'] as String;
      String? existingUrl;

      switch (type) {
        case 'pdf':
          existingUrl = data.manifestoData?.pdfUrl;
          break;
        case 'image':
          existingUrl = data.manifestoData?.image;
          break;
        case 'video':
          existingUrl = data.manifestoData?.videoUrl;
          break;
      }

      if (existingUrl != null && existingUrl.isNotEmpty) {
        filesToDelete[type] = existingUrl;
        AppLogger.candidate('🗑️ [AutoDelete] Will delete existing $type file: $existingUrl');
      }
    }

    // Delete the old files
    for (final entry in filesToDelete.entries) {
      final type = entry.key;
      final url = entry.value;
      try {
        AppLogger.candidate('🗑️ [AutoDelete] Deleting old $type file from storage...');
        await _deleteFileFromStorageOnly(type, url);
        AppLogger.candidate('✅ [AutoDelete] Successfully deleted old $type file');
      } catch (e) {
        AppLogger.candidateError('❌ [AutoDelete] Failed to delete old $type file: $e');
        // Continue with upload even if deletion fails
      }
    }
  }

  Future<Map<String, String>> _uploadLocalFilesUsingStorageManager() async {
    if (_localFiles.isEmpty) {
      AppLogger.candidate('🚀 [Storage Manager Upload] No local files to upload');
      return {};
    }

    AppLogger.candidate('🚀 [Storage Manager Upload] Starting bulk upload of ${_localFiles.length} files...');
    AppLogger.candidate('🚀 [Storage Manager Upload] Current _isUploading flag: $_isUploading');

    // AUTO DELETE OLD FILES: Before uploading new files, delete existing ones of the same type
    await _autoDeleteOldFilesForUpload();

    if (!mounted) return {};

    // Use ADVANCED media uploader with PROGRESS DIALOG
    final mediaHandler = MediaUploadHandler(
      context: context,
      userId: widget.candidateData.candidateId,
      category: 'manifesto',
    );

    // Convert local files to MediaFile format for advanced uploading
    final mediaFiles = <MediaFile>[];
    for (final localFile in _localFiles) {
      final type = localFile['type'] as String;
      final fileName = localFile['fileName'] as String;
      final bytes = localFile['bytes'] as Uint8List?; // Check for pre-read bytes
      final tempPath = localFile['localPath'] as String;

      // Create MediaFile - handle both web (with bytes) and mobile (with temp path) cases
      if (bytes != null && bytes.isNotEmpty) {
        // Web files with pre-read bytes
        final mediaFile = MediaFile(
          id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
          name: fileName,
          type: type,
          bytes: bytes,
          size: bytes.length,
        );
        mediaFiles.add(mediaFile);
      } else {
        // Mobile files or web files without pre-read bytes - need to read from temp path
        try {
          Uint8List fileBytes;
          if (kIsWeb && tempPath.startsWith('temp:')) {
            // Web file stored in memory
            final tempId = tempPath.split(':')[1];
            final storageManager = FileStorageManager();
            if (storageManager.hasWebFileData(tempId)) {
              fileBytes = storageManager.getWebFileData(tempId)!;
            } else {
              AppLogger.candidate('⚠️ [Upload] Web file data not found for $tempId');
              continue;
            }
          } else {
            // Mobile file - read from local path
            final file = File(tempPath.replaceFirst('local:', ''));
            fileBytes = await file.readAsBytes();
          }

          final mediaFile = MediaFile(
            id: '${type}_${DateTime.now().millisecondsSinceEpoch}',
            name: fileName,
            type: type,
            bytes: fileBytes,
            size: fileBytes.length,
          );
          mediaFiles.add(mediaFile);
        } catch (e) {
          AppLogger.candidate('⚠️ [Upload] Failed to read file bytes for $fileName: $e');
          continue;
        }
      }
    }

    if (mediaFiles.isEmpty) {
      AppLogger.candidate('⚠️ [Upload] No valid media files to upload');
      return {};
    }

    // Show progress dialog and upload with real-time progress tracking
    final urls = await mediaHandler.uploadMediaFilesWithProgressDialog(
      mediaFiles,
      customPath: 'manifesto_files/${widget.candidateData.candidateId}/',
    );

    // Convert back to expected format
    final result = <String, String>{};
    for (int i = 0; i < mediaFiles.length; i++) {
      final mediaFile = mediaFiles[i];
      if (i < urls.length) {
        result[mediaFile.type] = urls[i];
      }
    }

    // Clear local files after upload attempt
    setState(() => _localFiles.clear());

    return result;
  }

  Future<void> _deleteMarkedFiles() async {
    final data = _getData();

    AppLogger.candidate('🗑️ [DeleteFiles] ===== STARTING SEQUENTIAL DELETION PROCESS =====');

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
        SnackbarUtils.showWarning('Failed to delete $type file from storage. File may still exist.');
      }
      // Re-throw to maintain error propagation
      rethrow;
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
        SnackbarUtils.showSuccess('$fileType deleted successfully from storage');
      }
    } catch (e) {
      String errorDetails = e.toString().toLowerCase();

      if (errorDetails.contains('object-not-found') || errorDetails.contains('object does not exist') ||
          errorDetails.contains('404') || errorDetails.contains('no such object')) {
        AppLogger.candidate('⚠️ [Storage Delete] $fileType file already deleted or never existed: $e');
        // This is actually okay - the file is already gone
        if (mounted) {
          SnackbarUtils.showInfo('$fileType already removed from storage');
        }
      } else if (errorDetails.contains('permission') || errorDetails.contains('unauthorized') ||
                 errorDetails.contains('forbidden') || errorDetails.contains('403')) {
        AppLogger.candidateError('🚫 [Storage Delete] Permission denied deleting $fileType: $e');
        if (mounted) {
          SnackbarUtils.showError('Permission denied: cannot delete $fileType from storage');
        }
      } else if (errorDetails.contains('invalid') || errorDetails.contains('malformed')) {
        AppLogger.candidateError('❌ [Storage Delete] Invalid URL format for $fileType: $e');
        if (mounted) {
          SnackbarUtils.showError('Invalid storage URL format for $fileType');
        }
      } else {
        AppLogger.candidateError('❌ [Storage Delete] Unknown error deleting $fileType from storage: $e');
        if (mounted) {
          SnackbarUtils.showError('Failed to delete $fileType from storage: ${e.toString()}');
        }
      }

      // Re-throw to ensure calling code knows deletion failed
      rethrow;
    }
  }


  @override
  Widget build(BuildContext context) {
    final data = _getData();

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

        // Upload section - now uses clean architecture with separate components
        ManifestoFileSection(
          candidate: widget.candidateData,
          existingPdfUrl: data.manifestoData?.pdfUrl,
          existingImageUrl: data.manifestoData?.image,
          existingVideoUrl: data.manifestoData?.videoUrl,
          onPdfUrlChange: widget.onManifestoPdfChange,
          onImageUrlChange: widget.onManifestoImageChange,
          onVideoUrlChange: widget.onManifestoVideoChange,
        ),
      ],
    );
  }




}
