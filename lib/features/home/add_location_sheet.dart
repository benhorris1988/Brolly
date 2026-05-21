import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/geocoding_result.dart';
import '../../data/repositories/geocoding_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../domain/models/saved_location.dart';

/// Add-location sheet. The user types a place name and picks from
/// Open-Meteo geocoder results — no coordinates required.
class AddLocationSheet extends ConsumerStatefulWidget {
  const AddLocationSheet({super.key});

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  String _lastQuery = '';
  bool _searching = false;
  bool _saving = false;
  String? _error;
  List<GeocodingResult> _results = const <GeocodingResult>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final String trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = const <GeocodingResult>[];
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searching = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final List<GeocodingResult> hits =
          await ref.read(geocodingRepositoryProvider).search(query);
      if (!mounted || query != _lastQuery) return;
      setState(() {
        _results = hits;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || query != _lastQuery) return;
      setState(() {
        _results = const <GeocodingResult>[];
        _searching = false;
        _error = 'Search failed. Check your connection and try again.';
      });
    }
  }

  Future<void> _pick(GeocodingResult r) async {
    setState(() => _saving = true);
    final String label = _formatLabel(r);
    final SavedLocation loc = SavedLocation(
      name: label,
      latitude: r.latitude,
      longitude: r.longitude,
      country: r.country,
    );
    await ref.read(locationRepositoryProvider).addLocation(loc);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _formatLabel(GeocodingResult r) {
    final List<String> parts = <String>[
      r.name,
      if (r.admin1 != null && r.admin1!.isNotEmpty && r.admin1 != r.name) r.admin1!,
      if (r.country != null && r.country!.isNotEmpty) r.country!,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Add location', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search for a place',
              hintText: 'e.g. Edinburgh, London, Cardiff',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _query.clear();
                        _onQueryChanged('');
                      },
                    ),
            ),
            onChanged: _onQueryChanged,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _buildResults(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_saving) {
      return const Center(
        heightFactor: 2,
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    if (_searching) {
      return const Center(
        heightFactor: 2,
        child: CircularProgressIndicator(),
      );
    }
    if (_query.text.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Type at least two characters to search.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No matches for "${_query.text.trim()}".',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int i) {
        final GeocodingResult r = _results[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(r.name),
          subtitle: Text(
            <String>[
              if (r.admin1 != null && r.admin1!.isNotEmpty && r.admin1 != r.name)
                r.admin1!,
              if (r.country != null && r.country!.isNotEmpty) r.country!,
            ].join(', '),
          ),
          onTap: () => _pick(r),
        );
      },
    );
  }
}
