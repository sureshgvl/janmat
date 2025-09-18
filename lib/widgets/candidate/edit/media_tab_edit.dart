import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/candidate_model.dart';
import '../../../services/file_upload_service.dart';
import '../../../services/plan_service.dart';
import '../../common/reusable_image_widget.dart';
import '../../common/reusable_video_widget.dart';
import '../../common/confirmation_dialog.dart';
import '../demo_data_modal.dart';

// Media Item Model
class MediaItem {
  String title;
  String date;
  List<String> images;
  List<String> videos;
  List<String> youtubeLinks;
  Map<String, int> likes; // Track likes for each media item

  MediaItem({
    this.title = '',
    String? date,
    List<String>? images,
    List<String>? videos,
    List<String>? youtubeLinks,
    Map<String, int>? likes,
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

// Reusable Media Item Widget
class MediaItemWidget extends StatelessWidget {
  final String mediaUrl;
  final String type; // 'image' or 'video'
  final bool isEditing;
  final int index;
  final bool isMarkedForDeletion;
  final Function(int, bool) onMarkForDeletion;
  final bool isLocal;

  const MediaItemWidget({
    super.key,
    required this.mediaUrl,
    required this.type,
    required this.isEditing,
    required this.index,
    required this.isMarkedForDeletion,
    required this.onMarkForDeletion,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: isMarkedForDeletion ? Colors.red.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    type == 'image' ? Icons.image : Icons.video_call,
                    color: isMarkedForDeletion
                        ? Colors.red.shade700
                        : (type == 'image' ? Colors.green : Colors.purple),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${type == 'image' ? 'Image' : 'Video'} ${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMarkedForDeletion ? Colors.red.shade700 : null,
                        decoration: isMarkedForDeletion
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  if (isEditing)
                    Checkbox(
                      value: isMarkedForDeletion,
                      onChanged: (checked) async {
                        if (checked == true) {
                          final confirmed = await ConfirmationDialog.show(
                            context: context,
                            title:
                                'Mark ${type[0].toUpperCase() + type.substring(1)} for Deletion',
                            content:
                                'This ${type.toLowerCase()} will be deleted when you save. Are you sure?',
                            confirmText: 'Mark for Deletion',
                          );
                          if (confirmed == true) {
                            onMarkForDeletion(index, true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${type[0].toUpperCase() + type.substring(1)} marked for deletion',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } else {
                          onMarkForDeletion(index, false);
                        }
                      },
                      activeColor: Colors.red,
                    ),
                ],
              ),
              if (isMarkedForDeletion) ...[
                const SizedBox(height: 4),
                Text(
                  'Will be deleted when you save',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (type == 'image')
                ReusableImageWidget(
                  imageUrl: mediaUrl,
                  isLocal: isLocal,
                  fit: BoxFit.cover,
                  minHeight: 150,
                  maxHeight: 200,
                  borderColor: Colors.grey.shade300,
                  fullScreenTitle: 'Media Image',
                )
              else
                VideoPreviewWidget(
                  videoUrl: mediaUrl,
                  title: 'Media Video ${index + 1}',
                  aspectRatio: 16 / 9,
                ),
            ],
          ),
        ),
      ),
    );
  }
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
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();
  late List<MediaItem> _mediaItems;
  final Set<String> _uploadedMediaUrls = {};

  // Files marked for deletion (will be deleted on save)
  final Map<String, bool> _markedForDeletion = {};

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
    final media = data.extraInfo?.media ?? [];

    _mediaItems = media.map((item) => MediaItem.fromJson(item)).toList();

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

  Future<void> _cleanupDanglingFiles() async {
    try {
      await _fileUploadService.cleanupTempPhotos();
      debugPrint('🗑️ Cleaned up all temporary local files');
      _uploadedMediaUrls.clear();
    } catch (e) {
      debugPrint('❌ Error during file cleanup: $e');
    }
  }

  void _addNewMediaItem() {
    setState(() {
      _mediaItems.add(MediaItem());
    });
    _updateMedia();
  }

  void _removeMediaItem(int index) {
    setState(() {
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
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Skip cropping - directly save the selected image locally
      await _saveImageLocally(itemIndex, pickedFile.path);
    } catch (e) {
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
      debugPrint('💾 [Media Image] Starting local save process...');

      // Step 1: Validate file size
      debugPrint('💾 [Media Image] Step 1: Validating file size...');
      final validation = await _fileUploadService.validateMediaFileSize(
        imagePath,
        'image',
      );

      if (!validation.isValid) {
        debugPrint('💾 [Media Image] File too large');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      debugPrint('💾 [Media Image] File size validation passed');

      // Step 2: Save to local storage
      debugPrint('💾 [Media Image] Step 2: Saving to local storage...');
      final candidateId = widget.candidateData.candidateId;
      final localPath = await _fileUploadService.saveExistingFileLocally(
        imagePath,
        candidateId,
        'media_image',
      );

      if (localPath == null) {
        debugPrint('💾 [Media Image] Failed to save locally');
        throw Exception('Failed to save image locally');
      }

      debugPrint('💾 [Media Image] Saved locally at: $localPath');

      // Step 3: Add to media item
      _uploadedMediaUrls.add(localPath);
      _addImageToItem(itemIndex, localPath);

      debugPrint('💾 [Media Image] Image added to media item');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image saved locally (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('💾 [Media Image] Error: $e');
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

      _uploadedMediaUrls.add(localPath);
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
      // Validate video file size (3MB limit)
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

      // For now, just add the video URL directly
      // In a real implementation, you'd want to upload to Firebase Storage
      _addVideoToItem(itemIndex, videoPath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add video: $e')));
    }
  }

  Future<void> uploadPendingFiles() async {
    debugPrint('📤 [Media] Starting upload of pending files...');

    for (int itemIndex = 0; itemIndex < _mediaItems.length; itemIndex++) {
      final item = _mediaItems[itemIndex];

      // Upload images for this item
      for (int i = 0; i < item.images.length; i++) {
        final imageUrl = item.images[i];
        if (_fileUploadService.isLocalPath(imageUrl) &&
            !_uploadedMediaUrls.contains(imageUrl)) {
          try {
            debugPrint('📤 [Media] Uploading image: $imageUrl');

            final fileName =
                'media_image_${widget.candidateData.candidateId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final storagePath = 'media/images/$fileName';

            final downloadUrl = await _fileUploadService.uploadFile(
              imageUrl,
              storagePath,
              'image/jpeg',
            );

            if (downloadUrl != null) {
              setState(() {
                _mediaItems[itemIndex].images[i] = downloadUrl;
              });
              debugPrint('📤 [Media] Successfully uploaded image');
            }
          } catch (e) {
            debugPrint('📤 [Media] Failed to upload image: $e');
          }
        }
      }

      // Upload videos for this item
      for (int i = 0; i < item.videos.length; i++) {
        final videoUrl = item.videos[i];
        if (_fileUploadService.isLocalPath(videoUrl) &&
            !_uploadedMediaUrls.contains(videoUrl)) {
          try {
            debugPrint('📤 [Media] Uploading video: $videoUrl');

            final fileName =
                'media_video_${widget.candidateData.candidateId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
            final storagePath = 'media/videos/$fileName';

            final downloadUrl = await _fileUploadService.uploadFile(
              videoUrl,
              storagePath,
              'video/mp4',
            );

            if (downloadUrl != null) {
              setState(() {
                _mediaItems[itemIndex].videos[i] = downloadUrl;
              });
              debugPrint('📤 [Media] Successfully uploaded video');
            }
          } catch (e) {
            debugPrint('📤 [Media] Failed to upload video: $e');
          }
        }
      }
    }

    _updateMedia();
    debugPrint('📤 [Media] Finished uploading pending files');
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                    IconButton(
                      icon: const Icon(Icons.lightbulb, color: Colors.amber),
                      onPressed: _showDemoDataModal,
                      tooltip: 'Use demo media',
                    ),
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
                          labelText: 'Date (YYYY-MM-DD)',
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

            // Media content sections
            _buildImagesSection(item, itemIndex),
            _buildVideosSection(item, itemIndex),
            _buildYoutubeLinksSection(item, itemIndex),

            // Add media buttons
            if (widget.isEditing) ...[
              const Divider(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: !_canUploadMedia || item.images.length >= _maxImagesPerItem
                        ? null
                        : () => _pickAndUploadImage(itemIndex),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text('Add Image (${item.images.length}/${_maxImagesPerItem == 50 ? "Unlimited" : _maxImagesPerItem.toString()})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_canUploadMedia || item.images.length >= _maxImagesPerItem
                          ? Colors.grey
                          : Colors.green,
                      foregroundColor: !_canUploadMedia || item.images.length >= _maxImagesPerItem
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: !_canUploadMedia || item.videos.length >= _maxVideosPerItem
                        ? null
                        : () => _pickAndUploadVideo(itemIndex),
                    icon: const Icon(Icons.video_call),
                    label: Text('Add Video (${item.videos.length}/${_maxVideosPerItem})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_canUploadMedia || item.videos.length >= _maxVideosPerItem
                          ? Colors.grey
                          : Colors.purple,
                      foregroundColor: !_canUploadMedia || item.videos.length >= _maxVideosPerItem
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showYoutubeLinkDialog(itemIndex),
                    icon: const Icon(Icons.link),
                    label: const Text('Add YouTube Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(MediaItem item, int itemIndex) {
    if (item.images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: item.images.length,
          itemBuilder: (context, index) {
            final imageUrl = item.images[index];
            return Stack(
              children: [
                ReusableImageWidget(
                  imageUrl: imageUrl,
                  isLocal: _fileUploadService.isLocalPath(imageUrl),
                  fit: BoxFit.cover,
                  minHeight: 80,
                  maxHeight: 80,
                  borderColor: Colors.grey.shade300,
                ),
                if (widget.isEditing)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImageFromItem(itemIndex, index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVideosSection(MediaItem item, int itemIndex) {
    if (item.videos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Videos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: List.generate(item.videos.length, (index) {
            final videoUrl = item.videos[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: VideoPreviewWidget(
                      videoUrl: videoUrl,
                      title: 'Video ${index + 1}',
                      aspectRatio: 16 / 9,
                    ),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeVideoFromItem(itemIndex, index),
                      tooltip: 'Remove video',
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildYoutubeLinksSection(MediaItem item, int itemIndex) {
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
        const SizedBox(height: 16),
      ],
    );
  }
}
