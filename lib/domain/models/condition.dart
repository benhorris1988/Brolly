import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

/// Coarse weather condition categories — used to pick an icon and a short label.
/// Derived from provider-specific codes at the repository edge so the UI doesn't
/// care whether the data came from Met Office or Open-Meteo.
enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  overcast,
  fog,
  drizzle,
  rain,
  heavyRain,
  showers,
  sleet,
  snow,
  thunderstorm,
  unknown,
}

extension WeatherConditionX on WeatherCondition {
  String get label {
    switch (this) {
      case WeatherCondition.clear:
        return 'Clear';
      case WeatherCondition.partlyCloudy:
        return 'Partly cloudy';
      case WeatherCondition.cloudy:
        return 'Cloudy';
      case WeatherCondition.overcast:
        return 'Overcast';
      case WeatherCondition.fog:
        return 'Fog';
      case WeatherCondition.drizzle:
        return 'Drizzle';
      case WeatherCondition.rain:
        return 'Rain';
      case WeatherCondition.heavyRain:
        return 'Heavy rain';
      case WeatherCondition.showers:
        return 'Showers';
      case WeatherCondition.sleet:
        return 'Sleet';
      case WeatherCondition.snow:
        return 'Snow';
      case WeatherCondition.thunderstorm:
        return 'Thunderstorms';
      case WeatherCondition.unknown:
        return '—';
    }
  }

  /// Daytime weather_icons glyph for this condition.
  IconData get icon => iconFor(isNight: false);

  /// Pick a glyph that matches the time of day. Switches sun-based icons
  /// to their moon variants at night.
  IconData iconFor({required bool isNight}) {
    switch (this) {
      case WeatherCondition.clear:
        return isNight ? WeatherIcons.night_clear : WeatherIcons.day_sunny;
      case WeatherCondition.partlyCloudy:
        return isNight
            ? WeatherIcons.night_alt_cloudy
            : WeatherIcons.day_cloudy;
      case WeatherCondition.cloudy:
        return WeatherIcons.cloud;
      case WeatherCondition.overcast:
        return WeatherIcons.cloudy;
      case WeatherCondition.fog:
        return WeatherIcons.fog;
      case WeatherCondition.drizzle:
        return WeatherIcons.sprinkle;
      case WeatherCondition.rain:
        return WeatherIcons.rain;
      case WeatherCondition.heavyRain:
        return WeatherIcons.rain_wind;
      case WeatherCondition.showers:
        return isNight
            ? WeatherIcons.night_alt_showers
            : WeatherIcons.day_showers;
      case WeatherCondition.sleet:
        return WeatherIcons.sleet;
      case WeatherCondition.snow:
        return WeatherIcons.snow;
      case WeatherCondition.thunderstorm:
        return isNight
            ? WeatherIcons.night_alt_thunderstorm
            : WeatherIcons.day_thunderstorm;
      case WeatherCondition.unknown:
        return WeatherIcons.na;
    }
  }

  /// Tint for the icon — gives each condition a recognisable colour rather
  /// than the monochrome black/white of the weather_icons font.
  Color iconColor({required bool isNight}) {
    switch (this) {
      case WeatherCondition.clear:
        return isNight
            ? const Color(0xFFB0C4DE) // moon-silver
            : const Color(0xFFFFB300); // bright sun amber
      case WeatherCondition.partlyCloudy:
        return isNight
            ? const Color(0xFF8FA6C4)
            : const Color(0xFF4FA3D1); // sun behind cloud blue
      case WeatherCondition.cloudy:
        return const Color(0xFF607D8B);
      case WeatherCondition.overcast:
        return const Color(0xFF455A64);
      case WeatherCondition.fog:
        return const Color(0xFF90A4AE);
      case WeatherCondition.drizzle:
        return const Color(0xFF4FC3F7);
      case WeatherCondition.rain:
        return const Color(0xFF1E88E5);
      case WeatherCondition.heavyRain:
        return const Color(0xFF1565C0);
      case WeatherCondition.showers:
        return const Color(0xFF29B6F6);
      case WeatherCondition.sleet:
        return const Color(0xFF80DEEA);
      case WeatherCondition.snow:
        return const Color(0xFFB3E5FC);
      case WeatherCondition.thunderstorm:
        return const Color(0xFF7B1FA2);
      case WeatherCondition.unknown:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Maps a Met Office "significantWeatherCode" (0–30) to our domain enum.
/// See https://datahub.metoffice.gov.uk for the full code list.
WeatherCondition metOfficeCodeToCondition(int? code) {
  if (code == null) return WeatherCondition.unknown;
  switch (code) {
    case 0:
    case 1:
      return WeatherCondition.clear;
    case 2:
    case 3:
      return WeatherCondition.partlyCloudy;
    case 5:
      return WeatherCondition.fog;
    case 6:
    case 7:
      return WeatherCondition.cloudy;
    case 8:
      return WeatherCondition.overcast;
    case 9:
    case 10:
    case 11:
    case 12:
      return WeatherCondition.drizzle;
    case 13:
    case 14:
      return WeatherCondition.showers;
    case 15:
      return WeatherCondition.heavyRain;
    case 16:
    case 17:
      return WeatherCondition.sleet;
    case 18:
    case 23:
    case 24:
      return WeatherCondition.sleet;
    case 19:
    case 20:
    case 21:
    case 22:
    case 25:
    case 26:
    case 27:
      return WeatherCondition.snow;
    case 28:
    case 29:
    case 30:
      return WeatherCondition.thunderstorm;
    default:
      return WeatherCondition.unknown;
  }
}

/// Maps an Open-Meteo WMO weather code to our domain enum.
WeatherCondition openMeteoCodeToCondition(int? code) {
  if (code == null) return WeatherCondition.unknown;
  if (code == 0) return WeatherCondition.clear;
  if (code == 1 || code == 2) return WeatherCondition.partlyCloudy;
  if (code == 3) return WeatherCondition.overcast;
  if (code == 45 || code == 48) return WeatherCondition.fog;
  if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
  if (code == 61 || code == 63) return WeatherCondition.rain;
  if (code == 65) return WeatherCondition.heavyRain;
  if (code >= 66 && code <= 67) return WeatherCondition.sleet;
  if (code >= 71 && code <= 77) return WeatherCondition.snow;
  if (code >= 80 && code <= 82) return WeatherCondition.showers;
  if (code == 85 || code == 86) return WeatherCondition.snow;
  if (code >= 95) return WeatherCondition.thunderstorm;
  return WeatherCondition.unknown;
}
