import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String pollId;
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final Map<String, String> userVotes;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  Poll({
    required this.pollId,
    required this.question,
    required this.options,
    required this.votes,
    required this.userVotes,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    DateTime? expiresAt;
    if (json['expiresAt'] is Timestamp) {
      expiresAt = (json['expiresAt'] as Timestamp).toDate();
    } else if (json['expiresAt'] is String) {
      expiresAt = DateTime.parse(json['expiresAt']);
    }

    return Poll(
      pollId: json['pollId'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      votes: Map<String, int>.from(json['votes'] ?? {}),
      userVotes: Map<String, String>.from(json['userVotes'] ?? {}),
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pollId': pollId,
      'question': question,
      'options': options,
      'votes': votes,
      'userVotes': userVotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
    };
  }

  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  int get totalVotes {
    return votes.values.fold(0, (sum, count) => sum + count);
  }

  double getVotePercentage(String option) {
    if (totalVotes == 0) return 0.0;
    return (votes[option] ?? 0) / totalVotes;
  }

  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get expirationStatus {
    if (expiresAt == null) return 'No expiration';
    if (isExpired) return 'Expired';
    final remaining = timeRemaining!;
    if (remaining.inDays > 0) return '${remaining.inDays} days left';
    if (remaining.inHours > 0) return '${remaining.inHours} hours left';
    if (remaining.inMinutes > 0) return '${remaining.inMinutes} minutes left';
    return 'Expires soon';
  }

  Poll copyWith({
    String? pollId,
    String? question,
    List<String>? options,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return Poll(
      pollId: pollId ?? this.pollId,
      question: question ?? this.question,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }
}