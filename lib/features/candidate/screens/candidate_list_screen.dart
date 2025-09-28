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
import '../../../models/user_model.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../../../utils/progressive_loader.dart';
import '../../../utils/maharashtra_utils.dart';
import '../models/candidate_model.dart';
import '../widgets/candidate_card.dart';

class CandidateListScreen extends StatefulWidget {
  final String? initialDistrictId;
  final String? initialBodyId;
  final String? initialWardId;

  const CandidateListScreen({
    super.key,
    this.initialDistrictId,
    this.initialBodyId,
    this.initialWardId,
  });

  @override
  State<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends State<CandidateListScreen> {
  final CandidateController controller = Get.put(CandidateController());
  String? selectedDistrictId;
  String? selectedBodyId;
  Ward? selectedWard;

  List<District> districts = [];
  Map<String, List<Body>> districtBodies = {};
  Map<String, List<Ward>> bodyWards = {};
  bool isLoadingDistricts = true;

  // Progressive loading
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

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
      debugPrint('Error loading more candidates: $e');
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

      debugPrint(
        '💾 Cached location data for ${districts.length} districts, ${districtBodies.length} body groups, ${bodyWards.length} ward groups',
      );
    } catch (e) {
      debugPrint('❌ Failed to cache location data: $e');
    }
  }

  // Load cached location data
  Future<bool> _loadCachedLocationData() async {
    try {
      if (!_isCacheValid()) {
        debugPrint('🔄 Location cache expired or missing');
        return false;
      }

      final districtsString = _prefs.getString(_districtsCacheKey);
      final bodiesString = _prefs.getString(_bodiesCacheKey);
      final wardsString = _prefs.getString(_wardsCacheKey);

      if (districtsString == null ||
          bodiesString == null ||
          wardsString == null) {
        debugPrint('🔄 Incomplete location cache');
        return false;
      }

      // Parse and load cached data
      // Note: In a real implementation, you'd use json.decode() here
      // For now, we'll just return false to force fresh load
      debugPrint('⚡ CACHE HIT: Loading cached location data');
      return false; // Temporary - implement proper JSON parsing
    } catch (e) {
      debugPrint('❌ Failed to load cached location data: $e');
      return false;
    }
  }

  Future<void> _loadDistricts() async {
    // Try to load from cache first
    final cacheLoaded = await _loadCachedLocationData();
    if (cacheLoaded) {
      setState(() {
        isLoadingDistricts = false;
      });
      _setInitialValues();
      return;
    }

    // Cache miss - load from Firestore
    debugPrint('🔄 Loading districts from Firestore');
    try {
      // Load districts from Firestore (correct path: states/stateId/districts)
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra') // Use the correct state ID
          .collection('districts')
          .get();
      districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({'id': doc.id, ...data});
      }).toList();

      debugPrint('✅ [CANDIDATE_LIST] Loaded ${districts.length} districts');

      // Don't load bodies upfront - load them on-demand when district is selected
      // This optimizes performance and reduces unnecessary Firebase calls

      setState(() {
        isLoadingDistricts = false;
      });

      _setInitialValues();
    } catch (e) {
      debugPrint('Error loading districts: $e');
      setState(() {
        isLoadingDistricts = false;
      });
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel.fromJson(userData);

        debugPrint('🔍 Loading candidates for user: ${userModel.uid}');
        debugPrint('📊 User has ${userModel.electionAreas.length} election areas');

        // Use the new method to fetch candidates for user
        await controller.fetchCandidatesForUser(userModel);
      }
    } catch (e) {
      debugPrint('❌ Error loading candidates for current user: $e');
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
        debugPrint('🔍 Performing debounced search for: "$query"');

        // For now, filter locally. In production, you might want to search server-side
        final allCandidates = controller.candidates;
        final filteredCandidates = allCandidates.where((candidate) {
          final nameMatch = candidate.name.toLowerCase().contains(
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
        debugPrint(
          '✅ Search completed: found ${filteredCandidates.length} candidates',
        );
      } catch (e) {
        debugPrint('❌ Search failed: $e');
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
      debugPrint('⚡ CACHE HIT: Using cached wards for $districtId/$bodyId');
      setState(() {});
      return;
    }

    debugPrint('🔄 [CANDIDATE_LIST] Loading wards from Firestore for $districtId/$bodyId');
    debugPrint('🔍 [CANDIDATE_LIST] State: maharashtra, District: $districtId, Body: $bodyId');
    try {
      // Load wards for the selected district and body
      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('   Ward: ${doc.id} - ${data['name'] ?? 'No name'}');
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
      }).toList();

      bodyWards[cacheKey] = wards;
      debugPrint('✅ [CANDIDATE_LIST] Successfully loaded ${wards.length} wards for body $bodyId');

      // Update cache
      await _cacheLocationData();

      setState(() {});
    } catch (e) {
      debugPrint('Error loading wards: $e');
    }
  }

  Future<void> _loadBodiesForDistrict(String districtId) async {
    // Check if bodies are already loaded for this district
    if (districtBodies.containsKey(districtId)) {
      debugPrint('⚡ CACHE HIT: Using cached bodies for district $districtId');
      return;
    }

    debugPrint('🔄 [CANDIDATE_LIST] Loading bodies for district $districtId');
    try {
      final bodiesSnapshot = await FirebaseFirestore.instance
          .collection('states')
          .doc('maharashtra')
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .get();

      debugPrint('📊 [CANDIDATE_LIST] Found ${bodiesSnapshot.docs.length} bodies in district $districtId');

      districtBodies[districtId] = bodiesSnapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('🏢 [CANDIDATE_LIST] Body: ${doc.id} - ${data['name'] ?? 'No name'} (${data['type'] ?? 'No type'})');
        return Body.fromJson({
          'id': doc.id,
          'districtId': districtId,
          'stateId': 'MH', // Assuming Maharashtra state
          ...data,
        });
      }).toList();

      // Update cache
      await _cacheLocationData();

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading bodies for district $districtId: $e');
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
            debugPrint('🎯 [CANDIDATE_LIST] Body selected: $bodyId for district: $selectedDistrictId');
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
        title: Text(CandidateLocalizations.of(context)!.searchCandidates),
      ),
      body: GetBuilder<CandidateController>(
        builder: (controller) {
          return Column(
            children: [
              // District, Body and Ward Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: CandidateLocalizations.of(context)!.searchCandidatesHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),

                    // District Selection
                    if (isLoadingDistricts)
                      const Center(child: CircularProgressIndicator())
                    else
                      InkWell(
                        onTap: () => _showDistrictSelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: CandidateLocalizations.of(context)!.selectDistrict,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_city),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedDistrictId != null
                              ? Text(
                                  MaharashtraUtils.getDistrictDisplayNameV2(
                                    selectedDistrictId!,
                                    Localizations.localeOf(context),
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                )
                              : Text(
                                  CandidateLocalizations.of(context)!.selectDistrict,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Body Selection
                    if (selectedDistrictId != null &&
                        districtBodies[selectedDistrictId!] != null &&
                        districtBodies[selectedDistrictId!]!.isNotEmpty)
                      InkWell(
                        onTap: () => _showBodySelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: CandidateLocalizations.of(context)!.selectArea,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.business),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedBodyId != null
                              ? Builder(
                                  builder: (context) {
                                    final body =
                                        districtBodies[selectedDistrictId!]!
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
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                )
                              : Text(
                                  CandidateLocalizations.of(context)!.selectArea,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedDistrictId == null
                                  ? CandidateLocalizations.of(context)!.selectDistrictFirst
                                  : districtBodies[selectedDistrictId!] ==
                                            null ||
                                        districtBodies[selectedDistrictId!]!
                                            .isEmpty
                                  ? CandidateLocalizations.of(context)!.noAreasAvailable
                                  : CandidateLocalizations.of(context)!.selectArea,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Ward Selection
                    if (selectedBodyId != null &&
                        bodyWards[wardCacheKey] != null &&
                        bodyWards[wardCacheKey]!.isNotEmpty)
                      InkWell(
                        onTap: () => _showWardSelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: CandidateLocalizations.of(context)!.selectWard,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.home),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedWard != null
                              ? Builder(
                                  builder: (context) {
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
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                )
                              : Text(
                                  CandidateLocalizations.of(context)!.selectWard,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              selectedBodyId == null
                                  ? CandidateLocalizations.of(context)!.selectAreaFirst
                                  : bodyWards[wardCacheKey] == null ||
                                        bodyWards[wardCacheKey]!.isEmpty
                                  ? CandidateLocalizations.of(context)!.noWardsAvailable
                                  : CandidateLocalizations.of(context)!.selectWard,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),


              // Results Section
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.errorMessage != null
                    ? Center(
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
                    ? Center(
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
                    ? Center(
                        child: Text(
                          CandidateLocalizations.of(
                            context,
                          )!.selectWardToViewCandidates,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            controller.candidates.length +
                            (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == controller.candidates.length) {
                            // Show loading indicator at the end
                            return Container(
                              padding: const EdgeInsets.all(16),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            );
                          }

                          final candidate = controller.candidates[index];
                          return CandidateCard(candidate: candidate);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }


}
