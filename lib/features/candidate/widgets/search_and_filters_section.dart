import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/theme_constants.dart';
import '../../../utils/app_logger.dart';
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
  final VoidCallback? onDistrictRefresh;

  const SearchAndFiltersSection({
    super.key,
    required this.locationController,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onWardSelected,
    this.onDistrictRefresh,
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
            onDistrictTap: () {
              AppLogger.core('🔍 DISTRICT SELECTION: onDistrictTap called');
              AppLogger.core('🔍 DISTRICT SELECTION: Current state ID: ${locationController.selectedStateId.value}');
              AppLogger.core('🔍 DISTRICT SELECTION: Available districts: ${locationController.districts.length}');
              AppLogger.core('🔍 DISTRICT SELECTION: Current selected district: ${locationController.selectedDistrictId.value}');
              _showDistrictSelectionModal(context);
            },
            onBodyTap: () => _showBodySelectionModal(context),
            onWardTap: () => _showWardSelectionModal(context),
            onDistrictRefresh: onDistrictRefresh,
          ),
        ],
      ),
    );
  }

  void _showDistrictSelectionModal(BuildContext context) {
    AppLogger.core('🏠 DISTRICT MODAL: Opening district selection modal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        AppLogger.core('🏠 DISTRICT MODAL: Building modal widget');
        return DistrictSelectionModal(
          districts: locationController.districts,
          districtBodies: locationController.districtBodies,
          selectedDistrictId: locationController.selectedDistrictId.value,
          onDistrictSelected: (districtId) async {
            await locationController.selectDistrict(districtId);
          },
          onRefresh: () async {
            await locationController.forceRefreshDistricts();
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

class LocationBreadcrumb extends StatefulWidget {
  final LocationController locationController;
  final VoidCallback onStateTap;
  final VoidCallback onDistrictTap;
  final VoidCallback onBodyTap;
  final VoidCallback onWardTap;
  final VoidCallback? onDistrictRefresh;

  const LocationBreadcrumb({
    super.key,
    required this.locationController,
    required this.onStateTap,
    required this.onDistrictTap,
    required this.onBodyTap,
    required this.onWardTap,
    this.onDistrictRefresh,
  });

  @override
  State<LocationBreadcrumb> createState() => _LocationBreadcrumbState();
}

class _LocationBreadcrumbState extends State<LocationBreadcrumb> {
  final ScrollController _scrollController = ScrollController();
  late final Rx<String?> _previousSelectedBodyId = Rx<String?>(null);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locale = Localizations.localeOf(context);
      final isMarathi = locale.languageCode == 'mr';

      final parts = <Widget>[];

      // State
      final selectedState = widget.locationController.states.firstWhereOrNull(
        (state) => state.id == widget.locationController.selectedStateId.value,
      );
      final stateDisplayName = selectedState != null
          ? (isMarathi && selectedState.marathiName != null
              ? selectedState.marathiName!
              : selectedState.name)
          : CandidateLocalizations.of(context)!.selectState;

      parts.add(
        InkWell(
          onTap: widget.onStateTap,
          child: Text(
            stateDisplayName,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.blue,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
              fontSize: 18,

            ),
          ),
        ),
      );

      // District - show if state is selected
      if (widget.locationController.selectedStateId.value.isNotEmpty) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );
        parts.add(
          Row(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  AppLogger.core('🖱️ DISTRICT TEXT: onTapDown detected at ${details.globalPosition}');
                },
                onTap: () {
                  AppLogger.core('🖱️ DISTRICT TEXT: GestureDetector onTap fired!');
                  widget.onDistrictTap();
                },
                child: Text(
                  widget.locationController.selectedDistrictId.value != null
                      ? MaharashtraUtils.getDistrictDisplayNameV2(
                          widget.locationController.selectedDistrictId.value!,
                          locale,
                        )
                      : CandidateLocalizations.of(context)!.selectDistrict,
                  style: AppTypography.bodyMedium.copyWith(
                    color: widget.locationController.selectedDistrictId.value != null
                        ? Colors.blue
                        : AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        AppLogger.core('❌ DISTRICT NOT SHOWN: State not selected (selectedStateId is empty)');
      }

      // Body - show if district is selected
      if (widget.locationController.selectedDistrictId.value != null) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );

        final bodyDisplayName = widget.locationController.selectedBodyId.value != null
            ? (widget.locationController.selectedBody.value?.name ?? 'Body ${widget.locationController.selectedBodyId.value}')
            : CandidateLocalizations.of(context)!.selectArea;

        parts.add(
          InkWell(
            onTap: widget.onBodyTap,
            child: Text(
              bodyDisplayName,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.locationController.selectedBodyId.value != null
                    ? Colors.blue
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
        );
      }

      // Ward - show if body is selected
      if (widget.locationController.selectedBodyId.value != null) {
        parts.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('→', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
        );
        parts.add(
          InkWell(
            onTap: widget.onWardTap,
            child: Text(
              widget.locationController.selectedWard.value != null
                  ? widget.locationController.selectedWard.value!.name
                  : CandidateLocalizations.of(context)!.selectWard,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.locationController.selectedWard.value != null
                    ? Colors.blue
                    : AppColors.textSecondary,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
        );
      }

      // Auto-scroll to the end when body is selected (ward appears)
      if (widget.locationController.selectedBodyId.value != null &&
          _previousSelectedBodyId.value != widget.locationController.selectedBodyId.value) {
        _previousSelectedBodyId.value = widget.locationController.selectedBodyId.value;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
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
                controller: _scrollController,
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
