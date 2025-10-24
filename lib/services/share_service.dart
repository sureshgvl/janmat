import 'package:share_plus/share_plus.dart';
import 'package:flutter/widgets.dart';
import '../features/candidate/models/candidate_model.dart';
import '../l10n/features/candidate/candidate_localizations.dart';
import '../utils/symbol_utils.dart';

/// Service for handling sharing functionality across the app
class ShareService {
  /// Share candidate manifesto with text content
  static Future<void> shareCandidateManifesto(Candidate candidate, BuildContext context) async {
    try {
      final shareText = _generateManifestoShareText(candidate, context);
      await Share.share(shareText);
    } catch (e) {
      throw Exception('Failed to share manifesto: $e');
    }
  }

  /// Share candidate profile with basic information
  static Future<void> shareCandidateProfile(Candidate candidate) async {
    try {
      final shareText = _generateProfileShareText(candidate);
      await Share.share(shareText);
    } catch (e) {
      throw Exception('Failed to share profile: $e');
    }
  }

  /// Generate share text for candidate manifesto
  static String _generateManifestoShareText(Candidate candidate, BuildContext context) {
    final localizations = CandidateLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final StringBuffer buffer = StringBuffer();

    // Use localized manifesto text and display full name
    final candidateDisplayName = candidate.basicInfo?.fullName ?? candidate.name;
    buffer.writeln('📋 $candidateDisplayName - ${localizations.manifesto}');

    // Use SymbolUtils to get full localized party name
    final partyFullName = SymbolUtils.getPartyNameLocal(candidate.party, locale);
    buffer.writeln('🏛️ Party: $partyFullName');

    // Location info - show ward name and body name
    final wardName = candidate.location.wardId?.isNotEmpty == true ? candidate.location.wardId : null;
    final bodyName = candidate.location.bodyId?.isNotEmpty == true ? candidate.location.bodyId : null;

    if (wardName != null || bodyName != null) {
      final locationParts = [bodyName, wardName].where((part) => part != null).join(', ');
      buffer.writeln('📍 Location: $locationParts');
    }

    buffer.writeln();

    // Manifesto title
    if (candidate.manifestoData?.title != null &&
        candidate.manifestoData!.title!.isNotEmpty) {
      buffer.writeln('📄 ${candidate.manifestoData!.title}');
      buffer.writeln();
    }

    // Manifesto promises (first 3)
    final promises = candidate.manifestoData?.promises ?? [];
    if (promises.isNotEmpty) {
      buffer.writeln('Key Promises:');
      final displayPromises = promises.take(3); // Limit to 3 promises
      for (var i = 0; i < displayPromises.length; i++) {
        final promise = displayPromises.elementAt(i);
        final title = promise['title'] as String? ?? '';
        buffer.writeln('${i + 1}. $title');
      }

      if (promises.length > 3) {
        buffer.writeln('...and ${promises.length - 3} more promises');
      }
      buffer.writeln();
    }

    // Call to action with Play Store link
    buffer.writeln('🗳️ Learn more about $candidateDisplayName\'s vision for our community!');
    buffer.writeln('Download Janmat app to explore complete manifestos and connect with candidates.');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.janmat');

    return buffer.toString();
  }



  /// Generate share text for candidate profile
  static String _generateProfileShareText(Candidate candidate) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('👤 ${candidate.name}');
    buffer.writeln('🏛️ Party: ${candidate.party}');

    if (candidate.location.districtId?.isNotEmpty == true) {
      buffer.writeln('📍 Location: ${candidate.location.districtId}');
    }

    if (candidate.basicInfo?.age != null) {
      buffer.writeln('🎂 Age: ${candidate.basicInfo!.age}');
    }

    buffer.writeln();
    buffer.writeln('�️ Get to know this candidate on Janmat!');
    buffer.writeln('Download the app to view complete profiles, manifestos, and connect with leaders.');

    return buffer.toString();
  }
}
