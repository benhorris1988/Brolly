import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env/env.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/forecast.dart';
import '../api/met_office_api.dart';
import '../api/open_meteo_api.dart';
import '../models/met_office_forecast.dart';
import '../models/open_meteo_forecast.dart';

/// Routes forecast requests between Met Office and Open-Meteo.
///
/// Quota fallback strategy:
///   1. If no Met Office key is configured, always use Open-Meteo.
///   2. Otherwise try Met Office first.
///   3. On HTTP 429 (quota exceeded) or 401/403 (bad key) the repository
///      flips an in-memory `_metOfficeDisabledUntil` flag for the rest of
///      the day and immediately retries via Open-Meteo.
///   4. Any other Met Office error bubbles up (so transient outages don't
///      silently switch providers forever).
class WeatherRepository {
  WeatherRepository({
    required MetOfficeApi metOffice,
    required OpenMeteoApi openMeteo,
  })  : _metOffice = metOffice,
        _openMeteo = openMeteo;

  final MetOfficeApi _metOffice;
  final OpenMeteoApi _openMeteo;

  DateTime? _metOfficeDisabledUntil;

  bool get _metOfficeAvailable {
    if (!Env.hasMetOfficeKey) return false;
    final DateTime? until = _metOfficeDisabledUntil;
    if (until == null) return true;
    return DateTime.now().isAfter(until);
  }

  Future<WeatherForecast> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    if (_metOfficeAvailable && _isInUK(latitude, longitude)) {
      try {
        return await _fetchFromMetOffice(latitude, longitude);
      } on DioException catch (e) {
        final int? code = e.response?.statusCode;
        if (code == 429 || code == 401 || code == 403) {
          // Disable for the rest of the day; the quota resets at UTC midnight.
          final DateTime now = DateTime.now().toUtc();
          _metOfficeDisabledUntil = DateTime.utc(now.year, now.month, now.day + 1);
        } else {
          rethrow;
        }
      }
    }
    return _fetchFromOpenMeteo(latitude, longitude);
  }

  // ---- Met Office ----------------------------------------------------------

  Future<WeatherForecast> _fetchFromMetOffice(double lat, double lon) async {
    final Future<MetOfficeForecastResponse> hourlyF =
        _metOffice.getHourlyForecast(latitude: lat, longitude: lon);
    final Future<MetOfficeForecastResponse> dailyF =
        _metOffice.getDailyForecast(latitude: lat, longitude: lon);
    final List<MetOfficeForecastResponse> responses =
        await Future.wait<MetOfficeForecastResponse>(<Future<MetOfficeForecastResponse>>[
      hourlyF,
      dailyF,
    ]);
    final List<MetOfficeTimeSeriesEntry> hourlyEntries =
        responses[0].features.first.properties.timeSeries;
    final List<MetOfficeTimeSeriesEntry> dailyEntries =
        responses[1].features.first.properties.timeSeries;

    final List<HourlyForecast> hourly =
        hourlyEntries.map(_mapMetOfficeHourly).toList(growable: false);
    final List<DailyForecast> daily =
        dailyEntries.map(_mapMetOfficeDaily).toList(growable: false);

    final HourlyForecast current = hourly.isNotEmpty
        ? hourly.first
        : _emptyHourly(DateTime.now());

    return WeatherForecast(
      fetchedAt: DateTime.now(),
      source: ForecastSource.metOffice,
      current: current,
      hourly: hourly.take(48).toList(growable: false),
      daily: daily.take(7).toList(growable: false),
    );
  }

  HourlyForecast _mapMetOfficeHourly(MetOfficeTimeSeriesEntry e) {
    return HourlyForecast(
      time: DateTime.parse(e.time).toLocal(),
      temperatureC: e.screenTemperature ?? 0,
      feelsLikeC: e.feelsLikeTemperature ?? e.screenTemperature ?? 0,
      condition: metOfficeCodeToCondition(e.significantWeatherCode),
      windSpeedKph: (e.windSpeed10m ?? 0) * 3.6, // m/s → km/h
      windDirectionDeg: e.windDirectionFrom10m ?? 0,
      precipitationMm: e.totalPrecipAmount ?? 0,
      precipProbability: e.probOfPrecipitation ?? 0,
      humidity: e.screenRelativeHumidity ?? 0,
    );
  }

  DailyForecast _mapMetOfficeDaily(MetOfficeTimeSeriesEntry e) {
    final double maxT = e.dayMaxScreenTemperature ?? 0;
    final double minT = e.nightMinScreenTemperature ?? 0;
    final int? wxCode = e.daySignificantWeatherCode ?? e.nightSignificantWeatherCode;
    final double precipProb = ((e.dayProbabilityOfPrecipitation ?? 0) >
            (e.nightProbabilityOfPrecipitation ?? 0))
        ? (e.dayProbabilityOfPrecipitation ?? 0)
        : (e.nightProbabilityOfPrecipitation ?? 0);
    return DailyForecast(
      date: DateTime.parse(e.time).toLocal(),
      maxTempC: maxT,
      minTempC: minT,
      condition: metOfficeCodeToCondition(wxCode),
      precipitationMm: e.totalPrecipAmountDay ?? 0,
      precipProbability: precipProb,
      windSpeedKph: (e.midday10MWindSpeed ?? 0) * 3.6,
      sunrise: null,
      sunset: null,
    );
  }

  // ---- Open-Meteo ----------------------------------------------------------

  Future<WeatherForecast> _fetchFromOpenMeteo(double lat, double lon) async {
    final OpenMeteoForecastResponse r =
        await _openMeteo.getForecast(latitude: lat, longitude: lon);
    final List<HourlyForecast> hourly = _expandOpenMeteoHourly(r.hourly);
    final List<DailyForecast> daily = _expandOpenMeteoDaily(r.daily);

    final HourlyForecast current = r.current != null
        ? HourlyForecast(
            time: DateTime.parse(r.current!.time).toLocal(),
            temperatureC: r.current!.temperature2m ?? 0,
            feelsLikeC: r.current!.apparentTemperature ??
                r.current!.temperature2m ??
                0,
            condition: openMeteoCodeToCondition(r.current!.weatherCode),
            windSpeedKph: r.current!.windSpeed10m ?? 0,
            windDirectionDeg: r.current!.windDirection10m ?? 0,
            precipitationMm: r.current!.precipitation ?? 0,
            precipProbability: 0,
            humidity: r.current!.relativeHumidity2m ?? 0,
          )
        : (hourly.isNotEmpty ? hourly.first : _emptyHourly(DateTime.now()));

    return WeatherForecast(
      fetchedAt: DateTime.now(),
      source: ForecastSource.openMeteo,
      current: current,
      hourly: hourly.take(48).toList(growable: false),
      daily: daily.take(7).toList(growable: false),
      minutely: _expandOpenMeteoMinutely(r.minutely15),
    );
  }

  /// Sample a [gridSize]×[gridSize] grid of points around (centerLat,
  /// centerLon) and fetch each one's next [hours] hours of precipitation
  /// forecast from Open-Meteo. Returns a [PrecipGrid] suitable for
  /// rendering as a circle overlay on the radar map.
  ///
  /// Open-Meteo's per-IP quota is generous (~10k/day) so 25 parallel calls
  /// per refresh is well within bounds.
  Future<PrecipGrid> getPrecipGrid({
    required double centerLat,
    required double centerLon,
    int gridSize = 5,
    double latSpanDeg = 1.6,
    double lonSpanDeg = 2.4,
    int hours = 6,
  }) async {
    final List<({double lat, double lon})> points =
        <({double lat, double lon})>[];
    final double latStep = latSpanDeg / (gridSize - 1);
    final double lonStep = lonSpanDeg / (gridSize - 1);
    final double latStart = centerLat - latSpanDeg / 2;
    final double lonStart = centerLon - lonSpanDeg / 2;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        points.add((lat: latStart + i * latStep, lon: lonStart + j * lonStep));
      }
    }

    // Ask for a few hours' headroom so we can drop the past hour cleanly.
    final int requestHours = hours + 2;
    // Per-point error tolerance: if one of the 25 calls fails (transient
    // network blip, parse error from a server-side change, etc.) we still
    // return the grid with the surviving points instead of erroring the
    // whole forecast.
    final List<OpenMeteoForecastResponse?> responses = await Future.wait(
      points.map((({double lat, double lon}) p) async {
        try {
          return await _openMeteo.getHourlyPrecipOnly(
            latitude: p.lat,
            longitude: p.lon,
            forecastHours: requestHours,
          );
        } catch (e) {
          return null;
        }
      }),
    );

    // Pick the hourly buckets that are *ahead of* "now". All grid points
    // share the same timezone (`auto` → user-local) so their `time` arrays
    // align; we read the timeline from the first non-empty response.
    final DateTime now = DateTime.now();
    List<DateTime> selectedHours = const <DateTime>[];
    List<int> selectedIndices = const <int>[];
    for (final OpenMeteoForecastResponse? r in responses) {
      if (r == null) continue;
      final OpenMeteoHourly? h = r.hourly;
      if (h == null) continue;
      final List<DateTime> all =
          h.time.map((String s) => DateTime.parse(s).toLocal()).toList();
      final List<int> idx = <int>[];
      for (int i = 0; i < all.length && idx.length < hours; i++) {
        if (all[i].isAfter(now)) idx.add(i);
      }
      if (idx.isNotEmpty) {
        selectedIndices = idx;
        selectedHours = idx.map((int i) => all[i]).toList();
        break;
      }
    }
    if (selectedHours.isEmpty) {
      return PrecipGrid(
        fetchedAt: DateTime.now(),
        hours: const <DateTime>[],
        points: const <PrecipGridPoint>[],
      );
    }

    final List<PrecipGridPoint> gridPoints = <PrecipGridPoint>[];
    for (int p = 0; p < responses.length; p++) {
      final OpenMeteoForecastResponse? r = responses[p];
      if (r == null) continue; // skip points whose request failed
      final List<double>? precip = r.hourly?.precipitation;
      final List<double> series = selectedIndices
          .map((int i) => (precip != null && i < precip.length) ? precip[i] : 0)
          .map((num v) => v.toDouble())
          .toList();
      gridPoints.add(PrecipGridPoint(
        latitude: points[p].lat,
        longitude: points[p].lon,
        precipMmPerHour: series,
      ));
    }

    return PrecipGrid(
      fetchedAt: DateTime.now(),
      hours: selectedHours,
      points: gridPoints,
    );
  }

  MinutelyPrecip? _expandOpenMeteoMinutely(OpenMeteoMinutely15? m) {
    if (m == null) return null;
    final List<double>? precip = m.precipitation;
    if (precip == null || precip.isEmpty) return null;
    final List<DateTime> times = m.time
        .map((String s) => DateTime.parse(s).toLocal())
        .toList(growable: false);
    return MinutelyPrecip(times: times, precipitationMm: precip);
  }

  List<HourlyForecast> _expandOpenMeteoHourly(OpenMeteoHourly? h) {
    if (h == null) return const <HourlyForecast>[];
    final int n = h.time.length;
    final List<HourlyForecast> out = <HourlyForecast>[];
    for (int i = 0; i < n; i++) {
      out.add(HourlyForecast(
        time: DateTime.parse(h.time[i]).toLocal(),
        temperatureC: _at(h.temperature2m, i),
        feelsLikeC: _at(h.apparentTemperature, i, fallback: _at(h.temperature2m, i)),
        condition: openMeteoCodeToCondition(_intAt(h.weatherCode, i)),
        windSpeedKph: _at(h.windSpeed10m, i),
        windDirectionDeg: _at(h.windDirection10m, i),
        precipitationMm: _at(h.precipitation, i),
        precipProbability: _at(h.precipitationProbability, i),
        humidity: _at(h.relativeHumidity2m, i),
      ));
    }
    return out;
  }

  List<DailyForecast> _expandOpenMeteoDaily(OpenMeteoDaily? d) {
    if (d == null) return const <DailyForecast>[];
    final int n = d.time.length;
    final List<DailyForecast> out = <DailyForecast>[];
    for (int i = 0; i < n; i++) {
      out.add(DailyForecast(
        date: DateTime.parse(d.time[i]).toLocal(),
        maxTempC: _at(d.temperature2mMax, i),
        minTempC: _at(d.temperature2mMin, i),
        condition: openMeteoCodeToCondition(_intAt(d.weatherCode, i)),
        precipitationMm: _at(d.precipitationSum, i),
        precipProbability: _at(d.precipitationProbabilityMax, i),
        windSpeedKph: _at(d.windSpeed10mMax, i),
        sunrise: _dateAt(d.sunrise, i),
        sunset: _dateAt(d.sunset, i),
      ));
    }
    return out;
  }

  static double _at(List<double>? list, int i, {double fallback = 0}) {
    if (list == null || i >= list.length) return fallback;
    return list[i];
  }

  static int? _intAt(List<int>? list, int i) {
    if (list == null || i >= list.length) return null;
    return list[i];
  }

  static DateTime? _dateAt(List<String>? list, int i) {
    if (list == null || i >= list.length) return null;
    return DateTime.tryParse(list[i])?.toLocal();
  }

  static HourlyForecast _emptyHourly(DateTime t) => HourlyForecast(
        time: t,
        temperatureC: 0,
        feelsLikeC: 0,
        condition: WeatherCondition.unknown,
        windSpeedKph: 0,
        windDirectionDeg: 0,
        precipitationMm: 0,
        precipProbability: 0,
        humidity: 0,
      );

  /// Rough UK bounding box. Outside this, skip Met Office and go straight to
  /// Open-Meteo since the Met Office only covers UK points.
  static bool _isInUK(double lat, double lon) {
    return lat >= 49.5 && lat <= 61.0 && lon >= -8.5 && lon <= 2.0;
  }
}

// ---- Providers ------------------------------------------------------------

final Provider<Dio> metOfficeDioProvider = Provider<Dio>((Ref ref) {
  final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: <String, String>{
      'accept': 'application/json',
    },
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      final String key = Env.metOfficeApiKey;
      if (key.isNotEmpty) {
        options.headers['x-api-key'] = key;
      }
      handler.next(options);
    },
  ));
  return dio;
});

final Provider<Dio> openMeteoDioProvider = Provider<Dio>((Ref ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: <String, String>{'accept': 'application/json'},
  ));
});

final Provider<MetOfficeApi> metOfficeApiProvider =
    Provider<MetOfficeApi>((Ref ref) => MetOfficeApi(ref.watch(metOfficeDioProvider)));

final Provider<OpenMeteoApi> openMeteoApiProvider =
    Provider<OpenMeteoApi>((Ref ref) => OpenMeteoApi(ref.watch(openMeteoDioProvider)));

final Provider<WeatherRepository> weatherRepositoryProvider =
    Provider<WeatherRepository>((Ref ref) {
  return WeatherRepository(
    metOffice: ref.watch(metOfficeApiProvider),
    openMeteo: ref.watch(openMeteoApiProvider),
  );
});
