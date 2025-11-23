import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../features/candidate/models/candidate_model.dart';
import '../utils/snackbar_utils.dart';

/// Service for generating and sharing candidate profile URLs
class ShareCandidateProfileService {
  static final ShareCandidateProfileService _instance = ShareCandidateProfileService._internal();
  factory ShareCandidateProfileService() => _instance;
  ShareCandidateProfileService._internal();

  /// Generate relative URL path for candidate profile
  /// Format: /candidate/stateId/districtId/bodyId/wardId/candidateId
  String generateProfilePath({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    return '/candidate/$stateId/$districtId/$bodyId/$wardId/$candidateId';
  }

  /// Generate full web URL for sharing
  /// Format: https://janmat-official.web.app/candidate/stateId/districtId/bodyId/wardId/candidateId
  String generateFullProfileUrl({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
    String? baseUrl,
  }) {
    final path = generateProfilePath(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    final domain = baseUrl ?? 'https://janmat-official.web.app';
    return '$domain$path';
  }

  /// Generate share URL from candidate data
  String generateUrlFromCandidate(Candidate candidate) {
    final location = candidate.location;
    return generateProfilePath(
      candidateId: candidate.candidateId,
      stateId: location.stateId ?? 'maharashtra',
      districtId: location.districtId ?? '',
      bodyId: location.bodyId ?? '',
      wardId: location.wardId ?? '',
    );
  }

  /// Generate share message for WhatsApp/SMS
  String generateShareMessage({
    required String candidateName,
    required String profileUrl,
  }) {
    return '''
📋 Check out this candidate profile on Janmat!

👤 $candidateName
🔗 $profileUrl

Vote wisely, stay informed! 🇮🇳
'''.trim();
  }

  /// Copy share URL to clipboard
  Future<void> copyShareUrlToClipboard({
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    final url = generateFullProfileUrl(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    await Share.share(url, subject: 'Janmat Candidate Profile');
    SnackbarUtils.showSuccess('Profile link copied to clipboard!');
  }

  /// Share via WhatsApp
  Future<void> shareViaWhatsApp({
    required String candidateName,
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    final profileUrl = generateFullProfileUrl(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    final message = generateShareMessage(
      candidateName: candidateName,
      profileUrl: profileUrl,
    );

    final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(message)}';

    try {
      if (await url_launcher.canLaunchUrl(Uri.parse(whatsappUrl))) {
        await url_launcher.launchUrl(Uri.parse(whatsappUrl));
      } else {
        await copyShareUrlToClipboard(
          candidateId: candidateId,
          stateId: stateId,
          districtId: districtId,
          bodyId: bodyId,
          wardId: wardId,
        );
        SnackbarUtils.showInfo('WhatsApp not available. Link copied to clipboard.');
      }
    } catch (e) {
      await copyShareUrlToClipboard(
        candidateId: candidateId,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
      SnackbarUtils.showInfo('Sharing failed. Link copied to clipboard.');
    }
  }

  /// Share via native share sheet
  Future<void> shareViaNativeSheet({
    required String candidateName,
    required String candidateId,
    required String stateId,
    required String districtId,
    required String bodyId,
    required String wardId,
  }) async {
    final profileUrl = generateFullProfileUrl(
      candidateId: candidateId,
      stateId: stateId,
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    final subject = 'Check out $candidateName\'s candidate profile';

    try {
      await Share.share(profileUrl, subject: subject);
    } catch (e) {
      await copyShareUrlToClipboard(
        candidateId: candidateId,
        stateId: stateId,
        districtId: districtId,
        bodyId: bodyId,
        wardId: wardId,
      );
    }
  }

  /// Track share analytics
  Future<void> trackShareEvent({
    required String candidateId,
    required String shareMethod,
    String? referrer,
  }) async {
    if (kDebugMode) {
      print('📊 Share tracked: candidate=$candidateId, method=$shareMethod');
    }
  }
}
