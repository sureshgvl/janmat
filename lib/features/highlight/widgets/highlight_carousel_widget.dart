import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../features/candidate/screens/candidate_profile_screen.dart';
import '../../../features/candidate/models/candidate_model.dart';
import '../models/highlight_display_model.dart';
import '../services/highlight_service.dart';

/// Widget for displaying horizontal scrolling highlight cards (Carousel Plan)
class HighlightCarouselWidget extends StatefulWidget {
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;
  final List<HomeHighlight> highlights;

  const HighlightCarouselWidget({
    super.key,
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    required this.highlights,
  });

  @override
  _HighlightCarouselWidgetState createState() => _HighlightCarouselWidgetState();
}

class _HighlightCarouselWidgetState extends State<HighlightCarouselWidget> {
  Future<void> _trackClick(HomeHighlight highlight) async {
    try {
      await HighlightService.trackClick(highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId);
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarousel: Error tracking click', error: e);
    }
  }

  Future<void> _onHighlightTap(HomeHighlight highlight) async {
    await _trackClick(highlight);

    // Navigate to candidate profile
    try {
      AppLogger.common('🎯 HighlightCarousel: Navigating to candidate profile for ${highlight.candidateName} (${highlight.candidateId})');

      // Fetch candidate data using optimized query
      final firestore = FirebaseFirestore.instance;
      final candidateDoc = await firestore
          .collection('states')
          .doc(widget.stateId)
          .collection('districts')
          .doc(highlight.districtId)
          .collection('bodies')
          .doc(highlight.bodyId)
          .collection('wards')
          .doc(highlight.wardId)
          .collection('candidates')
          .doc(highlight.candidateId)
          .get();

      if (candidateDoc.exists && mounted) {
        final data = candidateDoc.data()!;
        final candidateData = Map<String, dynamic>.from(data);
        candidateData['candidateId'] = candidateDoc.id;

        // Parse candidate data
        final candidate = Candidate.fromJson(candidateData);

        AppLogger.common('✅ HighlightCarousel: Found candidate, navigating to profile');
        Get.to(() => const CandidateProfileScreen(), arguments: candidate);
      } else {
        AppLogger.common('❌ HighlightCarousel: Candidate document not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidate profile not available')),
          );
        }
      }
    } catch (e) {
      AppLogger.commonError('❌ HighlightCarousel: Error fetching candidate data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading candidate profile: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if there are enough highlights for a meaningful carousel
    if (widget.highlights.length <= 1) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'More Highlights',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200, // Height for card carousel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.highlights.length,
            itemBuilder: (context, index) {
              final highlight = widget.highlights[index];
              return HighlightCard(
                highlight: highlight,
                districtId: widget.districtId,
                bodyId: widget.bodyId,
                wardId: widget.wardId,
                onTap: () => _onHighlightTap(highlight),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HighlightCard extends StatefulWidget {
  final HomeHighlight highlight;
  final String? districtId;
  final String? bodyId;
  final String? wardId;
  final VoidCallback? onTap;

  const HighlightCard({
    super.key,
    required this.highlight,
    this.districtId,
    this.bodyId,
    this.wardId,
    this.onTap,
  });

  @override
  _HighlightCardState createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  String? candidateProfileImageUrl;
  String? candidateName;
  String? candidateParty;
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCandidateProfileImage();
  }

  Future<void> _loadCandidateProfileImage() async {
    AppLogger.common('🔍 [HighlightCard] Loading candidate data for highlight: ${widget.highlight.id}, candidateId: ${widget.highlight.candidateId}');
    AppLogger.common('   Highlight data - name: "${widget.highlight.candidateName}", party: "${widget.highlight.party}", imageUrl: "${widget.highlight.candidatePhoto}"');

    // Use the imageUrl from the highlight directly
    if (widget.highlight.candidatePhoto != null && widget.highlight.candidatePhoto!.isNotEmpty) {
      setState(() {
        candidateProfileImageUrl = widget.highlight.candidatePhoto;
        candidateName = widget.highlight.candidateName ?? 'Candidate';
        candidateParty = widget.highlight.party ?? 'Party';
        isLoadingProfile = false;
      });
      AppLogger.common('✅ [HighlightCard] Using highlight data: name="$candidateName", party="$candidateParty", imageUrl="$candidateProfileImageUrl"');
      return;
    }

    // Fallback: try to fetch directly from candidate collection using highlight location
    try {
      final firestore = FirebaseFirestore.instance;
      final candidateDoc = await firestore
          .collection('states')
          .doc(widget.highlight.stateId)
          .collection('districts')
          .doc(widget.highlight.districtId)
          .collection('bodies')
          .doc(widget.highlight.bodyId)
          .collection('wards')
          .doc(widget.highlight.wardId)
          .collection('candidates')
          .doc(widget.highlight.candidateId)
          .get();

      if (candidateDoc.exists && mounted) {
        final candidateData = candidateDoc.data();
        AppLogger.common('✅ [HighlightCard] Found candidate document: ${candidateDoc.id}');
        setState(() {
          candidateProfileImageUrl = candidateData?['photo'];
          candidateName = candidateData?['name'] ?? widget.highlight.candidateName ?? 'Candidate';
          candidateParty = candidateData?['party'] ?? widget.highlight.party ?? 'Party';
          isLoadingProfile = false;
        });
        AppLogger.common('✅ [HighlightCard] Using fresh candidate data: name="$candidateName", party="$candidateParty", imageUrl="$candidateProfileImageUrl"');
      } else {
        // Final fallback: use highlight data
        if (mounted) {
          setState(() {
            candidateName = widget.highlight.candidateName ?? 'Candidate';
            candidateParty = widget.highlight.party ?? 'Party';
            isLoadingProfile = false;
          });
          AppLogger.common('✅ [HighlightCard] Using highlight data (fallback): name="$candidateName", party="$candidateParty"');
        }
      }
    } catch (e) {
      AppLogger.common('❌ [HighlightCard] Error fetching candidate data: $e');
      if (mounted) {
        setState(() {
          candidateName = widget.highlight.candidateName ?? 'Candidate';
          candidateParty = widget.highlight.party ?? 'Party';
          isLoadingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, // w-40 equivalent
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Image - matches HTML design
              Container(
                width: 70,
                height: 70,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50), // rounded-full
                  image: candidateProfileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(candidateProfileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[100],
                ),
                child: candidateProfileImageUrl == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.grey,
                        size: 28,
                      )
                    : null,
              ),

              // Candidate Info - matches HTML (reduced padding)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final displayName = candidateName ?? widget.highlight.candidateName ?? 'Candidate';
                        AppLogger.common('📋 [HighlightCard] Displaying name: "$displayName" for highlight: ${widget.highlight.id}');
                        return Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      candidateParty ?? widget.highlight.party ?? 'Party',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // View Button - matches HTML design (smaller)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.highlight.package == 'platinum' ? Colors.purple[100] : Colors.grey[200],
                    foregroundColor: widget.highlight.package == 'platinum' ? Colors.purple[900] : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: const Size(double.infinity, 28),
                  ),
                  child: Text(widget.highlight.package == 'platinum' ? 'PREMIUM' : 'View'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
