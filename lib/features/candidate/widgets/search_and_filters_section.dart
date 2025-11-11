import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../core/app_theme.dart';
import '../../../utils/theme_constants.dart';
import '../controllers/location_controller.dart';
import '../controllers/search_controller.dart' as search;

class SearchAndFiltersSection extends StatelessWidget {
  final LocationController locationController;
  final search.SearchController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;

  const SearchAndFiltersSection({
    super.key,
    required this.locationController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.lg),
          bottomRight: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Obx(() => TextField(
              onChanged: (query) {
                searchController.search(query, []); // Will be updated with actual candidates
                onSearchChanged(query);
              },
              controller: TextEditingController(text: searchController.searchQuery.value),
              decoration: InputDecoration(
                hintText: CandidateLocalizations.of(context)!.searchCandidatesHint,
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: searchController.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          searchController.clearSearch();
                          onClearSearch();
                        },
                      )
                    : searchController.isSearchDebouncing.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              style: AppTypography.bodyMedium,
            )),
          ),

          // Location Selectors
          LocationSelectors(
            locationController: locationController,
            onDistrictTap: () => _showDistrictSelectionModal(context),
            onBodyTap: () => _showBodySelectionModal(context),
            onWardTap: () => _showWardSelectionModal(context),
          ),
        ],
      ),
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    // Implementation will be added when we create the modal widgets
    // For now, this is a placeholder
  }

  void _showBodySelectionModal(BuildContext context) {
    // Implementation will be added when we create the modal widgets
    // For now, this is a placeholder
  }

  void _showWardSelectionModal(BuildContext context) {
    // Implementation will be added when we create the modal widgets
    // For now, this is a placeholder
  }
}

class LocationSelectors extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback onDistrictTap;
  final VoidCallback onBodyTap;
  final VoidCallback onWardTap;

  const LocationSelectors({
    super.key,
    required this.locationController,
    required this.onDistrictTap,
    required this.onBodyTap,
    required this.onWardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // District Selection
        Obx(() => locationController.isLoadingDistricts.value
            ? Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : InkWell(
                onTap: onDistrictTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [AppShadows.light],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CandidateLocalizations.of(context)!.selectDistrict,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                              locationController.selectedDistrictId.value != null
                                  ? 'District ${locationController.selectedDistrictId.value}' // Placeholder
                                  : CandidateLocalizations.of(context)!.selectDistrict,
                              style: AppTypography.bodyMedium.copyWith(
                                color: locationController.selectedDistrictId.value != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: locationController.selectedDistrictId.value != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            )),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: AppSpacing.md),

        // Body Selection
        Obx(() {
          final hasDistrict = locationController.selectedDistrictId.value != null;
          final hasBodies = locationController.districtBodies.containsKey(locationController.selectedDistrictId.value) &&
                           (locationController.districtBodies[locationController.selectedDistrictId.value]?.isNotEmpty ?? false);

          if (!hasDistrict || !hasBodies) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      !hasDistrict
                          ? CandidateLocalizations.of(context)!.selectDistrictFirst
                          : CandidateLocalizations.of(context)!.noAreasAvailable,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return InkWell(
            onTap: onBodyTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [AppShadows.light],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CandidateLocalizations.of(context)!.selectArea,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                          locationController.selectedBodyId.value != null
                              ? 'Body ${locationController.selectedBodyId.value}' // Placeholder
                              : CandidateLocalizations.of(context)!.selectArea,
                          style: AppTypography.bodyMedium.copyWith(
                            color: locationController.selectedBodyId.value != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: locationController.selectedBodyId.value != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),

        // Ward Selection
        Obx(() {
          final hasBody = locationController.selectedBodyId.value != null;
          final wardCacheKey = hasBody && locationController.selectedDistrictId.value != null
              ? '${locationController.selectedDistrictId.value}_${locationController.selectedBodyId.value}'
              : null;
          final hasWards = wardCacheKey != null &&
                          locationController.bodyWards.containsKey(wardCacheKey) &&
                          (locationController.bodyWards[wardCacheKey]?.isNotEmpty ?? false);

          if (!hasBody || !hasWards) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      !hasBody
                          ? CandidateLocalizations.of(context)!.selectAreaFirst
                          : CandidateLocalizations.of(context)!.noWardsAvailable,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return InkWell(
            onTap: onWardTap,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [AppShadows.light],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CandidateLocalizations.of(context)!.selectWard,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                          locationController.selectedWard.value != null
                              ? locationController.selectedWard.value!.name
                              : CandidateLocalizations.of(context)!.selectWard,
                          style: AppTypography.bodyMedium.copyWith(
                            color: locationController.selectedWard.value != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: locationController.selectedWard.value != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        )),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
