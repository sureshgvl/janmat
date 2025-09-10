import 'package:flutter_test/flutter_test.dart';
import 'package:janmat/models/chat_model.dart';

void main() {
  group('UserQuota Tests', () {
    test('remainingMessages calculation is correct', () {
      final quota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 5,
        extraQuota: 5,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // remainingMessages = (dailyLimit + extraQuota) - messagesSent
      // = (20 + 5) - 5 = 20
      expect(quota.remainingMessages, 20);
    });

    test('canSendMessage returns true when messagesSent < total limit', () {
      final quota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 15,
        extraQuota: 5,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // messagesSent (15) < dailyLimit + extraQuota (25), so should be true
      expect(quota.canSendMessage, true);
    });

    test('canSendMessage returns false when messagesSent >= total limit', () {
      final quota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 25,
        extraQuota: 5,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // messagesSent (25) >= dailyLimit + extraQuota (25), so should be false
      expect(quota.canSendMessage, false);
    });

    test('copyWith increments messagesSent correctly', () {
      final originalQuota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 5,
        extraQuota: 0,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final updatedQuota = originalQuota.copyWith(messagesSent: originalQuota.messagesSent + 1);

      expect(updatedQuota.messagesSent, 6);
      expect(updatedQuota.remainingMessages, 14); // 20 - 6 = 14
    });

    test('JSON serialization works correctly', () {
      final quota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 5,
        extraQuota: 3,
        lastReset: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
      );

      final json = quota.toJson();
      final deserializedQuota = UserQuota.fromJson(json);

      expect(deserializedQuota.userId, quota.userId);
      expect(deserializedQuota.dailyLimit, quota.dailyLimit);
      expect(deserializedQuota.messagesSent, quota.messagesSent);
      expect(deserializedQuota.extraQuota, quota.extraQuota);
      expect(deserializedQuota.remainingMessages, quota.remainingMessages);
      expect(deserializedQuota.canSendMessage, quota.canSendMessage);
    });
  });

  group('Quota Deduction Logic Tests', () {
    test('Simulates message sending quota deduction', () {
      // Simulate the logic from sendMessageWithQuotaUpdate
      UserQuota currentQuota = UserQuota(
        userId: 'test_user',
        dailyLimit: 20,
        messagesSent: 5,
        extraQuota: 0,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Before sending message
      expect(currentQuota.remainingMessages, 15); // 20 - 5 = 15
      expect(currentQuota.canSendMessage, true);

      // Simulate sending a message (increment messagesSent)
      UserQuota updatedQuota = currentQuota.copyWith(
        messagesSent: currentQuota.messagesSent + 1,
      );

      // After sending message
      expect(updatedQuota.messagesSent, 6);
      expect(updatedQuota.remainingMessages, 14); // 20 - 6 = 14
      expect(updatedQuota.canSendMessage, true);

      // Send another message
      updatedQuota = updatedQuota.copyWith(
        messagesSent: updatedQuota.messagesSent + 1,
      );

      expect(updatedQuota.messagesSent, 7);
      expect(updatedQuota.remainingMessages, 13); // 20 - 7 = 13
    });

    test('Handles quota exhaustion correctly', () {
      UserQuota quota = UserQuota(
        userId: 'test_user',
        dailyLimit: 5,
        messagesSent: 4,
        extraQuota: 0,
        lastReset: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(quota.remainingMessages, 1); // 5 - 4 = 1
      expect(quota.canSendMessage, true);

      // Send the last message
      quota = quota.copyWith(messagesSent: quota.messagesSent + 1);

      expect(quota.messagesSent, 5);
      expect(quota.remainingMessages, 0); // 5 - 5 = 0
      expect(quota.canSendMessage, false);
    });
  });
}