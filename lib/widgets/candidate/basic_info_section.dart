import 'package:flutter/material.dart';
import '../../models/candidate_model.dart';
import '../../utils/symbol_utils.dart';

class BasicInfoSection extends StatelessWidget {
  final Candidate candidateData;
  final String Function(String) getPartySymbolPath;

  const BasicInfoSection({
    super.key,
    required this.candidateData,
    required this.getPartySymbolPath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: candidateData.photo != null
                      ? NetworkImage(candidateData.photo!)
                      : null,
                  child: candidateData.photo == null
                      ? Text(
                          candidateData.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidateData.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (candidateData.party.toLowerCase().contains('independent') || candidateData.party.trim().isEmpty)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(
                                Icons.label,
                                size: 30,
                                color: Colors.grey,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: SymbolUtils.getSymbolImageProvider(
                                    SymbolUtils.getPartySymbolPath(candidateData.party, candidate: candidateData)
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidateData.party.toLowerCase().contains('independent') || candidateData.party.trim().isEmpty
                                      ? 'Independent Candidate'
                                      : candidateData.party,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: candidateData.party.toLowerCase().contains('independent') || candidateData.party.trim().isEmpty
                                        ? Colors.grey.shade700
                                        : Colors.blue,
                                    fontWeight: candidateData.party.toLowerCase().contains('independent') || candidateData.party.trim().isEmpty
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (candidateData.symbol != null && candidateData.symbol!.isNotEmpty)
                                  Text(
                                    'Symbol: ${candidateData.symbol}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                //city
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'City',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        candidateData.cityId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                //ward
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ward',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        candidateData.wardId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}