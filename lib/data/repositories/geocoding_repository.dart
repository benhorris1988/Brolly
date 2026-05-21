import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/geocoding_api.dart';
import '../models/geocoding_result.dart';
import 'weather_repository.dart' show openMeteoDioProvider;

final Provider<GeocodingApi> geocodingApiProvider =
    Provider<GeocodingApi>((Ref ref) =>
        GeocodingApi(ref.watch(openMeteoDioProvider)));

class GeocodingRepository {
  GeocodingRepository(this._api);

  final GeocodingApi _api;

  Future<List<GeocodingResult>> search(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return const <GeocodingResult>[];
    final GeocodingResponse res = await _api.search(name: trimmed);
    return res.results ?? const <GeocodingResult>[];
  }
}

final Provider<GeocodingRepository> geocodingRepositoryProvider =
    Provider<GeocodingRepository>(
        (Ref ref) => GeocodingRepository(ref.watch(geocodingApiProvider)));
