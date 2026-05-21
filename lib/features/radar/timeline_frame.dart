import '../../data/models/rainviewer_manifest.dart';

/// A single step in the unified radar timeline. The radar screen renders
/// past / nowcast frames using RainViewer tiles and forecast hours using
/// an Open-Meteo precipitation grid.
sealed class TimelineFrame {
  DateTime get time;
}

class LiveRadarFrame extends TimelineFrame {
  LiveRadarFrame(this.source);

  final RainViewerFrame source;

  @override
  DateTime get time =>
      DateTime.fromMillisecondsSinceEpoch(source.time * 1000).toLocal();
}

class ForecastHourFrame extends TimelineFrame {
  ForecastHourFrame(this.hour);

  /// Clock-hour the frame represents (local time).
  final DateTime hour;

  @override
  DateTime get time => hour;
}
