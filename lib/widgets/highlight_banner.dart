import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/highlight_service.dart';

class HighlightBanner extends StatefulWidget {
  final String districtId;
  final String bodyId;
  final String wardId;

  const HighlightBanner({
    super.key,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  @override
  _HighlightBannerState createState() => _HighlightBannerState();
}

class _HighlightBannerState extends State<HighlightBanner> {
  Highlight? platinumBanner;
  String? candidateProfileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlatinumBanner();
  }

  @override
  void didUpdateWidget(HighlightBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.districtId != widget.districtId ||
        oldWidget.bodyId != widget.bodyId ||
        oldWidget.wardId != widget.wardId) {
      _loadPlatinumBanner();
    }
  }

  Future<void> _loadPlatinumBanner() async {
    if (widget.districtId.isEmpty ||
        widget.bodyId.isEmpty ||
        widget.wardId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final banner = await HighlightService.getPlatinumBanner(
        widget.districtId,
        widget.bodyId,
        widget.wardId,
      );

      // Fetch candidate's profile picture if banner exists
      String? profileImageUrl;
      if (banner != null && banner.candidateId.isNotEmpty) {
        try {
          final candidateDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(banner.candidateId)
              .get();

          if (candidateDoc.exists) {
            profileImageUrl = candidateDoc.data()?['profileImageUrl'];
          }
        } catch (e) {
          print('Error fetching candidate profile image: $e');
        }
      }

      if (mounted) {
        setState(() {
          platinumBanner = banner;
          candidateProfileImageUrl = profileImageUrl;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading platinum banner: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onBannerTap() async {
    if (platinumBanner == null) return;

    // Track click
    await HighlightService.trackClick(platinumBanner!.id);

    // Track view analytics
    await _trackBannerView();

    // Navigate to candidate profile
    print('Navigate to candidate: ${platinumBanner!.candidateId}');
  }

  Future<void> _trackBannerView() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || platinumBanner == null) return;

      await FirebaseFirestore.instance.collection('section_views').add({
        'sectionType': 'banner',
        'contentId': platinumBanner!.id,
        'userId': userId,
        'candidateId': platinumBanner!.candidateId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
        'location': {
          'districtId': widget.districtId,
          'bodyId': widget.bodyId,
          'wardId': widget.wardId,
        },
      });
    } catch (e) {
      print('Error tracking banner view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: [
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (platinumBanner == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.6; // 60% of screen width for height

    return Column(
      children: [
        GestureDetector(
          onTap: _onBannerTap,
          child: Container(
            width: double.infinity,
            height: bannerHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // More rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  if (platinumBanner!.imageUrl != null)
                    Image.network(
                      platinumBanner!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1976d2).withOpacity(0.1),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Color(0xFF1976d2),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color(0xFF1976d2).withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF1976d2),
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Highlight Badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9933), // Saffron color
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'HIGHLIGHT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Section
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Candidate Info
                        Text(
                          platinumBanner!.candidateName ?? 'Featured Candidate',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          platinumBanner!.party ?? 'Political Party',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
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
                      ],
                    ),
                  ),

                  // View Profile Button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976d2), // Primary blue
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Impression tracking overlay (invisible)
                  Positioned.fill(child: Container(color: Colors.transparent)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
