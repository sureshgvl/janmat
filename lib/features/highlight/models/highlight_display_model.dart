// Model for displaying highlights in the home screen banner

class HomeHighlight {
  final String id;
  final String candidateId;
  final String candidateName;
  final String? candidatePhoto;
  final String? party;
  final String? wardInfo; // Using wardId as position info
  final String package; // 'gold' or 'platinum'
  final int viewCount;
  final DateTime createdAt;
  final bool isActive;
  final DateTime endDate; // For checking expiration
  // Add location fields for efficient candidate lookup
  final String stateId;
  final String districtId;
  final String bodyId;
  final String wardId;

  HomeHighlight({
    required this.id,
    required this.candidateId,
    required this.candidateName,
    this.candidatePhoto,
    this.party,
    this.wardInfo,
    required this.package,
    required this.viewCount,
    required this.createdAt,
    required this.isActive,
    required this.endDate,
    required this.stateId,
    required this.districtId,
    required this.bodyId,
    required this.wardId,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);

  factory HomeHighlight.fromHighlight(dynamic highlight) {
    // Work with Highlight from highlight_service.dart
    return HomeHighlight(
      id: highlight.id,
      candidateId: highlight.candidateId,
      candidateName: highlight.candidateName ?? 'Unknown Candidate',
      candidatePhoto: highlight.imageUrl, // Using imageUrl as candidatePhoto
      party: highlight.party,
      wardInfo: highlight.wardId, // Using wardId as position info
      package: highlight.package.toLowerCase(),
      viewCount: highlight.views,
      createdAt: highlight.startDate,
      isActive: highlight.active,
      endDate: highlight.endDate,
      stateId: highlight.stateId,
      districtId: highlight.districtId,
      bodyId: highlight.bodyId,
      wardId: highlight.wardId,
    );
  }
}
