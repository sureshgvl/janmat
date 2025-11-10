import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../services/admob_service.dart';
import '../models/user_quota.dart';
import '../repositories/chat_repository.dart';

/// Service responsible for managing rewarded ads and extra message rewards
/// Handles ad loading, display, and reward distribution
class AdRewardManager {
  final AdMobService _adMobService = Get.find<AdMobService>();
  final ChatRepository _repository = ChatRepository();

  /// Check if rewarded ads are available
  bool get isAdAvailable => _adMobService.isAdAvailable;

  /// Get ad status for debugging
  String getAdStatus() => _adMobService.getAdStatus();

  /// Get ad debug information
  Map<String, dynamic> getAdDebugInfo() => _adMobService.getAdDebugInfo();

  /// Initialize ad service if needed
  Future<void> initializeIfNeeded() async {
    await _adMobService.initializeIfNeeded();
  }

  /// Watch a rewarded ad to earn extra messages
  Future<bool> watchRewardedAdForExtraMessages({
    required String userId,
    required int extraMessages,
  }) async {
    try {
      AppLogger.chat('AdRewardManager: Starting rewarded ad for $extraMessages extra messages');

      // Check if ad is available
      if (!isAdAvailable) {
        AppLogger.chat('AdRewardManager: Ad not available');
        SnackbarUtils.showWarning('Ad failed to load. Please check your internet connection and try again.');
        return false;
      }

      // Show loading dialog
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Showing rewarded ad...'),
              const SizedBox(height: 8),
              Text(
                'Watch the ad completely to earn $extraMessages extra messages',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Show the ad
      final rewardXP = await _adMobService.showRewardedAd();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      AppLogger.chat('AdRewardManager: Ad result - rewardXP: $rewardXP');

      // Handle ad result
      if (rewardXP != null && rewardXP > 0) {
        // Award extra messages
        final success = await _awardExtraMessages(userId, extraMessages);
        if (success) {
          SnackbarUtils.showSuccess('You earned $extraMessages extra messages for watching the ad!');
          return true;
        } else {
          SnackbarUtils.showError('Ad was watched but failed to award extra messages. Please contact support.');
          return false;
        }
      } else if (_adMobService.isTestAdUnit()) {
        // For test ads, still award messages as fallback
        AppLogger.chat('AdRewardManager: Test ad detected, awarding fallback messages');
        final success = await _awardExtraMessages(userId, extraMessages);
        if (success) {
          SnackbarUtils.showSuccess('You earned $extraMessages extra messages (test mode)!');
          return true;
        }
      } else {
        AppLogger.chat('AdRewardManager: Ad shown but no reward earned');
        SnackbarUtils.showWarning('Ad was shown but no reward was earned. Please try again.');
        return false;
      }

      return false;

    } catch (e) {
      AppLogger.chat('AdRewardManager: Error in rewarded ad flow: $e');

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      SnackbarUtils.showError('Failed to show ad. Please try again later.');
      return false;
    }
  }

  /// Award extra messages to user after watching ad
  Future<bool> _awardExtraMessages(String userId, int extraMessages) async {
    try {
      AppLogger.chat('AdRewardManager: Awarding $extraMessages extra messages to user $userId');

      // Add extra quota using repository
      await _repository.addExtraQuota(userId, extraMessages);

      AppLogger.chat('AdRewardManager: Successfully awarded $extraMessages extra messages');
      return true;

    } catch (e) {
      AppLogger.chat('AdRewardManager: Error awarding extra messages: $e');
      return false;
    }
  }

  /// Force reload rewarded ads for testing
  void forceReloadAds() {
    _adMobService.reloadRewardedAd();
    SnackbarUtils.showInfo('Rewarded ads have been reloaded. Try watching an ad again.');
  }

  /// Simulate reward for testing purposes
  Future<int?> simulateRewardForTesting() async {
    return await _adMobService.simulateRewardForTesting();
  }

  /// Check if current ad unit is a test unit
  bool isTestAdUnit() => _adMobService.isTestAdUnit();

  /// Get current ad loading status
  Future<void> waitForAdLoad({Duration timeout = const Duration(seconds: 15)}) async {
    if (isAdAvailable) return;

    AppLogger.chat('AdRewardManager: Waiting for ad to load...');

    final startTime = DateTime.now();
    while (!isAdAvailable && DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!isAdAvailable) {
      AppLogger.chat('AdRewardManager: Ad failed to load within timeout');
      throw Exception('Ad failed to load within timeout');
    }

    AppLogger.chat('AdRewardManager: Ad loaded successfully');
  }

  /// Comprehensive ad watching flow with better error handling
  Future<bool> watchAdForReward({
    required String userId,
    required int rewardAmount,
    String rewardType = 'messages',
  }) async {
    try {
      AppLogger.chat('AdRewardManager: Starting comprehensive ad flow for $rewardAmount $rewardType');

      // Initialize if needed
      await initializeIfNeeded();

      // Wait for ad if not ready
      if (!isAdAvailable) {
        Get.dialog(
          AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Loading rewarded ad...'),
                const SizedBox(height: 8),
                Text(
                  'Preparing your ad. This may take a moment.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                  throw Exception('Ad loading cancelled by user');
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        // Wait up to 15 seconds for ad to load
        await waitForAdLoad();

        // Close loading dialog
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }

      // Watch the ad
      return await watchRewardedAdForExtraMessages(
        userId: userId,
        extraMessages: rewardAmount,
      );

    } catch (e) {
      AppLogger.chat('AdRewardManager: Comprehensive ad flow failed: $e');

      // Close any open dialogs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (e.toString().contains('cancelled')) {
        SnackbarUtils.showInfo('Ad loading cancelled');
      } else {
        SnackbarUtils.showError('Failed to load ad. Please try again later.');
      }

      return false;
    }
  }
}
