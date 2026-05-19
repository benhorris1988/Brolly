import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/met_office_forecast.dart';
import '../models/met_office_warnings.dart';

part 'met_office_api.g.dart';

/// Met Office DataHub — Site Specific Forecast + Severe Weather Warnings.
///
/// Auth: pass the API key in `x-api-key` (added via Dio interceptor in
/// `weather_repository.dart`).
///
/// Site Specific Forecast endpoints (frequency segment of the URL):
///   - `hourly`         — next 48 hours, 1-hour resolution
///   - `three-hourly`   — next 5 days, 3-hour resolution
///   - `daily`          — next 7 days, daily summary
///
/// Free tier: 360 calls/day per API. The repository falls back to Open-Meteo
/// once a 429 is observed or when the key is missing.
@RestApi(baseUrl: 'https://data.hub.api.metoffice.gov.uk/sitespecific/v0')
abstract class MetOfficeApi {
  factory MetOfficeApi(Dio dio, {String baseUrl}) = _MetOfficeApi;

  @GET('/point/hourly')
  Future<MetOfficeForecastResponse> getHourlyForecast({
    @Query('latitude') required double latitude,
    @Query('longitude') required double longitude,
    @Query('excludeParameterMetadata') bool excludeMetadata = true,
    @Query('includeLocationName') bool includeLocationName = true,
  });

  @GET('/point/three-hourly')
  Future<MetOfficeForecastResponse> getThreeHourlyForecast({
    @Query('latitude') required double latitude,
    @Query('longitude') required double longitude,
    @Query('excludeParameterMetadata') bool excludeMetadata = true,
    @Query('includeLocationName') bool includeLocationName = true,
  });

  @GET('/point/daily')
  Future<MetOfficeForecastResponse> getDailyForecast({
    @Query('latitude') required double latitude,
    @Query('longitude') required double longitude,
    @Query('excludeParameterMetadata') bool excludeMetadata = true,
    @Query('includeLocationName') bool includeLocationName = true,
  });
}

@RestApi(
  baseUrl: 'https://data.hub.api.metoffice.gov.uk/severe-weather-warnings/v1',
)
abstract class MetOfficeWarningsApi {
  factory MetOfficeWarningsApi(Dio dio, {String baseUrl}) = _MetOfficeWarningsApi;

  /// Returns all currently-active UK severe weather warnings.
  @GET('/warnings/active')
  Future<MetOfficeWarningsResponse> getActiveWarnings();
}
