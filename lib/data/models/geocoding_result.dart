import 'package:json_annotation/json_annotation.dart';

part 'geocoding_result.g.dart';

@JsonSerializable(explicitToJson: true)
class GeocodingResponse {
  const GeocodingResponse({this.results});

  final List<GeocodingResult>? results;

  factory GeocodingResponse.fromJson(Map<String, dynamic> json) =>
      _$GeocodingResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GeocodingResponseToJson(this);
}

@JsonSerializable()
class GeocodingResult {
  const GeocodingResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.countryCode,
    this.admin1,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String? admin1;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) =>
      _$GeocodingResultFromJson(json);
  Map<String, dynamic> toJson() => _$GeocodingResultToJson(this);
}
