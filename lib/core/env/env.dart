import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wrapper around .env values so callers don't depend on flutter_dotenv directly.
class Env {
  Env._();

  static String get metOfficeApiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet('MET_OFFICE_API_KEY') ?? '';
  }

  /// Whether we have a Met Office key configured.
  /// When false, the app falls back to Open-Meteo for forecasts and skips warnings.
  static bool get hasMetOfficeKey => metOfficeApiKey.trim().isNotEmpty;
}
