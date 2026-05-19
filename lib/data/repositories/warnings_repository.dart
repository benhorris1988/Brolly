import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env/env.dart';
import '../../domain/models/warning.dart';
import '../api/met_office_api.dart';
import '../models/met_office_warnings.dart';
import 'weather_repository.dart';

class WarningsRepository {
  WarningsRepository(this._api);

  final MetOfficeWarningsApi _api;

  Future<List<SevereWarning>> getActiveWarnings() async {
    if (!Env.hasMetOfficeKey) return const <SevereWarning>[];
    try {
      final MetOfficeWarningsResponse r = await _api.getActiveWarnings();
      return r.warnings.map(_map).toList(growable: false);
    } on DioException catch (e) {
      // Treat 404 / no-warnings as empty rather than an error.
      if (e.response?.statusCode == 404) return const <SevereWarning>[];
      rethrow;
    }
  }

  SevereWarning _map(MetOfficeWarning w) => SevereWarning(
        id: w.id,
        title: w.title,
        description: w.description,
        severity: WarningSeverityX.fromString(w.severity),
        type: w.warningType,
        validFrom: DateTime.parse(w.validFrom).toLocal(),
        validTo: DateTime.parse(w.validTo).toLocal(),
        regions: w.regions ?? const <String>[],
      );
}

final Provider<MetOfficeWarningsApi> metOfficeWarningsApiProvider =
    Provider<MetOfficeWarningsApi>(
        (Ref ref) => MetOfficeWarningsApi(ref.watch(metOfficeDioProvider)));

final Provider<WarningsRepository> warningsRepositoryProvider =
    Provider<WarningsRepository>(
        (Ref ref) => WarningsRepository(ref.watch(metOfficeWarningsApiProvider)));
