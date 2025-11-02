import 'package:flutter/material.dart';
import '../highlight/services/highlight_service.dart';

class AllocatedSeatsDisplay extends StatefulWidget {
  final int maxHighlights;
  final String? stateId;
  final String? districtId;
  final String? bodyId;
  final String? wardId;

  const AllocatedSeatsDisplay({
    required this.maxHighlights,
    this.stateId,
    this.districtId,
    this.bodyId,
    this.wardId,
    super.key,
  });

  @override
  State<AllocatedSeatsDisplay> createState() => _AllocatedSeatsDisplayState();
}

class _AllocatedSeatsDisplayState extends State<AllocatedSeatsDisplay> {
  int allocatedSeats = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllocatedSeats();
  }

  @override
  void didUpdateWidget(AllocatedSeatsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if location parameters changed
    if (oldWidget.stateId != widget.stateId ||
        oldWidget.districtId != widget.districtId ||
        oldWidget.bodyId != widget.bodyId ||
        oldWidget.wardId != widget.wardId) {
      _loadAllocatedSeats();
    }
  }

  Future<void> _loadAllocatedSeats() async {
    if (widget.stateId == null || widget.districtId == null ||
        widget.bodyId == null || widget.wardId == null) {
      setState(() {
        allocatedSeats = 0;
        isLoading = false;
      });
      return;
    }

    try {
      setState(() => isLoading = true);

      // First, cleanup expired highlights in this ward (on-demand cleanup)
      final cleanedCount = await HighlightService.cleanupExpiredHighlights(
        stateId: widget.stateId!,
        districtId: widget.districtId!,
        bodyId: widget.bodyId!,
        wardId: widget.wardId!,
      );

      if (cleanedCount > 0) {
        // Log cleanup activity (using debug print for now, can be replaced with proper logging)
        debugPrint('🧹 AllocatedSeatsDisplay: Cleaned up $cleanedCount expired highlights in ward ${widget.districtId}/${widget.bodyId}/${widget.wardId}');
      }

      // Then get all active highlights in the ward
      final highlights = await HighlightService.getActiveHighlights(
        widget.stateId!,
        widget.districtId!,
        widget.bodyId!,
        widget.wardId!,
      );

      setState(() {
        allocatedSeats = highlights.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        allocatedSeats = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber[200]!, width: 1.5),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading allocated seats...'),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Allocated Seats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$allocatedSeats/${widget.maxHighlights}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: allocatedSeats == widget.maxHighlights ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              widget.maxHighlights,
              (index) => Container(
                margin: const EdgeInsets.only(right: 4),
                child: Icon(
                  index < allocatedSeats ? Icons.event_seat : Icons.event_seat_outlined,
                  color: index < allocatedSeats ? Colors.green[600] : Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
