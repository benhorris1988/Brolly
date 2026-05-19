import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'db.g.dart';

@DataClassName('SavedLocationRow')
class SavedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get country => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: <Type>[SavedLocations])
class BrollyDatabase extends _$BrollyDatabase {
  BrollyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<SavedLocationRow>> getAllLocations() {
    final SimpleSelectStatement<$SavedLocationsTable, SavedLocationRow> q =
        select(savedLocations)..orderBy(<OrderClauseGenerator<$SavedLocationsTable>>[
          (t) => OrderingTerm(expression: t.position),
          (t) => OrderingTerm(expression: t.addedAt),
        ]);
    return q.get();
  }

  Stream<List<SavedLocationRow>> watchAllLocations() {
    final SimpleSelectStatement<$SavedLocationsTable, SavedLocationRow> q =
        select(savedLocations)..orderBy(<OrderClauseGenerator<$SavedLocationsTable>>[
          (t) => OrderingTerm(expression: t.position),
          (t) => OrderingTerm(expression: t.addedAt),
        ]);
    return q.watch();
  }

  Future<int> insertLocation(SavedLocationsCompanion entry) =>
      into(savedLocations).insert(entry);

  Future<bool> updateLocation(SavedLocationRow row) =>
      update(savedLocations).replace(row);

  Future<int> deleteLocation(int id) =>
      (delete(savedLocations)..where(($SavedLocationsTable t) => t.id.equals(id)))
          .go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'brolly.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
