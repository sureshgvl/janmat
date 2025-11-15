import 'media_model.dart';

// Base class for engagement operations
abstract class EngagementOperation {
  final DateTime timestamp;
  final String operationId;

  EngagementOperation()
      : timestamp = DateTime.now(),
        operationId = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toJson();
}

// Like/Unlike operation
class LikeOperation extends EngagementOperation {
  final MediaItem item;
  final bool liked;
  final String userId;
  final Map<String, String> userInfo;

  LikeOperation({
    required this.item,
    required this.liked,
    required this.userId,
    required this.userInfo,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'like',
      'operationId': operationId,
      'timestamp': timestamp.toIso8601String(),
      'itemTitle': item.title,
      'itemDate': item.date,
      'liked': liked,
      'userId': userId,
      'userInfo': userInfo,
    };
  }
}

// Comment operation
class CommentOperation extends EngagementOperation {
  final MediaItem item;
  final String text;
  final String userId;
  final Map<String, String> userInfo;

  CommentOperation({
    required this.item,
    required this.text,
    required this.userId,
    required this.userInfo,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'comment',
      'operationId': operationId,
      'timestamp': timestamp.toIso8601String(),
      'itemTitle': item.title,
      'itemDate': item.date,
      'text': text,
      'userId': userId,
      'userInfo': userInfo,
    };
  }
}
