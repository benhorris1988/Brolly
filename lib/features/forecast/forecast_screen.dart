import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/units/units.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/forecast.dart';
import '../../domain/models/saved_location.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/loading_view.dart';
import '../home/home_providers.dart';
import '../settings/settings_providers.dart';

class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SavedLocation> locations = ref.watch(homeLocationsProvider);
    if (locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Forecast')),
        body: const Center(child: Text('Add a location to see the forecast.')),
      );
    }
    final SavedLocation primary = locations.first;
    final AsyncValue<WeatherForecast> forecast =
        watchForecastFor(ref, primary);
    final UnitPreferences units = ref.watch(unitPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(primary.name),
        bottom: TabBar(
          controller: _tabs,
          tabs: const <Widget>[
            Tab(text: 'Hourly'),
            Tab(text: 'Daily'),
          ],
        ),
      ),
      body: forecast.when(
        data: (WeatherForecast f) => TabBarView(
          controller: _tabs,
          children: <Widget>[
            _HourlyList(hourly: f.hourly, units: units),
            _DailyList(daily: f.daily, units: units),
          ],
        ),
        loading: () => const LoadingView(),
        error: (Object e, StackTrace _) => ErrorView(
          message: 'Could not load forecast.\n$e',
          onRetry: () => invalidateForecastFor(ref, primary),
        ),
      ),
    );
  }
}

class _HourlyList extends StatelessWidget {
  const _HourlyList({required this.hourly, required this.units});
  final List<HourlyForecast> hourly;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) {
      return const Center(child: Text('No hourly data available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: hourly.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (BuildContext context, int i) {
        final HourlyForecast h = hourly[i];
        return ListTile(
          leading: Icon(h.condition.icon),
          title: Text(DateFormat('EEE HH:mm').format(h.time)),
          subtitle: Text(h.condition.label),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                UnitFormat.formatTemperature(h.temperatureC, units.temperature),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${h.precipProbability.round()}%',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _DailyList extends StatelessWidget {
  const _DailyList({required this.daily, required this.units});
  final List<DailyForecast> daily;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Center(child: Text('No daily data available.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: daily.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int i) {
        final DailyForecast d = daily[i];
        return ListTile(
          leading: Icon(d.condition.icon, size: 32),
          title: Text(DateFormat('EEEE').format(d.date)),
          subtitle: Text(d.condition.label),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(UnitFormat.formatTemperatureBare(
                      d.minTempC, units.temperature)),
                  const Text('  /  '),
                  Text(
                    UnitFormat.formatTemperature(d.maxTempC, units.temperature),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Text('${d.precipProbability.round()}%',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
