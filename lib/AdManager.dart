import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdManager {
  static BannerAd? _bannerAd;

  static void initialize() {
    MobileAds.instance.initialize();
  }

  static void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7547263048547584/1304056030', // Test banner ad ID
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Optional: Action after ad is loaded
        },
        onAdFailedToLoad: (ad, error) {
          // Optional: Action in case of ad load failure
          ad.dispose();
        },
      ),
    );

    _bannerAd?.load();
  }

  static Widget getBannerAdWidget() {
    if (_bannerAd == null) {
      return const SizedBox(); // Return an empty box if ad is not loaded
    }
    return Container(
      height: 50,
      child: AdWidget(ad: _bannerAd!), // Ensure _bannerAd is not null
    );
  }

  static void dispose() {
    _bannerAd?.dispose();
  }
}
