import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import 'package:janmat/services/file_upload_service.dart';
import 'package:janmat/services/plan_service.dart';
import 'package:janmat/features/common/reusable_image_widget.dart';
import 'package:janmat/features/common/reusable_video_widget.dart';
import 'package:janmat/features/common/confirmation_dialog.dart';
import 'package:janmat/features/candidate/widgets/demo_data_modal.dart';
import 'package:janmat/features/candidate/controllers/media_controller.dart';

// Media Item Model
class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  Map<String, int> likes; // Track likes for each media item
  String? addedDate; // New field for added date display

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    Map<String, int>? likes,
    this.addedDate,
  }) : date = date ?? DateTime.now().toIso8601String().split('T')[0],
       images = images ?? [],
       videos = videos ?? [],
       youtubeLinks = youtubeLinks ?? [],
       likes = likes ?? {};

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'images': images,
      'videos': videos,
      'youtubeLinks': youtubeLinks,
      'likes': likes,
      'added_date': addedDate,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] ?? '',
      date: json['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      images: List<String>.from(json['images'] ?? []),
      videos: List<String>.from(json['videos'] ?? []),
      youtubeLinks: List<String>.from(json['youtubeLinks'] ?? []),
      likes: Map<String, int>.from(json['likes'] ?? {}),
      addedDate: json['added_date'],
    );
  }
}

// File size validation result class
class FileSizeValidation {
  final bool isValid;
  final double fileSizeMB;
  final String message;
  final String? recommendation;
  final bool warning;

  FileSizeValidation({
    required this.isValid,
    required this.fileSizeMB,
    required this.message,
    this.recommendation,
    this.warning = false,
  });
}

// Main MediaTabEdit Widget
class MediaTabEdit extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(List<Map<String, dynamic>>) onMediaChange;

  const MediaTabEdit({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onMediaChange,
  });

  @override
  State<MediaTabEdit> createState() => MediaTabEditState();
}

class MediaTabEditState extends State<MediaTabEdit> {
  final MediaController _mediaController = Get.find<MediaController>();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  late List<MediaItem> _mediaItems;
  final Set<String> _uploadedMediaUrls = {};

  // Files marked for deletion (will be deleted on save)
  final Map<String, bool> _markedForDeletion = {};
  bool _isSaving = false;

  // Plan-based limits
  int _maxImagesPerItem = 10;
  int _maxVideosPerItem = 1;
  bool _canUploadMedia = false;

  @override
  void initState() {
    super.initState();
    _loadPlanLimits();
    _loadMedia();
  }

  Future<void> _loadPlanLimits() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _canUploadMedia = await PlanService.canUploadMedia(currentUser.uid);
      final mediaLimit = await PlanService.getMediaUploadLimit(currentUser.uid);
      _maxImagesPerItem = mediaLimit == -1 ? 50 : (mediaLimit ~/ 3).clamp(1, 10); // Distribute limit across items
      _maxVideosPerItem = 1; // Keep video limit as 1 for all plans
    }
  }

  @override
  void didUpdateWidget(MediaTabEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editedData != widget.editedData ||
        oldWidget.candidateData != widget.candidateData) {
      _loadMedia();
    }
  }

  @override
  void dispose() {
    _cleanupDanglingFiles();
    super.dispose();
  }

  void _loadMedia() {
    final data = widget.editedData ?? widget.candidateData;
    final media = data.media ?? [];

    // Handle both old format (individual Media objects) and new format (grouped MediaItem maps)
    _mediaItems = [];

    if (media.isNotEmpty) {
      // Check the first item to determine format
      final firstItem = media.first;
      if (firstItem is Map<String, dynamic>) {
        // New grouped format - each item is already a MediaItem map
        final validItems = media.whereType<Map<String, dynamic>>();
        AppLogger.candidate('🎯 [MEDIA_EDIT] Found ${validItems.length} map items out of ${media.length} total items');

        _mediaItems = validItems.map((item) {
          final itemMap = item as Map<String, dynamic>;
          AppLogger.candidate('🎯 [MEDIA_EDIT] Parsing item: title=${itemMap['title']}, images=${(itemMap['images'] as List?)?.length ?? 0}');

          // Debug image URLs
          final images = itemMap['images'] as List? ?? [];
          for (int i = 0; i < images.length; i++) {
            AppLogger.candidate('🎯 [MEDIA_EDIT] Image[$i]: ${images[i]}');
          }

          return MediaItem.fromJson(itemMap);
        }).toList();

        AppLogger.candidate('🎯 [MEDIA_EDIT] Loaded ${media.length} grouped MediaItems (new format). Total images: ${_mediaItems.expand((item) => item.images).length}');
      } else if (firstItem is Media) {
        // Old format - individual Media objects need to be converted to grouped format
        // Group by title and date (which were combined in the old format)
        final Map<String, List<Media>> groupedMedia = {};

        for (final item in media) {
          final mediaObj = item as Media;
          // Extract title from Media attributes (caption contains "title - date")
          final title = mediaObj.title ?? 'Untitled';
          final date = mediaObj.uploadedAt ?? DateTime.now().toIso8601String().split('T')[0];

          final groupKey = '$title|$date';

          if (!groupedMedia.containsKey(groupKey)) {
            groupedMedia[groupKey] = [];
          }
          groupedMedia[groupKey]!.add(mediaObj as Media);
        }

        // Convert grouped Media objects to MediaItem objects
        for (final entry in groupedMedia.entries) {
          final keyParts = entry.key.split('|');
          final title = keyParts[0];
          final date = keyParts[1];

          final List<String> images = [];
          final List<String> videos = [];
          final List<String> youtubeLinks = [];

          for (final mediaObj in entry.value) {
            switch (mediaObj.type) {
              case 'image':
                images.add(mediaObj.url);
                break;
              case 'video':
                videos.add(mediaObj.url);
                break;
              case 'youtube':
                youtubeLinks.add(mediaObj.url);
                break;
            }
          }

          _mediaItems.add(MediaItem(
            title: title,
            date: date,
            images: images,
            videos: videos,
            youtubeLinks: youtubeLinks,
          ));
        }

        AppLogger.candidate('🎯 [MEDIA_EDIT] Converted ${media.length} individual Media objects to ${_mediaItems.length} grouped MediaItems');
      } else {
        AppLogger.candidateError('🎯 [MEDIA_EDIT] Unexpected media item format: ${firstItem.runtimeType}');
        _mediaItems = [];
      }
    }

    // Collect all media URLs for upload tracking
    _uploadedMediaUrls.clear();
    for (final item in _mediaItems) {
      _uploadedMediaUrls.addAll(item.images);
      _uploadedMediaUrls.addAll(item.videos);
      _uploadedMediaUrls.addAll(item.youtubeLinks);
    }
  }

  void _updateMedia() {
    final mediaJson = _mediaItems.map((item) => item.toJson()).toList();
    widget.onMediaChange(mediaJson);
  }

  // Public method to get current media data after upload/updates
  List<dynamic> getMediaData() {
    return _mediaItems.map((item) => item.toJson()).toList();
  }

  Future<void> _cleanupDanglingFiles() async {
    try {
      await _fileUploadService.cleanupTempPhotos();
      AppLogger.candidate('🗑️ Cleaned up all temporary local files');
      _uploadedMediaUrls.clear();
    } catch (e) {
      AppLogger.candidateError('Error during file cleanup: $e');
    }
  }

  void _addNewMediaItem() {
    setState(() {
      _mediaItems.add(MediaItem());
    });
    _updateMedia();
  }

  void _removeMediaItem(int index) {
    // Collect URLs from the item being removed so we can clean them up later
    final itemBeingRemoved = _mediaItems[index];
    final mediaUrlsToDelete = [
      ...itemBeingRemoved.images,
      ...itemBeingRemoved.videos,
      ...itemBeingRemoved.youtubeLinks,
    ].where((url) => url.contains('firebasestorage.googleapis.com') && !url.startsWith('local:')).toList();

    // Add to tracked deletion list
    setState(() {
      // Mark URLs for deletion from storage
      for (final url in mediaUrlsToDelete) {
        _markedForDeletion[url] = true;
      }
      // Remove the item from local state
      _mediaItems.removeAt(index);
    });
    _updateMedia();
  }

  void _updateMediaItem(int index, MediaItem updatedItem) {
    setState(() {
      _mediaItems[index] = updatedItem;
    });
    _updateMedia();
  }

  void _markItemForDeletion(String itemId, bool mark) {
    setState(() {
      if (mark) {
        _markedForDeletion[itemId] = true;
      } else {
        _markedForDeletion.remove(itemId);
      }
    });
  }

  void _addImageToItem(int itemIndex, String imageUrl) {
    setState(() {
      if (_mediaItems[itemIndex].images.length < _maxImagesPerItem) {
        _mediaItems[itemIndex].images.add(imageUrl);
        _updateMedia();
      }
    });
  }

  void _addVideoToItem(int itemIndex, String videoUrl) {
    setState(() {
      if (_mediaItems[itemIndex].videos.length < _maxVideosPerItem) {
        _mediaItems[itemIndex].videos.add(videoUrl);
        _updateMedia();
      }
    });
  }

  void _addYoutubeLinkToItem(int itemIndex, String youtubeUrl) {
    setState(() {
      _mediaItems[itemIndex].youtubeLinks.add(youtubeUrl);
      _updateMedia();
    });
  }

  void _removeImageFromItem(int itemIndex, int imageIndex) {
    setState(() {
      _mediaItems[itemIndex].images.removeAt(imageIndex);
      _updateMedia();
    });
  }

  void _removeVideoFromItem(int itemIndex, int videoIndex) {
    setState(() {
      _mediaItems[itemIndex].videos.removeAt(videoIndex);
      _updateMedia();
    });
  }

  void _removeYoutubeLinkFromItem(int itemIndex, int linkIndex) {
    setState(() {
      _mediaItems[itemIndex].youtubeLinks.removeAt(linkIndex);
      _updateMedia();
    });
  }

  Future<void> _pickAndUploadImage(int itemIndex) async {
    try {
      // Show compression progress dialog
      final progressDialog = Get.dialog(
        const AlertDialog(
          title: Text('Optimizing Image...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Compressing image for faster upload...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85, // Base quality, will be optimized further
      );

      if (pickedFile == null) {
        if (Get.isDialogOpen!) Get.back(); // Close progress dialog
        return;
      }

      // PHASE 3 INTEGRATION: Use advanced compression instead of basic local save
      final optimizedFile = await _fileUploadService.optimizeImageSmartly(
        pickedFile,
        purpose: ImagePurpose.achievement, // Automatically compresses appropriately
      );

      // Close progress dialog
      if (Get.isDialogOpen!) Get.back();

      // Show compression results
      if (optimizedFile != null && optimizedFile.path != pickedFile.path) {
        final report = await _fileUploadService.generateOptimizationReport(pickedFile, optimizedFile);
        Get.snackbar(
          'Image Compressed',
          report,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
        );
      }

      // Continue with existing local save logic using optimized file
      final fileToSave = optimizedFile ?? pickedFile;
      await _saveImageLocally(itemIndex, fileToSave.path);

    } catch (e) {
      // Clean up dialogs if needed
      if (Get.isDialogOpen!) Get.back();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageLocally(int itemIndex, String imagePath) async {
    try {
      AppLogger.candidate('💾 [Media Image] Starting local save process...');

      // Step 1: Validate file size
      AppLogger.candidate('💾 [Media Image] Step 1: Validating file size...');
      final validation = await _fileUploadService.validateMediaFileSize(
        imagePath,
        'image',
      );

      if (!validation.isValid) {
        AppLogger.candidate('💾 [Media Image] File too large');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      AppLogger.candidate('💾 [Media Image] File size validation passed');

      // Step 2: Save to local storage
      AppLogger.candidate('💾 [Media Image] Step 2: Saving to local storage...');
      final candidateId = widget.candidateData.candidateId;
      final localPath = await _fileUploadService.saveExistingFileLocally(
        imagePath,
        candidateId,
        'media_image',
      );

      if (localPath == null) {
        AppLogger.candidate('💾 [Media Image] Failed to save locally');
        throw Exception('Failed to save image locally');
      }

      AppLogger.candidate('💾 [Media Image] Saved locally at: $localPath');

      // Step 3: Add to media item
      _addImageToItem(itemIndex, localPath);

      AppLogger.candidate('💾 [Media Image] Image added to media item');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image saved locally (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      AppLogger.candidateError('💾 [Media Image] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadImageToItem(int itemIndex, String imagePath) async {
    try {
      final candidateId = widget.candidateData.candidateId;
      final localPath = await _fileUploadService.savePhotoLocally(
        candidateId,
        'media_image_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (localPath == null) return;

      final validation = await _fileUploadService.validateMediaFileSize(
        localPath,
        'image',
      );

      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      _addImageToItem(itemIndex, localPath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image saved locally'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  Future<void> _pickAndUploadVideo(int itemIndex) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) return;

      await _uploadVideoToItem(itemIndex, pickedFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadVideoToItem(int itemIndex, String videoPath) async {
    try {
      // Validate video file size
      final validation = await _fileUploadService.validateMediaFileSize(
        videoPath,
        'video',
      );

      if (!validation.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Save video to local storage first for consistency with image flow
      final candidateId = widget.candidateData.candidateId;
      final localPath = await _fileUploadService.saveExistingFileLocally(
        videoPath,
        candidateId,
        'media_video',
      );

      if (localPath == null) {
        throw Exception('Failed to save video locally');
      }

      // Add the local path to the media item
      _addVideoToItem(itemIndex, localPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video saved locally (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add video: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> uploadPendingFiles() async {
    AppLogger.candidate('📤 [Media] Starting upload of pending files...');

    // First delete marked files from Firebase Storage
    if (_markedForDeletion.isNotEmpty) {
      AppLogger.candidate('🗑️ [Media] Deleting files from Firebase Storage...');
      final List<String> urlsToDelete = _markedForDeletion.keys.toList();
      for (final url in urlsToDelete) {
        try {
          // Delete from Firebase Storage
          await _fileUploadService.deleteFile(url);
          _markedForDeletion.remove(url);
          AppLogger.candidate('🗑️ [Media] Deleted file from storage: $url');
        } catch (e) {
          AppLogger.candidateError('🗑️ [Media] Failed to delete file $url: $e');
        }
      }
      AppLogger.candidate('🗑️ [Media] Finished deleting files from storage');
    }

    for (int itemIndex = 0; itemIndex < _mediaItems.length; itemIndex++) {
      final item = _mediaItems[itemIndex];

      // Upload images for this item
      for (int i = 0; i < item.images.length; i++) {
        final imageUrl = item.images[i];
        if (_fileUploadService.isLocalPath(imageUrl)) {
          try {
            AppLogger.candidate('📤 [Media] Uploading image: $imageUrl');

            final fileName =
                'media_image_${widget.candidateData.candidateId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final storagePath = 'media/images/$fileName';

            // Strip 'local:' prefix if present to get actual file path
            final actualImagePath = imageUrl.replaceFirst('local:', '');
            final downloadUrl = await _fileUploadService.uploadFile(
              actualImagePath,
              storagePath,
              'image/jpeg',
            );

            if (downloadUrl != null) {
              setState(() {
                _mediaItems[itemIndex].images[i] = downloadUrl;
              });
              _uploadedMediaUrls.add(downloadUrl); // Track successfully uploaded URLs
              AppLogger.candidate('📤 [Media] Successfully uploaded image');
            }
          } catch (e) {
            AppLogger.candidateError('📤 [Media] Failed to upload image: $e');
          }
        }
      }

      // Upload videos for this item
      for (int i = 0; i < item.videos.length; i++) {
        final videoUrl = item.videos[i];
        if (_fileUploadService.isLocalPath(videoUrl)) {
          try {
            AppLogger.candidate('📤 [Media] Uploading video: $videoUrl');

            final fileName =
                'media_video_${widget.candidateData.candidateId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
            final storagePath = 'media/videos/$fileName';

            // Strip 'local:' prefix if present to get actual file path
            final actualVideoPath = videoUrl.replaceFirst('local:', '');
            final downloadUrl = await _fileUploadService.uploadFile(
              actualVideoPath,
              storagePath,
              'video/mp4',
            );

            if (downloadUrl != null) {
              setState(() {
                _mediaItems[itemIndex].videos[i] = downloadUrl;
              });
              _uploadedMediaUrls.add(downloadUrl); // Track successfully uploaded URLs
              AppLogger.candidate('📤 [Media] Successfully uploaded video');
            }
          } catch (e) {
            AppLogger.candidateError('📤 [Media] Failed to upload video: $e');
          }
        }
      }
    }

    _updateMedia();
    AppLogger.candidate('📤 [Media] Finished uploading pending files');
  }



  void _showYoutubeLinkDialog(int itemIndex) {
    final TextEditingController youtubeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add YouTube Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: youtubeController,
              decoration: const InputDecoration(
                labelText: 'YouTube URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a valid YouTube URL. No size limit for YouTube links.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = youtubeController.text.trim();
              if (url.isNotEmpty) {
                // Basic YouTube URL validation
                if (url.contains('youtube.com') || url.contains('youtu.be')) {
                  _addYoutubeLinkToItem(itemIndex, url);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('YouTube link added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid YouTube URL'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Link'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String itemType,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete this $itemType?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDemoDataModal() {
    showDialog(
      context: context,
      builder: (context) => DemoDataModal(
        category: 'media',
        onDataSelected: (selectedData) {
          if (selectedData is Map<String, dynamic>) {
            setState(() {
              _mediaItems = [MediaItem.fromJson(selectedData)];
            });
            _updateMedia();
          }
        },
      ),
    );
  }

  Future<void> _saveMedia() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final data = widget.editedData ?? widget.candidateData;

      // Create media items list for saving
      final mediaItems = _mediaItems.map((item) => Media.fromJson(item.toJson())).toList();

      final success = await _mediaController.saveMediaTab(
        candidate: data,
        media: mediaItems,
        candidateName: data.basicInfo!.fullName,
        photoUrl: data.photo,
        onProgress: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Media information saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save media information'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving media information: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Media Gallery',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.lightbulb, color: Colors.amber),
                    //   onPressed: _showDemoDataModal,
                    //   tooltip: 'Use demo media',
                    // ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _addNewMediaItem,
                      tooltip: 'Add new media item',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Facebook-style "Add New Post" section
            _buildFacebookStyleAddNewPost(),

            const SizedBox(height: 24),

            // Media Items
            if (_mediaItems.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mediaItems.length,
                itemBuilder: (context, index) {
                  final item = _mediaItems[index];
                  return _buildMediaItemCard(item, index);
                },
              ),
            ] else ...[
              // Empty State
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'No media items yet. Add your first media item!',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addNewMediaItem,
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Add Media Item'),
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

  Widget _buildMediaItemCard(MediaItem item, int itemIndex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title, date and delete option
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: item.title,
                        decoration: const InputDecoration(
                          labelText: 'Media Title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          final updatedItem = MediaItem(
                            title: value,
                            date: item.date,
                            images: item.images,
                            videos: item.videos,
                            youtubeLinks: item.youtubeLinks,
                          );
                          _updateMediaItem(itemIndex, updatedItem);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: item.date,
                        decoration: const InputDecoration(
                          labelText: 'Date (DD/MM/YYYY)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          final updatedItem = MediaItem(
                            title: item.title,
                            date: value,
                            images: item.images,
                            videos: item.videos,
                            youtubeLinks: item.youtubeLinks,
                          );
                          _updateMediaItem(itemIndex, updatedItem);
                        },
                      ),
                    ],
                  ),
                ),
                if (widget.isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(
                      context,
                      'media item',
                      () => _removeMediaItem(itemIndex),
                    ),
                    tooltip: 'Delete media item',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Simple Media Picker - no Row widgets
            if (widget.isEditing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      'Add Media - ${item.images.length} images, ${item.videos.length} videos',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _canUploadMedia ? () => _showAddMediaOptionsDialog(itemIndex) : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Media'),
                    ),
                    if (item.youtubeLinks.length < 5) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showYoutubeLinkDialog(itemIndex),
                        icon: const Icon(Icons.link),
                        label: const Text('YouTube Link'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Facebook-style Add New Post section for edit mode
  Widget _buildFacebookStyleAddNewPost() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile avatar placeholder
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: widget.candidateData.photo != null && widget.candidateData.photo!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.candidateData.photo!,
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showAddPostDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "Create New Post",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPostDialog() {
    // Navigate to the Facebook-style add post screen
    Get.toNamed('/candidate/dashboard/media/add');
  }

  // Old methods removed - using Facebook-style media picker

  Widget _buildFacebookStyleMediaPicker(MediaItem item, int itemIndex) {
    final allMedia = [...item.images, ...item.videos.map((v) => 'video:$v'), ...item.youtubeLinks.map((y) => 'youtube:$y')];
    final imageCount = item.images.length;
    final videoCount = item.videos.length;
    final youtubeCount = item.youtubeLinks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Media previews area (Facebook-style grid)
        if (allMedia.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Media preview grid
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildFacebookStyleMediaPreviewGrid(item, itemIndex),
                ),

                // Add more media buttons inside the preview area - single column layout
                if (_canUploadMedia && allMedia.length < 11) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: InkWell(
                      onTap: () => _showAddMediaOptionsDialog(itemIndex),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add Photos/Videos',
                              style: TextStyle(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (youtubeCount < 5) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: InkWell(
                      onTap: () => _showYoutubeLinkDialog(itemIndex),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Add YouTube Link',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          // Empty state - larger Facebook-style add media area
          GestureDetector(
            onTap: _canUploadMedia ? () => _showAddMediaOptionsDialog(itemIndex) : null,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: _canUploadMedia ? Colors.blue.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _canUploadMedia
                        ? 'Add Photos and Videos'
                        : 'Media upload not available for your plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _canUploadMedia ? Colors.blue.shade600 : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _canUploadMedia
                        ? 'Share your story with images and videos'
                        : 'Upgrade your plan to add media',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],

        // Separate YouTube link area if no media previews
        if (allMedia.isEmpty && youtubeCount > 0) ...[
          const SizedBox(height: 16),
          _buildYoutubeLinksSectionCompact(item, itemIndex),
        ],
      ],
    );
  }

  Widget _buildFacebookStyleMediaPreviewGrid(MediaItem item, int itemIndex) {
    final allMedia = [
      // Add images
      ...item.images.map((img) => {'type': 'image', 'url': img, 'index': item.images.indexOf(img)}),
      // Add videos
      ...item.videos.map((vid) => {'type': 'video', 'url': vid, 'index': item.videos.indexOf(vid)}),
    ];

    if (allMedia.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: allMedia.length == 1 ? 1 : allMedia.length <= 4 ? 2 : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: allMedia.length,
      itemBuilder: (context, index) {
        final mediaItem = allMedia[index];
        final mediaType = mediaItem['type'] as String;
        final mediaUrl = mediaItem['url'] as String;
        final mediaIndex = mediaItem['index'] as int;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Media preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mediaType == 'video'
                    ? VideoPreviewWidget(
                        videoUrl: 'video:$mediaUrl',
                        title: 'Video ${mediaIndex + 1}',
                        aspectRatio: 1.0,
                      )
                    : ReusableImageWidget(
                        imageUrl: mediaUrl,
                        isLocal: _fileUploadService.isLocalPath(mediaUrl),
                        fit: BoxFit.cover,
                        minHeight: 80,
                        maxHeight: 80,
                      ),
              ),
            ),

            // Video indicator
            if (mediaType == 'video') ...[
              Positioned(
                top: 6,
                right: 6,
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

            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: mediaType == 'video'
                    ? () => _removeVideoFromItem(itemIndex, mediaIndex)
                    : () => _removeImageFromItem(itemIndex, mediaIndex),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),

            // Local file indicator
            if (_fileUploadService.isLocalPath(mediaUrl)) ...[
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LOCAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAddMediaOptionsDialog(int itemIndex) {
    if (!_canUploadMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media upload is not available for your current plan'),
          backgroundColor: Colors.orange,
        ),
      );
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAddMediaOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    subtitle: 'Photos & Videos',
                    onTap: () => _showGalleryOptionsDialog(itemIndex),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAddMediaOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    subtitle: 'Take Photo',
                    onTap: () => _pickAndUploadImageFromCamera(itemIndex),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAddMediaOption(
              icon: Icons.video_call,
              label: 'Video Camera',
              subtitle: 'Record Video',
              onTap: () => _pickAndUploadVideoFromCamera(itemIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMediaOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGalleryOptionsDialog(int itemIndex) {
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
              'Choose Media Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickAndUploadImage(itemIndex);
                    },
                    icon: const Icon(Icons.photo),
                    label: const Text('Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickAndUploadVideo(itemIndex);
                    },
                    icon: const Icon(Icons.video_call),
                    label: const Text('Videos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImageFromCamera(int itemIndex) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      await _saveImageLocally(itemIndex, pickedFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickAndUploadVideoFromCamera(int itemIndex) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile == null) return;
      await _uploadVideoToItem(itemIndex, pickedFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record video: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildYoutubeLinksSectionCompact(MediaItem item, int itemIndex) {
    if (item.youtubeLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YouTube Links',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(item.youtubeLinks.length, (index) {
            final youtubeUrl = item.youtubeLinks[index];
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
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      youtubeUrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _removeYoutubeLinkFromItem(itemIndex, index),
                      tooltip: 'Remove YouTube link',
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
