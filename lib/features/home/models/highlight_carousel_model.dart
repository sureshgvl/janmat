import 'package:cloud_firestore/cloud_firestore.dart';

class HighlightCarouselItem {
  final String highlightId;
  final String candidateId;
  final String candidateName;
  final String? candidateParty;
  final String? imageUrl;
  final int priority;
  final DateTime createdAt;

  const HighlightCarouselItem({
    required this.highlightId,
    required this.candidateId,
    required this.candidateName,
    this.candidateParty,
    this.imageUrl,
    required this.priority,
    required this.createdAt,
  });

  factory HighlightCarouselItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HighlightCarouselItem(
      highlightId: doc.id,
      candidateId: data['candidateId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      candidateParty: data['party'],
      imageUrl: data['imageUrl'],
      priority: data['priority'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': highlightId,
      'candidateId': candidateId,
      'candidateName': candidateName,
      'party': candidateParty,
      'imageUrl': imageUrl,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class HighlightCarouselState {
  final bool isLoading;
  final List<HighlightCarouselItem> items;
  final int currentPage;
  final String? error;

  const HighlightCarouselState({
    this.isLoading = false,
    this.items = const [],
    this.currentPage = 0,
    this.error,
  });

  HighlightCarouselState copyWith({
    bool? isLoading,
    List<HighlightCarouselItem>? items,
    int? currentPage,
    String? error,
  }) {
    return HighlightCarouselState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }

  bool get hasItems => items.isNotEmpty;
  bool get shouldAutoScroll => items.length > 1;
}