import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:janmat/core/app_theme.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../utils/multi_level_cache.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/theme_constants.dart';
import '../controllers/candidate_controller.dart';
import '../controllers/candidate_selection_controller.dart';
import '../../../features/user/models/user_model.dart';
import '../widgets/candidate_card.dart';
import '../../../utils/app_logger.dart';

class MyAreaCandidatesScreen extends StatefulWidget {
  const MyAreaCandidatesScreen({super.key});

  @override
  State<MyAreaCandidatesScreen> createState() => _MyAreaCandidatesScreenState();
}

class _MyAreaCandidatesScreenState extends State<MyAreaCandidatesScreen> {
  CandidateController? candidateController;
  CandidateSelectionController? selectionController;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  UserModel? currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize controllers first - ensure they exist
    try {
      candidateController = Get.find<CandidateController>();
    } catch (e) {
      // If not found, put it
      candidateController = Get.put<CandidateController>(CandidateController());
    }

    try {
      selectionController = Get.find<CandidateSelectionController>();
    } catch (e) {
      // If not found, put it
      selectionController = Get.put<CandidateSelectionController>(CandidateSelectionController());
    }

    _loadUserDataAndCandidates();
  }

  Future<void> _loadUserDataAndCandidates() async {
    if (currentUserId != null) {
      try {
        // First try to get user data from cache (from silent login)
        final cacheKey = 'home_user_data_$currentUserId';
        final cachedHomeData = await MultiLevelCache().get<Map<String, dynamic>>(cacheKey);

        if (cachedHomeData != null && cachedHomeData['user'] != null) {
          // Use cached user data
          currentUser = UserModel.fromJson(Map<String, dynamic>.from(cachedHomeData['user']));
          AppLogger.candidate('Using cached user data for My Area Candidates screen');
        } else {
          // Fallback to fetching from Firebase if cache is not available
          AppLogger.candidate('Cached user data not found, fetching from Firebase');
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

          if (userDoc.exists) {
            currentUser = UserModel.fromJson(userDoc.data()!);
          } else {
            AppLogger.candidate('User document not found in Firebase');
            return;
          }
        }

        // Load candidates from user's ward using new electionAreas structure
        final regularArea = currentUser!.electionAreas.isNotEmpty
            ? currentUser!.electionAreas.firstWhere(
                (area) => area.type == ElectionType.regular,
                orElse: () => currentUser!.electionAreas.first,
              )
            : null;

        // Validate required location data
        if (regularArea != null &&
            currentUser!.districtId != null &&
            currentUser!.districtId!.isNotEmpty &&
            regularArea.bodyId.isNotEmpty &&
            regularArea.wardId.isNotEmpty) {
          await candidateController!.fetchCandidatesByWard(
            currentUser!.districtId!,
            regularArea.bodyId,
            regularArea.wardId,
          );
        } else {
          AppLogger.candidateError('Missing required location data for user: districtId=${currentUser!.districtId}, bodyId=${regularArea?.bodyId}, wardId=${regularArea?.wardId}');
        }

        // If current user is a candidate, add them to the list
        if (currentUser!.role == 'candidate') {
          await _addCurrentUserToCandidatesList();
        }
      } catch (e) {
        AppLogger.candidateError('Error loading user data: $e');
      }
    }
  }

  Future<void> _addCurrentUserToCandidatesList() async {
    try {
      // Only proceed if current user data is available and they are a candidate
      if (currentUser == null || currentUser!.role != 'candidate') {
        return;
      }

      // Check if user has valid location data before attempting candidate lookup
      final regularArea = currentUser!.electionAreas.isNotEmpty
          ? currentUser!.electionAreas.firstWhere(
              (area) => area.type == ElectionType.regular,
              orElse: () => currentUser!.electionAreas.first,
            )
          : null;

      if (regularArea == null ||
          currentUser!.districtId == null ||
          currentUser!.districtId!.isEmpty ||
          regularArea.bodyId.isEmpty ||
          regularArea.wardId.isEmpty) {
        AppLogger.candidate('Skipping current user candidate lookup - incomplete location data');
        return;
      }

      // Get current user's candidate data using the repository method
      final currentUserCandidate = await candidateController!.candidateRepository
          .getCandidateData(currentUserId!);

      if (currentUserCandidate != null) {
        // Check if current user is already in the list (avoid duplicates)
        final existingIndex = candidateController!.candidates.indexWhere(
          (c) => c.candidateId == currentUserCandidate.candidateId,
        );

        if (existingIndex == -1) {
          // Add current user to the beginning of the list
          candidateController!.candidates.insert(0, currentUserCandidate);
          // RxList automatically triggers UI updates, no need for update()
        }
      }
    } catch (e) {
      AppLogger.candidateError('Error adding current user to candidates list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isInSelectionMode = selectionController!.isSelectionMode.value;
      final selectedCount = selectionController!.selectedCandidates.length;

      return Scaffold(
        backgroundColor: AppTheme.homeBackgroundColor,
        appBar: AppBar(
          title: isInSelectionMode
              ? Text('$selectedCount selected')
              : Text(CandidateLocalizations.of(context)!.myAreaCandidates),
          elevation: 0,
          leading: isInSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => selectionController!.toggleSelectionMode(),
                )
              : null,
          actions: [
            if (isInSelectionMode)
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: selectedCount >= 2
                      ? () => selectionController!.startComparison()
                      : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare'),
                  style: TextButton.styleFrom(
                    foregroundColor: selectedCount >= 2
                        ? AppColors.primary
                        : Colors.grey,
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: IconButton(
                  icon: Icon(Icons.compare, color: AppColors.accent),
                  tooltip: 'Compare candidates',
                  onPressed: () => selectionController!.toggleSelectionMode(),
                ),
              ),
          ],
        ),
        body: Obx(() {
          final controller = candidateController!;

        // Sort candidates by followers count (highest first)
        final sortedCandidates = controller.candidates.toList()
          ..sort((a, b) => b.followersCount.compareTo(a.followersCount));

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load candidates',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadUserDataAndCandidates,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.candidates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No candidates in your area',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no registered candidates in your ward yet.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter candidates based on search query
        final filteredCandidates = _searchQuery.isEmpty
            ? sortedCandidates
            : sortedCandidates.where((candidate) {
                final name = candidate.basicInfo?.fullName?.toLowerCase() ?? '';
                final party = SymbolUtils.getPartyDisplayNameWithLocale(
                  candidate.party,
                  Localizations.localeOf(context).languageCode,
                ).toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || party.contains(query);
              }).toList();

        return Column(
          children: [
            // Pinned Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search candidates...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800.withValues(alpha: 0.5)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Candidates List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadUserDataAndCandidates,
                child: filteredCandidates.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No candidates found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search terms.',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: filteredCandidates.length,
                        itemBuilder: (context, index) {
                          final candidate = filteredCandidates[index];
                          return CandidateCard(
                            candidate: candidate,
                            showCurrentUserIndicator: true,
                            currentUserId: currentUserId,
                            onFollowChanged: () {
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        );
        }),
      );
    });
  }


}
