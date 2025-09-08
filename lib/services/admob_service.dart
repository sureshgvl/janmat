import 'dart:async';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdMobService extends GetxService {
  // Use test ad unit ID for development/testing
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test ID
  // Production ID: 'ca-app-pub-6744159173512986/8362274275'

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Observable for UI updates
  var isRewardedAdLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeAdMob();
  }

  @override
  void onClose() {
    _rewardedAd?.dispose();
    super.onClose();
  }

  // Initialize AdMob
  Future<void> _initializeAdMob() async {
    await MobileAds.instance.initialize();
    print('✅ AdMob initialized successfully');
    _loadRewardedAd();
  }

  // Load rewarded ad
  void _loadRewardedAd() {
    print('🔄 Loading rewarded ad with unit ID: $rewardedAdUnitId');
    print('   Using ${isTestAdUnit() ? 'TEST' : 'PRODUCTION'} ad unit');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          isRewardedAdLoaded.value = true;
          print('✅ Rewarded ad loaded successfully');
          print('   Ad type: ${ad.responseInfo?.mediationAdapterClassName ?? 'Unknown'}');

          // Set up callbacks
          _setupRewardedAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          isRewardedAdLoaded.value = false;
          print('❌ Failed to load rewarded ad: $error');
          print('   Error code: ${error.code}');
          print('   Error message: ${error.message}');
          print('   Error domain: ${error.domain}');
          print('   Ad unit ID: $rewardedAdUnitId');

          // Handle specific error codes
          if (error.code == 3) { // No fill
            print('   No fill error - no ads available. Will retry in 60 seconds.');
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
      print('⚠️ Cannot setup callbacks: rewarded ad is null');
      return;
    }

    print('🔧 Setting up rewarded ad callbacks');

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('🎬 Rewarded ad showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('🎬 Rewarded ad dismissed');
        // Dispose and load new ad
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        isRewardedAdLoaded.value = false;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Failed to show rewarded ad: $error');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        isRewardedAdLoaded.value = false;
        _loadRewardedAd();
      },
      onAdImpression: (ad) {
        print('📊 Rewarded ad impression recorded');
      },
    );

    print('✅ Rewarded ad callbacks setup complete');
  }

  // Show rewarded ad and return reward amount
  Future<int?> showRewardedAd() async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      print('❌ Rewarded ad not ready');
      return null;
    }

    final completer = Completer<int?>();
    bool rewardEarned = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎉 User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;

        // Award 3-5 XP randomly
        final rewardXP = 3 + Random().nextInt(3); // 3, 4, or 5 XP
        completer.complete(rewardXP);
      },
    );

    // Add a timeout to handle cases where reward is never earned
    Future.delayed(const Duration(seconds: 30), () {
      if (!rewardEarned && !completer.isCompleted) {
        print('⚠️ Reward callback timeout - assuming ad was watched without reward');
        // Still award some XP as fallback
        final fallbackXP = 2; // Smaller reward for fallback
        completer.complete(fallbackXP);
      }
    });

    return completer.future;
  }

  // Check if rewarded ad is available
  bool get isAdAvailable => _isRewardedAdLoaded;

  // Force reload rewarded ad (for testing)
  void reloadRewardedAd() {
    print('🔄 Force reloading rewarded ad');
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    isRewardedAdLoaded.value = false;
    _loadRewardedAd();
  }

  // Simulate reward for testing (only in debug mode)
  Future<int?> simulateRewardForTesting() async {
    print('🧪 Simulating reward for testing purposes');
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
      print('🔄 Switching to production ad unit');
      reloadRewardedAd();
    }
  }

  // Switch to test ad unit (for development)
  void useTestAdUnit() {
    const testId = 'ca-app-pub-3940256099942544/5224354917';
    if (rewardedAdUnitId != testId) {
      print('🔄 Switching to test ad unit');
      reloadRewardedAd();
    }
  }
}