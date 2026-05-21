import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maplibre/maplibre.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../data/models/rainviewer_manifest.dart';
import '../../data/repositories/radar_repository.dart';
import '../../domain/models/forecast.dart';
import '../../domain/models/saved_location.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../home/home_providers.dart';
import 'radar_providers.dart';
import 'timeline_frame.dart';

const String _openFreeMapStyle =
    'https://tiles.openfreemap.org/styles/positron';
const Geographic _ukCentre = Geographic(lon: -2.5, lat: 54.0);
const double _locationZoom = 7;
const double _ukZoom = 6;
const double _maxZoomCap = 7;

const String _radarSourceId = 'rainviewer-radar';
const String _radarLayerId = 'rainviewer-radar';
const String _cloudsSourceId = 'rainviewer-clouds';
const String _cloudsLayerId = 'rainviewer-clouds';
const String _forecastSourceId = 'forecast-precip';
const String _forecastLayerId = 'forecast-precip';

int _closestToNow(List<TimelineFrame> frames) {
  final DateTime now = DateTime.now();
  int bestIdx = 0;
  Duration bestDiff = (frames.first.time.difference(now)).abs();
  for (int i = 1; i < frames.length; i++) {
    final Duration d = (frames[i].time.difference(now)).abs();
    if (d < bestDiff) {
      bestDiff = d;
      bestIdx = i;
    }
  }
  return bestIdx;
}

int _findClosestFrame(List<TimelineFrame> frames, DateTime target) {
  int bestIdx = 0;
  Duration bestDiff = (frames.first.time.difference(target)).abs();
  for (int i = 1; i < frames.length; i++) {
    final Duration d = (frames[i].time.difference(target)).abs();
    if (d < bestDiff) {
      bestDiff = d;
      bestIdx = i;
    }
  }
  return bestIdx;
}

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  StyleController? _styleController;
  int _frameIndex = 0;
  bool _playing = false;
  bool _showClouds = false;
  bool _didSetInitialFrame = false;

  // Tracks what's currently in the style so re-applies are no-ops when the
  // selection hasn't changed. Two sources are mutually exclusive at any time:
  // either a RainViewer raster (live) or a forecast circle layer.
  int? _appliedLiveFrameTime;
  DateTime? _appliedForecastHour;
  int? _appliedCloudsFrameTime;

  Timer? _playTimer;
  Timer? _manifestRefreshTimer;

  @override
  void initState() {
    super.initState();
    _startPlayback();
    _manifestRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      ref.invalidate(radarManifestProvider);
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _manifestRefreshTimer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_playing) return;
      final List<TimelineFrame>? frames =
          ref.read(timelineFramesProvider).asData?.value;
      if (frames == null || frames.isEmpty) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % frames.length;
      });
    });
  }

  void _togglePlay() => setState(() => _playing = !_playing);

  void _toggleClouds() {
    setState(() {
      _showClouds = !_showClouds;
      _appliedCloudsFrameTime = null;
      _appliedLiveFrameTime = null;
      _appliedForecastHour = null;
    });
  }

  Future<void> _applyState({
    required TimelineFrame frame,
    required RainViewerManifest manifest,
    PrecipGrid? forecastGrid,
  }) async {
    final StyleController? style = _styleController;
    if (style == null) return;

    final RainViewerFrame? cloudsFrame =
        (_showClouds && manifest.satellite != null &&
                manifest.satellite!.infrared.isNotEmpty)
            ? manifest.satellite!.infrared.last
            : null;

    final RadarRepository repo = ref.read(radarRepositoryProvider);

    try {
      // 1. Tear down anything currently rendered.
      if (_appliedLiveFrameTime != null) {
        await style.removeLayer(_radarLayerId);
        await style.removeSource(_radarSourceId);
        _appliedLiveFrameTime = null;
      }
      if (_appliedForecastHour != null) {
        await style.removeLayer(_forecastLayerId);
        await style.removeSource(_forecastSourceId);
        _appliedForecastHour = null;
      }
      if (_appliedCloudsFrameTime != null) {
        await style.removeLayer(_cloudsLayerId);
        await style.removeSource(_cloudsSourceId);
        _appliedCloudsFrameTime = null;
      }

      // 2. Clouds always go beneath the active rain layer.
      if (cloudsFrame != null) {
        await style.addSource(RasterSource(
          id: _cloudsSourceId,
          tiles: <String>[repo.satelliteTileUrlTemplate(manifest, cloudsFrame)],
          tileSize: 512,
          maxZoom: 7,
          attribution: 'Clouds by RainViewer',
        ));
        await style.addLayer(const RasterStyleLayer(
          id: _cloudsLayerId,
          sourceId: _cloudsSourceId,
          paint: <String, Object>{'raster-opacity': 0.55},
        ));
        _appliedCloudsFrameTime = cloudsFrame.time;
      }

      // 3. The frame-specific layer.
      switch (frame) {
        case LiveRadarFrame(:final RainViewerFrame source):
          await style.addSource(RasterSource(
            id: _radarSourceId,
            tiles: <String>[repo.tileUrlTemplate(manifest, source)],
            tileSize: 512,
            maxZoom: 7,
            attribution: 'Radar by RainViewer',
          ));
          await style.addLayer(const RasterStyleLayer(
            id: _radarLayerId,
            sourceId: _radarSourceId,
          ));
          _appliedLiveFrameTime = source.time;
        case ForecastHourFrame(:final DateTime hour):
          if (forecastGrid == null || forecastGrid.isEmpty) {
            // Grid not ready yet — fall through with no layer; the user
            // sees the basemap and we'll re-apply once the future resolves.
            break;
          }
          final int hourIndex = _matchHour(forecastGrid.hours, hour);
          if (hourIndex < 0) break;
          final String geojson = _buildForecastGeoJson(forecastGrid, hourIndex);
          await style.addSource(GeoJsonSource(
            id: _forecastSourceId,
            data: geojson,
          ));
          // Step colour expression: anything under 0.05 mm/h reads as a
          // faint anchor dot (so the user can see the grid is rendering
          // even on dry hours); 0.05+ jumps to coloured rain bands.
          await style.addLayer(const CircleStyleLayer(
            id: _forecastLayerId,
            sourceId: _forecastSourceId,
            paint: <String, Object>{
              'circle-radius': <Object>[
                'interpolate',
                <String>['linear'],
                <String>['zoom'],
                3, 6,
                5, 14,
                7, 28,
              ],
              'circle-color': <Object>[
                'step',
                <Object>['get', 'precip'],
                '#9E9E9E', // <0.05 mm/h — faint grey anchor
                0.05, '#A8E6A0',
                0.5, '#5CC85C',
                2.0, '#F1E15B',
                5.0, '#F58E3C',
                10.0, '#D9421A',
              ],
              'circle-opacity': <Object>[
                'step',
                <Object>['get', 'precip'],
                0.18, // faint when dry
                0.05, 0.75, // visible when raining
              ],
              'circle-blur': 0.6,
            },
          ));
          _appliedForecastHour = hour;
      }
    } catch (e, st) {
      debugPrint('Failed to apply layers: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  static int _matchHour(List<DateTime> hours, DateTime target) {
    for (int i = 0; i < hours.length; i++) {
      if (hours[i].year == target.year &&
          hours[i].month == target.month &&
          hours[i].day == target.day &&
          hours[i].hour == target.hour) {
        return i;
      }
    }
    return -1;
  }

  static String _buildForecastGeoJson(PrecipGrid grid, int hourIndex) {
    return jsonEncode(<String, Object?>{
      'type': 'FeatureCollection',
      'features': <Map<String, Object?>>[
        for (final PrecipGridPoint p in grid.points)
          <String, Object?>{
            'type': 'Feature',
            'geometry': <String, Object?>{
              'type': 'Point',
              'coordinates': <double>[p.longitude, p.latitude],
            },
            'properties': <String, Object?>{
              'precip': p.precipMmPerHour[hourIndex],
            },
          },
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<TimelineFrame>>>(timelineFramesProvider,
        (AsyncValue<List<TimelineFrame>>? prev,
            AsyncValue<List<TimelineFrame>> next) {
      final List<TimelineFrame>? frames = next.asData?.value;
      if (frames == null || frames.isEmpty) return;
      if (_didSetInitialFrame) return;
      _didSetInitialFrame = true;
      final int closest = _closestToNow(frames);
      if (closest != _frameIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _frameIndex = closest);
        });
      }
    });

    final AsyncValue<RainViewerManifest> manifestAsync =
        ref.watch(radarManifestProvider);
    final AsyncValue<List<TimelineFrame>> framesAsync =
        ref.watch(timelineFramesProvider);
    final List<SavedLocation> locations = ref.watch(homeLocationsProvider);

    final SavedLocation? focus =
        locations.isNotEmpty ? locations.first : null;
    final Geographic centre = focus != null
        ? Geographic(lon: focus.longitude, lat: focus.latitude)
        : _ukCentre;
    final double initialZoom = focus != null ? _locationZoom : _ukZoom;

    // Quantise the precip grid key to ~0.5° so small viewport shifts don't
    // refetch. The grid covers ~160km × 240km around the focus already.
    final ({double lat, double lon}) gridKey = focus != null
        ? (
            lat: (focus.latitude * 2).round() / 2,
            lon: (focus.longitude * 2).round() / 2,
          )
        : (lat: 54.0, lon: -2.5);

    final bool cloudsAvailable =
        manifestAsync.asData?.value.satellite?.infrared.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar'),
        actions: <Widget>[
          if (cloudsAvailable)
            IconButton(
              tooltip: _showClouds ? 'Hide clouds' : 'Show clouds',
              icon: Icon(_showClouds ? Icons.cloud : Icons.cloud_outlined),
              onPressed: _toggleClouds,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(radarManifestProvider);
              ref.invalidate(precipGridProvider(gridKey));
            },
          ),
        ],
      ),
      body: manifestAsync.when(
        loading: () => const LoadingView(message: 'Loading radar…'),
        error: (Object e, StackTrace _) => ErrorView(
          message: 'Could not load radar.\n$e',
          onRetry: () => ref.invalidate(radarManifestProvider),
        ),
        data: (RainViewerManifest manifest) {
          final List<TimelineFrame> frames =
              framesAsync.asData?.value ?? const <TimelineFrame>[];
          if (frames.isEmpty) {
            return const Center(child: Text('No radar frames available.'));
          }
          final int safeIndex = _frameIndex.clamp(0, frames.length - 1);
          final TimelineFrame current = frames[safeIndex];

          // Forecast grid is fetched lazily — only when the user scrubs
          // into the forecast portion of the timeline.
          PrecipGrid? grid;
          if (current is ForecastHourFrame) {
            grid = ref.watch(precipGridProvider(gridKey)).asData?.value;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _applyState(
              frame: current,
              manifest: manifest,
              forecastGrid: grid,
            );
          });

          return Stack(
            children: <Widget>[
              MapLibreMap(
                options: MapOptions(
                  initStyle: _openFreeMapStyle,
                  initCenter: centre,
                  initZoom: initialZoom,
                  minZoom: 3,
                  maxZoom: _maxZoomCap,
                ),
                onStyleLoaded: (StyleController style) {
                  _styleController = style;
                  _appliedLiveFrameTime = null;
                  _appliedForecastHour = null;
                  _appliedCloudsFrameTime = null;
                  _applyState(
                    frame: current,
                    manifest: manifest,
                    forecastGrid: grid,
                  );
                },
              ),
              if (current is ForecastHourFrame)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(child: _ForecastStatusBadge(
                    grid: grid,
                    hour: current.hour,
                  )),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: PointerInterceptor(
                  child: _RadarControls(
                    frames: frames,
                    index: safeIndex,
                    playing: _playing,
                    isForecast: current is ForecastHourFrame,
                    onTogglePlay: _togglePlay,
                    onScrub: (double v) =>
                        setState(() => _frameIndex = v.round()),
                    onJump: (int i) => setState(() {
                      _frameIndex = i;
                      _playing = false;
                    }),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '© OpenFreeMap • RainViewer • Open-Meteo',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ForecastStatusBadge extends StatelessWidget {
  const _ForecastStatusBadge({required this.grid, required this.hour});

  final PrecipGrid? grid;
  final DateTime hour;

  @override
  Widget build(BuildContext context) {
    if (grid == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Loading forecast…'),
            ],
          ),
        ),
      );
    }
    final int idx = _matchHourIndex(grid!.hours, hour);
    if (idx < 0) return const SizedBox.shrink();
    double peak = 0;
    for (final PrecipGridPoint p in grid!.points) {
      if (idx < p.precipMmPerHour.length && p.precipMmPerHour[idx] > peak) {
        peak = p.precipMmPerHour[idx];
      }
    }
    if (peak >= 0.05) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Model shows no significant rain — live radar may still see local showers',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _matchHourIndex(List<DateTime> hours, DateTime target) {
    for (int i = 0; i < hours.length; i++) {
      if (hours[i].year == target.year &&
          hours[i].month == target.month &&
          hours[i].day == target.day &&
          hours[i].hour == target.hour) {
        return i;
      }
    }
    return -1;
  }
}

class _RadarControls extends StatelessWidget {
  const _RadarControls({
    required this.frames,
    required this.index,
    required this.playing,
    required this.isForecast,
    required this.onTogglePlay,
    required this.onScrub,
    required this.onJump,
  });

  final List<TimelineFrame> frames;
  final int index;
  final bool playing;
  final bool isForecast;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TimelineFrame frame = frames[index];
    final DateTime time = frame.time;
    final DateTime now = DateTime.now();
    final Duration delta = time.difference(now);
    final String relative = _formatRelative(delta);
    final bool isFuture = delta.inMinutes >= 5;
    final int nowFrameIndex = _findClosestFrame(frames, now);
    final int latestIndex = frames.length - 1;
    final DateTime latestTime = frames.last.time;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: scheme.surface.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                children: <Widget>[
                  _JumpChip(
                    label: 'Now',
                    selected: index == nowFrameIndex,
                    onTap: () => onJump(nowFrameIndex),
                  ),
                  const SizedBox(width: 6),
                  _JumpChip(
                    label: '+1h',
                    selected: false,
                    onTap: () => onJump(_findClosestFrame(
                        frames, now.add(const Duration(hours: 1)))),
                  ),
                  const SizedBox(width: 6),
                  _JumpChip(
                    label: '+3h',
                    selected: false,
                    onTap: () => onJump(_findClosestFrame(
                        frames, now.add(const Duration(hours: 3)))),
                  ),
                  const SizedBox(width: 6),
                  _JumpChip(
                    label: 'End (${DateFormat('HH:mm').format(latestTime)})',
                    selected: index == latestIndex,
                    onTap: () => onJump(latestIndex),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                IconButton.filled(
                  onPressed: onTogglePlay,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            DateFormat('HH:mm').format(time),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? scheme.tertiaryContainer
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              relative,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isFuture
                                        ? scheme.onTertiaryContainer
                                        : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isForecast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Forecast',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      Slider(
                        value: index.toDouble(),
                        min: 0,
                        max: (frames.length - 1).toDouble(),
                        divisions: frames.length - 1,
                        onChanged: onScrub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRelative(Duration d) {
    if (d.inMinutes.abs() < 5) return 'Now';
    if (d.isNegative) {
      final int minutes = -d.inMinutes;
      if (minutes < 60) return '-${minutes}m';
      return '-${(minutes / 60).toStringAsFixed(1)}h';
    }
    final int minutes = d.inMinutes;
    if (minutes < 60) return '+${minutes}m';
    return '+${(minutes / 60).toStringAsFixed(1)}h';
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
