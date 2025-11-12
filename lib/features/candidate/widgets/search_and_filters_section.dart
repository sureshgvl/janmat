import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/theme_constants.dart';
import '../../../widgets/modals/state_selection_modal.dart';
import '../../../widgets/modals/district_selection_modal.dart';
import '../../../widgets/modals/area_selection_modal.dart';
import '../../../widgets/modals/ward_selection_modal.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../models/ward_model.dart';
import '../controllers/location_controller.dart';
import '../controllers/search_controller.dart' as search;

class SearchAndFiltersSection extends StatelessWidget {
  final LocationController locationController;
  final search.SearchController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onWardSelected;

  const SearchAndFiltersSection({
    super.key,
    required this.locationController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onWardSelected,
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
              onChanged: onSearchChanged,
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

          // Location Breadcrumb
          LocationBreadcrumb(
            locationController: locationController,
            onStateTap: () => _showStateSelectionModal(context),
            onDistrictTap: () => _showDistrictSelectionModal(context),
            onBodyTap: () => _showBodySelectionModal(context),
            onWardTap: () => _showWardSelectionModal(context),
          ),
        ],
      ),
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DistrictSelectionModal(
          districts: locationController.districts,
          districtBodies: locationController.districtBodies,
          selectedDistrictId: locationController.selectedDistrictId.value,
          onDistrictSelected: (districtId) async {
            await locationController.selectDistrict(districtId);
          },
        );
      },
    );
  }

  void _showBodySelectionModal(BuildContext context) {
    if (locationController.selectedDistrictId.value == null) return;

    final districtName = MaharashtraUtils.getDistrictDisplayNameV2(
      locationController.selectedDistrictId.value!,
      Localizations.localeOf(context),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: locationController.districtBodies[locationController.selectedDistrictId.value] ?? [],
          selectedBodyId: locationController.selectedBodyId.value,
          districtName: districtName,
          onBodySelected: (bodyId) async {
            await locationController.selectBody(bodyId);
          },
        );
      },
    );
  }

  void _showStateSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StateSelectionModal(
          states: locationController.states,
          selectedStateId: locationController.selectedStateId.value,
          onStateSelected: (stateId) async {
            await locationController.selectState(stateId);
          },
        );
      },
    );
  }

  void _showWardSelectionModal(BuildContext context) {
    if (locationController.selectedDistrictId.value == null ||
        locationController.selectedBodyId.value == null) return;

    final cacheKey = '${locationController.selectedDistrictId.value}_${locationController.selectedBodyId.value}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: locationController.bodyWards[cacheKey] ?? [],
          selectedWardId: locationController.selectedWard.value?.id,
          onWardSelected: (wardId) {
            final ward = locationController.bodyWards[cacheKey]?.firstWhere(
              (w) => w.id == wardId,
              orElse: () => Ward(id: '', name: '', areas: [], districtId: '', bodyId: '', stateId: ''),
            );
            if (ward != null && ward.id.isNotEmpty) {
              locationController.selectWard(ward);
              // Call the callback to load candidates
              onWardSelected?.call();
            }
          },
        );
      },
    );
  }
}

class LocationBreadcrumb extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback onStateTap;
  final VoidCallback onDistrictTap;
  final VoidCallback onBodyTap;
  final VoidCallback onWardTap;

  const LocationBreadcrumb({
    super.key,
    required this.locationController,
    required this.onStateTap,
    required this.onDistrictTap,
    required this.onBodyTap,
    required this.onWardTap,
  });

  // Format ward display like in the modal (e.g., "वॉर्ड 1 - Ward Name")
  String _formatWardDisplay(String wardId, String wardName) {
    // Extract number from ward_id (e.g., "ward_1" -> "1")
    final numberMatch = RegExp(r'ward_(\d+)').firstMatch(wardId.toLowerCase());
    if (numberMatch != null) {
      final wardNumber = numberMatch.group(1);
      return 'वॉर्ड $wardNumber - $wardName';
    }
    // Fallback to original name if pattern doesn't match
    return wardName;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isMarathi = locale.languageCode == 'mr';

    return Obx(() {
      final parts = <Widget>[];

      // State
      final selectedState = locationController.states.firstWhereOrNull(
        (state) => state.id == locationController.selectedStateId.value,
      );
      final stateDisplayName = selectedState != null
          ? (isMarathi && selectedState.marathiName != null
              ? selectedState.marathiName!
              : selectedState.name)
          : 'Select State';

      parts.add(
        InkWell(
          onTap: onStateTap,
          child: Text(
            stateDisplayName,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      // District - show if state is selected
      if (locationController.selectedStateId.value.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );
        parts.add(
          InkWell(
            onTap: onDistrictTap,
            child: Text(
              locationController.selectedDistrictId.value != null
                  ? MaharashtraUtils.getDistrictDisplayNameV2(
                      locationController.selectedDistrictId.value!,
                      locale,
                    )
                  : 'Select District',
              style: AppTypography.bodyMedium.copyWith(
                color: locationController.selectedDistrictId.value != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      // Body - show if district is selected
      if (locationController.selectedDistrictId.value != null) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );

        final bodyDisplayName = locationController.selectedBodyId.value != null
            ? (locationController.selectedBody?.name ?? 'Body ${locationController.selectedBodyId.value}')
            : 'Select Area';

        parts.add(
          InkWell(
            onTap: onBodyTap,
            child: Text(
              bodyDisplayName,
              style: AppTypography.bodyMedium.copyWith(
                color: locationController.selectedBodyId.value != null
                    ? AppColors.secondary
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      // Ward - show if body is selected
      if (locationController.selectedBodyId.value != null) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );
        parts.add(
          InkWell(
            onTap: onWardTap,
            child: Text(
              locationController.selectedWard.value != null
                  ? locationController.selectedWard.value!.name
                  : 'Select Ward',
              style: AppTypography.bodyMedium.copyWith(
                color: locationController.selectedWard.value != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }

      return Container(
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
              Icons.location_on,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: parts,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class LocationSelectors extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback onStateTap;
  final VoidCallback onDistrictTap;
  final VoidCallback onBodyTap;
  final VoidCallback onWardTap;

  const LocationSelectors({
    super.key,
    required this.locationController,
    required this.onStateTap,
    required this.onDistrictTap,
    required this.onBodyTap,
    required this.onWardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // State Selection
        Obx(() => locationController.isLoadingStates.value
            ? Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : InkWell(
                onTap: onStateTap,
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
                        Icons.map,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select State',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                              locationController.selectedStateId.value != 'maharashtra'
                                  ? locationController.states.firstWhereOrNull(
                                      (state) => state.id == locationController.selectedStateId.value,
                                    )?.marathiName ?? locationController.states.firstWhereOrNull(
                                      (state) => state.id == locationController.selectedStateId.value,
                                    )?.name ?? 'Select State'
                                  : 'Maharashtra',
                              style: AppTypography.bodyMedium.copyWith(
                                color: locationController.selectedStateId.value.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: locationController.selectedStateId.value.isNotEmpty
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
                                  ? MaharashtraUtils.getDistrictDisplayNameV2(
                                      locationController.selectedDistrictId.value!,
                                      Localizations.localeOf(context),
                                    )
                                  : CandidateLocalizations.of(context)!.selectDistrict,
                              style: AppTypography.bodyMedium.copyWith(
                                color: locationController.selectedDistrictId.value != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: locationController.selectedDistrictId.value != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
                              ? locationController.selectedBody?.name ?? 'Body ${locationController.selectedBodyId.value}'
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
