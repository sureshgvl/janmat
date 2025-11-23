/// Mobile stub implementation that does nothing
/// Prevents dart:html dependencies from affecting mobile builds
class UniversalGuestService {
  Future<Map<String, dynamic>?> checkGuestUrl() async => null;
  void navigateToGuestRoute(dynamic params) {}
}

/// Mobile stub for URL parameters (not used on mobile)
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

  bool get isValid => false; // Always false for mobile
}
