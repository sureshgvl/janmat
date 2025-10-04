import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/whatsapp_image_viewer.dart';
import '../../../common/reusable_video_widget.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';

/// Improved Manifesto Resources Section with Modern Card Design
/// Supports single PDF, single Image, and single Video (≤2 mins)
class ManifestoResourcesImproved extends StatelessWidget {
  final String? pdfUrl;
  final String? imageUrl;
  final String? videoUrl;

  const ManifestoResourcesImproved({
    super.key,
    this.pdfUrl,
    this.imageUrl,
    this.videoUrl,
  });

  void _playVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => ReusableVideoWidget(
        videoUrl: videoUrl,
        title: CandidateTranslations.tr('manifestoVideo')
      ),
    );
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

  Future<void> _downloadPdf(String pdfUrl) async {
    if (await canLaunch(pdfUrl)) {
      await launch(pdfUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attachment,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CandidateTranslations.tr('additionalResources'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Three-column resource cards
          Row(
            children: [
              // PDF Card
              Expanded(
                child: _buildPdfCard(context),
              ),
              const SizedBox(width: 16),

              // Image Card
              Expanded(
                child: _buildImageCard(context),
              ),
              const SizedBox(width: 16),

              // Video Card
              Expanded(
                child: _buildVideoCard(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(BuildContext context) {
    final hasPdf = pdfUrl != null && pdfUrl!.isNotEmpty;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasPdf
            ? [Colors.red.shade50, Colors.red.shade100]
            : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPdf ? Colors.red.shade200 : Colors.grey.shade300,
        ),
        boxShadow: hasPdf ? [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: hasPdf ? () => _downloadPdf(pdfUrl!) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PDF Icon with background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasPdf ? Colors.red.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 32,
                      color: hasPdf ? Colors.red.shade600 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    'Manifesto PDF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasPdf ? Colors.red.shade800 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  // Status/Action text
                  Text(
                    hasPdf ? 'Tap to Download' : 'Not Available',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasPdf ? Colors.red.shade600 : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // File size (if available)
                  if (hasPdf) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '2.3 MB',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasImage
            ? [Colors.green.shade50, Colors.green.shade100]
            : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        boxShadow: hasImage ? [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: hasImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Image preview
                Positioned.fill(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.green.shade50,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.green.shade50,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.green,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showFullScreenImage(context, imageUrl!),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.green.shade600,
                                size: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Manifesto Image',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to View',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.image,
                    size: 32,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Image',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Not Available',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    final hasVideo = videoUrl != null && videoUrl!.isNotEmpty;

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasVideo
            ? [Colors.purple.shade50, Colors.purple.shade100]
            : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVideo ? Colors.purple.shade200 : Colors.grey.shade300,
        ),
        boxShadow: hasVideo ? [
          BoxShadow(
            color: Colors.purple.shade100,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: hasVideo ? () => _playVideo(context, videoUrl!) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Video thumbnail area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasVideo ? Colors.purple.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Placeholder for video thumbnail
                        if (hasVideo)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade400, Colors.purple.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                        // Play button
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasVideo
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: hasVideo ? Colors.purple.shade600 : Colors.grey.shade500,
                            size: 20,
                          ),
                        ),

                        // Duration badge
                        if (hasVideo)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '2:00',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  'Manifesto Video',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasVideo ? Colors.purple.shade800 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Status text
                Text(
                  hasVideo ? 'Tap to Play' : 'Not Available',
                  style: TextStyle(
                    fontSize: 10,
                    color: hasVideo ? Colors.purple.shade600 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

