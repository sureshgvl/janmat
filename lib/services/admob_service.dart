import 'dart:async';
import 'dart:math';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdMobService extends GetxService {
  static const String rewardedAdUnitId = 'ca-app-pub-6744159173512986/8362274275';

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
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          isRewardedAdLoaded.value = true;
          print('✅ Rewarded ad loaded successfully');

          // Set up callbacks
          _setupRewardedAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          isRewardedAdLoaded.value = false;
          print('❌ Failed to load rewarded ad: $error');

          // Retry loading after delay
          Future.delayed(const Duration(seconds: 30), () {
            if (!_isRewardedAdLoaded) {
              _loadRewardedAd();
            }
          });
        },
      ),
    );
  }

  // Set up rewarded ad callbacks
  void _setupRewardedAdCallbacks() {
    if (_rewardedAd == null) return;

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
  }

  // Show rewarded ad and return reward amount
  Future<int?> showRewardedAd() async {
    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      print('❌ Rewarded ad not ready');
      return null;
    }

    final completer = Completer<int?>();

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎉 User earned reward: ${reward.amount} ${reward.type}');

        // Award 3-5 XP randomly
        final rewardXP = 3 + Random().nextInt(3); // 3, 4, or 5 XP
        completer.complete(rewardXP);
      },
    );

    return completer.future;
  }

  // Check if rewarded ad is available
  bool get isAdAvailable => _isRewardedAdLoaded;

  // Force reload rewarded ad (for testing)
  void reloadRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
    isRewardedAdLoaded.value = false;
    _loadRewardedAd();
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
}