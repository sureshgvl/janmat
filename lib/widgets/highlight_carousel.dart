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

  @override
  void initState() {
    super.initState();
    _loadHighlights();
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
      debugPrint('Error loading highlights: $e');
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

        // Horizontal scrolling carousel - matches HTML design
        SizedBox(
          height: 200, // Adjust height for horizontal cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return HighlightCard(
                highlight: highlight,
                onTap: () => _onHighlightTap(highlight),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

