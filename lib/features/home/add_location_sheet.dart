import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/location_repository.dart';
import '../../domain/models/saved_location.dart';

/// Minimal "add a pinned location" sheet — accepts a label and lat/lon.
/// Geocoding is out of scope for v1; the user can copy/paste coordinates
/// from any maps app.
class AddLocationSheet extends ConsumerStatefulWidget {
  const AddLocationSheet({super.key});

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lon = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final SavedLocation loc = SavedLocation(
      name: _name.text.trim(),
      latitude: double.parse(_lat.text.trim()),
      longitude: double.parse(_lon.text.trim()),
    );
    await ref.read(locationRepositoryProvider).addLocation(loc);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Add location',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Edinburgh',
              ),
              textInputAction: TextInputAction.next,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                    ],
                    validator: _validateLatLon(minVal: -90, maxVal: 90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lon,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                    ],
                    validator: _validateLatLon(minVal: -180, maxVal: 180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _validateLatLon({
    required double minVal,
    required double maxVal,
  }) {
    return (String? v) {
      if (v == null || v.trim().isEmpty) return 'Required';
      final double? parsed = double.tryParse(v.trim());
      if (parsed == null) return 'Not a number';
      if (parsed < minVal || parsed > maxVal) {
        return 'Must be between $minVal and $maxVal';
      }
      return null;
    };
  }
}
