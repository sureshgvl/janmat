import '../../../utils/app_logger.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Manages message reactions
class MessageReactionManager {
  final ChatRepository _repository = ChatRepository();

  /// Add reaction to message
  Future<void> addReaction(
    String roomId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    await _repository.addReactionToMessage(roomId, messageId, userId, emoji);
    AppLogger.chat('MessageReactionManager: Added reaction $emoji to message $messageId');
  }
}
