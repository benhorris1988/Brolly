import 'package:json_annotation/json_annotation.dart';

part 'met_office_forecast.g.dart';

/// Top-level Met Office Site Specific Forecast response.
///
/// Returns a GeoJSON FeatureCollection with one feature; the feature's
/// `properties.timeSeries` is the array of point forecasts.
@JsonSerializable(explicitToJson: true)
class MetOfficeForecastResponse {
  const MetOfficeForecastResponse({
    required this.type,
    required this.features,
  });

  final String type;
  final List<MetOfficeFeature> features;

  factory MetOfficeForecastResponse.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeForecastResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeForecastResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MetOfficeFeature {
  const MetOfficeFeature({
    required this.type,
    this.geometry,
    required this.properties,
  });

  final String type;
  final MetOfficeGeometry? geometry;
  final MetOfficeProperties properties;

  factory MetOfficeFeature.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeFeatureFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeFeatureToJson(this);
}

@JsonSerializable()
class MetOfficeGeometry {
  const MetOfficeGeometry({required this.type, required this.coordinates});

  final String type;
  /// [longitude, latitude, elevation]
  final List<double> coordinates;

  factory MetOfficeGeometry.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeGeometryFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeGeometryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MetOfficeProperties {
  const MetOfficeProperties({
    this.location,
    this.requestPointDistance,
    this.modelRunDate,
    required this.timeSeries,
  });

  final MetOfficeLocation? location;
  final double? requestPointDistance;
  final String? modelRunDate;
  final List<MetOfficeTimeSeriesEntry> timeSeries;

  factory MetOfficeProperties.fromJson(Map<String, dynamic> json) =>
      _$MetOfficePropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficePropertiesToJson(this);
}

@JsonSerializable()
class MetOfficeLocation {
  const MetOfficeLocation({this.name});
  final String? name;

  factory MetOfficeLocation.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeLocationFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeLocationToJson(this);
}

/// One row of the time-series — keys vary by frequency (hourly / three-hourly /
/// daily). The fields below cover the union; absent keys are null.
@JsonSerializable()
class MetOfficeTimeSeriesEntry {
  const MetOfficeTimeSeriesEntry({
    required this.time,
    // Hourly / three-hourly
    this.screenTemperature,
    this.feelsLikeTemperature,
    this.windSpeed10m,
    this.windDirectionFrom10m,
    this.totalPrecipAmount,
    this.probOfPrecipitation,
    this.screenRelativeHumidity,
    this.significantWeatherCode,
    // Daily
    this.dayMaxScreenTemperature,
    this.nightMinScreenTemperature,
    this.daySignificantWeatherCode,
    this.nightSignificantWeatherCode,
    this.dayProbabilityOfPrecipitation,
    this.nightProbabilityOfPrecipitation,
    this.midday10MWindSpeed,
    this.totalPrecipAmountDay,
  });

  final String time;

  // Common / hourly
  final double? screenTemperature;
  final double? feelsLikeTemperature;
  final double? windSpeed10m;
  final double? windDirectionFrom10m;
  final double? totalPrecipAmount;
  final double? probOfPrecipitation;
  final double? screenRelativeHumidity;
  final int? significantWeatherCode;

  // Daily
  final double? dayMaxScreenTemperature;
  final double? nightMinScreenTemperature;
  final int? daySignificantWeatherCode;
  final int? nightSignificantWeatherCode;
  final double? dayProbabilityOfPrecipitation;
  final double? nightProbabilityOfPrecipitation;
  final double? midday10MWindSpeed;
  final double? totalPrecipAmountDay;

  factory MetOfficeTimeSeriesEntry.fromJson(Map<String, dynamic> json) =>
      _$MetOfficeTimeSeriesEntryFromJson(json);
  Map<String, dynamic> toJson() => _$MetOfficeTimeSeriesEntryToJson(this);
}
