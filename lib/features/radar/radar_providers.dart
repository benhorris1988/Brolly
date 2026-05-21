import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/rainviewer_manifest.dart';
import '../../data/repositories/radar_repository.dart';
import '../../data/repositories/weather_repository.dart';
import '../../domain/models/forecast.dart';
import 'timeline_frame.dart';

/// Cached manifest. Auto-refreshes when invalidated; the radar screen also
/// invalidates it on a 5-minute timer while visible.
final FutureProvider<RainViewerManifest> radarManifestProvider =
    FutureProvider<RainViewerManifest>((Ref ref) {
  return ref.watch(radarRepositoryProvider).getManifest();
});

/// Live RainViewer frames in order: past first, then nowcast.
final FutureProvider<List<RainViewerFrame>> radarFramesProvider =
    FutureProvider<List<RainViewerFrame>>((Ref ref) async {
  final RainViewerManifest m = await ref.watch(radarManifestProvider.future);
  return <RainViewerFrame>[...m.radar.past, ...m.radar.nowcast];
});

/// Unified timeline: every RainViewer frame, followed by six clock-hour
/// forecast frames for the next 6 hours. The radar screen swaps between
/// raster tiles (for live frames) and the precipitation grid (for forecast
/// frames) as the user scrubs across the boundary.
final FutureProvider<List<TimelineFrame>> timelineFramesProvider =
    FutureProvider<List<TimelineFrame>>((Ref ref) async {
  final List<RainViewerFrame> live = await ref.watch(radarFramesProvider.future);
  final List<TimelineFrame> out = <TimelineFrame>[
    ...live.map(LiveRadarFrame.new),
  ];

  // Forecast hours: next 6 *clock* hours from now (not now+1h, now+2h, …).
  // Rounding to the clock matches Open-Meteo's hourly buckets exactly so we
  // don't show "+47m" labels when the user is mid-hour.
  final DateTime now = DateTime.now();
  final DateTime nextHour =
      DateTime(now.year, now.month, now.day, now.hour).add(const Duration(hours: 1));
  for (int i = 0; i < 6; i++) {
    out.add(ForecastHourFrame(nextHour.add(Duration(hours: i))));
  }
  return out;
});

/// Cached precipitation grid for a (rough) lat/lon. Open-Meteo's per-IP
/// quota is generous so we don't need aggressive caching, but bucketing
/// keeps nearby zoom changes from re-fetching constantly.
final FutureProviderFamily<PrecipGrid, ({double lat, double lon})>
    precipGridProvider =
    FutureProvider.family<PrecipGrid, ({double lat, double lon})>(
        (Ref ref, ({double lat, double lon}) key) {
  return ref.watch(weatherRepositoryProvider).getPrecipGrid(
        centerLat: key.lat,
        centerLon: key.lon,
      );
});
