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
    _pageController = PageController(viewportFraction: 0.85);
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
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Featured Candidates',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${highlights.length} candidates',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),

        // Carousel using PageView
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: highlights.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 200,
                      width: Curves.easeOut.transform(value) * 280,
                      child: child,
                    ),
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
          const SizedBox(height: 12),
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
                      ? Theme.of(context).primaryColor
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
