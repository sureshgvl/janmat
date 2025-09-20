import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';

class ChatRoomHelpers {
  // Get room color based on type
  static Color getRoomColor(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Colors.blue.shade600; // Blue for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Colors.green.shade600; // Green for candidate chats
    } else {
      return Colors.purple.shade600; // Purple for other chats
    }
  }

  // Get room icon based on type
  static IconData getRoomIcon(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return Icons.location_city; // City icon for ward chats
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return Icons.person; // Person icon for candidate chats
    } else {
      return Icons.group; // Group icon for other chats
    }
  }

  // Get display title for room
  static String getRoomDisplayTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, title is the city name
      return chatRoom.title ?? 'City Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, title is candidate name
      return chatRoom.title ?? 'Candidate Chat';
    } else {
      return chatRoom.title ?? chatRoom.roomId;
    }
  }

  // Get display subtitle for room
  static String getRoomDisplaySubtitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      // For ward rooms, subtitle is the ward name
      return chatRoom.description ?? 'Ward Discussion';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      // For candidate rooms, subtitle is description
      return chatRoom.description ?? 'Official Updates';
    } else {
      return chatRoom.description ?? 'Group Chat';
    }
  }

  // Get default room title
  static String getDefaultRoomTitle(ChatRoom chatRoom) {
    if (chatRoom.roomId.startsWith('ward_')) {
      return 'Ward ${chatRoom.roomId.replaceAll('ward_', '')} Chat';
    } else if (chatRoom.roomId.startsWith('candidate_')) {
      return 'Candidate Discussion';
    } else {
      return chatRoom.roomId;
    }
  }

  // Scroll to bottom of list with intelligent behavior
  static void scrollToBottom(ScrollController scrollController, {
    bool force = false,
    Duration? duration,
  }) {
    if (!scrollController.hasClients) return;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    final viewportHeight = scrollController.position.viewportDimension;

    // If force is true, always scroll to bottom
    // Otherwise, only scroll if user is near the bottom (within 100px of bottom)
    final shouldScroll = force || (maxScroll - currentScroll) < 100;

    if (shouldScroll) {
      scrollController.animateTo(
        maxScroll,
        duration: duration ?? const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic, // Smoother curve
      );
    }
  }

  // Check if user is near bottom of list
  static bool isNearBottom(ScrollController scrollController, {double threshold = 100.0}) {
    if (!scrollController.hasClients) return false;

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;

    return (maxScroll - currentScroll) <= threshold;
  }

  // Scroll to specific position with smooth animation
  static void scrollToPosition(
    ScrollController scrollController,
    double position, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeInOutCubic,
  }) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        position,
        duration: duration,
        curve: curve,
      );
    }
  }

  // Format message text for display
  static String formatMessageText(String text, {bool isDeleted = false}) {
    if (isDeleted) {
      return 'This message was deleted';
    }
    return text;
  }

  // Get message status icon
  static IconData? getMessageStatusIcon(
    bool isCurrentUser,
    List<String> readBy,
    int totalMembers,
  ) {
    if (!isCurrentUser) return null;

    if (readBy.length > 1) {
      return Icons.done_all; // Read by others
    } else {
      return Icons.done; // Sent but not read
    }
  }

  // Get message status color
  static Color getMessageStatusColor(
    bool isCurrentUser,
    List<String> readBy,
    int totalMembers,
  ) {
    if (!isCurrentUser) return Colors.transparent;

    if (readBy.length > 1) {
      return Colors.lightBlue; // Read by others
    } else {
      return Colors.white.withOpacity(0.7); // Sent but not read
    }
  }

  // Check if message can be reacted to
  static bool canReactToMessage(Message message) {
    return !(message.isDeleted ?? false);
  }

  // Check if message can be deleted
  static bool canDeleteMessage(Message message, String? currentUserId) {
    if (message.isDeleted ?? false) return false;
    return message.senderId == currentUserId;
  }

  // Check if message can be reported
  static bool canReportMessage(Message message, String? currentUserId) {
    if (message.isDeleted ?? false) return false;
    return message.senderId != currentUserId;
  }

  // Get poll vote percentage
  static double getPollVotePercentage(int votes, int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return votes / totalVotes;
  }

  // Format poll results text
  static String formatPollResults(int totalVotes) {
    return '$totalVotes vote${totalVotes != 1 ? 's' : ''}';
  }

  // Get poll option style
  static TextStyle getPollOptionStyle({
    required bool isSelected,
    required bool isUserChoice,
    required bool isCurrentUser,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      color: isCurrentUser ? Colors.white : Colors.black87,
    );
  }

  // Get poll option background color
  static Color getPollOptionBackgroundColor({
    required bool isSelected,
    required bool isUserChoice,
    required bool isCurrentUser,
  }) {
    if (isUserChoice) {
      return Colors.blue.shade50;
    } else if (isSelected) {
      return Colors.grey.shade50;
    } else {
      return Colors.white;
    }
  }

  // Get poll option border color
  static Color getPollOptionBorderColor({
    required bool isSelected,
    required bool isUserChoice,
    required bool isCurrentUser,
  }) {
    if (isSelected) {
      return Colors.blue.shade300;
    } else {
      return Colors.grey.shade300;
    }
  }

  // Validate poll question
  static String? validatePollQuestion(String question) {
    if (question.trim().isEmpty) {
      return 'Poll question cannot be empty';
    }
    if (question.trim().length < 5) {
      return 'Poll question must be at least 5 characters';
    }
    return null;
  }

  // Validate poll options
  static String? validatePollOptions(List<String> options) {
    if (options.length < 2) {
      return 'Poll must have at least 2 options';
    }
    if (options.length > 10) {
      return 'Poll cannot have more than 10 options';
    }

    final validOptions = options
        .where((option) => option.trim().isNotEmpty)
        .toList();
    if (validOptions.length < 2) {
      return 'Poll must have at least 2 valid options';
    }

    // Check for duplicate options
    final uniqueOptions = validOptions.toSet();
    if (uniqueOptions.length != validOptions.length) {
      return 'Poll options must be unique';
    }

    return null;
  }

  // Format poll creation message
  static String formatPollCreationMessage(String question) {
    return '📊 $question';
  }

  // Get attachment option icons
  static List<Map<String, dynamic>> getAttachmentOptions() {
    return [
      {'icon': Icons.image, 'label': 'Send Image', 'action': 'image'},
      {'icon': Icons.poll, 'label': 'Create Poll', 'action': 'poll'},
    ];
  }

  // Get room action options
  static List<Map<String, dynamic>> getRoomActionOptions() {
    return [
      {'icon': Icons.info, 'label': 'Room Info', 'action': 'info'},
      {'icon': Icons.exit_to_app, 'label': 'Leave Room', 'action': 'leave'},
    ];
  }

  // Get message action options
  static List<Map<String, dynamic>> getMessageActionOptions({
    required bool isDeleted,
    required bool isCurrentUserMessage,
  }) {
    final options = <Map<String, dynamic>>[];

    if (!isDeleted) {
      options.addAll([
        {
          'icon': Icons.add_reaction,
          'label': 'Add Reaction',
          'action': 'react',
        },
        {'icon': Icons.report, 'label': 'Report Message', 'action': 'report'},
      ]);
    }

    if (isCurrentUserMessage && !isDeleted) {
      options.add({
        'icon': Icons.delete,
        'label': 'Delete Message',
        'action': 'delete',
      });
    }

    return options;
  }
}
