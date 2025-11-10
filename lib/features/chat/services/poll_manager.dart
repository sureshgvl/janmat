import 'dart:async';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../models/poll.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../../notifications/services/poll_notification_service.dart';

/// Service responsible for poll creation and management
/// Handles poll lifecycle, voting, and notifications
class PollManager {
  final ChatRepository _repository = ChatRepository();

  /// Create a new poll in a chat room
  Future<Poll?> createPoll({
    required String roomId,
    required String question,
    required List<String> options,
    required String creatorId,
    required String creatorName,
    DateTime? expiresAt,
  }) async {
    try {
      AppLogger.chat('PollManager: Creating poll "$question" with ${options.length} options');

      // Validate input
      if (question.trim().isEmpty) {
        throw Exception('Poll question cannot be empty');
      }
      if (options.length < 2) {
        throw Exception('Poll must have at least 2 options');
      }
      if (options.any((option) => option.trim().isEmpty)) {
        throw Exception('Poll options cannot be empty');
      }

      // Create poll object
      final pollId = DateTime.now().millisecondsSinceEpoch.toString();
      final poll = Poll(
        pollId: pollId,
        question: question.trim(),
        options: options.map((option) => option.trim()).toList(),
        votes: {},
        userVotes: {},
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        isActive: true,
      );

      // Save poll to repository
      await _repository.createPoll(roomId, poll);
      AppLogger.chat('PollManager: Poll created successfully: $pollId');

      // Send notifications to room members
      await _notifyPollCreated(roomId, pollId, creatorId, question);

      return poll;

    } catch (e) {
      AppLogger.chat('PollManager: Error creating poll: $e');
      SnackbarUtils.showError('Failed to create poll. Please try again.');
      return null;
    }
  }

  /// Vote on a poll option
  Future<bool> voteOnPoll({
    required String roomId,
    required String pollId,
    required String userId,
    required int optionIndex,
  }) async {
    try {
      AppLogger.chat('PollManager: User $userId voting on poll $pollId, option $optionIndex');

      // Get current poll data
      final poll = await getPoll(roomId, pollId);
      if (poll == null) {
        throw Exception('Poll not found');
      }

      // Check if poll is still active
      if (!poll.isActive) {
        SnackbarUtils.showInfo('This poll has ended');
        return false;
      }

      // Check if poll has expired
      if (poll.expiresAt != null && DateTime.now().isAfter(poll.expiresAt!)) {
        SnackbarUtils.showInfo('This poll has expired');
        return false;
      }

      // Check if user already voted
      if (poll.userVotes.containsKey(userId)) {
        SnackbarUtils.showInfo('You have already voted on this poll');
        return false;
      }

      // Validate option index
      if (optionIndex < 0 || optionIndex >= poll.options.length) {
        throw Exception('Invalid option index');
      }

      // Use repository's voteOnPoll method
      final optionText = poll.options[optionIndex];
      await _repository.voteOnPoll(pollId, userId, optionText);

      AppLogger.chat('PollManager: Vote recorded successfully');
      SnackbarUtils.showSuccess('Your vote has been recorded!');
      return true;

    } catch (e) {
      AppLogger.chat('PollManager: Error voting on poll: $e');
      SnackbarUtils.showError('Failed to record vote. Please try again.');
      return false;
    }
  }

  /// Get poll data by finding it in the stream
  Future<Poll?> getPoll(String roomId, String pollId) async {
    try {
      // Get the polls stream and find the specific poll
      final pollsStream = _repository.getPollsForRoom(roomId);
      final polls = await pollsStream.first; // Get first emission
      for (final poll in polls) {
        if (poll.pollId == pollId) {
          return poll;
        }
      }
      return null;
    } catch (e) {
      AppLogger.chat('PollManager: Error getting poll: $e');
      return null;
    }
  }

  /// Get all polls for a room (returns stream, so we convert to future)
  Future<List<Poll>> getPollsForRoom(String roomId) async {
    try {
      final pollsStream = _repository.getPollsForRoom(roomId);
      return await pollsStream.first; // Get first emission
    } catch (e) {
      AppLogger.chat('PollManager: Error getting polls for room: $e');
      return [];
    }
  }

  /// Check if a user has voted on a poll
  bool hasUserVoted(Poll poll, String userId) {
    return poll.userVotes.containsKey(userId);
  }

  /// Get the option index a user voted for
  int? getUserVote(Poll poll, String userId) {
    final vote = poll.userVotes[userId];
    if (vote != null && vote.isNotEmpty) {
      return int.tryParse(vote);
    }
    return null;
  }

  /// Get vote count for a specific option
  int getVoteCount(Poll poll, int optionIndex) {
    if (optionIndex < 0 || optionIndex >= poll.options.length) {
      return 0;
    }
    return poll.votes[poll.options[optionIndex]] ?? 0;
  }

  /// Get total votes for a poll
  int getTotalVotes(Poll poll) {
    return poll.votes.values.fold(0, (sum, count) => sum + count);
  }

  /// Check if poll is expired
  bool isPollExpired(Poll poll) {
    return poll.expiresAt != null && DateTime.now().isAfter(poll.expiresAt!);
  }

  /// Check if poll is active
  bool isPollActive(Poll poll) {
    return poll.isActive && !isPollExpired(poll);
  }

  /// End a poll manually (admin function) - Note: This requires repository support
  Future<bool> endPoll(String roomId, String pollId) async {
    // TODO: Implement when repository supports poll updates
    AppLogger.chat('PollManager: endPoll not implemented - requires repository update support');
    return false;
  }

  /// Send notifications when a poll is created
  Future<void> _notifyPollCreated(
    String roomId,
    String pollId,
    String creatorId,
    String question,
  ) async {
    try {
      final pollNotificationService = PollNotificationService();
      await pollNotificationService.notifyNewPollCreated(
        roomId: roomId,
        pollId: pollId,
        creatorId: creatorId,
        pollQuestion: question,
      );
      AppLogger.chat('PollManager: Poll creation notifications sent');
    } catch (e) {
      AppLogger.chat('PollManager: Failed to send poll notifications: $e');
      // Don't fail poll creation if notifications fail
    }
  }

  /// Create poll message for chat
  Message createPollMessage(Poll poll, String senderId) {
    return Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📊 ${poll.question}',
      senderId: senderId,
      type: 'poll',
      createdAt: DateTime.now(),
      readBy: [senderId],
      metadata: {'pollId': poll.pollId},
    );
  }

  /// Get poll results as formatted text
  String getPollResultsText(Poll poll) {
    final buffer = StringBuffer();
    buffer.writeln('📊 ${poll.question}');
    buffer.writeln();

    final totalVotes = getTotalVotes(poll);

    for (int i = 0; i < poll.options.length; i++) {
      final option = poll.options[i];
      final votes = getVoteCount(poll, i);
      final percentage = totalVotes > 0 ? (votes / totalVotes * 100).round() : 0;

      buffer.writeln('$option: $votes votes (${percentage}%)');
    }

    buffer.writeln();
    buffer.write('Total votes: $totalVotes');

    if (poll.expiresAt != null) {
      buffer.write(' • Expires: ${_formatDateTime(poll.expiresAt!)}');
    }

    return buffer.toString();
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}
