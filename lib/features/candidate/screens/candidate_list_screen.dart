import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/candidate_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../features/user/models/user_model.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../../../utils/progressive_loader.dart';
import '../../../utils/maharashtra_utils.dart';
import '../../../utils/theme_constants.dart';
import '../models/candidate_model.dart';
import '../widgets/candidate_card.dart';
import '../../../services/local_database_service.dart';
import '../../../utils/app_logger.dart';
import '../../chat/controllers/chat_controller.dart';

class CandidateListScreen extends StatefulWidget {
  final String? initialDistrictId;
  final String? initialBodyId;
  final String? initialWardId;
  final String? stateId; // Make state configurable

  const CandidateListScreen({
    super.key,
    this.initialDistrictId,
    this.initialBodyId,
    this.initialWardId,
    this.stateId, // Default will be handled in state
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  final CandidateController controller = Get.put(CandidateController());
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();
  late String selectedStateId; // Make state configurable
  String? selectedDistrictId;
  String? selectedBodyId;
  Ward? selectedWard;

  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  bool isLoadingDistricts = true;

  // Progressive loading and scrolling
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

  // Swipe gesture detection and pull-to-refresh
  double _dragStartY = 0.0;
  double _dragDistance = 0.0;
  static const double _minSwipeDistance = 100.0;
  bool _showRefreshIndicator = false;

  // Cache keys
  static const String _districtsCacheKey = 'cached_districts';
  static const String _bodiesCacheKey = 'cached_bodies';
  static const String _wardsCacheKey = 'cached_wards';
  static const String _cacheTimestampKey = 'location_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(
    hours: 24,
  ); // Cache for 24 hours

  late SharedPreferences _prefs;

  // Search debouncing
  late SearchDebouncer _searchDebouncer;
  String _searchQuery = '';
  bool _isSearching = false;


  @override
  void initState() {
    super.initState();
    selectedStateId = widget.stateId ?? 'maharashtra'; // Default to maharashtra for backward compatibility
    _searchDebouncer = SearchDebouncer();
    _scrollController.addListener(_onScroll);
    _initializeCacheAndLoadDistricts();
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData &&
        selectedWard != null &&
        !_isSearching) {
      _loadMoreCandidates();
    }
  }

  // Handle swipe gestures for better UX
  void _onVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final currentY = details.globalPosition.dy;
    _dragDistance = _dragStartY - currentY; // Positive when swiping up

    // Show refresh indicator when pulling down
    if (_dragDistance < -50 && !_showRefreshIndicator) {
      setState(() => _showRefreshIndicator = true);
    } else if (_dragDistance > -50 && _showRefreshIndicator) {
      setState(() => _showRefreshIndicator = false);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // Check if it was a pull-down to refresh gesture
    if (_dragDistance < -_minSwipeDistance) {
      AppLogger.candidate('🔄 Pull down detected - refreshing candidates');
      _refreshCandidates();
    }
    // Check if it was a swipe up gesture
    else if (_dragDistance > _minSwipeDistance && selectedWard != null) {
      AppLogger.candidate('🔄 Swipe up detected - loading more candidates');
      _loadMoreCandidates();
    }

    _dragDistance = 0.0; // Reset drag distance
    if (_showRefreshIndicator) {
      setState(() => _showRefreshIndicator = false);
    }
  }

  Future<void> _refreshCandidates() async {
    if (selectedDistrictId != null && selectedBodyId != null && selectedWard != null) {
      setState(() => controller.isLoading = true);

      try {
        await controller.fetchCandidatesByWard(
          selectedDistrictId!,
          selectedBodyId!,
          selectedWard!.id,
        );
        AppLogger.candidate('✅ Candidates refreshed successfully');
      } catch (e) {
        AppLogger.candidateError('Failed to refresh candidates: $e');
      } finally {
        setState(() => controller.isLoading = false);
      }
    }
  }

  Future<void> _loadMoreCandidates() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      // Use progressive loader for additional candidates
      final progressiveLoader = ProgressiveLoader<Candidate>((
        offset,
        limit,
      ) async {
        // For now, we'll simulate pagination by loading more from the same ward
        // In a real implementation, you'd have a paginated method in the repository
        final allCandidates = await controller.candidateRepository
            .getCandidatesByWard(
              selectedDistrictId!,
              selectedBodyId!,
              selectedWard!.id,
            );

        // Simulate pagination by returning a subset
        final startIndex = offset;
        final endIndex = (startIndex + limit).clamp(0, allCandidates.length);

        if (startIndex >= allCandidates.length) {
          return []; // No more data
        }

        return allCandidates.sublist(startIndex, endIndex);
      }, pageSize: _pageSize);

      await progressiveLoader.loadMore();

      final newItems = progressiveLoader.items;
      final hasMore = progressiveLoader.hasMore;

      setState(() {
        // Add only new items that aren't already in the list
        final existingIds = controller.candidates
            .map((c) => c.candidateId)
            .toSet();
        final uniqueNewItems = newItems
            .where((c) => !existingIds.contains(c.candidateId))
            .toList();

        controller.candidates.addAll(uniqueNewItems);
        _hasMoreData = hasMore;
      });
    } catch (e) {
      AppLogger.candidateError('Error loading more candidates: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _initializeCacheAndLoadDistricts() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadDistricts();
  }

  // Check if cache is valid
  bool _isCacheValid() {
    final timestamp = _prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  // Cache location data
  Future<void> _cacheLocationData() async {
    try {
      // Cache districts
      final districtsJson = districts.map((d) => d.toJson()).toList();
      await _prefs.setString(_districtsCacheKey, districtsJson.toString());

      // Cache bodies
      final bodiesJson = districtBodies.map(
        (key, value) => MapEntry(key, value.map((b) => b.toJson()).toList()),
      );
      await _prefs.setString(_bodiesCacheKey, bodiesJson.toString());

      // Cache wards
      final wardsJson = bodyWards.map(
        (key, value) => MapEntry(key, value.map((w) => w.toJson()).toList()),
      );
      await _prefs.setString(_wardsCacheKey, wardsJson.toString());

      // Cache timestamp
      await _prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      AppLogger.candidate(
        '💾 Cached location data for ${districts.length} districts, ${districtBodies.length} body groups, ${bodyWards.length} ward groups',
      );
    } catch (e) {
      AppLogger.candidateError('Failed to cache location data: $e');
    }
  }

  // Load cached location data
  Future<bool> _loadCachedLocationData() async {
    try {
      if (!_isCacheValid()) {
        AppLogger.candidate('🔄 Location cache expired or missing');
        return false;
      }

      final districtsString = _prefs.getString(_districtsCacheKey);
      final bodiesString = _prefs.getString(_bodiesCacheKey);
      final wardsString = _prefs.getString(_wardsCacheKey);

      if (districtsString == null ||
          bodiesString == null ||
          wardsString == null) {
        AppLogger.candidate('🔄 Incomplete location cache');
        return false;
      }

      // Parse and load cached data
      // Note: In a real implementation, you'd use json.decode() here
      // For now, we'll just return false to force fresh load
      AppLogger.candidate('⚡ CACHE HIT: Loading cached location data');
      return false; // Temporary - implement proper JSON parsing
    } catch (e) {
      AppLogger.candidateError('Failed to load cached location data: $e');
      return false;
    }
  }

  Future<void> _loadDistricts() async {
    // Try to load from SQLite cache first
    final cacheLoaded = await _loadDistrictsFromSQLite();
    if (cacheLoaded) {
      setState(() {
        isLoadingDistricts = false;
      });
      _setInitialValues();
      return;
    }

    // SQLite cache miss - load from Firestore
    AppLogger.candidate('🔄 Loading districts from Firestore');
    try {
      // Load districts from Firestore (correct path: states/stateId/districts)
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId) // Use the configurable state ID
          .collection('districts')
          .get();
      districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({'id': doc.id, ...data});
      }).toList();

      AppLogger.candidate('✅ [CANDIDATE_LIST] Loaded ${districts.length} districts from Firebase');

      // Cache districts in SQLite for future use
      await _locationDatabase.insertDistricts(districts);

      // Don't load bodies upfront - load them on-demand when district is selected
      // This optimizes performance and reduces unnecessary Firebase calls

      setState(() {
        isLoadingDistricts = false;
      });

      _setInitialValues();
    } catch (e) {
      AppLogger.candidateError('Error loading districts from Firebase: $e');
      setState(() {
        isLoadingDistricts = false;
      });
    }
  }

  // Load districts from SQLite cache
  Future<bool> _loadDistrictsFromSQLite() async {
    final startTime = DateTime.now();
    try {
      AppLogger.candidate('🔍 [CANDIDATE_LIST:SQLite] Checking districts cache for state: $selectedStateId');

      // Check if districts cache is valid (24 hours)
      final lastUpdate = await _locationDatabase.getLastUpdateTime('districts');
      final cacheAge = lastUpdate != null ? DateTime.now().difference(lastUpdate) : null;
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      AppLogger.candidate('📊 [CANDIDATE_LIST:SQLite] Districts cache status:');
      AppLogger.candidate('   - Last update: ${lastUpdate?.toIso8601String() ?? 'Never'}');
      AppLogger.candidate('   - Cache age: ${cacheAge?.inMinutes ?? 'N/A'} minutes');
      AppLogger.candidate('   - Is valid: $isCacheValid');

      if (!isCacheValid) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST:SQLite] Districts cache expired or missing - will fetch from Firebase');
        return false;
      }

      // Load districts from SQLite - filter by stateId
      final db = await _locationDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.districtsTable,
        where: 'stateId = ?',
        whereArgs: [selectedStateId],
      );

      final loadTime = DateTime.now().difference(startTime).inMilliseconds;

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST:SQLite] No districts found in SQLite for state: $selectedStateId (load time: ${loadTime}ms)');
        return false;
      }

      districts = maps.map((map) => District.fromJson(map)).toList();
      AppLogger.candidate('✅ [CANDIDATE_LIST:SQLite] CACHE HIT - Loaded ${districts.length} districts from SQLite');
      AppLogger.candidate('   - State: $selectedStateId');
      AppLogger.candidate('   - Load time: ${loadTime}ms');
      AppLogger.candidate('   - Sample districts: ${districts.take(3).map((d) => '${d.id}:${d.name}').join(', ')}');

      return true;
    } catch (e) {
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.candidateError('[CANDIDATE_LIST:SQLite] Error loading districts from SQLite (${loadTime}ms): $e');
      return false;
    }
  }

  void _setInitialValues() {
    // Set initial values if provided
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialDistrictId != null &&
          districts.any((d) => d.id == widget.initialDistrictId)) {
        setState(() => selectedDistrictId = widget.initialDistrictId);

        // Load bodies for the initial district
        await _loadBodiesForDistrict(widget.initialDistrictId!);

        if (widget.initialBodyId != null &&
            districtBodies[widget.initialDistrictId]?.any(
                  (b) => b.id == widget.initialBodyId,
                ) ==
                true) {
          setState(() => selectedBodyId = widget.initialBodyId);
          await _loadWards(
            widget.initialDistrictId!,
            widget.initialBodyId!,
            context,
          );

          if (widget.initialWardId != null) {
            // Set initial ward if provided
            final ward = bodyWards[widget.initialBodyId]?.firstWhere(
              (ward) => ward.id == widget.initialWardId,
              orElse: () => Ward(
                id: '',
                name: '',
                areas: [],
                districtId: '',
                bodyId: '',
                stateId: '',
              ),
            );
            if (ward != null && ward.id.isNotEmpty) {
              setState(() => selectedWard = ward);
              await controller.fetchCandidatesByWard(
                widget.initialDistrictId!,
                widget.initialBodyId!,
                widget.initialWardId!,
              );
            }
          }
        }
      } else {
        // Try to load candidates for current user if no initial values provided
        await _loadCandidatesForCurrentUser();
      }
    });
  }

  // Load candidates for current user based on their election areas
  Future<void> _loadCandidatesForCurrentUser() async {
    try {
      // Use existing currentUser data from ChatController instead of Firebase call
      final chatController = Get.find<ChatController>();
      final userModel = chatController.currentUser;

      if (userModel == null) {
        AppLogger.candidate('No current user data available, skipping candidate loading');
        return;
      }

      AppLogger.candidate('🔍 Loading candidates for user: ${userModel.uid}');
      AppLogger.candidate('📊 User has ${userModel.electionAreas.length} election areas');

      // Use the new method to fetch candidates for user
      await controller.fetchCandidatesForUser(userModel);
    } catch (e) {
      AppLogger.candidateError('Error loading candidates for current user: $e');
    }
  }

  // Debounced search functionality
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);

    if (query.isEmpty) {
      // Clear search and show all candidates
      if (selectedDistrictId != null &&
          selectedBodyId != null &&
          selectedWard != null) {
        controller.fetchCandidatesByWard(
          selectedDistrictId!,
          selectedBodyId!,
          selectedWard!.id,
        );
      }
      return;
    }

    _searchDebouncer.debounceSearch(query, () async {
      if (!mounted) return;

      setState(() => _isSearching = true);

      try {
        // Perform search with debouncing
        AppLogger.candidate('🔍 Performing debounced search for: "$query"');

        // For now, filter locally. In production, you might want to search server-side
        final allCandidates = controller.candidates;
        final filteredCandidates = allCandidates.where((candidate) {
          final nameMatch = candidate.basicInfo!.fullName!.toLowerCase().contains(
            query.toLowerCase(),
          );
          final partyMatch = candidate.party.toLowerCase().contains(
            query.toLowerCase(),
          );
          return nameMatch || partyMatch;
        }).toList();

        // Update controller with filtered results
        controller.candidates = filteredCandidates;
        controller.update();
        AppLogger.candidate(
          '✅ Search completed: found ${filteredCandidates.length} candidates',
        );
      } catch (e) {
        AppLogger.candidateError('Search failed: $e');
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  // Clear search
  void _clearSearch() {
    _searchDebouncer.cancel();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });

    // Reload original candidates
    if (selectedDistrictId != null &&
        selectedBodyId != null &&
        selectedWard != null) {
      controller.fetchCandidatesByWard(
        selectedDistrictId!,
        selectedBodyId!,
        selectedWard!.id,
      );
    }
  }

  Future<void> _loadWards(
    String districtId,
    String bodyId,
    BuildContext context,
  ) async {
    final cacheKey = '${districtId}_$bodyId';

    // Check if wards are already cached
    if (bodyWards.containsKey(cacheKey)) {
      AppLogger.candidate('⚡ CACHE HIT: Using cached wards for $districtId/$bodyId');
      setState(() {});
      return;
    }

    // Try to load from SQLite cache first
    final cacheLoaded = await _loadWardsFromSQLite(districtId, bodyId, cacheKey);
    if (cacheLoaded) {
      setState(() {});
      return;
    }

    AppLogger.candidate('🔄 [CANDIDATE_LIST] Loading wards from Firestore for $districtId/$bodyId');
    AppLogger.candidate('🔍 [CANDIDATE_LIST] State: $selectedStateId, District: $districtId, Body: $bodyId');
    try {
      // Load wards for the selected district and body
      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        AppLogger.candidate('   Ward: ${doc.id} - ${data['name'] ?? 'No name'}');
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
      }).toList();

      bodyWards[cacheKey] = wards;
      AppLogger.candidate('✅ [CANDIDATE_LIST] Successfully loaded ${wards.length} wards for body $bodyId from Firebase');

      // Cache wards in SQLite for future use
      await _locationDatabase.insertWards(wards);

      setState(() {});
    } catch (e) {
      AppLogger.candidateError('Error loading wards from Firebase: $e');
    }
  }

  // Load wards from SQLite cache
  Future<bool> _loadWardsFromSQLite(String districtId, String bodyId, String cacheKey) async {
    try {
      AppLogger.candidate('🔍 [CANDIDATE_LIST] Checking SQLite cache for wards: $districtId/$bodyId');

      // Check if wards cache is valid (24 hours)
      final lastUpdate = await _locationDatabase.getLastUpdateTime('wards');
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      if (!isCacheValid) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST] Wards cache expired or missing');
        return false;
      }

      // Load wards from SQLite for this district and body
      final db = await _locationDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.wardsTable,
        where: 'districtId = ? AND bodyId = ? AND stateId = ?',
        whereArgs: [districtId, bodyId, selectedStateId],
      );

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST] No wards found in SQLite for $districtId/$bodyId');
        return false;
      }

      bodyWards[cacheKey] = maps.map((map) => Ward.fromJson(map)).toList();
      AppLogger.candidate('✅ [CANDIDATE_LIST] Loaded ${bodyWards[cacheKey]!.length} wards from SQLite cache for $districtId/$bodyId');

      return true;
    } catch (e) {
      AppLogger.candidateError('[CANDIDATE_LIST] Error loading wards from SQLite: $e');
      return false;
    }
  }

  Future<void> _loadBodiesForDistrict(String districtId) async {
    // Check if bodies are already loaded for this district
    if (districtBodies.containsKey(districtId)) {
      AppLogger.candidate('⚡ CACHE HIT: Using cached bodies for district $districtId');
      return;
    }

    // Try to load from SQLite cache first
    final cacheLoaded = await _loadBodiesFromSQLite(districtId);
    if (cacheLoaded) {
      setState(() {});
      return;
    }

    AppLogger.candidate('🔄 [CANDIDATE_LIST] Loading bodies for district $districtId from Firebase');
    try {
      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc(selectedStateId)
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      AppLogger.candidate('📊 [CANDIDATE_LIST] Found ${bodiesSnapshot.docs.length} bodies in district $districtId from Firebase');

      districtBodies[districtId] = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        AppLogger.candidate('🏢 [CANDIDATE_LIST] Body: ${doc.id} - ${data['name'] ?? 'No name'} (${data['type'] ?? 'No type'})');
        return Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': selectedStateId, // Use dynamic state ID
          ...data,
        });
      }).toList();

      // Cache bodies in SQLite for future use
      await _locationDatabase.insertBodies(districtBodies[districtId]!);

      setState(() {});
    } catch (e) {
      AppLogger.candidateError('Error loading bodies for district $districtId from Firebase: $e');
    }
  }

  // Load bodies from SQLite cache
  Future<bool> _loadBodiesFromSQLite(String districtId) async {
    try {
      AppLogger.candidate('🔍 [CANDIDATE_LIST] Checking SQLite cache for bodies in district: $districtId');

      // Check if bodies cache is valid (24 hours)
      final lastUpdate = await _locationDatabase.getLastUpdateTime('bodies');
      final isCacheValid = lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheValidityDuration;

      if (!isCacheValid) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST] Bodies cache expired or missing');
        return false;
      }

      // Load bodies from SQLite for this district
      final db = await _locationDatabase.database;
      final List<Map<String, dynamic>> maps = await db.query(
        LocalDatabaseService.bodiesTable,
        where: 'districtId = ? AND stateId = ?',
        whereArgs: [districtId, selectedStateId],
      );

      if (maps.isEmpty) {
        AppLogger.candidate('🔄 [CANDIDATE_LIST] No bodies found in SQLite for district: $districtId');
        return false;
      }

      districtBodies[districtId] = maps.map((map) => Body.fromJson(map)).toList();
      AppLogger.candidate('✅ [CANDIDATE_LIST] Loaded ${districtBodies[districtId]!.length} bodies from SQLite cache for district: $districtId');

      return true;
    } catch (e) {
      AppLogger.candidateError('[CANDIDATE_LIST] Error loading bodies from SQLite: $e');
      return false;
    }
  }

  void _showDistrictSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DistrictSelectionModal(
          districts: districts,
          districtBodies: districtBodies,
          selectedDistrictId: selectedDistrictId,
          onDistrictSelected: (districtId) async {
            setState(() {
              selectedDistrictId = districtId;
              selectedBodyId = null;
              selectedWard = null;
              bodyWards.clear();
            });
            controller.clearCandidates();

            // Load bodies for the selected district
            await _loadBodiesForDistrict(districtId);
          },
        );
      },
    );
  }

  void _showBodySelectionModal(BuildContext context) {
    final selectedDistrict = districts.firstWhere(
      (d) => d.id == selectedDistrictId,
    );
    final districtName = selectedDistrict.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: districtBodies[selectedDistrictId!]!,
          selectedBodyId: selectedBodyId,
          districtName: districtName,
          onBodySelected: (bodyId) {
            AppLogger.candidate('🎯 [CANDIDATE_LIST] Body selected: $bodyId for district: $selectedDistrictId');
            setState(() {
              selectedBodyId = bodyId;
              selectedWard = null;
              bodyWards.clear();
            });
            _loadWards(selectedDistrictId!, bodyId, context);
            controller.clearCandidates();
          },
        );
      },
    );
  }

  void _showWardSelectionModal(BuildContext context) {
    final wardCacheKey = selectedBodyId != null && selectedDistrictId != null
        ? '${selectedDistrictId}_$selectedBodyId'
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: bodyWards[wardCacheKey] ?? [],
          selectedWardId: selectedWard?.id,
          onWardSelected: (wardId) {
            final ward = bodyWards[wardCacheKey]!.firstWhere(
              (w) => w.id == wardId,
            );
            setState(() {
              selectedWard = ward;
            });
            if (selectedDistrictId != null && selectedBodyId != null) {
              controller.fetchCandidatesByWard(
                selectedDistrictId!,
                selectedBodyId!,
                wardId,
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute ward cache key for consistent access
    final wardCacheKey = selectedBodyId != null && selectedDistrictId != null
        ? '${selectedDistrictId}_$selectedBodyId'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          CandidateLocalizations.of(context)!.searchCandidates,
        ),
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
              onPressed: selectedWard != null ? _refreshCandidates : null,
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          child: GetBuilder<CandidateController>(
            builder: (controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filters Section
                  Container(
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
                          child: TextField(
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: CandidateLocalizations.of(context)!.searchCandidatesHint,
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: _clearSearch,
                                    )
                                  : _isSearching
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
                          ),
                        ),

                        // District Selection
                        if (isLoadingDistricts)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        else
                          InkWell(
                            onTap: () => _showDistrictSelectionModal(context),
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
                                        Text(
                                          selectedDistrictId != null
                                              ? MaharashtraUtils.getDistrictDisplayNameV2(
                                                  selectedDistrictId!,
                                                  Localizations.localeOf(context),
                                                )
                                              : CandidateLocalizations.of(context)!.selectDistrict,
                                          style: AppTypography.bodyMedium.copyWith(
                                            color: selectedDistrictId != null
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                            fontWeight: selectedDistrictId != null
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
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
                          ),
                        const SizedBox(height: AppSpacing.md),

                        // Body Selection
                        if (selectedDistrictId != null &&
                            districtBodies[selectedDistrictId!] != null &&
                            districtBodies[selectedDistrictId!]!.isNotEmpty)
                          InkWell(
                            onTap: () => _showBodySelectionModal(context),
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
                                        Builder(
                                          builder: (context) {
                                            if (selectedBodyId != null) {
                                              final body = districtBodies[selectedDistrictId!]!
                                                  .firstWhere(
                                                    (b) => b.id == selectedBodyId,
                                                    orElse: () => Body(
                                                      id: '',
                                                      name: '',
                                                      type: BodyType.municipal_corporation,
                                                      districtId: '',
                                                      stateId: '',
                                                    ),
                                                  );
                                              return Text(
                                                body.id.isNotEmpty
                                                    ? '${body.name} (${CandidateLocalizations.of(context)!.translateBodyType(body.type.toString().split('.').last)})'
                                                    : selectedBodyId!,
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }
                                            return Text(
                                              CandidateLocalizations.of(context)!.selectArea,
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            );
                                          },
                                        ),
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
                          )
                        else
                          Container(
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
                                    selectedDistrictId == null
                                        ? CandidateLocalizations.of(context)!.selectDistrictFirst
                                        : districtBodies[selectedDistrictId!] == null ||
                                            districtBodies[selectedDistrictId!]!.isEmpty
                                        ? CandidateLocalizations.of(context)!.noAreasAvailable
                                        : CandidateLocalizations.of(context)!.selectArea,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),

                        // Ward Selection
                        if (selectedBodyId != null &&
                            bodyWards[wardCacheKey] != null &&
                            bodyWards[wardCacheKey]!.isNotEmpty)
                          InkWell(
                            onTap: () => _showWardSelectionModal(context),
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
                                        Builder(
                                          builder: (context) {
                                            if (selectedWard != null) {
                                              // Format ward display like "वॉर्ड 1 - Ward Name"
                                              final numberMatch = RegExp(r'ward_(\d+)')
                                                  .firstMatch(
                                                    selectedWard!.id.toLowerCase(),
                                                  );
                                              final displayText = numberMatch != null
                                                  ? 'वॉर्ड ${numberMatch.group(1)} - ${selectedWard!.name}'
                                                  : selectedWard!.name;
                                              return Text(
                                                displayText,
                                                style: AppTypography.bodyMedium.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            }
                                            return Text(
                                              CandidateLocalizations.of(context)!.selectWard,
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                            );
                                          },
                                        ),
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
                          )
                        else
                          Container(
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
                                    selectedBodyId == null
                                        ? CandidateLocalizations.of(context)!.selectAreaFirst
                                        : bodyWards[wardCacheKey] == null ||
                                            bodyWards[wardCacheKey]!.isEmpty
                                        ? CandidateLocalizations.of(context)!.noWardsAvailable
                                        : CandidateLocalizations.of(context)!.selectWard,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Results Section
                  controller.isLoading
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      : controller.errorMessage != null
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.6,
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
                                controller.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  controller.clearError();
                                  if (selectedDistrictId != null &&
                                      selectedBodyId != null &&
                                      selectedWard != null) {
                                    controller.fetchCandidatesByWard(
                                      selectedDistrictId!,
                                      selectedBodyId!,
                                      selectedWard!.id,
                                    );
                                  }
                                },
                                child: Text(AppLocalizations.of(context)!.retry),
                              ),
                            ],
                          ),
                        )
                      : controller.candidates.isEmpty && selectedWard != null
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.6,
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
                                '${CandidateLocalizations.of(context)!.noCandidatesFound} ${selectedWard!.name}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : selectedWard == null
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          alignment: Alignment.center,
                          child: Text(
                            CandidateLocalizations.of(
                              context,
                            )!.selectWardToViewCandidates,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: [
                            // Pull to refresh indicator
                            if (_showRefreshIndicator)
                              Container(
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
                              ),

                            // Candidate List
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(AppBorderRadius.lg),
                                  topRight: Radius.circular(AppBorderRadius.lg),
                                ),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: controller.candidates.length + (_isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == controller.candidates.length) {
                                    // Show loading indicator at the end
                                    return Container(
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    );
                                  }

                                  final candidate = controller.candidates[index];
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
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: selectedWard != null
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
          : null,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

