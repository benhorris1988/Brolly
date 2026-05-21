import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weather_icons/weather_icons.dart';

import '../../core/units/units.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/forecast.dart';
import '../../domain/models/saved_location.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../settings/settings_providers.dart';
import 'add_location_sheet.dart';
import 'home_providers.dart';
import 'rain_next_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SavedLocation> locations = ref.watch(homeLocationsProvider);
    final AsyncValue<SavedLocation?> current =
        ref.watch(currentLocationProvider);

    return Scaffold(
      body: current.isLoading && locations.isEmpty
          ? const LoadingView(message: 'Finding your location…')
          : locations.isEmpty
              ? _EmptyState(onAdd: () => _showAddSheet(context))
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: locations.length,
                        onPageChanged: (int i) => setState(() => _page = i),
                        itemBuilder: (BuildContext _, int i) =>
                            _LocationPage(
                          location: locations[i],
                          onAdd: () => _showAddSheet(context),
                        ),
                      ),
                    ),
                    if (locations.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _DotsIndicator(
                          count: locations.length,
                          index: _page,
                        ),
                      ),
                  ],
                ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext _) => const AddLocationSheet(),
    );
  }
}

class _LocationPage extends ConsumerStatefulWidget {
  const _LocationPage({required this.location, required this.onAdd});

  final SavedLocation location;
  final VoidCallback onAdd;

  @override
  ConsumerState<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends ConsumerState<_LocationPage> {
  int _selectedDay = 0;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WeatherForecast> forecast =
        watchForecastFor(ref, widget.location);
    final UnitPreferences units = ref.watch(unitPreferencesProvider);

    return RefreshIndicator(
      onRefresh: () async => invalidateForecastFor(ref, widget.location),
      child: forecast.when(
        loading: () => const LoadingView(),
        error: (Object e, StackTrace _) => ErrorView(
          message: 'Could not load forecast.\n$e',
          onRetry: () => invalidateForecastFor(ref, widget.location),
        ),
        data: (WeatherForecast f) {
          final List<DailyForecast> days = f.daily;
          final int safeDay =
              days.isEmpty ? 0 : _selectedDay.clamp(0, days.length - 1);
          final DailyForecast? selectedDay =
              days.isEmpty ? null : days[safeDay];
          final List<HourlyForecast> hoursForDay = selectedDay == null
              ? const <HourlyForecast>[]
              : _hoursForDay(f.hourly, selectedDay.date);
          final HourlyForecast heroHour = _heroHourFor(f, safeDay);

          return Column(
            children: <Widget>[
              _Hero(
                location: widget.location,
                current: heroHour,
                units: units,
                isNight: _heroIsNight(f, safeDay, heroHour),
                onAdd: widget.onAdd,
              ),
              RainNextCard(minutely: f.minutely),
              if (days.isNotEmpty)
                _DayStrip(
                  days: days,
                  selected: safeDay,
                  onSelect: (int i) => setState(() => _selectedDay = i),
                  units: units,
                ),
              if (selectedDay != null) ...<Widget>[
                _DaySummary(day: selectedDay, units: units),
                const Divider(height: 1),
              ],
              Expanded(
                child: hoursForDay.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: <Widget>[
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              days.isEmpty
                                  ? 'No forecast data available.'
                                  : 'No hourly data for this day.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: hoursForDay.length,
                        itemBuilder: (BuildContext context, int i) {
                          final HourlyForecast h = hoursForDay[i];
                          return _HourRow(hour: h, units: units);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isNight(WeatherForecast f) {
    final DailyForecast? today =
        f.daily.isNotEmpty ? f.daily.first : null;
    final DateTime now = DateTime.now();
    if (today?.sunrise != null && now.isBefore(today!.sunrise!)) return true;
    if (today?.sunset != null && now.isAfter(today!.sunset!)) return true;
    return false;
  }

  /// Pick what to show in the hero for the selected day.
  ///   * day 0 (Today)  -> the live "current" observation
  ///   * future days    -> hourly entry closest to early afternoon, which
  ///                       reads as a representative "what the day feels
  ///                       like" snapshot for the hero card.
  HourlyForecast _heroHourFor(WeatherForecast f, int dayIndex) {
    if (dayIndex <= 0 || dayIndex >= f.daily.length) return f.current;
    final DailyForecast day = f.daily[dayIndex];
    final DateTime target =
        DateTime(day.date.year, day.date.month, day.date.day, 13);
    HourlyForecast? best;
    Duration bestDiff = const Duration(days: 999);
    for (final HourlyForecast h in f.hourly) {
      final Duration diff = h.time.difference(target).abs();
      if (best == null || diff < bestDiff) {
        best = h;
        bestDiff = diff;
      }
    }
    return best ?? f.current;
  }

  bool _heroIsNight(WeatherForecast f, int dayIndex, HourlyForecast hero) {
    if (dayIndex <= 0 || dayIndex >= f.daily.length) return _isNight(f);
    final DailyForecast day = f.daily[dayIndex];
    if (day.sunrise != null && hero.time.isBefore(day.sunrise!)) return true;
    if (day.sunset != null && hero.time.isAfter(day.sunset!)) return true;
    return false;
  }

  List<HourlyForecast> _hoursForDay(
      List<HourlyForecast> all, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    return all
        .where((HourlyForecast h) =>
            !h.time.isBefore(start) && h.time.isBefore(end))
        .toList(growable: false);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.location,
    required this.current,
    required this.units,
    required this.isNight,
    required this.onAdd,
  });

  final SavedLocation location;
  final HourlyForecast current;
  final UnitPreferences units;
  final bool isNight;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return _HeroBackground(
      condition: current.condition,
      isNight: isNight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 12,
          20,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (location.isCurrent)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.my_location,
                        size: 18, color: Colors.white),
                  ),
                Expanded(
                  child: Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Add location',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_location_alt_outlined,
                      color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          UnitFormat.formatTemperatureBare(
                              current.temperatureC, units.temperature),
                          style: text.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 84,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.condition.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _WindChip(current: current, units: units),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBackground extends StatefulWidget {
  const _HeroBackground({
    required this.condition,
    required this.isNight,
    required this.child,
  });

  final WeatherCondition condition;
  final bool isNight;
  final Widget child;

  @override
  State<_HeroBackground> createState() => _HeroBackgroundState();
}

class _HeroBackgroundState extends State<_HeroBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext _, Widget? __) {
                  return CustomPaint(
                    painter: _HeroPainter(
                      condition: widget.condition,
                      isNight: widget.isNight,
                      t: _controller.value,
                    ),
                  );
                },
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({
    required this.condition,
    required this.isNight,
    required this.t,
  });

  final WeatherCondition condition;
  final bool isNight;
  final double t; // 0..1, repeats

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    _paintGradient(canvas, rect);

    switch (condition) {
      case WeatherCondition.clear:
        _paintCelestial(canvas, size);
      case WeatherCondition.partlyCloudy:
        _paintCelestial(canvas, size);
        _paintClouds(canvas, size, count: 2, opacity: 0.85);
      case WeatherCondition.cloudy:
        _paintClouds(canvas, size, count: 3, opacity: 0.95);
      case WeatherCondition.overcast:
        _paintClouds(canvas, size, count: 4, opacity: 1.0, dark: true);
      case WeatherCondition.fog:
        _paintFog(canvas, size);
      case WeatherCondition.drizzle:
        _paintClouds(canvas, size, count: 2, opacity: 0.9);
        _paintRain(canvas, size, drops: 40, length: 6, opacity: 0.6);
      case WeatherCondition.rain:
      case WeatherCondition.showers:
        _paintClouds(canvas, size, count: 3, opacity: 0.95);
        _paintRain(canvas, size, drops: 60, length: 12, opacity: 0.8);
      case WeatherCondition.heavyRain:
        _paintClouds(canvas, size, count: 4, opacity: 1.0, dark: true);
        _paintRain(canvas, size, drops: 90, length: 16, opacity: 0.95);
      case WeatherCondition.sleet:
        _paintClouds(canvas, size, count: 3, opacity: 0.95);
        _paintRain(canvas, size, drops: 40, length: 8, opacity: 0.75);
        _paintSnow(canvas, size, flakes: 25);
      case WeatherCondition.snow:
        _paintClouds(canvas, size, count: 3, opacity: 0.95, light: true);
        _paintSnow(canvas, size, flakes: 60);
      case WeatherCondition.thunderstorm:
        _paintClouds(canvas, size, count: 4, opacity: 1.0, dark: true);
        _paintRain(canvas, size, drops: 70, length: 14, opacity: 0.9);
        _paintLightning(canvas, size);
      case WeatherCondition.unknown:
        break;
    }
  }

  void _paintGradient(Canvas canvas, Rect rect) {
    final List<Color> colors = _gradient();
    final Paint p = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, p);
  }

  List<Color> _gradient() {
    if (isNight) {
      return const <Color>[Color(0xFF0B1E3B), Color(0xFF1C355E)];
    }
    switch (condition) {
      case WeatherCondition.clear:
        return const <Color>[Color(0xFF1E90D8), Color(0xFF7AC7EE)];
      case WeatherCondition.partlyCloudy:
        return const <Color>[Color(0xFF4488B5), Color(0xFF8ABBD8)];
      case WeatherCondition.cloudy:
        return const <Color>[Color(0xFF5E7A92), Color(0xFF93AABE)];
      case WeatherCondition.overcast:
      case WeatherCondition.fog:
        return const <Color>[Color(0xFF566370), Color(0xFF8794A2)];
      case WeatherCondition.drizzle:
      case WeatherCondition.rain:
      case WeatherCondition.showers:
        return const <Color>[Color(0xFF3D6985), Color(0xFF74A0BE)];
      case WeatherCondition.heavyRain:
        return const <Color>[Color(0xFF24364B), Color(0xFF4A6379)];
      case WeatherCondition.sleet:
        return const <Color>[Color(0xFF8AA0B5), Color(0xFFB8C8D6)];
      case WeatherCondition.snow:
        return const <Color>[Color(0xFFA7BACD), Color(0xFFD5E1EC)];
      case WeatherCondition.thunderstorm:
        return const <Color>[Color(0xFF1F2A3B), Color(0xFF3F4F66)];
      case WeatherCondition.unknown:
        return const <Color>[Color(0xFF6C8FA8), Color(0xFF9BB4C7)];
    }
  }

  void _paintCelestial(Canvas canvas, Size size) {
    // Sun (day) or moon (night) in the upper-right with a soft halo.
    final Offset centre = Offset(size.width - 60, 50);
    final Color body = isNight ? const Color(0xFFE6ECF5) : const Color(0xFFFFD66B);
    final Color glow = body.withValues(alpha: 0.35);

    canvas.drawCircle(
      centre,
      54,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[glow, glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: 54)),
    );
    canvas.drawCircle(centre, 24, Paint()..color = body);
  }

  void _paintClouds(
    Canvas canvas,
    Size size, {
    required int count,
    required double opacity,
    bool dark = false,
    bool light = false,
  }) {
    final Color base = light
        ? Colors.white
        : dark
            ? const Color(0xFF4A5664)
            : const Color(0xFFE8EEF4);
    final Paint paint = Paint()..color = base.withValues(alpha: opacity);

    // Slow horizontal drift across the panel.
    final double drift = t * size.width * 0.4;

    for (int i = 0; i < count; i++) {
      final double cx =
          ((size.width / count) * i + drift) % (size.width + 200) - 100;
      final double cy = 30 + (i * 18) % 40;
      _drawCloud(canvas, paint, Offset(cx, cy), scale: 1.0 + i * 0.15);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset c, {double scale = 1.0}) {
    final double r = 22 * scale;
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c.translate(r * 1.1, 4), r * 0.9, paint);
    canvas.drawCircle(c.translate(-r * 1.0, 6), r * 0.85, paint);
    canvas.drawCircle(c.translate(r * 0.4, -r * 0.7), r * 0.75, paint);
  }

  void _paintFog(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0xFFE8EEF4).withValues(alpha: 0.7);
    for (int i = 0; i < 4; i++) {
      final double y = 30 + i * 24.0;
      final double drift = t * size.width * 0.2 + i * 30.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              ((-100 + drift) % (size.width + 200)) - 100, y, 240, 14),
          const Radius.circular(8),
        ),
        p,
      );
    }
  }

  void _paintRain(
    Canvas canvas,
    Size size, {
    required int drops,
    required double length,
    required double opacity,
  }) {
    final Paint p = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final math.Random rng = math.Random(7);
    final double cycle = size.height + 120;
    for (int i = 0; i < drops; i++) {
      final double x = rng.nextDouble() * size.width;
      final double phase = rng.nextDouble();
      final double y = ((t + phase) * cycle) % cycle - 40;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 4, y + length),
        p,
      );
    }
  }

  void _paintSnow(Canvas canvas, Size size, {required int flakes}) {
    final Paint p = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final math.Random rng = math.Random(11);
    final double cycle = size.height + 80;
    for (int i = 0; i < flakes; i++) {
      final double phase = rng.nextDouble();
      final double baseX = rng.nextDouble() * size.width;
      final double wobble =
          math.sin((t + phase) * 6.28 + i * 0.5) * 8;
      final double y = ((t * 0.6 + phase) * cycle) % cycle - 20;
      canvas.drawCircle(Offset(baseX + wobble, y), 2.2, p);
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    // Flash twice per cycle.
    final double phase = (t * 2) % 1;
    if (phase > 0.05) return;
    final double opacity = (0.05 - phase) / 0.05;
    final Paint flash = Paint()
      ..color = const Color(0xFFFFF7C8).withValues(alpha: opacity);
    canvas.drawRect(Offset.zero & size, flash);
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.t != t || old.condition != condition || old.isNight != isNight;
}

class _WindChip extends StatelessWidget {
  const _WindChip({required this.current, required this.units});

  final HourlyForecast current;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Transform.rotate(
          angle: current.windDirectionDeg * 3.14159 / 180,
          child: const Icon(WeatherIcons.wind, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 6),
        Text(
          UnitFormat.formatWindSpeed(current.windSpeedKph, units.windSpeed),
          style: text.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
    required this.units,
  });

  final List<DailyForecast> days;
  final int selected;
  final ValueChanged<int> onSelect;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          return _DayChip(
            day: days[i],
            index: i,
            selected: i == selected,
            onTap: () => onSelect(i),
            units: units,
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.units,
  });

  final DailyForecast day;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color fg = selected ? scheme.onPrimary : scheme.onSurface;
    final Color fgMuted = selected
        ? scheme.onPrimary.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _label(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            BoxedIcon(
              day.condition.icon,
              size: 22,
              color: selected ? fg : day.condition.iconColor(isNight: false),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  UnitFormat.formatTemperatureBare(
                      day.maxTempC, units.temperature),
                  style: text.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  UnitFormat.formatTemperatureBare(
                      day.minTempC, units.temperature),
                  style: text.titleSmall?.copyWith(
                    color: fgMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label() {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return DateFormat('EEE dd/MM').format(day.date);
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, required this.units});

  final DailyForecast day;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: <Widget>[
          BoxedIcon(
            day.condition.icon,
            size: 32,
            color: day.condition.iconColor(isNight: false),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(day.condition.label,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'High ${UnitFormat.formatTemperature(day.maxTempC, units.temperature)} • '
                  'Low ${UnitFormat.formatTemperature(day.minTempC, units.temperature)}',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(WeatherIcons.raindrop,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${day.precipProbability.round()}%',
                      style: text.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(WeatherIcons.wind,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    UnitFormat.formatWindSpeed(
                        day.windSpeedKph, units.windSpeed),
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.hour, required this.units});

  final HourlyForecast hour;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final DateTime local = hour.time.toLocal();
    final bool night = local.hour < 6 || local.hour >= 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Text(DateFormat('HH:mm').format(local),
                style: text.titleMedium),
          ),
          BoxedIcon(
            hour.condition.iconFor(isNight: night),
            size: 26,
            color: hour.condition.iconColor(isNight: night),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(hour.condition.label,
                    style: text.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(WeatherIcons.wind,
                        size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      UnitFormat.formatWindSpeed(
                          hour.windSpeedKph, units.windSpeed),
                      style: text.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Icon(WeatherIcons.raindrop,
                        size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${hour.precipProbability.round()}%',
                        style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            UnitFormat.formatTemperature(hour.temperatureC, units.temperature),
            style: text.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.umbrella,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('Welcome to Brolly',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Grant location access on the bottom-nav prompt, or pin a '
              'location to get started.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add location'),
            ),
          ],
        ),
      ),
    );
  }
}
