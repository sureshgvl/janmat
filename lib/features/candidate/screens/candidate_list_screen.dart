import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/candidate_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/ward_model.dart';
import '../../../models/district_model.dart';
import '../../../models/body_model.dart';
import '../../../utils/symbol_utils.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/profile/district_selection_modal.dart';
import '../../../widgets/profile/area_selection_modal.dart';
import '../../../widgets/profile/ward_selection_modal.dart';
import '../../../utils/progressive_loader.dart';
import '../models/candidate_model.dart';

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
              selectedWard!.wardId,
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
      // Load districts from Firestore
      final districtsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .get();
      districts = districtsSnapshot.docs.map((doc) {
        final data = doc.data();
        return District.fromJson({'districtId': doc.id, ...data});
      }).toList();

      // Load bodies for each district
      for (final district in districts) {
        final bodiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(district.districtId)
            .collection('bodies')
            .get();
        districtBodies[district.districtId] = bodiesSnapshot.docs.map((doc) {
          final data = doc.data();
          return Body.fromJson({
            'bodyId': doc.id,
            'districtId': district.districtId,
            ...data,
          });
        }).toList();
      }

      // Cache the loaded data
      await _cacheLocationData();

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
          districts.any((d) => d.districtId == widget.initialDistrictId)) {
        setState(() => selectedDistrictId = widget.initialDistrictId);

        if (widget.initialBodyId != null &&
            districtBodies[widget.initialDistrictId]?.any(
                  (b) => b.bodyId == widget.initialBodyId,
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
              (ward) => ward.wardId == widget.initialWardId,
              orElse: () => Ward(
                wardId: '',
                name: '',
                areas: [],
                districtId: '',
                bodyId: '',
              ),
            );
            if (ward != null && ward.wardId.isNotEmpty) {
              setState(() => selectedWard = ward);
              await controller.fetchCandidatesByWard(
                widget.initialDistrictId!,
                widget.initialBodyId!,
                widget.initialWardId!,
              );
            }
          }
        }
      }
    });
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
          selectedWard!.wardId,
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
        selectedWard!.wardId,
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

    debugPrint('🔄 Loading wards from Firestore for $districtId/$bodyId');
    try {
      // Load wards for the selected district and body
      final wardsSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('bodies')
          .doc(bodyId)
          .collection('wards')
          .get();

      final wards = wardsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Ward.fromJson({
          ...data,
          'wardId': doc.id,
          'districtId': districtId,
          'bodyId': bodyId,
        });
      }).toList();

      bodyWards[cacheKey] = wards;

      // Update cache
      await _cacheLocationData();

      setState(() {});
    } catch (e) {
      debugPrint('Error loading wards: $e');
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
          onDistrictSelected: (districtId) {
            setState(() {
              selectedDistrictId = districtId;
              selectedBodyId = null;
              selectedWard = null;
              bodyWards.clear();
            });
            controller.clearCandidates();
          },
        );
      },
    );
  }

  void _showBodySelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return AreaSelectionModal(
          bodies: districtBodies[selectedDistrictId!]!,
          selectedBodyId: selectedBodyId,
          onBodySelected: (bodyId) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return WardSelectionModal(
          wards: bodyWards[selectedBodyId!] ?? [],
          selectedWardId: selectedWard?.wardId,
          onWardSelected: (wardId) {
            final ward = bodyWards[selectedBodyId!]!.firstWhere(
              (w) => w.wardId == wardId,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchCandidates),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
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
                          hintText: 'Search candidates by name or party...',
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
                            labelText: 'Select District',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_city),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: selectedDistrictId != null
                              ? Text(
                                  districts
                                      .firstWhere(
                                        (d) =>
                                            d.districtId == selectedDistrictId,
                                      )
                                      .name,
                                  style: const TextStyle(fontSize: 16),
                                )
                              : const Text(
                                  'Select District',
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
                            labelText: 'Select Area (विभाग)',
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
                                              (b) => b.bodyId == selectedBodyId,
                                              orElse: () => Body(
                                                bodyId: '',
                                                districtId: '',
                                                name: '',
                                                type: '',
                                                wardCount: 0,
                                              ),
                                            );
                                    return Text(
                                      body.bodyId.isNotEmpty
                                          ? '${body.name} (${body.type})'
                                          : selectedBodyId!,
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  },
                                )
                              : const Text(
                                  'Select Area (विभाग)',
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
                                  ? 'Select district first'
                                  : districtBodies[selectedDistrictId!] ==
                                            null ||
                                        districtBodies[selectedDistrictId!]!
                                            .isEmpty
                                  ? 'No areas available in this district'
                                  : 'Select Area (विभाग)',
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
                        bodyWards[selectedBodyId!] != null &&
                        bodyWards[selectedBodyId!]!.isNotEmpty)
                      InkWell(
                        onTap: () => _showWardSelectionModal(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Select Ward (वॉर्ड)',
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
                                          selectedWard!.wardId.toLowerCase(),
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
                              : const Text(
                                  'Select Ward (वॉर्ड)',
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
                                  ? 'Select area first'
                                  : bodyWards[selectedBodyId!] == null ||
                                        bodyWards[selectedBodyId!]!.isEmpty
                                  ? 'No wards available in this area'
                                  : 'Select Ward (वॉर्ड)',
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
                                    selectedWard!.wardId,
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
                              AppLocalizations.of(context)!.noCandidatesFound,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.noCandidatesFound} ${selectedWard!.name}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : selectedWard == null
                    ? Center(
                        child: Text(
                          AppLocalizations.of(
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
                          return _buildCandidateCard(context, candidate);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, candidate) {
    // Determine if candidate is premium
    bool isPremiumCandidate =
        candidate.sponsored || candidate.followersCount > 1000;

    return GestureDetector(
      onTap: () {
        // Navigate to candidate profile
        Get.toNamed('/candidate-profile', arguments: candidate);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Candidate Photo
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPremiumCandidate
                        ? Colors.blue.shade600
                        : Colors.grey.shade500,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: candidate.photo != null && candidate.photo!.isNotEmpty
                      ? Image.network(
                          candidate.photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              backgroundColor: isPremiumCandidate
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade500,
                              child: Text(
                                candidate.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            );
                          },
                        )
                      : CircleAvatar(
                          backgroundColor: isPremiumCandidate
                              ? Colors.blue.shade600
                              : Colors.grey.shade500,
                          child: Text(
                            candidate.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Candidate Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Party with Symbol
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            candidate.party,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Manifesto
                    if (candidate.manifesto != null &&
                        candidate.manifesto!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          candidate.manifesto!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9ca3af),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Premium/Free Badge
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPremiumCandidate
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPremiumCandidate
                              ? Colors.blue.shade300
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(
                        isPremiumCandidate ? 'Premium' : 'Free',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPremiumCandidate
                              ? Colors.blue.shade700
                              : Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Phone Number
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, color: Colors.green.shade600, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    candidate.contact.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
