import 'package:flutter/material.dart';

class AllocatedSeatsDisplay extends StatelessWidget {
  final int maxHighlights;
  final int allocatedSeats;

  const AllocatedSeatsDisplay({
    required this.maxHighlights,
    required this.allocatedSeats,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                '$allocatedSeats/$maxHighlights',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: allocatedSeats == maxHighlights ? Colors.green : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              maxHighlights,
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
