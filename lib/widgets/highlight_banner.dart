import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/highlight_service.dart';
import '../repositories/highlight_repository.dart';
import '../models/highlight_model.dart' as highlight_model;
import '../features/candidate/screens/candidate_profile_screen.dart';
import '../features/candidate/repositories/candidate_repository.dart';
import '../features/candidate/models/candidate_model.dart' as candidate_model;
import '../utils/symbol_utils.dart';
import '../utils/app_logger.dart';

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
  List<highlight_model.Highlight> platinumBanners = [];
  int currentBannerIndex = 0;
  Timer? _rotationTimer;
  String? candidateProfileImageUrl;
  String? candidateParty;
  String? candidateName;
  bool isLoading = true;
  String? bannerStyle;
  String? callToAction;
  String? customMessage;
  String? priorityLevel;

  // Global key for external access
  static final GlobalKey<_HighlightBannerState> _globalKey =
      GlobalKey<_HighlightBannerState>();

  @override
  void initState() {
    super.initState();
    _loadHighlightBanners();
  }

  @override
  void didUpdateWidget(HighlightBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.districtId != widget.districtId ||
        oldWidget.bodyId != widget.bodyId ||
        oldWidget.wardId != widget.wardId) {
      _loadHighlightBanners();
    }
  }

  // Method to update banner data when rotation occurs
  void _onBannerRotated() {
    if (platinumBanners.isNotEmpty) {
      final currentBanner = platinumBanners[currentBannerIndex];
      // Load candidate data for the newly visible banner
      _loadCandidateDataForBanner(currentBanner);
    }
  }

  Future<void> _loadCandidateDataForBanner(highlight_model.Highlight banner) async {
    try {
      if (banner.candidateId.isNotEmpty) {
        final candidateRepository = CandidateRepository();
        AppLogger.database(
          'Fetching candidate data for rotated banner: ${banner.candidateId}',
          tag: 'CANDIDATE',
        );
        final candidate = await _fetchCandidateDataWithRetry(banner.candidateId);

        if (candidate != null && mounted) {
          // Resolve party symbol
          final partyValue = candidate.party ?? '';
          String resolvedParty;
          if (partyValue.length <= 20 &&
              partyValue.isNotEmpty &&
              RegExp(r'^[a-z]').hasMatch(partyValue) &&
              !partyValue.contains(' ') &&
              !partyValue.contains('Nationalist') &&
              !partyValue.contains('Congress') &&
              !partyValue.contains('Party')) {
            resolvedParty = partyValue;
          } else {
            resolvedParty = SymbolUtils.convertOldPartyNameToKey(partyValue) ?? partyValue;
          }

          setState(() {
            candidateProfileImageUrl = candidate.photo;
            candidateParty = resolvedParty;
            candidateName = candidate.name;
          });

          AppLogger.database(
            'Updated banner data for rotated banner: $candidateName ($resolvedParty)',
            tag: 'CANDIDATE',
          );
        }
      }
    } catch (e) {
      AppLogger.databaseError(
        'Error loading candidate data for rotated banner',
        tag: 'CANDIDATE',
        error: e,
      );
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  // Public method to refresh banner data when candidate profile is updated
  void refreshBannerData() {
    AppLogger.database(
      'Refreshing banner data due to candidate profile update',
      tag: 'CANDIDATE',
    );
    _loadHighlightBanners();
  }

  // Start rotation timer for multiple banners
  void _startRotationTimer(int bannerCount) {
    _rotationTimer?.cancel();
    if (bannerCount > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          setState(() {
            currentBannerIndex = (currentBannerIndex + 1) % bannerCount;
          });
          // Load candidate data for the newly visible banner
          _onBannerRotated();
        }
      });
    }
  }

  Future<void> _loadHighlightBanners() async {
    if (widget.districtId.isEmpty ||
        widget.bodyId.isEmpty ||
        widget.wardId.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final banners = await _fetchHighlightBanners();

      // If no banners found, set loading to false and return
      if (banners.isEmpty) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      // Store all banners for rotation
      platinumBanners = banners.map((banner) => highlight_model.Highlight(
        id: banner.id,
        candidateId: banner.candidateId,
        wardId: banner.wardId,
        districtId: banner.districtId,
        bodyId: banner.bodyId,
        locationKey: banner.locationKey,
        package: banner.package,
        placement: banner.placement,
        priority: banner.priority,
        startDate: banner.startDate,
        endDate: banner.endDate,
        active: banner.active,
        exclusive: banner.exclusive,
        rotation: banner.rotation,
        lastShown: banner.lastShown,
        views: banner.views,
        clicks: banner.clicks,
        imageUrl: banner.imageUrl,
        candidateName: banner.candidateName,
        party: banner.party,
        createdAt: banner.createdAt,
      )).toList();

      // Start rotation timer if multiple banners exist
      if (banners.length > 1) {
        _startRotationTimer(banners.length);
      }

      // Process banners for rotation - use current banner based on index
      // Only load candidate data for the first banner initially
      final currentBanner = platinumBanners[currentBannerIndex];

      // Fetch candidate data if banner exists
      String? profileImageUrl;
      if (currentBanner.candidateId.isNotEmpty) {
        try {
          // Use candidate repository to fetch candidate data with retry logic
          final candidateRepository = CandidateRepository();
          AppLogger.database(
            'Fetching candidate data for ID: ${currentBanner.candidateId}',
            tag: 'CANDIDATE',
          );
          final candidate = await _fetchCandidateDataWithRetry(
            currentBanner.candidateId,
          );

          if (candidate != null) {
            // First print all candidate data from Firebase (broken into chunks to avoid truncation)
            AppLogger.database(
              '💾 [CANDIDATE] Raw Firebase candidate data:',
              tag: 'CANDIDATE',
            );
            final jsonData = candidate.toJson();
            AppLogger.database('   📋 BASIC INFO:', tag: 'CANDIDATE');
            AppLogger.database(
              '     candidateId: ${candidate.candidateId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     userId: ${candidate.userId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     name: ${candidate.name}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     party: ${candidate.party}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     symbolUrl: ${candidate.symbolUrl}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     symbolName: ${candidate.symbolName}',
              tag: 'CANDIDATE',
            );

            AppLogger.database('   📍 LOCATION INFO:', tag: 'CANDIDATE');
            AppLogger.database(
              '     districtId: ${candidate.districtId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     stateId: ${candidate.stateId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     bodyId: ${candidate.bodyId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     wardId: ${candidate.wardId}',
              tag: 'CANDIDATE',
            );

            AppLogger.database('   📸 MEDIA INFO:', tag: 'CANDIDATE');
            AppLogger.database(
              '     photo: ${candidate.photo}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     coverPhoto: ${candidate.coverPhoto}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     manifesto: ${candidate.manifesto}',
              tag: 'CANDIDATE',
            );

            AppLogger.database('   ⚙️ STATUS INFO:', tag: 'CANDIDATE');
            AppLogger.database(
              '     sponsored: ${candidate.sponsored}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     premium: N/A (removed from candidate model)',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     approved: ${candidate.approved}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     status: ${candidate.status}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     createdAt: ${candidate.createdAt}',
              tag: 'CANDIDATE',
            );

            AppLogger.database('   📞 CONTACT INFO:', tag: 'CANDIDATE');
            AppLogger.database(
              '     phone: ${candidate.contact.phone}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     email: ${candidate.contact.email}',
              tag: 'CANDIDATE',
            );

            AppLogger.database('   📊 STATS:', tag: 'CANDIDATE');
            AppLogger.database(
              '     followersCount: ${candidate.followersCount}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '     followingCount: ${candidate.followingCount}',
              tag: 'CANDIDATE',
            );

            AppLogger.database(
              '   📋 EXTRA INFO EXISTS: ${candidate.extraInfo != null}',
              tag: 'CANDIDATE',
            );
            if (candidate.extraInfo != null) {
              AppLogger.database('   📋 EXTRA INFO DETAILS:', tag: 'CANDIDATE');
              AppLogger.database(
                '     bio: ${candidate.extraInfo!.bio}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     achievements count: ${candidate.extraInfo!.achievements?.length ?? 0}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     manifesto exists: ${candidate.extraInfo!.manifesto != null}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     contact exists: ${candidate.extraInfo!.contact != null}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     media count: ${candidate.extraInfo!.media?.length ?? 0}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     events count: ${candidate.extraInfo!.events?.length ?? 0}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     highlight exists: ${candidate.extraInfo!.highlight != null}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     analytics exists: ${candidate.extraInfo!.analytics != null}',
                tag: 'CANDIDATE',
              );
              AppLogger.database(
                '     basicInfo exists: ${candidate.extraInfo!.basicInfo != null}',
                tag: 'CANDIDATE',
              );
            }

            AppLogger.database(
              '   🔍 FULL JSON KEYS: ${jsonData.keys.toList()}',
              tag: 'CANDIDATE',
            );

            profileImageUrl = candidate.photo;

            // Resolve the proper party key for symbol display
            final partyValue = candidate.party ?? '';
            String resolvedParty;

            // Check if party is already a key (short, starts with lowercase letter, no spaces)
            if (partyValue.length <= 20 &&
                partyValue.isNotEmpty &&
                RegExp(r'^[a-z]').hasMatch(partyValue) &&
                !partyValue.contains(' ') &&
                !partyValue.contains('Nationalist') &&
                !partyValue.contains('Congress') &&
                !partyValue.contains('Party')) {
              resolvedParty = partyValue;
            } else {
              // Convert old full names to keys
              resolvedParty =
                  SymbolUtils.convertOldPartyNameToKey(partyValue) ??
                  partyValue;
            }
            candidateParty = resolvedParty;
            candidateName = candidate.name;

            // Debug logging for party symbol resolution
            AppLogger.database(
              '🎯 [HighlightBanner] Loaded candidate party: $resolvedParty (from: ${candidate.party}) for candidate: $candidateName',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '   Raw candidate.party: ${candidate.party}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '   candidate.toJson()["party"]: ${candidate.toJson()["party"]}',
              tag: 'CANDIDATE',
            );

            // Debug logging
            AppLogger.database(
              'Candidate data loaded successfully:',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '  candidateId: ${currentBanner.candidateId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database('  name: ${candidate.name}', tag: 'CANDIDATE');
            AppLogger.database(
              '  photo URL: $profileImageUrl',
              tag: 'CANDIDATE',
            );
            AppLogger.database('  party: $candidateParty', tag: 'CANDIDATE');
            AppLogger.database(
              '  candidate.party directly: ${candidate.party}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '  candidate.toJson()["party"]: ${candidate.toJson()["party"]}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '  Raw candidate object: ${candidate.toJson()}',
              tag: 'CANDIDATE',
            );
          } else {
            // Candidate not found - skip this banner and try to clean it up
            AppLogger.database(
              '⛔ 💾❌ [CANDIDATE] Candidate not found for ID: ${currentBanner.candidateId}',
              tag: 'CANDIDATE',
            );
            AppLogger.database(
              '  This means getCandidateDataById returned null - skipping banner',
              tag: 'CANDIDATE',
            );

            // Attempt to deactivate the highlight since candidate doesn't exist
            try {
              await HighlightService.updateHighlightStatus(
                currentBanner.id,
                false, // Set to inactive
                districtId: widget.districtId,
                bodyId: widget.bodyId,
                wardId: widget.wardId,
              );
              AppLogger.database(
                '  ✅ Deactivated highlight ${currentBanner.id} due to missing candidate',
                tag: 'CANDIDATE',
              );
            } catch (deactivateError) {
              AppLogger.databaseError(
                '  ❌ Failed to deactivate highlight ${currentBanner.id}',
                tag: 'CANDIDATE',
                error: deactivateError,
              );
            }

            // Set banner to null so it won't be displayed
            if (mounted) {
              setState(() {
                platinumBanners = [];
                isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          AppLogger.databaseError(
            'Error fetching candidate data',
            tag: 'CANDIDATE',
            error: e,
          );
          // On error, also skip the banner
          if (mounted) {
            setState(() {
              platinumBanners = [];
              isLoading = false;
            });
          }
          return;
        }
      }

      // Extract enhanced configuration from banner data
      String? bannerStyleConfig;
      String? callToActionConfig;
      String? customMessageConfig;
      String? priorityLevelConfig;

      if (currentBanner != null) {
        // Get the full document data to access enhanced fields using hierarchical structure
        final snapshot = await FirebaseFirestore.instance
            .collection('states')
            .doc('maharashtra')
            .collection('districts')
            .doc(widget.districtId)
            .collection('bodies')
            .doc(widget.bodyId)
            .collection('wards')
            .doc(widget.wardId)
            .collection('highlights')
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
          candidateProfileImageUrl = profileImageUrl;
          candidateParty =
              candidateParty ?? 'independent'; // Ensure fallback to independent
          candidateName =
              candidateName ?? 'Unknown Candidate'; // Ensure fallback name
          bannerStyle = bannerStyleConfig;
          callToAction = callToActionConfig;
          customMessage = customMessageConfig;
          priorityLevel = priorityLevelConfig;
          isLoading = false;
        });

        // Debug logging for final state
        AppLogger.database(
          '🎯 [HighlightBanner] Final banner state set:',
          tag: 'CANDIDATE',
        );
        AppLogger.database(
          '   candidateName: $candidateName',
          tag: 'CANDIDATE',
        );
        AppLogger.database(
          '   candidateParty: $candidateParty',
          tag: 'CANDIDATE',
        );
        AppLogger.database(
          '   profileImageUrl: $candidateProfileImageUrl',
          tag: 'CANDIDATE',
        );

        // Animation removed - no longer needed
      }
    } catch (e) {
      AppLogger.databaseError(
        'Error loading platinum banner',
        tag: 'CANDIDATE',
        error: e,
      );
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onBannerTap() async {
    if (platinumBanners.isEmpty) return;

    final currentBanner = platinumBanners[currentBannerIndex];

    // Track click
    await HighlightService.trackClick(
      currentBanner.id,
      districtId: widget.districtId,
      bodyId: widget.bodyId,
      wardId: widget.wardId,
    );

    // Track view analytics
    await _trackBannerView();

    // Navigate to candidate profile
    try {
      // Use candidate repository to fetch candidate data (handles hierarchical structure)
      final candidateRepository = CandidateRepository();
      final candidate = await candidateRepository.getCandidateDataById(currentBanner.candidateId);

      if (candidate != null && mounted) {
        // Navigate to candidate profile screen
        Get.to(() => const CandidateProfileScreen(), arguments: candidate);
      } else {
        AppLogger.databaseError('Candidate not found for navigation: ${currentBanner.candidateId}', tag: 'CANDIDATE');
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
      AppLogger.databaseError('Error navigating to candidate profile', tag: 'CANDIDATE', error: e);
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
      if (userId == null || platinumBanners.isEmpty) return;

      final currentBanner = platinumBanners[currentBannerIndex];
      await FirebaseFirestore.instance.collection('section_views').add({
        'sectionType': 'banner',
        'contentId': currentBanner.id,
        'userId': userId,
        'candidateId': currentBanner.candidateId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': {'platform': 'mobile', 'appVersion': '1.0.0'},
        'location': {
          'districtId': widget.districtId,
          'bodyId': widget.bodyId,
          'wardId': widget.wardId,
        },
      });
    } catch (e) {
      AppLogger.databaseError(
        'Error tracking banner view',
        tag: 'CANDIDATE',
        error: e,
      );
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

    if (platinumBanners.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use Option 1 design (Single Symbol + Candidate Info) with rotation
    return _buildOption1Design(context);
  }

  // Option 1: Single Symbol + Candidate Info design with rotation
  Widget _buildOption1Design(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentBanner = platinumBanners[currentBannerIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: GestureDetector(
        onTap: _onBannerTap, // Make entire banner clickable
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
              // Main content (image only - info section removed to reduce height)
              // Image section (without overlapping symbol)
              SizedBox(
                width: double.infinity,
                height: 180, // Reduced height for more compact design
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    12,
                  ), // Full rounded corners since no info section
                  child: _buildCandidateImage(),
                ),
              ),

              // Floating party symbol (upper left)
              Positioned(
                top: 12, // Position from top
                left: 12, // Position from left
                child: Container(
                  width: 55, // Same size as before
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
                    child: Image.asset(
                      () {
                        final partyToUse = candidateParty ?? 'independent';
                        final partyPath = SymbolUtils.getPartySymbolPath(
                          partyToUse,
                        );
                        AppLogger.common(
                          '🎯 [HighlightBanner] Floating party symbol for candidate: $candidateName, party: $partyToUse, path: $partyPath',
                        );
                        return partyPath;
                      }(),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.star, size: 25, color: Colors.grey);
                      },
                    ),
                  ),
                ),
              ),

              // Floating arrow button (right side) - now just visual, whole banner is clickable
              Positioned(
                top: 12, // Position from top
                right: 12, // Position from right
                child: Container(
                  width: 40, // Smaller floating button
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
                    size: 20, // Smaller icon
                  ),
                ),
              ),

              // Rotation indicator (only show if multiple banners)
              if (platinumBanners.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      platinumBanners.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == currentBannerIndex
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
  Widget _buildCandidateImage() {
    final currentBanner = platinumBanners[currentBannerIndex];
    return candidateProfileImageUrl != null
        ? Image.network(
            candidateProfileImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (currentBanner.imageUrl != null) {
                return Image.network(
                  currentBanner.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderImage();
                  },
                );
              } else {
                return _buildPlaceholderImage();
              }
            },
          )
        : currentBanner.imageUrl != null
            ? Image.network(
                currentBanner.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
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

  // Helper method to build party symbol circle
  Widget _buildPartySymbolCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          () {
            final partyToUse = candidateParty ?? 'independent';
            final partyPath = SymbolUtils.getPartySymbolPath(partyToUse);
            AppLogger.common(
              '🎯 [HighlightBanner] Party symbol for candidate: $candidateName, party: $partyToUse, path: $partyPath',
            );
            return partyPath;
          }(),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.star, size: size * 0.5, color: Colors.grey);
          },
        ),
      ),
    );
  }

  // Helper method to build action button
  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _onBannerTap,
      style:
          ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            shadowColor: Colors.black.withValues(alpha: 0.2),
            elevation: 4,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.blue.shade800;
              }
              if (states.contains(WidgetState.hovered)) {
                return Colors.blue.shade700;
              }
              return null;
            }),
          ),
      child: const Text(
        'अधिक पहा',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Noto Sans Devanagari',
        ),
      ),
    );
  }

  /// Helper method to fetch highlight banners (returns list for rotation)
  Future<List<highlight_model.Highlight>> _fetchHighlightBanners() async {
    final banners = await HighlightRepository.getHighlightBanners(
      stateId: 'maharashtra', // TODO: Make dynamic based on user location
      districtId: widget.districtId,
      bodyId: widget.bodyId,
      wardId: widget.wardId,
    );
    return banners.map((banner) => highlight_model.Highlight(
      id: banner.id,
      candidateId: banner.candidateId,
      wardId: banner.wardId,
      districtId: banner.districtId,
      bodyId: banner.bodyId,
      locationKey: banner.locationKey,
      package: banner.package,
      placement: banner.placement,
      priority: banner.priority,
      startDate: banner.startDate,
      endDate: banner.endDate,
      active: banner.active,
      exclusive: banner.exclusive,
      rotation: banner.rotation,
      lastShown: banner.lastShown,
      views: banner.views,
      clicks: banner.clicks,
      imageUrl: banner.imageUrl,
      candidateName: banner.candidateName,
      party: banner.party,
      createdAt: banner.createdAt,
    )).toList();
  }

  /// Helper method to fetch candidate data with retry logic
  Future<candidate_model.Candidate?> _fetchCandidateDataWithRetry(
    String candidateId,
  ) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final candidateRepository = CandidateRepository();
        return await candidateRepository.getCandidateDataById(candidateId);
      } catch (e) {
        AppLogger.databaseError(
          'Candidate data fetch attempt $attempt failed for ID: $candidateId',
          tag: 'CANDIDATE',
          error: e,
        );

        if (attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff
        final delay = baseDelay * (1 << (attempt - 1)); // 1s, 2s, 4s
        AppLogger.database(
          'Retrying candidate data fetch in ${delay.inSeconds}s...',
          tag: 'CANDIDATE',
        );
        await Future.delayed(delay);
      }
    }

    throw Exception(
      'Failed to fetch candidate data after $maxRetries attempts',
    );
  }
}
