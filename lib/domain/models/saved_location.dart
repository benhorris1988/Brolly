import 'package:meta/meta.dart';

/// A location the user has pinned to their home screen. The `id == null`
/// sentinel is reserved for the live current-location entry, which is not
/// persisted in drift.
@immutable
class SavedLocation {
  const SavedLocation({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isCurrent = false,
    this.country,
  });

  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isCurrent;
  final String? country;

  SavedLocation copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    bool? isCurrent,
    String? country,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isCurrent: isCurrent ?? this.isCurrent,
      country: country ?? this.country,
    );
  }
}
