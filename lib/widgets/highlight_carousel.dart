import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/highlight_service.dart';
import 'highlight_card.dart';

class HighlightCarousel extends StatefulWidget {
  final String districtId;
  final String bodyId;
  final String wardId;

  const HighlightCarousel({
    super.key,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  @override
  _HighlightCarouselState createState() => _HighlightCarouselState();
}

class _HighlightCarouselState extends State<HighlightCarousel> {
  List<Highlight> highlights = [];
  bool isLoading = true;
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _loadHighlights();
  }

  @override
  void didUpdateWidget(HighlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wardId != widget.wardId) {
      _loadHighlights();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHighlights() async {
    if (widget.wardId.isEmpty ||
        widget.districtId.isEmpty ||
        widget.bodyId.isEmpty)
      return;

    setState(() => isLoading = true);

    try {
      final loadedHighlights = await HighlightService.getActiveHighlights(
        widget.districtId,
        widget.bodyId,
        widget.wardId,
      );
      if (mounted) {
        setState(() {
          highlights = loadedHighlights;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading highlights: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onHighlightTap(Highlight highlight) async {
    // Track click
    await HighlightService.trackClick(highlight.id);

    // Navigate to candidate profile
    // You'll need to implement this navigation based on your app's routing
    print('Navigate to candidate: ${highlight.candidateId}');
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Track impression for the new visible highlight
    if (highlights.isNotEmpty && index < highlights.length) {
      HighlightService.trackImpression(highlights[index].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: [
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Highlight Candidates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),

        // Carousel using PageView with performance optimizations
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: highlights.length,
            onPageChanged: _onPageChanged,
            // Add physics to prevent overscroll issues
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween<double>(
                  begin: 1.0,
                  end: _currentIndex == index ? 1.0 : 0.8,
                ),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: HighlightCard(
                  highlight: highlight,
                  onTap: () => _onHighlightTap(highlight),
                ),
              );
            },
          ),
        ),

        // Dots indicator
        if (highlights.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              highlights.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? const Color(0xFF1976d2) // Primary blue
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}
