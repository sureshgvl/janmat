import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/candidate_model.dart';
import '../../../../services/demo_data_service.dart';
import '../../controllers/candidate_data_controller.dart';
import '../../../common/whatsapp_image_viewer.dart';
import '../../../common/reusable_video_widget.dart';

class ManifestoTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final bool
  showVoterInteractions; // New parameter to control voter interactions

  const ManifestoTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
    this.showVoterInteractions =
        true, // Default to true for backward compatibility
  });

  @override
  State<ManifestoTabView> createState() => _ManifestoTabViewState();
}

class _ManifestoTabViewState extends State<ManifestoTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CandidateDataController? _dataController;

  // Voter interaction state
  bool _isLiked = false;
  int _likeCount = 0;
  String? _selectedPollOption;
  final Map<String, int> _pollOptions = {
    'development': 0,
    'transparency': 0,
    'youth_education': 0,
    'women_safety': 0,
  };

  // Comments functionality
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    if (widget.isOwnProfile) {
      _dataController = Get.find<CandidateDataController>();
    } else {
      _dataController = null;
    }
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Award XP for supporting manifesto
    if (_isLiked) {
      Get.snackbar(
        AppLocalizations.of(context)!.xpEarned,
        AppLocalizations.of(context)!.earnedXpForSupportingManifesto('10'),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
        maxWidth: 300,
      );
    }
  }

  void _selectPollOption(String option) {
    setState(() {
      _selectedPollOption = option;
      _pollOptions[option] = (_pollOptions[option] ?? 0) + 1;
    });

    Get.snackbar(
      AppLocalizations.of(context)!.thankYou,
      AppLocalizations.of(context)!.feedbackRecorded,
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 2),
      maxWidth: 300,
    );
  }

  void _shareManifesto() {
    final manifestoTitle =
        widget.candidate.extraInfo?.manifesto?.title ?? 'Manifesto';
    final manifestoText =
        '''
Check out ${widget.candidate.name}'s manifesto!

"$manifestoTitle"

${widget.candidate.party.isNotEmpty ? 'Party: ${widget.candidate.party}' : 'Independent Candidate'}
Location: ${widget.candidate.districtId}, ${widget.candidate.wardId}

Read their complete manifesto and learn about their vision at: [Your App URL]
''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.shareFunctionalityComingSoon, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterComment, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _comments.add({
        'text': _commentController.text.trim(),
        'timestamp': DateTime.now(),
        'likes': 0,
        'isLiked': false,
      });
      _commentController.clear();
    });

    // Award XP for commenting
    Get.snackbar(
      AppLocalizations.of(context)!.xpEarned,
      AppLocalizations.of(context)!.earnedXpForCommenting('5'),
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 2),
      maxWidth: 300,
    );
  }

  void _toggleCommentLike(int index) {
    setState(() {
      final comment = _comments[index];
      comment['isLiked'] = !comment['isLiked'];
      comment['likes'] =
          (comment['likes'] as int) + (comment['isLiked'] ? 1 : -1);
    });
  }

  void _toggleCommentsVisibility() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  String _formatCommentTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Video player functionality
  void _playVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) =>
          ReusableVideoWidget(videoUrl: videoUrl, title: AppLocalizations.of(context)!.manifestoVideo),
    );
  }

  // WhatsApp-style full-screen image viewer
  void _showFullScreenImage(String imageUrl) {
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

  Widget _buildPollOption(String optionKey, String optionText) {
    final isSelected = _selectedPollOption == optionKey;
    final voteCount = _pollOptions[optionKey] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectPollOption(optionKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (voteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$voteCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use reactive data for own profile, static data for others
    if (widget.isOwnProfile && _dataController != null) {
      return Obx(() {
        final candidate =
            _dataController.candidateData.value ?? widget.candidate;
        return _buildContent(candidate);
      });
    } else {
      return _buildContent(widget.candidate);
    }
  }

  Widget _buildContent(Candidate candidate) {
    final manifestoPromises = candidate.extraInfo?.manifesto?.promises ?? [];
    final manifesto = candidate.manifesto ?? '';

    // Use demo manifesto items if no real items exist
    final displayManifestoPromises = manifestoPromises.isNotEmpty
        ? manifestoPromises
        : DemoDataService.getDemoManifestoPromises('development', 'en');

    final hasStructuredData =
        displayManifestoPromises.isNotEmpty || manifesto.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasStructuredData || manifesto.isNotEmpty)
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Manifesto Title with Share Button
                      if (widget.candidate.extraInfo?.manifesto?.title !=
                              null &&
                          widget
                              .candidate
                              .extraInfo!
                              .manifesto!
                              .title!
                              .isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Text(
                                  widget.candidate.extraInfo!.manifesto!.title!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1f2937),
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Share Button
                            GestureDetector(
                              onTap: _shareManifesto,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.share,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        // Placeholder for manifesto title
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.title,
                                size: 24,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.manifestoTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppLocalizations.of(context)!.notAvailable,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Display Manifesto Items
                  if (manifestoPromises.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.promisesTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF374151),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(manifestoPromises.length, (
                        index,
                      ) {
                        final promise = manifestoPromises[index];
                        if (promise.isEmpty) return const SizedBox.shrink();

                        // Handle new structured format
                        final title = promise['title'] as String? ?? '';
                        final points =
                            promise['points'] as List<dynamic>? ?? [];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Promise Title
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 8),
                                  // Promise Points
                                  ...points.map((point) {
                                    final pointIndex =
                                        points.indexOf(point) + 1;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 4,
                                        left: 16,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$pointIndex. ',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              point.toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                height: 1.4,
                                                color: Color(0xFF6B7280),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Show placeholder when no promises are available
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'promisesTitle'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.notAvailable,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Additional Resources Section
                  Container(
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
                          AppLocalizations.of(context)!.additionalResources,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // PDF Section
                        if (widget.candidate.extraInfo?.manifesto?.pdfUrl !=
                                null &&
                            widget
                                .candidate
                                .extraInfo!
                                .manifesto!
                                .pdfUrl!
                                .isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.manifestoPdfAvailable,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF374151),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final url = widget
                                      .candidate
                                      .extraInfo!
                                      .manifesto!
                                      .pdfUrl!;
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  }
                                },
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.blue,
                                ),
                                tooltip: 'downloadPdf'.tr,
                              ),
                            ],
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
                                  'pdfDocument'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'notAvailable'.tr,
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

                        const SizedBox(height: 12),

                        // Image Section
                        if (widget.candidate.extraInfo?.manifesto?.image !=
                                null &&
                            widget
                                .candidate
                                .extraInfo!
                                .manifesto!
                                .image!
                                .isNotEmpty) ...[
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
                                      'manifestoImage'.tr,
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
                                    aspectRatio:
                                        16 /
                                        9, // Default aspect ratio, can be made dynamic
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(
                                        widget
                                            .candidate
                                            .extraInfo!
                                            .manifesto!
                                            .image!,
                                      ),
                                      child: Image.network(
                                        widget
                                            .candidate
                                            .extraInfo!
                                            .manifesto!
                                            .image!,
                                        fit: BoxFit
                                            .cover, // Instagram/WhatsApp style preview
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                color: Colors.grey.shade100,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade100,
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
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
                                  onPressed: () => _showFullScreenImage(
                                    widget
                                        .candidate
                                        .extraInfo!
                                        .manifesto!
                                        .image!,
                                  ),
                                  icon: const Icon(Icons.fullscreen, size: 16),
                                  label: Text('viewFullImage'.tr),
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
                                  'image'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'notAvailable'.tr,
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
                        if (widget.candidate.extraInfo?.manifesto?.videoUrl !=
                                null &&
                            widget
                                .candidate
                                .extraInfo!
                                .manifesto!
                                .videoUrl!
                                .isNotEmpty) ...[
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
                                    'manifestoVideo'.tr,
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
                                videoUrl: widget
                                    .candidate
                                    .extraInfo!
                                    .manifesto!
                                    .videoUrl!,
                                title: 'Manifesto Video',
                                onPlayPressed: () => _playVideo(
                                  widget
                                      .candidate
                                      .extraInfo!
                                      .manifesto!
                                      .videoUrl!,
                                ),
                              ),
                              // Video info and controls
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'tapToPlayVideo'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _playVideo(
                                      widget
                                          .candidate
                                          .extraInfo!
                                          .manifesto!
                                          .videoUrl!,
                                    ),
                                    icon: const Icon(
                                      Icons.play_circle_fill,
                                      size: 16,
                                    ),
                                    label: Text('play'.tr, overflow: TextOverflow.ellipsis),
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
                                  'video'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'notAvailable'.tr,
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
                  ),
                  const SizedBox(height: 16),

                  // Voter Interaction Section (only show if enabled)
                  if (widget.showVoterInteractions) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Like/Support Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _toggleLike,
                                icon: Icon(
                                  _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.grey,
                                ),
                                label: Text(
                                  _isLiked
                                      ? 'supportedWithCount'.tr.trArgs([_likeCount.toString()])
                                      : 'supportThisManifesto'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isLiked ? Colors.red : Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLiked
                                      ? Colors.red.shade50
                                      : Colors.white,
                                  side: BorderSide(
                                    color: _isLiked
                                        ? Colors.red.shade300
                                        : Colors.grey.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Poll Section
                          Text(
                            'whatIssueMattersMost'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildPollOption(
                                'development',
                                'developmentInfrastructure'.tr,
                              ),
                              _buildPollOption(
                                'transparency',
                                'transparencyGovernance'.tr,
                              ),
                              _buildPollOption(
                                'youth_education',
                                'youthEducation'.tr,
                              ),
                              _buildPollOption(
                                'women_safety',
                                'womenSafety'.tr,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Comments Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'comments'.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              InkWell(
                                onTap: _toggleCommentsVisibility,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _showComments
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _showComments
                                          ? 'hideComments'.tr
                                          : '${_comments.length}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Add Comment Input
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    hintText: 'shareYourThoughts'.tr,
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintStyle: TextStyle(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: TextButton(
                                        onPressed: () =>
                                            _commentController.clear(),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                        ),
                                        child: Text('cancel'.tr, overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: ElevatedButton.icon(
                                        onPressed: _addComment,
                                        icon: const Icon(Icons.send, size: 16),
                                        label: Text('postComment'.tr, overflow: TextOverflow.ellipsis),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Comments List
                          if (_showComments) ...[
                            if (_comments.isEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'noCommentsYet'.tr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ] else ...[
                              ..._comments.map((comment) {
                                final index = _comments.indexOf(comment);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.blue,
                                            child: Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'anonymousVoter'.tr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: Color(0xFF374151),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              _formatCommentTime(
                                                comment['timestamp'] as DateTime,
                                              ),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment['text'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: Color(0xFF374151),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _toggleCommentLike(index),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    comment['isLiked'] as bool
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    size: 16,
                                                    color:
                                                        comment['isLiked'] as bool
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      '${comment['likes']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () {
                                                // Reply functionality could be added here
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'replyFunctionalityComingSoon'.tr,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.reply,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'reply'.tr,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'noManifestoAvailable'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
