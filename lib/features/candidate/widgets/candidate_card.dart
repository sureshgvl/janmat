import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../../../utils/symbol_utils.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool showCurrentUserIndicator;
  final String? currentUserId;
  final VoidCallback? onFollowChanged;

  const CandidateCard({
    super.key,
    required this.candidate,
    this.showCurrentUserIndicator = false,
    this.currentUserId,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = showCurrentUserIndicator && candidate.userId == currentUserId;

    // Get age from extra info
    final age = candidate.extraInfo?.basicInfo?.age;
    final displayName = age != null ? '${candidate.name}, $age' : candidate.name;

    // Get education
    final education = candidate.extraInfo?.basicInfo?.education;

    // Get achievements
    final achievements = candidate.extraInfo?.achievements;

    // Determine if candidate is premium
    final isPremiumCandidate = candidate.sponsored || candidate.followersCount > 1000;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed('/candidate-profile', arguments: candidate);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Candidate Photo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: candidate.photo != null && candidate.photo!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(candidate.photo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: candidate.photo == null || candidate.photo!.isEmpty
                        ? (isPremiumCandidate
                            ? Colors.blue.shade600
                            : Colors.grey.shade400)
                        : null,
                  ),
                  child: candidate.photo == null || candidate.photo!.isEmpty
                      ? Center(
                          child: Text(
                            candidate.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Candidate Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with Age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1f2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Education and Party row
                      Row(
                        children: [
                          // Party Symbol and Name
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: SymbolUtils.getSymbolImageProvider(
                                        SymbolUtils.getPartySymbolPath(
                                          candidate.party,
                                          candidate: candidate,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    SymbolUtils.getPartyDisplayNameWithLocale(
                                      candidate.party,
                                      Localizations.localeOf(context).languageCode,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.6)
                                          : const Color(0xFF6b7280),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),
                          // Education
                          if (education != null && education.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 16,
                                    color: const Color(0xFF1173d4),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      education,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.6)
                                            : const Color(0xFF6b7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Achievements and Premium badge row
                      Row(
                        children: [
                          // Achievements
                          if (achievements != null && achievements.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 16,
                                  color: Colors.amber.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${achievements.length} Achievement${achievements.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.6)
                                        : const Color(0xFF6b7280),
                                  ),
                                ),
                              ],
                            ),

                          const Spacer(),

                          // Premium/Free Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPremiumCandidate
                                  ? Colors.amber.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              isPremiumCandidate ? 'Premium' : 'Free',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPremiumCandidate
                                    ? Colors.amber.shade600
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Follow Button or Current User Indicator
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  GetBuilder<CandidateController>(
                    builder: (controller) {
                      final isFollowing = controller.followStatus[candidate.candidateId] ?? false;
                      final isLoading = controller.followLoading[candidate.candidateId] ?? false;

                      // Hide follow button if already following
                      if (isFollowing) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1173d4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                  await controller.followCandidate(
                                    userId,
                                    candidate.candidateId,
                                    stateId: candidate.stateId,
                                    districtId: candidate.districtId,
                                    bodyId: candidate.bodyId,
                                    wardId: candidate.wardId,
                                  );
                                  onFollowChanged?.call();
                                },
                          icon: Icon(
                            Icons.person_add,
                            size: 20,
                            color: const Color(0xFF1173d4),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}