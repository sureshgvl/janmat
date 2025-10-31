// Enhanced Highlight Configuration Model
// Follows Single Responsibility Principle - handles only highlight configuration data

class HighlightConfig {
  bool enabled;
  String bannerStyle;
  String bannerImageUrl;
  String callToAction;
  String priorityLevel;
  List<String> targetLocations;
  bool showAnalytics;
  String customMessage;
  String title;
  DateTime? endDate;

  HighlightConfig({
    this.enabled = false,
    this.bannerStyle = 'premium',
    this.bannerImageUrl = '',
    this.callToAction = 'View Profile',
    this.priorityLevel = 'normal',
    this.targetLocations = const [],
    this.showAnalytics = false,
    this.customMessage = '',
    this.title = '',
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bannerStyle': bannerStyle,
      'image_url': bannerImageUrl, // Save as image_url to match existing data structure
      'callToAction': callToAction,
      'priority': priorityLevel,
      'targetLocations': targetLocations,
      'showAnalytics': showAnalytics,
      'message': customMessage,
      'title': title,
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory HighlightConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HighlightConfig();
    return HighlightConfig(
      enabled: json['enabled'] ?? false,
      bannerStyle: json['bannerStyle'] ?? 'premium',
      bannerImageUrl: json['bannerImageUrl'] ?? json['image_url'] ?? '',
      callToAction: json['callToAction'] ?? 'View Profile',
      priorityLevel: json['priorityLevel'] ?? json['priority'] ?? 'normal',
      targetLocations: List<String>.from(json['targetLocations'] ?? []),
      showAnalytics: json['showAnalytics'] ?? false,
      customMessage: json['customMessage'] ?? json['message'] ?? '',
      title: json['title'] ?? '',
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  HighlightConfig copyWith({
    bool? enabled,
    String? bannerStyle,
    String? bannerImageUrl,
    String? callToAction,
    String? priorityLevel,
    List<String>? targetLocations,
    bool? showAnalytics,
    String? customMessage,
    String? title,
    DateTime? endDate,
  }) {
    return HighlightConfig(
      enabled: enabled ?? this.enabled,
      bannerStyle: bannerStyle ?? this.bannerStyle,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      callToAction: callToAction ?? this.callToAction,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      targetLocations: targetLocations ?? this.targetLocations,
      showAnalytics: showAnalytics ?? this.showAnalytics,
      customMessage: customMessage ?? this.customMessage,
      title: title ?? this.title,
      endDate: endDate ?? this.endDate,
    );
  }
}
