import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_user_controller.dart';
import '../controllers/candidate_controller.dart';
import '../screens/followers_list_screen.dart';
import '../screens/following_list_screen.dart';

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
                                  stateId: candidate.location.stateId,
                                  districtId: candidate.location.districtId,
                                  bodyId: candidate.location.bodyId,
                                  wardId: candidate.location.wardId,
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
                    candidateName: candidate.basicInfo!.fullName!,
                    candidateData: candidate,
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
              onTap: () {
                Get.to(
                  () => FollowingListScreen(
                    candidateId: candidate.candidateId,
                    candidateName: candidate.basicInfo!.fullName!,
                    candidateData: candidate,
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
