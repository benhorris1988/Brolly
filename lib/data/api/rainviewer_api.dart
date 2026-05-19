import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/rainviewer_manifest.dart';

part 'rainviewer_api.g.dart';

/// RainViewer — public, key-less radar tile manifest.
///
/// The manifest is updated every 10 minutes; the repository refreshes its
/// cache every 5 minutes to be safe.
///
/// Tile URL pattern (applied after we resolve a frame's `path`):
///   `https://tilecache.rainviewer.com/{path}/{size}/{z}/{x}/{y}/{color}/{options}.png`
/// where `color = 2` is the universal blue palette and `options = 1_1` means
/// smoothing on, snow on.
@RestApi(baseUrl: 'https://api.rainviewer.com')
abstract class RainViewerApi {
  factory RainViewerApi(Dio dio, {String baseUrl}) = _RainViewerApi;

  @GET('/public/weather-maps.json')
  Future<RainViewerManifest> getManifest();
}
