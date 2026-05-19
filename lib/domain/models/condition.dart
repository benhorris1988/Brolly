import 'package:flutter/material.dart';

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

  IconData get icon {
    switch (this) {
      case WeatherCondition.clear:
        return Icons.wb_sunny_outlined;
      case WeatherCondition.partlyCloudy:
        return Icons.cloud_queue;
      case WeatherCondition.cloudy:
      case WeatherCondition.overcast:
        return Icons.cloud_outlined;
      case WeatherCondition.fog:
        return Icons.foggy;
      case WeatherCondition.drizzle:
        return Icons.grain;
      case WeatherCondition.rain:
      case WeatherCondition.heavyRain:
      case WeatherCondition.showers:
        return Icons.water_drop_outlined;
      case WeatherCondition.sleet:
        return Icons.ac_unit;
      case WeatherCondition.snow:
        return Icons.ac_unit_outlined;
      case WeatherCondition.thunderstorm:
        return Icons.thunderstorm_outlined;
      case WeatherCondition.unknown:
        return Icons.help_outline;
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
