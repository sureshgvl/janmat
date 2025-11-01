import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../../../common/whatsapp_image_viewer.dart';
import '../../../common/reusable_video_widget.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';

class ManifestoResourcesSection extends StatelessWidget {
  final String? pdfUrl;
  final String? imageUrl;
  final String? videoUrl;
  final String? candidateName;

  const ManifestoResourcesSection({
    super.key,
    this.pdfUrl,
    this.imageUrl,
    this.videoUrl,
    this.candidateName,
  });

  void _showPdfOptions(BuildContext context, String pdfUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // PDF Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CandidateTranslations.tr('manifestoPdf'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          CandidateTranslations.tr('pdfDocument'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Options
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Open with option
                  ListTile(
                    leading: Icon(
                      Icons.open_in_new,
                      color: Colors.blue.shade600,
                    ),
                    title: Text(
                      CandidateTranslations.tr('openWith'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    subtitle: Text(
                      CandidateTranslations.tr('chooseAppToOpenPdf'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      // Open PDF URL directly - browser will show app chooser
                      if (await canLaunch(pdfUrl)) {
                        await launch(pdfUrl);
                      }
                    },
                  ),

                  // Share option
                  ListTile(
                    leading: Icon(
                      Icons.share,
                      color: Colors.purple.shade600,
                    ),
                    title: Text(
                      CandidateTranslations.tr('share'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    subtitle: Text(
                      CandidateTranslations.tr('sendToOthers'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () async {
                      // Show loading before dismissing sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(CandidateTranslations.tr('preparingPdfForSharing'))),
                      );
                      Navigator.of(context).pop();

                      // Continue with share after sheet is dismissed
                      await _sharePdf(context, pdfUrl);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) =>
          ReusableVideoWidget(
            videoUrl: videoUrl,
            title: CandidateTranslations.tr('manifestoVideo'),
            autoPlay: true, // Auto-play when dialog opens - one-click play!
          ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, String pdfUrl) async {
    try {
      // Download the PDF
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF');
      }

      // Get downloads directory - try multiple approaches for Android
      Directory? downloadsDir;

      // Try to get Downloads directory (Android 10+)
      try {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = null;
        }
      } catch (e) {
        downloadsDir = null;
      }

      // Fallback to external storage
      downloadsDir ??= await getExternalStorageDirectory();

      // Last fallback to app documents
      downloadsDir ??= await getApplicationDocumentsDirectory();

      // Create file name
      final fileName = 'manifesto_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(downloadsDir.path, fileName);

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(CandidateTranslations.tr('pdfDownloadedSuccessfully')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${CandidateTranslations.tr('downloadFailed')} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdf(BuildContext context, String pdfUrl) async {
    try {
      // Download the PDF first, then share the actual file
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF');
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Create file name with candidate name: "candidate_name_manifesto.pdf" or Marathi equivalent
      final safeName = _sanitizeFileName(candidateName ?? 'candidate');
      final manifestoText = CandidateTranslations.tr('manifesto'); // Localized manifesto text
      final fileName = '${safeName}_$manifestoText.pdf';
      final filePath = path.join(tempDir.path, fileName);

      // Save to temporary file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Share the actual PDF file with candidate name in subject
      final displayName = candidateName ?? 'Candidate';
      await Share.shareXFiles(
        [XFile(filePath)],
        text: CandidateTranslations.tr('shareManifestoText', args: {'name': displayName}),
        subject: CandidateTranslations.tr('shareManifestoSubject', args: {'name': displayName, 'title': manifestoText}),
      );

      // Clean up temporary file after a delay
      Future.delayed(const Duration(seconds: 30), () async {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${CandidateTranslations.tr('shareFailed')} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Sanitize filename by removing/replacing invalid characters while preserving Unicode
  String _sanitizeFileName(String name) {
    // More permissive pattern that allows Unicode letters and common symbols
    return name
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0A80-\u0AFF\u0B00-\u0B7F\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF\u0D00-\u0D7F\u0D80-\u0DFF\u0E00-\u0E7F\u0E80-\u0EFF\u0F00-\u0FFF\u1000-\u109F\u10A0-\u10FF\u1100-\u11FF\u1200-\u137F\u1380-\u139F\u13A0-\u13FF\u1400-\u167F\u1680-\u169F\u16A0-\u16FF\u1700-\u171F\u1720-\u173F\u1740-\u175F\u1760-\u177F\u1780-\u17FF\u1800-\u18AF\u1900-\u194F\u1950-\u197F\u1980-\u19DF\u19E0-\u19FF\u1A00-\u1A1F\u1A20-\u1AAF\u1AB0-\u1AFF\u1B00-\u1B7F\u1B80-\u1BBF\u1BC0-\u1BFF\u1C00-\u1C4F\u1C50-\u1C7F\u1C80-\u1C8F\u1CC0-\u1CCF\u1CD0-\u1CF6\u1CF8-\u1CFF\u1D00-\u1D7F\u1D80-\u1DBF\u1DC0-\u1DFF\u1E00-\u1EFF\u1F00-\u1FFF\u2000-\u206F\u2070-\u209F\u20A0-\u20CF\u20D0-\u20FF\u2100-\u214F\u2150-\u218F\u2190-\u21FF\u2200-\u22FF\u2300-\u23FF\u2400-\u243F\u2440-\u245F\u2460-\u24FF\u2500-\u257F\u2580-\u259F\u25A0-\u25FF\u2600-\u26FF\u2700-\u27BF\u27C0-\u27EF\u27F0-\u27FF\u2800-\u28FF\u2900-\u297F\u2980-\u29FF\u2A00-\u2AFF\u2B00-\u2BFF\u2C00-\u2C5F\u2C60-\u2C7F\u2C80-\u2CFF\u2D00-\u2D2F\u2D30-\u2D7F\u2D80-\u2DDF\u2DE0-\u2DFF\u2E00-\u2E7F\u2E80-\u2EFF\u2F00-\u2FDF\u2FF0-\u2FFF\u3000-\u303F\u3040-\u309F\u30A0-\u30FF\u3100-\u312F\u3130-\u318F\u3190-\u319F\u31A0-\u31BF\u31C0-\u31EF\u31F0-\u31FF\u3200-\u32FF\u3300-\u33FF\u3400-\u4DBF\u4DC0-\u4DFF\u4E00-\u9FFF\uA000-\uA48F\uA490-\uA4CF\uA4D0-\uA4FF\uA500-\uA63F\uA640-\uA69F\uA6A0-\uA6FF\uA700-\uA71F\uA720-\uA7FF\uA800-\uA82F\uA830-\uA83F\uA840-\uA87F\uA880-\uA8DF\uA8E0-\uA8FF\uA900-\uA92F\uA930-\uA95F\uA960-\uA97F\uA980-\uA9DF\uA9E0-\uA9FF\uAA00-\uAA5F\uAA60-\uAA7F\uAA80-\uAADF\uAAE0-\uAAFF\uAB00-\uAB2F\uAB30-\uAB6F\uAB70-\uABBF\uABC0-\uABFF\uAC00-\uD7AF\uD7B0-\uD7FF\uD800-\uDB7F\uDB80-\uDBFF\uDC00-\uDFFF\uE000-\uF8FF\uF900-\uFAFF\uFB00-\uFB4F\uFB50-\uFDFF\uFE00-\uFE0F\uFE10-\uFE1F\uFE20-\uFE2F\uFE30-\uFE4F\uFE50-\uFE6F\uFE70-\uFEFF\uFF00-\uFFEF\uFFF0-\uFFFF\-_\.]'), '_') // Replace invalid chars with underscore, allow Unicode
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
        .substring(0, name.length > 50 ? 50 : name.length); // Limit length but allow more for Unicode names
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return WhatsAppImageViewer(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CandidateTranslations.tr('additionalResources'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),

          // PDF Section
          if (pdfUrl != null && pdfUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showPdfOptions(context, pdfUrl!),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CandidateTranslations.tr('manifestoPdfAvailable'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                          Text(
                            CandidateTranslations.tr('tapToViewPdf'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CandidateTranslations.tr('pdfDocument'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    CandidateTranslations.tr('notAvailable'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Image Section
          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.image,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CandidateTranslations.tr('manifestoImage'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Image Preview with Actual Aspect Ratio (Facebook/WhatsApp style)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 300, // Maintain max height constraint
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => _showFullScreenImage(context, imageUrl!),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.contain, // Show actual aspect ratio like Facebook/WhatsApp
                        width: double.infinity,
                        alignment: Alignment.center,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            constraints: const BoxConstraints(
                              minHeight: 120, // Minimum loading height
                            ),
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            constraints: const BoxConstraints(
                              minHeight: 120, // Minimum error height
                            ),
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Full-screen view button
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showFullScreenImage(context, imageUrl!),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: Text(CandidateTranslations.tr('viewFullImage')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.image,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CandidateTranslations.tr('image'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    CandidateTranslations.tr('notAvailable'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Video Section
          if (videoUrl != null && videoUrl!.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.video_call,
                      color: Colors.purple.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CandidateTranslations.tr('manifestoVideo'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Video Preview Widget
                VideoPreviewWidget(
                  videoUrl: videoUrl!,
                  title: 'Manifesto Video',
                  onPlayPressed: () => _playVideo(context, videoUrl!),
                ),
                // Video info and controls
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        CandidateTranslations.tr('tapToPlayVideo'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _playVideo(context, videoUrl!),
                      icon: const Icon(
                        Icons.play_circle_fill,
                        size: 16,
                      ),
                      label: Text(CandidateTranslations.tr('play'), overflow: TextOverflow.ellipsis),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.purple.shade600,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.video_call,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CandidateTranslations.tr('video'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    CandidateTranslations.tr('notAvailable'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Video Preview Widget with YouTube-style thumbnail
class VideoThumbnailPreview extends StatefulWidget {
  final String videoUrl;
  final String title;
  final VoidCallback onPlayPressed;

  const VideoThumbnailPreview({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.onPlayPressed,
  });

  @override
  State<VideoThumbnailPreview> createState() => _VideoThumbnailPreviewState();
}

class _VideoThumbnailPreviewState extends State<VideoThumbnailPreview> {
  VideoPlayerController? _controller;
  bool _isThumbnailLoaded = false;
  bool _hasError = false;
  double _aspectRatio = 16 / 9; // Default aspect ratio

  @override
  void initState() {
    super.initState();
    _loadVideoThumbnail();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller!.initialize();

      // Get the video dimensions for proper aspect ratio
      if (mounted) {
        final size = _controller!.value.size;
        if (size.width > 0 && size.height > 0) {
          setState(() {
            _aspectRatio = size.width / size.height;
          });
        }
      }

      // Try multiple seek positions to find a meaningful frame
      // This avoids blank/black frames that are common at the beginning
      final videoDuration = _controller!.value.duration;
      final seekPositions = _calculateSeekPositions(videoDuration);

      bool foundGoodFrame = false;
      for (final seekPosition in seekPositions) {
        try {
          await _controller!.seekTo(seekPosition);
          // Give time for frame to load
          await Future.delayed(const Duration(milliseconds: 300));

          // For now, assume the seek worked - in a more advanced implementation
          // we could check if the frame actually has content
          foundGoodFrame = true;
          break;
        } catch (e) {
          // Continue to next seek position
          continue;
        }
      }

      if (mounted && foundGoodFrame) {
        setState(() {
          _isThumbnailLoaded = true;
        });
      } else if (mounted) {
        // If no good frames found, still show what we have
        setState(() {
          _isThumbnailLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  /// Calculate optimal seek positions to find meaningful video frames
  List<Duration> _calculateSeekPositions(Duration videoDuration) {
    final positions = <Duration>[];

    // Convert to seconds for easier calculation
    final totalSeconds = videoDuration.inSeconds;

    // For videos longer than 5 seconds, try multiple positions
    if (totalSeconds >= 5) {
      positions.add(const Duration(seconds: 1));  // Skip potential intro black
      positions.add(const Duration(seconds: 2));  // Skip to main content
      positions.add(Duration(seconds: totalSeconds ~/ 3)); // Third through video
    }
    // For medium videos (2-5 seconds)
    else if (totalSeconds >= 2) {
      positions.add(const Duration(milliseconds: 500)); // 0.5 seconds in
      positions.add(const Duration(seconds: 1));  // 1 second in
    }
    // For very short clips (< 2 seconds)
    else {
      positions.add(Duration(milliseconds: totalSeconds * 200)); // 20% through
    }

    // Always include a fallback to first frame
    positions.add(Duration.zero);

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 300, // Maintain max height constraint like images
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail with natural aspect ratio scaling
          if (_isThumbnailLoaded && _controller != null && _controller!.value.isInitialized)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.contain, // Scale to fit without cropping - matches Facebook/WhatsApp behavior
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            )
          else if (_hasError)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.video_call,
                  color: Colors.white70,
                  size: 64,
                ),
              ),
            )
          else
            // Loading state
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // Dark overlay for better play button visibility
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Play button overlay
          IconButton(
            onPressed: widget.onPlayPressed,
            icon: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 64,
            ),
          ),

          // Video duration indicator (if available)
          if (_isThumbnailLoaded && _controller != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(_controller!.value.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Video dimensions indicator (for debugging)
          if (_isThumbnailLoaded && _controller != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_controller!.value.size.width.toInt()}:${_controller!.value.size.height.toInt()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Legacy Video Preview Widget - keep for backward compatibility
class VideoPreviewWidget extends StatelessWidget {
  final String videoUrl;
  final String title;
  final VoidCallback onPlayPressed;

  const VideoPreviewWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return VideoThumbnailPreview(
      videoUrl: videoUrl,
      title: title,
      onPlayPressed: onPlayPressed,
    );
  }
}
