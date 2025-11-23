import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/share_candidate_profile_service.dart';
import '../../utils/snackbar_utils.dart';

/// Simple share button for candidate profiles
class CandidateProfileShareButton extends StatelessWidget {
  final String candidateName;
  final String candidateId;
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;

  const CandidateProfileShareButton({
    super.key,
    required this.candidateName,
    required this.candidateId,
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: 'Share Profile',
      onPressed: () => _handleShare(context),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final url = ShareCandidateProfileService().generateFullProfileUrl(
        candidateId: candidateId,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      final subject = 'Check out $candidateName\'s candidate profile on Janmat';

      await Share.share(url, subject: subject);

      // Track the share
      ShareCandidateProfileService().trackShareEvent(
        candidateId: candidateId,
        shareMethod: 'native_sheet',
      );

    } catch (e) {
      SnackbarUtils.showError('Failed to share profile');
    }
  }
}

/// Floating Action Button style share button
class CandidateProfileShareFAB extends StatelessWidget {
  final String candidateName;
  final String candidateId;
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;

  const CandidateProfileShareFAB({
    super.key,
    required this.candidateName,
    required this.candidateId,
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handleShare(context),
      tooltip: 'Share Profile',
      child: const Icon(Icons.share),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      final url = ShareCandidateProfileService().generateFullProfileUrl(
        candidateId: candidateId,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );

      final subject = 'Check out $candidateName\'s candidate profile on Janmat';

      await Share.share(url, subject: subject);

      SnackbarUtils.showSuccess('Profile link shared successfully!');
    } catch (e) {
      SnackbarUtils.showError('Failed to share profile');
    }
  }
}
