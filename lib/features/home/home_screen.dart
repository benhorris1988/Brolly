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
import '../settings/settings_providers.dart';
import 'add_location_sheet.dart';
import 'home_providers.dart';

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
      appBar: AppBar(
        title: const Text('Brolly'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Add location',
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (BuildContext _) => const AddLocationSheet(),
            ),
          ),
        ],
      ),
      body: current.isLoading && locations.isEmpty
          ? const LoadingView(message: 'Finding your location…')
          : locations.isEmpty
              ? _EmptyState(
                  onAdd: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (BuildContext _) => const AddLocationSheet(),
                  ),
                )
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: locations.length,
                        onPageChanged: (int i) => setState(() => _page = i),
                        itemBuilder: (BuildContext _, int i) =>
                            _LocationCard(location: locations[i]),
                      ),
                    ),
                    if (locations.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _DotsIndicator(
                          count: locations.length,
                          index: _page,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.location});
  final SavedLocation location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<WeatherForecast> forecast =
        watchForecastFor(ref, location);
    final UnitPreferences units = ref.watch(unitPreferencesProvider);

    return RefreshIndicator(
      onRefresh: () async => invalidateForecastFor(ref, location),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              if (location.isCurrent)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.my_location, size: 18),
                ),
              Expanded(
                child: Text(
                  location.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          forecast.when(
            data: (WeatherForecast f) => _ForecastHero(forecast: f, units: units),
            loading: () => const SizedBox(
                height: 240, child: LoadingView()),
            error: (Object e, StackTrace _) => ErrorView(
              message: 'Could not load forecast.\n$e',
              onRetry: () => invalidateForecastFor(ref, location),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastHero extends StatelessWidget {
  const _ForecastHero({required this.forecast, required this.units});

  final WeatherForecast forecast;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    final HourlyForecast c = forecast.current;
    final DailyForecast? today =
        forecast.daily.isNotEmpty ? forecast.daily.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(c.condition.icon,
                size: 88, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    UnitFormat.formatTemperatureBare(
                        c.temperatureC, units.temperature),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          height: 1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(c.condition.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like '
                    '${UnitFormat.formatTemperature(c.feelsLikeC, units.temperature)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (today != null) ...<Widget>[
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Icon(Icons.arrow_upward,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(UnitFormat.formatTemperature(
                  today.maxTempC, units.temperature)),
              const SizedBox(width: 16),
              Icon(Icons.arrow_downward,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text(UnitFormat.formatTemperature(
                  today.minTempC, units.temperature)),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              children: <Widget>[
                _Stat(
                  icon: Icons.air,
                  label: 'Wind',
                  value: UnitFormat.formatWindSpeed(
                      c.windSpeedKph, units.windSpeed),
                ),
                _Stat(
                  icon: Icons.water_drop_outlined,
                  label: 'Precip',
                  value: UnitFormat.formatPrecipitation(
                      c.precipitationMm, units.precipitation),
                ),
                _Stat(
                  icon: Icons.umbrella_outlined,
                  label: 'Chance',
                  value: '${c.precipProbability.round()}%',
                ),
                _Stat(
                  icon: Icons.water,
                  label: 'Humidity',
                  value: '${c.humidity.round()}%',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Next hours',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.hourly.take(12).length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (BuildContext _, int i) {
              final HourlyForecast h = forecast.hourly[i];
              return _HourPill(hour: h, units: units);
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Source: ${forecast.source.label}'
          ' • updated ${DateFormat.Hm().format(forecast.fetchedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HourPill extends StatelessWidget {
  const _HourPill({required this.hour, required this.units});
  final HourlyForecast hour;
  final UnitPreferences units;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(DateFormat.Hm().format(hour.time),
              style: Theme.of(context).textTheme.bodySmall),
          Icon(hour.condition.icon, size: 24),
          Text(
            UnitFormat.formatTemperatureBare(hour.temperatureC, units.temperature),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ],
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
