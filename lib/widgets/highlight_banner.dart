import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/highlight_service.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/screens/candidate_profile_screen.dart';
import '../features/candidate/repositories/candidate_repository.dart';
import '../utils/symbol_utils.dart';

class HighlightBanner extends StatefulWidget {
    final String districtId;
    final String bodyId;
    final String wardId;
    final bool showViewMoreButton;

    const HighlightBanner({
      super.key,
      required this.districtId,
      required this.bodyId,
      required this.wardId,
      this.showViewMoreButton = false,
    });

   // Static method to refresh all banner instances
   static void refreshBanners() {
     // This will be called when candidate data is updated
     // The banner will reload data on next build
   }

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
    String? candidateParty;
    String? candidateName;
    bool isLoading = true;
    String? bannerStyle;
    String? callToAction;
    String? customMessage;
    String? priorityLevel;

    // Global key for external access
    static final GlobalKey<_HighlightBannerState> _globalKey = GlobalKey<_HighlightBannerState>();

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

  @override
  void dispose() {
    super.dispose();
  }

  // Public method to refresh banner data when candidate profile is updated
  void refreshBannerData() {
    print('🔄 [HighlightBanner] Refreshing banner data due to candidate profile update');
    _loadPlatinumBanner();
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

      // Fetch candidate data if banner exists
      String? profileImageUrl;
      String? candidateParty;
      if (banner != null && banner.candidateId.isNotEmpty) {
        try {
          // Use candidate repository to fetch candidate data (handles hierarchical structure)
          final candidateRepository = CandidateRepository();
          print('🔍 [HighlightBanner] Fetching candidate data for ID: ${banner.candidateId}');
          final candidate = await candidateRepository.getCandidateDataById(banner.candidateId);

          if (candidate != null) {
            profileImageUrl = candidate.photo;
            candidateParty = candidate.party;
            candidateName = candidate.name;

            // Debug logging
            print('🎯 [HighlightBanner] Candidate data loaded successfully:');
            print('   candidateId: ${banner.candidateId}');
            print('   name: ${candidate.name}');
            print('   photo URL: $profileImageUrl');
            print('   party: $candidateParty');
            print('   candidate.party directly: ${candidate.party}');
            print('   candidate.toJson()["party"]: ${candidate.toJson()["party"]}');
            print('   Raw candidate object: ${candidate.toJson()}');
          } else {
            print('❌ [HighlightBanner] Candidate not found for ID: ${banner.candidateId}');
            print('   This means getCandidateDataById returned null');
          }
        } catch (e) {
          print('❌ [HighlightBanner] Error fetching candidate data: $e');
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
          candidateParty = candidateParty;
          candidateName = candidateName;
          bannerStyle = bannerStyleConfig;
          callToAction = callToActionConfig;
          customMessage = customMessageConfig;
          priorityLevel = priorityLevelConfig;
          isLoading = false;
        });

        // Animation removed - no longer needed
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
      // Use candidate repository to fetch candidate data (handles hierarchical structure)
      final candidateRepository = CandidateRepository();
      final candidate = await candidateRepository.getCandidateDataById(platinumBanner!.candidateId);

      if (candidate != null && mounted) {
        // Navigate to candidate profile screen
        Get.to(() => const CandidateProfileScreen(), arguments: candidate);
      } else {
        print('❌ [HighlightBanner] Candidate not found for navigation: ${platinumBanner!.candidateId}');
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
    } catch (e) {
      print('❌ [HighlightBanner] Error navigating to candidate profile: $e');
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
              child: SizedBox(
                height: 192,
                child: Stack(
                  children: [
                    // Background with custom gradient styling
                    Container(
                      height: 192,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: HighlightBanner.getBannerGradient(bannerStyle),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: candidateProfileImageUrl != null
                          ? Image.network(
                              candidateProfileImageUrl!,
                              fit: BoxFit.cover,
                              color: Colors.white.withOpacity(0.3),
                              colorBlendMode: BlendMode.overlay,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to stored highlight imageUrl if available
                                if (platinumBanner!.imageUrl != null) {
                                  return Image.network(
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
                                  );
                                } else {
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
                                }
                              },
                            )
                          : platinumBanner!.imageUrl != null
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


                    // Impression tracking overlay
                    Positioned.fill(child: Container(color: Colors.transparent)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // View More button (conditional)
        if (widget.showViewMoreButton) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onBannerTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976d2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View More',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
