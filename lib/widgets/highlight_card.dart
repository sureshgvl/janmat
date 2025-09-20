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
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              if (widget.highlight.imageUrl != null)
                Image.network(
                  widget.highlight.imageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 48, color: Colors.grey),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),

              // Sponsored Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'HIGHLIGHT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Picture Overlay
              Positioned(
                bottom: 100,
                left: 16,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: candidateProfileImageUrl != null
                        ? NetworkImage(candidateProfileImageUrl!)
                        : null,
                    backgroundColor: Colors.white,
                    child: candidateProfileImageUrl == null
                        ? Icon(Icons.person, color: Colors.grey, size: 24)
                        : null,
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Candidate Name
                    Text(
                      widget.highlight.candidateName ?? 'Candidate',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Party Name
                    Text(
                      widget.highlight.party ?? 'Party',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // View Profile Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Package Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.highlight.package == 'platinum'
                        ? Colors.purple
                        : Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.highlight.package.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
    print('Navigate to candidate profile: ${widget.highlight.candidateId}');

    // Example navigation (adjust based on your app's routing):
    // Navigator.pushNamed(
    //   context,
    //   '/candidate-profile',
    //   arguments: {'candidateId': widget.highlight.candidateId},
    // );
  }
}
