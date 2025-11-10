import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../models/user_quota.dart';
import '../repositories/chat_repository.dart';

/// Manages user message quotas
class UserQuotaManager {
  final ChatRepository _repository = ChatRepository();

  var userQuota = Rx<UserQuota?>(null);

  /// Load user quota
  Future<void> loadUserQuota(String userId) async {
    try {
      final quota = await _repository.getUserQuota(userId);
      if (quota != null) {
        userQuota.value = quota;
        AppLogger.chat('UserQuotaManager: Loaded quota: ${quota.remainingMessages} remaining');
      } else {
        // Create default quota
        final defaultQuota = UserQuota(
          userId: userId,
          lastReset: DateTime.now(),
          createdAt: DateTime.now(),
        );
        userQuota.value = defaultQuota;
        await _repository.updateUserQuota(defaultQuota);
        AppLogger.chat('UserQuotaManager: Created default quota');
      }
    } catch (e) {
      AppLogger.chat('UserQuotaManager: Failed to load quota: $e');
    }
  }

  /// Update quota after sending a message
  Future<void> updateQuotaAfterMessage() async {
    try {
      final currentQuota = userQuota.value;
      if (currentQuota != null) {
        final updatedQuota = currentQuota.copyWith(
          messagesSent: currentQuota.messagesSent + 1,
        );

        userQuota.value = updatedQuota;
        await _repository.updateUserQuota(updatedQuota);

        AppLogger.chat(
          'UserQuotaManager: Updated quota - sent: ${updatedQuota.messagesSent}, remaining: ${updatedQuota.remainingMessages}',
        );
      }
    } catch (e) {
      AppLogger.chat('UserQuotaManager: Failed to update quota: $e');
    }
  }

  /// Add extra quota (from ads, etc.)
  Future<void> addExtraQuota(String userId, int extraMessages) async {
    try {
      await _repository.addExtraQuota(userId, extraMessages);

      // Update local state
      final currentQuota = userQuota.value;
      if (currentQuota != null) {
        final updatedQuota = currentQuota.copyWith(
          extraQuota: currentQuota.extraQuota + extraMessages,
        );
        userQuota.value = updatedQuota;
        AppLogger.chat('UserQuotaManager: Added $extraMessages extra messages');
      }
    } catch (e) {
      AppLogger.chat('UserQuotaManager: Failed to add extra quota: $e');
      rethrow;
    }
  }

  /// Check if user can send message
  bool canSendMessage(String userId) {
    final quota = userQuota.value;
    return quota != null && quota.canSendMessage;
  }

  /// Get remaining messages
  int get remainingMessages {
    return userQuota.value?.remainingMessages ?? 0;
  }

  /// Clear quota
  void clearQuota() {
    userQuota.value = null;
  }
}
