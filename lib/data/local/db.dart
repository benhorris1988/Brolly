import 'package:drift/drift.dart';

import 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart' as connection;

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

DatabaseConnection _openConnection() => connection.openConnection();
