import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/app_theme.dart';
import '../../../utils/theme_constants.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/search_controller.dart' as search;
import '../controllers/location_controller.dart';
import '../controllers/pagination_controller.dart';
import '../widgets/candidate_card.dart';

class CandidateListView extends StatelessWidget {
  final CandidateController candidateController;
  final search.SearchController searchController;
  final LocationController locationController;
  final PaginationController paginationController;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;

  const CandidateListView({
    super.key,
    required this.candidateController,
    required this.searchController,
    required this.locationController,
    required this.paginationController,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine which candidates to show
      final candidatesToShow = _getCandidatesToShow();

      // Loading state
      if (candidateController.isLoading) {
        return _buildLoadingState();
      }

      // Error state
      if (candidateController.errorMessage != null) {
        return _buildErrorState(context);
      }

      // Empty state - no ward selected
      if (locationController.selectedWard.value == null) {
        return _buildNoWardSelectedState(context);
      }

      // Empty state - no candidates found
      if (candidatesToShow.isEmpty) {
        return _buildNoCandidatesFoundState(context);
      }

      // Candidates list
      return _buildCandidatesList(context, candidatesToShow);
    });
  }

  List<Candidate> _getCandidatesToShow() {
    // Priority: Search results > All candidates
    if (searchController.hasActiveSearch && searchController.hasResults) {
      return searchController.currentResults;
    }
    return candidateController.candidates;
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            candidateController.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRefresh,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWardSelectedState(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Text(
        CandidateLocalizations.of(context)!.selectWardToViewCandidates,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildNoCandidatesFoundState(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            CandidateLocalizations.of(context)!.noCandidatesFound,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ward: ${locationController.selectedWard.value?.name ?? 'Unknown'}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatesList(BuildContext context, List<Candidate> candidates) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.homeBackgroundColor.withValues(alpha: 0.3), // Semi-transparent theme background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      child: Column(
        children: [
          // Pull to refresh indicator
          Obx(() => paginationController.showRefreshIndicator.value
              ? _buildPullToRefreshIndicator()
              : const SizedBox.shrink()),

          // Candidates list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: candidates.length + (paginationController.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator at the end
              if (index == candidates.length) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                );
              }

              final candidate = candidates[index];
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: CandidateCard(candidate: candidate),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPullToRefreshIndicator() {
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Pull down to refresh',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
