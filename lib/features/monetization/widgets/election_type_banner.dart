import 'package:flutter/material.dart';

class ElectionTypeBanner extends StatelessWidget {
  final String electionType;
  final String Function(String) formatElectionType;

  const ElectionTypeBanner({
    super.key,
    required this.electionType,
    required this.formatElectionType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.how_to_vote, color: Colors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing plans for: ${formatElectionType(electionType)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

