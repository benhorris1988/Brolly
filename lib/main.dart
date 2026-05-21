import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ads/ads_init.dart';
import 'features/settings/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env missing — Met Office calls will be skipped and Open-Meteo used instead.
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Best-effort, non-blocking ads init. We don't await it so the UI shows
  // immediately even if consent / network takes a moment.
  unawaited(initAds());

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BrollyApp(),
    ),
  );
}
