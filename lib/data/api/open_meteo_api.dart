import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/open_meteo_forecast.dart';

part 'open_meteo_api.g.dart';

/// Open-Meteo — no key required. Used as a fallback when the Met Office quota
/// is exhausted or the user is outside the UK.
@RestApi(baseUrl: 'https://api.open-meteo.com/v1')
abstract class OpenMeteoApi {
  factory OpenMeteoApi(Dio dio, {String baseUrl}) = _OpenMeteoApi;

  /// Lightweight call used by the radar's forecast grid — pulls only the
  /// hourly precipitation series for a single point. Skipping `current`,
  /// `daily`, and `minutely_15` keeps the response small when we fan out
  /// to 25+ grid points in parallel.
  ///
  /// Uses Open-Meteo's default `best_match` model blend. We tried switching
  /// to `models=ukmo_seamless` for better UK accuracy, but UKMO returns
  /// `null` entries in `precipitation_probability`, which breaks JSON
  /// deserialization. best_match is less UK-accurate but returns clean data.
  @GET('/forecast')
  Future<OpenMeteoForecastResponse> getHourlyPrecipOnly({
    @Query('latitude') required double latitude,
    @Query('longitude') required double longitude,
    @Query('hourly') String hourly = 'precipitation',
    @Query('forecast_hours') int forecastHours = 8,
    @Query('timezone') String timezone = 'auto',
  });

  @GET('/forecast')
  Future<OpenMeteoForecastResponse> getForecast({
    @Query('latitude') required double latitude,
    @Query('longitude') required double longitude,
    @Query('current') String current =
        'temperature_2m,apparent_temperature,relative_humidity_2m,'
        'precipitation,weather_code,wind_speed_10m,wind_direction_10m',
    @Query('minutely_15') String minutely15 = 'precipitation',
    @Query('forecast_minutely_15') int forecastMinutely15 = 8,
    @Query('hourly') String hourly =
        'temperature_2m,apparent_temperature,precipitation,'
        'precipitation_probability,weather_code,wind_speed_10m,'
        'wind_direction_10m,relative_humidity_2m',
    @Query('daily') String daily =
        'weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,precipitation_probability_max,'
        'wind_speed_10m_max,sunrise,sunset',
    @Query('forecast_days') int forecastDays = 7,
    @Query('forecast_hours') int forecastHours = 48,
    @Query('wind_speed_unit') String windSpeedUnit = 'kmh',
    @Query('timezone') String timezone = 'auto',
  });
}
