import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/symbol_utils.dart';
import '../services/highlight_service.dart';
import '../../../features/candidate/screens/candidate_profile_screen.dart';
import '../../../features/candidate/models/candidate_model.dart';
import '../models/highlight_display_model.dart';
import '../../../features/monetization/controllers/monetization_controller.dart';
import 'highlight_card.dart';

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
  State<CandidateHighlightBanner> createState() =>
      _CandidateHighlightBannerState();
}

class _CandidateHighlightBannerState extends State<CandidateHighlightBanner> {
  int _currentIndex = 0;
  List<HomeHighlight> _highlights = [];
  bool _isLoading = true;
  bool _hasError = false;
  Widget _currentSymbol = const Icon(Icons.star, color: Colors.amber, size: 25);
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    try {
      AppLogger.common('🎯 HighlightBanner: === LOADING HIGHLIGHTS START ===');
      AppLogger.common(
        '🎯 HighlightBanner: Location: ${widget.districtId}/${widget.bodyId}/${widget.wardId}',
      );

      // Log current timestamp for expiry checking
      final now = DateTime.now();
      AppLogger.common('🎯 HighlightBanner: Current timestamp: $now');

      final highlights = await HighlightService.getActiveHighlights(
        widget.stateId,
        widget.districtId,
        widget.bodyId,
        widget.wardId,
      );

      final homeHighlights = highlights
          .map((h) => HomeHighlight.fromHighlight(h))
          .where((h) => h.isActive && !h.isExpired)
          .take(10) // Max 10 for carousel rotation
          .toList();

      // Check if no highlights found and log the conditions
      if (homeHighlights.isEmpty) {
        AppLogger.common(
          '❗ HighlightBanner: No highlights to display. Checking conditions:',
        );
        AppLogger.common('   - Raw highlights count: ${highlights.length}');

        if (highlights.isNotEmpty) {
          final activeCount = highlights.where((h) => h.active).length;
          final nonExpiredCount = highlights
              .where((h) => !now.isAfter(h.endDate))
              .length;
          final bothCount = highlights
              .where((h) => h.active && !now.isAfter(h.endDate))
              .length;

          AppLogger.common('   - Active highlights: $activeCount');
          AppLogger.common('   - Non-expired highlights: $nonExpiredCount');
          AppLogger.common('   - Both active and non-expired: $bothCount');
        }
      }

      if (mounted) {
        setState(() {
          _highlights = homeHighlights;
          _isLoading = false;
          _hasError = false;
        });

        // Carousel will handle auto-rotation if multiple highlights
        if (_highlights.length > 1) {
          AppLogger.common(
            '🔄 HighlightBanner: Carousel will auto-rotate ${_highlights.length} highlights',
          );
        } else if (_highlights.length == 1) {
          AppLogger.common(
            '📌 HighlightBanner: Single highlight - no rotation needed',
          );
        }

        // Track impression for first highlight
        if (_highlights.isNotEmpty) {
          AppLogger.common(
            '👁️ HighlightBanner: Tracking impression for first highlight: ${_highlights[0].id}',
          );
          _trackImpression(_highlights[0]);

          // Load symbol for first highlight
          _loadPartySymbolForCurrentHighlight();
        }
      } else {
        AppLogger.common(
          '⚠️ HighlightBanner: Widget not mounted, skipping setState',
        );
      }

      AppLogger.common('🎯 HighlightBanner: === LOADING HIGHLIGHTS END ===\n');
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightBanner: Error loading highlights',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Load party symbol for current highlight
  void _loadPartySymbolForCurrentHighlight() async {
    if (_highlights.isEmpty || !mounted) return;

    final currentHighlight = _highlights[_currentIndex];
    final party = currentHighlight.party ?? 'independent';

    // For independent candidates, check for custom symbol via service
    if (party.toLowerCase().contains('independent')) {
      try {
        final symbolUrl = await HighlightService.getCandidateSymbolUrl(
          stateId: widget.stateId,
          districtId: currentHighlight.districtId,
          bodyId: currentHighlight.bodyId,
          wardId: currentHighlight.wardId,
          candidateId: currentHighlight.candidateId,
        );

        if (symbolUrl != null && mounted) {
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
                  return Image.asset(
                    'assets/symbols/independent.png',
                    width: 35,
                    height: 35,
                    fit: BoxFit.cover,
                  );
                },
              ),
            );
          });
          return;
        }
      } catch (e) {
        AppLogger.commonError(
          '❌ HighlightBanner: Error fetching custom symbol',
          error: e,
        );
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
      HighlightService.trackImpression(
        highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId,
      );
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightBanner: Error tracking impression',
        error: e,
      );
    }
  }

  void _trackClick(HomeHighlight highlight) {
    try {
      HighlightService.trackClick(
        highlight.id,
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId,
      );
    } catch (e) {
      AppLogger.commonError(
        '❌ HighlightBanner: Error tracking click',
        error: e,
      );
    }
  }

  void _onHighlightTap(HomeHighlight highlight) async {
    _trackClick(highlight);

    // Navigate to candidate profile
    try {
      AppLogger.common(
        '🎯 HighlightBanner: Navigating to candidate profile for ${highlight.candidateName} (${highlight.candidateId})',
      );

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

        AppLogger.common(
          '✅ HighlightBanner: Found candidate, navigating to profile',
        );
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
      AppLogger.commonError(
        '❌ HighlightBanner: Error fetching candidate data',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading candidate profile: ${e.toString()}'),
          ),
        );
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
    final currentUser =
        Get.find<MonetizationController>().currentUserModel.value;
    final hasCarouselPlan =
        currentUser?.carouselPlanId != null &&
        currentUser?.carouselPlanExpiresAt != null &&
        DateTime.now().isBefore(currentUser!.carouselPlanExpiresAt!);

    return Column(
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
    );
  }

  // Main banner-style design with carousel_slider for auto-rotation
  Widget _buildBannerDesign(BuildContext context) {
    if (_highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_highlights.length == 1) {
      // Single highlight - show static banner
      return _buildSingleBanner(context, _highlights[0]);
    }

    // Multiple highlights - use carousel
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
          ), // Removed horizontal padding for full width
          child: CarouselSlider(
            carouselController: _carouselController,
            options: CarouselOptions(
              height:
                  240, // Increased height to accommodate banner + info section below
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.easeInOut,
              enlargeCenterPage: false,
              viewportFraction:
                  0.9, // Allow space between cards (90% of screen width)
              padEnds: true, // Add padding at ends
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
                // Update party symbol for new highlight
                _loadPartySymbolForCurrentHighlight();
                // Track impression when highlight changes
                _trackImpression(_highlights[index]);
              },
            ),
            items: _highlights.map((highlight) {
              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                ), // 10px margin on each side = 20px gap between cards
                child: Column(
                  children: [
                    _buildSingleBanner(context, highlight),
                    const SizedBox(height: 8),
                    _buildCandidateInfoSectionForCard(context, highlight),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // Auto-rotation indicator (dots) outside the cards
        if (_highlights.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _highlights.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.blue.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to build a single banner item with enhanced design
  Widget _buildSingleBanner(BuildContext context, HomeHighlight highlight) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onHighlightTap(highlight),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            16,
          ), // Increased to 16px for better card-style look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ), // Slightly stronger shadow
              blurRadius: 12, // Increased blur for softer shadow
              offset: const Offset(0, 6), // Increased offset for more depth
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image with gradient overlay
              SizedBox(
                width: double.infinity,
                height: 180, // Main banner height
                child: Stack(
                  children: [
                    // Candidate image as background
                    Positioned.fill(child: _buildCandidateImage(highlight)),
                    // Light gradient overlay for better text visibility
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(
                                alpha: 0.1,
                              ), // Very light overlay at top
                              Colors.black.withValues(
                                alpha: 0.3,
                              ), // Medium overlay at bottom
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Party logo watermark (10-20% opacity) in bottom right corner
              Positioned(
                bottom: 16,
                right: 16,
                child: Opacity(
                  opacity: 0.15, // 15% opacity for subtle watermark effect
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: _buildPartySymbolForWatermark(highlight),
                    ),
                  ),
                ),
              ),

              // Floating party symbol (upper left) - enhanced with animation
              Positioned(
                top: 12,
                left: 12,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
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
                    child: ClipOval(child: _buildPartySymbol()),
                  ),
                ),
              ),

              // Floating arrow button (right side) - enhanced with animation
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
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

  // Helper method to build party symbol for watermark (specific to highlight)
  Widget _buildPartySymbolForWatermark(HomeHighlight highlight) {
    final party = highlight.party ?? 'independent';

    // For independent candidates, check Firebase for custom symbol
    if (party.toLowerCase().contains('independent')) {
      // For watermark, we'll use a simple fallback since we can't async load here
      return Image.asset(
        'assets/symbols/independent.png',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.star, color: Colors.amber, size: 25);
        },
      );
    }

    // For regular parties, use SymbolUtils
    final symbolPath = SymbolUtils.getPartySymbolPath(party);
    return Image(
      image: SymbolUtils.getSymbolImageProvider(symbolPath),
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.star, color: Colors.amber, size: 25);
      },
    );
  }

  // Helper method to build candidate info section for each carousel card
  Widget _buildCandidateInfoSectionForCard(
    BuildContext context,
    HomeHighlight highlight,
  ) {
    final candidateName = highlight.candidateName;
    final partyName = highlight.party ?? 'Independent';
    final partyKey =
        SymbolUtils.convertOldPartyNameToKey(partyName) ?? partyName;
    final partyShortName = SymbolUtils.getPartySymbolNameLocal(partyKey, Get.locale?.languageCode ?? 'en'),//SymbolUtils.getPartyShortName(partyKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Party symbol icon
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(child: _buildPartySymbolForInfo(highlight)),
          ),

          // Candidate name and party short name
          Expanded(
            child: Text(
              '$candidateName - $partyShortName',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build party symbol for info section
  Widget _buildPartySymbolForInfo(HomeHighlight highlight) {
    final party = highlight.party ?? 'independent';

    // For independent candidates, use a simple icon
    if (party.toLowerCase().contains('independent')) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.grey, size: 20),
      );
    }

    // For regular parties, use SymbolUtils
    final symbolPath = SymbolUtils.getPartySymbolPath(party);
    return Image(
      image: SymbolUtils.getSymbolImageProvider(symbolPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.star, color: Colors.amber, size: 20),
        );
      },
    );
  }
}
