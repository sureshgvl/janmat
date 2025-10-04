// Enhanced Highlight Configuration Model
// Follows Single Responsibility Principle - handles only highlight configuration data

class HighlightConfig {
  bool enabled;
  String bannerStyle;
  String callToAction;
  String priorityLevel;
  List<String> targetLocations;
  bool showAnalytics;
  String customMessage;

  HighlightConfig({
    this.enabled = false,
    this.bannerStyle = 'premium',
    this.callToAction = 'View Profile',
    this.priorityLevel = 'normal',
    this.targetLocations = const [],
    this.showAnalytics = false,
    this.customMessage = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'bannerStyle': bannerStyle,
      'callToAction': callToAction,
      'priorityLevel': priorityLevel,
      'targetLocations': targetLocations,
      'showAnalytics': showAnalytics,
      'customMessage': customMessage,
    };
  }

  factory HighlightConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HighlightConfig();
    return HighlightConfig(
      enabled: json['enabled'] ?? false,
      bannerStyle: json['bannerStyle'] ?? 'premium',
      callToAction: json['callToAction'] ?? 'View Profile',
      priorityLevel: json['priorityLevel'] ?? 'normal',
      targetLocations: List<String>.from(json['targetLocations'] ?? []),
      showAnalytics: json['showAnalytics'] ?? false,
      customMessage: json['customMessage'] ?? '',
    );
  }

  HighlightConfig copyWith({
    bool? enabled,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    List<String>? targetLocations,
    bool? showAnalytics,
    String? customMessage,
  }) {
    return HighlightConfig(
      enabled: enabled ?? this.enabled,
      bannerStyle: bannerStyle ?? this.bannerStyle,
      callToAction: callToAction ?? this.callToAction,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      targetLocations: targetLocations ?? this.targetLocations,
      showAnalytics: showAnalytics ?? this.showAnalytics,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}

