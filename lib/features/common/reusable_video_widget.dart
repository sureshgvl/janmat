import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../utils/app_logger.dart';

/// Reusable video player widget with WhatsApp-style UI
class ReusableVideoWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onPlayPressed;

  const ReusableVideoWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.aspectRatio,
    this.autoPlay = false,
    this.showControls = true,
    this.onPlayPressed,
  });

  @override
  State<ReusableVideoWidget> createState() => _ReusableVideoWidgetState();
}

class _ReusableVideoWidgetState extends State<ReusableVideoWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      AppLogger.ui(
        'Initializing video player for: ${widget.videoUrl}',
        tag: 'VIDEO',
      );

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: false,
        showControls: widget.showControls,
        showControlsOnInitialize: true,
        showOptions: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: [0.5, 1.0, 1.25, 1.5, 2.0],
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.purple,
          handleColor: Colors.purpleAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      AppLogger.ui('Video player initialized successfully', tag: 'VIDEO');
    } catch (e) {
      AppLogger.ui('Error initializing video: $e', tag: 'VIDEO');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title ?? 'Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Video content
            Expanded(
              child: _isLoading
                  ? Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _hasError
                  ? Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Text(
                          'Video player not available',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video preview widget for displaying video thumbnails with play button
class VideoPreviewWidget extends StatelessWidget {
  final String videoUrl;
  final String? title;
  final double? aspectRatio;
  final VoidCallback? onPlayPressed;
  final bool showDuration;
  final String? durationText;

  const VideoPreviewWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.aspectRatio,
    this.onPlayPressed,
    this.showDuration = true,
    this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio ?? 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.purple.shade50,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail placeholder (can be enhanced with real thumbnail)
            Container(
              color: Colors.purple.shade50,
              child: const Center(
                child: Icon(Icons.video_call, color: Colors.purple, size: 64),
              ),
            ),
            // Duration indicator
            if (showDuration)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    durationText ?? '0:00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            // Play button overlay
            GestureDetector(
              onTap:
                  onPlayPressed ??
                  () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          ReusableVideoWidget(videoUrl: videoUrl, title: title),
                    );
                  },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
