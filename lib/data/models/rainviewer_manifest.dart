import 'package:json_annotation/json_annotation.dart';

part 'rainviewer_manifest.g.dart';

@JsonSerializable(explicitToJson: true)
class RainViewerManifest {
  const RainViewerManifest({
    required this.version,
    required this.generated,
    required this.host,
    required this.radar,
    this.satellite,
  });

  final String version;
  final int generated;
  final String host;
  final RainViewerRadar radar;
  final RainViewerSatellite? satellite;

  factory RainViewerManifest.fromJson(Map<String, dynamic> json) =>
      _$RainViewerManifestFromJson(json);
  Map<String, dynamic> toJson() => _$RainViewerManifestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RainViewerRadar {
  const RainViewerRadar({required this.past, required this.nowcast});

  final List<RainViewerFrame> past;
  final List<RainViewerFrame> nowcast;

  factory RainViewerRadar.fromJson(Map<String, dynamic> json) =>
      _$RainViewerRadarFromJson(json);
  Map<String, dynamic> toJson() => _$RainViewerRadarToJson(this);
}

@JsonSerializable(explicitToJson: true)
class RainViewerSatellite {
  const RainViewerSatellite({required this.infrared});

  final List<RainViewerFrame> infrared;

  factory RainViewerSatellite.fromJson(Map<String, dynamic> json) =>
      _$RainViewerSatelliteFromJson(json);
  Map<String, dynamic> toJson() => _$RainViewerSatelliteToJson(this);
}

@JsonSerializable()
class RainViewerFrame {
  const RainViewerFrame({required this.time, required this.path});

  /// Unix seconds.
  final int time;
  /// e.g. `/v2/radar/1700000000`
  final String path;

  factory RainViewerFrame.fromJson(Map<String, dynamic> json) =>
      _$RainViewerFrameFromJson(json);
  Map<String, dynamic> toJson() => _$RainViewerFrameToJson(this);
}
