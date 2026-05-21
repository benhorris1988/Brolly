import 'package:flutter/foundation.dart';

import 'ad_config.dart';
import 'ads_init_mobile.dart'
    if (dart.library.html) 'ads_init_stub.dart' as platform;

/// Boots Google Mobile Ads + handles the GDPR/UK-GDPR consent dialog.
///
/// Call once from `main()` after WidgetsFlutterBinding is ready. The whole
/// thing is a no-op on web and on builds compiled with `ADS_ENABLED=false`,
/// so it's always safe to call.
Future<void> initAds() async {
  if (!adsActive) return;
  try {
    await platform.consentAndInit();
  } catch (e, st) {
    debugPrint('Ad SDK init failed (continuing without ads): $e');
    debugPrintStack(stackTrace: st);
  }
}
