import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String? stateId;
  final String? districtId;
  final String? bodyId;
  final String? wardId;

  const LocationModel({
    this.stateId,
    this.districtId,
    this.bodyId,
    this.wardId,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      stateId: json['stateId'] as String?,
      districtId: json['districtId'] as String?,
      bodyId: json['bodyId'] as String?,
      wardId: json['wardId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (stateId != null) 'stateId': stateId,
      if (districtId != null) 'districtId': districtId,
      if (bodyId != null) 'bodyId': bodyId,
      if (wardId != null) 'wardId': wardId,
    };
  }

  LocationModel copyWith({
    String? stateId,
    String? districtId,
    String? bodyId,
    String? wardId,
  }) {
    return LocationModel(
      stateId: stateId ?? this.stateId,
      districtId: districtId ?? this.districtId,
      bodyId: bodyId ?? this.bodyId,
      wardId: wardId ?? this.wardId,
    );
  }

  @override
  List<Object?> get props => [stateId, districtId, bodyId, wardId];

  factory LocationModel.empty() {
    return const LocationModel();
  }
}