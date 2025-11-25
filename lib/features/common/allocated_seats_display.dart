import 'dart:async';
import 'package:flutter/material.dart';
import '../highlight/services/highlight_service.dart';
import '../highlight/models/highlight_model.dart';

class AllocatedSeatsDisplay extends StatefulWidget {
  final int maxHighlights;
  final String? stateId;
  final String? districtId;
  final String? bodyId;
  final String? wardId;
  final Function(List<Highlight>)? onHighlightsLoaded;

  const AllocatedSeatsDisplay({
    required this.maxHighlights,
    this.stateId,
    this.districtId,
    this.bodyId,
    this.wardId,
    this.onHighlightsLoaded,
    super.key,
  });

  @override
  State<AllocatedSeatsDisplay> createState() => _AllocatedSeatsDisplayState();
}

class _AllocatedSeatsDisplayState extends State<AllocatedSeatsDisplay> {
  List<Highlight> allocatedHighlights = [];
  bool isLoading = true;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadAllocatedSeats();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
        allocatedHighlights = [];
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
        allocatedHighlights = highlights;
        isLoading = false;
        _manageCountdownTimer();
      });

      // Notify parent widget about loaded highlights
      widget.onHighlightsLoaded?.call(highlights);
    } catch (e) {
      setState(() {
        allocatedHighlights = [];
        isLoading = false;
        _manageCountdownTimer();
      });
    }
  }

  void _manageCountdownTimer() {
    // Check if any highlight has less than 24 hours remaining
    final hasCountdownHighlights = allocatedHighlights.any((highlight) {
      final difference = highlight.endDate.difference(DateTime.now());
      return !difference.isNegative && difference.inHours < 24;
    });

    if (hasCountdownHighlights && _countdownTimer == null) {
      // Start countdown timer
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            // Force rebuild to update countdown
          });
        }
      });
    } else if (!hasCountdownHighlights && _countdownTimer != null) {
      // Stop countdown timer
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  String _formatRemainingTime(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    if (days > 1) {
      return '$days days';
    } else if (days == 1) {
      return '1 day';
    } else {
      // Less than 1 day, show hours, minutes, seconds with labels (singular/plural)
      final hourLabel = hours == 1 ? 'hr' : 'hrs';
      final minuteLabel = minutes == 1 ? 'min' : 'mins';
      final secondLabel = seconds == 1 ? 'sec' : 'secs';
      return '${hours.toString().padLeft(2, '0')} $hourLabel, ${minutes.toString().padLeft(2, '0')} $minuteLabel, ${seconds.toString().padLeft(2, '0')} $secondLabel';
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
                '${allocatedHighlights.length}/${widget.maxHighlights}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: allocatedHighlights.length == widget.maxHighlights ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Show all seats in one row (allocated filled, empty outlined)
          Row(
            children: List.generate(
              widget.maxHighlights,
              (index) => Container(
                margin: const EdgeInsets.only(right: 4),
                child: Icon(
                  index < allocatedHighlights.length ? Icons.event_seat : Icons.event_seat_outlined,
                  color: index < allocatedHighlights.length ? Colors.green[600] : Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
          ),
          // Display individual allocated seats with candidate names and remaining time below
          if (allocatedHighlights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: allocatedHighlights.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final highlight = entry.value;
                final remainingTime = _formatRemainingTime(highlight.endDate);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$index. ${highlight.candidateName ?? 'Unknown'} - $remainingTime',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
