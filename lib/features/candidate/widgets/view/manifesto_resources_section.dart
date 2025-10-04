import 'package:flutter/material.dart';
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

  const ManifestoResourcesSection({
    super.key,
    this.pdfUrl,
    this.imageUrl,
    this.videoUrl,
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
                          'Manifesto PDF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'PDF Document',
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
                      'Open with',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    subtitle: Text(
                      'Choose an app to open this PDF',
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
                      'Share',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    subtitle: Text(
                      'Send to others',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    onTap: () async {
                      // Show loading before dismissing sheet
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preparing PDF for sharing...')),
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
          ReusableVideoWidget(videoUrl: videoUrl, title: CandidateTranslations.tr('manifestoVideo')),
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
      if (downloadsDir == null) {
        downloadsDir = await getExternalStorageDirectory();
      }

      // Last fallback to app documents
      if (downloadsDir == null) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Create file name
      final fileName = 'manifesto_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(downloadsDir!.path, fileName);

      // Save file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF downloaded successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdf(BuildContext context, String pdfUrl) async {
    try {
      // Share the PDF URL directly
      await Share.share(
        'Check out this Manifesto PDF: $pdfUrl',
        subject: 'Manifesto PDF',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                            'Tap to view PDF',
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
                // Improved Image Preview with Aspect Ratio
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Default aspect ratio, can be made dynamic
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, imageUrl!),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover, // Instagram/WhatsApp style preview
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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

// Video Preview Widget (assuming it's defined elsewhere, but including a simple version)
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
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for video thumbnail
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          IconButton(
            onPressed: onPlayPressed,
            icon: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

