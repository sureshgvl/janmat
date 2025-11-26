import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/services/media_storage_service.dart';
import 'package:janmat/features/monetization/services/plan_service.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';
import 'package:janmat/features/candidate/controllers/candidate_user_controller.dart';

// Image Gallery Viewer Widget for swipeable image viewing
class ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool Function(int) isLocal;

  const ImageGalleryViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.isLocal,
  });

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ReusableImageWidget(
                  imageUrl: widget.images[index],
                  isLocal: widget.isLocal(index),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Upload Progress Dialog Widget
class UploadProgressDialog extends StatefulWidget {
  final String initialMessage;
  final int initialCurrentFile;
  final int initialTotalFiles;

  const UploadProgressDialog({
    super.key,
    required this.initialMessage,
    required this.initialCurrentFile,
    required this.initialTotalFiles,
  });

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  late String message;
  late int currentFile;
  late int totalFiles;

  @override
  void initState() {
    super.initState();
    message = widget.initialMessage;
    currentFile = widget.initialCurrentFile;
    totalFiles = widget.initialTotalFiles;
  }

  // Method to update the message and progress - called from parent via GlobalKey
  void updateProgress({required String message, int? currentFile, int? totalFiles}) {
    if (mounted) {
      setState(() {
        this.message = message;
        if (currentFile != null) this.currentFile = currentFile;
        if (totalFiles != null) this.totalFiles = totalFiles;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalFiles > 0 ? currentFile / totalFiles : 0.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Uploading Files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (totalFiles > 1) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentFile / $totalFiles files',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ] else ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ],
      ),
      actions: null, // No actions - user cannot dismiss
    );
  }
}

class MediaAddPostScreen extends StatefulWidget {
  final MediaItem? existingItem;
  final Function(MediaItem)? onPostCreated;
  final Function(MediaItem, MediaItem)? onPostUpdated;
  final Candidate? candidate;

  const MediaAddPostScreen({
    super.key,
    this.existingItem,
    this.onPostCreated,
    this.onPostUpdated,
    this.candidate,
  });

  @override
  State<MediaAddPostScreen> createState() => _MediaAddPostScreenState();
}

class _MediaAddPostScreenState extends State<MediaAddPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _youtubeLinkController = TextEditingController();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  late List<String> _selectedImages;
  late List<String> _selectedVideos;
  late List<String> _selectedYoutubeLinks;
  bool _isLoading = false;

  // Plan-based limits
  int _maxImages = 10;
  int _maxVideos = 1;
  bool _canUploadMedia = false;

  @override
  void initState() {
    super.initState();
    // Ensure MediaController is initialized
    if (!Get.isRegistered<MediaController>()) {
      Get.put<MediaController>(MediaController());
    }
    _loadNavigationArguments();
    _loadPlanLimits();
    _initializeData();
  }

  void _loadNavigationArguments() {
    // Handle candidate from navigation
    if (widget.candidate != null) {
      _candidate = widget.candidate;
    } else {
      // Try to get candidate from arguments
      final candidateArg = Get.arguments as Candidate?;
      if (candidateArg != null) {
        _candidate = candidateArg;
      } else if (Get.arguments is Map<String, dynamic>) {
        final args = Get.arguments as Map<String, dynamic>;
        if (args.containsKey('candidate')) {
          _candidate = args['candidate'] as Candidate?;
        }
      }
    }
  }

  late Candidate? _candidate;

  Future<void> _loadPlanLimits() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _canUploadMedia = await PlanService.canUploadMedia(currentUser.uid);
        final mediaLimit = await PlanService.getMediaUploadLimit(currentUser.uid);
        _maxImages = mediaLimit == -1 ? 50 : (mediaLimit ~/ 3).clamp(1, 10);
        _maxVideos = 1; // Keep video limit as 1 for all plans
      }
    } catch (e) {
      AppLogger.candidateError('Error saving post: $e');
      if (mounted) {
        SnackbarUtils.showError('Failed to save post: $e');
      }
    }
  }

  void _initializeData() {
    if (widget.existingItem != null) {
      _titleController.text = widget.existingItem!.title;
      _selectedImages = [...widget.existingItem!.images];
      _selectedVideos = [...widget.existingItem!.videos];
      _selectedYoutubeLinks = [...widget.existingItem!.youtubeLinks];
    } else {
      _selectedImages = [];
      _selectedVideos = [];
      _selectedYoutubeLinks = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _youtubeLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem != null ? 'Edit Post' : 'Create Post'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _savePost,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(_isLoading ? 'Posting...' : 'Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.blue.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title Input
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Media Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Add Media Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddMediaOptions(context),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Add Photo/Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddYoutubeDialog(),
                          icon: const Icon(Icons.link),
                          label: const Text('YouTube Link'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Selected Media Preview
                  if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMediaPreview(),
                  ],
                ],
              ),
            ),

            // YouTube Links List
            if (_selectedYoutubeLinks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildYoutubeLinksList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    final allMedia = [
      ..._selectedImages.map((img) => {'type': 'image', 'url': img}),
      ..._selectedVideos.map((vid) => {'type': 'video', 'url': vid}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected Media (${allMedia.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: allMedia.map((media) {
            final index = allMedia.indexOf(media);
            return GestureDetector(
              onTap: media['type'] == 'image'
                  ? () => _viewImageInGallery(index, allMedia.where((m) => m['type'] == 'image').toList())
                  : null,
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: media['type'] == 'image'
                          ? ReusableImageWidget(
                              imageUrl: media['url']!,
                              isLocal: MediaStorageService.isLocalMedia(media['url']!),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                Icons.videocam,
                                color: Colors.grey.shade600,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  // Close button - positioned better with shadow for visibility
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeMedia(media['type']!, media['url']!),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  if (media['type'] == 'video')
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // View image in gallery with swipe functionality
  void _viewImageInGallery(int initialIndex, List<Map<String, String?>> images) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          images: images.map((img) => img['url']!).toList(),
          initialIndex: initialIndex,
          isLocal: (index) => MediaStorageService.isLocalMedia(images[index]['url']!),
        ),
      ),
    );
  }

  Widget _buildYoutubeLinksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('YouTube Links', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._selectedYoutubeLinks.map((link) {
          final index = _selectedYoutubeLinks.indexOf(link);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    link,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeYoutubeLink(index),
                  icon: const Icon(Icons.close, color: Colors.red),
                  iconSize: 16,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showAddMediaOptions(BuildContext context) {
    if (!_canUploadMedia) {
      SnackbarUtils.showError('Media upload is not available for your current plan');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Media',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_selectedImages.length < _maxImages)
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Photos from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImages();
                },
              ),
            if (_selectedVideos.length < _maxVideos)
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
                title: const Text('Video from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickVideo();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.purple),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddYoutubeDialog() {
    if (_selectedYoutubeLinks.length >= 5) {
      SnackbarUtils.showError('Maximum 5 YouTube links allowed');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add YouTube Link'),
        content: TextField(
          controller: _youtubeLinkController,
          decoration: const InputDecoration(
            labelText: 'YouTube URL',
            hintText: 'https://www.youtube.com/watch?v=...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = _youtubeLinkController.text.trim();
              if (url.isNotEmpty && (url.contains('youtube.com') || url.contains('youtu.be'))) {
                setState(() {
                  _selectedYoutubeLinks.add(url);
                });
                _youtubeLinkController.clear();
                Navigator.of(context).pop();
              } else {
                SnackbarUtils.showError('Please enter a valid YouTube URL');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      if (kIsWeb) {
        // Web: Use file picker to get bytes directly and upload immediately
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true, // Get bytes directly
        );

        if (result != null && result.files.isNotEmpty) {
          for (final file in result.files) {
            if (_selectedImages.length >= _maxImages) break;

            if (file.bytes != null) {
              await _uploadImageBytesToFirebase(file.bytes!, file.name);
            }
          }
        }
      } else {
        // Mobile: Use image_picker
        final images = await _imagePicker.pickMultiImage(maxWidth: 1920, maxHeight: 1080);
        if (images.isNotEmpty) {
          for (final image in images) {
            if (_selectedImages.length < _maxImages) {
              await _saveImageLocally(image.path);
            }
          }
        }
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (video != null && _selectedVideos.length < _maxVideos) {
        await _saveVideoLocally(video.path);
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to pick video: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1080);
      if (image != null && _selectedImages.length < _maxImages) {
        await _saveImageLocally(image.path);
      }
    } catch (e) {
      SnackbarUtils.showError('Failed to take photo: $e');
    }
  }

  Future<void> _saveImageLocally(String imagePath) async {
    try {
      final candidateId = _candidate?.candidateId ?? 'temp-candidate-id';

      // On web, upload immediately to Firebase to avoid blob URL issues
      if (kIsWeb) {
        AppLogger.candidate('🌐 [Web Upload] Uploading image directly to Firebase to avoid blob URLs');

        // Show upload progress for immediate feedback
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            title: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Uploading Image...'),
              ],
            ),
            content: Text('Please wait while we upload your image...'),
          ),
        );

        try {
          // For web, we need to handle blob URLs differently
          // Since blob URLs can't be fetched via HTTP, we need to get the bytes directly
          if (imagePath.startsWith('blob:')) {
            // Convert blob URL to Firebase URL using the blob upload method
            final firebaseUrl = await _fileUploadService.uploadBlobUrlToFirebase(imagePath);
            if (firebaseUrl != null) {
              setState(() {
                _selectedImages.add(firebaseUrl);
              });
              AppLogger.candidate('✅ Image uploaded to Firebase: $firebaseUrl');
            } else {
              throw Exception('Blob upload returned null');
            }
          } else {
            // Fallback for non-blob URLs (shouldn't happen on web)
            final firebaseUrl = await _fileUploadService.uploadLocalPhotoToFirebase(imagePath);
            if (firebaseUrl != null) {
              setState(() {
                _selectedImages.add(firebaseUrl);
              });
              AppLogger.candidate('✅ Image uploaded to Firebase: $firebaseUrl');
            } else {
              throw Exception('Upload returned null');
            }
          }

          if (mounted) {
            Navigator.of(context).pop(); // Dismiss progress dialog
          }
        } catch (uploadError) {
          if (mounted) {
            Navigator.of(context).pop(); // Dismiss progress dialog
          }
          AppLogger.candidateError('❌ Web upload failed: $uploadError');
          SnackbarUtils.showError('Failed to upload image: $uploadError');
          return; // Don't re-throw, just show error
        }
      } else {
        // Mobile: Save locally first (platform-aware)
        final localReference = await MediaStorageService.saveMediaLocally(
          imagePath,
          candidateId,
          'image',
        );

        // Add to selected images list
        setState(() {
          _selectedImages.add(localReference);
        });

        AppLogger.candidate('✅ Image saved locally: $localReference');
      }
    } catch (e) {
      AppLogger.candidateError('❌ Error saving/uploading image: $e');
      SnackbarUtils.showError('Failed to save image: $e');
    }
  }

  Future<void> _saveVideoLocally(String videoPath) async {
    try {
      final candidateId = _candidate?.candidateId ?? 'temp-candidate-id';

      // Save locally first (platform-aware)
      final localReference = await MediaStorageService.saveMediaLocally(
        videoPath,
        candidateId,
        'video',
      );

      // Add to selected videos list
      setState(() {
        _selectedVideos.add(localReference);
      });

      AppLogger.candidate('✅ Video saved locally: $localReference');
    } catch (e) {
      AppLogger.candidateError('❌ Error saving video locally: $e');
      SnackbarUtils.showError('Failed to save video: $e');
    }
  }

  void _removeMedia(String type, String url) {
    setState(() {
      if (type == 'image') {
        _selectedImages.remove(url);
      } else if (type == 'video') {
        _selectedVideos.remove(url);
      }
    });
  }

  void _removeYoutubeLink(int index) {
    setState(() {
      _selectedYoutubeLinks.removeAt(index);
    });
  }

  // Upload image bytes directly to Firebase (web-specific)
  Future<void> _uploadImageBytesToFirebase(Uint8List bytes, String fileName) async {
    try {
      AppLogger.candidate('🌐 [Web Direct Upload] Starting upload for file: $fileName, bytes length: ${bytes.length}');

      // Show upload progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 16),
              Text('Uploading Image...'),
            ],
          ),
          content: Text('Please wait while we upload your image...'),
        ),
      );

      // Generate Firebase storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'media/images/web_upload_${timestamp}_${fileName.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\.]'), '_')}';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      AppLogger.candidate('🌐 [Web Direct Upload] Uploading bytes to Firebase: $storagePath');

      // Upload bytes directly
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.candidate('✅ [Web Direct Upload] Successfully uploaded: $downloadUrl');

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss progress dialog
      }

      setState(() {
        _selectedImages.add(downloadUrl);
      });

      AppLogger.candidate('✅ [Web Direct Upload] Added to selected images, total images: ${_selectedImages.length}');
    } catch (e) {
      AppLogger.candidateError('❌ [Web Direct Upload] Failed: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss progress dialog
      }
      SnackbarUtils.showError('Failed to upload image: $e');
      // Don't re-throw - let the user continue without this image
    }
  }

  // Schedule cleanup of files that are being removed during edit operation (deferred delete pattern)
  Future<void> _cleanupDeletedFiles() async {
    if (widget.existingItem == null) return; // Only for edit operations

    try {
      AppLogger.candidate('🧹 [Cleanup] Starting deferred cleanup of deleted files from edit operation');

      // Get original Firebase URLs from existing item
      final originalImages = widget.existingItem!.images.where((url) => !MediaStorageService.isLocalMedia(url)).toList();
      final originalVideos = widget.existingItem!.videos.where((url) => !MediaStorageService.isLocalMedia(url)).toList();

      // Get current selection (only Firebase URLs, not local paths)
      final currentImages = _selectedImages.where((url) => !MediaStorageService.isLocalMedia(url)).toList();
      final currentVideos = _selectedVideos.where((url) => !MediaStorageService.isLocalMedia(url)).toList();

      // Find files that are in original but not in current selection
      final deletedImages = originalImages.where((url) => !currentImages.contains(url)).toList();
      final deletedVideos = originalVideos.where((url) => !currentVideos.contains(url)).toList();

      // Convert Firebase URLs to storage paths for deferred cleanup
      final storagePathsToDelete = [
        ...deletedImages.map(_extractStoragePath),
        ...deletedVideos.map(_extractStoragePath),
      ];

      AppLogger.candidate('🧹 [Cleanup] Found ${storagePathsToDelete.length} files to schedule for deferred deletion');

      if (storagePathsToDelete.isNotEmpty) {
        // Non-blocking operation - add paths to candidate's deleteStorage array
        Future.microtask(() async {
          try {
            // Build correct hierarchical path for candidate
            final candidateRef = FirebaseFirestore.instance
                .collection('states')
                .doc(_candidate?.location.stateId)
                .collection('districts')
                .doc(_candidate?.location.districtId)
                .collection('bodies')
                .doc(_candidate?.location.bodyId)
                .collection('wards')
                .doc(_candidate?.location.wardId)
                .collection('candidates')
                .doc(_candidate?.candidateId);

            await candidateRef.update({
              'deleteStorage': FieldValue.arrayUnion(storagePathsToDelete),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            AppLogger.candidate('📋 Scheduled ${storagePathsToDelete.length} files for background cleanup (hierarchical path)');
          } catch (e) {
            AppLogger.candidateError('Failed to schedule background cleanup: $e');
          }
        });
      }

      AppLogger.candidate('🧹 [Cleanup] Finished scheduling deferred cleanup of files');
    } catch (e) {
      AppLogger.candidateError('❌ [Cleanup] Error during deferred cleanup scheduling: $e');
    }
  }

  // Extract storage path from Firebase URL for deferred cleanup
  String _extractStoragePath(String firebaseUrl) {
    try {
      // Firebase URL format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{storagePath}?...
      final uri = Uri.parse(firebaseUrl);
      final path = uri.pathSegments.skip(3).join('/'); // Skip v0/b/bucket/o/ parts
      return Uri.decodeComponent(path); // Decode URL encoding
    } catch (e) {
      AppLogger.candidateError('Failed to extract storage path from: $firebaseUrl');
      return firebaseUrl; // Fallback to original URL if parsing fails
    }
  }

  // Upload all local files to Firebase Storage and return Firebase URLs with progress tracking
  Future<List<String>> _uploadLocalFilesToFirebase(
    List<String> localPaths,
    String fileType,
    Function(String) onProgressUpdate,
  ) async {
    return await MediaStorageService.uploadLocalMediaBatch(
      localPaths,
      fileType,
      onProgressUpdate,
    );
  }

  GlobalKey<_UploadProgressDialogState>? _progressDialogKey;
  int _totalFilesToUpload = 0;
  int _currentUploadedCount = 0;

  // Show upload progress dialog
  void _showUploadProgressDialog(int totalFiles) {
    _totalFilesToUpload = totalFiles;
    _currentUploadedCount = 0;
    _progressDialogKey = GlobalKey<_UploadProgressDialogState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UploadProgressDialog(
          key: _progressDialogKey,
          initialMessage: 'Starting upload...',
          initialCurrentFile: 0,
          initialTotalFiles: totalFiles,
        );
      },
    );
  }

  // Show general posting progress dialog
  void _showPostingProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Creating Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Please wait while we create your post...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  // Update upload progress dialog message
  void _updateUploadProgress(String message) {
    if (message == 'Upload completed successfully!') {
      // Close the progress dialog when upload completes
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }
      return;
    }

    if (_progressDialogKey?.currentState != null) {
      // Extract count from message like "Uploading 2/5 files..."
      final regex = RegExp(r'Uploading (\d+)/(\d+)');
      final match = regex.firstMatch(message);

      if (match != null) {
        _currentUploadedCount = int.parse(match.group(1)!);
      }

      _progressDialogKey!.currentState!.updateProgress(
        message: message,
        currentFile: _currentUploadedCount,
        totalFiles: _totalFilesToUpload,
      );
    }
  }

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty) {
      SnackbarUtils.showError('Please enter a title');
      return;
    }

    if (_selectedImages.isEmpty && _selectedVideos.isEmpty && _selectedYoutubeLinks.isEmpty) {
      SnackbarUtils.showError('Please add some media or YouTube links');
      return;
    }

    if (_candidate == null) {
      SnackbarUtils.showError('No candidate found - cannot save post');
      return;
    }

    // Check limits: max 5 images, 1 video, 5 YouTube links per post
    if (_selectedImages.length > 5) {
      SnackbarUtils.showError('Maximum 5 images allowed per post');
      return;
    }

    if (_selectedVideos.length > 1) {
      SnackbarUtils.showError('Maximum 1 video allowed per post');
      return;
    }

    if (_selectedYoutubeLinks.length > 5) {
      SnackbarUtils.showError('Maximum 5 YouTube links allowed per post');
      return;
    }

    // Calculate total files to upload
    final totalLocalImages = _selectedImages.where((url) => MediaStorageService.isLocalMedia(url)).length;
    final totalLocalVideos = _selectedVideos.where((url) => MediaStorageService.isLocalMedia(url)).length;
    final totalFilesToUpload = totalLocalImages + totalLocalVideos;

    // Always show loading dialog when posting
    if (totalFilesToUpload > 0) {
      _showUploadProgressDialog(totalFilesToUpload);
    } else {
      // Show general posting progress dialog
      _showPostingProgressDialog();
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // For EDIT MODE: Clean up files that are being removed
      if (widget.existingItem != null) {
        await _cleanupDeletedFiles();
      }

      // Upload all local files to Firebase Storage and get Firebase URLs with progress tracking
      var firebaseImages = await _uploadLocalFilesToFirebase(_selectedImages, 'image', _updateUploadProgress);
      var firebaseVideos = await _uploadLocalFilesToFirebase(_selectedVideos, 'video', _updateUploadProgress);

      // Close upload progress dialog after all uploads are complete
      if (totalFilesToUpload > 0 && mounted) {
        _updateUploadProgress('Upload completed successfully!');
      }

      // CRITICAL: Ensure no blob URLs are stored in the database
      // Check if any blob URLs remain (upload failures)
      final hasBlobImages = firebaseImages.any((url) => url.startsWith('blob:'));
      final hasBlobVideos = firebaseVideos.any((url) => url.startsWith('blob:'));

      if (hasBlobImages || hasBlobVideos) {
        AppLogger.candidateError('❌ CRITICAL: Blob URLs detected after upload! This will cause issues when app becomes inactive.');
        AppLogger.candidateError('❌ Images with blob URLs: ${firebaseImages.where((url) => url.startsWith('blob:')).toList()}');
        AppLogger.candidateError('❌ Videos with blob URLs: ${firebaseVideos.where((url) => url.startsWith('blob:')).toList()}');

        // Filter out blob URLs to prevent saving corrupted data
        final cleanImages = firebaseImages.where((url) => !url.startsWith('blob:')).toList();
        final cleanVideos = firebaseVideos.where((url) => !url.startsWith('blob:')).toList();

        AppLogger.candidate('🧹 Filtered out blob URLs. Clean images: ${cleanImages.length}, clean videos: ${cleanVideos.length}');

        // Update the variables to use clean URLs
        firebaseImages = cleanImages;
        firebaseVideos = cleanVideos;

        // If no valid media remains, show error
        if (firebaseImages.isEmpty && firebaseVideos.isEmpty && _selectedYoutubeLinks.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop(); // Dismiss progress dialog
            SnackbarUtils.showError('All media uploads failed. Please try again.');
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        // Show warning but allow saving with partial content
        if (mounted) {
          SnackbarUtils.showError('Some media files failed to upload but post will be saved with available content.');
        }
      }

      final String postDate = widget.existingItem != null
          ? widget.existingItem!.date
          : DateTime.now().toIso8601String().split('T')[0];

      final newMediaItem = MediaItem(
        title: _titleController.text.trim(),
        date: postDate,
        images: firebaseImages,
        videos: firebaseVideos,
        youtubeLinks: _selectedYoutubeLinks,
      );

      // STEP 1: Fetch existing media data from Firebase
      final mediaController = Get.find<MediaController>();
      final existingMedia = await mediaController.getMediaGrouped(_candidate!);

      // Check total posts limit: max 5 posts
      if (existingMedia != null && existingMedia.length >= 5) {
        SnackbarUtils.showError('Maximum 5 posts allowed. Please delete some posts first.');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // STEP 2: Combine existing media with new/updated item
      final List<Map<String, dynamic>> allGroupedMedia = [];

      if (existingMedia != null && existingMedia.isNotEmpty) {
        allGroupedMedia.addAll(existingMedia);
        AppLogger.candidate('Found ${existingMedia.length} existing media posts');
      } else {
        AppLogger.candidate('No existing media found, creating first post');
      }

      final Map<String, dynamic> mediaDataToSave = newMediaItem.toJson();

      // Check if this is an edit operation
      if (widget.existingItem != null) {
        // EDIT MODE: Find and replace the existing item
        final existingTitle = widget.existingItem!.title;
        final existingDate = widget.existingItem!.date;

        bool itemReplaced = false;
        for (int i = 0; i < allGroupedMedia.length; i++) {
          final existingItemData = allGroupedMedia[i];
          final parsedItem = MediaItem.fromJson(existingItemData);

          // Match by title and date
          if (parsedItem.title == existingTitle && parsedItem.date == existingDate) {
            // Replace the existing item with updated data
            allGroupedMedia[i] = mediaDataToSave;
            itemReplaced = true;
            AppLogger.candidate('Replaced existing media item at index $i: "$existingTitle" ($existingDate)');
            break;
          }
        }

        if (itemReplaced) {
          AppLogger.candidate('Successfully updated existing media post');
        } else {
          AppLogger.candidateError('Could not find existing item to replace! Title: "$existingTitle", Date: $existingDate');
          // Fallback: add new item anyway
          allGroupedMedia.insert(0, mediaDataToSave);
        }
      } else {
        // CREATE MODE: Add the new media item at the beginning (most recent first)
        allGroupedMedia.insert(0, mediaDataToSave);
        AppLogger.candidate('Added new media post at the beginning');
      }

      AppLogger.candidate('Saving ${allGroupedMedia.length} media posts');

      // STEP 3: Save the combined media array
      final success = await mediaController.saveMediaGrouped(_candidate!, allGroupedMedia);

      if (success) {
        // Dismiss the posting progress dialog
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss progress dialog
        }

        // Show success message safely
        if (mounted) {
          SnackbarUtils.showSuccess('Post created successfully!');
        }

        // Refresh candidate data so media tab shows updated posts instantly
        try {
          final candidateController = Get.find<CandidateUserController>();
          await candidateController.refreshCandidateData();

          // Force reactive update to trigger UI rebuild
          candidateController.update();

          AppLogger.candidate('✅ Successfully refreshed candidate data after posting');
        } catch (e) {
          AppLogger.candidateError('❌ Error refreshing candidate data after post: $e');
        }

        // Call callbacks for backward compatibility
        if (widget.existingItem != null) {
          widget.onPostUpdated?.call(widget.existingItem!, newMediaItem);
        } else {
          widget.onPostCreated?.call(newMediaItem);
        }

        // Navigate back immediately without delay to avoid context issues
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Dismiss the posting progress dialog on failure
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss progress dialog
        }

        if (mounted) {
          SnackbarUtils.showError('Failed to create post. Please try again.');
        }
      }
    } catch (e) {
      // Dismiss the posting progress dialog on error
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss progress dialog
      }

      AppLogger.candidateError('Error saving post: $e');
      if (mounted) {
        SnackbarUtils.showScaffoldError(context, 'Failed to save post: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
