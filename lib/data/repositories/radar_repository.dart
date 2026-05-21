import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/rainviewer_api.dart';
import '../models/rainviewer_manifest.dart';

/// Caches the RainViewer manifest and exposes helpers to build tile URLs.
class RadarRepository {
  RadarRepository(this._api);

  final RainViewerApi _api;

  RainViewerManifest? _manifest;
  DateTime? _fetchedAt;

  static const Duration _ttl = Duration(minutes: 5);

  Future<RainViewerManifest> getManifest({bool force = false}) async {
    final RainViewerManifest? cached = _manifest;
    final DateTime? at = _fetchedAt;
    final bool fresh = at != null && DateTime.now().difference(at) < _ttl;
    if (!force && cached != null && fresh) return cached;

    final RainViewerManifest fetched = await _api.getManifest();
    _manifest = fetched;
    _fetchedAt = DateTime.now();
    return fetched;
  }

  /// All radar frames in playback order — past first, nowcast last.
  Future<List<RainViewerFrame>> getFrames({bool force = false}) async {
    final RainViewerManifest m = await getManifest(force: force);
    return <RainViewerFrame>[...m.radar.past, ...m.radar.nowcast];
  }

  /// Build the satellite infrared cloud-cover tile URL. RainViewer expects
  /// `colorScheme = 0` for the standard greyscale infrared rendering;
  /// `options` are unused but kept at `0_0` to match the URL grammar.
  String satelliteTileUrlTemplate(
    RainViewerManifest manifest,
    RainViewerFrame frame, {
    int size = 512,
    int colorScheme = 0,
  }) {
    return '${manifest.host}${frame.path}/$size/{z}/{x}/{y}/$colorScheme/0_0.png';
  }

  /// Build a flutter_map tile-template URL for a given frame.
  ///
  /// `colorScheme = 3` is RainViewer's "Weather Channel" green/yellow/red
  /// palette — the classic radar look most users recognise, and it stays
  /// readable over both light and dark map backgrounds. `1_1` means
  /// smoothing on, snow on.
  ///
  /// Default `size = 512` matches MapLibre's reference tile size, so on
  /// high-DPI displays the renderer fetches at exactly the camera zoom
  /// instead of overzooming by one level (which would push us past
  /// RainViewer's z=7 ceiling).
  String tileUrlTemplate(
    RainViewerManifest manifest,
    RainViewerFrame frame, {
    int size = 512,
    int colorScheme = 3,
    bool smooth = true,
    bool showSnow = true,
  }) {
    final String options = '${smooth ? 1 : 0}_${showSnow ? 1 : 0}';
    return '${manifest.host}${frame.path}/$size/{z}/{x}/{y}/$colorScheme/$options.png';
  }
}

final Provider<Dio> rainViewerDioProvider = Provider<Dio>((Ref ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: <String, String>{'accept': 'application/json'},
  ));
});

final Provider<RainViewerApi> rainViewerApiProvider =
    Provider<RainViewerApi>((Ref ref) => RainViewerApi(ref.watch(rainViewerDioProvider)));

final Provider<RadarRepository> radarRepositoryProvider =
    Provider<RadarRepository>(
        (Ref ref) => RadarRepository(ref.watch(rainViewerApiProvider)));
