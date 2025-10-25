import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/candidate_model.dart';
import '../../../controllers/candidate_controller.dart';
import '../../../../../utils/symbol_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../services/local_database_service.dart';
import '../../../../../services/share_service.dart';
import '../../../../../models/district_model.dart';
import '../../../../../models/ward_model.dart';
import '../../../../../utils/app_logger.dart';

class ProfileTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final bool showVoterInteractions;

  const ProfileTabView({
    super.key,
    required this.candidate,
    this.isOwnProfile = false,
    this.showVoterInteractions = true,
  });

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isProfileLiked = false;
  int _profileLikes = 0;
  String? _districtName;
  String? _wardDisplayName;
  final LocalDatabaseService _locationDatabase = LocalDatabaseService();

  @override
  void initState() {
    super.initState();
    _profileLikes = widget.candidate.followersCount ?? 0;
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    AppLogger.candidate('🔍 [Profile Tab] Loading location data for candidate ${widget.candidate.candidateId}');
    AppLogger.candidate('📍 [Profile Tab] IDs: district=${widget.candidate.location.districtId}, body=${widget.candidate.location.bodyId}, ward=${widget.candidate.location.wardId}');

    try {
      final locationData = await _locationDatabase.getCandidateLocationData(
        widget.candidate.location.districtId ?? '',
        widget.candidate.location.bodyId ?? '',
        widget.candidate.location.wardId ?? '',
        widget.candidate.location.stateId ?? 'maharashtra',
      );

      if (locationData['wardName'] == null) {
        AppLogger.candidate('⚠️ [Profile Tab] Ward data not found in cache, triggering sync...');
        await _syncMissingLocationData();
        final updatedLocationData = await _locationDatabase.getCandidateLocationData(
          widget.candidate.location.districtId ?? '',
          widget.candidate.location.bodyId ?? '',
          widget.candidate.location.wardId ?? '',
          widget.candidate.location.stateId ?? 'maharashtra',
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
      if (mounted) {
        setState(() {
          _districtName = widget.candidate.location.districtId;
          _wardDisplayName = 'Ward ${widget.candidate.location.wardId}';
        });
      }
    }
  }

  Future<void> _syncMissingLocationData() async {
    try {
      AppLogger.candidate('🔄 [Profile Tab] Syncing missing location data...');
      final candidateRepository = Get.find<CandidateController>().candidateRepository;

      if (_districtName == null) {
        AppLogger.candidate('🏙️ [Sync] Fetching district data for ${widget.candidate.location.districtId}');
        final districts = await candidateRepository.getAllDistricts();
        final district = districts.firstWhere(
          (d) => d.id == widget.candidate.location.districtId,
          orElse: () => District(
            id: widget.candidate.location.districtId ?? '',
            name: widget.candidate.location.districtId ?? '',
            stateId: widget.candidate.location.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertDistricts([district]);
        AppLogger.candidate('✅ [Sync] District data synced');
      }

      if (_wardDisplayName == null) {
        AppLogger.candidate('🏛️ [Sync] Fetching ward data for ${widget.candidate.location.wardId}');
        final wards = await candidateRepository.getWardsByDistrictAndBody(
          widget.candidate.location.districtId ?? '',
          widget.candidate.location.bodyId ?? '',
        );
        final ward = wards.firstWhere(
          (w) => w.id == widget.candidate.location.wardId,
          orElse: () => Ward(
            id: widget.candidate.location.wardId ?? '',
            name: 'Ward ${widget.candidate.location.wardId ?? ''}',
            districtId: widget.candidate.location.districtId ?? '',
            bodyId: widget.candidate.location.bodyId ?? '',
            stateId: widget.candidate.location.stateId ?? 'maharashtra',
          ),
        );
        await _locationDatabase.insertWards([ward]);
        AppLogger.candidate('✅ [Sync] Ward data synced');

        final updatedLocationData = await _locationDatabase.getCandidateLocationData(
          widget.candidate.location.districtId ?? '',
          widget.candidate.location.bodyId ?? '',
          widget.candidate.location.wardId ?? '',
          widget.candidate.location.stateId ?? 'maharashtra',
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
    }
  }

  void _toggleProfileLike() {
    setState(() {
      _isProfileLiked = !_isProfileLiked;
      _profileLikes += _isProfileLiked ? 1 : -1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isProfileLiked
            ? AppLocalizations.of(context)!.profileLiked
            : AppLocalizations.of(context)!.profileUnliked),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1e3a8a).withValues(alpha: 0.05),
            const Color(0xFF3b82f6).withValues(alpha: 0.03),
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFf8fafc),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFe2e8f0).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3b82f6).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366f1).withValues(alpha: 0.06),
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
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade100.withValues(alpha: 0.3),
                              Colors.purple.shade100.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          backgroundImage: widget.candidate.photo != null
                              ? NetworkImage(widget.candidate.photo!)
                              : null,
                          child: widget.candidate.photo == null
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.purple.shade400,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.candidate.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Candidate Name
                            Text(
                              widget.candidate.basicInfo!.fullName!,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1f2937),
                                shadows: const [
                                  Shadow(
                                    color: Color.fromRGBO(37, 99, 235, 0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Party Information
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: widget.candidate.party.toLowerCase().contains('independent') ||
                                            widget.candidate.party.trim().isEmpty
                                        ? Icon(
                                            Icons.label,
                                            size: 26,
                                            color: Colors.grey.shade600,
                                          )
                                        : Image.asset(
                                            SymbolUtils.getPartySymbolPath(
                                              widget.candidate.party,
                                              candidate: widget.candidate,
                                            ),
                                            fit: BoxFit.contain,
                                            width: 32,
                                            height: 32,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.candidate.party.toLowerCase().contains('independent') ||
                                                widget.candidate.party.trim().isEmpty
                                            ? AppLocalizations.of(context)!.party_independent
                                            : SymbolUtils.getPartyFullNameWithLocale(
                                                widget.candidate.party,
                                                Localizations.localeOf(context).languageCode,
                                              ),
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: widget.candidate.party.toLowerCase().contains('independent') ||
                                                  widget.candidate.party.trim().isEmpty
                                              ? Colors.grey.shade700
                                              : const Color(0xFF3b82f6),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      if (widget.candidate.symbolName != null &&
                                          widget.candidate.symbolName!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            AppLocalizations.of(context)!.symbolLabel(widget.candidate.symbolName!),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
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

                  // Like Count and Interactive Buttons
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Like Count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.shade50,
                              Colors.pink.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 18,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _profileLikes.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1f2937),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _profileLikes == 1
                                  ? AppLocalizations.of(context)!.like
                                  : AppLocalizations.of(context)!.likes,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _isProfileLiked
                                        ? [Colors.red.shade100, Colors.red.shade50]
                                        : [Colors.grey.shade100, Colors.grey.shade50],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _isProfileLiked
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.grey.withValues(alpha: 0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isProfileLiked
                                          ? Colors.red.withValues(alpha: 0.2)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isProfileLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: _isProfileLiked ? Colors.red.shade700 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Share Button
                            GestureDetector(
                              onTap: _shareProfile,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue.shade100,
                                      Colors.blue.shade50,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.share,
                                  size: 18,
                                  color: Color(0xFF3b82f6),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFf8fafc),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFe2e8f0).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
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
                  if (widget.candidate.basicInfo?.age != null ||
                      widget.candidate.basicInfo?.gender != null) ...[
                    Row(
                      children: [
                        if (widget.candidate.basicInfo?.age != null)
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
                                    '${widget.candidate.basicInfo!.age}',
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
                        if (widget.candidate.basicInfo?.age != null &&
                            widget.candidate.basicInfo?.gender != null)
                          const SizedBox(width: 12),
                        if (widget.candidate.basicInfo?.gender != null)
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
                                    widget.candidate.basicInfo!.gender!,
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
                  if (widget.candidate.basicInfo?.education != null) ...[
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
                            widget.candidate.basicInfo!.education!,
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
                  if (widget.candidate.contact?.address != null) ...[
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
                            widget.candidate.contact!.address!,
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFf8fafc),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFe2e8f0).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.shade50,
                              Colors.pink.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: Colors.red.shade600,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.indigo.shade50,
                                Colors.indigo.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.indigo.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: Colors.indigo.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.district,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _districtName ?? (widget.candidate.location.districtId ?? ''),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1f2937),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.pink.shade50,
                                Colors.pink.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.pink.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_city,
                                    size: 16,
                                    color: Colors.pink.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.ward,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.pink.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _wardDisplayName ?? (widget.candidate.location.wardId ?? ''),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1f2937),
                                  letterSpacing: 0.2,
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
      ),
    );
  }
}
