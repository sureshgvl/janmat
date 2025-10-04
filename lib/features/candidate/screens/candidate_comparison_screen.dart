import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import '../models/candidate_model.dart';

class CandidateComparisonScreen extends StatelessWidget {
  final Candidate candidate1;
  final Candidate candidate2;

  const CandidateComparisonScreen({
    super.key,
    required this.candidate1,
    required this.candidate2,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.candidateComparison),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Comparing ${candidate1.name} vs ${candidate2.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comparison Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Metric',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            candidate1.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            candidate2.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Photo Row
                  _buildComparisonRow(
                    'Photo',
                    _buildPhotoWidget(candidate1),
                    _buildPhotoWidget(candidate2),
                  ),

                  // Name Row
                  _buildComparisonRow(
                    'Name',
                    Text(
                      candidate1.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Party Row
                  _buildComparisonRow(
                    'Party',
                    Text(
                      candidate1.party,
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.party,
                      style: TextStyle(color: Colors.grey.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Age Row
                  _buildComparisonRow(
                    'Age',
                    Text(
                      candidate1.extraInfo?.basicInfo?.age?.toString() ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.extraInfo?.basicInfo?.age?.toString() ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Manifesto Points Row
                  _buildComparisonRow(
                    'Manifesto Points',
                    Text(
                      candidate1.extraInfo?.manifesto?.promises?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.extraInfo?.manifesto?.promises?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Achievements Row
                  _buildComparisonRow(
                    'Achievements',
                    Text(
                      candidate1.extraInfo?.achievements?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.extraInfo?.achievements?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Likes Row
                  _buildComparisonRow(
                    'Likes',
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate1.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('❤️'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate2.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('❤️'),
                      ],
                    ),
                  ),

                  // Events Attended Row
                  _buildComparisonRow(
                    'Events Attended',
                    Text(
                      candidate1.extraInfo?.events?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.extraInfo?.events?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed('/candidate-profile', arguments: candidate1);
                    },
                    icon: const Icon(Icons.person),
                    label: Text('View ${candidate1.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed('/candidate-profile', arguments: candidate2);
                    },
                    icon: const Icon(Icons.person),
                    label: Text('View ${candidate2.name}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String metric, Widget value1, Widget value2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: value1,
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: value2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(Candidate candidate) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipOval(
        child: candidate.photo != null && candidate.photo!.isNotEmpty
            ? Image.network(
                candidate.photo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      candidate.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  );
                },
              )
            : CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  candidate.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
      ),
    );
  }
}

