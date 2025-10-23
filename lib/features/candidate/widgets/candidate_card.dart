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

    // Get age from basic info
    final age = candidate.basicInfo?.age;
    final displayName = age != null ? '${candidate.name}, $age' : candidate.name;

    // Get education
    final education = candidate.basicInfo?.education;

    // Get achievements
    final achievements = candidate.achievements;

    // Determine if candidate is premium
    final isPremiumCandidate = candidate.sponsored || candidate.followersCount > 1000;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.toNamed('/candidate-profile', arguments: candidate);
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white,
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: isPremiumCandidate
                    ? Colors.amber.withValues(alpha: 0.3)
                    : AppColors.borderLight,
                width: isPremiumCandidate ? 1.5 : 1.0,
              ),
              boxShadow: [
                AppShadows.light,
                if (isPremiumCandidate) AppShadows.medium,
              ],
            ),
            child: Row(
              children: [
                // Candidate Photo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: isPremiumCandidate
                          ? Colors.amber.withValues(alpha: 0.6)
                          : AppColors.borderLight,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      image: candidate.photo != null && candidate.photo!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(candidate.photo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: candidate.photo == null || candidate.photo!.isEmpty
                          ? (isPremiumCandidate
                              ? Colors.amber.shade100
                              : Colors.grey.shade200)
                          : null,
                    ),
                    child: candidate.photo == null || candidate.photo!.isEmpty
                        ? Center(
                            child: Text(
                              candidate.name[0].toUpperCase(),
                              style: AppTypography.labelLarge.copyWith(
                                color: isPremiumCandidate
                                    ? Colors.amber.shade800
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          )
                        : null,
                  ),
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
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                ),
                                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: Text(
                                'YOU',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Education and Party row
                      Row(
                        children: [
                          // Party Symbol and Name
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
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
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    SymbolUtils.getPartyDisplayNameWithLocale(
                                      candidate.party,
                                      Localizations.localeOf(context).languageCode,
                                    ),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: AppSpacing.sm),
                          // Education
                          if (education != null && education.isNotEmpty)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 14,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        education,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.info,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Achievements row
                      if (achievements != null && achievements.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${achievements.length} Achievement${achievements.length > 1 ? 's' : ''}',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Follow Button or Current User Indicator
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'YOU',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.info.withValues(alpha: 0.2), AppColors.info.withValues(alpha: 0.1)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                  await controller.followCandidate(
                                    userId,
                                    candidate.candidateId,
                                    stateId: candidate.location.stateId,
                                    districtId: candidate.location.districtId,
                                    bodyId: candidate.location.bodyId,
                                    wardId: candidate.location.wardId,
                                  );
                                  onFollowChanged?.call();
                                },
                          icon: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                                  ),
                                )
                              : Icon(
                                  Icons.person_add,
                                  size: 22,
                                  color: AppColors.info,
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

