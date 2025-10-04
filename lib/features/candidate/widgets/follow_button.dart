import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_controller.dart';
import 'notification_settings_dialog.dart';

class FollowButton extends StatelessWidget {
  final String candidateId;
  final String userId;
  final String? stateId;
  final String? districtId;
  final String? bodyId;
  final String? wardId;
  final bool showFollowersCount;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.candidateId,
    required this.userId,
    this.stateId,
    this.districtId,
    this.bodyId,
    this.wardId,
    this.showFollowersCount = true,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CandidateController>();

    return GetBuilder<CandidateController>(
      builder: (controller) {
        final isFollowing = controller.followStatus[candidateId] ?? false;
        final isLoading = controller.followLoading[candidateId] ?? false;

        // Find candidate to get followers count
        final candidate = controller.candidates.firstWhereOrNull(
          (c) => c.candidateId == candidateId,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showFollowersCount && candidate != null)
              Text(
                '${candidate.followersCount} followers',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!isFollowing) {
                        // Show notification settings dialog when following
                        showDialog(
                          context: context,
                          builder: (context) => NotificationSettingsDialog(
                            candidateId: candidateId,
                            candidateName: candidate?.name ?? 'Candidate',
                            userId: userId,
                            currentNotificationsEnabled: true,
                          ),
                        ).then((_) {
                          // After dialog closes, perform the follow action
                          controller.followCandidate(
                            userId,
                            candidateId,
                            notificationsEnabled: true,
                            stateId: stateId,
                            districtId: districtId,
                            bodyId: bodyId,
                            wardId: wardId,
                          );
                          onFollowChanged?.call();
                        });
                      } else {
                        await controller.toggleFollow(userId, candidateId);
                        onFollowChanged?.call();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.grey[300]
                    : Theme.of(context).primaryColor,
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: isFollowing ? 0 : 2,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

