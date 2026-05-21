import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/units/units.dart';

/// Set in `main()` so providers can read it synchronously.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
        (Ref ref) => throw UnimplementedError('Override in ProviderScope'));

// ---- Keys -----------------------------------------------------------------

class _Keys {
  static const String themeMode = 'settings.themeMode';
  static const String tempUnit = 'settings.temperatureUnit';
  static const String windUnit = 'settings.windSpeedUnit';
  static const String precipUnit = 'settings.precipitationUnit';
  static const String adsEnabled = 'settings.adsEnabled';
}

// ---- Theme ----------------------------------------------------------------

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences p) {
    switch (p.getString(_Keys.themeMode)) {
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_Keys.themeMode, mode.name);
  }
}

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
        (Ref ref) => ThemeModeNotifier(ref.watch(sharedPreferencesProvider)));

// ---- Units ----------------------------------------------------------------

class UnitPreferences {
  const UnitPreferences({
    required this.temperature,
    required this.windSpeed,
    required this.precipitation,
  });

  final TemperatureUnit temperature;
  final WindSpeedUnit windSpeed;
  final PrecipitationUnit precipitation;

  UnitPreferences copyWith({
    TemperatureUnit? temperature,
    WindSpeedUnit? windSpeed,
    PrecipitationUnit? precipitation,
  }) {
    return UnitPreferences(
      temperature: temperature ?? this.temperature,
      windSpeed: windSpeed ?? this.windSpeed,
      precipitation: precipitation ?? this.precipitation,
    );
  }
}

class UnitPreferencesNotifier extends StateNotifier<UnitPreferences> {
  UnitPreferencesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static UnitPreferences _load(SharedPreferences p) {
    return UnitPreferences(
      temperature: TemperatureUnit.values.byName(
          p.getString(_Keys.tempUnit) ?? TemperatureUnit.celsius.name),
      windSpeed: WindSpeedUnit.values
          .byName(p.getString(_Keys.windUnit) ?? WindSpeedUnit.mph.name),
      precipitation: PrecipitationUnit.values
          .byName(p.getString(_Keys.precipUnit) ?? PrecipitationUnit.mm.name),
    );
  }

  Future<void> setTemperature(TemperatureUnit u) async {
    state = state.copyWith(temperature: u);
    await _prefs.setString(_Keys.tempUnit, u.name);
  }

  Future<void> setWindSpeed(WindSpeedUnit u) async {
    state = state.copyWith(windSpeed: u);
    await _prefs.setString(_Keys.windUnit, u.name);
  }

  Future<void> setPrecipitation(PrecipitationUnit u) async {
    state = state.copyWith(precipitation: u);
    await _prefs.setString(_Keys.precipUnit, u.name);
  }
}

final StateNotifierProvider<UnitPreferencesNotifier, UnitPreferences>
    unitPreferencesProvider =
    StateNotifierProvider<UnitPreferencesNotifier, UnitPreferences>(
        (Ref ref) =>
            UnitPreferencesNotifier(ref.watch(sharedPreferencesProvider)));

// ---- Ads ------------------------------------------------------------------

/// User-controlled toggle for whether the in-app banner should render.
/// Default: false (hidden). When the user flips it on, ads appear.
/// The compile-time `kAdsEnabled` flag and the runtime `adsEnabledProvider`
/// must BOTH be true for the banner to show — letting you ship an ad-free
/// build with `--dart-define=ADS_ENABLED=false` regardless of the toggle.
class AdsEnabledNotifier extends StateNotifier<bool> {
  AdsEnabledNotifier(this._prefs)
      : super(_prefs.getBool(_Keys.adsEnabled) ?? true);

  final SharedPreferences _prefs;

  Future<void> set(bool value) async {
    state = value;
    await _prefs.setBool(_Keys.adsEnabled, value);
  }
}

final StateNotifierProvider<AdsEnabledNotifier, bool> adsEnabledProvider =
    StateNotifierProvider<AdsEnabledNotifier, bool>(
        (Ref ref) => AdsEnabledNotifier(ref.watch(sharedPreferencesProvider)));
