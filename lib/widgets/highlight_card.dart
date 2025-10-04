import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/highlight_service.dart';

class HighlightCard extends StatefulWidget {
  final Highlight highlight;
  final VoidCallback? onTap;

  const HighlightCard({super.key, required this.highlight, this.onTap});

  @override
  _HighlightCardState createState() => _HighlightCardState();
}

class _HighlightCardState extends State<HighlightCard> {
  String? candidateProfileImageUrl;
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadCandidateProfileImage();
    _trackCarouselView();
  }

  Future<void> _loadCandidateProfileImage() async {
    if (widget.highlight.candidateId.isEmpty) {
      setState(() => isLoadingProfile = false);
      return;
    }

    try {
      final candidateDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.highlight.candidateId)
          .get();

      if (candidateDoc.exists && mounted) {
        setState(() {
          candidateProfileImageUrl = candidateDoc.data()?['profileImageUrl'];
          isLoadingProfile = false;
        });
      } else if (mounted) {
        setState(() => isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error fetching candidate profile image: $e');
      if (mounted) {
        setState(() => isLoadingProfile = false);
      }
    }
  }

  Future<void> _trackCarouselView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || widget.highlight.candidateId.isEmpty) return;

      await FirebaseFirestore.instance.collection('section_views').add({
        'sectionType': 'carousel',
        'contentId': widget.highlight.id,
        'userId': userId,
        'candidateId': widget.highlight.candidateId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
      });
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
                    Text(
                      widget.highlight.candidateName ?? 'Candidate',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.highlight.party ?? 'Party',
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
    HighlightService.trackClick(widget.highlight.id);

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

