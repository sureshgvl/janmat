import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/highlight_model.dart';
import '../controllers/highlight_controller.dart';

class HighlightCard extends StatefulWidget {
  final Highlight highlight;
  final VoidCallback? onTap;

  const HighlightCard({super.key, required this.highlight, this.onTap});

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
    _trackCarouselView();
  }

  Future<void> _loadCandidateProfileImage() async {
    debugPrint('🔍 [HighlightCard] Loading candidate data for highlight: ${widget.highlight.id}, candidateId: ${widget.highlight.candidateId}');
    debugPrint('   Highlight data - name: "${widget.highlight.candidateName}", party: "${widget.highlight.party}", imageUrl: "${widget.highlight.imageUrl}"');

    // First, try to use the imageUrl from the highlight itself
    if (widget.highlight.imageUrl != null && widget.highlight.imageUrl!.isNotEmpty) {
      setState(() {
        candidateProfileImageUrl = widget.highlight.imageUrl;
        candidateName = widget.highlight.candidateName ?? 'Candidate';
        candidateParty = widget.highlight.party ?? 'Party';
        isLoadingProfile = false;
      });
      debugPrint('✅ [HighlightCard] Using highlight data: name="$candidateName", party="$candidateParty", imageUrl="$candidateProfileImageUrl"');
      return;
    }

    // Fallback: fetch from candidates collection
    if (widget.highlight.candidateId.isEmpty) {
      setState(() {
        candidateName = widget.highlight.candidateName ?? 'Candidate';
        candidateParty = widget.highlight.party ?? 'Party';
        isLoadingProfile = false;
      });
      return;
    }

    try {
      // Try to find candidate in the hierarchical structure
      // First get user data to find candidate location
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.highlight.candidateId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final electionAreas = userData?['electionAreas'] as List<dynamic>?;

        if (electionAreas != null && electionAreas.isNotEmpty) {
          final primaryArea = electionAreas.first as Map<String, dynamic>;
          final districtId = userData?['districtId'] ?? widget.highlight.districtId;
          final bodyId = primaryArea['bodyId'] ?? widget.highlight.bodyId;
          final wardId = primaryArea['wardId'] ?? widget.highlight.wardId;

          // Fetch candidate from hierarchical collection
          final candidateDoc = await FirebaseFirestore.instance
              .collection('states')
              .doc('maharashtra') // Assuming Maharashtra for now
              .collection('districts')
              .doc(districtId)
              .collection('bodies')
              .doc(bodyId)
              .collection('wards')
              .doc(wardId)
              .collection('candidates')
              .doc(widget.highlight.candidateId)
              .get();

          if (candidateDoc.exists && mounted) {
            final candidateData = candidateDoc.data();
            debugPrint('📋 [HighlightCard] Found candidate document: ${candidateDoc.id}');
            debugPrint('   Candidate data - name: "${candidateData?['name']}", party: "${candidateData?['party']}", photo: "${candidateData?['photo']}"');
            setState(() {
              candidateProfileImageUrl = candidateData?['photo'];
              candidateName = candidateData?['name'] ?? widget.highlight.candidateName ?? 'Candidate';
              candidateParty = candidateData?['party'] ?? widget.highlight.party ?? 'Party';
              isLoadingProfile = false;
            });
            debugPrint('✅ [HighlightCard] Using fresh candidate data: name="$candidateName", party="$candidateParty", imageUrl="$candidateProfileImageUrl"');
            return;
          } else {
            debugPrint('❌ [HighlightCard] Candidate document not found at path: states/maharashtra/districts/$districtId/bodies/$bodyId/wards/$wardId/candidates/${widget.highlight.candidateId}');
          }
        }
      }

      // Final fallback: use highlight data
      if (mounted) {
        setState(() {
          candidateName = widget.highlight.candidateName ?? 'Candidate';
          candidateParty = widget.highlight.party ?? 'Party';
          isLoadingProfile = false;
        });
        debugPrint('✅ [HighlightCard] Using highlight data (final fallback): name="$candidateName", party="$candidateParty"');
      }
    } catch (e) {
      debugPrint('❌ [HighlightCard] Error fetching candidate data: $e');
      if (mounted) {
        setState(() {
          candidateName = widget.highlight.candidateName ?? 'Candidate';
          candidateParty = widget.highlight.party ?? 'Party';
          isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _trackCarouselView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || widget.highlight.candidateId.isEmpty) return;

      final controller = Get.find<HighlightController>();
      await controller.trackCarouselView(
        contentId: widget.highlight.id,
        userId: userId,
        candidateId: widget.highlight.candidateId,
      );
    } catch (e) {
      debugPrint('Error tracking carousel view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160, // w-40 equivalent
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: widget.onTap ?? () => _defaultOnTap(context),
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
                        debugPrint('📋 [HighlightCard] Displaying name: "$displayName" for highlight: ${widget.highlight.id}');
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ElevatedButton(
                  onPressed: () => _defaultOnTap(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
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
                  child: const Text('View'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _defaultOnTap(BuildContext context) {
    // Track click
    final controller = Get.find<HighlightController>();
    controller.trackClick(widget.highlight.id);

    // Default navigation - you'll need to implement this based on your routing
    debugPrint('Navigate to candidate profile: ${widget.highlight.candidateId}');

    // Example navigation (adjust based on your app's routing):
    // Navigator.pushNamed(
    //   context,
    //   '/candidate-profile',
    //   arguments: {'candidateId': widget.highlight.candidateId},
    // );
  }
}

