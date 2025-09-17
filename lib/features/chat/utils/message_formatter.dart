import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_message.dart';

class MessageFormatter {
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  // Format message timestamp
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return _timeFormat.format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday ${_timeFormat.format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return '${DateFormat('EEE').format(timestamp)} ${_timeFormat.format(timestamp)}';
    } else {
      // Older - show date and time
      return '${_dateFormat.format(timestamp)} ${_timeFormat.format(timestamp)}';
    }
  }

  // Format relative time (for chat bubbles)
  static String formatRelativeTime(DateTime timestamp) {
    return timeago.format(timestamp);
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format duration
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  // Get message preview for notifications/chat list
  static String getMessagePreview(Message message) {
    switch (message.type) {
      case 'image':
        return '📷 Image';
      case 'audio':
        return '🎵 Voice message';
      case 'poll':
        return '📊 Poll';
      default:
        // Truncate text messages
        if (message.text.length > 50) {
          return '${message.text.substring(0, 50)}...';
        }
        return message.text;
    }
  }

  // Format message text with mentions and links
  static String formatMessageText(String text) {
    // TODO: Implement mention highlighting, link detection, etc.
    return text;
  }

  // Get message type display name
  static String getMessageTypeDisplayName(String type) {
    switch (type) {
      case 'text':
        return 'Text';
      case 'image':
        return 'Image';
      case 'audio':
        return 'Voice Message';
      case 'poll':
        return 'Poll';
      default:
        return 'Message';
    }
  }

  // Format unread count
  static String formatUnreadCount(int count) {
    if (count > 99) {
      return '99+';
    }
    return count.toString();
  }

  // Format user name with role indicator
  static String formatUserName(String name, String? role) {
    if (role == 'candidate') {
      return '$name (Candidate)';
    } else if (role == 'admin') {
      return '$name (Admin)';
    }
    return name;
  }

  // Validate message text
  static String? validateMessageText(String text) {
    if (text.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (text.length > 4096) {
      return 'Message is too long (max 4096 characters)';
    }
    return null;
  }

  // Sanitize message text
  static String sanitizeMessageText(String text) {
    // Remove excessive whitespace
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Check if message contains links
  static bool containsLinks(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.hasMatch(text);
  }

  // Extract links from message
  static List<String> extractLinks(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }
}
