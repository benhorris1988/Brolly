import 'package:flutter/material.dart';

import '../../domain/models/forecast.dart';

/// 2-hour minute-by-minute precipitation forecast (chart). Uses the
/// `minutely_15` field from Open-Meteo. If the source is Met Office (no
/// minutely feed) the widget renders nothing.
class RainNextCard extends StatelessWidget {
  const RainNextCard({super.key, required this.minutely});

  final MinutelyPrecip? minutely;

  @override
  Widget build(BuildContext context) {
    final MinutelyPrecip? m = minutely;
    if (m == null || m.isEmpty) return const SizedBox.shrink();

    // Trim to the next 2 hours from "now".
    final DateTime now = DateTime.now();
    final DateTime cutoff = now.add(const Duration(hours: 2));
    final List<double> values = <double>[];
    final List<DateTime> times = <DateTime>[];
    for (int i = 0; i < m.times.length; i++) {
      final DateTime t = m.times[i];
      if (t.isBefore(now.subtract(const Duration(minutes: 15)))) continue;
      if (t.isAfter(cutoff)) break;
      times.add(t);
      values.add(m.precipitationMm[i]);
    }
    if (values.isEmpty) return const SizedBox.shrink();

    final double peak = values.fold<double>(
        0, (double a, double b) => b > a ? b : a);

    final String title = peak < 0.05
        ? 'No rain expected in the next 2 hours.'
        : 'Rain over the next 2 hours.';

    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A3B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: CustomPaint(
                size: Size.infinite,
                painter: _RainChartPainter(
                  values: values,
                  startTime: times.first,
                  durationMinutes: 120,
                  curveColor: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RainChartPainter extends CustomPainter {
  _RainChartPainter({
    required this.values,
    required this.startTime,
    required this.durationMinutes,
    required this.curveColor,
  });

  final List<double> values; // mm per 15-min bucket
  final DateTime startTime;
  final int durationMinutes;
  final Color curveColor;

  // Intensity reference levels for the LIGHT / MEDIUM / HEAVY bands. Open-Meteo
  // gives precipitation in millimetres over the 15-minute window — these
  // thresholds are the mm-per-15-min equivalent of light / medium / heavy rain
  // (1, 4, 8 mm/h respectively).
  static const double _light = 0.25;
  static const double _medium = 1.0;
  static const double _heavy = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 60; // room for LIGHT/MEDIUM/HEAVY labels
    const double rightPad = 4;
    const double topPad = 8;
    const double bottomPad = 22; // x-axis labels
    final double w = size.width - leftPad - rightPad;
    final double h = size.height - topPad - bottomPad;
    final double xOrigin = leftPad;
    final double yOrigin = topPad + h;

    // Grid + band labels
    final TextPainter labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );
    final List<(String, double)> bands = <(String, double)>[
      ('HEAVY', _heavy),
      ('MEDIUM', _medium),
      ('LIGHT', _light),
    ];
    final Paint gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (final (String name, double level) in bands) {
      final double y = yOrigin - _scaleY(level, h);
      // Dashed line
      _drawDashedLine(canvas, Offset(xOrigin, y),
          Offset(xOrigin + w, y), gridPaint, dash: 4, gap: 4);
      labelPainter.text = TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      );
      labelPainter.layout(minWidth: 0, maxWidth: leftPad - 8);
      labelPainter.paint(
        canvas,
        Offset(leftPad - 8 - labelPainter.width, y - labelPainter.height / 2),
      );
    }

    // Bottom x-axis labels (minutes from now: 0, 30, 60, 90, 120)
    final TextStyle axisStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 10,
    );
    for (int t = 0; t <= durationMinutes; t += 30) {
      final double x =
          xOrigin + (t / durationMinutes) * w;
      labelPainter
        ..text = TextSpan(text: '$t', style: axisStyle)
        ..layout();
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, yOrigin + 6),
      );
    }

    // Build the curve. Each value covers a 15-min slot.
    final int n = values.length;
    if (n == 0) return;
    final Path linePath = Path();
    final Path fillPath = Path();
    final List<Offset> pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final double tMinutes = i * 15.0;
      final double x = xOrigin + (tMinutes / durationMinutes) * w;
      final double y = yOrigin - _scaleY(values[i], h);
      pts.add(Offset(x, y));
    }
    if (pts.isEmpty) return;

    // Smooth curve with quadratic bezier through midpoints.
    linePath.moveTo(pts.first.dx, pts.first.dy);
    fillPath.moveTo(pts.first.dx, yOrigin);
    fillPath.lineTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final Offset prev = pts[i - 1];
      final Offset curr = pts[i];
      final Offset mid =
          Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      fillPath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(pts.last.dx, pts.last.dy);
    fillPath.lineTo(pts.last.dx, pts.last.dy);
    fillPath.lineTo(pts.last.dx, yOrigin);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            curveColor.withValues(alpha: 0.55),
            curveColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, topPad, size.width, h)),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = curveColor.withValues(alpha: 0.95)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  double _scaleY(double mm, double h) {
    // Clamp to slightly above HEAVY so peaks don't overflow the chart.
    final double top = _heavy * 1.25;
    final double v = mm.clamp(0, top);
    return (v / top) * h;
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint,
      {required double dash, required double gap}) {
    final double totalDx = to.dx - from.dx;
    final double totalDy = to.dy - from.dy;
    final double length = totalDx.abs() + totalDy.abs();
    final double step = dash + gap;
    final int steps = (length / step).floor();
    double t = 0;
    for (int i = 0; i < steps; i++) {
      final double startT = t / length;
      final double endT = (t + dash) / length;
      canvas.drawLine(
        Offset.lerp(from, to, startT)!,
        Offset.lerp(from, to, endT)!,
        paint,
      );
      t += step;
    }
  }

  @override
  bool shouldRepaint(covariant _RainChartPainter old) =>
      old.values != values ||
      old.startTime != startTime ||
      old.curveColor != curveColor;
}
