import 'package:cloud_firestore/cloud_firestore.dart';

class HighlightBannerData {
  final String highlightId;
  final String candidateId;
  final String candidateName;
  final String? candidateParty;
  final String? candidateProfileImageUrl;
  final String? bannerStyle;
  final String? callToAction;
  final String? customMessage;
  final String? priorityLevel;
  final DateTime createdAt;

  const HighlightBannerData({
    required this.highlightId,
    required this.candidateId,
    required this.candidateName,
    this.candidateParty,
    this.candidateProfileImageUrl,
    this.bannerStyle,
    this.callToAction,
    this.customMessage,
    this.priorityLevel,
    required this.createdAt,
  });

  factory HighlightBannerData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HighlightBannerData(
      highlightId: doc.id,
      candidateId: data['candidateId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      candidateParty: data['party'],
      candidateProfileImageUrl: data['imageUrl'],
      bannerStyle: data['bannerStyle'],
      callToAction: data['callToAction'],
      customMessage: data['customMessage'],
      priorityLevel: data['priorityLevel'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': highlightId,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'party': candidateParty,
      'imageUrl': candidateProfileImageUrl,
      'bannerStyle': bannerStyle,
      'callToAction': callToAction,
      'customMessage': customMessage,
      'priorityLevel': priorityLevel,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class HighlightBannerState {
  final bool isLoading;
  final HighlightBannerData? bannerData;
  final String? error;

  const HighlightBannerState({
    this.isLoading = false,
    this.bannerData,
    this.error,
  });

  HighlightBannerState copyWith({
    bool? isLoading,
    HighlightBannerData? bannerData,
    String? error,
  }) {
    return HighlightBannerState(
      isLoading: isLoading ?? this.isLoading,
      bannerData: bannerData ?? this.bannerData,
      error: error ?? this.error,
    );
  }
}