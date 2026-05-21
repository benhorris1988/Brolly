import 'package:flutter/foundation.dart';

/// Compile-time flag for whether ads should render at all.
///
/// Production builds default to true. For your personal ad-free build:
///     flutter build apk --release --dart-define=ADS_ENABLED=false
const bool kAdsEnabled =
    bool.fromEnvironment('ADS_ENABLED', defaultValue: true);

/// Whether the current platform supports the Google Mobile Ads SDK.
/// google_mobile_ads only ships Android/iOS bindings — web is a no-op.
bool get adsSupportedOnPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Combined check most callers want: ads should actually render right now.
bool get adsActive => kAdsEnabled && adsSupportedOnPlatform;

/// AdMob unit IDs.
///
/// Debug builds always use Google's official test unit IDs — these render
/// safe placeholder ads and are the only IDs you should ever use during
/// development. Using your real production IDs while testing can flag your
/// AdMob account as fraudulent.
///
/// Release builds use the production IDs declared below. Replace the
/// placeholder values with your real AdMob ad unit IDs (one per platform)
/// once you've created them in the AdMob console.
class AdUnits {
  AdUnits._();

  // Google's published test ad unit IDs — safe to commit.
  // Always used in debug builds to keep your AdMob account in good standing.
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';

  // Real Brolly Android ad units. iOS not configured yet — kept as
  // placeholder; debug builds use test IDs there too.
  static const String _prodBannerAndroid =
      'ca-app-pub-9435133170872304/3435315722';
  static const String _prodBannerIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Created in AdMob but intentionally NOT rendered yet — keeping the
  // experience clean (banner only). When/if we add full-screen ads in the
  // future, wire these in via InterstitialAd / AppOpenAd.
  // ignore: unused_field
  static const String _prodInterstitialAndroid =
      'ca-app-pub-9435133170872304/3546996361';
  // ignore: unused_field
  static const String _prodAppOpenAndroid =
      'ca-app-pub-9435133170872304/1328027134';

  static String get homeBanner {
    if (!adsSupportedOnPlatform) return '';
    final bool useTest = kDebugMode;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return useTest ? _testBannerAndroid : _prodBannerAndroid;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return useTest ? _testBannerIos : _prodBannerIos;
    }
    return '';
  }
}
