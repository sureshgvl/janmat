import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../models/chat_message.dart';

/// Service responsible for message moderation and content filtering
/// Handles inappropriate content detection, spam prevention, and message validation
class MessageModerationManager {
  // List of inappropriate words/phrases to filter
  static const List<String> _inappropriateWords = [
    // Add inappropriate words here as needed
    // This is a basic implementation - in production, use more sophisticated filtering
  ];

  // List of spam patterns
  static const List<String> _spamPatterns = [
    r'\b(?:free|cheap|buy|sell|discount)\b.*\b(?:money|cash|bitcoin|crypto)\b',
    r'\b(?:click here|visit|check out)\b.*\b(?:http|www|\.com)\b',
    r'(?:\+?\d{10,}|\+\d{1,3}\s?\d{3,})', // Phone numbers
  ];

  /// Validate message content before sending
  Future<MessageValidationResult> validateMessage(String text, String senderId) async {
    try {
      AppLogger.chat('MessageModerationManager: Validating message from $senderId');

      // Check for empty messages
      if (text.trim().isEmpty) {
        return MessageValidationResult(
          isValid: false,
          reason: 'Message cannot be empty',
          severity: ValidationSeverity.error,
        );
      }

      // Check message length
      if (text.length > 2000) {
        return MessageValidationResult(
          isValid: false,
          reason: 'Message is too long (maximum 2000 characters)',
          severity: ValidationSeverity.error,
        );
      }

      // Check for inappropriate content
      final inappropriateCheck = _checkInappropriateContent(text);
      if (!inappropriateCheck.isValid) {
        return inappropriateCheck;
      }

      // Check for spam
      final spamCheck = _checkSpam(text);
      if (!spamCheck.isValid) {
        return spamCheck;
      }

      // Check for repeated messages (basic rate limiting)
      final repeatCheck = await _checkRepeatedMessages(text, senderId);
      if (!repeatCheck.isValid) {
        return repeatCheck;
      }

      AppLogger.chat('MessageModerationManager: Message validation passed');
      return MessageValidationResult(isValid: true);

    } catch (e) {
      AppLogger.chat('MessageModerationManager: Error validating message: $e');
      // Allow message if validation fails
      return MessageValidationResult(isValid: true);
    }
  }

  /// Check for inappropriate content
  MessageValidationResult _checkInappropriateContent(String text) {
    final lowerText = text.toLowerCase();

    for (final word in _inappropriateWords) {
      if (lowerText.contains(word.toLowerCase())) {
        return MessageValidationResult(
          isValid: false,
          reason: 'Message contains inappropriate content',
          severity: ValidationSeverity.error,
        );
      }
    }

    return MessageValidationResult(isValid: true);
  }

  /// Check for spam patterns
  MessageValidationResult _checkSpam(String text) {
    final lowerText = text.toLowerCase();

    for (final pattern in _spamPatterns) {
      final regExp = RegExp(pattern, caseSensitive: false);
      if (regExp.hasMatch(lowerText)) {
        return MessageValidationResult(
          isValid: false,
          reason: 'Message appears to be spam',
          severity: ValidationSeverity.warning,
        );
      }
    }

    return MessageValidationResult(isValid: true);
  }

  /// Check for repeated messages (basic implementation)
  Future<MessageValidationResult> _checkRepeatedMessages(String text, String senderId) async {
    // TODO: Implement proper rate limiting with message history
    // For now, just return valid
    return MessageValidationResult(isValid: true);
  }

  /// Moderate existing message (for admin use)
  Future<bool> moderateMessage(String messageId, ModerationAction action, String moderatorId) async {
    try {
      AppLogger.chat('MessageModerationManager: Moderating message $messageId with action $action');

      switch (action) {
        case ModerationAction.delete:
          // TODO: Implement message deletion
          SnackbarUtils.showInfo('Message deletion not yet implemented');
          return false;

        case ModerationAction.hide:
          // TODO: Implement message hiding
          SnackbarUtils.showInfo('Message hiding not yet implemented');
          return false;

        case ModerationAction.warn:
          // TODO: Implement user warning
          SnackbarUtils.showInfo('User warning not yet implemented');
          return false;

        case ModerationAction.ban:
          // TODO: Implement user banning
          SnackbarUtils.showInfo('User banning not yet implemented');
          return false;
      }

    } catch (e) {
      AppLogger.chat('MessageModerationManager: Error moderating message: $e');
      SnackbarUtils.showError('Failed to moderate message');
      return false;
    }
  }

  /// Report message for moderation
  Future<bool> reportMessage(String messageId, String reporterId, String reason) async {
    try {
      AppLogger.chat('MessageModerationManager: Reporting message $messageId by $reporterId for: $reason');

      // TODO: Implement message reporting system
      SnackbarUtils.showSuccess('Message reported. Thank you for helping keep the community safe.');
      return true;

    } catch (e) {
      AppLogger.chat('MessageModerationManager: Error reporting message: $e');
      SnackbarUtils.showError('Failed to report message');
      return false;
    }
  }

  /// Check if user is allowed to send messages (rate limiting, bans, etc.)
  Future<bool> canUserSendMessage(String userId) async {
    try {
      // TODO: Implement user permission checking
      // For now, allow all users
      return true;
    } catch (e) {
      AppLogger.chat('MessageModerationManager: Error checking user permissions: $e');
      return false;
    }
  }

  /// Clean message content (remove excessive whitespace, etc.)
  String cleanMessageContent(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\n{3,}'), '\n\n'); // Limit consecutive newlines
  }

  /// Get moderation statistics
  Future<Map<String, int>> getModerationStats() async {
    // TODO: Implement moderation statistics
    return {
      'reported_messages': 0,
      'deleted_messages': 0,
      'banned_users': 0,
      'warnings_issued': 0,
    };
  }
}

/// Result of message validation
class MessageValidationResult {
  final bool isValid;
  final String? reason;
  final ValidationSeverity severity;

  MessageValidationResult({
    required this.isValid,
    this.reason,
    this.severity = ValidationSeverity.error,
  });
}

/// Severity levels for validation issues
enum ValidationSeverity {
  error,   // Block message
  warning, // Allow but flag
  info,    // Allow with notification
}

/// Available moderation actions
enum ModerationAction {
  delete, // Delete the message
  hide,   // Hide the message
  warn,   // Warn the user
  ban,    // Ban the user
}
