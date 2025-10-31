import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_logger.dart';
import '../../candidate/models/location_model.dart';

class Highlight {
  final String id;
  final String candidateId;
  final LocationModel location; // Unified location model with stateId
  final String locationKey; // Composite key: district_body_ward
  final String package;
  final List<String> placement;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final bool active;
  final bool exclusive;
  final bool rotation;
  final DateTime? lastShown;
  final int views;
  final int clicks;
  final String? imageUrl;
  final String? candidateName;
  final String? party;
  final DateTime createdAt;
  final String status; // 'active', 'expired', 'inactive', 'pending'
  final DateTime? expiredAt;
  final int renewalCount;
  final DateTime? lastRenewedAt;

  Highlight({
    required this.id,
    required this.candidateId,
    required this.location,
    required this.locationKey,
    required this.package,
    required this.placement,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.exclusive,
    required this.rotation,
    this.lastShown,
    required this.views,
    required this.clicks,
    this.imageUrl,
    this.candidateName,
    this.party,
    required this.createdAt,
    this.status = 'active', // Default to active for backward compatibility
    this.expiredAt,
    this.renewalCount = 0,
    this.lastRenewedAt,
  });

  // Backward compatibility getters
  String get wardId => location.wardId ?? '';
  String get districtId => location.districtId ?? '';
  String get bodyId => location.bodyId ?? '';
  String get stateId => location.stateId ?? 'maharashtra';

  factory Highlight.fromJson(Map<String, dynamic> json) {
    // Debug logging for active field
    final activeValue = json['active'];
    AppLogger.common('🔍 [Highlight.fromJson] Document ${json['highlightId']}: active field = $activeValue (type: ${activeValue?.runtimeType})');

    return Highlight(
      id: json['highlightId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      location: LocationModel.fromJson(json),
      locationKey: json['locationKey'] ?? '',
      package: json['package'] ?? '',
      placement: List<String>.from(json['placement'] ?? []),
      priority: json['priority'] ?? 1,
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: json['active'] ?? false,
      exclusive: json['exclusive'] ?? false,
      rotation: json['rotation'] ?? true,
      lastShown: (json['lastShown'] as Timestamp?)?.toDate(),
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      imageUrl: json['imageUrl'],
      candidateName: json['candidateName'],
      party: json['party'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: json['status'] ?? 'active', // Default to active for backward compatibility
      expiredAt: (json['expiredAt'] as Timestamp?)?.toDate(),
      renewalCount: json['renewalCount'] ?? 0,
      lastRenewedAt: (json['lastRenewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Location model fields
      ...location.toJson(),
      // Legacy fields for backward compatibility
      'wardId': location.wardId,
      'districtId': location.districtId,
      'bodyId': location.bodyId,
      // Other fields
      'highlightId': id,
      'candidateId': candidateId,
      'locationKey': locationKey,
      'package': package,
      'placement': placement,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'active': active,
      'exclusive': exclusive,
      'rotation': rotation,
      'lastShown': lastShown != null ? Timestamp.fromDate(lastShown!) : null,
      'views': views,
      'clicks': clicks,
      'imageUrl': imageUrl,
      'candidateName': candidateName,
      'party': party,
      'createdAt': Timestamp.fromDate(createdAt),
      // New lifecycle management fields
      'status': status,
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'renewalCount': renewalCount,
      'lastRenewedAt': lastRenewedAt != null ? Timestamp.fromDate(lastRenewedAt!) : null,
    };
  }

  Highlight copyWith({
    String? id,
    String? candidateId,
    LocationModel? location,
    String? locationKey,
    String? package,
    List<String>? placement,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    bool? exclusive,
    bool? rotation,
    DateTime? lastShown,
    int? views,
    int? clicks,
    String? imageUrl,
    String? candidateName,
    String? party,
    DateTime? createdAt,
    String? status,
    DateTime? expiredAt,
    int? renewalCount,
    DateTime? lastRenewedAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      candidateId: candidateId ?? this.candidateId,
      location: location ?? this.location,
      locationKey: locationKey ?? this.locationKey,
      package: package ?? this.package,
      placement: placement ?? this.placement,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      exclusive: exclusive ?? this.exclusive,
      rotation: rotation ?? this.rotation,
      lastShown: lastShown ?? this.lastShown,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      imageUrl: imageUrl ?? this.imageUrl,
      candidateName: candidateName ?? this.candidateName,
      party: party ?? this.party,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      expiredAt: expiredAt ?? this.expiredAt,
      renewalCount: renewalCount ?? this.renewalCount,
      lastRenewedAt: lastRenewedAt ?? this.lastRenewedAt,
    );
  }
}
