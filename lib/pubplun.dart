import 'package:google_mobile_ads/google_mobile_ads.dart';

class PubPlun {
  static InterstitialAd? _interstitialAd;

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7547263048547584/7001738296', // ID d'annonce interstitielle de test
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('Interstitial ad loaded');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // Remise à zéro après l'affichage
    } else {
      print('Interstitial ad is not ready yet.');
    }
  }
}
