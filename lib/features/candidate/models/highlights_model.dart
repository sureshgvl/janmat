import 'package:equatable/equatable.dart';

class HighlightData extends Equatable {
  final bool enabled;
  final String? title;
  final String? message;
  final String? imageUrl;
  final String? priority;
  final String? expiresAt;

  // Banner configuration fields
  final String? bannerStyle;
  final String? callToAction;
  final String? priorityLevel;
  final List<String>? targetLocations;
  final bool? showAnalytics;
  final String? customMessage;

  const HighlightData({
    required this.enabled,
    this.title,
    this.message,
    this.imageUrl,
    this.priority,
    this.expiresAt,
    // Banner config fields
    this.bannerStyle,
    this.callToAction,
    this.priorityLevel,
    this.targetLocations,
    this.showAnalytics,
    this.customMessage,
  });

  factory HighlightData.fromJson(Map<String, dynamic> json) {
    return HighlightData(
      enabled: json['enabled'] ?? false,
      title: json['title'],
      message: json['message'],
      imageUrl: json['image_url'],
      priority: json['priority'],
      expiresAt: json['expires_at'],
      // Banner config fields
      bannerStyle: json['bannerStyle'] ?? json['banner_style'],
      callToAction: json['callToAction'] ?? json['call_to_action'],
      priorityLevel: json['priorityLevel'] ?? json['priority_level'],
      targetLocations: json['targetLocations'] != null
          ? List<String>.from(json['targetLocations'])
          : null,
      showAnalytics: json['showAnalytics'] ?? json['show_analytics'],
      customMessage: json['customMessage'] ?? json['custom_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'priority': priority,
      'expires_at': expiresAt,
      // Banner config fields
      'bannerStyle': bannerStyle,
      'callToAction': callToAction,
      'priorityLevel': priorityLevel,
      'targetLocations': targetLocations,
      'showAnalytics': showAnalytics,
      'customMessage': customMessage,
    };
  }

  HighlightData copyWith({
    bool? enabled,
    String? title,
    String? message,
    String? imageUrl,
    String? priority,
    String? expiresAt,
    String? bannerStyle,
    String? callToAction,
    String? priorityLevel,
    List<String>? targetLocations,
    bool? showAnalytics,
    String? customMessage,
  }) {
    return HighlightData(
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
      expiresAt: expiresAt ?? this.expiresAt,
      bannerStyle: bannerStyle ?? this.bannerStyle,
      callToAction: callToAction ?? this.callToAction,
      priorityLevel: priorityLevel ?? this.priorityLevel,
      targetLocations: targetLocations ?? this.targetLocations,
      showAnalytics: showAnalytics ?? this.showAnalytics,
      customMessage: customMessage ?? this.customMessage,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        title,
        message,
        imageUrl,
        priority,
        expiresAt,
        bannerStyle,
        callToAction,
        priorityLevel,
        targetLocations,
        showAnalytics,
        customMessage,
      ];
}

class HighlightsModel extends Equatable {
  final List<HighlightData>? highlights;

  const HighlightsModel({
    this.highlights,
  });

  factory HighlightsModel.fromJson(Map<String, dynamic> json) {
    return HighlightsModel(
      highlights: json['highlights'] != null
          ? (json['highlights'] as List<dynamic>)
              .map((item) => HighlightData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (highlights != null)
        'highlights': highlights!.map((h) => h.toJson()).toList(),
    };
  }

  HighlightsModel copyWith({
    List<HighlightData>? highlights,
  }) {
    return HighlightsModel(
      highlights: highlights ?? this.highlights,
    );
  }

  // Getters for backward compatibility
  int get length => highlights?.length ?? 0;
  bool get isNotEmpty => highlights?.isNotEmpty ?? false;
  bool get isEmpty => highlights?.isEmpty ?? true;
  HighlightData? operator [](int index) => highlights?[index];

  @override
  List<Object?> get props => [highlights];
}
