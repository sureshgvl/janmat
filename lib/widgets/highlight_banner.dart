import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/highlight_service.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/screens/candidate_profile_screen.dart';

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

   // Helper method to get gradient colors based on banner style
   static List<Color> getBannerGradient(String? bannerStyle) {
     switch (bannerStyle) {
       case 'premium':
         return [Colors.blue.shade600, Colors.blue.shade800];
       case 'elegant':
         return [Colors.purple.shade600, Colors.purple.shade800];
       case 'bold':
         return [Colors.red.shade600, Colors.red.shade800];
       case 'minimal':
         return [Colors.grey.shade600, Colors.grey.shade800];
       default:
         return [Colors.blue.shade600, Colors.blue.shade800];
     }
   }

   // Helper method to get call to action text
   static String getCallToAction(String? callToAction) {
     return callToAction ?? 'View Profile';
   }

  @override
  _HighlightBannerState createState() => _HighlightBannerState();
}

class _HighlightBannerState extends State<HighlightBanner> {
  Highlight? platinumBanner;
  String? candidateProfileImageUrl;
  bool isLoading = true;
  String? bannerStyle;
  String? callToAction;
  String? customMessage;
  String? priorityLevel;

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

      // Extract enhanced configuration from banner data
      String? bannerStyleConfig;
      String? callToActionConfig;
      String? customMessageConfig;
      String? priorityLevelConfig;

      if (banner != null) {
        // Get the full document data to access enhanced fields
        final snapshot = await FirebaseFirestore.instance
            .collection('highlights')
            .where('locationKey', isEqualTo: '${widget.districtId}_${widget.bodyId}_${widget.wardId}')
            .where('active', isEqualTo: true)
            .where('placement', arrayContains: 'top_banner')
            .orderBy('priority', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          bannerStyleConfig = data['bannerStyle'] as String?;
          callToActionConfig = data['callToAction'] as String?;
          customMessageConfig = data['customMessage'] as String?;
          priorityLevelConfig = data['priorityLevel'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          platinumBanner = banner;
          candidateProfileImageUrl = profileImageUrl;
          bannerStyle = bannerStyleConfig;
          callToAction = callToActionConfig;
          customMessage = customMessageConfig;
          priorityLevel = priorityLevelConfig;
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
    try {
      // Fetch candidate data from Firestore
      final candidateDoc = await FirebaseFirestore.instance
          .collection('candidates')
          .doc(platinumBanner!.candidateId)
          .get();

      if (candidateDoc.exists && mounted) {
        final candidateData = candidateDoc.data();
        if (candidateData != null) {
          // Create candidate object
          final candidate = Candidate(
            candidateId: platinumBanner!.candidateId,
            userId: candidateData['userId'] ?? '',
            name: candidateData['name'] ?? platinumBanner!.candidateName ?? '',
            party: candidateData['party'] ?? platinumBanner!.party ?? '',
            photo: candidateData['photo'],
            districtId: candidateData['districtId'] ?? widget.districtId,
            bodyId: candidateData['bodyId'] ?? widget.bodyId,
            wardId: candidateData['wardId'] ?? widget.wardId,
            stateId: candidateData['stateId'],
            sponsored: candidateData['sponsored'] ?? false,
            premium: candidateData['premium'] ?? false,
            contact: Contact.fromJson(candidateData['contact'] ?? {}),
            createdAt: candidateData['createdAt'] is Timestamp
                ? (candidateData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            extraInfo: candidateData['extraInfo'] != null
                ? ExtraInfo.fromJson(candidateData['extraInfo'])
                : null,
          );

          // Navigate to candidate profile screen
          Get.to(() => const CandidateProfileScreen(), arguments: candidate);
        }
      }
    } catch (e) {
      print('Error navigating to candidate profile: $e');
      // Fallback: show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load candidate profile'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
        // Main banner section - matches HTML design
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: _onBannerTap,
              child: Stack(
                children: [
                  // Background with custom gradient styling
                  Container(
                    height: 192, // h-48 equivalent
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: HighlightBanner.getBannerGradient(bannerStyle),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: platinumBanner!.imageUrl != null
                        ? Image.network(
                            platinumBanner!.imageUrl!,
                            fit: BoxFit.cover,
                            color: Colors.white.withOpacity(0.3),
                            colorBlendMode: BlendMode.overlay,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: HighlightBanner.getBannerGradient(bannerStyle),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white70,
                                ),
                              );
                            },
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: HighlightBanner.getBannerGradient(bannerStyle),
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white70,
                            ),
                          ),
                  ),

                  // Highlight Badge - top left like HTML
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9933), // Saffron color
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⭐ HIGHLIGHT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom gradient overlay - matches HTML
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content at bottom - matches HTML layout
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        // Candidate info on left
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                platinumBanner!.candidateName ?? 'Featured Candidate',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
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
                              // Show custom message or party name
                              Text(
                                customMessage?.isNotEmpty == true
                                    ? '"$customMessage"'
                                    : platinumBanner!.party ?? 'Political Party',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontStyle: customMessage?.isNotEmpty == true ? FontStyle.italic : FontStyle.normal,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Party symbol on right - matches HTML
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Impression tracking overlay
                  Positioned.fill(child: Container(color: Colors.transparent)),
                ],
              ),
            ),
          ),
        ),

        // View Profile button below banner - matches HTML
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onBannerTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976d2), // Primary blue
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              HighlightBanner.getCallToAction(callToAction),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
