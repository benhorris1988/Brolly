import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/models/saved_location.dart';
import '../local/db.dart';

class LocationRepository {
  LocationRepository(this._db);

  final BrollyDatabase _db;

  // ---- Device location -----------------------------------------------------

  /// Request location permission and return the device position.
  /// Returns null if the user denies permission or location services are off.
  Future<SavedLocation?> getCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final ph.PermissionStatus status = await ph.Permission.locationWhenInUse.status;
    ph.PermissionStatus effective = status;
    if (!status.isGranted) {
      effective = await ph.Permission.locationWhenInUse.request();
    }
    if (!effective.isGranted) return null;

    final Position p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return SavedLocation(
      name: 'My location',
      latitude: p.latitude,
      longitude: p.longitude,
      isCurrent: true,
    );
  }

  // ---- Saved locations (drift) --------------------------------------------

  Stream<List<SavedLocation>> watchSaved() =>
      _db.watchAllLocations().map(_mapRows);

  Future<List<SavedLocation>> getSaved() async =>
      _mapRows(await _db.getAllLocations());

  Future<int> addLocation(SavedLocation l) {
    return _db.insertLocation(SavedLocationsCompanion.insert(
      name: l.name,
      latitude: l.latitude,
      longitude: l.longitude,
      country: l.country == null ? const Value<String?>.absent() : Value<String?>(l.country),
    ));
  }

  Future<int> removeLocation(int id) => _db.deleteLocation(id);

  List<SavedLocation> _mapRows(List<SavedLocationRow> rows) {
    return rows
        .map((SavedLocationRow r) => SavedLocation(
              id: r.id,
              name: r.name,
              latitude: r.latitude,
              longitude: r.longitude,
              country: r.country,
            ))
        .toList(growable: false);
  }
}

// ---- Providers ------------------------------------------------------------

final Provider<BrollyDatabase> brollyDatabaseProvider =
    Provider<BrollyDatabase>((Ref ref) {
  final BrollyDatabase db = BrollyDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<LocationRepository> locationRepositoryProvider =
    Provider<LocationRepository>(
        (Ref ref) => LocationRepository(ref.watch(brollyDatabaseProvider)));

/// Async fetch of the user's current device location. Caches inside Riverpod
/// so screens can call `ref.watch(currentLocationProvider)` freely.
final FutureProvider<SavedLocation?> currentLocationProvider =
    FutureProvider<SavedLocation?>((Ref ref) async {
  return ref.watch(locationRepositoryProvider).getCurrentLocation();
});

/// Stream of saved (pinned) locations from drift.
final StreamProvider<List<SavedLocation>> savedLocationsProvider =
    StreamProvider<List<SavedLocation>>(
        (Ref ref) => ref.watch(locationRepositoryProvider).watchSaved());
