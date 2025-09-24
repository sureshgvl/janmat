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
      print('Error fetching candidate profile image: $e');
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
      print('Error tracking carousel view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _defaultOnTap(context),
      child: Container(
        width: 160, // Smaller width for carousel
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // More rounded
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundImage: candidateProfileImageUrl != null
                    ? NetworkImage(candidateProfileImageUrl!)
                    : null,
                backgroundColor: Colors.grey[100],
                child: candidateProfileImageUrl == null
                    ? Icon(Icons.person, color: Colors.grey, size: 32)
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            // Candidate Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    widget.highlight.candidateName ?? 'Candidate',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    widget.highlight.party ?? 'Party',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // View Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _defaultOnTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _defaultOnTap(BuildContext context) {
    // Track click
    HighlightService.trackClick(widget.highlight.id);

    // Default navigation - you'll need to implement this based on your routing
    print('Navigate to candidate profile: ${widget.highlight.candidateId}');

    // Example navigation (adjust based on your app's routing):
    // Navigator.pushNamed(
    //   context,
    //   '/candidate-profile',
    //   arguments: {'candidateId': widget.highlight.candidateId},
    // );
  }
}
