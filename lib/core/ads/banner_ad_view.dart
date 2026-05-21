import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_providers.dart';
import 'ad_config.dart';
import 'banner_ad_view_mobile.dart'
    if (dart.library.html) 'banner_ad_view_stub.dart' as platform;

/// Inline banner ad slot. Renders a real BannerAd on Android/iOS when:
///   * the compile-time flag `kAdsEnabled` is true (it is by default), AND
///   * the user has flipped the "Show ads" switch on in Settings.
/// Collapses to zero size everywhere else.
class HomeBannerAd extends ConsumerWidget {
  const HomeBannerAd({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!adsActive) return const SizedBox.shrink();
    final bool userEnabled = ref.watch(adsEnabledProvider);
    if (!userEnabled) return const SizedBox.shrink();
    return platform.buildBannerAd(context);
  }
}
