import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/app_route_names.dart';
import 'public_candidate_service.dart';
import '../utils/app_logger.dart';
import 'package:get/get.dart';

// Dynamic import - only loads the appropriate implementation per platform
import 'universal_guest_service.dart'
    if (dart.library.html) 'universal_guest_service.dart'
    if (dart.library.io) 'universal_guest_service_stub.dart';

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

/// Handles guest routing logic for public candidate profile access
/// Keeps guest routing completely separate from authenticated user flows
class GuestRoutingService {
  static final GuestRoutingService _instance = GuestRoutingService._internal();
  factory GuestRoutingService() => _instance;
  GuestRoutingService._internal();

  /// Check if current URL is a valid guest candidate URL and return routing data
  Future<Map<String, dynamic>?> checkGuestUrl() async {
    try {
      // Only check URLs on web platform
      if (!kIsWeb) {
        AppLogger.common('📱 Mobile platform - guest URL features disabled');
        return null;
      }

      // Use the dynamically imported service
      final service = UniversalGuestService();
      return await service.checkGuestUrl();
    } catch (e, stackTrace) {
      AppLogger.common('⚠️ Guest URL check failed: $e $stackTrace');
      return null;
    }
  }

  /// Navigate to guest route with parameters
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

  /// Helper to determine if user came via guest URL (for UI adjustments)
  static bool isCurrentlyInGuestMode() {
    // Check if we're on the public profile route
    return Get.currentRoute == AppRouteNames.publicCandidateProfile;
  }
}
