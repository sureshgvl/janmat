import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/candidate_model.dart';
import '../../../../services/demo_data_service.dart';
import '../../../../services/share_service.dart';
import '../../../notifications/services/constituency_notifications.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';
import 'manifesto_resources_section.dart';
import 'manifesto_poll_section.dart';
import '../../services/manifesto_likes_service.dart';
import '../../services/analytics_data_collection_service.dart';
import '../../../../utils/advanced_analytics.dart' as analytics;
import '../../../../utils/snackbar_utils.dart';
import '../../../../core/app_theme.dart';

class ManifestoContentBuilder extends StatefulWidget {
  final Candidate candidate;
  final String? currentUserId;
  final bool showVoterInteractions;

  const ManifestoContentBuilder({
    super.key,
    required this.candidate,
    required this.currentUserId,
    required this.showVoterInteractions,
  });

  @override
  State<ManifestoContentBuilder> createState() => _ManifestoContentBuilderState();
}

class _ManifestoContentBuilderState extends State<ManifestoContentBuilder> {
  /// Get standardized manifesto ID for services
  String _getManifestoId() {
    return widget.candidate.candidateId ?? widget.candidate.userId ?? 'unknown';
  }

  Future<void> _toggleManifestoLike() async {
    if (widget.currentUserId == null) {
      SnackbarUtils.showError('pleaseLoginToInteract'.tr);
      return;
    }

    try {
      final isLiked = await ManifestoLikesService.toggleLike(widget.currentUserId!, _getManifestoId());

      // Track manifesto like analytics using new service
      await AnalyticsDataCollectionService().trackManifestoInteraction(
        candidateId: widget.candidate.candidateId ?? widget.candidate.userId ?? 'unknown',
        interactionType: isLiked ? 'like' : 'unlike',
        userId: widget.currentUserId,
        section: 'manifesto_title',
        metadata: {
          'manifesto_title': widget.candidate.manifestoData?.title,
          'interaction_source': 'manifesto_tab',
        },
      );

      // Also track using existing analytics manager for backward compatibility
      analytics.AdvancedAnalyticsManager().trackUserInteraction(
        isLiked ? 'manifesto_like' : 'manifesto_unlike',
        'manifesto_tab',
        elementId: _getManifestoId(),
        metadata: {
          'user_id': widget.currentUserId,
          'candidate_id': widget.candidate.candidateId,
        },
      );
    } catch (e) {
      SnackbarUtils.showError('failedToUpdateLike'.tr);
    }
  }

  void _shareManifesto() async {
    try {
      // Share the manifesto via native sharing (now with context for translations)
      await ShareService.shareCandidateManifesto(widget.candidate, context);

      // Track manifesto share analytics
      await AnalyticsDataCollectionService().trackManifestoInteraction(
        candidateId: widget.candidate.candidateId ?? widget.candidate.userId ?? 'unknown',
        interactionType: 'share',
        userId: widget.currentUserId,
        section: 'full_manifesto',
        metadata: {
          'manifesto_title': widget.candidate.manifestoData?.title,
          'share_platform': 'native_share',
          'interaction_source': 'manifesto_tab',
        },
      );

      // Send notification to followers and constituency about the sharing
      final manifestoTitle = widget.candidate.manifestoData?.title ?? 'Manifesto';
      final constituencyNotifications = ConstituencyNotifications();

      await constituencyNotifications.sendManifestoSharedNotification(
        candidateId: widget.candidate.candidateId ?? widget.candidate.userId ?? '',
        manifestoTitle: manifestoTitle,
        shareMessage: null, // Could be enhanced to include custom message
        sharePlatform: 'native_share', // Could detect actual platform
      );

      SnackbarUtils.showSuccess('Manifesto shared successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to share manifesto. Please try again.');
    }
  }


  @override
  Widget build(BuildContext context) {
    final manifestoPromises = widget.candidate.manifestoData?.promises ?? [];

    // Use demo manifesto items if no real items exist
    final displayManifestoPromises = manifestoPromises.isNotEmpty
        ? manifestoPromises
        : DemoDataService.getDemoManifestoPromises('development', 'en');

    final hasStructuredData = displayManifestoPromises.isNotEmpty;

    // final manifestoId = widget.candidate.candidateId ?? widget.candidate.userId ?? '';

    return Container(
      color: AppTheme.homeBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasStructuredData)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simple Manifesto Title
                if (widget.candidate.manifestoData?.title != null &&
                    widget.candidate.manifestoData!.title!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.candidate.manifestoData!.title!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // Like Button with Counter
                        StreamBuilder<int>(
                          stream: ManifestoLikesService.getLikeCountStream(_getManifestoId()),
                          builder: (context, likeSnapshot) {
                            final likeCount = likeSnapshot.data ?? 0;
                            return StreamBuilder<bool>(
                              stream: widget.currentUserId != null
                                  ? ManifestoLikesService.getUserLikeStatusStream(widget.currentUserId!, _getManifestoId())
                                  : Stream.value(false),
                              builder: (context, userLikeSnapshot) {
                                final isLiked = userLikeSnapshot.data ?? false;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _toggleManifestoLike,
                                      icon: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : Colors.grey,
                                      ),
                                      tooltip: isLiked ? 'Unlike Manifesto' : 'Like Manifesto',
                                    ),
                                    if (likeCount > 0)
                                      Text(
                                        '$likeCount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          onPressed: _shareManifesto,
                          icon: const Icon(Icons.share, color: Colors.blue),
                          tooltip: 'Share Manifesto',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Simple Promises List
                if (manifestoPromises.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in,
                                color: Colors.green.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CandidateTranslations.tr('promises'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${manifestoPromises.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        ...displayManifestoPromises.map((promise) {
                          final title = promise['title'] as String? ?? '';
                          final points = promise['points'] as List<dynamic>? ?? [];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...points.map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '• ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          point.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Simple Resources Section
                ManifestoResourcesSection(
                  pdfUrl: widget.candidate.manifestoData?.pdfUrl,
                  imageUrl: widget.candidate.manifestoData?.image,
                  videoUrl: widget.candidate.manifestoData?.videoUrl,
                  candidateName: widget.candidate.basicInfo?.fullName ?? 'candidate ', // Pass proper candidate name for PDF sharing
                ),

                // Voter Interactions (if enabled)
                if (widget.showVoterInteractions) ...[
                  const SizedBox(height: 24),
                  // Poll Section
                  ManifestoPollSection(
                    manifestoId: _getManifestoId(),
                    currentUserId: widget.currentUserId,
                  ),
                ],
              ],
            )
          else
            // Simple empty state
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Manifesto Coming Soon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This candidate is preparing their manifesto. Check back soon!',
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
          const SizedBox(height: 120), // Increased from 20 to add 100px bottom padding
        ],
      ),
    ),
  );
}
}
