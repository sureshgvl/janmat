import 'dart:html' as html;
import '../utils/app_logger.dart';
import '../core/app_route_names.dart';
import 'public_candidate_service.dart';
import 'package:get/get.dart';
import 'dart:async';

class UniversalGuestService {
  Future<Map<String, dynamic>?> checkGuestUrl() async {
    try {
      // DEBUG: Log initial URL state
      AppLogger.common('🔍 GUEST ROUTING DEBUG: Window.location.hash = "${html.window.location.hash}"');
      AppLogger.common('🔍 GUEST ROUTING DEBUG: Window.location.pathname = "${html.window.location.pathname}"');
      AppLogger.common('🔍 GUEST ROUTING DEBUG: Window.location.href = "${html.window.location.href}"');

      // Try hash-based routing first (for in-app navigation)
      String path = html.window.location.hash ?? '';
      if (path.isEmpty || !path.startsWith('#/candidate/')) {
        AppLogger.common('🔍 GUEST ROUTING DEBUG: Trying direct path routing...');
        // Try direct path routing (for direct URL access)
        path = html.window.location.pathname ?? '';
        if (path.isEmpty || !path.startsWith('/candidate/')) {
          AppLogger.common('🔍 GUEST ROUTING DEBUG: No valid candidate path found, returning null');
          return null;
        }
      } else {
        // Remove '#' from hash-based URLs
        path = path.substring(1);
        AppLogger.common('🔍 GUEST ROUTING DEBUG: Using hash-based routing: $path');
      }

      AppLogger.common('🔍 GUEST ROUTING DEBUG: Parsed path: $path');

      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      AppLogger.common('🔍 GUEST ROUTING DEBUG: Path segments: $segments');

      // Pattern: candidate/stateId/districtId/bodyId/wardId/candidateId
      if (segments.length < 6 || segments[0] != 'candidate') {
        AppLogger.common('🔍 GUEST ROUTING DEBUG: Seg ments length ${segments.length}, first segment "${segments.isNotEmpty ? segments[0] : 'none'}" - not a valid candidate URL');
        return null;
      }

      final urlParams = PublicCandidateUrlParams(
        stateId: segments[1],
        districtId: segments[2],
        bodyId: segments[3],
        wardId: segments[4],
        candidateId: segments[5],
      );

      AppLogger.common('🔍 Detected guest candidate URL: ${urlParams.toString()}');

      // Validate that the location path exists (prevents showing errors for bad URLs)
      AppLogger.common('🔍 GUEST ROUTING DEBUG: Validating location path...');
      final pathExists = await PublicCandidateService().validateLocationPath(
        stateId: urlParams.stateId,
        districtId: urlParams.districtId,
        bodyId: urlParams.bodyId,
        wardId: urlParams.wardId,
      );

      if (!pathExists) {
        AppLogger.common('❌ Guest URL location path does not exist: ${urlParams.toString()}');
        return null; // Location doesn't exist - let normal auth flow handle
      }

      AppLogger.common('✅ GUEST ROUTING DEBUG: Validation passed, returning guest route data');

      // Return guest routing data
      return {
        'isGuestAccess': true,
        'initialRoute': AppRouteNames.publicCandidateProfile,
        'candidateParams': urlParams,
      };

    } catch (e, stackTrace) {
      AppLogger.common('⚠️ Guest URL check failed: $e $stackTrace');
      return null;
    }
  }

  void navigateToGuestRoute(PublicCandidateUrlParams params) {
    try {
      AppLogger.common('🚀 Navigating to guest candidate profile: ${params.candidateId}');

      // Pass the URL parameters to the next screen
      Get.offAllNamed(
        AppRouteNames.publicCandidateProfile,
        arguments: params,
      );

      // Track guest view for analytics
      unawaited(
        PublicCandidateService().trackGuestProfileView(
          candidateId: params.candidateId,
          source: 'direct_url',
        ),
      );

    } catch (e) {
      AppLogger.common('❌ Guest navigation failed: $e');
      // Fallback to login if navigation fails
      Get.offAllNamed(AppRouteNames.login);
    }
  }
}

/// Data class for public candidate URL parameters
class PublicCandidateUrlParams {
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;
  final String candidateId;

  PublicCandidateUrlParams({
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
    required this.candidateId,
  });

  bool get isValid =>
      stateId.isNotEmpty &&
      districtId.isNotEmpty &&
      bodyId.isNotEmpty &&
      wardId.isNotEmpty &&
      candidateId.isNotEmpty;

  @override
  String toString() =>
      'state: $stateId, district: $districtId, body: $bodyId, ward: $wardId, candidate: $candidateId';
}
