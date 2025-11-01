import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/symbol_utils.dart';
import '../services/highlight_service.dart';
import '../../../features/candidate/screens/candidate_profile_screen.dart';
import '../../../features/candidate/models/candidate_model.dart';
import '../models/highlight_display_model.dart';
import '../../../features/monetization/controllers/monetization_controller.dart';
import 'highlight_carousel_widget.dart';

class CandidateHighlightBanner extends StatefulWidget {
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;

  const CandidateHighlightBanner({
    super.key,
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  // Static method to refresh all banner instances
  static void refreshAllBanners() {
    // Since we can't directly access state from static method,
    // we'll use GetX to find and refresh banner controllers
    // This approach works well for the app's architecture
  }

  @override
  State<CandidateHighlightBanner> createState() => _CandidateHighlightBannerState();
}

class _CandidateHighlightBannerState extends State<CandidateHighlightBanner> {
  late Timer _rotationTimer;
  int _currentIndex = 0;
  List<HomeHighlight> _highlights = [];
  bool _isLoading = true;
  bool _hasError = false;
  Widget _currentSymbol = const Icon(Icons.star, color: Colors.amber, size: 25);

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  @override
  void dispose() {
    _rotationTimer.cancel();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    try {
      AppLogger.common('🎯 HighlightBanner: === LOADING HIGHLIGHTS START ===');
      AppLogger.common('🎯 HighlightBanner: Location: ${widget.districtId}/${widget.bodyId}/${widget.wardId}');

      // Log current timestamp for expiry checking
      final now = DateTime.now();
      AppLogger.common('🎯 HighlightBanner: Current timestamp: $now');

      final highlights = await HighlightService.getActiveHighlights(
        widget.stateId,
        widget.districtId,
        widget.bodyId,
        widget.wardId
      );

      AppLogger.common('🎯 HighlightBanner: Raw highlights from service: ${highlights.length}');

      // Log details of each highlight for debugging
      for (int i = 0; i < highlights.length; i++) {
        final h = highlights[i];
        AppLogger.common('🔍 Raw highlight ${i+1}: ID=${h.id}, Active=${h.active}, Name=${h.candidateName}');
        AppLogger.common('   Package: ${h.package}, Placement: ${h.placement}');
        AppLogger.common('   Dates: Start=${h.startDate}, End=${h.endDate}');
        AppLogger.common('   Is expired: ${now.isAfter(h.endDate)}');
      }

      final homeHighlights = highlights
          .map((h) => HomeHighlight.fromHighlight(h))
          .where((h) => h.isActive && !h.isExpired)
          .take(10) // Max 10 for carousel rotation
          .toList();

      AppLogger.common('🎯 HighlightBanner: After filtering: ${homeHighlights.length} active, non-expired highlights');

      // Log which highlights passed filtering
      for (int i = 0; i < homeHighlights.length; i++) {
        final h = homeHighlights[i];
        AppLogger.common('✅ Filtered highlight ${i+1}: ID=${h.id}, Name=${h.candidateName}, Package=${h.package}');
        AppLogger.common('   Active=${h.isActive}, Expired=${h.isExpired}');
      }

      // Check if no highlights found and log the conditions
      if (homeHighlights.isEmpty) {
        AppLogger.common('❗ HighlightBanner: No highlights to display. Checking conditions:');
        AppLogger.common('   - Raw highlights count: ${highlights.length}');

        if (highlights.isNotEmpty) {
          final activeCount = highlights.where((h) => h.active).length;
          final nonExpiredCount = highlights.where((h) => !now.isAfter(h.endDate)).length;
          final bothCount = highlights.where((h) => h.active && !now.isAfter(h.endDate)).length;

          AppLogger.common('   - Active highlights: $activeCount');
          AppLogger.common('   - Non-expired highlights: $nonExpiredCount');
          AppLogger.common('   - Both active and non-expired: $bothCount');

          // Check specific highlights that failed filtering
          for (final h in highlights) {
            if (!(h.active && !now.isAfter(h.endDate))) {
              AppLogger.common('❌ Excluded highlight: ID=${h.id}, Active=${h.active}, Expired=${now.isAfter(h.endDate)}');
            }
          }
        }

        // Check current user's location vs banner location
        AppLogger.common('📍 HighlightBanner: Checking if this matches user location for banner display');

        // Note: Banner will be hidden by build() method conditions
        AppLogger.common('🐛 HighlightBanner: Banner will be hidden (empty highlights list)');
      }

      if (mounted) {
        setState(() {
          _highlights = homeHighlights;
          _isLoading = false;
          _hasError = false;
        });

        // Start rotation if multiple highlights
        if (_highlights.length > 1) {
          AppLogger.common('🔄 HighlightBanner: Starting rotation timer for ${_highlights.length} highlights');
          _startRotation();
        } else if (_highlights.length == 1) {
          AppLogger.common('📌 HighlightBanner: Single highlight - no rotation needed');
        }

        // Track impression for first highlight
        if (_highlights.isNotEmpty) {
          AppLogger.common('👁️ HighlightBanner: Tracking impression for first highlight: ${_highlights[0].id}');
          _trackImpression(_highlights[0]);

          // Load symbol for first highlight
          _loadPartySymbolForCurrentHighlight();
        }
      } else {
        AppLogger.common('⚠️ HighlightBanner: Widget not mounted, skipping setState');
      }

      AppLogger.common('🎯 HighlightBanner: === LOADING HIGHLIGHTS END ===\n');
    } catch (e) {
      AppLogger.commonError('❌ HighlightBanner: Error loading highlights', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startRotation() {
    _rotationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _highlights.isEmpty) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _highlights.length;
      });

      // Update party symbol for new highlight asynchronously
      _loadPartySymbolForCurrentHighlight();

      // Track impression when highlight changes
      _trackImpression(_highlights[_currentIndex]);
    });
  }

  // Load party symbol for current highlight
  void _loadPartySymbolForCurrentHighlight() async {
    if (_highlights.isEmpty || !mounted) return;

    final currentHighlight = _highlights[_currentIndex];
    final party = currentHighlight.party ?? 'independent';

    // For independent candidates, check Firebase for custom symbol
    if (party.toLowerCase().contains('independent')) {
      try {
        final firestore = FirebaseFirestore.instance;
        final candidateDoc = await firestore
            .collection('states')
            .doc(widget.stateId)
            .collection('districts')
            .doc(currentHighlight.districtId)
            .collection('bodies')
            .doc(currentHighlight.bodyId)
            .collection('wards')
            .doc(currentHighlight.wardId)
            .collection('candidates')
            .doc(currentHighlight.candidateId)
            .get();

        if (candidateDoc.exists && candidateDoc.data() != null && mounted) {
          final candidateData = candidateDoc.data()!;
          final symbolUrl = candidateData['symbol'] as String?;

          if (symbolUrl != null && symbolUrl.isNotEmpty && symbolUrl.startsWith('http')) {
            // Use custom symbol - update state
            setState(() {
              _currentSymbol = ClipOval(
                child: Image.network(
                  symbolUrl,
                  width: 35,
                  height: 35,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to generic independent symbol
                    return Image.asset('assets/symbols/independent.png',
                      width: 35, height: 35, fit: BoxFit.cover);
                  },
                ),
              );
            });
            return;
          }
        }
      } catch (e) {
        AppLogger.commonError('❌ HighlightBanner: Error fetching custom symbol', error: e);
      }
    }

    // For regular parties or fallback, use SymbolUtils
    final symbolPath = SymbolUtils.getPartySymbolPath(party);
    if (mounted) {
      setState(() {
        _currentSymbol = ClipOval(
          child: Image(
            image: SymbolUtils.getSymbolImageProvider(symbolPath),
            width: 35,
            height: 35,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to star icon
              return const Icon(Icons.star, color: Colors.amber, size: 25);
            },
          ),
        );
      });
    }
  }

  void _trackImpression(HomeHighlight highlight) {
    try {
      HighlightService.trackImpression(highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId);
    } catch (e) {
      AppLogger.commonError('❌ HighlightBanner: Error tracking impression', error: e);
    }
  }

  void _trackClick(HomeHighlight highlight) {
    try {
      HighlightService.trackClick(highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId);
    } catch (e) {
      AppLogger.commonError('❌ HighlightBanner: Error tracking click', error: e);
    }
  }

  void _onHighlightTap(HomeHighlight highlight) async {
    _trackClick(highlight);

    // Navigate to candidate profile
    try {
      AppLogger.common('🎯 HighlightBanner: Navigating to candidate profile for ${highlight.candidateName} (${highlight.candidateId})');

      // Optimized: Fetch candidate data directly using location from highlight
      // Since highlights contain location info, we can query more efficiently
      final firestore = FirebaseFirestore.instance;
      final candidateDoc = await firestore
          .collection('states')
          .doc(widget.stateId) // Use the stateId parameter
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

        // Parse the candidate data using Candidate model
        final candidate = Candidate.fromJson(candidateData);

        AppLogger.common('✅ HighlightBanner: Found candidate, navigating to profile');
        Get.to(() => const CandidateProfileScreen(), arguments: candidate);
      } else {
        AppLogger.common('❌ HighlightBanner: Candidate document not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidate profile not available')),
          );
        }
      }
    } catch (e) {
      AppLogger.commonError('❌ HighlightBanner: Error fetching candidate data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading candidate profile: ${e.toString()}')),
        );
      }
    }
  }

  void _onHighlightIndexChanged(int index) {
    // Track impression when user scrolls to a different highlight
    if (index != _currentIndex && index >= 0 && index < _highlights.length) {
      _currentIndex = index;
      if (_highlights.isNotEmpty) {
        _trackImpression(_highlights[_currentIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_hasError || _highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if user has carousel plan - check if user has carouselPlanId (simpler approach)
    final currentUser = Get.find<MonetizationController>().currentUserModel.value;
    final hasCarouselPlan = currentUser?.carouselPlanId != null &&
                           currentUser?.carouselPlanExpiresAt != null &&
                           DateTime.now().isBefore(currentUser!.carouselPlanExpiresAt!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MAIN HIGHLIGHT BANNER (Top Banner Plan - Single rotating banner)
          _buildBannerDesign(context),

          // CAROUSEL PLAN CARDS (Below banner - Horizontal card carousel)
          if (hasCarouselPlan && _highlights.length > 1) ...[
            HighlightCarouselWidget(
              stateId: widget.stateId,
              districtId: widget.districtId,
              bodyId: widget.bodyId,
              wardId: widget.wardId,
              highlights: _highlights,
            ),
          ],
        ],
      ),
    );
  }

  // Main banner-style design with party symbol overlay and auto-rotation
  Widget _buildBannerDesign(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentHighlight = _highlights[_currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: GestureDetector(
        onTap: () => _onHighlightTap(currentHighlight),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      Colors.blue.shade900.withValues(alpha: 0.3),
                      Colors.green.shade900.withValues(alpha: 0.3),
                    ]
                  : [
                      Colors.blue.shade100.withValues(alpha: 0.7),
                      Colors.green.shade100.withValues(alpha: 0.7),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Stack(
            children: [
              // Main content (image only)
              SizedBox(
                width: double.infinity,
                height: 180, // Main banner height
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCandidateImage(currentHighlight),
                ),
              ),

              // Floating party symbol (upper left)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _buildPartySymbol(),
                  ),
                ),
              ),

              // Floating arrow button (right side)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
              ),

              // Auto-rotation indicator (only show if multiple highlights)
              if (_highlights.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _highlights.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                        ),
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

  // Helper method to build candidate image
  Widget _buildCandidateImage(HomeHighlight highlight) {
    return highlight.candidatePhoto != null
        ? Image.network(
            highlight.candidatePhoto!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        : _buildPlaceholderImage();
  }

  // Helper method to build placeholder image
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 48, color: Colors.grey),
    );
  }

  // Helper method to build party symbol
  Widget _buildPartySymbol() {
    return _currentSymbol;
  }

  // Helper method for symbol images
  Widget _buildSymbolImage(String symbolPath) {
    return ClipOval(
      child: Image(
        image: SymbolUtils.getSymbolImageProvider(symbolPath),
        width: 35,
        height: 35,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.star,
            color: Colors.amber,
            size: 25,
          );
        },
      ),
    );
  }

  List<Color> _getGradientColors(HomeHighlight highlight) {
    return highlight.package == 'platinum'
      ? [const Color(0xFFE91E63), const Color(0xFF9C27B0)] // Pink to Purple
      : [const Color(0xFFFFC107), const Color(0xFFFF9800)]; // Gold to Orange
  }

  Color _getPackageColor(HomeHighlight highlight) {
    return highlight.package == 'platinum'
      ? const Color(0xFFE91E63)
      : const Color(0xFFFF9800);
  }
}

class HighlightCard extends StatefulWidget {
  final HomeHighlight highlight;
  final String? districtId;
  final String? bodyId;
  final String? wardId;

  const HighlightCard({
    super.key,
    required this.highlight,
    this.districtId,
    this.bodyId,
    this.wardId,
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
        onTap: () => _onTap(context),
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
                  onPressed: () => _onTap(context),
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

  void _onTap(BuildContext context) async {
    try {
      // Track click using HighlightService directly
      await HighlightService.trackClick(widget.highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId,
      );

      // Navigate to candidate profile - use the banner's navigation method by triggering the parent's tap handler
      final bannerState = context.findAncestorStateOfType<_CandidateHighlightBannerState>();
      if (bannerState != null) {
        bannerState._onHighlightTap(widget.highlight);
      }
    } catch (e) {
      AppLogger.common('Error in highlight card tap: $e');
    }
  }
}
