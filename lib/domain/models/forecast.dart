import 'package:meta/meta.dart';

import 'condition.dart';

/// A point-in-time forecast — all values are metric.
@immutable
class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.condition,
    required this.windSpeedKph,
    required this.windDirectionDeg,
    required this.precipitationMm,
    required this.precipProbability,
    required this.humidity,
  });

  final DateTime time;
  final double temperatureC;
  final double feelsLikeC;
  final WeatherCondition condition;
  final double windSpeedKph;
  final double windDirectionDeg;
  final double precipitationMm;
  final double precipProbability; // 0–100
  final double humidity; // 0–100
}

@immutable
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.condition,
    required this.precipitationMm,
    required this.precipProbability,
    required this.windSpeedKph,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final WeatherCondition condition;
  final double precipitationMm;
  final double precipProbability;
  final double windSpeedKph;
  final DateTime? sunrise;
  final DateTime? sunset;
}

/// Whole forecast bundle for a single point.
@immutable
class WeatherForecast {
  const WeatherForecast({
    required this.fetchedAt,
    required this.source,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final DateTime fetchedAt;
  final ForecastSource source;
  final HourlyForecast current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
}

enum ForecastSource { metOffice, openMeteo }

extension ForecastSourceX on ForecastSource {
  String get label =>
      this == ForecastSource.metOffice ? 'Met Office' : 'Open-Meteo';
}
