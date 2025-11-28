import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/utils/app_logger.dart';
import 'package:janmat/utils/snackbar_utils.dart';
import 'package:janmat/features/candidate/models/candidate_model.dart';
import 'package:janmat/features/candidate/models/media_model.dart';
import '../../../../core/services/firebase_uploader.dart';
import '../../../../core/models/unified_file.dart';
import '../../../../core/widgets/file_upload_section.dart';
import '../../../../core/services/file_picker_helper.dart';
import '../../../services/media_storage_service.dart';
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

  late List<UnifiedFile> _selectedImageFiles;
  late List<UnifiedFile> _selectedVideoFiles;
  late List<String> _selectedYoutubeLinks;
  late List<String> _uploadedImageUrls;
  late List<String> _uploadedVideoUrls;
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
      AppLogger.candidateError('Error loading plan limits: $e');
    }
  }

  void _initializeData() {
    if (widget.existingItem != null) {
      _titleController.text = widget.existingItem!.title;
      _selectedImageFiles = [];
      _selectedVideoFiles = [];
      _uploadedImageUrls = [...widget.existingItem!.images];
      _uploadedVideoUrls = [...widget.existingItem!.videos];
      _selectedYoutubeLinks = [...widget.existingItem!.youtubeLinks];
    } else {
      _selectedImageFiles = [];
      _selectedVideoFiles = [];
      _uploadedImageUrls = [];
      _uploadedVideoUrls = [];
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

            // Cross-platform Media Upload Section
            _buildMediaUploadSection(),
            const SizedBox(height: 16),

            // YouTube Links Section
            _buildYoutubeLinksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FileUploadSection(
                  title: 'Add Photos',
                  subtitle: 'Select multiple photos for your post',
                  storagePath: 'media/images',
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                  maxFileSize: 10,
                  maxFiles: 5,
                  fileType: UnifiedFileType.image,
                  existingFileUrl: null,
                  onFilesSelected: (files) {
                    setState(() {
                      _selectedImageFiles.addAll(files);
                    });
                  },
                  onUploadComplete: (url) {
                    if (url != null) {
                      setState(() {
                        _uploadedImageUrls.add(url);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FileUploadSection(
                  title: 'Add Video',
                  subtitle: 'Select a video for your post',
                  storagePath: 'media/videos',
                  allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
                  maxFileSize: 20,
                  maxFiles: 1,
                  fileType: UnifiedFileType.video,
                  existingFileUrl: null,
                  onFilesSelected: (files) {
                    setState(() {
                      _selectedVideoFiles.addAll(files);
                    });
                  },
                  onUploadComplete: (url) {
                    if (url != null) {
                      setState(() {
                        _uploadedVideoUrls.add(url);
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          // Selected Media Preview
          if (_uploadedImageUrls.isNotEmpty || _uploadedVideoUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMediaPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final allMedia = [
      ..._uploadedImageUrls.map((url) => {'type': 'image', 'url': url}),
      ..._uploadedVideoUrls.map((url) => {'type': 'video', 'url': url}),
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
                  // Close button
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

  Widget _buildYoutubeLinksSection() {
    return Column(
      children: [
        // Add YouTube Link Button
        ElevatedButton.icon(
          onPressed: _showAddYoutubeDialog,
          icon: const Icon(Icons.link),
          label: const Text('Add YouTube Link'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        // YouTube Links List
        if (_selectedYoutubeLinks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
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
          ),
        ],
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

  void _removeMedia(String type, String url) {
    setState(() {
      if (type == 'image') {
        _uploadedImageUrls.remove(url);
      } else if (type == 'video') {
        _uploadedVideoUrls.remove(url);
      }
    });
  }

  void _removeYoutubeLink(int index) {
    setState(() {
      _selectedYoutubeLinks.removeAt(index);
    });
  }

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty) {
      SnackbarUtils.showError('Please enter a title');
      return;
    }

    if (_uploadedImageUrls.isEmpty && _uploadedVideoUrls.isEmpty && _selectedYoutubeLinks.isEmpty) {
      SnackbarUtils.showError('Please add some media or YouTube links');
      return;
    }

    if (_candidate == null) {
      SnackbarUtils.showError('No candidate found - cannot save post');
      return;
    }

    // Check limits
    if (_uploadedImageUrls.length > 5) {
      SnackbarUtils.showError('Maximum 5 images allowed per post');
      return;
    }

    if (_uploadedVideoUrls.length > 1) {
      SnackbarUtils.showError('Maximum 1 video allowed per post');
      return;
    }

    if (_selectedYoutubeLinks.length > 5) {
      SnackbarUtils.showError('Maximum 5 YouTube links allowed per post');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String postDate = widget.existingItem != null
          ? widget.existingItem!.date
          : DateTime.now().toIso8601String().split('T')[0];

      final newMediaItem = MediaItem(
        title: _titleController.text.trim(),
        date: postDate,
        images: _uploadedImageUrls,
        videos: _uploadedVideoUrls,
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
        if (mounted) {
          SnackbarUtils.showError('Failed to create post. Please try again.');
        }
      }
    } catch (e) {
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
