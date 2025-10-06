import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../features/chat/models/poll.dart';
import '../../../features/chat/repositories/chat_repository.dart';
import '../models/notification_type.dart';
import 'notification_manager.dart';

/// Service for handling poll-related notifications
class PollNotificationService {
  final NotificationManager _notificationManager = NotificationManager();
  final ChatRepository _chatRepository = ChatRepository();

  /// Notify users when a new poll is created in a chat room
  Future<void> notifyNewPollCreated({
    required String roomId,
    required String pollId,
    required String creatorId,
    required String pollQuestion,
  }) async {
    try {
      // Get room information to determine who should be notified
      final room = await _getRoomInfo(roomId);
      if (room == null) return;

      // Get list of users who should be notified (room members)
      final targetUserIds = await _getRoomMemberIds(roomId, excludeUserId: creatorId);
      if (targetUserIds.isEmpty) return;

      // Create notification for each user
      for (final userId in targetUserIds) {
        await _notificationManager.createNotification(
          type: NotificationType.newPoll,
          title: 'New Poll in ${room.title}',
          body: '"$pollQuestion"',
          data: {
            'pollId': pollId,
            'roomId': roomId,
            'roomTitle': room.title,
            'creatorId': creatorId,
            'pollQuestion': pollQuestion,
            'notificationType': 'new_poll',
          },
        );
      }

      debugPrint('🔔 New poll notifications sent to ${targetUserIds.length} users in room $roomId');
    } catch (e) {
      debugPrint('❌ Error sending new poll notifications: $e');
    }
  }

  /// Notify users when poll results are available (poll expired)
  Future<void> notifyPollResultsAvailable({
    required String roomId,
    required String pollId,
    required String pollQuestion,
    required Map<String, int> finalResults,
  }) async {
    try {
      final room = await _getRoomInfo(roomId);
      if (room == null) return;

      // Get all users who participated in the poll
      final poll = await _chatRepository.getPollById(pollId);
      if (poll == null) return;

      final participantIds = poll.userVotes.keys.toList();
      if (participantIds.isEmpty) return;

      // Find the winning option
      final winningOption = _getWinningOption(finalResults);

      // Create notification for each participant
      for (final userId in participantIds) {
        final userChoice = poll.userVotes[userId];
        final didWin = userChoice == winningOption;

        await _notificationManager.createNotification(
          type: NotificationType.pollResult,
          title: 'Poll Results: ${room.title}',
          body: didWin
              ? 'Your choice won! "$winningOption" - "$pollQuestion"'
              : 'Results are in for "$pollQuestion"',
          data: {
            'pollId': pollId,
            'roomId': roomId,
            'roomTitle': room.title,
            'pollQuestion': pollQuestion,
            'finalResults': finalResults,
            'userChoice': userChoice,
            'winningOption': winningOption,
            'didWin': didWin,
            'notificationType': 'poll_results',
          },
        );
      }

      debugPrint('🔔 Poll results notifications sent to ${participantIds.length} participants');
    } catch (e) {
      debugPrint('❌ Error sending poll results notifications: $e');
    }
  }

  /// Send reminder notifications before poll deadline
  Future<void> sendPollDeadlineReminders({
    required String roomId,
    required String pollId,
    required String pollQuestion,
    required Duration timeRemaining,
  }) async {
    try {
      final room = await _getRoomInfo(roomId);
      if (room == null) return;

      // Get poll to find participants who haven't voted yet
      final poll = await _chatRepository.getPollById(pollId);
      if (poll == null) return;

      // Get all room members
      final allMemberIds = await _getRoomMemberIds(roomId);
      if (allMemberIds.isEmpty) return;

      // Find users who haven't voted yet
      final nonVoters = allMemberIds.where((userId) => !poll.userVotes.containsKey(userId)).toList();
      if (nonVoters.isEmpty) return;

      // Determine reminder type based on time remaining
      final hoursRemaining = timeRemaining.inHours;
      final reminderType = hoursRemaining <= 1 ? 'urgent' : 'regular';

      // Create reminder notifications
      for (final userId in nonVoters) {
        await _notificationManager.createNotification(
          type: NotificationType.pollDeadline,
          title: 'Poll Ending Soon: ${room.title}',
          body: hoursRemaining <= 1
              ? 'Poll closes in ${timeRemaining.inMinutes} minutes! "$pollQuestion"'
              : 'Poll closes in $hoursRemaining hours. Don\'t miss your chance to vote!',
          data: {
            'pollId': pollId,
            'roomId': roomId,
            'roomTitle': room.title,
            'pollQuestion': pollQuestion,
            'timeRemaining': timeRemaining.inMilliseconds,
            'hoursRemaining': hoursRemaining,
            'reminderType': reminderType,
            'notificationType': 'poll_deadline',
          },
        );
      }

      debugPrint('🔔 Poll deadline reminders sent to ${nonVoters.length} users (${hoursRemaining}h remaining)');
    } catch (e) {
      debugPrint('❌ Error sending poll deadline reminders: $e');
    }
  }

  /// Send voting reminders to users who haven't voted yet
  Future<void> sendVotingReminders({
    required String roomId,
    required String pollId,
    required String pollQuestion,
  }) async {
    try {
      final room = await _getRoomInfo(roomId);
      if (room == null) return;

      // Get poll to find non-voters
      final poll = await _chatRepository.getPollById(pollId);
      if (poll == null) return;

      // Get all room members
      final allMemberIds = await _getRoomMemberIds(roomId);
      if (allMemberIds.isEmpty) return;

      // Find users who haven't voted
      final nonVoters = allMemberIds.where((userId) => !poll.userVotes.containsKey(userId)).toList();
      if (nonVoters.isEmpty) return;

      // Create voting reminder notifications
      for (final userId in nonVoters) {
        await _notificationManager.createNotification(
          type: NotificationType.votingReminder,
          title: 'Vote Reminder: ${room.title}',
          body: 'You haven\'t voted yet on "$pollQuestion"',
          data: {
            'pollId': pollId,
            'roomId': roomId,
            'roomTitle': room.title,
            'pollQuestion': pollQuestion,
            'notificationType': 'voting_reminder',
          },
        );
      }

      debugPrint('🔔 Voting reminders sent to ${nonVoters.length} users in room $roomId');
    } catch (e) {
      debugPrint('❌ Error sending voting reminders: $e');
    }
  }

  /// Notify users about manifesto poll results
  Future<void> notifyManifestoPollResults({
    required String manifestoId,
    required String candidateName,
    required Map<String, int> finalResults,
  }) async {
    try {
      // Get manifesto followers/interested users
      final targetUserIds = await _getManifestoInterestedUsers(manifestoId);
      if (targetUserIds.isEmpty) return;

      // Find the winning option
      final winningOption = _getWinningOption(finalResults);

      // Create notification for each interested user
      for (final userId in targetUserIds) {
        await _notificationManager.createNotification(
          type: NotificationType.pollResult,
          title: 'Manifesto Poll Results',
          body: '$candidateName\'s manifesto poll: "$winningOption" wins!',
          data: {
            'manifestoId': manifestoId,
            'candidateName': candidateName,
            'finalResults': finalResults,
            'winningOption': winningOption,
            'notificationType': 'manifesto_poll_results',
          },
        );
      }

      debugPrint('🔔 Manifesto poll results notifications sent to ${targetUserIds.length} users');
    } catch (e) {
      debugPrint('❌ Error sending manifesto poll results notifications: $e');
    }
  }

  /// Helper method to get room information
  Future<ChatRoom?> _getRoomInfo(String roomId) async {
    try {
      // This would need to be implemented based on how rooms are stored
      // For now, return a basic room object
      return ChatRoom(
        roomId: roomId,
        title: 'Chat Room', // This should be fetched from actual room data
        type: 'group',
        createdAt: DateTime.now(),
        createdBy: '',
        description: 'Chat room for notifications',
        members: [],
      );
    } catch (e) {
      debugPrint('❌ Error getting room info: $e');
      return null;
    }
  }

  /// Helper method to get room member IDs
  Future<List<String>> _getRoomMemberIds(String roomId, {String? excludeUserId}) async {
    try {
      // This would need to be implemented based on how room membership is stored
      // For now, return empty list - this should be implemented properly
      return [];
    } catch (e) {
      debugPrint('❌ Error getting room member IDs: $e');
      return [];
    }
  }

  /// Helper method to get users interested in a manifesto
  Future<List<String>> _getManifestoInterestedUsers(String manifestoId) async {
    try {
      // This would need to be implemented based on manifesto following/interaction system
      // For now, return empty list - this should be implemented properly
      return [];
    } catch (e) {
      debugPrint('❌ Error getting manifesto interested users: $e');
      return [];
    }
  }

  /// Helper method to determine winning poll option
  String _getWinningOption(Map<String, int> results) {
    if (results.isEmpty) return 'No winner';

    String winningOption = results.keys.first;
    int maxVotes = results[winningOption] ?? 0;

    for (final entry in results.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        winningOption = entry.key;
      }
    }

    return winningOption;
  }
}