import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/highlight_model.dart';
import '../features/home/controllers/highlight_carousel_controller.dart';
import '../features/home/models/highlight_carousel_model.dart';
import 'highlight_card.dart';

class HighlightCarouselSolid extends StatefulWidget {
  final String districtId;
  final String bodyId;
  final String wardId;

  const HighlightCarouselSolid({
    super.key,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  @override
  State<HighlightCarouselSolid> createState() => _HighlightCarouselSolidState();
}

class _HighlightCarouselSolidState extends State<HighlightCarouselSolid> {
  late final HighlightCarouselController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      HighlightCarouselController(),
      tag: '${widget.districtId}_${widget.bodyId}_${widget.wardId}_carousel',
    );
    _loadCarousel();
  }

  @override
  void didUpdateWidget(HighlightCarouselSolid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.districtId != widget.districtId ||
        oldWidget.bodyId != widget.bodyId ||
        oldWidget.wardId != widget.wardId) {
      _loadCarousel();
    }
  }

  void _loadCarousel() {
    _controller.loadCarouselItems(
      districtId: widget.districtId,
      bodyId: widget.bodyId,
      wardId: widget.wardId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = _controller.carouselState.value;

      if (state.isLoading) {
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

      if (!state.hasItems) {
        return const SizedBox.shrink();
      }

      return _buildCarousel(context, state);
    });
  }

  Widget _buildCarousel(BuildContext context, HighlightCarouselState state) {
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
          height: 200,
          child: PageView.builder(
            controller: _controller.pageController,
            scrollDirection: Axis.horizontal,
            itemCount: state.items.length,
            onPageChanged: _controller.onPageChanged,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HighlightCard(
                  highlight: _convertToHighlight(item),
                  onTap: () => _controller.onCarouselItemTap(item),
                  districtId: widget.districtId,
                  bodyId: widget.bodyId,
                  wardId: widget.wardId,
                ),
              );
            },
          ),
        ),

        // Page indicators
        if (state.shouldAutoScroll) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              state.items.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.currentPage == index
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

  // Convert HighlightCarouselItem to Highlight for compatibility with existing HighlightCard
  Highlight _convertToHighlight(HighlightCarouselItem item) {
    return Highlight(
      id: item.highlightId,
      candidateId: item.candidateId,
      wardId: widget.wardId,
      districtId: widget.districtId,
      bodyId: widget.bodyId,
      locationKey: '${widget.districtId}_${widget.bodyId}_${widget.wardId}',
      package: 'carousel',
      placement: ['carousel'],
      priority: item.priority,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 30)),
      active: true,
      exclusive: false,
      rotation: true,
      views: 0,
      clicks: 0,
      imageUrl: item.imageUrl,
      candidateName: item.candidateName,
      party: item.candidateParty,
      createdAt: item.createdAt,
    );
  }
}