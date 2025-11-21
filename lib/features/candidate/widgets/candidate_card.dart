import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/theme_constants.dart';

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

    // Get data - use optimistically updated count if following
    final age = candidate.basicInfo?.age;
    final education = candidate.basicInfo?.education;
    final achievements = candidate.achievements;

    // OPTIMISTIC FOLLOWER COUNT: Show 1+ if following (handles server delay)
    int followersCount = candidate.followersCount;
    bool isFollowingOptimistically = false;

    // Check if we're optimistically following (controller says yes but server not updated)
    final controller = Get.find<CandidateController>();
    isFollowingOptimistically = controller.followStatus[candidate.candidateId] == true && followersCount == 0;

    if (isFollowingOptimistically) {
      followersCount = 1; // Show at least 1 follower when following
    }
    final isPremiumCandidate = candidate.sponsored || followersCount > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            debugPrint('🔄 CANDIDATE_CARD_NAVIGATION: Navigating to profile for ${candidate.candidateId}');
            Get.toNamed('/candidate-profile', arguments: candidate);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              border: Border.all(
                color: isPremiumCandidate
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: Profile Photo + Follow Button Column
                Column(
                  children: [
                    // Profile Photo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPremiumCandidate
                              ? Colors.amber.withValues(alpha: 0.5)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: candidate.basicInfo!.photo != null && candidate.basicInfo!.photo!.isNotEmpty
                            ? Image.network(
                                candidate.basicInfo!.photo!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: isPremiumCandidate
                                    ? Colors.amber.shade100
                                    : Colors.grey.shade200,
                                child: Center(
                                  child: Text(
                                    candidate.basicInfo!.fullName![0].toUpperCase(),
                                    style: AppTypography.labelLarge.copyWith(
                                      color: isPremiumCandidate
                                          ? Colors.amber.shade800
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),



                    // "YOU" Indicator for current user
                    if (isCurrentUser)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            'YOU',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // RIGHT: Text Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Name (Large, Bold)
                      Text(
                        candidate.basicInfo!.fullName!,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Party + Age Row
                      Row(
                        children: [
                          // Party Symbol
                          Container(
                            width: 22,
                            height: 22,
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
                          // Party Name + Age
                          Expanded(
                            child: Text(
                              '${SymbolUtils.getPartyDisplayNameWithLocale(
                                candidate.party,
                                Localizations.localeOf(context).languageCode,
                              )} • ${age != null ? '$age years' : 'Age not specified'}',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Follow Button (right-aligned) - only show if not current user
                          if (!isCurrentUser)
                            GetBuilder<CandidateController>(
                              builder: (controller) {
                                final isFollowing = controller.followStatus[candidate.candidateId] ?? false;
                                final isLoading = controller.followLoading[candidate.candidateId] ?? false;
                                debugPrint('🎭 CANDIDATE_CARD_FOLLOW_STATUS: ${candidate.candidateId} -> isFollowing=$isFollowing, isLoading=$isLoading, controller=${controller.hashCode}');

                                return Container(
                                  width: 32,
                                  height: 32,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        isFollowing ? Colors.grey.shade400 : AppColors.primary,
                                        isFollowing ? Colors.grey.shade600 : AppColors.secondary,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                            debugPrint('🔥 CANDIDATE_CARD_FOLLOW_CLICK: User $userId attempting to follow/unfollow ${candidate.candidateId}');
                                            await controller.followCandidate(
                                              userId,
                                              candidate.candidateId,
                                              stateId: candidate.location.stateId,
                                              districtId: candidate.location.districtId,
                                              bodyId: candidate.location.bodyId,
                                              wardId: candidate.location.wardId,
                                            );
                                            onFollowChanged?.call();
                                            debugPrint('✅ CANDIDATE_CARD_FOLLOW_COMPLETED: Follow operation finished for ${candidate.candidateId}');
                                          },
                                    icon: isLoading
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            isFollowing ? Icons.check : Icons.person_add,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Chips Row 1: Followers + Education
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(maxWidth: 120),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$followersCount',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (education != null && education.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 14,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      education,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.info,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Chips Row 2: Achievements
                      if (achievements != null && achievements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${achievements.length} achievement${achievements.length > 1 ? 's' : ''}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
