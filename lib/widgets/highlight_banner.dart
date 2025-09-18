import 'package:flutter/material.dart';
import '../services/highlight_service.dart';

class HighlightBanner extends StatefulWidget {
  final String districtId;
  final String bodyId;
  final String wardId;

  const HighlightBanner({
    Key? key,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  }) : super(key: key);

  @override
  _HighlightBannerState createState() => _HighlightBannerState();
}

class _HighlightBannerState extends State<HighlightBanner> {
  Highlight? platinumBanner;
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
    if (widget.districtId.isEmpty || widget.bodyId.isEmpty || widget.wardId.isEmpty) {
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
      if (mounted) {
        setState(() {
          platinumBanner = banner;
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

    // Navigate to candidate profile
    print('Navigate to candidate: ${platinumBanner!.candidateId}');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (platinumBanner == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth * 0.4; // 40% of screen width for height

    return GestureDetector(
      onTap: _onBannerTap,
      child: Container(
        width: double.infinity,
        height: bannerHeight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                      color: Colors.purple.shade100,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.purple,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.purple.shade100,
                  child: const Icon(
                    Icons.star,
                    size: 48,
                    color: Colors.purple,
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
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // Platinum Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple,
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
                      Icon(
                        Icons.diamond,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PLATINUM',
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

              // Sponsored Badge
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.black,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SPONSORED',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    // Candidate Photo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundImage: platinumBanner!.imageUrl != null
                            ? NetworkImage(platinumBanner!.imageUrl!)
                            : null,
                        backgroundColor: Colors.white,
                        child: platinumBanner!.imageUrl == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.purple,
                                size: 30,
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Candidate Info
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
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
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
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // CTA Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Impression tracking overlay (invisible)
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}