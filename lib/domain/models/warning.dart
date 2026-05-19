import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../core/theme/app_theme.dart';

enum WarningSeverity { yellow, amber, red, unknown }

extension WarningSeverityX on WarningSeverity {
  String get label {
    switch (this) {
      case WarningSeverity.yellow:
        return 'Yellow';
      case WarningSeverity.amber:
        return 'Amber';
      case WarningSeverity.red:
        return 'Red';
      case WarningSeverity.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case WarningSeverity.yellow:
        return BrollyColors.warningYellow;
      case WarningSeverity.amber:
        return BrollyColors.warningAmber;
      case WarningSeverity.red:
        return BrollyColors.warningRed;
      case WarningSeverity.unknown:
        return Colors.grey;
    }
  }

  static WarningSeverity fromString(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'yellow':
        return WarningSeverity.yellow;
      case 'amber':
        return WarningSeverity.amber;
      case 'red':
        return WarningSeverity.red;
      default:
        return WarningSeverity.unknown;
    }
  }
}

@immutable
class SevereWarning {
  const SevereWarning({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.validFrom,
    required this.validTo,
    required this.regions,
  });

  final String id;
  final String title;
  final String description;
  final WarningSeverity severity;
  final String type; // rain, wind, snow, ice, fog, thunderstorm, …
  final DateTime validFrom;
  final DateTime validTo;
  final List<String> regions;
}
