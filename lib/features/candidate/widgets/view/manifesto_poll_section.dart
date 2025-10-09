import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../../services/manifesto_poll_service.dart';
import '../../../../utils/advanced_analytics.dart' as analytics;

class ManifestoPollSection extends StatefulWidget {
  final String? manifestoId;
  final String? currentUserId;

  const ManifestoPollSection({
    super.key,
    required this.manifestoId,
    required this.currentUserId,
  });

  @override
  State<ManifestoPollSection> createState() => _ManifestoPollSectionState();
}

class _ManifestoPollSectionState extends State<ManifestoPollSection> {
  bool _isPollLoading = false;
  String? _pollError;
  Stream<Map<String, int>>? _pollResultsStream;
  Stream<String?>? _userVoteStream;

  @override
  void initState() {
    super.initState();
    if (widget.manifestoId != null && widget.currentUserId != null) {
      _pollResultsStream = ManifestoPollService.getPollResultsStream(widget.manifestoId!);
      _userVoteStream = Stream.fromFuture(
        ManifestoPollService.getUserVote(widget.manifestoId!, widget.currentUserId!)
      );
    }
  }

  Future<void> _selectPollOption(String option) async {
    if (widget.currentUserId == null) {
      Get.snackbar(
        'error'.tr,
        'pleaseLoginToInteract'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    if (widget.manifestoId == null) return;

    setState(() {
      _isPollLoading = true;
      _pollError = null;
    });

    try {
      await ManifestoPollService.voteOnPoll(widget.manifestoId!, widget.currentUserId!, option);

      // Track poll vote analytics
      analytics.AdvancedAnalyticsManager().trackUserInteraction(
        'poll_vote',
        'manifesto_tab',
        elementId: widget.manifestoId,
        metadata: {
          'option': option,
          'user_id': widget.currentUserId,
        },
      );

      Get.snackbar(
        'thankYou'.tr,
        'voteRecorded'.tr,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
        maxWidth: 300,
      );
    } catch (e) {
      setState(() {
        _pollError = e.toString();
      });
      Get.snackbar(
        'error'.tr,
        'failedToRecordVote'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isPollLoading = false;
      });
    }
  }

  Widget _buildPollOption(String optionKey, String optionText, Map<String, int> pollResults, String? userVote) {
    final isSelected = userVote == optionKey;
    final voteCount = pollResults[optionKey] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: (_isPollLoading) ? null : () => _selectPollOption(optionKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (voteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$voteCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CandidateTranslations.tr('whatIssueMattersMost'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (_pollResultsStream != null && _userVoteStream != null)
          StreamBuilder<Map<String, int>>(
            stream: _pollResultsStream,
            builder: (context, resultsSnapshot) {
              return StreamBuilder<String?>(
                stream: _userVoteStream,
                builder: (context, userVoteSnapshot) {
                  final pollResults = resultsSnapshot.data ?? {};
                  final userVote = userVoteSnapshot.data;

                  return Column(
                    children: [
                      _buildPollOption(
                        'development',
                        CandidateTranslations.tr('developmentInfrastructure'),
                        pollResults,
                        userVote,
                      ),
                      _buildPollOption(
                        'transparency',
                        CandidateTranslations.tr('transparencyGovernance'),
                        pollResults,
                        userVote,
                      ),
                      _buildPollOption(
                        'youth_education',
                        CandidateTranslations.tr('youthEducation'),
                        pollResults,
                        userVote,
                      ),
                      _buildPollOption(
                        'women_safety',
                        CandidateTranslations.tr('womenSafety'),
                        pollResults,
                        userVote,
                      ),
                    ],
                  );
                },
              );
            },
          )
        else
          const Center(child: Text('Poll not available')),
        if (_pollError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _pollError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

