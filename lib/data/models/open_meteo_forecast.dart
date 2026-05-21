import 'package:json_annotation/json_annotation.dart';

part 'open_meteo_forecast.g.dart';

@JsonSerializable(explicitToJson: true)
class OpenMeteoForecastResponse {
  const OpenMeteoForecastResponse({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.current,
    this.minutely15,
    this.hourly,
    this.daily,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final OpenMeteoCurrent? current;
  @JsonKey(name: 'minutely_15')
  final OpenMeteoMinutely15? minutely15;
  final OpenMeteoHourly? hourly;
  final OpenMeteoDaily? daily;

  factory OpenMeteoForecastResponse.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoForecastResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OpenMeteoForecastResponseToJson(this);
}

@JsonSerializable()
class OpenMeteoMinutely15 {
  const OpenMeteoMinutely15({
    required this.time,
    this.precipitation,
  });

  final List<String> time;
  final List<double>? precipitation;

  factory OpenMeteoMinutely15.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoMinutely15FromJson(json);
  Map<String, dynamic> toJson() => _$OpenMeteoMinutely15ToJson(this);
}

@JsonSerializable()
class OpenMeteoCurrent {
  const OpenMeteoCurrent({
    required this.time,
    this.temperature2m,
    this.apparentTemperature,
    this.relativeHumidity2m,
    this.precipitation,
    this.weatherCode,
    this.windSpeed10m,
    this.windDirection10m,
  });

  final String time;
  @JsonKey(name: 'temperature_2m')
  final double? temperature2m;
  @JsonKey(name: 'apparent_temperature')
  final double? apparentTemperature;
  @JsonKey(name: 'relative_humidity_2m')
  final double? relativeHumidity2m;
  final double? precipitation;
  @JsonKey(name: 'weather_code')
  final int? weatherCode;
  @JsonKey(name: 'wind_speed_10m')
  final double? windSpeed10m;
  @JsonKey(name: 'wind_direction_10m')
  final double? windDirection10m;

  factory OpenMeteoCurrent.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoCurrentFromJson(json);
  Map<String, dynamic> toJson() => _$OpenMeteoCurrentToJson(this);
}

@JsonSerializable()
class OpenMeteoHourly {
  const OpenMeteoHourly({
    required this.time,
    this.temperature2m,
    this.apparentTemperature,
    this.precipitation,
    this.precipitationProbability,
    this.weatherCode,
    this.windSpeed10m,
    this.windDirection10m,
    this.relativeHumidity2m,
  });

  final List<String> time;
  @JsonKey(name: 'temperature_2m')
  final List<double>? temperature2m;
  @JsonKey(name: 'apparent_temperature')
  final List<double>? apparentTemperature;
  final List<double>? precipitation;
  @JsonKey(name: 'precipitation_probability')
  final List<double>? precipitationProbability;
  @JsonKey(name: 'weather_code')
  final List<int>? weatherCode;
  @JsonKey(name: 'wind_speed_10m')
  final List<double>? windSpeed10m;
  @JsonKey(name: 'wind_direction_10m')
  final List<double>? windDirection10m;
  @JsonKey(name: 'relative_humidity_2m')
  final List<double>? relativeHumidity2m;

  factory OpenMeteoHourly.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoHourlyFromJson(json);
  Map<String, dynamic> toJson() => _$OpenMeteoHourlyToJson(this);
}

@JsonSerializable()
class OpenMeteoDaily {
  const OpenMeteoDaily({
    required this.time,
    this.weatherCode,
    this.temperature2mMax,
    this.temperature2mMin,
    this.precipitationSum,
    this.precipitationProbabilityMax,
    this.windSpeed10mMax,
    this.sunrise,
    this.sunset,
  });

  final List<String> time;
  @JsonKey(name: 'weather_code')
  final List<int>? weatherCode;
  @JsonKey(name: 'temperature_2m_max')
  final List<double>? temperature2mMax;
  @JsonKey(name: 'temperature_2m_min')
  final List<double>? temperature2mMin;
  @JsonKey(name: 'precipitation_sum')
  final List<double>? precipitationSum;
  @JsonKey(name: 'precipitation_probability_max')
  final List<double>? precipitationProbabilityMax;
  @JsonKey(name: 'wind_speed_10m_max')
  final List<double>? windSpeed10mMax;
  final List<String>? sunrise;
  final List<String>? sunset;

  factory OpenMeteoDaily.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoDailyFromJson(json);
  Map<String, dynamic> toJson() => _$OpenMeteoDailyToJson(this);
}
