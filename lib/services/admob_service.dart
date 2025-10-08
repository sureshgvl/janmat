import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';
import '../utils/app_logger.dart';
import 'background_initializer.dart';

class AdMobService extends GetxService {
  // Use test ad unit ID for development/testing
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // Test ID
  // Production ID: 'ca-app-pub-6744159173512986/8362274275'

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Observable for UI updates
  var isRewardedAdLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Defer AdMob initialization to avoid blocking startup
    // Will be initialized when first ad is needed
    AppLogger.common('📱 AdMob service initialized - heavy operations deferred');
  }

  @override
  void onClose() {
    _rewardedAd?.dispose();
    super.onClose();
  }

  // Initialize AdMob
  Future<void> _initializeAdMob() async {
    // Set application ID at runtime since we removed it from manifest
    await MobileAds.instance.initialize();

    AppLogger.common('✅ AdMob initialized successfully');
    _loadRewardedAd();
  }

  // Load rewarded ad
  void _loadRewardedAd() {
    AppLogger.common('🔄 Loading rewarded ad with unit ID: $rewardedAdUnitId');
    AppLogger.common('   Using ${isTestAdUnit() ? 'TEST' : 'PRODUCTION'} ad unit');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          isRewardedAdLoaded.value = true;

          AppLogger.common('✅ Rewarded ad loaded successfully');
          AppLogger.common(
            '   Ad type: ${ad.responseInfo?.mediationAdapterClassName ?? 'Unknown'}',
          );

          // Set up callbacks
          _setupRewardedAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          isRewardedAdLoaded.value = false;
          AppLogger.commonError('❌ Failed to load rewarded ad', error: error);
          AppLogger.common('   Error code: ${error.code}');
          AppLogger.common('   Error message: ${error.message}');
          AppLogger.common('   Error domain: ${error.domain}');
          AppLogger.common('   Ad unit ID: $rewardedAdUnitId');

          // Handle specific error codes
          if (error.code == 3) {
            // No fill
            AppLogger.common(
              '   No fill error - no ads available. Will retry in 60 seconds.',
            );
            Future.delayed(const Duration(seconds: 60), () {
              if (!_isRewardedAdLoaded) {
                _loadRewardedAd();
              }
            });
          } else {
            // For other errors, retry sooner
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isRewardedAdLoaded) {
                _loadRewardedAd();
              }
            });
          }
        },
      ),
    );
  }

  // Check if using test ad unit
  bool isTestAdUnit() {
    return rewardedAdUnitId == 'ca-app-pub-3940256099942544/5224354917';
  }

  // Set up rewarded ad callbacks
  void _setupRewardedAdCallbacks() {
    if (_rewardedAd == null) {
      AppLogger.common('⚠️ Cannot setup callbacks: rewarded ad is null');
      return;
    }

    AppLogger.common('🔧 Setting up rewarded ad callbacks');

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AppLogger.common('🎬 Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.common('🎬 Rewarded ad dismissed');
        // Dispose and load new ad
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        isRewardedAdLoaded.value = false;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.commonError('❌ Failed to show rewarded ad', error: error);
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        isRewardedAdLoaded.value = false;
        _loadRewardedAd();
      },
      onAdImpression: (ad) {
        AppLogger.common('📊 Rewarded ad impression recorded');
      },
    );

    AppLogger.common('✅ Rewarded ad callbacks setup complete');
  }

  // Show rewarded ad and return reward amount
  Future<int?> showRewardedAd() async {
    // Ensure AdMob is initialized
    await initializeIfNeeded();

    // Wait for ad to be loaded (with timeout)
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    while (!_isRewardedAdLoaded &&
        DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      AppLogger.common('❌ Rewarded ad not ready after initialization');
      return null;
    }

    final completer = Completer<int?>();
    bool rewardEarned = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        AppLogger.common('🎉 User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;

        // Award 3-5 XP randomly
        final rewardXP = 3 + Random().nextInt(3); // 3, 4, or 5 XP
        completer.complete(rewardXP);
      },
    );

    // Add a timeout to handle cases where reward is never earned
    Future.delayed(const Duration(seconds: 30), () {
      if (!rewardEarned && !completer.isCompleted) {
        AppLogger.common(
          '⚠️ Reward callback timeout - assuming ad was watched without reward',
        );
        // Still award some XP as fallback
        final fallbackXP = 2; // Smaller reward for fallback
        completer.complete(fallbackXP);
      }
    });

    return completer.future;
  }

  // Lazy initialization of AdMob
  Future<void> initializeIfNeeded() async {
    if (_rewardedAd != null || _isRewardedAdLoaded) {
      return; // Already initialized
    }

    AppLogger.common('🚀 Starting zero-frame AdMob initialization');

    // Use background initializer for zero-frame AdMob setup
    final backgroundInit = BackgroundInitializer();
    await backgroundInit.initializeServiceWithZeroFrames(
      'AdMob',
      () => _initializeAdMob(),
    );

    AppLogger.common('✅ AdMob initialized with zero frames');
  }

  // Check if rewarded ad is available
  bool get isAdAvailable => _isRewardedAdLoaded;

  // Force reload rewarded ad (for testing)
  void reloadRewardedAd() {
    AppLogger.common('🔄 Force reloading rewarded ad');
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    isRewardedAdLoaded.value = false;
    _loadRewardedAd();
  }

  // Simulate reward for testing (only in debug mode)
  Future<int?> simulateRewardForTesting() async {
    AppLogger.common('🧪 Simulating reward for testing purposes');
    final rewardXP = 3 + Random().nextInt(3); // 3, 4, or 5 XP
    return rewardXP;
  }

  // Get ad loading status
  String getAdStatus() {
    if (_isRewardedAdLoaded) {
      return 'Ad Ready';
    } else if (_rewardedAd != null) {
      return 'Ad Loading';
    } else {
      return 'Ad Not Loaded';
    }
  }

  // Get detailed ad information for debugging
  Map<String, dynamic> getAdDebugInfo() {
    return {
      'isLoaded': _isRewardedAdLoaded,
      'adUnitId': rewardedAdUnitId,
      'isTestAd': isTestAdUnit(),
      'adObject': _rewardedAd != null ? 'Exists' : 'Null',
      'status': getAdStatus(),
    };
  }

  // Switch to production ad unit (for production builds)
  void useProductionAdUnit() {
    const productionId = 'ca-app-pub-6744159173512986/8362274275';
    if (rewardedAdUnitId != productionId) {
      AppLogger.common('🔄 Switching to production ad unit');
      reloadRewardedAd();
    }
  }

  // Switch to test ad unit (for development)
  void useTestAdUnit() {
    const testId = 'ca-app-pub-3940256099942544/5224354917';
    if (rewardedAdUnitId != testId) {
      AppLogger.common('🔄 Switching to test ad unit');
      reloadRewardedAd();
    }
  }
}
