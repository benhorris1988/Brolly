import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/location_repository.dart';
import '../../data/repositories/weather_repository.dart';
import '../../domain/models/forecast.dart';
import '../../domain/models/saved_location.dart';

/// Combined list of locations to show on the home PageView:
/// current location (if known) followed by saved (pinned) locations.
final Provider<List<SavedLocation>> homeLocationsProvider =
    Provider<List<SavedLocation>>((Ref ref) {
  final AsyncValue<SavedLocation?> current =
      ref.watch(currentLocationProvider);
  final AsyncValue<List<SavedLocation>> saved =
      ref.watch(savedLocationsProvider);

  final List<SavedLocation> out = <SavedLocation>[];
  final SavedLocation? loc = current.asData?.value;
  if (loc != null) out.add(loc);
  out.addAll(saved.asData?.value ?? const <SavedLocation>[]);
  return out;
});

/// Forecast for a given (lat, lon) pair. Keyed by location so each card can
/// load independently and we don't refetch when the user swipes back.
final FutureProviderFamily<WeatherForecast, _LatLon> forecastForLocationProvider =
    FutureProvider.family<WeatherForecast, _LatLon>((Ref ref, _LatLon key) {
  return ref
      .watch(weatherRepositoryProvider)
      .getForecast(latitude: key.lat, longitude: key.lon);
});

class _LatLon {
  const _LatLon(this.lat, this.lon);
  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _LatLon &&
          (lat - other.lat).abs() < 0.0001 &&
          (lon - other.lon).abs() < 0.0001);

  @override
  int get hashCode => Object.hash(
      (lat * 10000).round(), (lon * 10000).round());
}

/// Convenience to look up a forecast for a [SavedLocation].
AsyncValue<WeatherForecast> watchForecastFor(WidgetRef ref, SavedLocation l) {
  return ref.watch(forecastForLocationProvider(_LatLon(l.latitude, l.longitude)));
}

void invalidateForecastFor(WidgetRef ref, SavedLocation l) {
  ref.invalidate(forecastForLocationProvider(_LatLon(l.latitude, l.longitude)));
}
