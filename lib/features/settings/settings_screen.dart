import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units/units.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/models/saved_location.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final UnitPreferences units = ref.watch(unitPreferencesProvider);
    final AsyncValue<List<SavedLocation>> saved =
        ref.watch(savedLocationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          _SectionHeader(label: 'Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (ThemeMode? v) =>
                v == null ? null : ref.read(themeModeProvider.notifier).set(v),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (ThemeMode? v) =>
                v == null ? null : ref.read(themeModeProvider.notifier).set(v),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (ThemeMode? v) =>
                v == null ? null : ref.read(themeModeProvider.notifier).set(v),
          ),
          const Divider(),
          _SectionHeader(label: 'Units'),
          ListTile(
            title: const Text('Temperature'),
            subtitle:
                Text(units.temperature == TemperatureUnit.celsius ? '°C' : '°F'),
            trailing: SegmentedButton<TemperatureUnit>(
              segments: const <ButtonSegment<TemperatureUnit>>[
                ButtonSegment<TemperatureUnit>(
                    value: TemperatureUnit.celsius, label: Text('°C')),
                ButtonSegment<TemperatureUnit>(
                    value: TemperatureUnit.fahrenheit, label: Text('°F')),
              ],
              selected: <TemperatureUnit>{units.temperature},
              onSelectionChanged: (Set<TemperatureUnit> v) =>
                  ref.read(unitPreferencesProvider.notifier)
                      .setTemperature(v.first),
            ),
          ),
          ListTile(
            title: const Text('Wind speed'),
            trailing: SegmentedButton<WindSpeedUnit>(
              segments: const <ButtonSegment<WindSpeedUnit>>[
                ButtonSegment<WindSpeedUnit>(
                    value: WindSpeedUnit.kph, label: Text('km/h')),
                ButtonSegment<WindSpeedUnit>(
                    value: WindSpeedUnit.mph, label: Text('mph')),
                ButtonSegment<WindSpeedUnit>(
                    value: WindSpeedUnit.ms, label: Text('m/s')),
              ],
              selected: <WindSpeedUnit>{units.windSpeed},
              onSelectionChanged: (Set<WindSpeedUnit> v) =>
                  ref.read(unitPreferencesProvider.notifier)
                      .setWindSpeed(v.first),
            ),
          ),
          ListTile(
            title: const Text('Precipitation'),
            trailing: SegmentedButton<PrecipitationUnit>(
              segments: const <ButtonSegment<PrecipitationUnit>>[
                ButtonSegment<PrecipitationUnit>(
                    value: PrecipitationUnit.mm, label: Text('mm')),
                ButtonSegment<PrecipitationUnit>(
                    value: PrecipitationUnit.inches, label: Text('in')),
              ],
              selected: <PrecipitationUnit>{units.precipitation},
              onSelectionChanged: (Set<PrecipitationUnit> v) =>
                  ref.read(unitPreferencesProvider.notifier)
                      .setPrecipitation(v.first),
            ),
          ),
          const Divider(),
          _SectionHeader(label: 'Saved locations'),
          saved.when(
            data: (List<SavedLocation> list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No saved locations yet — add one from the home screen.'),
                );
              }
              return Column(
                children: list.map((SavedLocation l) {
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(l.name),
                    subtitle: Text('${l.latitude.toStringAsFixed(3)}, '
                        '${l.longitude.toStringAsFixed(3)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: l.id == null
                          ? null
                          : () => ref
                              .read(locationRepositoryProvider)
                              .removeLocation(l.id!),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (Object e, StackTrace _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load: $e'),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Brolly — the forecast, without the noise.\n'
              'No ads. No tracking. No accounts.',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
