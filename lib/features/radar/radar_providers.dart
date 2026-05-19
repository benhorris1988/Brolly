import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/rainviewer_manifest.dart';
import '../../data/repositories/radar_repository.dart';

/// Cached manifest. Auto-refreshes when invalidated; the radar screen also
/// invalidates it on a 5-minute timer while visible.
final FutureProvider<RainViewerManifest> radarManifestProvider =
    FutureProvider<RainViewerManifest>((Ref ref) {
  return ref.watch(radarRepositoryProvider).getManifest();
});

/// Convenience — all playback frames in order (past + nowcast).
final FutureProvider<List<RainViewerFrame>> radarFramesProvider =
    FutureProvider<List<RainViewerFrame>>((Ref ref) async {
  final RainViewerManifest m = await ref.watch(radarManifestProvider.future);
  return <RainViewerFrame>[...m.radar.past, ...m.radar.nowcast];
});
