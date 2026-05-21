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

/// 15-minute precipitation forecast — used by the "rain in the next 2 hours"
/// graph on the home screen. Times are local. Met Office doesn't expose this
/// granularity on the free tier so this is populated only when the data came
/// from Open-Meteo.
@immutable
class MinutelyPrecip {
  const MinutelyPrecip({required this.times, required this.precipitationMm});

  final List<DateTime> times;
  final List<double> precipitationMm; // mm per 15-min interval

  bool get isEmpty => times.isEmpty || precipitationMm.isEmpty;
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
    this.minutely,
  });

  final DateTime fetchedAt;
  final ForecastSource source;
  final HourlyForecast current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final MinutelyPrecip? minutely;
}

enum ForecastSource { metOffice, openMeteo }

extension ForecastSourceX on ForecastSource {
  String get label =>
      this == ForecastSource.metOffice ? 'Met Office' : 'Open-Meteo';
}

/// A single sampled lat/lon point's precipitation forecast for a sequence of
/// upcoming hours. Used by the radar's "next 6 hours" forecast overlay.
@immutable
class PrecipGridPoint {
  const PrecipGridPoint({
    required this.latitude,
    required this.longitude,
    required this.precipMmPerHour,
  });

  final double latitude;
  final double longitude;

  /// Precipitation in millimetres for each hour, aligned with the parent
  /// grid's `hours` list. `precipMmPerHour[i]` is the forecast precip for
  /// `PrecipGrid.hours[i]`.
  final List<double> precipMmPerHour;
}

/// Grid of precipitation forecast points around a focus location. The radar
/// screen turns each future hour into a [TimelineFrame] and renders the
/// grid as a circle layer beneath the user's map.
@immutable
class PrecipGrid {
  const PrecipGrid({
    required this.fetchedAt,
    required this.hours,
    required this.points,
  });

  final DateTime fetchedAt;

  /// The (local) hourly buckets the grid covers, ascending. `hours.length`
  /// matches every point's `precipMmPerHour.length`.
  final List<DateTime> hours;

  /// Sampled grid points. Order is arbitrary (callers should not assume
  /// row-major or any other layout).
  final List<PrecipGridPoint> points;

  bool get isEmpty => points.isEmpty || hours.isEmpty;
}
