import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/search_controller.dart' as search;
import '../controllers/pagination_controller.dart';
import '../widgets/search_and_filters_section.dart';
import '../widgets/candidate_list_view.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/theme_constants.dart';
import '../../../utils/app_logger.dart';
import '../../../core/app_theme.dart';
import '../../chat/controllers/chat_controller.dart';

class CandidateListScreen extends StatefulWidget {
  final String? initialDistrictId;
  final String? initialBodyId;
  final String? initialWardId;
  final String? stateId;

  const CandidateListScreen({
    super.key,
    this.initialDistrictId,
    this.initialBodyId,
    this.initialWardId,
    this.stateId,
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  // Controllers
  final CandidateController candidateController = Get.put(CandidateController());
  final LocationController locationController = Get.put(LocationController());
  final search.SearchController searchController = Get.put(search.SearchController());
  late final PaginationController paginationController;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

  // Initialize PaginationController
    paginationController = Get.put(PaginationController(
      loadFunction: (offset, limit) async {
        AppLogger.candidate('🔄 [Pagination] Load function called with offset: $offset, limit: $limit');
        AppLogger.candidate('🔄 [Pagination] Selected district: ${locationController.selectedDistrictId.value}');
        AppLogger.candidate('🔄 [Pagination] Selected body: ${locationController.selectedBodyId.value}');
        AppLogger.candidate('🔄 [Pagination] Selected ward: ${locationController.selectedWard.value?.name ?? 'null'}');

        // Use CandidateRepository to load candidates
        if (locationController.selectedDistrictId.value != null &&
            locationController.selectedBodyId.value != null &&
            locationController.selectedWard.value != null) {
          try {
            AppLogger.candidate('🔄 [Pagination] Calling getCandidatesByWard...');
            final candidates = await candidateController.candidateRepository.getCandidatesByWard(
              locationController.selectedDistrictId.value!,
              locationController.selectedBodyId.value!,
              locationController.selectedWard.value!.id,
            );
            AppLogger.candidate('🔄 [Pagination] getCandidatesByWard returned ${candidates.length} candidates');

            // Update the candidateController.candidates list so the UI can display them
            AppLogger.candidate('🔄 [Pagination] Updating candidateController.candidates with ${candidates.length} candidates');
            candidateController.candidates.assignAll(candidates);
            candidateController.update();
            AppLogger.candidate('🔄 [Pagination] candidateController updated, returning ${candidates.length} candidates');

            return candidates;
          } catch (e) {
            AppLogger.candidateError('🔄 [Pagination] Failed to load candidates: $e');
            return [];
          }
        }
        AppLogger.candidate('🔄 [Pagination] Missing required location data, returning empty list');
        return [];
      },
    ));

    _initializeScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Handle pagination when scrolling near the end
    if (paginationController.shouldLoadMore(
      _scrollController.position.pixels,
      _scrollController.position.maxScrollExtent,
    )) {
      _loadMoreCandidates();
    }
  }

  Future<void> _initializeScreen() async {
    try {
      // Initialize location data
      await locationController.initialize();

      // Set initial values if provided
      if (widget.initialDistrictId != null) {
        await locationController.setInitialDistrict(widget.initialDistrictId!);
      }
      if (widget.initialBodyId != null) {
        await locationController.setInitialBody(widget.initialBodyId!);
      }
      if (widget.initialWardId != null) {
        await locationController.setInitialWard(widget.initialWardId!);
        // Load candidates for the initial ward using pagination
        AppLogger.candidate('🔄 Loading initial candidates via pagination for ward: ${widget.initialWardId}');
        await paginationController.loadInitial();
      } else {
        // Try to load candidates for current user
        await _loadCandidatesForCurrentUser();
      }

      AppLogger.candidate('✅ Candidate list screen initialized successfully');
    } catch (e) {
      AppLogger.candidateError('Failed to initialize candidate list screen: $e');
    }
  }

  Future<void> _loadCandidatesForWard({String? stateId}) async {
    if (locationController.selectedDistrictId.value != null &&
        locationController.selectedBodyId.value != null &&
        locationController.selectedWard.value != null) {
      try {
        await candidateController.fetchCandidatesByWard(
          locationController.selectedDistrictId.value!,
          locationController.selectedBodyId.value!,
          locationController.selectedWard.value!.id,
          stateId: stateId ?? locationController.selectedStateId.value,
        );
        AppLogger.candidate('✅ Candidates loaded for ward: ${locationController.selectedWard.value!.name}');
      } catch (e) {
        AppLogger.candidateError('Failed to load candidates for ward: $e');
      }
    }
  }

  Future<void> _loadCandidatesForCurrentUser() async {
    try {
      final chatController = Get.find<ChatController>();
      final userModel = chatController.currentUser;

      if (userModel == null) {
        AppLogger.candidate('No current user data available, skipping candidate loading');
        return;
      }

      AppLogger.candidate('🔍 Loading candidates for user: ${userModel.uid}');
      await candidateController.fetchCandidatesForUser(userModel);
    } catch (e) {
      AppLogger.candidateError('Error loading candidates for current user: $e');
    }
  }

  Future<void> _loadMoreCandidates() async {
    if (locationController.selectedWard.value != null) {
      await paginationController.loadMore();
    }
  }

  Future<void> _refreshCandidates() async {
    await paginationController.refresh();
    await _loadCandidatesForWard();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      // Clear search and reload original candidates
      //searchController.clearSearch();
      _loadCandidatesForWard();
    } else {
      // Perform search on current candidates
      searchController.search(query, candidateController.candidates);
    }
  }

  void _onClearSearch() {
    searchController.clearSearch();
    _loadCandidatesForWard();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.homeBackgroundColor,
      appBar: AppBar(
        title: Text(CandidateLocalizations.of(context)!.searchCandidates),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: AppColors.accent,
              ),
              tooltip: 'Refresh candidates',
              onPressed: locationController.selectedWard.value != null
                  ? _refreshCandidates
                  : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          children: [
            // Search and Filters Section
            SearchAndFiltersSection(
              locationController: locationController,
              searchController: searchController,
              onSearchChanged: _onSearchChanged,
              onClearSearch: _onClearSearch,
              onWardSelected: () async {
                AppLogger.candidate('🔄 Ward selected via UI, loading candidates via pagination');
                await paginationController.loadInitial();
              },
              onDistrictRefresh: () async {
                await locationController.forceRefreshDistricts();
              },
            ),

            // Candidate List View
            CandidateListView(
              candidateController: candidateController,
              searchController: searchController,
              locationController: locationController,
              paginationController: paginationController,
              onRefresh: _refreshCandidates,
              onLoadMore: _loadMoreCandidates,
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(() => locationController.selectedWard.value != null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                tooltip: 'Scroll to top',
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
            )
          : const SizedBox.shrink()),
    );
  }
}
