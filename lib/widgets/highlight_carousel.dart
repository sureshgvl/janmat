import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/highlight_model.dart';
import '../controllers/highlight_controller.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(HighlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wardId != widget.wardId) {
      _loadHighlights();
    }
  }

  Future<void> _loadHighlights() async {
    if (widget.wardId.isEmpty ||
        widget.districtId.isEmpty ||
        widget.bodyId.isEmpty)
      return;

    setState(() => isLoading = true);

    try {
      final controller = Get.find<HighlightController>();
      await controller.loadHighlights(
        districtId: widget.districtId,
        bodyId: widget.bodyId,
        wardId: widget.wardId,
      );

      if (mounted) {
        setState(() {
          highlights = controller.highlights;
          isLoading = false;
        });
        _startAutoScroll();
      }
    } catch (e) {
      debugPrint('Error loading highlights: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (highlights.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;

      setState(() {
        _currentPage = (_currentPage + 1) % highlights.length;
      });

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onHighlightTap(Highlight highlight) async {
    // Track click
    final controller = Get.find<HighlightController>();
    await controller.trackClick(highlight.id);

    // Navigate to candidate profile
    // You'll need to implement this navigation based on your app's routing
    debugPrint('Navigate to candidate: ${highlight.candidateId}');
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

        // Auto-rotating PageView carousel
        SizedBox(
          height: 200, // Adjust height for horizontal cards
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HighlightCard(
                  highlight: highlight,
                  onTap: () => _onHighlightTap(highlight),
                ),
              );
            },
          ),
        ),

        // Page indicators
        if (highlights.length > 1) ...[
          const SizedBox(height: 8),
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
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
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

