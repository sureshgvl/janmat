import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/candidate_model.dart';
import '../../../../services/video_processing_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../common/reusable_image_widget.dart';
import '../../../common/confirmation_dialog.dart';
import 'promise_management_section.dart';
import '../../../common/file_upload_section.dart';

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
   late TextEditingController _manifestoController;
   late TextEditingController _titleController;
   late List<Map<String, dynamic>> _promiseControllers;
   String? _originalText;
   List<Map<String, dynamic>> _localFiles = [];

  // Files marked for deletion (will be deleted on save)
  bool _isPdfMarkedForDeletion = false;
  bool _isImageMarkedForDeletion = false;
  bool _isVideoMarkedForDeletion = false;

  @override
  void initState() {
    super.initState();
    debugPrint('ManifestoTabEdit initState called');
    final data = widget.editedData ?? widget.candidateData;
    _originalText = data.extraInfo?.manifesto?.title ?? '';
    _manifestoController = TextEditingController(text: _originalText);

    // Initialize title controller with model data
    final manifestoTitle = data.extraInfo?.manifesto?.title ?? '';
    _titleController = TextEditingController(
      text: _stripBoldMarkers(manifestoTitle),
    );

    // Initialize manifesto promises list with structured format from model
    final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
    debugPrint('Raw promises from data: $rawPromises');
    final manifestoPromises = rawPromises
        .map((promise) {
          // Already structured format
          return promise;
        })
        .cast<Map<String, dynamic>>()
        .toList();

    // Initialize controllers for existing promises
    _promiseControllers = manifestoPromises.map((promise) {
      final title = promise['title'] as String? ?? '';
      final points = promise['points'] as List<dynamic>? ?? <dynamic>[];
      return <String, dynamic>{
        'title': TextEditingController(text: _stripBoldMarkers(title)),
        'points': points
            .map(
              (point) => TextEditingController(
                text: _stripBoldMarkers(point.toString()),
              ),
            )
            .toList(),
      };
    }).toList();

    // If no promises exist, create one empty promise
    if (manifestoPromises.isEmpty) {
      debugPrint('No promises found, creating empty promise');
      _promiseControllers.add(<String, dynamic>{
        'title': TextEditingController(),
        'points': <TextEditingController>[TextEditingController()],
      });
    }
    debugPrint('Initialized with ${manifestoPromises.length} promises');
  }

  @override
  void didUpdateWidget(ManifestoTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      'ManifestoTabEdit didUpdateWidget called, isEditing: ${widget.isEditing}',
    );
    final data = widget.editedData ?? widget.candidateData;
    final newText = data.extraInfo?.manifesto?.title ?? '';
    if (_originalText != newText) {
      debugPrint('Updating original text from $_originalText to $newText');
      _originalText = newText;
      _manifestoController.text = newText;
    }

    // Update title controller with model data
    final newTitle = data.extraInfo?.manifesto?.title ?? '';
    _titleController.text = _stripBoldMarkers(newTitle);

    // Only update promises if we're not in editing mode or if the data has actually changed
    if (!widget.isEditing) {
      final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
      debugPrint('Raw promises in didUpdateWidget: $rawPromises');
      final newManifestoPromises = rawPromises
          .map((promise) {
            // Already structured format
            return promise;
          })
          .cast<Map<String, dynamic>>()
          .toList();

      // Update controllers with new data
      _promiseControllers = newManifestoPromises.map((promise) {
        final title = promise['title'] as String? ?? '';
        final points = promise['points'] as List<dynamic>? ?? <dynamic>[];
        return <String, dynamic>{
          'title': TextEditingController(text: _stripBoldMarkers(title)),
          'points': points
              .map(
                (point) => TextEditingController(
                  text: _stripBoldMarkers(point.toString()),
                ),
              )
              .toList(),
        };
      }).toList();

      // If no promises exist, create one empty promise
      if (newManifestoPromises.isEmpty) {
        debugPrint(
          'No promises found in didUpdateWidget, creating empty promise',
        );
        _promiseControllers.add(<String, dynamic>{
          'title': TextEditingController(),
          'points': <TextEditingController>[TextEditingController()],
        });
      }
    } else {
      debugPrint('In editing mode, skipping promise updates');
    }
  }


  void _showDemoTitleOptions() {
    String selectedLanguage = 'en'; // Default to English
    final cityId = widget.candidateData.districtId;
    final wardId = widget.candidateData.wardId;

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
                Text(
                  AppLocalizations.of(context)!.selectLanguage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLanguage = 'en';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedLanguage == 'en'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          foregroundColor: selectedLanguage == 'en'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('English'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLanguage = 'mr';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedLanguage == 'mr'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          foregroundColor: selectedLanguage == 'mr'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('मराठी'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.chooseTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // English Titles
                if (selectedLanguage == 'en') ...[
                  ListTile(
                    title: Text('Ward $wardId Development Plan'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.standardDevelopmentFocus,
                    ),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Development Plan';
                      widget.onManifestoTitleChange(
                        'Ward $wardId Development Plan',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Development & Transparency Plan'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.developmentWithTransparency,
                    ),
                    onTap: () {
                      _titleController.text =
                          'Ward $wardId Development & Transparency Plan';
                      widget.onManifestoTitleChange(
                        'Ward $wardId Development & Transparency Plan',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Progress Manifesto'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.focusOnProgress,
                    ),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Progress Manifesto';
                      widget.onManifestoTitleChange(
                        'Ward $wardId Progress Manifesto',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Citizen Welfare Plan'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.focusOnCitizenWelfare,
                    ),
                    onTap: () {
                      _titleController.text =
                          'Ward $wardId Citizen Welfare Plan';
                      widget.onManifestoTitleChange(
                        'Ward $wardId Citizen Welfare Plan',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ]
                // Marathi Titles
                else ...[
                  ListTile(
                    title: Text('वॉर्ड $wardId विकास योजना'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.standardDevelopmentFocus,
                    ),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId विकास योजना';
                      widget.onManifestoTitleChange(
                        'वॉर्ड $wardId विकास योजना',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId विकास आणि पारदर्शकता योजना'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.developmentWithTransparency,
                    ),
                    onTap: () {
                      _titleController.text =
                          'वॉर्ड $wardId विकास आणि पारदर्शकता योजना';
                      widget.onManifestoTitleChange(
                        'वॉर्ड $wardId विकास आणि पारदर्शकता योजना',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId प्रगती घोषणापत्र'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.focusOnProgress,
                    ),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId प्रगती घोषणापत्र';
                      widget.onManifestoTitleChange(
                        'वॉर्ड $wardId प्रगती घोषणापत्र',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId नागरिक कल्याण योजना'),
                    subtitle: Text(
                      AppLocalizations.of(context)!.focusOnCitizenWelfare,
                    ),
                    onTap: () {
                      _titleController.text =
                          'वॉर्ड $wardId नागरिक कल्याण योजना';
                      widget.onManifestoTitleChange(
                        'वॉर्ड $wardId नागरिक कल्याण योजना',
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
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

  // Strip simple markdown bold markers for display
  String _stripBoldMarkers(String s) {
    if (s.isEmpty) return s;
    // Remove any ** surrounding markers and any standalone occurrences
    final trimmed = s.trim();
    if (trimmed.startsWith('**') &&
        trimmed.endsWith('**') &&
        trimmed.length >= 4) {
      return trimmed.substring(2, trimmed.length - 2).trim();
    }
    return trimmed.replaceAll('**', '').trim();
  }

  @override
  void dispose() {
    _manifestoController.dispose();
    _titleController.dispose();
    for (var controllerMap in _promiseControllers) {
      (controllerMap['title'] as TextEditingController?)?.dispose();
      for (var pointController
          in (controllerMap['points'] as List<TextEditingController>? ?? [])) {
        pointController.dispose();
      }
    }
    super.dispose();
  }


  // Clean up local file after upload
  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      debugPrint('🧹 [Local Storage] Cleaning up local file: $localPath');
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🧹 [Local Storage] Local file deleted successfully');
      } else {
        debugPrint('🧹 [Local Storage] Local file not found, nothing to clean');
      }
    } catch (e) {
      debugPrint('🧹 [Local Storage] Error cleaning up local file: $e');
    }
  }

  // Enhanced upload method with Cloudinary integration for videos
  Future<void> _uploadLocalFilesToFirebase() async {
    debugPrint(
      '☁️ [Enhanced Upload] Starting upload for ${_localFiles.length} local files...',
    );

    for (final localFile in _localFiles) {
      try {
        final type = localFile['type'] as String;
        final localPath = localFile['localPath'] as String;
        final fileName = localFile['fileName'] as String;
        final isPremiumVideo = localFile['isPremium'] as bool? ?? false;

        debugPrint(
          '☁️ [Enhanced Upload] Processing $type file: $fileName (Premium: $isPremiumVideo)',
        );

        final file = File(localPath);

        // Handle video uploads with Cloudinary for premium users
        if (type == 'video' && isPremiumVideo) {
          debugPrint(
            '🎥 [Cloudinary Upload] Processing premium video with Cloudinary...',
          );

          try {
            // Initialize VideoProcessingService
            final videoService = VideoProcessingService();

            // Show processing progress
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Processing premium video with multi-resolution optimization...',
                ),
                backgroundColor: Colors.purple,
                duration: Duration(seconds: 3),
              ),
            );

            // Upload and process video through Cloudinary
            final processedVideo = await videoService.uploadAndProcessVideo(
              file,
              widget.candidateData.userId ?? 'unknown_user',
              onProgress: (progress) {
                debugPrint(
                  '🎥 [Cloudinary Progress] ${progress.toStringAsFixed(1)}%',
                );
              },
            );

            debugPrint(
              '🎥 [Cloudinary Success] Video processed successfully: ${processedVideo.id}',
            );

            // Update candidate with processed video URL
            widget.onManifestoVideoChange(processedVideo.originalUrl);

            // Clean up local file
            await _cleanupLocalFile(localPath);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Premium video processed and optimized! Available in ${processedVideo.resolutions.length} resolutions.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          } catch (cloudinaryError) {
            debugPrint('🎥 [Cloudinary Error] $cloudinaryError');

            // Fallback to Firebase Storage for videos if Cloudinary fails
            debugPrint('🎥 [Fallback] Using Firebase Storage as fallback...');
            await _uploadVideoToFirebase(file, localPath, fileName);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video uploaded successfully (basic processing)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Handle regular files (PDF, Image, non-premium video) with Firebase
          await _uploadRegularFileToFirebase(file, localPath, fileName, type);
        }
      } catch (e) {
        debugPrint(
          '☁️ [Enhanced Upload] Error processing ${localFile['type']}: $e',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload ${localFile['type']}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Clear local files list after upload
    setState(() {
      _localFiles.clear();
    });

    debugPrint('☁️ [Enhanced Upload] All local files processed');
  }

  // Upload regular files (PDF, Image, non-premium video) to Firebase
  Future<void> _uploadRegularFileToFirebase(
    File file,
    String localPath,
    String fileName,
    String type,
  ) async {
    debugPrint('📄 [Firebase Upload] Uploading regular $type file: $fileName');

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    // Generate unique filename for Firebase
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = widget.candidateData.userId ?? 'unknown_user';
    final firebaseFileName =
        '${type}_${userId}_$timestamp.${_getFileExtension(type)}';

    // Determine storage path based on file type
    String storagePath;
    switch (type) {
      case 'pdf':
        storagePath = 'manifestos/$firebaseFileName';
        break;
      case 'image':
        storagePath = 'manifesto_images/$firebaseFileName';
        break;
      case 'video':
        storagePath = 'manifesto_videos/$firebaseFileName';
        break;
      default:
        debugPrint('📄 [Firebase Upload] Unknown file type: $type');
        return;
    }

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Upload file
    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: _getContentType(type)),
    );

    // Monitor upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      debugPrint(
        '📄 [Firebase Upload] $type upload progress: ${progress.toStringAsFixed(1)}%',
      );
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    debugPrint(
      '📄 [Firebase Upload] $type uploaded successfully. URL: $downloadUrl',
    );

    // Update candidate data based on file type
    if (type == 'pdf') {
      widget.onManifestoPdfChange(downloadUrl);
    } else if (type == 'image') {
      widget.onManifestoImageChange(downloadUrl);
    } else if (type == 'video') {
      widget.onManifestoVideoChange(downloadUrl);
    }

    // Clean up local file after successful upload
    await _cleanupLocalFile(localPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$type uploaded successfully (${fileSizeMB.toStringAsFixed(1)}MB)',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Fallback method for video upload to Firebase (when Cloudinary fails)
  Future<void> _uploadVideoToFirebase(
    File file,
    String localPath,
    String fileName,
  ) async {
    debugPrint('🎥 [Firebase Fallback] Uploading video to Firebase Storage...');

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = widget.candidateData.userId ?? 'unknown_user';
    final firebaseFileName = 'video_${userId}_$timestamp.mp4';
    final storagePath = 'manifesto_videos/$firebaseFileName';

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      debugPrint(
        '🎥 [Firebase Fallback] Upload progress: ${progress.toStringAsFixed(1)}%',
      );
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    debugPrint(
      '🎥 [Firebase Fallback] Video uploaded successfully. URL: $downloadUrl',
    );

    // Update candidate with video URL
    widget.onManifestoVideoChange(downloadUrl);

    // Clean up local file
    await _cleanupLocalFile(localPath);
  }

  // Helper methods
  String _getFileExtension(String type) {
    switch (type) {
      case 'pdf':
        return 'pdf';
      case 'image':
        return 'jpg';
      case 'video':
        return 'mp4';
      default:
        return 'tmp';
    }
  }

  String _getContentType(String type) {
    switch (type) {
      case 'pdf':
        return 'application/pdf';
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  // Method to be called when save button is pressed
  Future<void> uploadPendingFiles() async {
    // First, upload any pending local files
    if (_localFiles.isNotEmpty) {
      debugPrint(
        '💾 [Save] Uploading ${_localFiles.length} pending local files to Firebase...',
      );
      await _uploadLocalFilesToFirebase();
    } else {
      debugPrint('💾 [Save] No pending local files to upload');
    }

    // Then, delete any files marked for deletion
    await _deleteMarkedFiles();
  }

  // Delete files marked for deletion from Firebase Storage
  Future<void> _deleteMarkedFiles() async {
    final data = widget.editedData ?? widget.candidateData;

    // Delete PDF if marked
    if (_isPdfMarkedForDeletion && data.extraInfo?.manifesto?.pdfUrl != null) {
      await _deleteFileFromStorage(data.extraInfo!.manifesto!.pdfUrl!, 'PDF');
      widget.onManifestoPdfChange(''); // Clear URL
      _isPdfMarkedForDeletion = false; // Reset flag
    }

    // Delete Image if marked
    if (_isImageMarkedForDeletion &&
        data.extraInfo?.manifesto?.image != null &&
        data.extraInfo!.manifesto!.image!.isNotEmpty) {
      await _deleteFileFromStorage(data.extraInfo!.manifesto!.image!, 'Image');
      widget.onManifestoImageChange(''); // Clear URL
      _isImageMarkedForDeletion = false; // Reset flag
    }

    // Delete Video if marked
    if (_isVideoMarkedForDeletion &&
        data.extraInfo?.manifesto?.videoUrl != null) {
      await _deleteFileFromStorage(
        data.extraInfo!.manifesto!.videoUrl!,
        'Video',
      );
      widget.onManifestoVideoChange(''); // Clear URL
      _isVideoMarkedForDeletion = false; // Reset flag
    }
  }

  // Helper method to delete a file from Firebase Storage
  Future<void> _deleteFileFromStorage(String fileUrl, String fileType) async {
    try {
      debugPrint(
        '🗑️ [Storage Delete] Deleting $fileType from Firebase Storage: $fileUrl',
      );

      final storageRef = FirebaseStorage.instance.refFromURL(fileUrl);
      await storageRef.delete();

      debugPrint(
        '🗑️ [Storage Delete] Successfully deleted $fileType from Firebase Storage',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileType deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Storage Delete] Failed to delete $fileType: $e');

      // Show warning but don't fail the entire save operation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: $fileType may still exist in storage'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Helper method to extract filename from URL
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
    final data = widget.editedData ?? widget.candidateData;
    final manifesto = data.extraInfo?.manifesto?.title ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          80,
        ), // Added 80px bottom padding to prevent content from being hidden behind floating action buttons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manifesto Title
            Text(
              AppLocalizations.of(context)!.manifestoTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
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
              onChanged: (v) => widget.onManifestoTitleChange(v),
            ),
            const SizedBox(height: 16),

            // Manifesto Promises (Dynamic Add/Delete)
            PromiseManagementSection(
              promiseControllers: _promiseControllers,
              onPromisesChange: widget.onManifestoPromisesChange,
              isEditing: widget.isEditing,
            ),

            const SizedBox(height: 16),

            // File Upload Section
            FileUploadSection(
              candidateData: widget.candidateData,
              isEditing: widget.isEditing,
              onManifestoPdfChange: widget.onManifestoPdfChange,
              onManifestoImageChange: widget.onManifestoImageChange,
              onManifestoVideoChange: widget.onManifestoVideoChange,
              onLocalFilesUpdate: (files) {
                setState(() {
                  _localFiles = files;
                });
              },
            ),

            // Display uploaded files (both in view and edit mode)
            if (data.extraInfo?.manifesto?.pdfUrl != null &&
                data.extraInfo!.manifesto!.pdfUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isPdfMarkedForDeletion
                      ? Colors.red.shade100
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isPdfMarkedForDeletion
                        ? Colors.red.shade300
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: _isPdfMarkedForDeletion
                          ? Colors.red.shade900
                          : Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.manifestoPdf,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isPdfMarkedForDeletion
                                  ? Colors.red.shade900
                                  : Colors.red.shade700,
                              decoration: _isPdfMarkedForDeletion
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            _getFileNameFromUrl(
                              data.extraInfo!.manifesto!.pdfUrl!,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPdfMarkedForDeletion
                                  ? Colors.red.shade600
                                  : Colors.grey,
                              decoration: _isPdfMarkedForDeletion
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (_isPdfMarkedForDeletion) ...[
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.willBeDeletedWhenYouSave,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Checkbox for marking deletion
                    Checkbox(
                      value: _isPdfMarkedForDeletion,
                      onChanged: (checked) async {
                        if (checked == true) {
                          final confirmed = await ConfirmationDialog.show(
                            context: context,
                            title: AppLocalizations.of(
                              context,
                            )!.markPdfForDeletion,
                            content: AppLocalizations.of(
                              context,
                            )!.pdfDeletionWarning,
                            confirmText: AppLocalizations.of(
                              context,
                            )!.markForDeletion,
                          );
                          if (confirmed == true) {
                            setState(() => _isPdfMarkedForDeletion = true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.pdfMarkedForDeletion,
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } else {
                          setState(() => _isPdfMarkedForDeletion = false);
                        }
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
            if (data.extraInfo?.manifesto?.image != null &&
                data.extraInfo!.manifesto!.image!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isImageMarkedForDeletion
                      ? Colors.red.shade100
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isImageMarkedForDeletion
                        ? Colors.red.shade300
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: _isImageMarkedForDeletion
                              ? Colors.red.shade900
                              : Colors.green.shade700,
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
                                  color: _isImageMarkedForDeletion
                                      ? Colors.red.shade900
                                      : Colors.green.shade700,
                                  decoration: _isImageMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                _getFileNameFromUrl(
                                  data.extraInfo!.manifesto!.image!,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isImageMarkedForDeletion
                                      ? Colors.red.shade600
                                      : Colors.grey,
                                  decoration: _isImageMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (_isImageMarkedForDeletion) ...[
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.willBeDeletedWhenYouSave,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Checkbox for marking deletion
                        Checkbox(
                          value: _isImageMarkedForDeletion,
                          onChanged: (checked) async {
                            if (checked == true) {
                              final confirmed = await ConfirmationDialog.show(
                                context: context,
                                title: AppLocalizations.of(
                                  context,
                                )!.markImageForDeletion,
                                content: AppLocalizations.of(
                                  context,
                                )!.imageDeletionWarning,
                                confirmText: AppLocalizations.of(
                                  context,
                                )!.markForDeletion,
                              );
                              if (confirmed == true) {
                                setState(
                                  () => _isImageMarkedForDeletion = true,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.imageMarkedForDeletion,
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } else {
                              setState(() => _isImageMarkedForDeletion = false);
                            }
                          },
                          activeColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ReusableImageWidget(
                      imageUrl: data.extraInfo!.manifesto!.image!,
                      fit: BoxFit.contain,
                      minHeight: 120,
                      maxHeight: 200,
                      borderColor: Colors.grey.shade300,
                      fullScreenTitle: 'Manifesto Image',
                    ),
                  ],
                ),
              ),
            ],
            if (data.extraInfo?.manifesto?.videoUrl != null &&
                data.extraInfo!.manifesto!.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isVideoMarkedForDeletion
                      ? Colors.red.shade100
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isVideoMarkedForDeletion
                        ? Colors.red.shade300
                        : Colors.purple.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.video_call,
                          color: _isVideoMarkedForDeletion
                              ? Colors.red.shade900
                              : Colors.purple.shade700,
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
                                  color: _isVideoMarkedForDeletion
                                      ? Colors.red.shade900
                                      : Colors.purple.shade700,
                                  decoration: _isVideoMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                _getFileNameFromUrl(
                                  data.extraInfo!.manifesto!.videoUrl!,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isVideoMarkedForDeletion
                                      ? Colors.red.shade600
                                      : Colors.grey,
                                  decoration: _isVideoMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              // Premium feature comment
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.premiumFeatureMultiResolution,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isVideoMarkedForDeletion
                                      ? Colors.red.shade700
                                      : Colors.purple,
                                  fontStyle: FontStyle.italic,
                                  decoration: _isVideoMarkedForDeletion
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (_isVideoMarkedForDeletion) ...[
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.willBeDeletedWhenYouSave,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Checkbox for marking deletion
                        Checkbox(
                          value: _isVideoMarkedForDeletion,
                          onChanged: (checked) async {
                            if (checked == true) {
                              final confirmed = await ConfirmationDialog.show(
                                context: context,
                                title: AppLocalizations.of(
                                  context,
                                )!.markVideoForDeletion,
                                content: AppLocalizations.of(
                                  context,
                                )!.videoDeletionWarning,
                                confirmText: AppLocalizations.of(
                                  context,
                                )!.markForDeletion,
                              );
                              if (confirmed == true) {
                                setState(
                                  () => _isVideoMarkedForDeletion = true,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.videoMarkedForDeletion,
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } else {
                              setState(() => _isVideoMarkedForDeletion = false);
                            }
                          },
                          activeColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 16 / 9, // Maintain aspect ratio for video
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.black,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 64,
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.premiumVideo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

