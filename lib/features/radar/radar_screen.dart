import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/rainviewer_manifest.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/radar_repository.dart';
import '../../domain/models/saved_location.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import 'radar_providers.dart';

/// Centre of the UK — used as the default map centre when no device location.
const LatLng _ukCentre = LatLng(54.0, -2.5);

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  final MapController _mapController = MapController();
  int _frameIndex = 0;
  bool _playing = true;
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
    _mapController.dispose();
    super.dispose();
  }

  void _startPlayback() {
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_playing) return;
      final List<RainViewerFrame>? frames =
          ref.read(radarFramesProvider).asData?.value;
      if (frames == null || frames.isEmpty) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % frames.length;
      });
    });
  }

  void _togglePlay() => setState(() => _playing = !_playing);

  @override
  Widget build(BuildContext context) {
    final AsyncValue<RainViewerManifest> manifestAsync =
        ref.watch(radarManifestProvider);
    final AsyncValue<List<RainViewerFrame>> framesAsync =
        ref.watch(radarFramesProvider);
    final AsyncValue<SavedLocation?> current =
        ref.watch(currentLocationProvider);

    final LatLng centre = current.asData?.value != null
        ? LatLng(current.asData!.value!.latitude,
            current.asData!.value!.longitude)
        : _ukCentre;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(radarManifestProvider),
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
          final List<RainViewerFrame> frames =
              framesAsync.asData?.value ?? const <RainViewerFrame>[];
          if (frames.isEmpty) {
            return const Center(child: Text('No radar frames available.'));
          }
          final int safeIndex = _frameIndex.clamp(0, frames.length - 1);
          final RainViewerFrame current = frames[safeIndex];
          final RadarRepository repo = ref.read(radarRepositoryProvider);

          return Stack(
            children: <Widget>[
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: 6,
                  minZoom: 3,
                  maxZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yourname.brolly',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  // Radar overlay — swapping urlTemplate when _frameIndex
                  // changes triggers flutter_map to fetch the new frame's tiles.
                  TileLayer(
                    key: ValueKey<int>(current.time),
                    urlTemplate: repo.tileUrlTemplate(manifest, current),
                    userAgentPackageName: 'com.yourname.brolly',
                    tileProvider: CancellableNetworkTileProvider(),
                  ),
                  const RichAttributionWidget(
                    attributions: <SourceAttribution>[
                      TextSourceAttribution(
                          '© OpenStreetMap contributors • Radar by RainViewer'),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _RadarControls(
                  frames: frames,
                  index: safeIndex,
                  playing: _playing,
                  onTogglePlay: _togglePlay,
                  onScrub: (double v) =>
                      setState(() => _frameIndex = v.round()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RadarControls extends StatelessWidget {
  const _RadarControls({
    required this.frames,
    required this.index,
    required this.playing,
    required this.onTogglePlay,
    required this.onScrub,
  });

  final List<RainViewerFrame> frames;
  final int index;
  final bool playing;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;

  @override
  Widget build(BuildContext context) {
    final RainViewerFrame frame = frames[index];
    final DateTime time =
        DateTime.fromMillisecondsSinceEpoch(frame.time * 1000).toLocal();
    final bool isFuture = time.isAfter(DateTime.now());

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
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
                      Text(
                        isFuture ? 'Nowcast' : 'Past',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isFuture
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.outline,
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
      ),
    );
  }
}
