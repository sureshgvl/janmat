import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../features/common/whatsapp_image_viewer.dart';
import '../../../utils/symbol_utils.dart';
import '../models/candidate_model.dart';

class CandidateComparisonScreen extends StatefulWidget {
  final List<Candidate> candidates;

  const CandidateComparisonScreen({
    super.key,
    required this.candidates,
  });

  @override
  State<CandidateComparisonScreen> createState() => _CandidateComparisonScreenState();
}

class _CandidateComparisonScreenState extends State<CandidateComparisonScreen> {
  int _currentPairIndex = 0;

  List<Candidate> get candidates => widget.candidates;

  bool get hasMultiplePairs => candidates.length > 2;

  List<Candidate> get currentPair {
    if (candidates.length == 2) return candidates;
    final startIndex = _currentPairIndex * 2;
    return candidates.sublist(startIndex, (startIndex + 2).clamp(0, candidates.length));
  }

  void _nextPair() {
    if (_currentPairIndex < (candidates.length / 2).floor() - 1) {
      setState(() => _currentPairIndex++);
    }
  }

  void _previousPair() {
    if (_currentPairIndex > 0) {
      setState(() => _currentPairIndex--);
    }
  }

  Candidate get candidate1 => currentPair[0];
  Candidate get candidate2 => currentPair.length > 1 ? currentPair[1] : currentPair[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: hasMultiplePairs
            ? Text(CandidateLocalizations.of(context)!.comparingCandidates(count: candidates.length))
            : Text(CandidateLocalizations.of(context)!.candidateComparison),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: hasMultiplePairs ? [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPairIndex > 0 ? _previousPair : null,
          ),
          Text(CandidateLocalizations.of(context)!.pairOfTotal(current: _currentPairIndex + 1, total: (candidates.length / 2).ceil())),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPairIndex < (candidates.length / 2).floor() - 1 ? _nextPair : null,
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasMultiplePairs || candidates.length == 2
                          ? CandidateLocalizations.of(context)!.comparingPair(first: candidate1.basicInfo!.fullName!, second: candidate2.basicInfo!.fullName!)
                          : CandidateLocalizations.of(context)!.comparingCandidates(count: candidates.length),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Comparison Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            CandidateLocalizations.of(context)!.metric,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            candidate1.basicInfo!.fullName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            candidate2.basicInfo!.fullName!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Photo Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.photo,
                    _buildPhotoWidget(candidate1, context),
                    _buildPhotoWidget(candidate2, context),
                  ),

                  // Name Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.name,
                    Text(
                      candidate1.basicInfo!.fullName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.basicInfo!.fullName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Party Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.party,
                    _buildPartyDisplay(candidate1, context),
                    _buildPartyDisplay(candidate2, context),
                  ),

                  // Followers Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.followers,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate1.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('👥'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate2.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('👥'),
                      ],
                    ),
                  ),

                  // Education Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.education,
                    Text(
                      candidate1.basicInfo?.education ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.basicInfo?.education ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Age Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.age,
                    Text(
                      candidate1.basicInfo?.age?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.basicInfo?.age?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Manifesto Points Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.manifestoPoints,
                    Text(
                      candidate1.manifestoData?.promises?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.manifestoData?.promises?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Achievements Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.achievements,
                    Text(
                      candidate1.achievements?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.achievements?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Likes Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.likes,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate1.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('❤️'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          candidate2.followersCount.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Text('❤️'),
                      ],
                    ),
                  ),

                  // Events Attended Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.eventsAttended,
                    Text(
                      candidate1.events?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.events?.length.toString() ?? '0',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Profile Views Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.profileViews,
                    Text(
                      candidate1.analytics?.profileViews?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.analytics?.profileViews?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Manifesto Views Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.manifestoViews,
                    Text(
                      candidate1.analytics?.manifestoViews?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.analytics?.manifestoViews?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Contact Clicks Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.contactClicks,
                    Text(
                      candidate1.analytics?.contactClicks?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.analytics?.contactClicks?.toString() ?? CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Engagement Rate Row
                  _buildComparisonRow(
                    CandidateLocalizations.of(context)!.engagementRate,
                    Text(
                      candidate1.analytics?.engagementRate != null
                          ? '${candidate1.analytics!.engagementRate!.toStringAsFixed(1)}%'
                          : CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      candidate2.analytics?.engagementRate != null
                          ? '${candidate2.analytics!.engagementRate!.toStringAsFixed(1)}%'
                          : CandidateLocalizations.of(context)!.notSpecified,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: currentPair.map((candidate) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.toNamed('/candidate-profile', arguments: candidate);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6), // Blue color
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile Picture
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: ClipOval(
                              child: candidate.basicInfo!.photo != null && candidate.basicInfo!.photo!.isNotEmpty
                                  ? Image.network(
                                      candidate.basicInfo!.photo!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return CircleAvatar(
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          child: Text(
                                            candidate.basicInfo!.fullName![0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      child: Text(
                                        candidate.basicInfo!.fullName![0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Name
                          Flexible(
                            child: Text(
                              candidate.basicInfo!.fullName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String metric, Widget value1, Widget value2) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: value1,
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: value2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoWidget(Candidate candidate, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (candidate.basicInfo!.photo != null && candidate.basicInfo!.photo!.isNotEmpty) {
          // Use existing WhatsApp-like image viewer
          Get.to(() => WhatsAppImageViewer(
            imageUrl: candidate.basicInfo!.photo!,
            title: candidate.basicInfo!.fullName,
          ));
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipOval(
          child: candidate.basicInfo!.photo != null && candidate.basicInfo!.photo!.isNotEmpty
              ? Image.network(
                  candidate.basicInfo!.photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        candidate.basicInfo!.fullName![0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    );
                  },
                )
              : CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    candidate.basicInfo!.fullName![0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPartyDisplay(Candidate candidate, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Party Symbol
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
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
        // Party Name
        Flexible(
          child: Text(
            SymbolUtils.getPartyDisplayNameWithLocale(
              candidate.party,
              Localizations.localeOf(context).languageCode,
            ),
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

