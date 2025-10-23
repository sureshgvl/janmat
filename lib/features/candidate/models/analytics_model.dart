import 'package:equatable/equatable.dart';

class AnalyticsModel extends Equatable {
  final int? profileViews;
  final int? manifestoViews;
  final int? contactClicks;
  final int? socialMediaClicks;
  final Map<String, int>? locationViews;
  final DateTime? lastUpdated;
  final double? engagementRate;
  final int? manifestoComments;
  final Map<String, dynamic>? demographics;

  const AnalyticsModel({
    this.profileViews,
    this.manifestoViews,
    this.contactClicks,
    this.socialMediaClicks,
    this.locationViews,
    this.lastUpdated,
    this.engagementRate,
    this.manifestoComments,
    this.demographics,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsModel(
      profileViews: json['profileViews'] as int?,
      manifestoViews: json['manifestoViews'] as int?,
      contactClicks: json['contactClicks'] as int?,
      socialMediaClicks: json['socialMediaClicks'] as int?,
      locationViews: json['locationViews'] != null
          ? Map<String, int>.from(json['locationViews'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'].toString())
          : null,
      engagementRate: json['engagementRate'] != null
          ? (json['engagementRate'] as num).toDouble()
          : null,
      manifestoComments: json['manifestoComments'] as int?,
      demographics: json['demographics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (profileViews != null) 'profileViews': profileViews,
      if (manifestoViews != null) 'manifestoViews': manifestoViews,
      if (contactClicks != null) 'contactClicks': contactClicks,
      if (socialMediaClicks != null) 'socialMediaClicks': socialMediaClicks,
      if (locationViews != null) 'locationViews': locationViews,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
      if (engagementRate != null) 'engagementRate': engagementRate,
      if (manifestoComments != null) 'manifestoComments': manifestoComments,
      if (demographics != null) 'demographics': demographics,
    };
  }

  AnalyticsModel copyWith({
    int? profileViews,
    int? manifestoViews,
    int? contactClicks,
    int? socialMediaClicks,
    Map<String, int>? locationViews,
    DateTime? lastUpdated,
    double? engagementRate,
    int? manifestoComments,
    Map<String, dynamic>? demographics,
  }) {
    return AnalyticsModel(
      profileViews: profileViews ?? this.profileViews,
      manifestoViews: manifestoViews ?? this.manifestoViews,
      contactClicks: contactClicks ?? this.contactClicks,
      socialMediaClicks: socialMediaClicks ?? this.socialMediaClicks,
      locationViews: locationViews ?? this.locationViews,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      engagementRate: engagementRate ?? this.engagementRate,
      manifestoComments: manifestoComments ?? this.manifestoComments,
      demographics: demographics ?? this.demographics,
    );
  }

  @override
  List<Object?> get props => [
        profileViews,
        manifestoViews,
        contactClicks,
        socialMediaClicks,
        locationViews,
        lastUpdated,
        engagementRate,
        manifestoComments,
        demographics,
      ];
}
