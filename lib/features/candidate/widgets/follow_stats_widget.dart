import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_data_controller.dart';
import '../controllers/candidate_controller.dart';
import '../screens/followers_list_screen.dart';

class FollowStatsWidget extends StatelessWidget {
  final Candidate candidate;
  final String? currentUserId;
  final String Function(String) formatNumber;

  const FollowStatsWidget({
    super.key,
    required this.candidate,
    required this.currentUserId,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Follow/Following Button (hide if user.id == candidate.id)
          if (currentUserId != candidate.userId)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: GetBuilder<CandidateController>(
                  builder: (controller) {
                    final isFollowing = controller.followStatus[candidate.candidateId] ?? false;
                    final isLoading = controller.followLoading[candidate.candidateId] ?? false;

                    return ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                              if (!isFollowing) {
                                await controller.followCandidate(
                                  userId,
                                  candidate.candidateId,
                                  stateId: candidate.stateId,
                                  districtId: candidate.districtId,
                                  bodyId: candidate.bodyId,
                                  wardId: candidate.wardId,
                                );
                              } else {
                                await controller.toggleFollow(userId, candidate.candidateId);
                              }
                            },
                      icon: Icon(
                        isFollowing ? Icons.check : Icons.person_add,
                        size: 16,
                      ),
                      label: Text(isFollowing ? 'Following' : 'Follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Followers Count (Clickable)
          Expanded(
            child: InkWell(
              onTap: () {
                Get.to(
                  () => FollowersListScreen(
                    candidateId: candidate.candidateId,
                    candidateName: candidate.name,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      formatNumber(
                        candidate.followersCount.toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      CandidateTranslations.tr('followers'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Following Count (Clickable)
          Expanded(
            child: InkWell(
              onTap: () async {
                // Debug: Log all candidate data in system
                try {
                  final controller = Get.find<CandidateDataController>();
                  await controller.logAllCandidateData();

                  // Show detailed candidate info in a dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text(
                          'Candidate Data Audit',
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Current Candidate: ${candidate.name}',
                              ),
                              Text(
                                'Party: ${candidate.party}',
                              ),
                              Text(
                                'ID: ${candidate.candidateId}',
                              ),
                              Text(
                                'User ID: ${candidate.userId}',
                              ),
                              Text(
                                'District: ${candidate.districtId}',
                              ),
                              Text(
                                'Ward: ${candidate.wardId}',
                              ),
                              Text(
                                'Approved: ${candidate.approved}',
                              ),
                              Text(
                                'Status: ${candidate.status}',
                              ),
                              Text(
                                'Followers: ${candidate.followersCount}',
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '📊 System audit completed! Check console logs for full details.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } catch (e) {
                  Get.snackbar(
                    'Debug Error',
                    'Failed to log candidate data: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      formatNumber(
                        candidate.followingCount.toString(),
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      CandidateTranslations.tr('following'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}