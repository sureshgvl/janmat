import 'package:share_plus/share_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/models/achievements_model.dart';
import '../l10n/features/candidate/candidate_localizations.dart';
import '../utils/symbol_utils.dart';
import '../services/file_upload_service.dart';
import '../services/share_candidate_profile_service.dart';

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
      if (kIsWeb) {
        // On web, copy to clipboard instead of using Share API
        final url = await _generateWebShareUrl(candidate);
        await _copyToClipboard(url, 'Profile link copied to clipboard!');
      } else {
        // On mobile, use Share API
        final shareText = _generateProfileShareText(candidate);
        await Share.share(shareText);
      }
    } catch (e) {
      throw Exception('Failed to share profile: $e');
    }
  }

  /// Share candidate achievement with title, description, year and image
  static Future<void> shareAchievement({
    required Achievement achievement,
    required Candidate candidate,
    required BuildContext context,
  }) async {
    try {
      final shareText = _generateAchievementShareText(achievement, candidate);

      // Check if achievement has an image
      if (achievement.photoUrl != null && achievement.photoUrl!.isNotEmpty) {
        // Share with image - similar to manifesto PDF sharing
        await _shareAchievementWithImage(context, achievement, candidate, shareText);
      } else {
        // Share text only
        await Share.share(shareText);
      }
    } catch (e) {
      throw Exception('Failed to share achievement: $e');
    }
  }

  /// Share achievement with image download
  static Future<void> _shareAchievementWithImage(
    BuildContext context,
    Achievement achievement,
    Candidate candidate,
    String shareText,
  ) async {
    File? imageFile;

    try {
      // Check if the image is locally stored (from the achievement card display)
      final fileUploadService = FileUploadService();
      final isLocal = fileUploadService.isLocalPath(achievement.photoUrl!);

      if (kIsWeb) {
        // On web platform
        if (isLocal) {
          // Cannot share local files on web - fallback to text sharing
          await Share.share(shareText);
          return;
        } else {
          // Download and trigger download for remote images
          final response = await http.get(Uri.parse(achievement.photoUrl!));
          if (response.statusCode != 200) {
            throw Exception('Failed to download achievement image');
          }

          final blob = html.Blob([response.bodyBytes], 'image/jpeg');
          final url = html.Url.createObjectUrlFromBlob(blob);

          // Create filename from achievement title
          final safeTitle = achievement.title
              .replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), '_')
              .replaceAll(RegExp(r'\s+'), '_')
              .substring(0, achievement.title.length > 30 ? 30 : achievement.title.length);
          final fileName = '${safeTitle}_achievement.jpg';

          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();

          html.Url.revokeObjectUrl(url);
        }
      } else {
        // On Android/iOS platforms
        if (isLocal) {
          // Use the local file directly - no need to download
          final localPath = achievement.photoUrl!.replaceFirst('local:', '');
          imageFile = File(localPath);
          if (!await imageFile.exists()) {
            throw Exception('Local image file not found');
          }
        } else {
          // Download the image from Firebase URL
          final response = await http.get(Uri.parse(achievement.photoUrl!));
          if (response.statusCode != 200) {
            throw Exception('Failed to download achievement image');
          }

          // Get temporary directory
          final tempDir = await getTemporaryDirectory();

          // Create file name with achievement title
          final safeTitle = achievement.title
              .replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), '_') // Allow Unicode but replace special chars
              .replaceAll(RegExp(r'\s+'), '_')
              .substring(0, achievement.title.length > 30 ? 30 : achievement.title.length);
          final fileName = '${safeTitle}_achievement.jpg';
          final filePath = path.join(tempDir.path, fileName);

          // Save image to temporary file
          imageFile = File(filePath);
          await imageFile.writeAsBytes(response.bodyBytes);

          // For downloaded files, clean up after sharing
          Future.delayed(const Duration(seconds: 30), () async {
            try {
              if (await imageFile!.exists()) {
                await imageFile.delete();
              }
            } catch (e) {
              // Ignore cleanup errors
            }
          });
        }

        // Share the image file with text - Use proper display name
        final candidateDisplayName = candidate.basicInfo?.fullName ?? candidate.basicInfo!.fullName;
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: shareText,
          subject: '🏆 $candidateDisplayName - ${achievement.title}',
        );
      }

    } catch (e) {
      // Fallback to text sharing if image processing fails
      await Share.share(shareText);
      // Don't throw error here - let the calling method handle the success case
    }
  }

  /// Generate share text for candidate manifesto
  static String _generateManifestoShareText(Candidate candidate, BuildContext context) {
    final localizations = CandidateLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final StringBuffer buffer = StringBuffer();

    // Use localized manifesto text and display full name
    final candidateDisplayName = candidate.basicInfo?.fullName ?? 'candidate ';
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

    buffer.writeln('👤 ${candidate.basicInfo!.fullName}');
    buffer.writeln('🏛️ Party: ${candidate.party}');

    if (candidate.location.districtId?.isNotEmpty == true) {
      buffer.writeln('📍 Location: ${candidate.location.districtId}');
    }

    if (candidate.basicInfo?.age != null) {
      buffer.writeln('🎂 Age: ${candidate.basicInfo!.age}');
    }

    buffer.writeln();
    buffer.writeln('️ Get to know this candidate on Janmat!');
    buffer.writeln('Download the app to view complete profiles, manifestos, and connect with leaders.');

    return buffer.toString();
  }

  /// Generate share text for candidate achievement
  static String _generateAchievementShareText(Achievement achievement, Candidate candidate) {
    final StringBuffer buffer = StringBuffer();

    // Achievement header - Use proper display name (fullName or fallback to name)
    final candidateDisplayName = candidate.basicInfo?.fullName ?? 'candidate ';
    buffer.writeln('🏆 Achievement by $candidateDisplayName');

    // Achievement details
    if (achievement.title.isNotEmpty) {
      buffer.writeln('✨ "${achievement.title}"');
    }

    // Year
    if (achievement.year != null && achievement.year!.isNotEmpty) {
      buffer.writeln('📅 Year: ${achievement.year}');
    }

    buffer.writeln();

    // Achievement description
    if (achievement.description.isNotEmpty) {
      buffer.writeln(achievement.description);
      buffer.writeln();
    }

    // Call to action
    buffer.writeln('🌟 Experience this candidate\'s journey on Janmat!');
    buffer.writeln('View complete profile, achievements, and connect with leaders.');
    buffer.writeln('Download Janmat app now!');
    buffer.writeln('https://play.google.com/store/apps/details?id=com.janmat');

    return buffer.toString();
  }

  /// Generate web share URL for candidate profile
  static String _generateWebShareUrl(Candidate candidate) {
    // Import needed for accessing the service
    // Use the same ShareCandidateProfileService to generate the URL
    return ShareCandidateProfileService().generateFullProfileUrl(
      candidateId: candidate.candidateId,
      stateId: candidate.location.stateId! ,
      districtId: candidate.location.districtId!,
      bodyId: candidate.location.bodyId!,
      wardId: candidate.location.wardId!,
    );
  }

  /// Copy text to clipboard (web implementation)
  static Future<void> _copyToClipboard(String text, String successMessage) async {
    if (kIsWeb) {
      html.window.navigator.clipboard?.writeText(text);
      // For now, just show a simple success message
      // In a real app, you'd want to import a snackbar service
      html.window.alert(successMessage);
    }
  }
}
