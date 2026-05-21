import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Request UMP consent and then initialize the Mobile Ads SDK.
/// Safe to call multiple times — consent is persisted by the SDK.
Future<void> consentAndInit() async {
  await _requestConsent();
  await MobileAds.instance.initialize();
}

Future<void> _requestConsent() async {
  final Completer<void> done = Completer<void>();

  final ConsentRequestParameters params = ConsentRequestParameters();

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () async {
      try {
        final bool isAvailable =
            await ConsentInformation.instance.isConsentFormAvailable();
        if (!isAvailable) {
          done.complete();
          return;
        }
        ConsentForm.loadConsentForm((ConsentForm form) async {
          final ConsentStatus status =
              await ConsentInformation.instance.getConsentStatus();
          if (status == ConsentStatus.required) {
            form.show((FormError? _) {
              done.complete();
            });
          } else {
            done.complete();
          }
        }, (FormError error) {
          debugPrint('UMP loadConsentForm error: ${error.message}');
          done.complete();
        });
      } catch (e) {
        debugPrint('UMP consent flow error: $e');
        done.complete();
      }
    },
    (FormError error) {
      debugPrint('UMP requestConsentInfoUpdate error: ${error.message}');
      done.complete();
    },
  );

  return done.future;
}
