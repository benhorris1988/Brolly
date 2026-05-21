import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/geocoding_result.dart';

part 'geocoding_api.g.dart';

/// Open-Meteo geocoding — free, no API key. Used by the "Add location"
/// flow so users can search by place name instead of typing coordinates.
@RestApi(baseUrl: 'https://geocoding-api.open-meteo.com/v1')
abstract class GeocodingApi {
  factory GeocodingApi(Dio dio, {String baseUrl}) = _GeocodingApi;

  @GET('/search')
  Future<GeocodingResponse> search({
    @Query('name') required String name,
    @Query('count') int count = 10,
    @Query('language') String language = 'en',
    @Query('format') String format = 'json',
  });
}
