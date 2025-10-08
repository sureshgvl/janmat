import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/candidate_model.dart';
import '../../controllers/candidate_controller.dart';
import '../../../../utils/symbol_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/maharashtra_utils.dart';
import '../../../../services/local_database_service.dart';
import '../../../../services/share_service.dart';
import '../../../../models/district_model.dart';
import '../../../../models/ward_model.dart';
import '../../../../utils/app_logger.dart';

class ProfileTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final bool
  showVoterInteractions; // New parameter to control voter interactions

  const ProfileTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
    this.showVoterInteractions =
        true, // Default to true for backward compatibility
  });

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Like functionality state
  bool _isProfileLiked = false;
  int _profileLikes = 0;

  // Location display state
  String? _districtName;
  String? _wardDisplayName;
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    // Initialize with some mock data - in real app this would come from server
    _profileLikes = widget.candidate.followersCount ?? 0;

    // Load location data
    _loadLocationData();
  }

  // Load location data from cache or fallback to utils
  Future<void> _loadLocationData() async {
    AppLogger.candidate('🔍 [Profile Tab] Loading location data for candidate ${widget.candidate.candidateId}');
    AppLogger.candidate('📍 [Profile Tab] IDs: district=${widget.candidate.districtId}, body=${widget.candidate.bodyId}, ward=${widget.candidate.wardId}');

    try {
      // Load location data from SQLite cache
      final locationData = await _locationDatabase.getCandidateLocationData(
        widget.candidate.districtId,
        widget.candidate.bodyId,
        widget.candidate.wardId,
        widget.candidate.stateId,
      );

      // Check if ward data is missing (most likely to be missing)
      if (locationData['wardName'] == null) {
        AppLogger.candidate('⚠️ [Profile Tab] Ward data not found in cache, triggering sync...');

        // Trigger background sync for missing location data
        await _syncMissingLocationData();

        // Try loading again after sync
        final updatedLocationData = await _locationDatabase.getCandidateLocationData(
          widget.candidate.districtId,
          widget.candidate.bodyId,
          widget.candidate.wardId,
          widget.candidate.stateId,
        );

        if (mounted) {
          setState(() {
            _districtName = updatedLocationData['districtName'];
            _wardDisplayName = updatedLocationData['wardName'];
          });
        }

        AppLogger.candidate('✅ [Profile Tab] Location data loaded after sync:');
        AppLogger.candidate('   📍 District: $_districtName');
        AppLogger.candidate('   🏛️ Ward: $_wardDisplayName');
      } else {
        if (mounted) {
          setState(() {
            _districtName = locationData['districtName'];
            _wardDisplayName = locationData['wardName'];
          });
        }

        AppLogger.candidate('✅ [Profile Tab] Location data loaded successfully from SQLite:');
        AppLogger.candidate('   📍 District: $_districtName');
        AppLogger.candidate('   🏛️ Ward: $_wardDisplayName');
      }
    } catch (e) {
      AppLogger.candidateError('❌ [Profile Tab] Error loading location data: $e');

      // Fallback to ID-based display if sync fails
      if (mounted) {
        setState(() {
          _districtName = widget.candidate.districtId;
          _wardDisplayName = 'Ward ${widget.candidate.wardId}';
        });
      }
    }
  }

  // Fallback method using MaharashtraUtils for localization
  void _loadLocationDataFromUtils() {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    // Get district name from utils
    final districtName = MaharashtraUtils.getDistrictDisplayNameWithLocale(
      widget.candidate.districtId,
      languageCode,
    );

    // Get ward display name (extract number and format)
    final wardNumber = MaharashtraUtils.getWardNumber(widget.candidate.wardId);
    String wardDisplayName;
    if (wardNumber != null) {
      wardDisplayName = languageCode == 'mr'
          ? 'वॉर्ड $wardNumber'
          : 'Ward $wardNumber';
    } else {
      wardDisplayName = widget.candidate.wardId; // Fallback
    }

    if (mounted) {
      setState(() {
        _districtName = districtName;
        _wardDisplayName = wardDisplayName;
      });
    }
  }

  // Sync missing location data from Firebase to SQLite
  Future<void> _syncMissingLocationData() async {
    try {
      AppLogger.candidate('🔄 [Profile Tab] Syncing missing location data...');

      // Import candidate repository dynamically to avoid circular imports
      final candidateRepository = Get.find<CandidateController>().candidateRepository;

      // Sync district data if missing
      if (_districtName == null) {
        AppLogger.candidate('🏙️ [Sync] Fetching district data for ${widget.candidate.districtId}');
        final districts = await candidateRepository.getAllDistricts();
        final district = districts.firstWhere(
          (d) => d.id == widget.candidate.districtId,
          orElse: () => District(
            id: widget.candidate.districtId,
            name: widget.candidate.districtId,
            stateId: widget.candidate.stateId ?? 'maharashtra', // Use candidate's actual state ID
          ),
        );
        await _locationDatabase.insertDistricts([district]);
        AppLogger.candidate('✅ [Sync] District data synced');
      }

      // Sync ward data (most critical)
      if (_wardDisplayName == null) {
        AppLogger.candidate('🏛️ [Sync] Fetching ward data for ${widget.candidate.wardId}');
        final wards = await candidateRepository.getWardsByDistrictAndBody(
          widget.candidate.districtId,
          widget.candidate.bodyId,
        );
        final ward = wards.firstWhere(
          (w) => w.id == widget.candidate.wardId,
          orElse: () => Ward(
            id: widget.candidate.wardId,
            name: 'Ward ${widget.candidate.wardId}',
            districtId: widget.candidate.districtId,
            bodyId: widget.candidate.bodyId,
            stateId: widget.candidate.stateId ?? 'maharashtra', // Use candidate's actual state ID
          ),
        );
        await _locationDatabase.insertWards([ward]);
        AppLogger.candidate('✅ [Sync] Ward data synced');

        // Reload location data after sync
        final updatedLocationData = await _locationDatabase.getCandidateLocationData(
          widget.candidate.districtId,
          widget.candidate.bodyId,
          widget.candidate.wardId,
          widget.candidate.stateId,
        );

        if (mounted) {
          setState(() {
            _districtName = updatedLocationData['districtName'];
            _wardDisplayName = updatedLocationData['wardName'];
          });
        }
      }

      AppLogger.candidate('✅ [Profile Tab] Location data sync completed');
    } catch (e) {
      AppLogger.candidateError('❌ [Profile Tab] Error syncing location data: $e');
      // Fallback to utils-based localization
      _loadLocationDataFromUtils();
    }
  }

  void _toggleProfileLike() {
    setState(() {
      _isProfileLiked = !_isProfileLiked;
      _profileLikes += _isProfileLiked ? 1 : -1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isProfileLiked ? AppLocalizations.of(context)!.profileLiked : AppLocalizations.of(context)!.profileUnliked),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareProfile() async {
    try {
      await ShareService.shareCandidateProfile(widget.candidate);
      Get.snackbar(
        'share'.tr,
        'Profile shared successfully!',
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'share'.tr,
        'Failed to share profile. Please try again.',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Photo and Basic Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.candidate.photo != null
                          ? NetworkImage(widget.candidate.photo!)
                          : null,
                      child: widget.candidate.photo == null
                          ? Text(
                              widget.candidate.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Candidate Name - Full width
                          Text(
                            widget.candidate.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Party Information
                          Row(
                            children: [
                              if (widget.candidate.party.toLowerCase().contains(
                                    'independent',
                                  ) ||
                                  widget.candidate.party.trim().isEmpty)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: const Icon(
                                    Icons.label,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: SymbolUtils.getSymbolImageProvider(
                                        SymbolUtils.getPartySymbolPath(
                                          widget.candidate.party,
                                          candidate: widget.candidate,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.candidate.party
                                                  .toLowerCase()
                                                  .contains('independent') ||
                                              widget.candidate.party
                                                  .trim()
                                                  .isEmpty
                                          ? AppLocalizations.of(context)!.party_independent
                                          : SymbolUtils.getPartyFullNameWithLocale(
                                              widget.candidate.party,
                                              Localizations.localeOf(context).languageCode,
                                            ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            SymbolUtils.getPartyFullName(widget.candidate.party)
                                                    .toLowerCase()
                                                    .contains('independent') ||
                                                widget.candidate.party
                                                    .trim()
                                                    .isEmpty
                                            ? Colors.grey.shade700
                                            : Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.candidate.symbolName != null &&
                                        widget.candidate.symbolName!.isNotEmpty)
                                      Text(
                                        AppLocalizations.of(context)!.symbolLabel(widget.candidate.symbolName!),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Like Count and Interactive Buttons - At the end
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like Count - Always visible
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _profileLikes.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_profileLikes == 1)
                            Text(
                              AppLocalizations.of(context)!.like,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            )
                          else
                            Text(
                              AppLocalizations.of(context)!.likes,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Interactive Like and Share buttons - Only for voters
                    if (widget.showVoterInteractions)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Like Button
                          GestureDetector(
                            onTap: _toggleProfileLike,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isProfileLiked
                                    ? Colors.red.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isProfileLiked
                                      ? Colors.red.shade200
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Icon(
                                _isProfileLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color: _isProfileLiked
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Share Button
                          GestureDetector(
                            onTap: _shareProfile,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                ),
                              ),
                              child: const Icon(
                                Icons.share,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Basic Information Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.basicInformation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Age and Gender
                if (widget.candidate.extraInfo?.basicInfo?.age != null ||
                    widget.candidate.extraInfo?.basicInfo?.gender != null) ...[
                  Row(
                    children: [
                      if (widget.candidate.extraInfo?.basicInfo?.age != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.age,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.candidate.extraInfo!.basicInfo!.age}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.candidate.extraInfo?.basicInfo?.age != null &&
                          widget.candidate.extraInfo?.basicInfo?.gender != null)
                        const SizedBox(width: 12),
                      if (widget.candidate.extraInfo?.basicInfo?.gender != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.gender,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget
                                      .candidate
                                      .extraInfo!
                                      .basicInfo!
                                      .gender!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Education
                if (widget.candidate.extraInfo?.basicInfo?.education !=
                    null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.education,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.candidate.extraInfo!.basicInfo!.education!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Address
                if (widget.candidate.extraInfo?.contact?.address != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.candidate.extraInfo!.contact!.address!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Location Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.location,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.district,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _districtName ?? widget.candidate.districtId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.ward,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.pink.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _wardDisplayName ?? widget.candidate.wardId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

